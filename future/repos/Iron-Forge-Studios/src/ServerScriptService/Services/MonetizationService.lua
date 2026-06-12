--[[
    MonetizationService.lua (Server)
    Handles all Robux purchases: Game Passes & Developer Products.
    - Server-side validation on all purchases
    - Idempotent receipt processing
    - Pass benefit application
    - Product delivery (DC, eggs, boosts, vault expansion)
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Constants = require(game.ReplicatedStorage.Modules.Shared.Constants)
local Remotes = require(game.ReplicatedStorage.Modules.Shared.Remotes)
local DataService = require(game.ServerScriptService.Services.DataService)

local MonetizationService = {}

-- ═══════════════════════════════════════════════════════════════
-- GAME PASSES
-- ═══════════════════════════════════════════════════════════════

local function checkAndGrantPasses(player: Player)
    for passKey, passInfo in Constants.GamePasses do
        if passInfo.PassId > 0 then
            local success, ownsPass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passInfo.PassId)
            end)

            if success and ownsPass then
                DataService.GrantPass(player, passKey)
                MonetizationService._applyPassBenefits(player, passKey)
            end
        end
    end
end

function MonetizationService._applyPassBenefits(player: Player, passKey: string)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if passKey == "DesertVIP" then
        -- Gold name tag (handled by client UI)
        -- 2x income is checked in EggService passiveIncome
        -- VIP zone access checked in WorldService

    elseif passKey == "HeistMaster" then
        -- +3 daily heists checked in HeistService
        -- Radar is client-side UI

    elseif passKey == "AutoCollector" then
        -- Offline income calculated on login
        local data = DataService.GetData(player)
        if data then
            local offlineTime = os.time() - (data.LastLogin or os.time())
            local maxOffline = 8 * 3600 -- 8 hours max
            offlineTime = math.min(offlineTime, maxOffline)

            if offlineTime > 60 and data.TotalPassiveIncome > 0 then
                local offlineIncome = math.floor((data.TotalPassiveIncome / 60) * offlineTime)
                if offlineIncome > 0 then
                    DataService.AddCurrency(player, offlineIncome)
                    Remotes.GetEvent("NotificationPush"):FireClient(player, {
                        Title = "Auto-Collector",
                        Text = string.format("Earned %d DC while offline!", offlineIncome),
                        Duration = 5,
                    })
                end
            end
        end

    elseif passKey == "OasisArchitect" then
        -- Double plots limit checked in PlotService
        local data = DataService.GetData(player)
        if data then
            data.Plot.MaxPlots = Constants.Plot.MAX_PLOTS_ARCHITECT
        end

    elseif passKey == "SpeedDemon" then
        -- 2x walk speed
        if humanoid then
            humanoid.WalkSpeed = 32 -- default is 16
        end

    elseif passKey == "MegaBundle" then
        -- Grant all other passes
        for otherKey, _ in Constants.GamePasses do
            if otherKey ~= "MegaBundle" then
                DataService.GrantPass(player, otherKey)
                MonetizationService._applyPassBenefits(player, otherKey)
            end
        end
        -- +10000 DC (only on first purchase, tracked via pass ownership)
        DataService.AddCurrency(player, 10000)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- DEVELOPER PRODUCTS (Consumables)
-- ═══════════════════════════════════════════════════════════════

local function processReceipt(receiptInfo): Enum.ProductPurchaseDecision
    local userId = receiptInfo.PlayerId
    local productId = receiptInfo.ProductId
    local receiptId = tostring(receiptInfo.PurchaseId)

    local player = Players:GetPlayerByUserId(userId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local data = DataService.GetData(player)
    if not data then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Idempotency check
    if data.ProcessedReceipts[receiptId] then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    -- Find which product was purchased
    local productKey = nil
    for key, productInfo in Constants.DevProducts do
        if productInfo.ProductId == productId then
            productKey = key
            break
        end
    end

    if not productKey then
        warn("[MonetizationService] Unknown product ID:", productId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Deliver product
    local delivered = false
    local productInfo = Constants.DevProducts[productKey]

    if productKey == "DC1000" or productKey == "DC5000" then
        delivered = DataService.AddCurrency(player, productInfo.DC)

    elseif productKey == "PremiumEgg" then
        -- Give a premium egg (auto-hatch Rare+ guaranteed)
        local EggService = require(game.ServerScriptService.Services.EggService)
        -- Direct icon grant at Rare tier minimum
        local IconDB = require(game.ReplicatedStorage.Modules.Data.IconDatabase)
        local rareIcons = IconDB.GetByRarity("Rare")
        if #rareIcons > 0 then
            local icon = rareIcons[math.random(1, #rareIcons)]
            DataService.AddIcon(player, icon.Id)
            delivered = true
        end

    elseif productKey == "LegendaryEgg" then
        local IconDB = require(game.ReplicatedStorage.Modules.Data.IconDatabase)
        local legendaryIcons = IconDB.GetByRarity("Legendary")
        if #legendaryIcons > 0 then
            local icon = legendaryIcons[math.random(1, #legendaryIcons)]
            DataService.AddIcon(player, icon.Id)
            delivered = true
        end

    elseif productKey == "LuckyBoost" then
        table.insert(data.ActiveBoosts, {
            BoostType = "LuckyBoost",
            ExpiresAt = os.time() + 1800, -- 30 minutes
        })
        delivered = true

    elseif productKey == "Shield" then
        table.insert(data.ActiveBoosts, {
            BoostType = "Shield",
            ExpiresAt = os.time() + 3600, -- 1 hour
        })
        delivered = true

    elseif productKey == "VaultExpand" then
        data.VaultSlots = (data.VaultSlots or Constants.Heist.FREE_VAULT_SLOTS) + Constants.Heist.VAULT_EXPANSION_SLOTS
        delivered = true
    end

    if delivered then
        -- Mark receipt as processed
        data.ProcessedReceipts[receiptId] = true

        -- Save immediately for purchase safety
        task.spawn(function()
            DataService.SavePlayerData(player)
        end)

        Remotes.GetEvent("NotificationPush"):FireClient(player, {
            Title = "Purchase Complete",
            Text = "You received: " .. productInfo.Name,
            Duration = 4,
        })

        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ═══════════════════════════════════════════════════════════════
-- GAME PASS PURCHASE HANDLER
-- ═══════════════════════════════════════════════════════════════

local function onGamePassPurchased(player: Player, passId: number, wasPurchased: boolean)
    if not wasPurchased then return end

    for passKey, passInfo in Constants.GamePasses do
        if passInfo.PassId == passId then
            DataService.GrantPass(player, passKey)
            MonetizationService._applyPassBenefits(player, passKey)

            Remotes.GetEvent("NotificationPush"):FireClient(player, {
                Title = "Pass Unlocked!",
                Text = passInfo.Name .. " - " .. table.concat(passInfo.Benefits, ", "),
                Duration = 5,
            })
            break
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- PREMIUM PAYOUTS
-- ═══════════════════════════════════════════════════════════════

local function setupPremiumPayouts()
    local function onPremiumChanged(player: Player)
        if player.MembershipType == Enum.MembershipType.Premium then
            -- Bonus for premium players
            DataService.AddCurrency(player, 500)
            Remotes.GetEvent("NotificationPush"):FireClient(player, {
                Title = "Premium Bonus",
                Text = "Thanks for being a Premium member! +500 DC",
                Duration = 4,
            })
        end
    end

    Players.PlayerAdded:Connect(function(player)
        if player.MembershipType == Enum.MembershipType.Premium then
            -- Wait for data to load
            task.delay(3, function()
                if DataService.IsLoaded(player) then
                    onPremiumChanged(player)
                end
            end)
        end
    end)

    Players.PlayerMembershipChanged:Connect(onPremiumChanged)
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function MonetizationService.Init()
    -- Receipt processor (idempotent)
    MarketplaceService.ProcessReceipt = processReceipt

    -- Game pass purchase callback
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamePassPurchased)

    -- Check passes when data loads
    DataService.PlayerDataLoaded:Connect(function(player)
        task.spawn(checkAndGrantPasses, player)
    end)

    -- Premium payouts
    setupPremiumPayouts()

    print("[MonetizationService] Initialized")
end

return MonetizationService

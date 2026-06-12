--[[
    TestCommands.lua
    Chat-based test commands for Play Solo verification.
    All commands use the "/" prefix.

    Usage (in Roblox chat):
        /claimplot 1
        /buildhouse kaufmann
        /coins 500
        /fashion
        /status
        etc.
]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local Utilities     = require(ReplicatedStorage:WaitForChild("Utilities"))

local TestCommands = {}
TestCommands._services = nil

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function TestCommands:init(services: table)
    self._services = services

    -- Listen for chat messages from all players
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            self:_handleChat(player, message)
        end)
    end)

    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            self:_handleChat(player, message)
        end)
    end

    print("[TestCommands] Initialized — type /help for commands")
end

---------------------------------------------------------------------------
-- CHAT HANDLER
---------------------------------------------------------------------------

function TestCommands:_handleChat(player: Player, message: string)
    -- Only process commands starting with "/"
    if string.sub(message, 1, 1) ~= "/" then return end

    local parts = string.split(message, " ")
    local command = string.lower(parts[1])

    if command == "/help" then
        self:_cmdHelp(player)
    elseif command == "/claimplot" then
        self:_cmdClaimPlot(player, parts[2])
    elseif command == "/claimelpasseo" or command == "/claimshop" then
        self:_cmdClaimShop(player, parts[2])
    elseif command == "/buildhouse" or command == "/build" then
        self:_cmdBuildHouse(player, parts[2])
    elseif command == "/placefurniture" or command == "/place" then
        self:_cmdPlaceFurniture(player, parts[2])
    elseif command == "/plant" then
        self:_cmdPlant(player, parts[2], parts[3])
    elseif command == "/water" then
        self:_cmdWater(player, parts[2])
    elseif command == "/harvest" then
        self:_cmdHarvest(player, parts[2])
    elseif command == "/fashion" then
        self:_cmdFashion(player)
    elseif command == "/joinrunway" or command == "/join" then
        self:_cmdJoinRunway(player)
    elseif command == "/vote" then
        self:_cmdVote(player, parts[2])
    elseif command == "/night" then
        self:_cmdNight(player)
    elseif command == "/coins" then
        self:_cmdCoins(player, parts[2])
    elseif command == "/prestige" then
        self:_cmdPrestige(player, parts[2])
    elseif command == "/event" then
        self:_cmdEvent(player, table.concat(parts, " ", 2))
    elseif command == "/partcount" or command == "/parts" then
        self:_cmdPartCount(player)
    elseif command == "/save" then
        self:_cmdSave(player)
    elseif command == "/status" then
        self:_cmdStatus(player)
    elseif command == "/stock" then
        self:_cmdStock(player, parts[2], parts[3], parts[4])
    elseif command == "/buy" then
        self:_cmdBuy(player, parts[2], parts[3])
    elseif command == "/inventory" or command == "/inv" then
        self:_cmdInventory(player)
    else
        self:_notify(player, "Unknown command: " .. command .. " — type /help")
    end
end

---------------------------------------------------------------------------
-- COMMAND IMPLEMENTATIONS
---------------------------------------------------------------------------

function TestCommands:_cmdHelp(player: Player)
    local lines = {
        "=== Palm Springs Paradise Test Commands ===",
        "/claimplot [1-4] — Claim a residential plot",
        "/buildhouse [kaufmann|frey|wexler|neutra] — Build MCM home",
        "/placefurniture [itemId] — Place furniture at look position",
        "/claimshop [1-6] — Claim El Paseo storefront",
        "/stock [itemId] [qty] [price] — Stock your shop",
        "/buy [shopId] [itemId] — Buy from a shop",
        "/plant [plantId] [plotIndex] — Plant seed in garden",
        "/water [plotIndex] — Water garden plot",
        "/harvest [plotIndex] — Harvest mature plant",
        "/fashion — Start fashion event now",
        "/joinrunway — Join active fashion event",
        "/vote [playerName] — Vote in fashion event",
        "/night — Toggle night mode",
        "/coins [amount] — Give yourself SunCoins",
        "/prestige [amount] — Give yourself Prestige",
        "/event [theme] — Trigger event theme",
        "/partcount — Show total part count",
        "/inventory — Show your inventory",
        "/save — Force save your data",
        "/status — Show all system statuses",
    }
    for _, line in ipairs(lines) do
        self:_notify(player, line)
    end
end

function TestCommands:_cmdClaimPlot(player: Player, plotIdStr: string?)
    local plotId = tonumber(plotIdStr)
    if not plotId or plotId < 1 or plotId > 4 then
        self:_notify(player, "Usage: /claimplot [1-4]")
        return
    end
    self._services.plot:claimPlot(player, plotId)
end

function TestCommands:_cmdClaimShop(player: Player, shopIdStr: string?)
    local shopId = tonumber(shopIdStr)
    if not shopId or shopId < 1 or shopId > 6 then
        self:_notify(player, "Usage: /claimshop [1-6]")
        return
    end
    self._services.shop:claimShop(player, shopId)
end

function TestCommands:_cmdBuildHouse(player: Player, style: string?)
    if not style then
        self:_notify(player, "Usage: /buildhouse [kaufmann|frey|wexler|neutra]")
        return
    end

    -- Capitalize first letter
    style = string.upper(string.sub(style, 1, 1)) .. string.lower(string.sub(style, 2))

    if not GameConfig.HomeStyles[style] then
        self:_notify(player, "Invalid style! Options: Kaufmann, Frey, Wexler, Neutra")
        return
    end

    self._services.plot:buildHome(player, style)
end

function TestCommands:_cmdPlaceFurniture(player: Player, itemId: string?)
    if not itemId then
        self:_notify(player, "Usage: /placefurniture [itemId]")
        self:_notify(player, "Examples: eames_lounge, kidney_table, starburst_clock")
        return
    end

    -- Place at player's look position (or slightly in front)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        self:_notify(player, "Character not loaded!")
        return
    end

    local hrp = char.HumanoidRootPart
    local position = hrp.Position + hrp.CFrame.LookVector * 8 + Vector3.new(0, 1, 0)

    -- Give the item first if they don't have it (test mode)
    if not self._services.economy:hasItem(player, itemId) then
        self._services.economy:giveItem(player, itemId)
    end

    self._services.plot:placeFurniture(player, itemId, position, 0)
end

function TestCommands:_cmdPlant(player: Player, plantId: string?, plotIndexStr: string?)
    if not plantId then
        self:_notify(player, "Usage: /plant [plantId] [plotIndex]")
        self:_notify(player, "Plants: saguaro_cactus, barrel_cactus, agave, desert_marigold, bougainvillea")
        return
    end

    local plotIndex = tonumber(plotIndexStr) or 1
    self._services.garden:plantSeed(player, plotIndex, plantId)
end

function TestCommands:_cmdWater(player: Player, plotIndexStr: string?)
    local plotIndex = tonumber(plotIndexStr) or 1
    self._services.garden:waterPlant(player, plotIndex)
end

function TestCommands:_cmdHarvest(player: Player, plotIndexStr: string?)
    local plotIndex = tonumber(plotIndexStr) or 1
    self._services.garden:harvestPlant(player, plotIndex)
end

function TestCommands:_cmdFashion(player: Player)
    self._services.fashion:startEvent()
    self:_notify(player, "Fashion event started!")
end

function TestCommands:_cmdJoinRunway(player: Player)
    self._services.fashion:joinEvent(player)
end

function TestCommands:_cmdVote(player: Player, targetName: string?)
    if not targetName then
        self:_notify(player, "Usage: /vote [playerName]")
        return
    end

    -- Find target player
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name) == string.lower(targetName) then
            self._services.fashion:voteForOutfit(player, p.UserId)
            return
        end
    end
    self:_notify(player, "Player not found: " .. targetName)
end

function TestCommands:_cmdNight(player: Player)
    RemoteManager:fireClient("ToggleNight", player)
    self:_notify(player, "Night toggle sent to client!")
end

function TestCommands:_cmdCoins(player: Player, amountStr: string?)
    local amount = tonumber(amountStr) or 100
    self._services.economy:addCoins(player, math.abs(math.floor(amount)), "Test command")
    self:_notify(player, "Added " .. math.abs(math.floor(amount)) .. " SunCoins!")
end

function TestCommands:_cmdPrestige(player: Player, amountStr: string?)
    local amount = tonumber(amountStr) or 10
    self._services.economy:addPrestige(player, math.abs(math.floor(amount)))
    self:_notify(player, "Added " .. math.abs(math.floor(amount)) .. " Prestige!")
end

function TestCommands:_cmdEvent(player: Player, themeName: string?)
    if not themeName or themeName == "" then
        self:_notify(player, "Usage: /event [theme name]")
        self:_notify(player, "Themes: Poolside Paradise, Desert Bloom, Retro Revival, Modernism Week")
        return
    end
    self._services.event:startWeeklyTheme(themeName)
end

function TestCommands:_cmdPartCount(player: Player)
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            count += 1
        end
    end

    local budget = GameConfig.PartLimits.MaxTotalParts
    local pct = math.floor(count / budget * 100)
    self:_notify(player, "Total parts: " .. count .. " / " .. budget .. " (" .. pct .. "%)")
end

function TestCommands:_cmdSave(player: Player)
    self._services.persistence:savePlayer(player)
    self:_notify(player, "Data saved!")
end

function TestCommands:_cmdStatus(player: Player)
    self:_notify(player, "=== SYSTEM STATUS ===")

    -- Economy
    local data = self._services.economy:getPlayerData(player)
    if data then
        self:_notify(player, "SunCoins: " .. Utilities.formatCurrency(data.sunCoins))
        self:_notify(player, "Prestige: " .. data.prestige .. " | Level: " .. data.level)
        self:_notify(player, "Plot: " .. (data.plotId and ("#" .. data.plotId) or "None"))
        self:_notify(player, "Shop: " .. (data.shopId and ("#" .. data.shopId) or "None"))
        self:_notify(player, "Home: " .. (data.homeStyle or "None"))
    end

    -- Garden
    local gardenState = self._services.garden:getFullState()
    local planted = 0
    for _, plot in pairs(gardenState) do
        if plot.growthStage ~= "empty" then planted += 1 end
    end
    self:_notify(player, "Garden: " .. planted .. "/16 plots active")

    -- Fashion
    local fashionEvent = self._services.fashion:getCurrentEvent()
    self:_notify(player, "Fashion: " ..
        (fashionEvent and (fashionEvent.theme .. " (" .. #fashionEvent.participants .. " participants)") or "No event"))

    -- Event
    local currentEvent = self._services.event:getCurrentEvent()
    self:_notify(player, "Event: " ..
        (currentEvent and currentEvent.name or "None"))
    self:_notify(player, "Modernism Week: " ..
        (self._services.event:isModernismWeek() and "ACTIVE" or "inactive"))

    -- Parts
    local partCount = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then partCount += 1 end
    end
    self:_notify(player, "Parts: " .. partCount .. "/" .. GameConfig.PartLimits.MaxTotalParts)

    self:_notify(player, "=== END STATUS ===")
end

function TestCommands:_cmdStock(player: Player, itemId: string?, qtyStr: string?, priceStr: string?)
    if not itemId then
        self:_notify(player, "Usage: /stock [itemId] [quantity] [price]")
        return
    end

    local qty = tonumber(qtyStr) or 1
    local price = tonumber(priceStr)

    -- Give item to player first (test mode)
    self._services.economy:giveItem(player, itemId, qty)
    self._services.shop:stockItem(player, itemId, qty, price)
end

function TestCommands:_cmdBuy(player: Player, shopIdStr: string?, itemId: string?)
    if not shopIdStr or not itemId then
        self:_notify(player, "Usage: /buy [shopId] [itemId]")
        return
    end
    local shopId = tonumber(shopIdStr)
    if not shopId then return end
    self._services.shop:purchaseFromShop(player, shopId, itemId)
end

function TestCommands:_cmdInventory(player: Player)
    local data = self._services.economy:getPlayerData(player)
    if not data then
        self:_notify(player, "No data loaded!")
        return
    end

    self:_notify(player, "=== INVENTORY ===")
    local count = 0
    for itemId, qty in pairs(data.inventory) do
        self:_notify(player, "  " .. itemId .. " x" .. qty)
        count += 1
    end
    if count == 0 then
        self:_notify(player, "  (empty)")
    end
end

---------------------------------------------------------------------------
-- NOTIFICATION HELPER
---------------------------------------------------------------------------

function TestCommands:_notify(player: Player, message: string)
    RemoteManager:fireClient("NotifyPlayer", player, message)
    -- Also print to server output for debugging
    print("[TestCmd → " .. player.Name .. "] " .. message)
end

return TestCommands

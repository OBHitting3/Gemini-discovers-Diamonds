--[[
    RunwayBuilder.lua
    Builds the poolside fashion runway stage for Palm Springs Paradise.

    Components:
    - Central runway platform (30×6, 1 stud elevated)
    - Pink accent strip down the center
    - 8 poolside lounge chairs (4 per side)
    - Judge's table (3 seats)
    - Stage lighting rigs (4 poles)
    - Backdrop wall with "Palm Springs Paradise" SurfaceGui
    - DJ booth
    - Walk-on marker

    Part budget: < 80 parts.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Utilities  = require(ReplicatedStorage:WaitForChild("Utilities"))

local C = GameConfig.Colors

local RunwayBuilder = {}
RunwayBuilder._partCount = 0

---------------------------------------------------------------------------
-- BUILD RUNWAY
---------------------------------------------------------------------------

function RunwayBuilder:buildRunway(): number
    local parts = 0
    local world = GameConfig.World
    local runwayPos = world.RunwayPosition

    local folder = Instance.new("Folder")
    folder.Name = "FashionRunway"
    folder.Parent = workspace
    self._folder = folder

    local origin = CFrame.new(runwayPos)
    local rw = world.RunwaySize.X   -- 6 studs wide
    local rl = world.RunwaySize.Z   -- 30 studs long

    -- Main runway platform
    Utilities.createPart({
        Name = "RunwayPlatform",
        Size = Vector3.new(rw, 1, rl),
        CFrame = origin * CFrame.new(0, 0.5, 0),
        Color = C.WallWhite,
        Material = Enum.Material.SmoothPlastic,
        Reflectance = 0.05,
        Tag = "Runway",
        Parent = folder,
    })
    parts += 1

    -- Pink accent strip down the center
    Utilities.createPart({
        Name = "AccentStrip",
        Size = Vector3.new(1, 0.05, rl),
        CFrame = origin * CFrame.new(0, 1.03, 0),
        Color = C.DustyPink,
        Material = Enum.Material.Neon,
        Tag = "Runway",
        Parent = folder,
    })
    parts += 1

    -- Poolside lounge chairs (4 per side)
    for side = -1, 1, 2 do
        for i = 1, 4 do
            local zOff = (i - 2.5) * 7
            local xOff = side * (rw / 2 + 3)

            -- Chair base
            Utilities.createPart({
                Name = "LoungeChair_" .. (side == -1 and "L" or "R") .. i,
                Size = Vector3.new(2, 1, 5),
                CFrame = origin * CFrame.new(xOff, 0.5, zOff),
                Color = C.WallWhite,
                Material = Enum.Material.SmoothPlastic,
                Tag = "RunwaySeating",
                Parent = folder,
            })
            parts += 1

            -- Chair backrest (angled)
            Utilities.createPart({
                Name = "LoungeBack_" .. (side == -1 and "L" or "R") .. i,
                Size = Vector3.new(2, 1.5, 0.3),
                CFrame = origin * CFrame.new(xOff, 1.25, zOff - 2.2) *
                         CFrame.Angles(math.rad(-30), 0, 0),
                Color = C.WallWhite,
                Material = Enum.Material.SmoothPlastic,
                Tag = "RunwaySeating",
                Parent = folder,
            })
            parts += 1
        end
    end

    -- Judge's table at the far end
    local judgeZ = -rl / 2 - 5
    Utilities.createPart({
        Name = "JudgeTable",
        Size = Vector3.new(10, 2.5, 3),
        CFrame = origin * CFrame.new(0, 1.25, judgeZ),
        Color = C.Concrete,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Runway",
        Parent = folder,
    })
    parts += 1

    -- Judge seats (3)
    for i = 1, 3 do
        local jx = (i - 2) * 3.5
        Utilities.createPart({
            Name = "JudgeSeat_" .. i,
            Size = Vector3.new(2, 2, 2),
            CFrame = origin * CFrame.new(jx, 1, judgeZ - 2.5),
            Color = C.Terracotta,
            Material = Enum.Material.Fabric,
            Tag = "Runway",
            Parent = folder,
        })
        parts += 1
    end

    -- Stage lighting rigs (4 tall poles with colored spotlights)
    local lightPositions = {
        { x = -rw / 2 - 2, z = -rl / 3, color = C.Turquoise },
        { x =  rw / 2 + 2, z = -rl / 3, color = C.DustyPink },
        { x = -rw / 2 - 2, z =  rl / 3, color = C.DustyPink },
        { x =  rw / 2 + 2, z =  rl / 3, color = C.Turquoise },
    }
    for i, lp in ipairs(lightPositions) do
        -- Pole
        Utilities.createPart({
            Name = "LightPole_" .. i,
            Size = Vector3.new(0.4, 12, 0.4),
            CFrame = origin * CFrame.new(lp.x, 6, lp.z),
            Color = C.RoofDarkGrey,
            Material = Enum.Material.Metal,
            Tag = "Runway",
            Parent = folder,
        })
        parts += 1

        -- Spotlight head (neon glow)
        Utilities.createPart({
            Name = "Spotlight_" .. i,
            Size = Vector3.new(1.5, 1.5, 1.5),
            CFrame = origin * CFrame.new(lp.x, 12, lp.z),
            Color = lp.color,
            Material = Enum.Material.Neon,
            Shape = Enum.PartType.Ball,
            Tag = "Runway",
            Parent = folder,
        })
        parts += 1

        -- SpotLight instance for actual lighting
        local spot = Instance.new("SpotLight")
        spot.Brightness = 3
        spot.Range = 30
        spot.Angle = 60
        spot.Color = lp.color
        spot.Face = Enum.NormalId.Bottom
        spot.Parent = folder:FindFirstChild("Spotlight_" .. i)
    end

    -- Backdrop wall with "Palm Springs Paradise" text
    local backdropZ = rl / 2 + 3
    local backdropPart = Utilities.createPart({
        Name = "Backdrop",
        Size = Vector3.new(16, 8, 0.5),
        CFrame = origin * CFrame.new(0, 4, backdropZ),
        Color = C.WallWhite,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Runway",
        Parent = folder,
    })
    parts += 1

    -- SurfaceGui for backdrop text
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Back  -- faces toward the runway
    gui.Parent = backdropPart

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "PALM SPRINGS"
    titleLabel.TextColor3 = C.Turquoise
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = gui

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, 0, 0.3, 0)
    subLabel.Position = UDim2.new(0, 0, 0.55, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = "PARADISE"
    subLabel.TextColor3 = C.DustyPink
    subLabel.TextScaled = true
    subLabel.Font = Enum.Font.GothamBold
    subLabel.Parent = gui

    -- DJ booth (small elevated platform)
    local djOrigin = origin * CFrame.new(rw / 2 + 6, 0, backdropZ)
    Utilities.createPart({
        Name = "DJPlatform",
        Size = Vector3.new(4, 2, 4),
        CFrame = djOrigin * CFrame.new(0, 1, 0),
        Color = C.RoofDarkGrey,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Runway",
        Parent = folder,
    })
    parts += 1

    -- DJ speakers
    for i, sx in ipairs({ -1.5, 1.5 }) do
        Utilities.createPart({
            Name = "DJSpeaker_" .. i,
            Size = Vector3.new(1.5, 2, 1.5),
            CFrame = djOrigin * CFrame.new(sx, 3, 0),
            Color = C.RoofDarkGrey,
            Material = Enum.Material.SmoothPlastic,
            Tag = "Runway",
            Parent = folder,
        })
        parts += 1
    end

    -- Walk-on marker (start position, neon strip)
    local walkOnZ = -rl / 2 + 1
    Utilities.createPart({
        Name = "WalkOnMarker",
        Size = Vector3.new(rw, 0.05, 0.5),
        CFrame = origin * CFrame.new(0, 1.03, walkOnZ),
        Color = C.Turquoise,
        Material = Enum.Material.Neon,
        Tag = "RunwayMarker",
        Parent = folder,
    })
    parts += 1

    -- Store walkway points for runway walk animation
    folder:SetAttribute("WalkStartZ", walkOnZ)
    folder:SetAttribute("WalkEndZ", rl / 2 - 1)
    folder:SetAttribute("RunwayCenterX", runwayPos.X)
    folder:SetAttribute("RunwayY", runwayPos.Y + 1)

    self._partCount += parts
    print("[RunwayBuilder] Fashion runway built (" .. parts .. " parts)")
    return parts
end

function RunwayBuilder:getFolder()
    return self._folder
end

function RunwayBuilder:getPartCount(): number
    return self._partCount
end

return RunwayBuilder

--[[
    CarBuilder.lua
    Mid-century style drive car for Palm Springs — sit and drive on El Paseo.
    VehicleSeat tagged PSP_DriveCar for fairy sparkle audio (SoundController).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local C = GameConfig.Colors

local CarBuilder = {}
CarBuilder._folder = nil

function CarBuilder:buildCar(): number
    local world = GameConfig.World
    local spawnPos = world.CarSpawnPosition or Vector3.new(12, 2.5, -108)

    local existing = workspace:FindFirstChild("PSP_DesertCar")
    if existing then
        existing:Destroy()
    end

    local model = Instance.new("Model")
    model.Name = "PSP_DesertCar"
    model.Parent = workspace
    self._folder = model

    local baseCf = CFrame.new(spawnPos) * CFrame.Angles(0, math.rad(-15), 0)

    local chassis = Instance.new("Part")
    chassis.Name = "Chassis"
    chassis.Size = Vector3.new(5.5, 1.4, 9)
    chassis.Color = C.Turquoise
    chassis.Material = Enum.Material.SmoothPlastic
    chassis.Anchored = false
    chassis.CanCollide = true
    chassis.Parent = model

    local cabin = Instance.new("Part")
    cabin.Name = "Cabin"
    cabin.Size = Vector3.new(4.8, 1.6, 4.5)
    cabin.Color = C.WallWhite
    cabin.Material = Enum.Material.SmoothPlastic
    cabin.Anchored = false
    cabin.CanCollide = true
    cabin.Parent = model

    local seat = Instance.new("VehicleSeat")
    seat.Name = "DriveSeat"
    seat.Size = Vector3.new(2, 0.8, 2)
    seat.Color = C.DustyPink
    seat.Material = Enum.Material.Fabric
    seat.Anchored = false
    seat.MaxSpeed = 48
    seat.Torque = 3
    seat.TurnSpeed = 2.5
    seat.Disabled = false
    seat.Parent = model
    CollectionService:AddTag(seat, "PSP_DriveCar")

    local wheelOffsets = {
        { -2.4, -0.4, 3.2 },
        { 2.4, -0.4, 3.2 },
        { -2.4, -0.4, -3.2 },
        { 2.4, -0.4, -3.2 },
    }
    local wheels = {}
    for i, off in ipairs(wheelOffsets) do
        local wheel = Instance.new("Part")
        wheel.Name = "Wheel_" .. i
        wheel.Shape = Enum.PartType.Cylinder
        wheel.Size = Vector3.new(1.2, 2.2, 2.2)
        wheel.Color = C.RoofDarkGrey
        wheel.Material = Enum.Material.SmoothPlastic
        wheel.Anchored = false
        wheel.CanCollide = true
        wheel.Parent = model
        wheels[i] = wheel
    end

    model.PrimaryPart = chassis
    model:PivotTo(baseCf)

    local function weld(a: BasePart, b: BasePart)
        local w = Instance.new("WeldConstraint")
        w.Part0 = a
        w.Part1 = b
        w.Parent = a
    end

    weld(chassis, cabin)
    weld(chassis, seat)
    for _, wheel in ipairs(wheels) do
        weld(chassis, wheel)
    end

    -- Cabin sits above chassis
    cabin.CFrame = chassis.CFrame * CFrame.new(0, 1.2, -0.5)
    seat.CFrame = chassis.CFrame * CFrame.new(0, 1.05, 0.3)
    for i, off in ipairs(wheelOffsets) do
        wheels[i].CFrame = chassis.CFrame
            * CFrame.new(off[1], off[2], off[3])
            * CFrame.Angles(0, 0, math.rad(90))
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DriveHint"
    billboard.Size = UDim2.fromOffset(200, 48)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = chassis
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = "Sit to drive — fairy chimes while you roll"
    label.Parent = billboard

    print("[CarBuilder] Desert car placed near spawn — tag PSP_DriveCar")
    return 6 + #wheels
end

function CarBuilder:getFolder()
    return self._folder
end

return CarBuilder

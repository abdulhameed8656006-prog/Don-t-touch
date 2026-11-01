-- Universal Menu: Speed / High Jump / Fly / No Clip
-- Works in most games (R6 + R15, respawns, games that reset your stats).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Settings (edit these if you want)
local SPEED_ON = 60
local JUMP_POWER_ON = 150
local JUMP_HEIGHT_ON = 50
local FLY_SPEED = 70

local state = {Speed = false, HighJump = false, Fly = false, NoClip = false}

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = player.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

---------------------------------------------------------------------
-- GUI (picks the safest place that works in your executor)
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999

pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(gui) end
end)

local parented = false
pcall(function()
    if gethui then
        local old = gethui():FindFirstChild("UniversalMenu")
        if old then old:Destroy() end
        gui.Parent = gethui()
        parented = true
    end
end)
if not parented then
    pcall(function()
        local old = game:GetService("CoreGui"):FindFirstChild("UniversalMenu")
        if old then old:Destroy() end
        gui.Parent = game:GetService("CoreGui")
        parented = true
    end)
end
if not parented then
    local pg = player:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("UniversalMenu")
    if old then old:Destroy() end
    gui.Parent = pg
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 190, 0, 236)
frame.Position = UDim2.new(0, 20, 0.5, -118)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 34)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Universal Menu"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

-- Hide / show button
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -34)
body.Position = UDim2.new(0, 0, 0, 34)
body.BackgroundTransparency = 1
body.Parent = frame

local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0, 28, 0, 24)
mini.Position = UDim2.new(1, -34, 0, 5)
mini.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
mini.Text = "-"
mini.TextColor3 = Color3.new(1, 1, 1)
mini.Font = Enum.Font.GothamBold
mini.TextSize = 16
mini.BorderSizePixel = 0
mini.Parent = frame
Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 6)

local minimized = false
mini.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    frame.Size = minimized and UDim2.new(0, 190, 0, 34) or UDim2.new(0, 190, 0, 236)
    mini.Text = minimized and "+" or "-"
end)

-- Dragging (mouse + touch)
do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local OFF_COLOR = Color3.fromRGB(170, 55, 55)
local ON_COLOR = Color3.fromRGB(55, 170, 85)

local function makeButton(label, key, y, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 40)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = OFF_COLOR
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Text = label .. ": OFF"
    btn.BorderSizePixel = 0
    btn.Parent = body
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        state[key] = not state[key]
        btn.Text = label .. (state[key] and ": ON" or ": OFF")
        btn.BackgroundColor3 = state[key] and ON_COLOR or OFF_COLOR
        if onToggle then onToggle(state[key]) end
    end)
end

---------------------------------------------------------------------
-- Fly helpers
---------------------------------------------------------------------
local flyBV, flyBG

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

local function startFly()
    local root = getRoot()
    local hum = getHumanoid()
    if not root or not hum then return end
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 9e4
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root

    hum.PlatformStand = true
end

---------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------
makeButton("Speed", "Speed", 4)
makeButton("High Jump", "HighJump", 52)
makeButton("Fly", "Fly", 100, function(on)
    if on then startFly() else stopFly() end
end)
makeButton("No Clip", "NoClip", 148)

---------------------------------------------------------------------
-- Main loop: keeps everything applied even if the game resets it
---------------------------------------------------------------------
local defaults = setmetatable({}, {__mode = "k"})
local applied = {Speed = false, HighJump = false}

RunService.Heartbeat:Connect(function()
    local hum = getHumanoid()
    if not hum then return end

    if not defaults[hum] then
        defaults[hum] = {
            speed = hum.WalkSpeed,
            power = hum.JumpPower,
            height = hum.JumpHeight,
        }
    end
    local d = defaults[hum]

    -- Speed
    if state.Speed then
        hum.WalkSpeed = SPEED_ON
        applied.Speed = true
    elseif applied.Speed then
        hum.WalkSpeed = d.speed
        applied.Speed = false
    end

    -- High jump (sets both so it works whether the game uses JumpPower or JumpHeight)
    if state.HighJump then
        hum.JumpPower = JUMP_POWER_ON
        hum.JumpHeight = JUMP_HEIGHT_ON
        applied.HighJump = true
    elseif applied.HighJump then
        hum.JumpPower = d.power
        hum.JumpHeight = d.height
        applied.HighJump = false
    end

    -- Keep fly alive (re-create if the game or a respawn removed it)
    if state.Fly then
        local root = getRoot()
        if root and (not flyBV or not flyBV.Parent or flyBV.Parent ~= root) then
            startFly()
        end
        if not hum.PlatformStand then hum.PlatformStand = true end
    end
end)

RunService.RenderStepped:Connect(function()
    if not state.Fly or not flyBV or not flyBG then return end
    local hum = getHumanoid()
    local camera = workspace.CurrentCamera
    if not hum or not camera then return end

    local md = hum.MoveDirection
    local look = camera.CFrame.LookVector
    local vel = Vector3.zero

    if md.Magnitude > 0 then
        -- move where you walk; look up/down to climb or dive (works on mobile)
        local flat = Vector3.new(look.X, 0, look.Z)
        local forward = flat.Magnitude > 0 and md:Dot(flat.Unit) or 0
        vel = md * FLY_SPEED + Vector3.new(0, look.Y * forward * FLY_SPEED, 0)
    end

    -- PC: Space = up, Left Shift = down
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        vel += Vector3.new(0, FLY_SPEED, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        vel -= Vector3.new(0, FLY_SPEED, 0)
    end

    flyBV.Velocity = vel
    flyBG.CFrame = CFrame.new(Vector3.zero, Vector3.new(look.X, 0, look.Z))
end)

RunService.Stepped:Connect(function()
    if not state.NoClip then return end
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

-- Clean up fly parts when you die so nothing gets stuck
player.CharacterRemoving:Connect(function()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end)








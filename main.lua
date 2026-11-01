-- Just a Baseplate: Speed / High Jump / Fly / Noclip menu
-- Paste into your executor and run.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Settings (change these if you want)
local SPEED_ON = 60
local SPEED_OFF = 16
local JUMP_ON = 150
local JUMP_OFF = 50
local FLY_SPEED = 70

local state = {Speed = false, HighJump = false, Fly = false, Noclip = false}

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------------
-- GUI
---------------------------------------------------------------------
local parent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
    local old = parent:FindFirstChild("BaseplateMenu")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BaseplateMenu"
gui.ResetOnSpawn = false
gui.Parent = parent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 190, 0, 230)
frame.Position = UDim2.new(0, 20, 0.5, -115)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundTransparency = 1
title.Text = "Baseplate Menu"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local OFF_COLOR = Color3.fromRGB(170, 55, 55)
local ON_COLOR = Color3.fromRGB(55, 170, 85)

local function makeButton(name, y, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 40)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = OFF_COLOR
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Text = name .. ": OFF"
    btn.BorderSizePixel = 0
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        local key = name:gsub(" ", "")
        state[key] = not state[key]
        btn.Text = name .. (state[key] and ": ON" or ": OFF")
        btn.BackgroundColor3 = state[key] and ON_COLOR or OFF_COLOR
        onToggle(state[key])
    end)
    return btn
end

---------------------------------------------------------------------
-- Speed
---------------------------------------------------------------------
makeButton("Speed", 42, function(on)
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = on and SPEED_ON or SPEED_OFF end
end)

---------------------------------------------------------------------
-- High Jump
---------------------------------------------------------------------
makeButton("High Jump", 90, function(on)
    local hum = getHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = on and JUMP_ON or JUMP_OFF
    end
end)

---------------------------------------------------------------------
-- Fly
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
    stopFly()

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

makeButton("Fly", 138, function(on)
    if on then startFly() else stopFly() end
end)

RunService.RenderStepped:Connect(function()
    if not state.Fly or not flyBV or not flyBG then return end
    local hum = getHumanoid()
    if not hum then return end

    local md = hum.MoveDirection
    local look = camera.CFrame.LookVector
    local vel = Vector3.zero

    if md.Magnitude > 0 then
        -- move where you walk; look up/down to climb or dive (works on mobile)
        local flatLook = Vector3.new(look.X, 0, look.Z)
        local forward = 0
        if flatLook.Magnitude > 0 then
            forward = md:Dot(flatLook.Unit)
        end
        vel = md * FLY_SPEED + Vector3.new(0, look.Y * forward * FLY_SPEED, 0)
    end

    -- Space = up, Left Shift = down (PC)
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        vel += Vector3.new(0, FLY_SPEED, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        vel -= Vector3.new(0, FLY_SPEED, 0)
    end

    flyBV.Velocity = vel
    flyBG.CFrame = CFrame.new(Vector3.zero, Vector3.new(look.X, 0, look.Z))
end)

---------------------------------------------------------------------
-- Noclip
---------------------------------------------------------------------
makeButton("No Clip", 186, function() end)

RunService.Stepped:Connect(function()
    if not state.NoClip then return end
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

---------------------------------------------------------------------
-- Re-apply after respawn
---------------------------------------------------------------------
player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    hum.WalkSpeed = state.Speed and SPEED_ON or SPEED_OFF
    hum.UseJumpPower = true
    hum.JumpPower = state.HighJump and JUMP_ON or JUMP_OFF
    if state.Fly then startFly() end
end)








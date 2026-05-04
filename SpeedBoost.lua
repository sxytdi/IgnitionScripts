-- SpeedBoost | LocalScript
-- StarterPlayer > StarterPlayerScripts

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local BOOST_MULT = 1.05
local enabled    = false

local function getSeat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum then return nil end
    local seat = hum.SeatPart
    if seat and seat:IsA("VehicleSeat") then return seat end
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name         = "SpeedUI"
gui.ResetOnSpawn = false
gui.Parent       = LocalPlayer.PlayerGui

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 210, 0, 100)
panel.Position         = UDim2.new(0, 16, 0.5, -50)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
panel.BorderSizePixel  = 0
panel.Active           = true
panel.Draggable        = true
panel.Parent           = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6)
local st = Instance.new("UIStroke", panel)
st.Color = Color3.fromRGB(70, 70, 120)
st.Thickness = 1

-- "Speed Boost:" label
local label = Instance.new("TextLabel", panel)
label.Size               = UDim2.new(0, 90, 0, 26)
label.Position           = UDim2.new(0, 8, 0, 10)
label.BackgroundTransparency = 1
label.Text               = "Speed Boost:"
label.TextColor3         = Color3.fromRGB(180, 180, 210)
label.Font               = Enum.Font.GothamBold
label.TextSize           = 13
label.TextXAlignment     = Enum.TextXAlignment.Left

-- Value input
local box = Instance.new("TextBox", panel)
box.Size             = UDim2.new(0, 90, 0, 26)
box.Position         = UDim2.new(0, 112, 0, 10)
box.BackgroundColor3 = Color3.fromRGB(28, 28, 48)
box.BorderSizePixel  = 0
box.Text             = tostring(BOOST_MULT)
box.TextColor3       = Color3.fromRGB(220, 220, 255)
box.Font             = Enum.Font.Gotham
box.TextSize         = 13
box.ClearTextOnFocus = false
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

box.FocusLost:Connect(function()
    local val = tonumber(box.Text)
    if val and val > 1 then
        BOOST_MULT = val
    else
        box.Text = tostring(BOOST_MULT)
    end
end)

-- ON / OFF button
local btn = Instance.new("TextButton", panel)
btn.Size             = UDim2.new(1, -16, 0, 34)
btn.Position         = UDim2.new(0, 8, 0, 52)
btn.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
btn.BorderSizePixel  = 0
btn.Text             = "OFF"
btn.TextColor3       = Color3.fromRGB(200, 80, 80)
btn.Font             = Enum.Font.GothamBold
btn.TextSize         = 14
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

btn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        btn.Text             = "ON"
        btn.TextColor3       = Color3.fromRGB(80, 200, 120)
        btn.BackgroundColor3 = Color3.fromRGB(25, 50, 35)
    else
        btn.Text             = "OFF"
        btn.TextColor3       = Color3.fromRGB(200, 80, 80)
        btn.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
    end
end)

-- Watermark
local wm = Instance.new("TextLabel", gui)
wm.Size               = UDim2.new(0, 150, 0, 18)
wm.Position           = UDim2.new(1, -158, 1, -22)
wm.BackgroundTransparency = 1
wm.Text               = "Ignition Scripts"
wm.TextColor3         = Color3.fromRGB(80, 80, 120)
wm.Font               = Enum.Font.GothamBold
wm.TextSize           = 12
wm.TextXAlignment     = Enum.TextXAlignment.Right

-- Loop
RunService.Stepped:Connect(function()
    if not enabled then return end
    if UserInputService:GetFocusedTextBox() then return end
    local seat = getSeat()
    if not seat then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        seat.AssemblyLinearVelocity *= Vector3.new(BOOST_MULT, 1, BOOST_MULT)
    end
end)

-- LocalScript: Vehicle Finder Pro
-- By: Ignition Scripts
-- Location: StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MAX_DISTANCE = 20
local SEARCH_INTERVAL = 0.5
local MOUNT_COOLDOWN = 1.5

local nearestSeat = nil
local lastSearch = 0
local lastMount = 0
local seatCache = {}
local connections = {}

-- ─────────────────────────────────────────
-- SEAT CACHE
-- ─────────────────────────────────────────

local function rebuildCache()
    seatCache = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
            table.insert(seatCache, obj)
        end
    end
end
rebuildCache()

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
        table.insert(seatCache, obj)
    end
end)

workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
        for i, seat in ipairs(seatCache) do
            if seat == obj then table.remove(seatCache, i) break end
        end
    end
end)

-- ─────────────────────────────────────────
-- UI
-- ─────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name = "VehicleFinderUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 250, 0, 135)
panel.Position = UDim2.new(0.5, -125, 1, -155)
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
panel.BackgroundTransparency = 1
panel.BorderSizePixel = 0
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 1
stroke.Thickness = 1
stroke.Parent = panel

-- Status dot
local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 14, 0, 15)
dot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
dot.BorderSizePixel = 0
dot.Parent = panel
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 20)
statusLabel.Position = UDim2.new(0, 28, 0, 10)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "No vehicle nearby"
statusLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

-- Separator
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -24, 0, 1)
sep.Position = UDim2.new(0, 12, 0, 34)
sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sep.BackgroundTransparency = 0.9
sep.BorderSizePixel = 0
sep.Parent = panel

-- Vehicle name
local vehicleName = Instance.new("TextLabel")
vehicleName.Size = UDim2.new(1, -24, 0, 20)
vehicleName.Position = UDim2.new(0, 12, 0, 40)
vehicleName.BackgroundTransparency = 1
vehicleName.Text = "Get closer to a vehicle"
vehicleName.TextColor3 = Color3.fromRGB(241, 245, 249)
vehicleName.TextSize = 14
vehicleName.Font = Enum.Font.GothamBold
vehicleName.TextXAlignment = Enum.TextXAlignment.Left
vehicleName.Parent = panel

-- Distance label
local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(1, -24, 0, 14)
distLabel.Position = UDim2.new(0, 12, 0, 61)
distLabel.BackgroundTransparency = 1
distLabel.Text = string.format("Search range: %d studs", MAX_DISTANCE)
distLabel.TextColor3 = Color3.fromRGB(71, 85, 105)
distLabel.TextSize = 11
distLabel.Font = Enum.Font.Gotham
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.Parent = panel

-- Distance bar background
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -24, 0, 4)
barBg.Position = UDim2.new(0, 12, 0, 77)
barBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barBg.BackgroundTransparency = 0.88
barBg.BorderSizePixel = 0
barBg.Parent = panel
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

-- Distance bar fill
local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(74, 222, 128)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

-- Mount button
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -24, 0, 30)
btn.Position = UDim2.new(0, 12, 0, 87)
btn.BackgroundColor3 = Color3.fromRGB(30, 58, 138)
btn.BorderSizePixel = 0
btn.Text = "Enter vehicle  [E]"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextSize = 12
btn.Font = Enum.Font.GothamMedium
btn.Visible = false
btn.Parent = panel
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.MouseEnter:Connect(function()
    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(37, 99, 235)}):Play()
end)
btn.MouseLeave:Connect(function()
    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 58, 138)}):Play()
end)

-- Watermark
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(1, -24, 0, 14)
watermark.Position = UDim2.new(0, 12, 0, 119)
watermark.BackgroundTransparency = 1
watermark.Text = "Ignition Scripts"
watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
watermark.TextTransparency = 0.75
watermark.TextSize = 10
watermark.Font = Enum.Font.GothamMedium
watermark.TextXAlignment = Enum.TextXAlignment.Right
watermark.Parent = panel

-- ─────────────────────────────────────────
-- FADE IN / FADE OUT
-- ─────────────────────────────────────────

local panelVisible = false

local function showPanel()
    if panelVisible then return end
    panelVisible = true
    TweenService:Create(panel, TweenInfo.new(0.25), {BackgroundTransparency = 0.08}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency = 0.88}):Play()
end

local function hidePanel()
    if not panelVisible then return end
    panelVisible = false
    TweenService:Create(panel, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
end

-- ─────────────────────────────────────────
-- UPDATE UI
-- ─────────────────────────────────────────

local function updateUI(seat, dist, found)
    if found then
        showPanel()
        if seat.Occupant ~= nil then
            dot.BackgroundColor3 = Color3.fromRGB(251, 191, 36)
            statusLabel.Text = "Seat occupied"
            statusLabel.TextColor3 = Color3.fromRGB(253, 224, 71)
            btn.Visible = false
        else
            dot.BackgroundColor3 = Color3.fromRGB(74, 222, 128)
            statusLabel.Text = "Vehicle available"
            statusLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
            btn.Visible = true
        end

        local modelName = seat.Parent and seat.Parent.Name or seat.Name
        vehicleName.Text = modelName
        distLabel.Text = string.format("%.1f studs away", dist)

        local pct = 1 - math.clamp(dist / MAX_DISTANCE, 0, 1)
        TweenService:Create(barFill, TweenInfo.new(0.3), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        barFill.BackgroundColor3 = pct > 0.6
            and Color3.fromRGB(74, 222, 128)
            or  Color3.fromRGB(251, 191, 36)
    else
        hidePanel()
        barFill.Size = UDim2.new(0, 0, 1, 0)
        btn.Visible = false
    end
end

-- ─────────────────────────────────────────
-- OPTIMIZED SEARCH WITH GetPartBoundsInRadius
-- ─────────────────────────────────────────

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isPlayerDriving()
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.SeatPart ~= nil
end

local function findNearestSeat(rootPos)
    local parts = workspace:GetPartBoundsInRadius(rootPos, MAX_DISTANCE, overlapParams)
    local partSet = {}
    for _, p in ipairs(parts) do partSet[p] = true end

    local closest, closestDist = nil, math.huge

    for i = #seatCache, 1, -1 do
        local seat = seatCache[i]
        if not seat or not seat.Parent then
            table.remove(seatCache, i)
        elseif partSet[seat] then
            local dist = (seat.Position - rootPos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = seat
            end
        end
    end

    return closest, closestDist
end

-- ─────────────────────────────────────────
-- HEARTBEAT — timer only, cheap search
-- ─────────────────────────────────────────

local function startSearch()
    local hb = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastSearch < SEARCH_INTERVAL then return end
        lastSearch = now

        if isPlayerDriving() then
            updateUI(nil, 0, false)
            return
        end

        local root = getRoot()
        if not root then return end

        local seat, dist = findNearestSeat(root.Position)

        if seat and dist <= MAX_DISTANCE then
            nearestSeat = seat
            updateUI(seat, dist, true)
        else
            nearestSeat = nil
            updateUI(nil, 0, false)
        end
    end)
    table.insert(connections, hb)
end

-- ─────────────────────────────────────────
-- CLEANUP ON DEATH / RESPAWN
-- ─────────────────────────────────────────

local function cleanup()
    for _, c in ipairs(connections) do c:Disconnect() end
    connections = {}
    nearestSeat = nil
end

player.CharacterAdded:Connect(function()
    cleanup()
    task.wait(1)
    startSearch()
end)

if player.Character then
    startSearch()
end

-- ─────────────────────────────────────────
-- MOUNT with cooldown
-- ─────────────────────────────────────────

local function tryMount()
    if not nearestSeat then return end
    if nearestSeat.Occupant ~= nil then return end
    if tick() - lastMount < MOUNT_COOLDOWN then return end
    lastMount = tick()

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        nearestSeat:Sit(humanoid)
    end
end

btn.MouseButton1Click:Connect(tryMount)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then tryMount() end
end)

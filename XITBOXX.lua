-- LocalScript в экзекутор
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local State = {
    Hitboxes = false,
    Chams = false,
    HitboxSize = 1.0,
    SilentAim = false
}
local hitboxData = {}
local chamsData = {}

-- ============================================================
-- GUI (Кнопка + Меню)
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 20, 0, 100)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
toggleBtn.Text = "☰"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 24
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 10
toggleBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = toggleBtn

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 300)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ZIndex = 20
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 70, 90)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
title.Text = "Меню"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.ZIndex = 21
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = title

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 22
closeBtn.Parent = title

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

local list = Instance.new("Frame")
list.Size = UDim2.new(1, -20, 1, -50)
list.Position = UDim2.new(0, 10, 0, 45)
list.BackgroundTransparency = 1
list.ZIndex = 21
list.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = list

-- ============================================================
-- ЛОГИКА ХИТБОКСОВ (БЕЗ ЛАГОВ)
-- ============================================================
local function removeHitbox(plr)
    local data = hitboxData[plr]
    if not data then return end
    if data.VisualBox then data.VisualBox:Destroy() end
    if data.Conn then data.Conn:Disconnect() end
    hitboxData[plr] = nil
end

local function createHitbox(plr)
    if plr == player or hitboxData[plr] then return end
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end

    local data = { Connections = {} }

    -- Визуальная коробка (просто для вида)
    local visualBox = Instance.new("Part")
    visualBox.Name = "VisualHitbox"
    visualBox.Size = Vector3.new(4, 5, 4)
    visualBox.CFrame = hrp.CFrame
    visualBox.Transparency = 0.7
    visualBox.Color = Color3.fromRGB(0, 255, 255)
    visualBox.Material = Enum.Material.Neon
    visualBox.CanCollide = false
    visualBox.Anchored = true
    visualBox.CanQuery = false
    visualBox.Parent = Workspace
    data.VisualBox = visualBox

    -- Обновление визуальной коробки
    data.Conn = RunService.RenderStepped:Connect(function()
        if hrp and hrp.Parent then
            visualBox.Size = Vector3.new(4 * State.HitboxSize, 5 * State.HitboxSize, 4 * State.HitboxSize)
            visualBox.CFrame = hrp.CFrame
        else
            removeHitbox(plr)
        end
    end)

    hitboxData[plr] = data
end

-- ============================================================
-- SILENT AIM (МАГНИТ)
-- ============================================================
local function getClosestTarget()
    local closest, bestDist = nil, math.huge
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                -- Радиус действия магнита (можно увеличить)
                if dist < 150 and dist < bestDist then
                    bestDist = dist
                    closest = hrp
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not State.SilentAim then return end
    local target = getClosestTarget()
    if target then
        local cam = Workspace.CurrentCamera
        -- Мягкий поворот камеры к цели
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.Position), 0.3)
    end
end)

-- ============================================================
-- CHAMS
-- ============================================================
local function removeChams(plr)
    local data = chamsData[plr]
    if not data then return end
    if data.Highlight then data.Highlight:Destroy() end
    chamsData[plr] = nil
end

local function createChams(plr)
    if plr == player or chamsData[plr] then return end
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    chamsData[plr] = { Highlight = hl }
end

local function updateAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if State.Hitboxes then createHitbox(plr) else removeHitbox(plr) end
            if State.Chams then createChams(plr) else removeChams(plr) end
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        updateAll()
    end)
end)

-- ============================================================
-- КНОПКИ И ПОЛЗУНОК
-- ============================================================
local function createToggle(name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Text = "  " .. name .. ": ВЫКЛ"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.ZIndex = 22
    btn.Parent = list

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = "  " .. name .. ": " .. (state and "ВКЛ" or "ВЫКЛ")
        btn.BackgroundColor3 = state and Color3.fromRGB(60, 140, 80) or Color3.fromRGB(45, 45, 55)
        callback(state)
    end)
end

createToggle("Hitboxes", 1, function(v) State.Hitboxes = v; updateAll() end)
createToggle("Chams", 2, function(v) State.Chams = v; updateAll() end)
createToggle("Silent Aim (Магнит)", 3, function(v) State.SilentAim = v end)

-- ПОЛЗУНОК
local sliderContainer = Instance.new("Frame")
sliderContainer.Size = UDim2.new(1, 0, 0, 50)
sliderContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
sliderContainer.LayoutOrder = 4
sliderContainer.ZIndex = 22
sliderContainer.Parent = list

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 8)
sliderCorner.Parent = sliderContainer

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(1, 0, 0, 20)
sliderLabel.Position = UDim2.new(0, 8, 0, 4)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = "Размер коробки: 1.0x"
sliderLabel.TextColor3 = Color3.new(1, 1, 1)
sliderLabel.TextSize = 12
sliderLabel.Font = Enum.Font.Gotham
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.ZIndex = 23
sliderLabel.Parent = sliderContainer

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, -16, 0, 8)
bar.Position = UDim2.new(0, 8, 0, 30)
bar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
bar.BorderSizePixel = 0
bar.ZIndex = 23
bar.Parent = sliderContainer

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = bar

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0.2, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
fill.BorderSizePixel = 0
fill.ZIndex = 24
fill.Parent = bar

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 16, 0, 16)
knob.Position = UDim2.new(0.2, -8, 0.5, -8)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.ZIndex = 25
knob.Parent = bar

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = knob

local isDraggingSlider = false

local function updateSlider(inputX)
    local relX = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
    local value = 1.0 + (relX * 4.0)
    State.HitboxSize = value
    
    fill.Size = UDim2.new(relX, 0, 1, 0)
    knob.Position = UDim2.new(relX, -8, 0.5, -8)
    sliderLabel.Text = string.format("Размер коробки: %.1fx", value)
end

bar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = true
        updateSlider(input.Position.X)
    end
end)

RunService.RenderStepped:Connect(function()
    if isDraggingSlider then
        if UserInputService.TouchEnabled then
            local touches = UserInputService:GetTouches()
            if #touches > 0 then
                updateSlider(touches[1].Position.X)
            end
        else
            updateSlider(UserInputService:GetMouseLocation().X)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = false
    end
end)

-- ============================================================
-- ОТКРЫТИЕ / ЗАКРЫТИЕ
-- ============================================================
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

local dragging = false
local dragStart, startPos

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.AbsolutePosition
    end
end)

toggleBtn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 10 then
            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y
            newX = math.clamp(newX, 0, screenGui.AbsoluteSize.X - 50)
            newY = math.clamp(newY, 0, screenGui.AbsoluteSize.Y - 50)
            toggleBtn.Position = UDim2.new(0, newX, 0, newY)
        end
    end
end)

toggleBtn.InputEnded:Connect(function(input)
    if dragging then
        dragging = false
        local delta = input.Position - dragStart
        if delta.Magnitude <= 10 then
            mainFrame.Visible = not mainFrame.Visible
        end
    end
end)

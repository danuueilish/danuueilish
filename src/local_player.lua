-- src/local_player.lua (Professional Layout with Collapsible)
-- Local Player: WalkSpeed • Infinite Jump • Admin-Style Fly • Clean ESP
local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu or not UI.NewSection then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local Theme = {
  bg    = Color3.fromRGB(24,20,40),
  card  = Color3.fromRGB(44,36,72),
  text  = Color3.fromRGB(235,230,255),
  text2 = Color3.fromRGB(190,180,220),
  accA  = Color3.fromRGB(125,84,255),
  accB  = Color3.fromRGB(215,55,255),
  good  = Color3.fromRGB(106,212,123),
  bad   = Color3.fromRGB(255,95,95),
}

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

----------------------------------------------------------------
-- COLLAPSIBLE SECTION SETUP
----------------------------------------------------------------
local sec = UI.NewSection(UI.Tabs.Menu, "Local Player")
local secRoot = sec
local isMinimized = true

-- Force reset function
local function forceCollapsedState()
  secRoot.Size = UDim2.new(1, -4, 0, 50)
  isMinimized = true
end

-- Hook to main GUI for state reset
local mainGui = LP.PlayerGui:FindFirstChild("danuu_hub_ui")
if mainGui then
  mainGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if mainGui.Enabled then
      task.wait(0.1)
      forceCollapsedState()
    end
  end)
end

-- Create Main Toggle Button
local mainToggle = Instance.new("TextButton")
mainToggle.Name = "MainToggle"
mainToggle.AutoButtonColor = false
mainToggle.Text = "+ Local Player"
mainToggle.Font = Enum.Font.GothamBold
mainToggle.TextSize = 16
mainToggle.TextColor3 = Theme.accA
mainToggle.BackgroundColor3 = Theme.card
mainToggle.Size = UDim2.new(1, -8, 0, 40)
mainToggle.Position = UDim2.fromOffset(4, 4)
mainToggle.Parent = secRoot
corner(mainToggle, 10)
stroke(mainToggle, Theme.accA, 1).Transparency = .4

-- Content Container
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.BackgroundTransparency = 1
contentContainer.Size = UDim2.new(1, -8, 1, -52)
contentContainer.Position = UDim2.fromOffset(4, 48)
contentContainer.Visible = false
contentContainer.Parent = secRoot

local contentLayout = Instance.new("UIListLayout", contentContainer)
contentLayout.Padding = UDim.new(0, 12)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

----------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------
local function Hum()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChildOfClass("Humanoid")
end

local function HRP()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart")
end

----------------------------------------------------------------
-- CLEAN OPTION ROW BUILDER
----------------------------------------------------------------
local function createOptionRow(labelText, hasSlider, hasToggle, initialValue, onSliderChange, onToggleChange)
  local row = Instance.new("Frame")
  row.BackgroundColor3 = Theme.card
  row.Size = UDim2.new(1, 0, 0, 60)
  row.Parent = contentContainer
  corner(row, 10)
  stroke(row, Theme.accA, 1).Transparency = .6

  local padding = Instance.new("UIPadding", row)
  padding.PaddingLeft = UDim.new(0, 16)
  padding.PaddingRight = UDim.new(0, 16)
  padding.PaddingTop = UDim.new(0, 12)
  padding.PaddingBottom = UDim.new(0, 12)

  local layout = Instance.new("UIListLayout", row)
  layout.FillDirection = Enum.FillDirection.Horizontal
  layout.VerticalAlignment = Enum.VerticalAlignment.Center
  layout.Padding = UDim.new(0, 12)

  -- Label
  local label = Instance.new("TextLabel")
  label.BackgroundTransparency = 1
  label.Size = UDim2.new(0, 120, 1, 0)
  label.Font = Enum.Font.GothamSemibold
  label.TextSize = 16
  label.TextColor3 = Theme.text
  label.TextXAlignment = Enum.TextXAlignment.Left
  label.Text = labelText
  label.Parent = row

  -- Right side container
  local rightContainer = Instance.new("Frame")
  rightContainer.BackgroundTransparency = 1
  rightContainer.Size = UDim2.new(1, -132, 1, 0)
  rightContainer.Parent = row

  local rightLayout = Instance.new("UIListLayout", rightContainer)
  rightLayout.FillDirection = Enum.FillDirection.Horizontal
  rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
  rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
  rightLayout.Padding = UDim.new(0, 12)

  local slider, textBox, toggle

  -- Slider + TextBox
  if hasSlider then
    local sliderContainer = Instance.new("Frame")
    sliderContainer.BackgroundTransparency = 1
    sliderContainer.Size = UDim2.new(1, hasToggle and -172 or -90, 1, 0)
    sliderContainer.Parent = rightContainer

    local sliderLayout = Instance.new("UIListLayout", sliderContainer)
    sliderLayout.FillDirection = Enum.FillDirection.Horizontal
    sliderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    sliderLayout.Padding = UDim.new(0, 10)

    -- Slider
    local sliderBar = Instance.new("Frame")
    sliderBar.BackgroundColor3 = Theme.bg
    sliderBar.Size = UDim2.new(1, -90, 0, 8)
    sliderBar.Parent = sliderContainer
    corner(sliderBar, 4)
    stroke(sliderBar, Theme.accA, 1).Transparency = .5

    local sliderFill = Instance.new("Frame")
    sliderFill.BackgroundColor3 = Theme.accA
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.Parent = sliderBar
    corner(sliderFill, 4)

    local sliderKnob = Instance.new("Frame")
    sliderKnob.BackgroundColor3 = Theme.accB
    sliderKnob.Size = UDim2.fromOffset(16, 16)
    sliderKnob.Position = UDim2.new(0, -8, 0.5, -8)
    sliderKnob.Parent = sliderBar
    corner(sliderKnob, 8)

    -- TextBox
    textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 80, 0, 36)
    textBox.BackgroundColor3 = Theme.bg
    textBox.TextColor3 = Theme.text
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 14
    textBox.TextXAlignment = Enum.TextXAlignment.Center
    textBox.ClearTextOnFocus = false
    textBox.Text = tostring(initialValue or 16)
    textBox.Parent = sliderContainer
    corner(textBox, 8)
    stroke(textBox, Theme.accA, 1).Transparency = .6

    slider = {
      bar = sliderBar,
      fill = sliderFill,
      knob = sliderKnob,
      textBox = textBox
    }
  end

  -- Toggle Switch
  if hasToggle then
    local switchFrame = Instance.new("Frame")
    switchFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    switchFrame.Size = UDim2.new(0, 60, 0, 30)
    switchFrame.Parent = rightContainer
    corner(switchFrame, 15)

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Size = UDim2.new(0, 26, 0, 26)
    knob.Position = UDim2.new(0, 2, 0.5, -13)
    knob.Parent = switchFrame
    corner(knob, 13)

    local clickDetector = Instance.new("TextButton")
    clickDetector.BackgroundTransparency = 1
    clickDetector.Size = UDim2.fromScale(1, 1)
    clickDetector.Text = ""
    clickDetector.Parent = switchFrame

    local state = false

    clickDetector.MouseButton1Click:Connect(function()
      state = not state

      local bgTween = TweenService:Create(switchFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        BackgroundColor3 = state and Theme.good or Color3.fromRGB(60, 60, 60)
      })

      local knobTween = TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = state and UDim2.new(0, 32, 0.5, -13) or UDim2.new(0, 2, 0.5, -13)
      })

      bgTween:Play()
      knobTween:Play()

      if onToggleChange then onToggleChange(state) end
    end)

    toggle = {
      switch = switchFrame,
      knob = knob,
      getState = function() return state end,
      setState = function(newState)
        state = newState
        switchFrame.BackgroundColor3 = state and Theme.good or Color3.fromRGB(60, 60, 60)
        knob.Position = state and UDim2.new(0, 32, 0.5, -13) or UDim2.new(0, 2, 0.5, -13)
      end
    }
  end

  return row, slider, toggle, textBox
end

----------------------------------------------------------------
-- WALKSPEED CONTROL
----------------------------------------------------------------
local WS_MIN, WS_MAX = 0, 100
local targetWS = 16

local _, wsSlider, _, _ = createOptionRow("Walk Speed", true, false, targetWS, nil, nil)

local function applyWS(v)
  targetWS = math.clamp(math.floor(tonumber(v) or targetWS), WS_MIN, WS_MAX)
  local rel = (targetWS - WS_MIN) / math.max(1, (WS_MAX - WS_MIN))
  wsSlider.fill.Size = UDim2.new(rel, 0, 1, 0)
  wsSlider.knob.Position = UDim2.new(rel, -8, 0.5, -8)
  wsSlider.textBox.Text = tostring(targetWS)
  local h = Hum()
  if h then h.WalkSpeed = targetWS end
end

-- Slider drag functionality
do
  local dragging = false
  local function setFromX(x)
    local rel = math.clamp((x - wsSlider.bar.AbsolutePosition.X) / math.max(1, wsSlider.bar.AbsoluteSize.X), 0, 1)
    applyWS(WS_MIN + rel * (WS_MAX - WS_MIN))
  end

  wsSlider.bar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true
      setFromX(input.Position.X)
      input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
          dragging = false
        end
      end)
    end
  end)

  UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
      setFromX(input.Position.X)
    end
  end)
end

wsSlider.textBox.FocusLost:Connect(function()
  applyWS(wsSlider.textBox.Text)
end)

applyWS(targetWS)
LP.CharacterAdded:Connect(function()
  task.wait(0.2)
  applyWS(targetWS)
end)

----------------------------------------------------------------
-- INFINITE JUMP
----------------------------------------------------------------
local infConn, infDebounce, infOn = nil, false, false

local function setInfJump(enabled)
  infOn = enabled
  if infConn then
    infConn:Disconnect()
    infConn = nil
  end
  if infOn then
    infConn = UIS.JumpRequest:Connect(function()
      if not infDebounce then
        infDebounce = true
        local h = Hum()
        if h then
          h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.wait()
        infDebounce = false
      end
    end)
  end
end

local _, _, infToggle, _ = createOptionRow("Infinite Jump", false, true, false, nil, setInfJump)

LP.CharacterAdded:Connect(function()
  if infOn then
    task.wait(0.2)
    setInfJump(true)
  end
end)

----------------------------------------------------------------
-- ADMIN-STYLE FLY (Mobile Friendly)
----------------------------------------------------------------
local flyOn = false
local flyConn, gyro, vel
local keys = {W=false, A=false, S=false, D=false, Up=false, Down=false}
local FLY_SPEED = 50

local function stopFly()
  flyOn = false
  if flyConn then flyConn:Disconnect(); flyConn = nil end
  if gyro then gyro:Destroy(); gyro = nil end
  if vel then vel:Destroy(); vel = nil end
end

local function startFly()
  local hrp = HRP()
  local h = Hum()
  if not hrp or not h then return end

  flyOn = true

  -- Create BodyGyro for rotation
  gyro = Instance.new("BodyGyro")
  gyro.P = 9000
  gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
  gyro.CFrame = workspace.CurrentCamera and workspace.CurrentCamera.CFrame or hrp.CFrame
  gyro.Parent = hrp

  -- Create BodyVelocity for movement
  vel = Instance.new("BodyVelocity")
  vel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
  vel.Velocity = Vector3.zero
  vel.Parent = hrp

  flyConn = RS.Heartbeat:Connect(function()
    if not hrp or not hrp.Parent then
      stopFly()
      return
    end

    local cam = workspace.CurrentCamera
    local cf = cam and cam.CFrame or hrp.CFrame
    local look, right, up = cf.LookVector, cf.RightVector, cf.UpVector

    -- Keyboard movement
    local move = Vector3.zero
    if keys.W then move = move + look end
    if keys.S then move = move - look end
    if keys.A then move = move - right end
    if keys.D then move = move + right end
    if keys.Up then move = move + up end
    if keys.Down then move = move - up end

    -- Mobile analog support (follows camera direction)
    local hum = Hum()
    local md = hum and hum.MoveDirection or Vector3.zero
    if md.Magnitude > 0.1 then
      local camLook = Vector3.new(look.X, 0, look.Z).Unit
      local camRight = Vector3.new(right.X, 0, right.Z).Unit
      move = move + (camLook * md.Z + camRight * md.X)
    end

    -- Apply movement
    if move.Magnitude > 0 then
      move = move.Unit
    end

    vel.Velocity = move * FLY_SPEED
    gyro.CFrame = cf

    -- Disable default character physics
    h.PlatformStand = true
  end)
end

-- Keyboard handlers
UIS.InputBegan:Connect(function(input, gameProcessed)
  if gameProcessed then return end
  local keyCode = input.KeyCode
  if keyCode == Enum.KeyCode.W then keys.W = true
  elseif keyCode == Enum.KeyCode.A then keys.A = true  
  elseif keyCode == Enum.KeyCode.S then keys.S = true
  elseif keyCode == Enum.KeyCode.D then keys.D = true
  elseif keyCode == Enum.KeyCode.Space then keys.Up = true
  elseif keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.LeftShift then keys.Down = true
  elseif keyCode == Enum.KeyCode.Q then FLY_SPEED = math.max(10, FLY_SPEED - 10)
  elseif keyCode == Enum.KeyCode.E then FLY_SPEED = math.min(200, FLY_SPEED + 10)
  end
end)

UIS.InputEnded:Connect(function(input)
  local keyCode = input.KeyCode
  if keyCode == Enum.KeyCode.W then keys.W = false
  elseif keyCode == Enum.KeyCode.A then keys.A = false
  elseif keyCode == Enum.KeyCode.S then keys.S = false  
  elseif keyCode == Enum.KeyCode.D then keys.D = false
  elseif keyCode == Enum.KeyCode.Space then keys.Up = false
  elseif keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.LeftShift then keys.Down = false
  end
end)

local function toggleFly(enabled)
  if enabled then
    startFly()
  else
    stopFly()
    local h = Hum()
    if h then
      h.PlatformStand = false
    end
  end
end

local _, _, flyToggle, _ = createOptionRow("Fly Mode", false, true, false, nil, toggleFly)

LP.CharacterAdded:Connect(function()
  if flyOn then
    task.wait(0.2)
    flyToggle.setState(true)
    startFly()
  end
end)

----------------------------------------------------------------
-- CLEAN ESP SYSTEM
----------------------------------------------------------------
local espOn = false
local espConnections = {}

local function clearESP(character)
  if not character then return end
  for _, child in pairs(character:GetChildren()) do
    if (child:IsA("BillboardGui") and child.Name == "danuu_esp_gui") or
       (child:IsA("Highlight") and child.Name == "danuu_esp_highlight") then
      child:Destroy()
    end
  end
end

local function createESP(player)
  if not espOn or player == LP then return end
  local character = player.Character
  if not character then return end

  clearESP(character)

  local hrp = character:FindFirstChild("HumanoidRootPart")
  if not hrp then return end

  -- Subtle highlight outline
  local highlight = Instance.new("Highlight")
  highlight.Name = "danuu_esp_highlight"
  highlight.FillTransparency = 0.8
  highlight.OutlineTransparency = 0.3
  highlight.OutlineColor = Theme.accA
  highlight.FillColor = Theme.accA
  highlight.Parent = character

  -- Clean name tag
  local billboardGui = Instance.new("BillboardGui")
  billboardGui.Name = "danuu_esp_gui"
  billboardGui.Adornee = hrp
  billboardGui.AlwaysOnTop = true
  billboardGui.Size = UDim2.new(0, 200, 0, 50)
  billboardGui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
  billboardGui.Parent = character

  local frame = Instance.new("Frame")
  frame.BackgroundColor3 = Theme.card
  frame.BackgroundTransparency = 0.2
  frame.Size = UDim2.fromScale(1, 1)
  frame.Parent = billboardGui
  corner(frame, 8)
  stroke(frame, Theme.accA, 1).Transparency = 0.4

  local padding = Instance.new("UIPadding", frame)
  padding.PaddingTop = UDim.new(0, 6)
  padding.PaddingBottom = UDim.new(0, 6)
  padding.PaddingLeft = UDim.new(0, 10)
  padding.PaddingRight = UDim.new(0, 10)

  local nameLabel = Instance.new("TextLabel")
  nameLabel.BackgroundTransparency = 1
  nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
  nameLabel.Font = Enum.Font.GothamSemibold
  nameLabel.TextSize = 14
  nameLabel.TextColor3 = Theme.text
  nameLabel.TextXAlignment = Enum.TextXAlignment.Center
  nameLabel.Text = player.DisplayName or player.Name
  nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
  nameLabel.Parent = frame

  local distanceLabel = Instance.new("TextLabel")
  distanceLabel.BackgroundTransparency = 1
  distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
  distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
  distanceLabel.Font = Enum.Font.Gotham
  distanceLabel.TextSize = 12
  distanceLabel.TextColor3 = Theme.text2
  distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
  distanceLabel.Parent = frame

  -- Update distance
  task.spawn(function()
    while espOn and character.Parent and billboardGui.Parent do
      local myHrp = HRP()
      if myHrp and hrp then
        local distance = (myHrp.Position - hrp.Position).Magnitude
        distanceLabel.Text = string.format("%.0f studs", distance)
      end
      task.wait(0.2)
    end
  end)
end

local function enableESP()
  espOn = true
  
  -- ESP for existing players
  for _, player in pairs(Players:GetPlayers()) do
    if player ~= LP then
      espConnections[player] = player.CharacterAdded:Connect(function()
        if espOn then
          task.wait(0.2)
          createESP(player)
        end
      end)
      if player.Character then
        createESP(player)
      end
    end
  end

  -- ESP for new players
  espConnections._playerAdded = Players.PlayerAdded:Connect(function(player)
    if espOn and player ~= LP then
      espConnections[player] = player.CharacterAdded:Connect(function()
        if espOn then
          task.wait(0.2)
          createESP(player)
        end
      end)
      if player.Character then
        createESP(player)
      end
    end
  end)

  -- Cleanup when players leave
  espConnections._playerRemoving = Players.PlayerRemoving:Connect(function(player)
    if espConnections[player] then
      espConnections[player]:Disconnect()
      espConnections[player] = nil
    end
  end)
end

local function disableESP()
  espOn = false
  
  -- Disconnect all connections
  for _, connection in pairs(espConnections) do
    if connection then
      connection:Disconnect()
    end
  end
  table.clear(espConnections)
  
  -- Clear all ESP elements
  for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
      clearESP(player.Character)
    end
  end
end

local _, _, espToggle, _ = createOptionRow("Player ESP", false, true, false, nil, function(enabled)
  if enabled then
    enableESP()
  else
    disableESP()
  end
end)

----------------------------------------------------------------
-- COLLAPSIBLE TOGGLE FUNCTION
----------------------------------------------------------------
local function toggle()
  isMinimized = not isMinimized
  contentContainer.Visible = not isMinimized
  mainToggle.Text = (isMinimized and "+" or "–") .. " Local Player"
  
  if isMinimized then
    secRoot.Size = UDim2.new(1, -4, 0, 50)
  else
    secRoot.Size = UDim2.new(1, -4, 0, 400) -- Fixed size for consistent spacing
  end
end

mainToggle.MouseButton1Click:Connect(toggle)

----------------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------------
-- Force initial collapsed state
forceCollapsedState()
contentContainer.Visible = false
mainToggle.Text = "+ Local Player"

print("[danuu • Local Player] Professional collapsible version loaded ✓")

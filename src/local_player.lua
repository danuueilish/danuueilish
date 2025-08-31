-- src/local_player.lua
-- Local Player: WalkSpeed + InfJump + Fly + ESP (rapi, mobile-friendly)

local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu then return end

----------------------------------------------------------------
-- Services & refs
----------------------------------------------------------------
local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local Tween    = game:GetService("TweenService")

local LP       = Players.LocalPlayer

----------------------------------------------------------------
-- Theme + tiny helpers (match hub)
----------------------------------------------------------------
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

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

local function HRP()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end

----------------------------------------------------------------
-- Section container (under Menu, below Home)
----------------------------------------------------------------
local sec = UI.NewSection(UI.Tabs.Menu, "Local Player")

-- a neat row: [label(left)] [control(right)]
local function row(labelText, height)
  local r = Instance.new("Frame")
  r.BackgroundColor3 = Theme.card
  r.Size = UDim2.new(1, -4, 0, height or 56)
  r.Parent = sec
  corner(r, 10); stroke(r, Theme.accA, 1).Transparency = .6

  local pad = Instance.new("UIPadding", r)
  pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10)
  pad.PaddingTop  = UDim.new(0,8);  pad.PaddingBottom = UDim.new(0,8)

  local h = Instance.new("UIListLayout", r)
  h.FillDirection = Enum.FillDirection.Horizontal
  h.Padding = UDim.new(0,10)
  h.VerticalAlignment = Enum.VerticalAlignment.Center

  local label = Instance.new("TextLabel")
  label.BackgroundTransparency = 1
  label.Text = labelText
  label.Font = Enum.Font.GothamSemibold
  label.TextSize = 16
  label.TextXAlignment = Enum.TextXAlignment.Left
  label.TextColor3 = Theme.text
  label.Size = UDim2.new(0, 140, 1, 0)
  label.Parent = r

  local right = Instance.new("Frame")
  right.BackgroundTransparency = 1
  right.Size = UDim2.new(1, -140-10, 1, 0)
  right.Parent = r

  return r, right
end

----------------------------------------------------------------
-- WalkSpeed  [WalkSpeed] [ slider + numeric box ]
----------------------------------------------------------------
local wsRow, wsRight = row("WalkSpeed", 56)

local sliderBar = Instance.new("Frame")
sliderBar.BackgroundColor3 = Theme.bg
sliderBar.Size = UDim2.new(1, -120-10, 0, 12) -- leave room for box
sliderBar.Position = UDim2.fromOffset(0, 0)
sliderBar.Parent = wsRight
sliderBar.AnchorPoint = Vector2.new(0, .5)
sliderBar.Position = UDim2.new(0, 0, .5, 0)
corner(sliderBar, 6); stroke(sliderBar, Theme.accA, 1).Transparency = .6

local sliderFill = Instance.new("Frame")
sliderFill.BackgroundColor3 = Theme.accA
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.Parent = sliderBar
corner(sliderFill, 6)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(22,22)
knob.AnchorPoint = Vector2.new(.5,.5)
knob.Position = UDim2.new(0, 0, .5, 0)
knob.BackgroundColor3 = Theme.accB
knob.Parent = sliderBar
corner(knob, 11)

local wsBox = Instance.new("TextBox")
wsBox.Size = UDim2.new(0, 120, 1, 0)
wsBox.Position = UDim2.new(1, -120, 0, 0)
wsBox.BackgroundColor3 = Theme.bg
wsBox.Font = Enum.Font.GothamSemibold
wsBox.TextSize = 16
wsBox.TextColor3 = Theme.text
wsBox.ClearTextOnFocus = false
wsBox.Text = "16"
wsBox.Parent = wsRight
corner(wsBox, 8); stroke(wsBox, Theme.accA, 1).Transparency = .5

local function setWS(v)
  local hrp, hum = HRP(); if not hum then return end
  hum.WalkSpeed = v
end

local wsMin, wsMax = 8, 200
local function reflectWS(v)
  v = math.clamp(math.floor(v + .5), wsMin, wsMax)
  wsBox.Text = tostring(v)
  local rel = (v - wsMin) / (wsMax - wsMin)
  sliderFill.Size = UDim2.new(rel,0,1,0)
  knob.Position = UDim2.new(rel,0,.5,0)
  setWS(v)
end
reflectWS(tonumber(wsBox.Text) or 16)

-- drag slider
do
  local dragging=false
  sliderBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end
  end)
  UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
  end)
  UIS.InputChanged:Connect(function(i)
    if not dragging then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
      local rel = math.clamp((i.Position.X - sliderBar.AbsolutePosition.X)/sliderBar.AbsoluteSize.X, 0,1)
      local v = wsMin + rel*(wsMax-wsMin)
      reflectWS(v)
    end
  end)
end
wsBox.FocusLost:Connect(function() reflectWS(tonumber(wsBox.Text) or 16) end)

----------------------------------------------------------------
-- Infinite Jump  [Infinite Jump] [ ON/OFF ]
----------------------------------------------------------------
local ijRow, ijRight = row("Infinite Jump", 56)
local ijBtn = Instance.new("TextButton")
ijBtn.Text = "OFF"; ijBtn.AutoButtonColor=false
ijBtn.Font = Enum.Font.GothamSemibold; ijBtn.TextSize = 16
ijBtn.TextColor3 = Theme.text; ijBtn.BackgroundColor3 = Theme.bg
ijBtn.Size = UDim2.new(0, 120, 1, 0); ijBtn.Parent = ijRight
corner(ijBtn, 8); stroke(ijBtn, Theme.accA, 1).Transparency = .5

local infJumpConn, infJumpBusy=false, false
local function setInfJump(on)
  if on then
    if infJumpConn then infJumpConn:Disconnect() end
    infJumpBusy = false
    infJumpConn = UIS.JumpRequest:Connect(function()
      if infJumpBusy then return end
      infJumpBusy = true
      local _, hum = HRP(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
      task.wait(); infJumpBusy=false
    end)
    ijBtn.Text="ON"; ijBtn.BackgroundColor3 = Theme.accA
  else
    if infJumpConn then infJumpConn:Disconnect() end
    infJumpConn=false
    ijBtn.Text="OFF"; ijBtn.BackgroundColor3 = Theme.bg
  end
end
ijBtn.MouseButton1Click:Connect(function() setInfJump(ijBtn.Text=="OFF") end)

----------------------------------------------------------------
-- Fly (IY-style)  [Fly] [ ON/OFF ]
----------------------------------------------------------------
local flyRow, flyRight = row("Fly", 56)
local flyBtn = Instance.new("TextButton")
flyBtn.Text = "OFF"; flyBtn.AutoButtonColor=false
flyBtn.Font = Enum.Font.GothamSemibold; flyBtn.TextSize = 16
flyBtn.TextColor3 = Theme.text; flyBtn.BackgroundColor3 = Theme.bg
flyBtn.Size = UDim2.new(0, 120, 1, 0); flyBtn.Parent = flyRight
corner(flyBtn, 8); stroke(flyBtn, Theme.accA, 1).Transparency = .5

local flying=false
local BV, BG, flyLoop
local flySpeed = 2     -- IY default step
local flyMax   = 100   -- hard cap

local control = Vector3.zero
local lastMove = Vector3.zero

local function startFly()
  if flying then return end
  local hrp, hum = HRP(); if not hrp or not hum then return end
  flying = true; flyBtn.Text = "ON"; flyBtn.BackgroundColor3=Theme.accA

  BV = Instance.new("BodyVelocity"); BV.MaxForce = Vector3.new(1e9,1e9,1e9); BV.P = 1250; BV.Velocity = Vector3.zero; BV.Parent = hrp
  BG = Instance.new("BodyGyro"); BG.MaxTorque = Vector3.new(1e9,1e9,1e9); BG.P = 1250; BG.CFrame = workspace.CurrentCamera.CFrame; BG.Parent = hrp

  hum.PlatformStand = true

  flyLoop = RS.Heartbeat:Connect(function(dt)
    if not flying then return end
    -- Mobile analog friendly: use Humanoid.MoveDirection as base
    local mv = hum.MoveDirection
    -- keyboard adds vertical control
    local up   = UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space)
    local down = UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.LeftShift)
    local camCF = workspace.CurrentCamera and workspace.CurrentCamera.CFrame or hrp.CFrame

    -- project move along camera XZ so it matches thumbstick orientation
    local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
    local right   = Vector3.new(camCF.RightVector.X,0, camCF.RightVector.Z).Unit
    if forward.Magnitude < .1 then forward = Vector3.new(0,0,-1) end
    if right.Magnitude   < .1 then right   = Vector3.new(1,0,0) end

    local wish = (forward * mv.Z + right * mv.X)
    if up then wish = wish + Vector3.new(0,1,0) end
    if down then wish = wish + Vector3.new(0,-1,0) end
    if wish.Magnitude > 0 then wish = wish.Unit end

    local step = math.clamp(flySpeed*60*dt*4, 0, flyMax) -- dt-aware
    BV.Velocity = wish * (step*10)
    BG.CFrame = CFrame.new(Vector3.zero, (wish.Magnitude>0 and wish or forward))
  end)
end

local function stopFly()
  if not flying then return end
  flying=false; flyBtn.Text="OFF"; flyBtn.BackgroundColor3=Theme.bg
  local hrp, hum = HRP(); if hum then hum.PlatformStand=false end
  if BV then BV:Destroy() end; BV=nil
  if BG then BG:Destroy() end; BG=nil
  if flyLoop then flyLoop:Disconnect() end; flyLoop=nil
end

flyBtn.MouseButton1Click:Connect(function()
  if flying then stopFly() else startFly() end
end)

----------------------------------------------------------------
-- ESP Player  [ESP Player] [ ON/OFF ]
----------------------------------------------------------------
local espRow, espRight = row("ESP Player", 56)
local espBtn = Instance.new("TextButton")
espBtn.Text = "OFF"; espBtn.AutoButtonColor=false
espBtn.Font = Enum.Font.GothamSemibold; espBtn.TextSize = 16
espBtn.TextColor3 = Theme.text; espBtn.BackgroundColor3 = Theme.bg
espBtn.Size = UDim2.new(0, 120, 1, 0); espBtn.Parent = espRight
corner(espBtn, 8); stroke(espBtn, Theme.accA, 1).Transparency = .5

-- store adorns per player
local ESP_ENABLED=false
local espMap = {} -- [Player] = {bb=BillboardGui, tag1, tag2, hl}

local function clearESP(plr)
  local pkg = espMap[plr]
  if pkg then
    if pkg.bb then pkg.bb:Destroy() end
    if pkg.hl then pkg.hl:Destroy() end
    espMap[plr] = nil
  end
end

local function applyESP(plr)
  if plr == LP then return end
  local function onChar(char)
    clearESP(plr)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
      char:GetPropertyChangedSignal("Parent"):Wait()
      task.delay(.1, function() if ESP_ENABLED then applyESP(plr) end end)
      return
    end
    -- Highlight (thin to not block)
    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Theme.accA
    hl.Parent = char

    -- Name + distance
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop, bb.Size, bb.StudsOffset = true, UDim2.new(0,160,0,38), Vector3.new(0,3.2,0)
    bb.MaxDistance = 20000
    bb.Name = "danuu_esp"
    bb.Parent = hrp

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1,1)
    bg.BackgroundColor3 = Color3.fromRGB(64,52,96)
    bg.BackgroundTransparency = .15
    bg.Parent = bb
    corner(bg, 8); stroke(bg, Theme.accB, 1).Transparency = .3

    local nameL = Instance.new("TextLabel")
    nameL.BackgroundTransparency = 1
    nameL.Font = Enum.Font.GothamSemibold; nameL.TextSize=14
    nameL.TextColor3 = Theme.text
    nameL.TextXAlignment = Enum.TextXAlignment.Center
    nameL.Size = UDim2.new(1, -8, 0, 18)
    nameL.Position = UDim2.fromOffset(4,2)
    nameL.Text = ("%s (%s)"):format(plr.DisplayName or plr.Name, plr.Name)
    nameL.Parent = bg

    local distL = Instance.new("TextLabel")
    distL.BackgroundTransparency = 1
    distL.Font = Enum.Font.Gotham; distL.TextSize=13
    distL.TextColor3 = Theme.text2
    distL.TextXAlignment = Enum.TextXAlignment.Center
    distL.Size = UDim2.new(1, -8, 0, 16)
    distL.Position = UDim2.fromOffset(4,20)
    distL.Text = "0 studs"
    distL.Parent = bg

    -- updater
    local updater
    updater = RS.Heartbeat:Connect(function()
      if not bb.Parent or not hrp or not hrp.Parent then updater:Disconnect() return end
      local myHrp = HRP()
      if myHrp then
        local d = (myHrp.Position - hrp.Position).Magnitude
        distL.Text = string.format("%.0f studs", d)
      end
    end)

    espMap[plr] = {bb=bb, hl=hl}
  end

  if plr.Character then onChar(plr.Character) end
  plr.CharacterAdded:Connect(function(c) if ESP_ENABLED then onChar(c) end end)
  plr.CharacterRemoving:Connect(function() clearESP(plr) end)
end

local function setESP(on)
  ESP_ENABLED = on
  if on then
    espBtn.Text="ON"; espBtn.BackgroundColor3=Theme.accA
    for _,p in ipairs(Players:GetPlayers()) do applyESP(p) end
    Players.PlayerAdded:Connect(function(p) if ESP_ENABLED then applyESP(p) end end)
    Players.PlayerRemoving:Connect(clearESP)
  else
    espBtn.Text="OFF"; espBtn.BackgroundColor3=Theme.bg
    for p,_ in pairs(espMap) do clearESP(p) end
  end
end
espBtn.MouseButton1Click:Connect(function() setESP(espBtn.Text=="OFF") end)

----------------------------------------------------------------
-- Cleanup on respawn / leave (safety)
----------------------------------------------------------------
LP.CharacterAdded:Connect(function()
  -- keep WalkSpeed in case box shows custom
  task.wait(0.5)
  local v = tonumber(wsBox.Text) or 16
  reflectWS(v)
end)

-- done

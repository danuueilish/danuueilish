-- src/local_player.lua
-- Local Player tools: WalkSpeed + Infinite Jump + Fly + ESP (rapi & aman)

local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu or not UI.NewSection then return end

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")

local LP = Players.LocalPlayer

-- === Theme (samakan dengan hub)
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

local function corner(p,r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,r or 10); c.Parent = p; return c end
local function stroke(p,c,t) local s = Instance.new("UIStroke"); s.Color = c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

-- === Helpers
local function getHRP()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart")
end
local function getHum()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChildOfClass("Humanoid")
end

-- ==== SECTION
local sec = UI.NewSection(UI.Tabs.Menu, "Local Player")

----------------------------------------------------------------------
-- WalkSpeed : Slider + Box
----------------------------------------------------------------------
local wsRow = Instance.new("Frame")
wsRow.BackgroundColor3 = Theme.card
wsRow.Size = UDim2.new(1,0,0,60)
wsRow.Parent = sec
corner(wsRow,10); stroke(wsRow,Theme.accA,1).Transparency=.6

local pad = Instance.new("UIPadding", wsRow)
pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0,10), UDim.new(0,10), UDim.new(0,10), UDim.new(0,10)

local wsLayout = Instance.new("UIListLayout", wsRow)
wsLayout.FillDirection = Enum.FillDirection.Horizontal
wsLayout.Padding = UDim.new(0,10)
wsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

-- label kiri
local wsLabel = Instance.new("TextLabel")
wsLabel.BackgroundTransparency = 1
wsLabel.Text = "WalkSpeed"
wsLabel.Font = Enum.Font.GothamSemibold
wsLabel.TextSize = 16
wsLabel.TextColor3 = Theme.text
wsLabel.TextXAlignment = Enum.TextXAlignment.Left
wsLabel.Size = UDim2.new(0,110,1,0)
wsLabel.Parent = wsRow

-- slider bar
local bar = Instance.new("Frame")
bar.BackgroundColor3 = Theme.bg
bar.Size = UDim2.new(1,-(110+100+20),0,12) -- sisa utk label & box
bar.Parent = wsRow
corner(bar,6); stroke(bar,Theme.accA,1).Transparency=.5
local fill = Instance.new("Frame")
fill.BackgroundColor3 = Theme.accA
fill.Size = UDim2.new(0,0,1,0)
fill.Parent = bar
corner(fill,6)

local knob = Instance.new("Frame")
knob.BackgroundColor3 = Theme.accB
knob.Size = UDim2.fromOffset(18,18)
knob.Position = UDim2.new(0, -9, 0.5, -9)
knob.Parent = bar
corner(knob,9)

-- box angka
local wsBox = Instance.new("TextBox")
wsBox.BackgroundColor3 = Theme.card
wsBox.TextColor3 = Theme.text
wsBox.PlaceholderText = "16"
wsBox.PlaceholderColor3 = Theme.text2
wsBox.ClearTextOnFocus = false
wsBox.Font = Enum.Font.Gotham
wsBox.TextSize = 14
wsBox.Text = ""
wsBox.TextXAlignment = Enum.TextXAlignment.Center
wsBox.Size = UDim2.new(0,100,0,34)
wsBox.Parent = wsRow
corner(wsBox,8); stroke(wsBox,Theme.accA,1).Transparency=.5

-- state & functions
local WS_MIN, WS_MAX = 0, 100
local targetWS = 16

local function applyWS(v)
  targetWS = math.clamp(math.floor(v+0.5), WS_MIN, WS_MAX)
  fill.Size   = UDim2.new((targetWS-WS_MIN)/(WS_MAX-WS_MIN),0,1,0)
  knob.Position = UDim2.new((targetWS-WS_MIN)/(WS_MAX-WS_MIN),-9,0.5,-9)
  wsBox.Text = tostring(targetWS)

  local hum = getHum()
  if hum then hum.WalkSpeed = targetWS end
end

-- init from humanoid
local hum = getHum()
if hum then targetWS = hum.WalkSpeed end
applyWS(targetWS)

LP.CharacterAdded:Connect(function()
  task.wait(0.2)
  local h = getHum()
  if h then h.WalkSpeed = targetWS end
end)

-- slider interaction
do
  local dragging=false
  bar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
      dragging=true
      i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
      local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
      applyWS(WS_MIN + rel*(WS_MAX-WS_MIN))
    end
  end)
end

wsBox.FocusLost:Connect(function()
  local v = tonumber(wsBox.Text)
  if not v then wsBox.Text=tostring(targetWS) return end
  applyWS(v)
end)

----------------------------------------------------------------------
-- Toggles row : Infinite Jump + Fly
----------------------------------------------------------------------
local togglesRow = Instance.new("Frame")
togglesRow.BackgroundColor3 = Theme.card
togglesRow.Size = UDim2.new(1,0,0,46)
togglesRow.Parent = sec
corner(togglesRow,10); stroke(togglesRow,Theme.accA,1).Transparency=.6

local toLay = Instance.new("UIListLayout", togglesRow)
toLay.FillDirection = Enum.FillDirection.Horizontal
toLay.Padding = UDim.new(0,10)
toLay.VerticalAlignment = Enum.VerticalAlignment.Center

local function mkToggle(text)
  local b = Instance.new("TextButton")
  b.AutoButtonColor=false
  b.Text = text..": OFF"
  b.Font = Enum.Font.GothamSemibold
  b.TextSize = 14
  b.TextColor3 = Theme.text
  b.BackgroundColor3 = Theme.card
  b.Size = UDim2.new(.5,-5,1,0)
  b.Parent = togglesRow
  corner(b,8); stroke(b,Theme.accA,1).Transparency=.5
  return b
end

-- Infinite Jump
local infBtn = mkToggle("Infinite Jump")
local infConn, infDebounce = nil, false
local infOn = false
local function setInf(on)
  infOn = on and true or false
  if infConn then infConn:Disconnect(); infConn=nil end
  if infOn then
    infConn = UIS.JumpRequest:Connect(function()
      if not infDebounce then
        infDebounce = true
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        task.wait()
        infDebounce = false
      end
    end)
  end
  infBtn.Text = "Infinite Jump: "..(infOn and "ON" or "OFF")
  infBtn.BackgroundColor3 = infOn and Theme.accA or Theme.card
end
infBtn.MouseButton1Click:Connect(function() setInf(not infOn) end)

-- Fly
local flyBtn = mkToggle("Fly")
local flyOn = false
local flyConn; local gyro, vel
local FLY_SPEED = 55

local function stopFly()
  flyOn = false
  if flyConn then flyConn:Disconnect(); flyConn=nil end
  if gyro then gyro:Destroy(); gyro=nil end
  if vel then vel:Destroy(); vel=nil end
  flyBtn.Text = "Fly: OFF"; flyBtn.BackgroundColor3 = Theme.card
end

local function startFly()
  local hrp = getHRP(); local h = getHum()
  if not hrp or not h then return end
  flyOn = true
  gyro = Instance.new("BodyGyro"); gyro.P = 9e4; gyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
  gyro.CFrame = workspace.CurrentCamera and workspace.CurrentCamera.CFrame or hrp.CFrame
  gyro.Parent = hrp

  vel = Instance.new("BodyVelocity"); vel.MaxForce = Vector3.new(9e9,9e9,9e9); vel.Velocity = Vector3.zero
  vel.Parent = hrp

  flyConn = RS.RenderStepped:Connect(function()
    if not hrp or not hrp.Parent then stopFly() return end
    local cam = workspace.CurrentCamera
    local dir = Vector3.new()
    -- gunakan arah kamera + MoveDirection player (mobile friendly)
    local move = h.MoveDirection
    if cam then
      -- proyeksi ke bidang horizontal, lalu scale dg move magnitude
      local look = cam.CFrame.LookVector
      local right = cam.CFrame.RightVector
      local horizLook = Vector3.new(look.X,0,look.Z).Unit
      local horizRight = Vector3.new(right.X,0,right.Z).Unit
      local xz = (horizLook * move.Z) + (horizRight * move.X)
      dir = (xz + Vector3.new(0, move.Y, 0))
    else
      dir = move
    end
    vel.Velocity = dir * FLY_SPEED
    gyro.CFrame = cam and cam.CFrame or hrp.CFrame
  end)

  flyBtn.Text = "Fly: ON"; flyBtn.BackgroundColor3 = Theme.accA
end

flyBtn.MouseButton1Click:Connect(function()
  if flyOn then stopFly() else startFly() end
end)

LP.CharacterAdded:Connect(function()
  if flyOn then task.wait(0.2); startFly() end
  if infOn then setInf(true) end
end)

----------------------------------------------------------------------
-- ESP Player (Highlight + NameTag)
----------------------------------------------------------------------
local espRow = Instance.new("Frame")
espRow.BackgroundColor3 = Theme.card
espRow.Size = UDim2.new(1,0,0,46)
espRow.Parent = sec
corner(espRow,10); stroke(espRow,Theme.accA,1).Transparency=.6

local espBtn = Instance.new("TextButton")
espBtn.AutoButtonColor=false
espBtn.Text="ESP Player: OFF"
espBtn.Font=Enum.Font.GothamSemibold
espBtn.TextSize=14
espBtn.TextColor3=Theme.text
espBtn.BackgroundColor3=Theme.card
espBtn.Size=UDim2.new(1,0,1,0)
espBtn.Parent=espRow
corner(espBtn,8); stroke(espBtn,Theme.accA,1).Transparency=.5

local espOn=false
local espFolder = Instance.new("Folder"); espFolder.Name="danuu_esp_folder"; espFolder.Parent = workspace

local function clearESPForChar(char)
  if not char then return end
  for _,d in ipairs(char:GetChildren()) do
    if d:IsA("BillboardGui") and d.Name=="danuu_name_esp" then d:Destroy() end
    if d:IsA("Highlight") and d.Name=="danuu_esp" then d:Destroy() end
  end
end

local function attachESP(player)
  if not espOn then return end
  if not player.Character then return end
  clearESPForChar(player.Character)

  -- Highlight
  local hl = Instance.new("Highlight")
  hl.Name = "danuu_esp"
  hl.FillTransparency = 1
  hl.OutlineTransparency = 0
  hl.OutlineColor = Theme.accA
  hl.Parent = player.Character

  -- NameTag
  local hrp = player.Character:FindFirstChild("HumanoidRootPart")
  if hrp then
    local bb = Instance.new("BillboardGui")
    bb.Name="danuu_name_esp"; bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,0,0,0); bb.StudsOffset=Vector3.new(0,3.5,0)
    bb.Parent = player.Character
    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency=1; tl.TextColor3=Theme.text; tl.Font=Enum.Font.GothamSemibold; tl.TextSize=14; tl.AnchorPoint=Vector2.new(.5,1)
    tl.Position=UDim2.fromScale(.5,1); tl.Size=UDim2.new(0,260,0,18); tl.Parent=bb
    tl.TextXAlignment=Enum.TextXAlignment.Center

    -- update jarak
    task.spawn(function()
      while espOn and bb.Parent do
        local myHRP = getHRP()
        local dist = (myHRP and hrp) and (myHRP.Position - hrp.Position).Magnitude or 0
        tl.Text = string.format("%s  (%.0f)", player.DisplayName or player.Name, dist)
        task.wait(0.25)
      end
    end)
  end
end

local function applyESPAll()
  espFolder:ClearAllChildren()
  for _,pl in ipairs(Players:GetPlayers()) do
    if pl ~= LP then
      attachESP(pl)
      pl.CharacterAdded:Connect(function()
        if espOn then task.wait(0.2); attachESP(pl) end
      end)
    end
  end
end

local function removeESPAll()
  for _,pl in ipairs(Players:GetPlayers()) do
    if pl.Character then clearESPForChar(pl.Character) end
  end
end

espBtn.MouseButton1Click:Connect(function()
  espOn = not espOn
  espBtn.Text = "ESP Player: "..(espOn and "ON" or "OFF")
  espBtn.BackgroundColor3 = espOn and Theme.accA or Theme.card
  if espOn then
    applyESPAll()
    Players.PlayerAdded:Connect(function(pl)
      if espOn then pl.CharacterAdded:Connect(function() task.wait(0.2); attachESP(pl) end) end
    end)
  else
    removeESPAll()
  end
end)

-- done

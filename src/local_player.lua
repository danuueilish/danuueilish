-- src/local_player.lua
-- Local Player (WalkSpeed • Infinite Jump • Fly (IY style) • ESP Player)

local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu or not UI.NewSection then return end

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")

local LP = Players.LocalPlayer

-- Theme selaras hub
local Theme = {
  bg    = Color3.fromRGB(24,20,40),
  card  = Color3.fromRGB(44,36,72),
  text  = Color3.fromRGB(235,230,255),
  text2 = Color3.fromRGB(190,180,220),
  accA  = Color3.fromRGB(125,84,255),
  accB  = Color3.fromRGB(215,55,255),
  good  = Color3.fromRGB(106,212,123),
}

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

local function Hum() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChildOfClass("Humanoid") end
local function HRP() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChild("HumanoidRootPart") end

-- Section
local sec = UI.NewSection(UI.Tabs.Menu, "Local Player")

-- Util: Row "label kiri | kontrol kanan"
local function newSettingRow(height)
  local row=Instance.new("Frame"); row.BackgroundColor3=Theme.card; row.Size=UDim2.new(1,0,0,height or 54); row.Parent=sec
  corner(row,10); stroke(row,Theme.accA,1).Transparency=.6
  local pad=Instance.new("UIPadding",row); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10); pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)
  local lay=Instance.new("UIListLayout",row); lay.FillDirection=Enum.FillDirection.Horizontal; lay.Padding=UDim.new(0,10); lay.VerticalAlignment=Enum.VerticalAlignment.Center
  local left=Instance.new("TextLabel"); left.BackgroundTransparency=1; left.Size=UDim2.new(0,140,1,0); left.Font=Enum.Font.GothamSemibold; left.TextSize=16; left.TextColor3=Theme.text; left.TextXAlignment=Enum.TextXAlignment.Left; left.Parent=row
  local right=Instance.new("Frame"); right.BackgroundTransparency=1; right.Size=UDim2.new(1,-140,1,0); right.Parent=row
  local rlay=Instance.new("UIListLayout",right); rlay.FillDirection=Enum.FillDirection.Horizontal; rlay.Padding=UDim.new(0,10); rlay.VerticalAlignment=Enum.VerticalAlignment.Center; rlay.HorizontalAlignment=Enum.HorizontalAlignment.Right
  return row,left,right
end

----------------------------------------------------------------
-- WalkSpeed: [label] | [slider + box angka]
----------------------------------------------------------------
local _, wsLabel, wsRight = newSettingRow(54); wsLabel.Text = "WalkSpeed"

-- slider bar
local bar = Instance.new("Frame"); bar.BackgroundColor3=Theme.bg; bar.Size=UDim2.new(1,-110,0,12); bar.Parent=wsRight; corner(bar,6); stroke(bar,Theme.accA,1).Transparency=.5
local fill=Instance.new("Frame"); fill.BackgroundColor3=Theme.accA; fill.Size=UDim2.new(0,0,1,0); fill.Parent=bar; corner(fill,6)
local knob=Instance.new("Frame"); knob.BackgroundColor3=Theme.accB; knob.Size=UDim2.fromOffset(18,18); knob.Position=UDim2.new(0,-9,0.5,-9); knob.Parent=bar; corner(knob,9)

-- box angka
local wsBox=Instance.new("TextBox"); wsBox.BackgroundColor3=Theme.card; wsBox.TextColor3=Theme.text; wsBox.Font=Enum.Font.Gotham; wsBox.TextSize=14
wsBox.PlaceholderText="16"; wsBox.PlaceholderColor3=Theme.text2; wsBox.ClearTextOnFocus=false; wsBox.Size=UDim2.new(0,100,0,34); wsBox.TextXAlignment=Enum.TextXAlignment.Center
wsBox.Parent=wsRight; corner(wsBox,8); stroke(wsBox,Theme.accA,1).Transparency=.5

local WS_MIN,WS_MAX=0,100
local targetWS = Hum() and Hum().WalkSpeed or 16
local function applyWS(v)
  targetWS = math.clamp(math.floor(tonumber(v) or targetWS), WS_MIN, WS_MAX)
  local rel=(targetWS-WS_MIN)/(WS_MAX-WS_MIN)
  fill.Size=UDim2.new(rel,0,1,0); knob.Position=UDim2.new(rel,-9,0.5,-9); wsBox.Text=tostring(targetWS)
  local h=Hum(); if h then h.WalkSpeed=targetWS end
end
applyWS(targetWS)
LP.CharacterAdded:Connect(function() task.wait(.2); applyWS(targetWS) end)

do -- drag slider
  local dragging=false
  bar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
      dragging=true; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
      local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
      applyWS(WS_MIN + rel*(WS_MAX-WS_MIN))
    end
  end)
end
wsBox.FocusLost:Connect(function() applyWS(wsBox.Text) end)

----------------------------------------------------------------
-- Infinite Jump: [label] | [ON/OFF]
----------------------------------------------------------------
local _, ijLabel, ijRight = newSettingRow(46); ijLabel.Text = "Infinite Jump"
local ijBtn=Instance.new("TextButton"); ijBtn.Size=UDim2.new(0,160,1,0); ijBtn.AutoButtonColor=false; ijBtn.Font=Enum.Font.GothamSemibold; ijBtn.TextSize=14
ijBtn.TextColor3=Theme.text; ijBtn.Text="OFF"; ijBtn.BackgroundColor3=Theme.card; ijBtn.Parent=ijRight; corner(ijBtn,8); stroke(ijBtn,Theme.accA,1).Transparency=.5

local infConn, infDebounce, infOn
local function setInf(on)
  infOn = on and true or false
  if infConn then infConn:Disconnect(); infConn=nil end
  if infOn then
    infConn = UIS.JumpRequest:Connect(function()
      if not infDebounce then
        infDebounce=true
        local h=Hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        task.wait(); infDebounce=false
      end
    end)
  end
  ijBtn.Text = infOn and "ON" or "OFF"
  ijBtn.BackgroundColor3 = infOn and Theme.accA or Theme.card
end
ijBtn.MouseButton1Click:Connect(function() setInf(not infOn) end)
LP.CharacterAdded:Connect(function() if infOn then setInf(true) end end)

----------------------------------------------------------------
-- Fly (Infinite Yield style): [label] | [ON/OFF]
----------------------------------------------------------------
local _, flyLabel, flyRight = newSettingRow(46); flyLabel.Text = "Fly"
local flyBtn=Instance.new("TextButton"); flyBtn.Size=UDim2.new(0,160,1,0); flyBtn.AutoButtonColor=false; flyBtn.Font=Enum.Font.GothamSemibold; flyBtn.TextSize=14
flyBtn.TextColor3=Theme.text; flyBtn.Text="OFF"; flyBtn.BackgroundColor3=Theme.card; flyBtn.Parent=flyRight; corner(flyBtn,8); stroke(flyBtn,Theme.accA,1).Transparency=.5

local flyOn=false; local flyConn; local gyro,vel
local IY_SPEED = 2       -- kecepatan dasar (nanti dikali 50)
local keys = {W=false,A=false,S=false,D=false,Up=false,Down=false}

local function stopFly()
  flyOn=false
  if flyConn then flyConn:Disconnect(); flyConn=nil end
  if gyro then gyro:Destroy(); gyro=nil end
  if vel then vel:Destroy(); vel=nil end
  flyBtn.Text="OFF"; flyBtn.BackgroundColor3=Theme.card
end

local function startFly()
  local hrp=HRP(); local h=Hum()
  if not hrp or not h then return end
  flyOn=true

  gyro=Instance.new("BodyGyro"); gyro.P=9e4; gyro.MaxTorque=Vector3.new(9e9,9e9,9e9); gyro.CFrame=workspace.CurrentCamera and workspace.CurrentCamera.CFrame or hrp.CFrame; gyro.Parent=hrp
  vel=Instance.new("BodyVelocity"); vel.MaxForce=Vector3.new(9e9,9e9,9e9); vel.Velocity=Vector3.zero; vel.Parent=hrp

  flyConn = RS.RenderStepped:Connect(function()
    if not hrp or not hrp.Parent then stopFly() return end
    local cam = workspace.CurrentCamera
    local cf  = cam and cam.CFrame or hrp.CFrame
    local lv  = cf.LookVector; local rv = cf.RightVector
    local move = Vector3.new()

    -- Keyboard style (IY)
    if keys.W then move += lv end
    if keys.S then move -= lv end
    if keys.A then move -= rv end
    if keys.D then move += rv end
    if keys.Up then move += Vector3.new(0,1,0) end
    if keys.Down then move -= Vector3.new(0,1,0) end

    -- Fallback joystick/mobile (gerak karakter)
    local md = h.MoveDirection
    if move.Magnitude < 0.01 and md.Magnitude>0 then
      local horizLook = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
      local horizRight= Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
      move = (horizLook*md.Z) + (horizRight*md.X) + Vector3.new(0,md.Y,0)
    end

    if move.Magnitude>0 then move=move.Unit end
    vel.Velocity = move * (IY_SPEED * 50)
    gyro.CFrame  = cf
  end)

  flyBtn.Text="ON"; flyBtn.BackgroundColor3=Theme.accA
end

-- input handler ala IY
UIS.InputBegan:Connect(function(i,gp)
  if gp then return end
  local kc=i.KeyCode
  if kc==Enum.KeyCode.W then keys.W=true
  elseif kc==Enum.KeyCode.A then keys.A=true
  elseif kc==Enum.KeyCode.S then keys.S=true
  elseif kc==Enum.KeyCode.D then keys.D=true
  elseif kc==Enum.KeyCode.Space then keys.Up=true
  elseif kc==Enum.KeyCode.LeftControl or kc==Enum.KeyCode.LeftShift then keys.Down=true
  elseif kc==Enum.KeyCode.E then IY_SPEED = math.clamp(IY_SPEED+0.5, 1, 6)
  elseif kc==Enum.KeyCode.Q then IY_SPEED = math.clamp(IY_SPEED-0.5, 1, 6)
  end
end)
UIS.InputEnded:Connect(function(i)
  local kc=i.KeyCode
  if kc==Enum.KeyCode.W then keys.W=false
  elseif kc==Enum.KeyCode.A then keys.A=false
  elseif kc==Enum.KeyCode.S then keys.S=false
  elseif kc==Enum.KeyCode.D then keys.D=false
  elseif kc==Enum.KeyCode.Space then keys.Up=false
  elseif kc==Enum.KeyCode.LeftControl or kc==Enum.KeyCode.LeftShift then keys.Down=false
  end
end)

flyBtn.MouseButton1Click:Connect(function() if flyOn then stopFly() else startFly() end end)
LP.CharacterAdded:Connect(function() if flyOn then task.wait(.2); startFly() end end)

----------------------------------------------------------------
-- ESP Player: Highlight + NameTag + Jarak
----------------------------------------------------------------
local _, espLabel, espRight = newSettingRow(46); espLabel.Text = "ESP Player"
local espBtn=Instance.new("TextButton"); espBtn.Size=UDim2.new(0,160,1,0); espBtn.AutoButtonColor=false; espBtn.Font=Enum.Font.GothamSemibold; espBtn.TextSize=14
espBtn.TextColor3=Theme.text; espBtn.Text="OFF"; espBtn.BackgroundColor3=Theme.card; espBtn.Parent=espRight; corner(espBtn,8); stroke(espBtn,Theme.accA,1).Transparency=.5

local espOn=false
local function clearESP(char)
  if not char then return end
  for _,d in ipairs(char:GetChildren()) do
    if (d:IsA("BillboardGui") and d.Name=="danuu_name_esp") or (d:IsA("Highlight") and d.Name=="danuu_esp") then d:Destroy() end
  end
end
local function addESP(plr)
  if not espOn then return end
  local ch = plr.Character
  if not ch then return end
  clearESP(ch)

  local hl = Instance.new("Highlight"); hl.Name="danuu_esp"; hl.FillTransparency=1; hl.OutlineTransparency=0; hl.OutlineColor=Theme.accA; hl.Parent=ch

  local hrp = ch:FindFirstChild("HumanoidRootPart")
  if not hrp then return end
  local bb = Instance.new("BillboardGui")
  bb.Name="danuu_name_esp"; bb.AlwaysOnTop=true; bb.MaxDistance=2000; bb.ExtentsOffsetWorldSpace=Vector3.new(0,3.3,0)
  bb.Size=UDim2.new(0,0,0,0); bb.Parent=ch

  local holder = Instance.new("Frame"); holder.BackgroundTransparency=1; holder.Size=UDim2.new(0,260,0,36); holder.AnchorPoint=Vector2.new(.5,1); holder.Position=UDim2.fromScale(.5,1); holder.Parent=bb
  local nameL = Instance.new("TextLabel"); nameL.BackgroundTransparency=1; nameL.Font=Enum.Font.GothamSemibold; nameL.TextSize=14; nameL.TextXAlignment=Enum.TextXAlignment.Center; nameL.TextColor3=Theme.text
  nameL.Position=UDim2.new(0,0,0,0); nameL.Size=UDim2.new(1,0,0,18); nameL.Parent=holder
  local distL = Instance.new("TextLabel"); distL.BackgroundTransparency=1; distL.Font=Enum.Font.Gotham; distL.TextSize=13; distL.TextXAlignment=Enum.TextXAlignment.Center; distL.TextColor3=Theme.text2
  distL.Position=UDim2.new(0,0,0,18); distL.Size=UDim2.new(1,0,0,18); distL.Parent=holder

  task.spawn(function()
    while espOn and ch.Parent and bb.Parent do
      nameL.Text = string.format("%s (%s)", plr.DisplayName or plr.Name, plr.Name)
      local my = HRP()
      local d = (my and hrp) and (my.Position - hrp.Position).Magnitude or 0
      distL.Text = string.format("%.0f studs", d)
      task.wait(0.2)
    end
  end)
end

local function enableESP()
  espOn=true
  espBtn.Text="ON"; espBtn.BackgroundColor3=Theme.accA
  for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP then
      addESP(p)
      p.CharacterAdded:Connect(function() if espOn then task.wait(.2); addESP(p) end end)
    end
  end
  Players.PlayerAdded:Connect(function(p)
    if espOn then p.CharacterAdded:Connect(function() task.wait(.2); addESP(p) end) end
  end)
end
local function disableESP()
  espOn=false
  espBtn.Text="OFF"; espBtn.BackgroundColor3=Theme.card
  for _,p in ipairs(Players:GetPlayers()) do if p.Character then clearESP(p.Character) end end
end
espBtn.MouseButton1Click:Connect(function() if espOn then disableESP() else enableESP() end end)
LP.CharacterRemoving:Connect(function() -- bersihkan highlight di dirimu sendiri kalau ada
  local ch = LP.Character
  if ch then clearESP(ch) end
end)

-- src/local_player.lua
-- Local Player: Kecepatan Jalan • Lompatan Tak Terbatas • Terbang (gaya IY, mobile OK) • ESP Pemain

local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu or not UI.NewSection then return end

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")

local LP = Players.LocalPlayer

-- ==== Tema (samakan dengan hub)
local Theme = {
  bg    = Color3.fromRGB(24,20,40),
  card  = Color3.fromRGB(44,36,72),
  text  = Color3.fromRGB(235,230,255),
  text2 = Color3.fromRGB(190,180,220),
  accA  = Color3.fromRGB(125,84,255),
  accB  = Color3.fromRGB(215,55,255),
}

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

local function Hum() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChildOfClass("Humanoid") end
local function HRP() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChild("HumanoidRootPart") end

-- ==== Section
local sec = UI.NewSection(UI.Tabs.Menu, "Local Player")

-- ==== Baris helper (label kiri | kontrol kanan)
local function newRow(height)
  local row=Instance.new("Frame"); row.BackgroundColor3=Theme.card; row.Size=UDim2.new(1,0,0,height or 54); row.Parent=sec
  corner(row,10); stroke(row,Theme.accA,1).Transparency=.6
  local pd=Instance.new("UIPadding",row); pd.PaddingLeft=UDim.new(0,10); pd.PaddingRight=UDim.new(0,10); pd.PaddingTop=UDim.new(0,8); pd.PaddingBottom=UDim.new(0,8)
  local lay=Instance.new("UIListLayout",row); lay.FillDirection=Enum.FillDirection.Horizontal; lay.Padding=UDim.new(0,10); lay.VerticalAlignment=Enum.VerticalAlignment.Center

  local left=Instance.new("TextLabel")
  left.BackgroundTransparency=1; left.Size=UDim2.new(0,150,1,0)
  left.Font=Enum.Font.GothamSemibold; left.TextSize=16; left.TextXAlignment=Enum.TextXAlignment.Left; left.TextColor3=Theme.text
  left.Parent=row

  local right=Instance.new("Frame")
  right.BackgroundTransparency=1; right.Size=UDim2.new(1,-150,1,0); right.Parent=row
  local rlay=Instance.new("UIListLayout",right)
  rlay.FillDirection=Enum.FillDirection.Horizontal; rlay.Padding=UDim.new(0,10)
  rlay.VerticalAlignment=Enum.VerticalAlignment.Center; rlay.HorizontalAlignment=Enum.HorizontalAlignment.Right

  return row,left,right
end

----------------------------------------------------------------
-- Kecepatan Jalan : [Kecepatan Jalan] [slider + kotak angka]
----------------------------------------------------------------
local _, wsLeft, wsRight = newRow(54); wsLeft.Text = "Kecepatan Jalan"

local sliderBar = Instance.new("Frame")
sliderBar.BackgroundColor3=Theme.bg; sliderBar.Size=UDim2.new(1,-106,0,12); sliderBar.Parent=wsRight
corner(sliderBar,6); stroke(sliderBar,Theme.accA,1).Transparency=.5

local sliderFill=Instance.new("Frame"); sliderFill.BackgroundColor3=Theme.accA; sliderFill.Size=UDim2.new(0,0,1,0); sliderFill.Parent=sliderBar; corner(sliderFill,6)
local sliderKnob=Instance.new("Frame"); sliderKnob.BackgroundColor3=Theme.accB; sliderKnob.Size=UDim2.fromOffset(18,18); sliderKnob.Position=UDim2.new(0,-9,0.5,-9); sliderKnob.Parent=sliderBar; corner(sliderKnob,9)

local wsBox=Instance.new("TextBox")
wsBox.Size=UDim2.new(0,96,0,34); wsBox.BackgroundColor3=Theme.card; wsBox.TextColor3=Theme.text; wsBox.Font=Enum.Font.Gotham
wsBox.TextSize=14; wsBox.ClearTextOnFocus=false; wsBox.Text="16"; wsBox.TextXAlignment=Enum.TextXAlignment.Center; wsBox.Parent=wsRight
corner(wsBox,8); stroke(wsBox,Theme.accA,1).Transparency=.5

local WS_MIN,WS_MAX=8,200
local targetWS = (Hum() and Hum().WalkSpeed) or 16

local function applyWS(v)
  targetWS = math.clamp(math.floor(tonumber(v) or targetWS), WS_MIN, WS_MAX)
  local rel=(targetWS-WS_MIN)/(WS_MAX-WS_MIN)
  sliderFill.Size=UDim2.new(rel,0,1,0)
  sliderKnob.Position=UDim2.new(rel,-9,0.5,-9)
  wsBox.Text=tostring(targetWS)
  local h=Hum(); if h then h.WalkSpeed=targetWS end
end
applyWS(targetWS)
LP.CharacterAdded:Connect(function() task.wait(.2); applyWS(targetWS) end)

do -- drag slider
  local dragging=false
  sliderBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
      dragging=true; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
      local rel = math.clamp((i.Position.X - sliderBar.AbsolutePosition.X)/sliderBar.AbsoluteSize.X,0,1)
      applyWS(WS_MIN + rel*(WS_MAX-WS_MIN))
    end
  end)
end
wsBox.FocusLost:Connect(function() applyWS(wsBox.Text) end)

----------------------------------------------------------------
-- Lompatan Tak Terbatas : [Lompatan Tak Terbatas] [ON/OFF]
----------------------------------------------------------------
local _, ijLeft, ijRight = newRow(46); ijLeft.Text = "Lompatan Tak Terbatas"
local ijBtn=Instance.new("TextButton"); ijBtn.Size=UDim2.new(0,160,1,0); ijBtn.AutoButtonColor=false
ijBtn.Font=Enum.Font.GothamSemibold; ijBtn.TextSize=14; ijBtn.TextColor3=Theme.text; ijBtn.BackgroundColor3=Theme.card; ijBtn.Text="OFF"; ijBtn.Parent=ijRight
corner(ijBtn,8); stroke(ijBtn,Theme.accA,1).Transparency=.5

local infConn, infDebounce, infOn=false,false,false
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
-- Terbang (gaya IY, mobile bersahabat) : [Terbang] [ON/OFF]
----------------------------------------------------------------
local _, flyLeft, flyRight = newRow(46); flyLeft.Text = "Terbang"
local flyBtn=Instance.new("TextButton"); flyBtn.Size=UDim2.new(0,160,1,0); flyBtn.AutoButtonColor=false
flyBtn.Font=Enum.Font.GothamSemibold; flyBtn.TextSize=14; flyBtn.TextColor3=Theme.text; flyBtn.BackgroundColor3=Theme.card; flyBtn.Text="OFF"; flyBtn.Parent=flyRight
corner(flyBtn,8); stroke(flyBtn,Theme.accA,1).Transparency=.5

local flyOn=false; local flyConn; local gyro,vel
local keys={W=false,A=false,S=false,D=false,Up=false,Down=false}
local FLY_SPEED=2  -- E tambah, Q kurang (1..6)

local function stopFly()
  flyOn=false
  if flyConn then flyConn:Disconnect(); flyConn=nil end
  if gyro then gyro:Destroy(); gyro=nil end
  if vel  then vel:Destroy();  vel=nil end
  local h=Hum(); if h then h.PlatformStand=false end
  flyBtn.Text="OFF"; flyBtn.BackgroundColor3=Theme.card
end

local function startFly()
  local hrp=HRP(); local h=Hum()
  if not hrp or not h then return end
  flyOn=true

  gyro=Instance.new("BodyGyro"); gyro.P=9e4; gyro.MaxTorque=Vector3.new(9e9,9e9,9e9); gyro.CFrame=(workspace.CurrentCamera and workspace.CurrentCamera.CFrame) or hrp.CFrame; gyro.Parent=hrp
  vel=Instance.new("BodyVelocity"); vel.MaxForce=Vector3.new(9e9,9e9,9e9); vel.Velocity=Vector3.zero; vel.Parent=hrp
  h.PlatformStand = true

  flyConn = RS.RenderStepped:Connect(function(dt)
    if not flyOn or not hrp.Parent then stopFly() return end
    local cam = workspace.CurrentCamera
    local cf  = cam and cam.CFrame or hrp.CFrame

    -- Arah keyboard
    local look, right = cf.LookVector, cf.RightVector
    local move = Vector3.new()
    if keys.W then move += look end
    if keys.S then move -= look end
    if keys.A then move -= right end
    if keys.D then move += right end
    if keys.Up then move += Vector3.new(0,1,0) end
    if keys.Down then move -= Vector3.new(0,1,0) end

    -- Arah analog mobile: Humanoid.MoveDirection (mengikuti kamera)
    local h = Hum()
    local md = h and h.MoveDirection or Vector3.zero
    if md.Magnitude>0 then
      local horizLook  = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
      local horizRight = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
      move = (horizLook*md.Z) + (horizRight*md.X) + Vector3.new(0, md.Y, 0)
    end

    if move.Magnitude>0 then move=move.Unit end
    vel.Velocity = move * (FLY_SPEED * 50)  -- halus & dt-aware
    gyro.CFrame  = cf
  end)

  flyBtn.Text="ON"; flyBtn.BackgroundColor3=Theme.accA
end

-- keyboard handler
UIS.InputBegan:Connect(function(i,gp)
  if gp then return end
  local k=i.KeyCode
  if   k==Enum.KeyCode.W then keys.W=true
  elseif k==Enum.KeyCode.A then keys.A=true
  elseif k==Enum.KeyCode.S then keys.S=true
  elseif k==Enum.KeyCode.D then keys.D=true
  elseif k==Enum.KeyCode.Space then keys.Up=true
  elseif k==Enum.KeyCode.LeftControl or k==Enum.KeyCode.LeftShift then keys.Down=true
  elseif k==Enum.KeyCode.E then FLY_SPEED = math.clamp(FLY_SPEED+0.5,1,6)
  elseif k==Enum.KeyCode.Q then FLY_SPEED = math.clamp(FLY_SPEED-0.5,1,6)
  end
end)
UIS.InputEnded:Connect(function(i)
  local k=i.KeyCode
  if   k==Enum.KeyCode.W then keys.W=false
  elseif k==Enum.KeyCode.A then keys.A=false
  elseif k==Enum.KeyCode.S then keys.S=false
  elseif k==Enum.KeyCode.D then keys.D=false
  elseif k==Enum.KeyCode.Space then keys.Up=false
  elseif k==Enum.KeyCode.LeftControl or k==Enum.KeyCode.LeftShift then keys.Down=false
  end
end)

flyBtn.MouseButton1Click:Connect(function() if flyOn then stopFly() else startFly() end end)
LP.CharacterAdded:Connect(function() if flyOn then task.wait(.2); startFly() end end)

----------------------------------------------------------------
-- ESP Pemain (Highlight + Nama + Jarak)
----------------------------------------------------------------
local _, espLeft, espRight = newRow(54); espLeft.Text = "ESP Pemain"
local espBtn=Instance.new("TextButton"); espBtn.Size=UDim2.new(0,160,1,0); espBtn.AutoButtonColor=false
espBtn.Font=Enum.Font.GothamSemibold; espBtn.TextSize=14; espBtn.TextColor3=Theme.text; espBtn.BackgroundColor3=Theme.card; espBtn.Text="OFF"; espBtn.Parent=espRight
corner(espBtn,8); stroke(espBtn,Theme.accA,1).Transparency=.5

local espOn=false
local addedConns = {}

local function clearESP(char)
  if not char then return end
  for _,d in ipairs(char:GetChildren()) do
    if (d:IsA("BillboardGui") and d.Name=="danuu_name_esp") or (d:IsA("Highlight") and d.Name=="danuu_esp") then d:Destroy() end
  end
end

local function addESP(plr)
  if not espOn or plr==LP then return end
  local ch = plr.Character
  if not ch then return end
  clearESP(ch)

  local hl = Instance.new("Highlight")
  hl.Name="danuu_esp"; hl.FillTransparency=1; hl.OutlineTransparency=0; hl.OutlineColor=Theme.accA; hl.Parent=ch

  local hrp = ch:FindFirstChild("HumanoidRootPart")
  if not hrp then return end

  local bb = Instance.new("BillboardGui")
  bb.Name="danuu_name_esp"; bb.Adornee=hrp; bb.AlwaysOnTop=true
  bb.Size=UDim2.new(0,160,0,32)           -- lebih ramping
  bb.StudsOffsetWorldSpace = Vector3.new(0,3.2,0)
  bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  bb.Parent = ch

  local bg = Instance.new("Frame", bb)
  bg.BackgroundTransparency=.15; bg.BackgroundColor3=Theme.card; bg.Size=UDim2.fromScale(1,1)
  corner(bg,6); stroke(bg,Theme.accA,1).Transparency=.25

  local nameL = Instance.new("TextLabel")
  nameL.BackgroundTransparency=1; nameL.Size=UDim2.new(1,-6,0,16); nameL.Position=UDim2.fromOffset(3,2)
  nameL.Font=Enum.Font.GothamSemibold; nameL.TextSize=13; nameL.TextColor3=Theme.text; nameL.TextXAlignment=Enum.TextXAlignment.Center
  nameL.Parent=bg

  local distL = Instance.new("TextLabel")
  distL.BackgroundTransparency=1; distL.Size=UDim2.new(1,-6,0,12); distL.Position=UDim2.fromOffset(3,18)
  distL.Font=Enum.Font.Gotham; distL.TextSize=12; distL.TextColor3=Theme.text2; distL.TextXAlignment=Enum.TextXAlignment.Center
  distL.Parent=bg

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

local function hookPlayer(p)
  addedConns[p] = p.CharacterAdded:Connect(function()
    if espOn then task.wait(.2); addESP(p) end
  end)
  if p.Character then addESP(p) end
end
local function unhookAll()
  for p,cn in pairs(addedConns) do if cn then cn:Disconnect() end end
  table.clear(addedConns)
  for _,p in ipairs(Players:GetPlayers()) do if p.Character then clearESP(p.Character) end end
end

local function enableESP()
  espOn=true; espBtn.Text="ON"; espBtn.BackgroundColor3=Theme.accA
  for _,p in ipairs(Players:GetPlayers()) do if p~=LP then hookPlayer(p) end end
  addedConns["_PlayerAdded"] = Players.PlayerAdded:Connect(function(p) if espOn then hookPlayer(p) end end)
  addedConns["_PlayerRemoving"] = Players.PlayerRemoving:Connect(function(p) if addedConns[p] then addedConns[p]:Disconnect(); addedConns[p]=nil end end)
end
local function disableESP()
  espOn=false; espBtn.Text="OFF"; espBtn.BackgroundColor3=Theme.card
  unhookAll()
end
espBtn.MouseButton1Click:Connect(function() if espOn then disableESP() else enableESP() end end)

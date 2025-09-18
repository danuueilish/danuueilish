-- local_player.lua (Super Clean Layout, seperti home.lua, RAPIH)
local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu or not UI.NewSection then return end

local Players, UIS, RS = game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP = Players.LocalPlayer

local Theme = {
  bg    = Color3.fromRGB(24,20,40),
  card  = Color3.fromRGB(44,36,72),
  text  = Color3.fromRGB(235,230,255),
  text2 = Color3.fromRGB(190,180,220),
  accA  = Color3.fromRGB(125,84,255),
  accB  = Color3.fromRGB(215,55,255),
}

local function corner(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke") s.Color=c or Color3.new(1,1,1) s.Thickness=t or 1 s.Transparency=.5 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end

local secRoot = UI.NewSection(UI.Tabs.Menu, "Local Player")
local content = Instance.new("Frame")
content.Size = UDim2.new(1,-8,1,0)
content.Position = UDim2.fromOffset(4,8)
content.BackgroundTransparency = 1
content.Parent = secRoot

local layout = Instance.new("UIListLayout",content)
layout.Padding = UDim.new(0,8)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function newRow(h)
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1,0,0,h or 34)
  row.BackgroundColor3 = Theme.card
  row.Parent = content
  corner(row,8); stroke(row,Theme.accA,1).Transparency=.35
  local lay = Instance.new("UIListLayout",row)
  lay.FillDirection = Enum.FillDirection.Horizontal
  lay.VerticalAlignment = Enum.VerticalAlignment.Center
  lay.Padding = UDim.new(0,8)
  -- LEFT-labeled
  local label = Instance.new("TextLabel")
  label.Size = UDim2.new(0,102,1,0)
  label.BackgroundTransparency = 1
  label.Font = Enum.Font.GothamSemibold
  label.TextXAlignment = Enum.TextXAlignment.Left
  label.TextSize = 14
  label.TextColor3 = Theme.text
  label.Text = ""
  label.Parent = row
  -- RIGHT container
  local right = Instance.new("Frame")
  right.BackgroundTransparency = 1
  right.Size = UDim2.new(1,-102,1,0)
  right.Parent = row
  return row, label, right
end

-- WalkSpeed
local _, wsLabel, wsRight = newRow(34)
wsLabel.Text = "Walk Speed"
local wsSlider = Instance.new("Frame")
wsSlider.BackgroundColor3 = Theme.bg
wsSlider.Size = UDim2.new(1,-50,0,7)
wsSlider.Parent = wsRight
corner(wsSlider,3); stroke(wsSlider,Theme.accA,1).Transparency=.21
local wsFill = Instance.new("Frame", wsSlider)
wsFill.BackgroundColor3 = Theme.accA
wsFill.Size = UDim2.new(0,0,1,0)
corner(wsFill, 3)
local wsKnob = Instance.new("Frame", wsSlider)
wsKnob.BackgroundColor3 = Theme.accB
wsKnob.Size = UDim2.fromOffset(10,10)
wsKnob.Position = UDim2.new(0,-5,0.5,-5)
corner(wsKnob,5)
local wsBox = Instance.new("TextBox")
wsBox.Size = UDim2.new(0,36,0,20)
wsBox.BackgroundColor3 = Theme.card
wsBox.TextColor3 = Theme.text
wsBox.Font = Enum.Font.Gotham
wsBox.TextSize = 12
wsBox.ClearTextOnFocus = false
wsBox.Text = "16"
wsBox.TextXAlignment = Enum.TextXAlignment.Center
wsBox.Parent = wsRight
corner(wsBox,4); stroke(wsBox,Theme.accA,1).Transparency=.16
local WS_MIN, WS_MAX, wsTarget = 0,100,16
local function Hum()return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function applyWS(v)local t=math.clamp(tonumber(v) or wsTarget,WS_MIN,WS_MAX)wsTarget=t;local r=(t-WS_MIN)/math.max(1,(WS_MAX-WS_MIN))wsFill.Size=UDim2.new(r,0,1,0)wsKnob.Position=UDim2.new(r,-5,0.5,-5)wsBox.Text=tostring(t)local h=Hum()if h then h.WalkSpeed=t end end
applyWS(wsTarget)
LP.CharacterAdded:Connect(function() task.wait(.21); applyWS(wsTarget) end)
do local dragging=false;local function setFromX(x)local r=math.clamp((x-wsSlider.AbsolutePosition.X)/math.max(1,wsSlider.AbsoluteSize.X),0,1)applyWS(WS_MIN+r*(WS_MAX-WS_MIN))end;wsSlider.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;setFromX(i.Position.X)i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then dragging=false end end)end end)UIS.InputChanged:Connect(function(i)if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then setFromX(i.Position.X)end end)end
wsBox.FocusLost:Connect(function()applyWS(wsBox.Text)end)

-- Infinite Jump
local _,ijLabel,ijRight = newRow(34)
ijLabel.Text = "Infinite Jump"
local ijBtn=Instance.new("TextButton")
ijBtn.Size=UDim2.new(0,45,1,0)
ijBtn.Font=Enum.Font.GothamSemibold
ijBtn.TextSize=13
ijBtn.TextColor3=Theme.text
ijBtn.BackgroundColor3=Theme.card
ijBtn.Text="OFF"
ijBtn.Parent=ijRight
corner(ijBtn,5); stroke(ijBtn,Theme.accA,1).Transparency=.16
local ijOn, ijConn, ijDebounce = false
local function setInf(on)
  ijOn=on and true or false
  if ijConn then ijConn:Disconnect(); ijConn=nil end
  if ijOn then
    ijConn = UIS.JumpRequest:Connect(function()
      if not ijDebounce then ijDebounce=true;local h=Hum();if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end;task.wait();ijDebounce=false end
    end)
  end
  ijBtn.Text, ijBtn.BackgroundColor3 = ijOn and "ON" or "OFF", ijOn and Theme.accA or Theme.card
end
ijBtn.MouseButton1Click:Connect(function() setInf(not ijOn) end)
LP.CharacterAdded:Connect(function() if ijOn then setInf(true) end end)

-- FLY
local _,flyLabel,flyRight=newRow(34)
flyLabel.Text="Fly Mode"
local flyBtn=Instance.new("TextButton")
flyBtn.Size=UDim2.new(0,45,1,0)
flyBtn.Font=Enum.Font.GothamSemibold
flyBtn.TextSize=13
flyBtn.TextColor3=Theme.text
flyBtn.BackgroundColor3=Theme.card
flyBtn.Text="OFF"
flyBtn.Parent=flyRight
corner(flyBtn,5); stroke(flyBtn,Theme.accA,1).Transparency=.16
local flyOn,flyConn,gyro,vel=false
local keys={W=false,A=false,S=false,D=false,Up=false,Down=false}
local FLY_SPEED=2
local function HRP()return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")end
local function stopFly() flyOn=false;if flyConn then flyConn:Disconnect();flyConn=nil end;if gyro then gyro:Destroy();gyro=nil end;if vel then vel:Destroy();vel=nil end;flyBtn.Text,flyBtn.BackgroundColor3 = "OFF", Theme.card;local h=Hum();if h then h.PlatformStand=false end end
local function startFly()
  local hrp=HRP();local h=Hum();if not hrp or not h then return end
  flyOn=true;h.PlatformStand=true
  gyro,vel=Instance.new("BodyGyro"),Instance.new("BodyVelocity")
  gyro.P=9000;gyro.MaxTorque=Vector3.new(9e9,9e9,9e9);gyro.CFrame=workspace.CurrentCamera and workspace.CurrentCamera.CFrame or hrp.CFrame;gyro.Parent=hrp
  vel.MaxForce=Vector3.new(9e9,9e9,9e9);vel.Velocity=Vector3.zero;vel.Parent=hrp
  flyConn=RS.RenderStepped:Connect(function()
    if not hrp or not hrp.Parent then stopFly() return end
    local cam=workspace.CurrentCamera;local cf=cam and cam.CFrame or hrp.CFrame
    local look,right=cf.LookVector,cf.RightVector
    local move=Vector3.zero
    if keys.W then move+=look end;if keys.S then move-=look end
    if keys.A then move-=right end;if keys.D then move+=right end
    if keys.Up then move+=Vector3.new(0,1,0)end;if keys.Down then move-=Vector3.new(0,1,0)end
    local hum=Hum();local md=hum and hum.MoveDirection or Vector3.zero
    if md.Magnitude>0 then local f=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z);local r=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
      if f.Magnitude>0 then f=f.Unit end;if r.Magnitude>0 then r=r.Unit end;move=(f*md.Z)+(r*md.X)end
    if move.Magnitude>0 then move=move.Unit end
    vel.Velocity=move*(FLY_SPEED*50);gyro.CFrame=cf
  end)
  flyBtn.Text,flyBtn.BackgroundColor3="ON",Theme.accA
end
UIS.InputBegan:Connect(function(i,gp)
  if gp then return end;local k=i.KeyCode
  if k==Enum.KeyCode.W then keys.W=true
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
  if k==Enum.KeyCode.W then keys.W=false
  elseif k==Enum.KeyCode.A then keys.A=false
  elseif k==Enum.KeyCode.S then keys.S=false
  elseif k==Enum.KeyCode.D then keys.D=false
  elseif k==Enum.KeyCode.Space then keys.Up=false
  elseif k==Enum.KeyCode.LeftControl or k==Enum.KeyCode.LeftShift then keys.Down=false
  end
end)
flyBtn.MouseButton1Click:Connect(function() if flyOn then stopFly() else startFly() end end)
LP.CharacterAdded:Connect(function() if flyOn then task.wait(.2); startFly() end end)

-- ESP
local _,espLabel,espRight = newRow(34)
espLabel.Text="Player ESP"
local espBtn=Instance.new("TextButton")
espBtn.Size=UDim2.new(0,45,1,0)
espBtn.Font=Enum.Font.GothamSemibold
espBtn.TextSize=13
espBtn.TextColor3=Theme.text
espBtn.BackgroundColor3=Theme.card
espBtn.Text="OFF"
espBtn.Parent=espRight
corner(espBtn,5); stroke(espBtn,Theme.accA,1).Transparency=.17
local espOn, espConns = false, {}
local function clearESP(char)if not char then return end;for _,d in ipairs(char:GetChildren()) do
  if (d:IsA("BillboardGui") and d.Name=="danuu_esp_gui") or (d:IsA("Highlight") and d.Name=="danuu_esp_highlight") then d:Destroy() end end end
local function addESP(plr)
  if not espOn or plr==LP then return end;local ch=plr.Character;if not ch then return end;clearESP(ch)
  local hl=Instance.new("Highlight")hl.Name="danuu_esp_highlight"hl.FillTransparency=1;hl.OutlineTransparency=0.15;hl.OutlineColor=Theme.accA;hl.Parent=ch
  local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
  local bb=Instance.new("BillboardGui")bb.Name="danuu_esp_gui";bb.Adornee=hrp;bb.AlwaysOnTop=true;bb.Size=UDim2.new(0,120,0,22)
  bb.StudsOffsetWorldSpace=Vector3.new(0,2.15,0);bb.Parent=ch
  local bg=Instance.new("Frame",bb)bg.BackgroundTransparency=.13;bg.BackgroundColor3=Theme.card;bg.Size=UDim2.fromScale(1,1);corner(bg,5);stroke(bg,Theme.accA,1).Transparency=.13
  local nameL=Instance.new("TextLabel")nameL.BackgroundTransparency=1;nameL.Size=UDim2.new(1,0,1,0)
  nameL.Font=Enum.Font.GothamSemibold;nameL.TextSize=13;nameL.TextColor3=Theme.text
  nameL.TextXAlignment=Enum.TextXAlignment.Center;nameL.TextTruncate=Enum.TextTruncate.AtEnd;nameL.Parent=bg
end
local function setupESP()
  for _,plr in ipairs(Players:GetPlayers()) do
    if plr~=LP then
      espConns[plr]=plr.CharacterAdded:Connect(function()if espOn then task.wait(.17);addESP(plr)end end)
      if plr.Character then addESP(plr) end
    end
  end
  espConns["_PlayerAdded"]=Players.PlayerAdded:Connect(function(plr)
    if plr~=LP then
      espConns[plr]=plr.CharacterAdded:Connect(function()if espOn then task.wait(.17);addESP(plr)end end)
    end
  end)
  espConns["_PlayerRemoving"]=Players.PlayerRemoving:Connect(function(plr)
    if espConns[plr] then espConns[plr]:Disconnect();espConns[plr]=nil end
    if plr.Character then clearESP(plr.Character) end
  end)
end
local function teardownESP()
  for _,cn in pairs(espConns)do if typeof(cn)=="RBXScriptConnection"then cn:Disconnect()end end
  table.clear(espConns)
  for _,plr in ipairs(Players:GetPlayers())do if plr.Character then clearESP(plr.Character)end end
end
espBtn.MouseButton1Click:Connect(function()
  espOn=not espOn;espBtn.Text,espBtn.BackgroundColor3 = espOn and "ON" or "OFF", espOn and Theme.accA or Theme.card
  if espOn then setupESP() else teardownESP() end
end)

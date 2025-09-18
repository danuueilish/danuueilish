-- src/local_player.lua (Professional, left label - right control, collapsible)
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
  good  = Color3.fromRGB(106,212,123),
  bad   = Color3.fromRGB(255,95,95),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end
local function stroke(p, c, t)
    local s = Instance.new("UIStroke")
    s.Color = c or Color3.new(1, 1, 1)
    s.Thickness = t or 1
    s.Transparency = .6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

-- Collapsible
local secRoot = UI.NewSection(UI.Tabs.Menu, "Local Player")
local isMinimized = true
local mainToggle = Instance.new("TextButton")
mainToggle.Name = "MainToggle"
mainToggle.Text = "+ Local Player"
mainToggle.Font = Enum.Font.GothamBold
mainToggle.TextSize = 16
mainToggle.TextColor3 = Theme.accA
mainToggle.BackgroundColor3 = Theme.card
mainToggle.Size = UDim2.new(1, -8, 0, 38)
mainToggle.Position = UDim2.fromOffset(4, 4)
mainToggle.AnchorPoint = Vector2.new(0, 0)
mainToggle.AutoButtonColor = false
mainToggle.ZIndex = 2
mainToggle.Parent = secRoot
corner(mainToggle, 10)
stroke(mainToggle, Theme.accA, 1).Transparency = .3

local container = Instance.new("Frame")
container.BackgroundTransparency = 1
container.Size = UDim2.new(1, -8, 1, -50)
container.Position = UDim2.fromOffset(4, 46)
container.Visible = false
container.Parent = secRoot
local containerLayout = Instance.new("UIListLayout", container)
containerLayout.Padding = UDim.new(0, 8)
containerLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function toggleMin()
    isMinimized = not isMinimized
    container.Visible = not isMinimized
    mainToggle.Text = (isMinimized and "+" or "–") .. " Local Player"
    secRoot.Size = isMinimized and UDim2.new(1, -4, 0, 46) or UDim2.new(1, -4, 0, 380)
end
mainToggle.MouseButton1Click:Connect(toggleMin)
toggleMin() -- start collapsed

-- Helper: Left label, Right control - Classic layout
local function newRow(height)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Theme.card
    row.Size = UDim2.new(1, 0, 0, height or 52)
    row.Parent = container
    corner(row, 10)
    stroke(row, Theme.accA, 1).Transparency = .5
    local lay = Instance.new("UIListLayout", row)
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.VerticalAlignment = Enum.VerticalAlignment.Center
    lay.Padding = UDim.new(0, 12)
    local left = Instance.new("TextLabel")
    left.BackgroundTransparency = 1
    left.Size = UDim2.new(0, 140, 1, 0)
    left.Font = Enum.Font.GothamSemibold
    left.TextSize = 15
    left.TextColor3 = Theme.text
    left.TextXAlignment = Enum.TextXAlignment.Left
    left.Parent = row
    local right = Instance.new("Frame")
    right.BackgroundTransparency = 1
    right.Size = UDim2.new(1, -140, 1, 0)
    right.Parent = row
    local rlay = Instance.new("UIListLayout", right)
    rlay.FillDirection = Enum.FillDirection.Horizontal
    rlay.VerticalAlignment = Enum.VerticalAlignment.Center
    rlay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rlay.Padding = UDim.new(0, 8)
    return row, left, right
end

-- WalkSpeed
local _, wsLabel, wsRight = newRow(54)
wsLabel.Text = "Walk Speed"
local WS_MIN, WS_MAX = 0, 100
local wsTarget = 16
local wsSlider = Instance.new("Frame")
wsSlider.BackgroundColor3 = Theme.bg
wsSlider.Size = UDim2.new(1, -80, 0, 10)
wsSlider.Parent = wsRight
corner(wsSlider, 5)
stroke(wsSlider, Theme.accA, 1).Transparency = .3
local wsFill = Instance.new("Frame")
wsFill.BackgroundColor3 = Theme.accA
wsFill.Size = UDim2.new(0, 0, 1, 0)
wsFill.Parent = wsSlider
corner(wsFill, 5)
local wsKnob = Instance.new("Frame")
wsKnob.BackgroundColor3 = Theme.accB
wsKnob.Size = UDim2.fromOffset(18, 18)
wsKnob.Position = UDim2.new(0, -9, 0.5, -9)
wsKnob.Parent = wsSlider
corner(wsKnob, 9)
local wsBox = Instance.new("TextBox")
wsBox.Size = UDim2.new(0, 64, 0, 36)
wsBox.BackgroundColor3 = Theme.card
wsBox.TextColor3 = Theme.text
wsBox.Font = Enum.Font.Gotham
wsBox.TextSize = 14
wsBox.ClearTextOnFocus = false
wsBox.Text = "16"
wsBox.TextXAlignment = Enum.TextXAlignment.Center
wsBox.Parent = wsRight
corner(wsBox, 7)
stroke(wsBox, Theme.accA, 1).Transparency = .6

local function applyWS(v)
    wsTarget = math.clamp(math.floor(tonumber(v) or wsTarget), WS_MIN, WS_MAX)
    local rel = (wsTarget - WS_MIN) / math.max(1, (WS_MAX - WS_MIN))
    wsFill.Size = UDim2.new(rel, 0, 1, 0)
    wsKnob.Position = UDim2.new(rel, -9, 0.5, -9)
    wsBox.Text = tostring(wsTarget)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = wsTarget end
end
applyWS(wsTarget)
LP.CharacterAdded:Connect(function() task.wait(.2); applyWS(wsTarget) end)
do -- slider
    local dragging=false
    local function setFromX(x)
        local rel = math.clamp((x - wsSlider.AbsolutePosition.X)/math.max(1,wsSlider.AbsoluteSize.X),0,1)
        applyWS(WS_MIN + rel * (WS_MAX-WS_MIN))
    end
    wsSlider.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; setFromX(i.Position.X)
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
end
wsBox.FocusLost:Connect(function() applyWS(wsBox.Text) end)

-- Infinite Jump
local _, ijLabel, ijRight = newRow(54)
ijLabel.Text = "Infinite Jump"
local ijBtn=Instance.new("TextButton")
ijBtn.Size=UDim2.new(0,80,1,0)
ijBtn.AutoButtonColor=false
ijBtn.Font=Enum.Font.GothamSemibold
ijBtn.TextSize=13
ijBtn.TextColor3=Theme.text
ijBtn.BackgroundColor3=Theme.card
ijBtn.Text="OFF"
ijBtn.Parent=ijRight
corner(ijBtn,8); stroke(ijBtn,Theme.accA,1).Transparency=.45
local ijOn, ijConn, ijDebounce = false
local function setInf(on)
    ijOn = on and true or false
    if ijConn then ijConn:Disconnect(); ijConn=nil end
    if ijOn then
        ijConn = UIS.JumpRequest:Connect(function()
            if not ijDebounce then
                ijDebounce=true
                local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                task.wait(); ijDebounce=false
            end
        end)
    end
    ijBtn.Text, ijBtn.BackgroundColor3 = ijOn and "ON" or "OFF", ijOn and Theme.accA or Theme.card
end
ijBtn.MouseButton1Click:Connect(function() setInf(not ijOn) end)
LP.CharacterAdded:Connect(function() if ijOn then setInf(true) end end)

-- FLY - ADMIN STYLE
local _, flyLabel, flyRight = newRow(54)
flyLabel.Text = "Fly Mode"
local flyBtn=Instance.new("TextButton")
flyBtn.Size=UDim2.new(0,80,1,0)
flyBtn.AutoButtonColor=false
flyBtn.Font=Enum.Font.GothamSemibold
flyBtn.TextSize=13
flyBtn.TextColor3=Theme.text
flyBtn.BackgroundColor3=Theme.card
flyBtn.Text="OFF"
flyBtn.Parent=flyRight
corner(flyBtn,8); stroke(flyBtn,Theme.accA,1).Transparency=.45
local flyOn, flyConn, gyro, vel = false
local keys={W=false,A=false,S=false,D=false,Up=false,Down=false}
local FLY_SPEED = 2
local function stopFly()
    flyOn=false
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if gyro then gyro:Destroy(); gyro=nil end
    if vel then vel:Destroy(); vel=nil end
    flyBtn.Text, flyBtn.BackgroundColor3 = "OFF", Theme.card
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand = false end
end
local function startFly()
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not h then return end
    flyOn=true; h.PlatformStand=true
    gyro, vel = Instance.new("BodyGyro"), Instance.new("BodyVelocity")
    gyro.P=9e3; gyro.MaxTorque=Vector3.new(9e9,9e9,9e9); gyro.CFrame=workspace.CurrentCamera and workspace.CurrentCamera.CFrame or hrp.CFrame; gyro.Parent=hrp
    vel.MaxForce=Vector3.new(9e9,9e9,9e9); vel.Velocity=Vector3.zero; vel.Parent=hrp
    flyConn = RS.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then stopFly() return end
        local cam = workspace.CurrentCamera; local cf = cam and cam.CFrame or hrp.CFrame
        local look, right = cf.LookVector, cf.RightVector
        local move = Vector3.new()
        if keys.W then move += look end
        if keys.S then move -= look end
        if keys.A then move -= right end
        if keys.D then move += right end
        if keys.Up then move += Vector3.new(0,1,0) end
        if keys.Down then move -= Vector3.new(0,1,0) end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        local md = hum and hum.MoveDirection or Vector3.zero
        if md.Magnitude > 0 then
            local f = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z); local r = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
            if f.Magnitude>0 then f=f.Unit end
            if r.Magnitude>0 then r=r.Unit end
            move = (f * md.Z) + (r * md.X)
        end
        if move.Magnitude>0 then move=move.Unit end
        vel.Velocity = move * (FLY_SPEED * 50)
        gyro.CFrame  = cf
    end)
    flyBtn.Text, flyBtn.BackgroundColor3 = "ON", Theme.accA
end
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    local k=i.KeyCode
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
local _, espLabel, espRight = newRow(54)
espLabel.Text = "Player ESP"
local espBtn=Instance.new("TextButton")
espBtn.Size=UDim2.new(0,80,1,0)
espBtn.AutoButtonColor=false
espBtn.Font=Enum.Font.GothamSemibold
espBtn.TextSize=13
espBtn.TextColor3=Theme.text
espBtn.BackgroundColor3=Theme.card
espBtn.Text="OFF"
espBtn.Parent=espRight
corner(espBtn,8); stroke(espBtn,Theme.accA,1).Transparency=.45
local espOn = false; local espConns = {}
local function clearESP(char)
    if not char then return end
    for _,d in ipairs(char:GetChildren()) do
        if (d:IsA("BillboardGui") and d.Name=="danuu_esp_gui") or (d:IsA("Highlight") and d.Name=="danuu_esp_highlight") then
            d:Destroy()
        end
    end
end
local function addESP(plr)
    if not espOn or plr==LP then return end
    local ch = plr.Character if not ch then return end
    clearESP(ch)
    local hl = Instance.new("Highlight")
    hl.Name="danuu_esp_highlight"
    hl.FillTransparency=1; hl.OutlineTransparency=0.2
    hl.OutlineColor=Theme.accA; hl.Parent=ch
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bb = Instance.new("BillboardGui")
    bb.Name="danuu_esp_gui"; bb.Adornee=hrp; bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,170,0,40)
    bb.StudsOffsetWorldSpace = Vector3.new(0,2.8,0); bb.Parent = ch
    local bg = Instance.new("Frame", bb)
    bg.BackgroundTransparency=.12; bg.BackgroundColor3=Theme.card
    bg.Size=UDim2.fromScale(1,1); corner(bg,7); stroke(bg,Theme.accA,1).Transparency=.15
    local nameL = Instance.new("TextLabel")
    nameL.BackgroundTransparency=1; nameL.Size=UDim2.new(1,0,0,18)
    nameL.Position=UDim2.fromOffset(0,3)
    nameL.Font=Enum.Font.GothamSemibold; nameL.TextSize=13; nameL.TextColor3=Theme.text
    nameL.TextXAlignment=Enum.TextXAlignment.Center
    nameL.TextTruncate = Enum.TextTruncate.AtEnd; nameL.Parent=bg
    local distL = Instance.new("TextLabel")
    distL.BackgroundTransparency=1; distL.Size=UDim2.new(1,0,0,15)
    distL.Position=UDim2.fromOffset(0,20)
    distL.Font=Enum.Font.Gotham
    distL.TextSize=12
    distL.TextColor3=Theme.text2
    distL.TextXAlignment=Enum.TextXAlignment.Center
    distL.TextTruncate = Enum.TextTruncate.AtEnd; distL.Parent=bg
    task.spawn(function()
        while espOn and ch.Parent and bb.Parent do
            nameL.Text = plr.DisplayName or plr.Name
            local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local d = (my and hrp) and (my.Position - hrp.Position).Magnitude or 0
            distL.Text = string.format("%.0f studs", d)
            task.wait(0.2)
        end
    end)
end
local function setupESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP then
            espConns[plr]=plr.CharacterAdded:Connect(function() if espOn then task.wait(0.2); addESP(plr) end end)
            if plr.Character then addESP(plr) end
        end
    end
    espConns["_PlayerAdded"]=Players.PlayerAdded:Connect(function(plr)
        if plr~=LP then
            espConns[plr]=plr.CharacterAdded:Connect(function() if espOn then task.wait(0.2); addESP(plr) end end)
        end
    end)
    espConns["_PlayerRemoving"]=Players.PlayerRemoving:Connect(function(plr)
        if espConns[plr] then espConns[plr]:Disconnect(); espConns[plr]=nil end
        if plr.Character then clearESP(plr.Character) end
    end)
end
local function teardownESP()
    for _,cn in pairs(espConns) do if typeof(cn)=="RBXScriptConnection" then cn:Disconnect() end end
    table.clear(espConns)
    for _,plr in ipairs(Players:GetPlayers()) do if plr.Character then clearESP(plr.Character) end end
end
espBtn.MouseButton1Click:Connect(function()
    espOn = not espOn
    espBtn.Text, espBtn.BackgroundColor3 = espOn and "ON" or "OFF", espOn and Theme.accA or Theme.card
    if espOn then setupESP() else teardownESP() end
end)

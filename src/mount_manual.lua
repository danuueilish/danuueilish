-- src/mount_manual.lua
-- Manual Waypoints • rapi (gaya Mount Atin) + lengkap fitur
local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Manual"] then return end

local Players         = game:GetService("Players")
local UIS             = game:GetService("UserInputService")
local GuiService      = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- THEME (samain dengan Mount Atin)
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

-- Helpers
local function HRP()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end
local function safeTP(pos)
  local hrp, hum = HRP(); if not hrp then return end
  hrp.AssemblyLinearVelocity = Vector3.zero
  hrp.AssemblyAngularVelocity = Vector3.zero
  if hum then hum:ChangeState(Enum.HumanoidStateType.Landed) end
  task.wait(0.03)
  hrp.CFrame = CFrame.new(pos + Vector3.new(0,2.4,0))
end
local function dance3(center)
  local hrp = select(1,HRP()); if not hrp then return end
  local cam = workspace.CurrentCamera
  local dir = (cam and cam.CFrame.LookVector or hrp.CFrame.LookVector)
  dir = Vector3.new(dir.X,0,dir.Z); if dir.Magnitude<0.1 then dir=Vector3.new(1,0,0) end; dir=dir.Unit
  local R=8
  for _=1,3 do
    hrp.CFrame = CFrame.new(center + dir*R + Vector3.new(0,2.4,0)); task.wait(0.12)
    hrp.CFrame = CFrame.new(center - dir*R + Vector3.new(0,2.4,0)); task.wait(0.12)
    hrp.CFrame = CFrame.new(center + Vector3.new(0,2.4,0));         task.wait(0.12)
  end
end

-- FS helpers
local CAN_FS = (writefile and readfile and isfile and makefolder) and true or false
local function enc(t) return HttpService:JSONEncode(t) end
local function dec(s) local ok,res=pcall(function() return HttpService:JSONDecode(s) end); return ok and res or nil end
local function sread(path, fb) if CAN_FS and isfile(path) then local ok,dt=pcall(readfile,path); if ok and dt~="" then return dt end end; return fb end
local function swrite(path, content) if CAN_FS then pcall(writefile,path,content) end end

----------------------------------------------------------------
-- UI SUB-SECTION builder (persis Mount Atin)
----------------------------------------------------------------
local secRoot = UI.MountSections["Manual"]

local function newSub(titleText)
  local box = Instance.new("Frame")
  box.BackgroundColor3 = Theme.card
  box.Size = UDim2.new(1,-16,0,60)
  box.Parent = secRoot
  corner(box,10); stroke(box,Theme.accA,1).Transparency=.5

  local title = Instance.new("TextLabel")
  title.BackgroundTransparency = 1
  title.Text = "  "..titleText
  title.Font = Enum.Font.GothamBlack
  title.TextSize = 18
  title.TextColor3 = Theme.text
  title.TextXAlignment = Enum.TextXAlignment.Left
  title.Size = UDim2.new(1,-8,0,28)
  title.Position = UDim2.fromOffset(8,6)
  title.Parent = box

  local inner = Instance.new("Frame")
  inner.BackgroundTransparency = 1
  inner.Size = UDim2.new(1,-16,0,0)
  inner.Position = UDim2.fromOffset(8,36)
  inner.Parent = box

  local lay = Instance.new("UIListLayout", inner)
  lay.Padding = UDim.new(0,8)

  local function resize()
    box.Size = UDim2.new(1,-16,0, math.max(60, 40 + lay.AbsoluteContentSize.Y))
    inner.Size = UDim2.new(1,-16,0, lay.AbsoluteContentSize.Y)
  end
  lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
  task.defer(resize)

  return inner
end

----------------------------------------------------------------
-- SUB 1: Waypoints (kecil)
----------------------------------------------------------------
local wpInner = newSub("Waypoints")

-- File per map
local WP_FILE = ("danuu_manual_wp_%s.json"):format(tostring(game.PlaceId))
local waypoints = {}
local function loadWP()
  waypoints = {}
  local t = dec(sread(WP_FILE,""))
  if typeof(t)=="table" then
    for _,v in ipairs(t) do
      if typeof(v)=="table" and v.x and v.y and v.z then
        table.insert(waypoints, Vector3.new(v.x,v.y,v.z))
      end
    end
  end
end
local function saveWP()
  local out = {}
  for _,p in ipairs(waypoints) do out[#out+1]={x=p.X,y=p.Y,z=p.Z} end
  swrite(WP_FILE, enc(out))
end

-- List card (tinggi kecil 120)
local listCard = Instance.new("Frame")
listCard.BackgroundColor3 = Theme.bg
listCard.Size = UDim2.new(1, -8, 0, 120)
listCard.Parent = wpInner
corner(listCard,8); stroke(listCard,Theme.accA,1).Transparency=.6
local padLC = Instance.new("UIPadding", listCard)
padLC.PaddingLeft, padLC.PaddingRight, padLC.PaddingTop, padLC.PaddingBottom = UDim.new(0,8),UDim.new(0,8),UDim.new(0,8),UDim.new(0,8)

local scroll = Instance.new("ScrollingFrame", listCard)
scroll.BackgroundTransparency = 1
scroll.Size = UDim2.fromScale(1,1)
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0,0,0,0)

local sl = Instance.new("UIListLayout", scroll)
sl.Padding = UDim.new(0,6)

local function refreshWP()
  for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
  for i,pos in ipairs(waypoints) do
    local row = Instance.new("Frame"); row.BackgroundColor3 = Theme.card; row.Size = UDim2.new(1,0,0,32); row.Parent=scroll
    corner(row,8); stroke(row,Theme.accA,1).Transparency=.55

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency=1; name.TextColor3=Theme.text; name.Font=Enum.Font.Gotham; name.TextSize=14
    name.TextXAlignment=Enum.TextXAlignment.Left
    name.Text = string.format("Camp %d (%.0f, %.0f, %.0f)", i,pos.X,pos.Y,pos.Z)
    name.Size = UDim2.new(1,-160,1,0)
    name.Position = UDim2.fromOffset(10,0)
    name.Parent=row

    local tp = Instance.new("TextButton")
    tp.AutoButtonColor=false; tp.Text="TP"; tp.Font=Enum.Font.GothamSemibold; tp.TextSize=13; tp.TextColor3=Theme.text
    tp.BackgroundColor3=Theme.accA; tp.Size=UDim2.new(0,48,1,0); tp.Parent=row; tp.Position = UDim2.new(1,-104,0,0)
    corner(tp,8); stroke(tp,Theme.accB,1).Transparency=.35
    tp.MouseButton1Click:Connect(function()
      safeTP(pos)
      if Settings.moveDance then dance3(pos) end
    end)

    local del = Instance.new("TextButton")
    del.AutoButtonColor=false; del.Text="✕"; del.Font=Enum.Font.GothamBold; del.TextSize=13; del.TextColor3=Theme.text
    del.BackgroundColor3=Theme.bad; del.Size=UDim2.new(0,48,1,0); del.Parent=row; del.Position = UDim2.new(1,-52,0,0)
    corner(del,8); stroke(del,Color3.new(1,1,1),1).Transparency=.75
    del.MouseButton1Click:Connect(function() table.remove(waypoints,i); refreshWP(); saveWP() end)
  end
  scroll.CanvasSize = UDim2.new(0,0,0, sl.AbsoluteContentSize.Y + 8)
end

-- Baris tombol Set / Delete Last
do
  local row = Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,36); row.Parent=wpInner
  local rLay = Instance.new("UIListLayout", row); rLay.FillDirection=Enum.FillDirection.Horizontal; rLay.Padding=UDim.new(0,8)

  local setB = Instance.new("TextButton")
  setB.AutoButtonColor=false; setB.Text="Set Waypoint"; setB.Font=Enum.Font.GothamSemibold; setB.TextSize=14; setB.TextColor3=Theme.text
  setB.BackgroundColor3=Theme.accA; setB.Size=UDim2.new(0,160,1,0); setB.Parent=row
  corner(setB,8); stroke(setB,Theme.accB,1).Transparency=.35

  local delB = Instance.new("TextButton")
  delB.AutoButtonColor=false; delB.Text="Delete Last"; delB.Font=Enum.Font.GothamSemibold; delB.TextSize=14; delB.TextColor3=Theme.text
  delB.BackgroundColor3=Theme.card; delB.Size=UDim2.new(0,160,1,0); delB.Parent=row
  corner(delB,8); stroke(delB,Theme.accA,1).Transparency=.5

  local lastPos, lastT = nil, 0
  local function mayInsert(p)
    if not lastPos then return true end
    if (p-lastPos).Magnitude >= 2 then return true end
    return (tick()-lastT) > 0.25
  end

  setB.MouseButton1Click:Connect(function()
    local hrp = select(1,HRP()); if not hrp then return end
    local p = hrp.Position
    if mayInsert(p) then
      table.insert(waypoints, p)
      lastPos, lastT = p, tick()
      refreshWP(); saveWP()
    end
  end)
  delB.MouseButton1Click:Connect(function()
    if #waypoints>0 then table.remove(waypoints,#waypoints); refreshWP(); saveWP() end
  end)
end

loadWP(); refreshWP()

----------------------------------------------------------------
-- SUB 2: Options (Delay, AutoKill, Dance, AutoRJ + Delay)
----------------------------------------------------------------
local optInner = newSub("Options")

-- row: Delay (box kecil) + Auto respawn/kill toggle
do
  local row = Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,34); row.Parent=optInner
  local lay = Instance.new("UIListLayout", row); lay.FillDirection=Enum.FillDirection.Horizontal; lay.Padding=UDim.new(0,8)

  local delayBox = Instance.new("TextBox")
  delayBox.Size=UDim2.new(0,80,1,0)
  delayBox.BackgroundColor3=Theme.card; delayBox.TextColor3=Theme.text
  delayBox.Font=Enum.Font.Gotham; delayBox.TextSize=14; delayBox.ClearTextOnFocus=false; delayBox.TextXAlignment=Enum.TextXAlignment.Center
  corner(delayBox,8); stroke(delayBox,Theme.accA,1).Transparency=.5; delayBox.Parent=row

  local killBtn = Instance.new("TextButton")
  killBtn.AutoButtonColor=false; killBtn.Text="Auto respawn/kill: OFF"
  killBtn.Font=Enum.Font.GothamSemibold; killBtn.TextSize=14; killBtn.TextColor3=Theme.text
  killBtn.BackgroundColor3=Theme.card; killBtn.Size=UDim2.new(0,200,1,0); killBtn.Parent=row
  corner(killBtn,8); stroke(killBtn,Theme.accA,1).Transparency=.45

  -- Persist settings
  local SETTINGS_FILE = "danuu_manual_settings.json"
  local Settings = dec(sread(SETTINGS_FILE,"")) or {}
  if type(Settings)~="table" then Settings={} end
  Settings.loopDelay = tonumber(Settings.loopDelay) or 3
  Settings.autoKill  = Settings.autoKill and true or false
  Settings.moveDance = (Settings.moveDance~=false) -- default true
  Settings.autoRJ    = Settings.autoRJ and true or false
  Settings.autoRJDelay = tonumber(Settings.autoRJDelay) or 5
  local function saveS() swrite(SETTINGS_FILE, enc(Settings)) end

  delayBox.Text = tostring(Settings.loopDelay)
  killBtn.Text  = "Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF")
  killBtn.BackgroundColor3 = Settings.autoKill and Theme.accA or Theme.card

  delayBox.FocusLost:Connect(function()
    local v = tonumber(delayBox.Text) or Settings.loopDelay
    v = math.clamp(math.floor(v+0.5),1,60)
    Settings.loopDelay=v; delayBox.Text=tostring(v); saveS()
  end)
  killBtn.MouseButton1Click:Connect(function()
    Settings.autoKill = not Settings.autoKill
    killBtn.Text  = "Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF")
    killBtn.BackgroundColor3 = Settings.autoKill and Theme.accA or Theme.card
    saveS()
  end)

  -- ===== row: Dance + Auto RJ + Delay RJ
  local row2 = Instance.new("Frame"); row2.BackgroundTransparency=1; row2.Size=UDim2.new(1,0,0,34); row2.Parent=optInner
  local lay2 = Instance.new("UIListLayout", row2); lay2.FillDirection=Enum.FillDirection.Horizontal; lay2.Padding=UDim.new(0,8)

  local danceBtn = Instance.new("TextButton")
  danceBtn.AutoButtonColor=false; danceBtn.Text="3x/8stud: "..(Settings.moveDance and "ON" or "OFF")
  danceBtn.Font=Enum.Font.GothamSemibold; danceBtn.TextSize=14; danceBtn.TextColor3=Theme.text
  danceBtn.BackgroundColor3=Settings.moveDance and Theme.accA or Theme.card; danceBtn.Size=UDim2.new(0,140,1,0); danceBtn.Parent=row2
  corner(danceBtn,8); stroke(danceBtn,Theme.accA,1).Transparency=.45
  danceBtn.MouseButton1Click:Connect(function()
    Settings.moveDance = not Settings.moveDance
    danceBtn.Text="3x/8stud: "..(Settings.moveDance and "ON" or "OFF")
    danceBtn.BackgroundColor3=Settings.moveDance and Theme.accA or Theme.card
    saveS()
  end)

  local rjBtn = Instance.new("TextButton")
  rjBtn.AutoButtonColor=false; rjBtn.Text="Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF")
  rjBtn.Font=Enum.Font.GothamSemibold; rjBtn.TextSize=14; rjBtn.TextColor3=Theme.text
  rjBtn.BackgroundColor3=Settings.autoRJ and Theme.accA or Theme.card; rjBtn.Size=UDim2.new(0,160,1,0); rjBtn.Parent=row2
  corner(rjBtn,8); stroke(rjBtn,Theme.accA,1).Transparency=.45

  local rjBox = Instance.new("TextBox")
  rjBox.Size=UDim2.new(0,80,1,0)
  rjBox.BackgroundColor3=Theme.card; rjBox.TextColor3=Theme.text; rjBox.Font=Enum.Font.Gotham; rjBox.TextSize=14
  rjBox.ClearTextOnFocus=false; rjBox.Text=tostring(Settings.autoRJDelay); rjBox.TextXAlignment=Enum.TextXAlignment.Center
  corner(rjBox,8); stroke(rjBox,Theme.accA,1).Transparency=.5; rjBox.Parent=row2
  rjBox.FocusLost:Connect(function()
    local v = tonumber(rjBox.Text) or Settings.autoRJDelay
    v = math.clamp(math.floor(v+0.5),2,120)
    Settings.autoRJDelay=v; rjBox.Text=tostring(v); saveS()
  end)

  -- Auto RJ loop + error hook
  local PlaceId, JobId = game.PlaceId, game.JobId
  local rjOn, rjConn = false, nil
  local function doRJ()
    if #Players:GetPlayers() <= 1 then
      LP:Kick("\nRejoining..."); task.wait(); TeleportService:Teleport(PlaceId, LP)
    else
      TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LP)
    end
  end
  local function startRJ()
    if rjConn then rjConn:Disconnect() end
    rjConn = GuiService.ErrorMessageChanged:Connect(function() task.defer(doRJ) end)
    rjOn = true
    task.spawn(function()
      while rjOn do
        local d = tonumber(rjBox.Text) or Settings.autoRJDelay
        d = math.clamp(math.floor(d+0.5),2,120)
        for _=1,d*10 do if not rjOn then break end; task.wait(0.1) end
        if not rjOn then break end
        doRJ()
      end
    end)
  end
  local function stopRJ() rjOn=false; if rjConn then rjConn:Disconnect(); rjConn=nil end end

  rjBtn.MouseButton1Click:Connect(function()
    Settings.autoRJ = not Settings.autoRJ
    rjBtn.Text="Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF")
    rjBtn.BackgroundColor3 = Settings.autoRJ and Theme.accA or Theme.card
    saveS()
    if Settings.autoRJ then startRJ() else stopRJ() end
  end)
  if Settings.autoRJ then startRJ() end

  -- expose state for Auto Loop
  optInner._settings = Settings
  optInner._saveS    = saveS
  optInner._delayBox = delayBox
end

----------------------------------------------------------------
-- SUB 3: Auto Loop
----------------------------------------------------------------
local loopInner = newSub("Auto Loop")

local loopBtn = Instance.new("TextButton")
loopBtn.AutoButtonColor=false; loopBtn.Text="Auto loop: OFF"
loopBtn.Font=Enum.Font.GothamSemibold; loopBtn.TextSize=14; loopBtn.TextColor3=Theme.text
loopBtn.BackgroundColor3=Theme.card; loopBtn.Size=UDim2.new(0,160,0,34); loopBtn.Parent=loopInner
corner(loopBtn,8); stroke(loopBtn,Theme.accA,1).Transparency=.45

local looping=false
local function setLoop(on)
  local S = optInner._settings; local saveS = optInner._saveS
  S.autoLoop = on and true or false
  loopBtn.Text = "Auto loop: "..(S.autoLoop and "ON" or "OFF")
  loopBtn.BackgroundColor3 = S.autoLoop and Theme.accA or Theme.card
  saveS()

  if S.autoLoop and not looping then
    looping=true
    task.spawn(function()
      while S.autoLoop do
        if #waypoints==0 then task.wait(0.15) else
          local d = tonumber(optInner._delayBox.Text) or S.loopDelay or 3
          d = math.clamp(math.floor(d+0.5),1,60)
          for i=1,#waypoints do
            if not S.autoLoop then break end
            local pos = waypoints[i]
            safeTP(pos)
            if S.moveDance then dance3(pos) end
            local t0=tick()
            while S.autoLoop and tick()-t0 < d do task.wait(0.05) end
            if S.autoLoop and i==#waypoints and S.autoKill then
              local hum = select(2,HRP()); if hum then hum.Health=0 end
              LP.CharacterAdded:Wait(); task.wait(0.8)
            end
          end
        end
        task.wait(0.05)
      end
      looping=false
    end)
  end
end
loopBtn.MouseButton1Click:Connect(function() setLoop(not (optInner._settings.autoLoop or false)) end)

-- load persisted autoLoop (jika ada)
do
  local S = optInner._settings
  if S.autoLoop then setLoop(true) end
end

print("[danuu • Manual] loaded ✓")

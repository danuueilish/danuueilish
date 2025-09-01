-- src/mount_manual.lua
-- Section "Manual" (Waypoints manual + auto loop + dance 3x/8stud + auto respawn/kill + auto rejoin)

local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Manual"] then return end

local Players         = game:GetService("Players")
local UIS             = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local GuiService      = game:GetService("GuiService")
local HttpService     = game:GetService("HttpService")
local LP = Players.LocalPlayer

----------------------------------------------------------------
-- THEME + HELPERS
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
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

local function HRP()
  local ch=LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end

local function safeTP(pos)
  local hrp, hum = HRP(); if not hrp then return false end
  hrp.CFrame = CFrame.new(pos + Vector3.new(0,2.4,0))
  if hum then hum:ChangeState(Enum.HumanoidStateType.Landed) end
  return true
end

local function dance3(center)
  local hrp = HRP()
  if not hrp then return end
  local cam = workspace.CurrentCamera
  local dir = (cam and cam.CFrame.LookVector or hrp.CFrame.LookVector)
  dir = Vector3.new(dir.X,0,dir.Z)
  if dir.Magnitude<0.1 then dir=Vector3.new(1,0,0) end
  dir=dir.Unit
  local R=8
  for _=1,3 do
    hrp.CFrame = CFrame.new(center) + dir*R; task.wait(0.12)
    hrp.CFrame = CFrame.new(center) - dir*R; task.wait(0.12)
    hrp.CFrame = CFrame.new(center); task.wait(0.12)
  end
end

local function enc(t) return HttpService:JSONEncode(t) end
local function dec(s) local ok,res=pcall(function() return HttpService:JSONDecode(s) end); if ok then return res end end
local function sread(path,fallback)
  if not isfile or not readfile then return fallback end
  if not isfile(path) then return fallback end
  local ok,d=pcall(function() return readfile(path) end)
  if ok then return d else return fallback end
end
local function swrite(path,txt)
  if not writefile then return end
  pcall(function() writefile(path,txt) end)
end

----------------------------------------------------------------
-- NEW SUBSECTION HELPER
----------------------------------------------------------------
local secRoot = UI.MountSections["Manual"]
local function newSub(titleText)
  local box=Instance.new("Frame")
  box.BackgroundColor3=Theme.card; box.Size=UDim2.new(1,-16,0,60); box.Parent=secRoot
  corner(box,10); stroke(box,Theme.accA,1).Transparency=.5

  local title=Instance.new("TextLabel")
  title.BackgroundTransparency=1; title.Text="  "..titleText
  title.Font=Enum.Font.GothamBlack; title.TextSize=18; title.TextColor3=Theme.text
  title.TextXAlignment=Enum.TextXAlignment.Left; title.Size=UDim2.new(1,-8,0,28)
  title.Position=UDim2.fromOffset(8,6); title.Parent=box

  local inner=Instance.new("Frame")
  inner.BackgroundTransparency=1; inner.Size=UDim2.new(1,-16,0,0)
  inner.Position=UDim2.fromOffset(8,36); inner.Parent=box

  local lay=Instance.new("UIListLayout",inner); lay.Padding=UDim.new(0,8)
  lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    box.Size=UDim2.new(1,-16,0,math.max(60,40+lay.AbsoluteContentSize.Y))
    inner.Size=UDim2.new(1,-16,0,lay.AbsoluteContentSize.Y)
  end)
  task.defer(function()
    box.Size=UDim2.new(1,-16,0,math.max(60,40+lay.AbsoluteContentSize.Y))
    inner.Size=UDim2.new(1,-16,0,lay.AbsoluteContentSize.Y)
  end)
  return inner
end

----------------------------------------------------------------
-- SUB 1: WAYPOINTS
----------------------------------------------------------------
local WP_FILE = ("danuu_manual_wp_%s.json"):format(tostring(game.PlaceId))
local waypoints = {}
do
  local data = dec(sread(WP_FILE,""))
  if type(data)=="table" then
    for _,v in ipairs(data) do
      if v.x and v.y and v.z then table.insert(waypoints, Vector3.new(v.x,v.y,v.z)) end
    end
  end
end
local function saveWP()
  local t = {}
  for _,v in ipairs(waypoints) do table.insert(t,{x=v.X,y=v.Y,z=v.Z}) end
  swrite(WP_FILE, enc(t))
end

local wpInner = newSub("Waypoints")

-- list scroll
local listCard=Instance.new("Frame"); listCard.BackgroundColor3=Theme.bg; listCard.Size=UDim2.new(1,0,0,120); listCard.Parent=wpInner
corner(listCard,8); stroke(listCard,Theme.accA,1).Transparency=.6
local wpScroll=Instance.new("ScrollingFrame"); wpScroll.BackgroundTransparency=1; wpScroll.Size=UDim2.fromScale(1,1)
wpScroll.ScrollBarThickness=6; wpScroll.CanvasSize=UDim2.new(0,0,0,0); wpScroll.Parent=listCard
local wpList=Instance.new("UIListLayout",wpScroll); wpList.Padding=UDim.new(0,6)
wpList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  wpScroll.CanvasSize=UDim2.new(0,0,0,wpList.AbsoluteContentSize.Y+8)
end)

local function refreshWP()
  for _,c in ipairs(wpScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
  for i,pos in ipairs(waypoints) do
    local row=Instance.new("Frame"); row.BackgroundColor3=Theme.card; row.Size=UDim2.new(1,0,0,28); row.Parent=wpScroll
    corner(row,6); stroke(row,Theme.accA,1).Transparency=.6
    local name=Instance.new("TextLabel"); name.BackgroundTransparency=1; name.Text=string.format("Camp %d (%.0f,%.0f,%.0f)",i,pos.X,pos.Y,pos.Z)
    name.Font=Enum.Font.Gotham; name.TextSize=13; name.TextColor3=Theme.text; name.TextXAlignment=Enum.TextXAlignment.Left
    name.Size=UDim2.new(1,-100,1,0); name.Parent=row
    local tp=Instance.new("TextButton"); tp.Text="TP"; tp.Font=Enum.Font.GothamSemibold; tp.TextSize=13; tp.TextColor3=Theme.text
    tp.Size=UDim2.new(0,44,1,0); tp.BackgroundColor3=Theme.accA; tp.Parent=row; corner(tp,6); stroke(tp,Theme.accB,1).Transparency=.35
    tp.MouseButton1Click:Connect(function() safeTP(pos); if Settings.moveDance then dance3(pos) end end)
    local del=Instance.new("TextButton"); del.Text="✕"; del.Font=Enum.Font.GothamBold; del.TextSize=13; del.TextColor3=Theme.text
    del.Size=UDim2.new(0,36,1,0); del.BackgroundColor3=Theme.bad; del.Parent=row; corner(del,6); stroke(del,Color3.new(1,1,1),1).Transparency=.7
    del.MouseButton1Click:Connect(function() table.remove(waypoints,i); refreshWP(); saveWP() end)
  end
end

-- tombol bawah
local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,34); row.Parent=wpInner
local lay=Instance.new("UIListLayout",row); lay.FillDirection=Enum.FillDirection.Horizontal; lay.Padding=UDim.new(0,8)

local btnSet=Instance.new("TextButton"); btnSet.Size=UDim2.new(0.5,-4,1,0); btnSet.Text="Set Waypoint"
btnSet.Font=Enum.Font.GothamSemibold; btnSet.TextSize=14; btnSet.TextColor3=Theme.text; btnSet.BackgroundColor3=Theme.accA
corner(btnSet,8); stroke(btnSet,Theme.accB,1).Transparency=.35; btnSet.Parent=row
local btnDel=Instance.new("TextButton"); btnDel.Size=UDim2.new(0.5,-4,1,0); btnDel.Text="Delete Last"
btnDel.Font=Enum.Font.GothamSemibold; btnDel.TextSize=14; btnDel.TextColor3=Theme.text; btnDel.BackgroundColor3=Theme.card
corner(btnDel,8); stroke(btnDel,Theme.accA,1).Transparency=.5; btnDel.Parent=row

btnSet.MouseButton1Click:Connect(function()
  local hrp=HRP(); if hrp then table.insert(waypoints,hrp.Position); refreshWP(); saveWP() end
end)
btnDel.MouseButton1Click:Connect(function()
  if #waypoints>0 then table.remove(waypoints,#waypoints); refreshWP(); saveWP() end
end)

refreshWP()

----------------------------------------------------------------
-- SUB 2: OPTIONS (Delay, AutoKill, Dance, AutoRJ+Delay, AutoLoop)
----------------------------------------------------------------
-- pakai kode yang aku kirim terakhir
-- >>> paste di sini full blok Options yang tadi <<<
----------------------------------------------------------------
-- SUB: Options (Delay, AutoKill, Dance, AutoRJ + Delay, AutoLoop)
----------------------------------------------------------------
local optInner = newSub("Options")

-- ====== SETTINGS (persist) ======
local SETTINGS_FILE = "danuu_manual_settings.json"
local Settings = dec(sread(SETTINGS_FILE,"")) or {}
if type(Settings)~="table" then Settings={} end
Settings.loopDelay   = tonumber(Settings.loopDelay)   or 3
Settings.autoKill    = Settings.autoKill and true or false
Settings.moveDance   = (Settings.moveDance ~= false) -- default ON
Settings.autoRJ      = Settings.autoRJ and true or false
Settings.autoRJDelay = tonumber(Settings.autoRJDelay) or 5
Settings.autoLoop    = Settings.autoLoop and true or false
local function saveS() swrite(SETTINGS_FILE, enc(Settings)) end

-- ===== Row 1: Delay + Auto respawn/kill =====
do
  local row = Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,34); row.Parent=optInner
  local lay = Instance.new("UIListLayout", row); lay.FillDirection=Enum.FillDirection.Horizontal; lay.Padding=UDim.new(0,8)

  local delayBox = Instance.new("TextBox")
  delayBox.Size=UDim2.new(0,80,1,0)
  delayBox.BackgroundColor3=Theme.card; delayBox.TextColor3=Theme.text
  delayBox.Font=Enum.Font.Gotham; delayBox.TextSize=14; delayBox.ClearTextOnFocus=false; delayBox.TextXAlignment=Enum.TextXAlignment.Center
  delayBox.Text = tostring(Settings.loopDelay)
  corner(delayBox,8); stroke(delayBox,Theme.accA,1).Transparency=.5; delayBox.Parent=row
  delayBox.FocusLost:Connect(function()
    local v = tonumber(delayBox.Text) or Settings.loopDelay
    v = math.clamp(math.floor(v+0.5),1,60)
    Settings.loopDelay=v; delayBox.Text=tostring(v); saveS()
  end)

  local killBtn = Instance.new("TextButton")
  killBtn.AutoButtonColor=false
  killBtn.Text="Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF")
  killBtn.Font=Enum.Font.GothamSemibold; killBtn.TextSize=14; killBtn.TextColor3=Theme.text
  killBtn.BackgroundColor3=Settings.autoKill and Theme.accA or Theme.card
  killBtn.Size=UDim2.new(0,200,1,0); killBtn.Parent=row
  corner(killBtn,8); stroke(killBtn,Theme.accA,1).Transparency=.45
  killBtn.MouseButton1Click:Connect(function()
    Settings.autoKill = not Settings.autoKill
    killBtn.Text  = "Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF")
    killBtn.BackgroundColor3 = Settings.autoKill and Theme.accA or Theme.card
    saveS()
  end)

  -- simpan buat dipakai Auto Loop
  optInner._delayBox = delayBox
end

-- ===== Row 2: 3x/8stud + Auto Rejoin + Delay RJ =====
local rjLoopOn, rjConn = false, nil
local function doRJ()
  local PlaceId, JobId = game.PlaceId, game.JobId
  if #Players:GetPlayers() <= 1 then
    LP:Kick("\nRejoining..."); task.wait(); TeleportService:Teleport(PlaceId, LP)
  else
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LP)
  end
end
local function startRJ(rjBox)
  if rjConn then rjConn:Disconnect() end
  rjConn = GuiService.ErrorMessageChanged:Connect(function() task.defer(doRJ) end)
  rjLoopOn = true
  task.spawn(function()
    while rjLoopOn do
      local d = tonumber(rjBox.Text) or Settings.autoRJDelay or 5
      d = math.clamp(math.floor(d+0.5),2,120)
      for _=1,d*10 do if not rjLoopOn then break end; task.wait(0.1) end
      if not rjLoopOn then break end
      doRJ()
    end
  end)
end
local function stopRJ() rjLoopOn=false; if rjConn then rjConn:Disconnect(); rjConn=nil end end

do
  local row2 = Instance.new("Frame"); row2.BackgroundTransparency=1; row2.Size=UDim2.new(1,0,0,34); row2.Parent=optInner
  local lay2 = Instance.new("UIListLayout", row2); lay2.FillDirection=Enum.FillDirection.Horizontal; lay2.Padding=UDim.new(0,8)

  local danceBtn = Instance.new("TextButton")
  danceBtn.AutoButtonColor=false
  danceBtn.Text="3x/8stud: "..(Settings.moveDance and "ON" or "OFF")
  danceBtn.Font=Enum.Font.GothamSemibold; danceBtn.TextSize=14; danceBtn.TextColor3=Theme.text
  danceBtn.BackgroundColor3=Settings.moveDance and Theme.accA or Theme.card
  danceBtn.Size=UDim2.new(0,140,1,0); danceBtn.Parent=row2
  corner(danceBtn,8); stroke(danceBtn,Theme.accA,1).Transparency=.45
  danceBtn.MouseButton1Click:Connect(function()
    Settings.moveDance = not Settings.moveDance
    danceBtn.Text="3x/8stud: "..(Settings.moveDance and "ON" or "OFF")
    danceBtn.BackgroundColor3=Settings.moveDance and Theme.accA or Theme.card
    saveS()
  end)

  local rjBtn = Instance.new("TextButton")
  rjBtn.AutoButtonColor=false
  rjBtn.Text="Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF")
  rjBtn.Font=Enum.Font.GothamSemibold; rjBtn.TextSize=14; rjBtn.TextColor3=Theme.text
  rjBtn.BackgroundColor3=Settings.autoRJ and Theme.accA or Theme.card
  rjBtn.Size=UDim2.new(0,160,1,0); rjBtn.Parent=row2
  corner(rjBtn,8); stroke(rjBtn,Theme.accA,1).Transparency=.45

  local rjBox = Instance.new("TextBox")
  rjBox.Size=UDim2.new(0,80,1,0)
  rjBox.BackgroundColor3=Theme.card; rjBox.TextColor3=Theme.text
  rjBox.Font=Enum.Font.Gotham; rjBox.TextSize=14; rjBox.ClearTextOnFocus=false
  rjBox.Text = tostring(Settings.autoRJDelay); rjBox.TextXAlignment=Enum.TextXAlignment.Center
  corner(rjBox,8); stroke(rjBox,Theme.accA,1).Transparency=.5; rjBox.Parent=row2
  rjBox.FocusLost:Connect(function()
    local v=tonumber(rjBox.Text) or Settings.autoRJDelay
    v = math.clamp(math.floor(v+0.5),2,120)
    Settings.autoRJDelay=v; rjBox.Text=tostring(v); saveS()
  end)

  rjBtn.MouseButton1Click:Connect(function()
    Settings.autoRJ = not Settings.autoRJ
    rjBtn.Text="Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF")
    rjBtn.BackgroundColor3 = Settings.autoRJ and Theme.accA or Theme.card
    saveS()
    if Settings.autoRJ then startRJ(rjBox) else stopRJ() end
  end)
  if Settings.autoRJ then startRJ(rjBox) end
end

-- ===== Row 3: Auto Loop (TAMPIL di Options) =====
local looping=false
local function setLoop(on)
  Settings.autoLoop = on and true or false
  loopBtn.Text = "Auto loop: "..(Settings.autoLoop and "ON" or "OFF")
  loopBtn.BackgroundColor3 = Settings.autoLoop and Theme.accA or Theme.card
  saveS()

  if Settings.autoLoop and not looping then
    looping=true
    task.spawn(function()
      while Settings.autoLoop do
        if #waypoints==0 then task.wait(0.15) else
          local d = tonumber(optInner._delayBox.Text) or Settings.loopDelay or 3
          d = math.clamp(math.floor(d+0.5),1,60)
          for i=1,#waypoints do
            if not Settings.autoLoop then break end
            local pos = waypoints[i]
            safeTP(pos)
            if Settings.moveDance then dance3(pos) end
            local t0=tick()
            while Settings.autoLoop and tick()-t0 < d do task.wait(0.05) end
            if Settings.autoLoop and i==#waypoints and Settings.autoKill then
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

local row3 = Instance.new("Frame"); row3.BackgroundTransparency=1; row3.Size=UDim2.new(1,0,0,34); row3.Parent=optInner
local r3 = Instance.new("UIListLayout", row3); r3.FillDirection=Enum.FillDirection.Horizontal; r3.Padding=UDim.new(0,8)

local cap = Instance.new("TextLabel") -- label kecil kiri: "Auto Loop"
cap.BackgroundTransparency=1; cap.TextColor3=Theme.text2; cap.Font=Enum.Font.Gotham; cap.TextSize=14
cap.Text = "Auto Loop"; cap.Size = UDim2.new(0,120,1,0); cap.Parent=row3

loopBtn = Instance.new("TextButton")
loopBtn.AutoButtonColor=false; loopBtn.Text="Auto loop: "..(Settings.autoLoop and "ON" or "OFF")
loopBtn.Font=Enum.Font.GothamSemibold; loopBtn.TextSize=14; loopBtn.TextColor3=Theme.text
loopBtn.BackgroundColor3=Settings.autoLoop and Theme.accA or Theme.card
loopBtn.Size=UDim2.new(0,160,1,0); loopBtn.Parent=row3
corner(loopBtn,8); stroke(loopBtn,Theme.accA,1).Transparency=.45
loopBtn.MouseButton1Click:Connect(function() setLoop(not Settings.autoLoop) end)

-- apply persisted
if Settings.autoLoop then setLoop(true) end

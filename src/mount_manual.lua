-- src/mount_manual.lua
-- Section "Manual" (Waypoints manual + auto loop + dance 3x/8stud + auto respawn/kill + auto rejoin)

-- ===== UI container =====
local UI = _G.danuu_hub_ui
if not UI then return end
local sec = (UI.MountSections and UI.MountSections["Manual"])
          or UI.NewSection(UI.Tabs.Mount, "Manual") -- JANGAN dideclare lagi!

-- ===== Services =====
local Players         = game:GetService("Players")
local UIS             = game:GetService("UserInputService")
local GuiService      = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- ===== Helpers UI =====
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

local function HRP() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChild("HumanoidRootPart") end
local function Hum() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChildOfClass("Humanoid") end

-- ===== file helpers (executor) =====
local CAN_FS = (writefile and readfile and isfile and makefolder) and true or false
local function safe_read(path, fallback)
  if not CAN_FS or not isfile(path) then return fallback end
  local ok, data = pcall(function() return readfile(path) end)
  if not ok or data=="" then return fallback end
  return data
end
local function safe_write(path, content)
  if not CAN_FS then return false end
  local ok = pcall(function() return writefile(path, content) end)
  return ok
end
local function enc(t) return HttpService:JSONEncode(t) end
local function dec(s) local ok,res=pcall(function() return HttpService:JSONDecode(s) end); if ok then return res end; return nil end

-- ===== Settings (persist: toggle + delay) =====
local SETTINGS_FILE = "danuu_manual_settings.json"
local Settings = {
  loopDelay   = 3,     -- Delay antar waypoint
  autoLoop    = false, -- Auto Loop ON/OFF
  autoKill    = false, -- Auto respawn/kill di akhir siklus
  moveDance   = true,  -- Gerak searah 3x @ 8 stud
  autoRJ      = false, -- Auto Rejoin
  autoRJDelay = 5,     -- Delay Auto Rejoin
}
local function saveSettings() safe_write(SETTINGS_FILE, enc(Settings)) end
local function loadSettings()
  local t = dec(safe_read(SETTINGS_FILE,""))
  if typeof(t)=="table" then for k,v in pairs(t) do Settings[k]=v end end
end
loadSettings()

-- ===== Row helper (kiri label | kanan kontrol) =====
local function newRow(height)
  local row=Instance.new("Frame"); row.BackgroundColor3=Theme.card; row.Size=UDim2.new(1,-4,0,height or 54)
  row.Position=UDim2.fromOffset(2,0); row.Parent=sec
  corner(row,10); stroke(row,Theme.accA,1).Transparency=.55
  local pd=Instance.new("UIPadding",row); pd.PaddingLeft=UDim.new(0,10); pd.PaddingRight=UDim.new(0,10); pd.PaddingTop=UDim.new(0,8); pd.PaddingBottom=UDim.new(0,8)

  local lay=Instance.new("UIListLayout",row)
  lay.FillDirection=Enum.FillDirection.Horizontal; lay.Padding=UDim.new(0,10); lay.VerticalAlignment=Enum.VerticalAlignment.Center

  local left=Instance.new("TextLabel"); left.BackgroundTransparency=1; left.Size=UDim2.new(0,150,1,0)
  left.Font=Enum.Font.GothamSemibold; left.TextSize=16; left.TextXAlignment=Enum.TextXAlignment.Left; left.TextColor3=Theme.text; left.Parent=row

  local right=Instance.new("Frame"); right.BackgroundTransparency=1; right.Size=UDim2.new(1,-150,1,0); right.Parent=row
  local rlay=Instance.new("UIListLayout",right)
  rlay.FillDirection=Enum.FillDirection.Horizontal; rlay.Padding=UDim.new(0,10)
  rlay.VerticalAlignment=Enum.VerticalAlignment.Center; rlay.HorizontalAlignment=Enum.HorizontalAlignment.Right
  return row,left,right
end

-- ===== Waypoints (persist per map) =====
local WP_FILE = ("danuu_manual_wp_%s.json"):format(tostring(game.PlaceId))
local waypoints = {}

local function saveWP()
  local t = {}
  for _,v in ipairs(waypoints) do t[#t+1]={x=v.X,y=v.Y,z=v.Z} end
  safe_write(WP_FILE, enc(t))
end
local function loadWP()
  local data = dec(safe_read(WP_FILE,""))
  waypoints = {}
  if typeof(data)=="table" then
    for _,v in ipairs(data) do
      if typeof(v)=="table" and v.x and v.y and v.z then
        table.insert(waypoints, Vector3.new(v.x,v.y,v.z))
      end
    end
  end
end

-- dance 3x @ 8 stud (searah kamera)
local function checkpointDance(center)
  local hrp = HRP(); if not hrp then return end
  local cam = workspace.CurrentCamera
  local dir = (cam and cam.CFrame.LookVector or hrp.CFrame.LookVector)
  dir = Vector3.new(dir.X,0,dir.Z); if dir.Magnitude<0.1 then dir=Vector3.new(1,0,0) end; dir=dir.Unit
  local R=8
  for _=1,3 do
    hrp.CFrame = CFrame.new(center) + dir*R; task.wait(0.12)
    hrp.CFrame = CFrame.new(center) - dir*R; task.wait(0.12)
    hrp.CFrame = CFrame.new(center);         task.wait(0.12)
  end
end

-- ===== UI: List Waypoints =====
do
  local title = Instance.new("TextLabel")
  title.BackgroundTransparency=1; title.TextXAlignment=Enum.TextXAlignment.Left
  title.Text="List Waypoints"; title.Font=Enum.Font.GothamBlack; title.TextSize=16; title.TextColor3=Theme.text
  title.Size=UDim2.new(1,0,0,22); title.Parent=sec

  local listCard=Instance.new("Frame"); listCard.BackgroundColor3=Theme.bg; listCard.Size=UDim2.new(1,-4,0,150)
  listCard.Position=UDim2.fromOffset(2,0); listCard.Parent=sec
  corner(listCard,10); stroke(listCard,Theme.accA,1).Transparency=.7
  local pad=Instance.new("UIPadding",listCard); pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8); pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)

  local wpScroll=Instance.new("ScrollingFrame"); wpScroll.BackgroundTransparency=1; wpScroll.Size=UDim2.fromScale(1,1)
  wpScroll.ScrollBarThickness=6; wpScroll.CanvasSize=UDim2.new(0,0,0,0); wpScroll.Parent=listCard
  local wpList=Instance.new("UIListLayout",wpScroll); wpList.Padding=UDim.new(0,6)
  wpList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    wpScroll.CanvasSize=UDim2.new(0,0,0,wpList.AbsoluteContentSize.Y+8)
  end)

  local function refreshWP()
    for _,c in ipairs(wpScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for i,pos in ipairs(waypoints) do
      local row=Instance.new("Frame"); row.BackgroundColor3=Theme.card; row.Size=UDim2.new(1,0,0,30); row.Parent=wpScroll
      corner(row,8); stroke(row,Theme.accA,1).Transparency=.65
      local name=Instance.new("TextLabel"); name.BackgroundTransparency=1; name.TextXAlignment=Enum.TextXAlignment.Left
      name.Text=string.format("Camp %d  (%.1f, %.1f, %.1f)", i,pos.X,pos.Y,pos.Z)
      name.TextColor3=Theme.text; name.Font=Enum.Font.Gotham; name.TextSize=13; name.Size=UDim2.new(1,-140,1,0); name.Position=UDim2.fromOffset(8,0); name.Parent=row

      local tp=Instance.new("TextButton"); tp.Text="TP"; tp.Font=Enum.Font.GothamSemibold; tp.TextSize=13; tp.TextColor3=Theme.text
      tp.Size=UDim2.new(0,44,1,0); tp.Position=UDim2.new(1,-94,0,0); tp.BackgroundColor3=Theme.accA; tp.AutoButtonColor=false
      corner(tp,8); stroke(tp,Theme.accB,1).Transparency=.35; tp.Parent=row
      tp.MouseButton1Click:Connect(function()
        local h=HRP(); if h then h.CFrame=CFrame.new(pos) end
        if Settings.moveDance then checkpointDance(pos) end
      end)

      local del=Instance.new("TextButton"); del.Text="✕"; del.Font=Enum.Font.GothamBold; del.TextSize=13; del.TextColor3=Theme.text
      del.Size=UDim2.new(0,40,1,0); del.Position=UDim2.new(1,-46,0,0); del.BackgroundColor3=Theme.bad; del.AutoButtonColor=false
      corner(del,8); stroke(del,Color3.new(1,1,1),1).Transparency=.75; del.Parent=row
      del.MouseButton1Click:Connect(function()
        table.remove(waypoints,i); refreshWP(); saveWP()
      end)
    end
  end

  sec._refreshWP = refreshWP

  -- tombol Set / Delete
  local _, l1, r1 = newRow(40); l1.Text = "Waypoints"
  local btnSet = Instance.new("TextButton"); btnSet.Size=UDim2.new(0,160,1,0); btnSet.AutoButtonColor=false
  btnSet.Text="Set Waypoint"; btnSet.Font=Enum.Font.GothamSemibold; btnSet.TextSize=14; btnSet.TextColor3=Theme.text
  btnSet.BackgroundColor3=Theme.accA; corner(btnSet,8); stroke(btnSet,Theme.accB,1).Transparency=.35; btnSet.Parent=r1

  local btnDel = Instance.new("TextButton"); btnDel.Size=UDim2.new(0,160,1,0); btnDel.AutoButtonColor=false
  btnDel.Text="Delete Last"; btnDel.Font=Enum.Font.GothamSemibold; btnDel.TextSize=14; btnDel.TextColor3=Theme.text
  btnDel.BackgroundColor3=Theme.card; corner(btnDel,8); stroke(btnDel,Theme.accA,1).Transparency=.5; btnDel.Parent=r1

  -- anti double insert
  local lastWPPos, lastWPTime = nil, 0
  local function mayInsert(pos)
    if not lastWPPos then return true end
    if (pos - lastWPPos).Magnitude >= 2 then return true end
    return (tick() - lastWPTime) > 0.25
  end

  btnSet.MouseButton1Click:Connect(function()
    local h=HRP(); if not h then return end
    local pos=h.Position
    if mayInsert(pos) then
      table.insert(waypoints, pos)
      lastWPPos, lastWPTime = pos, tick()
      refreshWP(); saveWP()
    end
  end)
  btnDel.MouseButton1Click:Connect(function()
    if #waypoints>0 then table.remove(waypoints,#waypoints); refreshWP(); saveWP() end
  end)

  loadWP(); refreshWP()
end

-- ===== Row: [Delay] [Auto Respawn/kill ON/OFF] =====
local _, dLeft, dRight = newRow(46); dLeft.Text = "Delay"
local delayBox = Instance.new("TextBox"); delayBox.Size=UDim2.new(0,140,1,0)
delayBox.BackgroundColor3=Theme.card; delayBox.TextColor3=Theme.text; delayBox.Font=Enum.Font.Gotham; delayBox.TextSize=14
delayBox.ClearTextOnFocus=false; delayBox.Text=tostring(Settings.loopDelay or 3); delayBox.TextXAlignment=Enum.TextXAlignment.Center
corner(delayBox,8); stroke(delayBox,Theme.accA,1).Transparency=.5; delayBox.Parent=dRight
delayBox.FocusLost:Connect(function()
  local v=tonumber(delayBox.Text) or Settings.loopDelay
  v = math.clamp(math.floor(v+0.5), 1, 60)
  Settings.loopDelay = v; delayBox.Text=tostring(v); saveSettings()
end)

local killBtn = Instance.new("TextButton"); killBtn.Size=UDim2.new(0,200,1,0); killBtn.AutoButtonColor=false
killBtn.Text="Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF")
killBtn.Font=Enum.Font.GothamSemibold; killBtn.TextSize=14; killBtn.TextColor3=Theme.text
killBtn.BackgroundColor3=Settings.autoKill and Theme.accA or Theme.card; corner(killBtn,8); stroke(killBtn,Theme.accA,1).Transparency=.45; killBtn.Parent=dRight
killBtn.MouseButton1Click:Connect(function()
  Settings.autoKill = not Settings.autoKill
  killBtn.Text = "Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF")
  killBtn.BackgroundColor3 = Settings.autoKill and Theme.accA or Theme.card
  saveSettings()
end)

-- ===== Row: [Gerak 3x/8stud] [Auto Rejoin] [Delay RJ] =====
local _, gLeft, gRight = newRow(46); gLeft.Text = "Opsi"
local danceBtn = Instance.new("TextButton"); danceBtn.Size=UDim2.new(0,200,1,0); danceBtn.AutoButtonColor=false
danceBtn.Text="Gerak 3x/8stud: "..(Settings.moveDance and "ON" or "OFF")
danceBtn.Font=Enum.Font.GothamSemibold; danceBtn.TextSize=14; danceBtn.TextColor3=Theme.text
danceBtn.BackgroundColor3=Settings.moveDance and Theme.accA or Theme.card; corner(danceBtn,8); stroke(danceBtn,Theme.accA,1).Transparency=.45; danceBtn.Parent=gRight
danceBtn.MouseButton1Click:Connect(function()
  Settings.moveDance = not Settings.moveDance
  danceBtn.Text="Gerak 3x/8stud: "..(Settings.moveDance and "ON" or "OFF")
  danceBtn.BackgroundColor3 = Settings.moveDance and Theme.accA or Theme.card
  saveSettings()
end)

local rjBtn = Instance.new("TextButton"); rjBtn.Size=UDim2.new(0,160,1,0); rjBtn.AutoButtonColor=false
rjBtn.Text="Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF")
rjBtn.Font=Enum.Font.GothamSemibold; rjBtn.TextSize=14; rjBtn.TextColor3=Theme.text
rjBtn.BackgroundColor3=Settings.autoRJ and Theme.accA or Theme.card; corner(rjBtn,8); stroke(rjBtn,Theme.accA,1).Transparency=.45; rjBtn.Parent=gRight

local rjBox = Instance.new("TextBox"); rjBox.Size=UDim2.new(0,140,1,0)
rjBox.BackgroundColor3=Theme.card; rjBox.TextColor3=Theme.text; rjBox.Font=Enum.Font.Gotham; rjBox.TextSize=14
rjBox.ClearTextOnFocus=false; rjBox.Text=tostring(Settings.autoRJDelay or 5); rjBox.TextXAlignment=Enum.TextXAlignment.Center
corner(rjBox,8); stroke(rjBox,Theme.accA,1).Transparency=.5; rjBox.Parent=gRight
rjBox.FocusLost:Connect(function()
  local v=tonumber(rjBox.Text) or Settings.autoRJDelay
  v = math.clamp(math.floor(v+0.5), 2, 120)
  Settings.autoRJDelay = v; rjBox.Text=tostring(v); saveSettings()
end)

-- Auto Rejoin logic
local PlaceId, JobId = game.PlaceId, game.JobId
local rjLoopOn, rjConn = false, nil
local function doRJ()
  if #Players:GetPlayers() <= 1 then
    LP:Kick("\nRejoining..."); task.wait(); TeleportService:Teleport(PlaceId, LP)
  else
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LP)
  end
end
local function startRJ()
  if rjConn then rjConn:Disconnect() end
  rjConn = GuiService.ErrorMessageChanged:Connect(function() doRJ() end)
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

rjBtn.MouseButton1Click:Connect(function()
  Settings.autoRJ = not Settings.autoRJ
  rjBtn.Text="Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF")
  rjBtn.BackgroundColor3 = Settings.autoRJ and Theme.accA or Theme.card
  saveSettings()
  if Settings.autoRJ then startRJ() else stopRJ() end
end)
if Settings.autoRJ then startRJ() end

-- ===== Row: [Auto Loop ON/OFF] =====
local _, aLeft, aRight = newRow(46); aLeft.Text = "Auto loop"
local loopBtn = Instance.new("TextButton"); loopBtn.Size=UDim2.new(0,180,1,0); loopBtn.AutoButtonColor=false
loopBtn.Text="Auto loop: "..(Settings.autoLoop and "ON" or "OFF")
loopBtn.Font=Enum.Font.GothamSemibold; loopBtn.TextSize=14; loopBtn.TextColor3=Theme.text
loopBtn.BackgroundColor3=Settings.autoLoop and Theme.accA or Theme.card; corner(loopBtn,8); stroke(loopBtn,Theme.accA,1).Transparency=.45; loopBtn.Parent=aRight

-- ===== Main Auto Loop =====
local looping = false
local function setLoop(on)
  Settings.autoLoop = on and true or false
  loopBtn.Text = "Auto loop: "..(Settings.autoLoop and "ON" or "OFF")
  loopBtn.BackgroundColor3 = Settings.autoLoop and Theme.accA or Theme.card
  saveSettings()

  if Settings.autoLoop and not looping then
    looping = true
    task.spawn(function()
      while Settings.autoLoop do
        if #waypoints == 0 then
          task.wait(0.15)
        else
          local d = tonumber(delayBox.Text) or Settings.loopDelay or 3
          d = math.clamp(math.floor(d + 0.5), 1, 60)

          for i = 1, #waypoints do
            if not Settings.autoLoop then break end

            local pos = waypoints[i]
            local h = HRP(); if h then h.CFrame = CFrame.new(pos) end
            if Settings.moveDance then checkpointDance(pos) end

            local t0 = tick()
            while Settings.autoLoop and (tick() - t0 < d) do task.wait(0.05) end

            -- akhir siklus
            if Settings.autoLoop and i == #waypoints and Settings.autoKill then
              local hum = Hum(); if hum then hum.Health = 0 end
              LP.CharacterAdded:Wait(); task.wait(0.8)
            end
          end
        end
        task.wait(0.05)
      end
      looping = false
    end)
  end
end

-- apply nilai yang tersimpan
delayBox.Text = tostring(Settings.loopDelay or 3)
rjBox.Text    = tostring(Settings.autoRJDelay or 5)
if Settings.autoLoop then setLoop(true) end

print("[danuu • Manual] loaded ✓")

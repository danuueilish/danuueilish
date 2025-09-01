-- src/mount_manual.lua
-- Manual: Waypoints + Auto Loop + Dance 3x/8stud + Auto Kill + Auto Rejoin (persist)

------------------------------------------------------------
-- Ambil container "Manual" dari UI
------------------------------------------------------------
local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections then return end
local sec = UI.MountSections["Manual"] or UI.NewSection(UI.Tabs.Mount, "Manual")
if not sec then return end

local Players         = game:GetService("Players")
local UIS             = game:GetService("UserInputService")
local GuiService      = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local LP              = Players.LocalPlayer

-- tema mini
local C = {
  bg   = Color3.fromRGB(24,20,40),
  card = Color3.fromRGB(44,36,72),
  txt  = Color3.fromRGB(235,230,255),
  txt2 = Color3.fromRGB(190,180,220),
  aA   = Color3.fromRGB(125,84,255),
  aB   = Color3.fromRGB(215,55,255),
  good = Color3.fromRGB(106,212,123),
  bad  = Color3.fromRGB(255,95,95),
}
local function corner(o,r) local u=Instance.new("UICorner"); u.CornerRadius=UDim.new(0,r or 8); u.Parent=o; return u end
local function stroke(o,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.55; s.Parent=o; return s end

local function HRP() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChild("HumanoidRootPart") end
local function Hum() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChildOfClass("Humanoid") end

------------------------------------------------------------
-- Persist helpers
------------------------------------------------------------
local CAN_FS = (writefile and readfile and isfile and makefolder) and true or false
local function enc(t) return HttpService:JSONEncode(t) end
local function dec(s) local ok,v=pcall(function() return HttpService:JSONDecode(s) end); return ok and v or nil end
local function sread(p,fb) if not CAN_FS or not isfile(p) then return fb end; local ok,d=pcall(function() return readfile(p) end); return ok and d or fb end
local function swrite(p,c) if not CAN_FS then return end; pcall(function() writefile(p,c) end) end

------------------------------------------------------------
-- Row builder (HALUS & SIMPLE)
------------------------------------------------------------
local order = 0
local function Row(height)
  order += 1
  local row = Instance.new("Frame")
  row.Name = "row"..order
  row.LayoutOrder = order
  row.Size = UDim2.new(1, -6, 0, height or 40)
  row.BackgroundColor3 = C.card
  row.Parent = sec
  corner(row, 10); stroke(row, C.aA, 1)

  local pad = Instance.new("UIPadding", row)
  pad.PaddingLeft, pad.PaddingRight = UDim.new(0,10), UDim.new(0,10)
  pad.PaddingTop,  pad.PaddingBottom = UDim.new(0,6), UDim.new(0,6)

  local l = Instance.new("TextLabel")
  l.BackgroundTransparency = 1
  l.TextColor3, l.Font, l.TextSize = C.txt, Enum.Font.GothamSemibold, 14
  l.TextXAlignment = Enum.TextXAlignment.Left
  l.Text = ""
  l.Size = UDim2.new(0,150,1,0)
  l.Parent = row

  local r = Instance.new("Frame")
  r.BackgroundTransparency = 1
  r.Size = UDim2.new(1,-150,1,0)
  r.Parent = row
  local rl = Instance.new("UIListLayout", r)
  rl.FillDirection = Enum.FillDirection.Horizontal
  rl.Padding = UDim.new(0,8)
  rl.VerticalAlignment = Enum.VerticalAlignment.Center
  rl.HorizontalAlignment = Enum.HorizontalAlignment.Right

  return row, l, r
end

local function Label(text, h)
  order += 1
  local t = Instance.new("TextLabel")
  t.LayoutOrder = order
  t.BackgroundTransparency = 1
  t.Text = text
  t.TextColor3 = C.txt
  t.Font = Enum.Font.GothamBlack
  t.TextSize = 16
  t.TextXAlignment = Enum.TextXAlignment.Left
  t.Size = UDim2.new(1, -6, 0, h or 24)
  t.Parent = sec
  return t
end

local function Btn(parent, txt, w)
  local b = Instance.new("TextButton")
  b.AutoButtonColor = false
  b.Size = UDim2.new(0, w or 150, 1, 0)
  b.Text = txt
  b.Font = Enum.Font.GothamSemibold
  b.TextSize = 14
  b.TextColor3 = C.txt
  b.BackgroundColor3 = C.aA
  b.Parent = parent
  corner(b,8); stroke(b, C.aB, 1).Transparency = .35
  return b
end

local function Box(parent, text, w)
  local tb = Instance.new("TextBox")
  tb.ClearTextOnFocus = false
  tb.Size = UDim2.new(0, w or 120, 1, 0)
  tb.Text = text
  tb.Font = Enum.Font.Gotham
  tb.TextSize = 14
  tb.TextColor3 = C.txt
  tb.TextXAlignment = Enum.TextXAlignment.Center
  tb.BackgroundColor3 = C.card
  tb.Parent = parent
  corner(tb,8); stroke(tb, C.aA, 1)
  return tb
end

------------------------------------------------------------
-- Waypoints (per PlaceId)
------------------------------------------------------------
local WP_FILE = ("danuu_manual_wp_%s.json"):format(tostring(game.PlaceId))
local waypoints = {}
local function saveWP()
  local t = {}
  for _,v in ipairs(waypoints) do t[#t+1] = {x=v.X,y=v.Y,z=v.Z} end
  swrite(WP_FILE, enc(t))
end
local function loadWP()
  waypoints = {}
  local t = dec(sread(WP_FILE, "")) or {}
  for _,v in ipairs(t) do
    if v.x and v.y and v.z then table.insert(waypoints, Vector3.new(v.x,v.y,v.z)) end
  end
end
loadWP()

-- dance 3x @ 8 stud
local function dance(center)
  local hrp = HRP(); if not hrp then return end
  local dir = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or hrp.CFrame.LookVector
  dir = Vector3.new(dir.X,0,dir.Z); if dir.Magnitude < 0.1 then dir = Vector3.new(1,0,0) end; dir = dir.Unit
  local R = 8
  for _=1,3 do
    hrp.CFrame = CFrame.new(center + dir*R); task.wait(0.12)
    hrp.CFrame = CFrame.new(center - dir*R); task.wait(0.12)
    hrp.CFrame = CFrame.new(center);         task.wait(0.12)
  end
end

------------------------------------------------------------
-- SETTINGS (persist)
------------------------------------------------------------
local SETTINGS_FILE = "danuu_manual_settings.json"
local Settings = {
  loopDelay   = 3,
  autoLoop    = false,
  autoKill    = false,
  moveDance   = true,
  autoRJ      = false,
  autoRJDelay = 5,
}
do
  local t = dec(sread(SETTINGS_FILE, "")) or {}
  for k,v in pairs(t) do Settings[k]=v end
end
local function saveSettings() swrite(SETTINGS_FILE, enc(Settings)) end

------------------------------------------------------------
-- UI — Controls
------------------------------------------------------------
-- Row: Waypoint buttons
do
  Label("List Waypoints")
  -- kartu list kecil
  order += 1
  local card = Instance.new("Frame")
  card.LayoutOrder = order
  card.BackgroundColor3 = C.bg
  card.Size = UDim2.new(1,-6,0,110) -- << kecil
  card.Parent = sec
  corner(card,10); stroke(card,C.aA,1)

  local pad = Instance.new("UIPadding", card)
  pad.PaddingLeft, pad.PaddingRight = UDim.new(0,8), UDim.new(0,8)
  pad.PaddingTop,  pad.PaddingBottom = UDim.new(0,8), UDim.new(0,8)

  local scroll = Instance.new("ScrollingFrame")
  scroll.BackgroundTransparency = 1
  scroll.Size = UDim2.fromScale(1,1)
  scroll.ScrollBarThickness = 6
  scroll.CanvasSize = UDim2.new(0,0,0,0)
  scroll.Parent = card

  local list = Instance.new("UIListLayout", scroll)
  list.Padding = UDim.new(0,6)
  list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y+8)
  end)

  local function refreshWP()
    for _,c in ipairs(scroll:GetChildren()) do
      if c:IsA("Frame") then c:Destroy() end
    end
    for i,pos in ipairs(waypoints) do
      local row = Instance.new("Frame")
      row.BackgroundColor3 = C.card
      row.Size = UDim2.new(1,0,0,28)
      row.Parent = scroll
      corner(row,8); stroke(row,C.aA,1).Transparency = .6

      local name = Instance.new("TextLabel")
      name.BackgroundTransparency = 1
      name.TextXAlignment = Enum.TextXAlignment.Left
      name.Text = string.format("Camp %d (%.0f, %.0f, %.0f)", i,pos.X,pos.Y,pos.Z)
      name.Font = Enum.Font.Gotham
      name.TextColor3 = C.txt
      name.TextSize = 13
      name.Size = UDim2.new(1,-96,1,0)
      name.Position = UDim2.fromOffset(8,0)
      name.Parent = row

      local tp = Btn(row, "TP", 42); tp.Position = UDim2.new(1,-88,0,0); tp.Size = UDim2.new(0,42,1,0)
      local del = Btn(row,"✕", 42); del.BackgroundColor3 = C.bad; del.Position = UDim2.new(1,-44,0,0); del.Size = UDim2.new(0,42,1,0)

      tp.MouseButton1Click:Connect(function()
        local h = HRP(); if h then h.CFrame = CFrame.new(pos) end
        if Settings.moveDance then dance(pos) end
      end)
      del.MouseButton1Click:Connect(function()
        table.remove(waypoints, i); refreshWP(); saveWP()
      end)
    end
  end

  -- tombol set/del
  local _, l, r = Row(40); l.Text = "Waypoints"
  local setBtn = Btn(r,"Set Waypoint",140)
  local delBtn = Btn(r,"Delete Last",120); delBtn.BackgroundColor3 = C.card; stroke(delBtn,C.aA,1)

  -- anti spam insert
  local lastPos, lastT = nil, 0
  local function mayInsert(p)
    if not lastPos then return true end
    if (p-lastPos).Magnitude >= 2 then return true end
    return (tick()-lastT) > .25
  end

  setBtn.MouseButton1Click:Connect(function()
    local h = HRP(); if not h then return end
    local p = h.Position
    if mayInsert(p) then
      table.insert(waypoints, p); lastPos, lastT = p, tick()
      refreshWP(); saveWP()
    end
  end)
  delBtn.MouseButton1Click:Connect(function()
    if #waypoints>0 then table.remove(waypoints,#waypoints); refreshWP(); saveWP() end
  end)

  refreshWP()
end

-- Row: Delay + Auto Kill
local delayBox, killBtn do
  local _, l, r = Row(40); l.Text = "Delay (s)"
  delayBox = Box(r, tostring(Settings.loopDelay or 3), 100)
  delayBox.FocusLost:Connect(function()
    local v = tonumber(delayBox.Text) or Settings.loopDelay
    v = math.clamp(math.floor(v+0.5),1,60)
    Settings.loopDelay = v; delayBox.Text = tostring(v); saveSettings()
  end)

  killBtn = Btn(r, ("Auto respawn/kill: %s"):format(Settings.autoKill and "ON" or "OFF"), 180)
  killBtn.BackgroundColor3 = Settings.autoKill and C.aA or C.card; stroke(killBtn, C.aA, 1)
  killBtn.MouseButton1Click:Connect(function()
    Settings.autoKill = not Settings.autoKill
    killBtn.Text = "Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF")
    killBtn.BackgroundColor3 = Settings.autoKill and C.aA or C.card
    saveSettings()
  end)
end

-- Row: Opsi (Dance + Auto RJ + Delay RJ)
local rjBox do
  local _, l, r = Row(40); l.Text = "Opsi"
  local danceBtn = Btn(r, ("Gerak 3x/8stud: %s"):format(Settings.moveDance and "ON" or "OFF"), 180)
  danceBtn.BackgroundColor3 = Settings.moveDance and C.aA or C.card; stroke(danceBtn,C.aA,1)
  danceBtn.MouseButton1Click:Connect(function()
    Settings.moveDance = not Settings.moveDance
    danceBtn.Text = "Gerak 3x/8stud: "..(Settings.moveDance and "ON" or "OFF")
    danceBtn.BackgroundColor3 = Settings.moveDance and C.aA or C.card
    saveSettings()
  end)

  local rjBtn = Btn(r, ("Auto rejoin: %s"):format(Settings.autoRJ and "ON" or "OFF"), 150)
  rjBtn.BackgroundColor3 = Settings.autoRJ and C.aA or C.card; stroke(rjBtn,C.aA,1)

  rjBox = Box(r, tostring(Settings.autoRJDelay or 5), 80)

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
    rjBtn.Text = "Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF")
    rjBtn.BackgroundColor3 = Settings.autoRJ and C.aA or C.card
    saveSettings()
    if Settings.autoRJ then startRJ() else stopRJ() end
  end)
  rjBox.FocusLost:Connect(function()
    local v=tonumber(rjBox.Text) or Settings.autoRJDelay
    v = math.clamp(math.floor(v+0.5),2,120)
    Settings.autoRJDelay = v; rjBox.Text=tostring(v); saveSettings()
  end)
  if Settings.autoRJ then task.defer(function() rjBtn:Activate() end) end
end

-- Row: Auto Loop
do
  local _, l, r = Row(40); l.Text = "Auto Loop"
  local loopBtn = Btn(r, ("Auto loop: %s"):format(Settings.autoLoop and "ON" or "OFF"), 140)
  loopBtn.BackgroundColor3 = Settings.autoLoop and C.aA or C.card; stroke(loopBtn,C.aA,1)

  local looping = false
  local function setLoop(on)
    Settings.autoLoop = on and true or false
    loopBtn.Text = "Auto loop: "..(Settings.autoLoop and "ON" or "OFF")
    loopBtn.BackgroundColor3 = Settings.autoLoop and C.aA or C.card
    saveSettings()

    if Settings.autoLoop and not looping then
      looping = true
      task.spawn(function()
        while Settings.autoLoop do
          if #waypoints == 0 then
            task.wait(0.15)
          else
            local d = tonumber(delayBox.Text) or Settings.loopDelay or 3
            d = math.clamp(math.floor(d+0.5),1,60)
            for i=1,#waypoints do
              if not Settings.autoLoop then break end
              local pos = waypoints[i]
              local h = HRP(); if h then h.CFrame = CFrame.new(pos) end
              if Settings.moveDance then dance(pos) end

              local t0=tick()
              while Settings.autoLoop and (tick()-t0 < d) do task.wait(0.05) end

              if Settings.autoLoop and i==#waypoints and Settings.autoKill then
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

  loopBtn.MouseButton1Click:Connect(function() setLoop(not Settings.autoLoop) end)
  if Settings.autoLoop then task.defer(function() loopBtn:Activate() end) end
end

print("[danuu • Manual] UI ready ✓")

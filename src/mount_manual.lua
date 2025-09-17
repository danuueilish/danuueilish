-- src/mount_manual.lua (FIXED VERSION)
-- Manual Waypoints • Clean & User Friendly Design
local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Manual"] then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
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

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

-- ===== HELPERS =====
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
    hrp.CFrame = CFrame.new(center + Vector3.new(0,2.4,0)); task.wait(0.12)
  end
end

-- ===== FILE SYSTEM =====
local CAN_FS = (writefile and readfile and isfile and makefolder) and true or false
local function enc(t) return HttpService:JSONEncode(t) end
local function dec(s) local ok,res=pcall(function() return HttpService:JSONDecode(s) end); return ok and res or nil end
local function sread(path, fb) if CAN_FS and isfile(path) then local ok,dt=pcall(readfile,path); if ok and dt~="" then return dt end end; return fb end
local function swrite(path, content) if CAN_FS then pcall(writefile,path,content) end end

-- ===== CLEAN SUB-SECTION BUILDER =====
local secRoot = UI.MountSections["Manual"]

local function newCleanSub(titleText, height)
  local container = Instance.new("Frame")
  container.BackgroundColor3 = Theme.card
  container.Size = UDim2.new(1, -4, 0, height or 200)
  container.Position = UDim2.fromOffset(2, 0)
  container.Parent = secRoot
  container.ClipsDescendants = true -- IMPORTANT: prevent overflow
  corner(container, 12)
  stroke(container, Theme.accA, 1).Transparency = .6

  local header = Instance.new("TextLabel")
  header.BackgroundTransparency = 1
  header.Text = "  " .. titleText
  header.Font = Enum.Font.GothamBlack
  header.TextSize = 18
  header.TextColor3 = Theme.text
  header.TextXAlignment = Enum.TextXAlignment.Left
  header.Size = UDim2.new(1, -16, 0, 32)
  header.Position = UDim2.fromOffset(8, 8)
  header.Parent = container

  local content = Instance.new("Frame")
  content.BackgroundTransparency = 1
  content.Size = UDim2.new(1, -16, 1, -48)
  content.Position = UDim2.fromOffset(8, 40)
  content.Parent = container
  
  local contentLayout = Instance.new("UIListLayout", content)
  contentLayout.Padding = UDim.new(0, 8)
  contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
  
  return content, container
end

-- ===== SETTINGS MANAGEMENT =====
local SETTINGS_FILE = "danuu_manual_settings.json"
local WP_FILE = ("danuu_manual_wp_%s.json"):format(tostring(game.PlaceId))

local Settings = dec(sread(SETTINGS_FILE,"")) or {}
if type(Settings)~="table" then Settings={} end
Settings.loopDelay = tonumber(Settings.loopDelay) or 3
Settings.autoKill = Settings.autoKill and true or false
Settings.moveDance = (Settings.moveDance~=false)
Settings.autoRJ = Settings.autoRJ and true or false
Settings.autoRJDelay = tonumber(Settings.autoRJDelay) or 5
Settings.autoLoop = Settings.autoLoop and true or false

local function saveSettings() swrite(SETTINGS_FILE, enc(Settings)) end

local waypoints = {}
local function loadWaypoints()
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
local function saveWaypoints()
  local out = {}
  for _,p in ipairs(waypoints) do out[#out+1]={x=p.X,y=p.Y,z=p.Z} end
  swrite(WP_FILE, enc(out))
end

-- ===== SECTION 1: WAYPOINTS =====
local waypointContent = newCleanSub("Waypoints", 200)

-- Waypoints List (Scrollable)
local listFrame = Instance.new("Frame")
listFrame.BackgroundColor3 = Theme.bg
listFrame.Size = UDim2.new(1, 0, 1, -50)
listFrame.LayoutOrder = 1
listFrame.Parent = waypointContent
corner(listFrame, 8); stroke(listFrame, Theme.accA, 1).Transparency = .7

local listScroll = Instance.new("ScrollingFrame", listFrame)
listScroll.BackgroundTransparency = 1
listScroll.Size = UDim2.fromScale(1, 1)
listScroll.ScrollBarThickness = 6
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listScroll.ClipsDescendants = true

local listPadding = Instance.new("UIPadding", listScroll)
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 6)
listPadding.PaddingRight = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout", listScroll)
listLayout.Padding = UDim.new(0, 4)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
end)

local function refreshWaypoints()
  for _,c in ipairs(listScroll:GetChildren()) do 
    if c:IsA("Frame") and c.Name == "WaypointRow" then c:Destroy() end 
  end
  
  for i, pos in ipairs(waypoints) do
    local row = Instance.new("Frame")
    row.Name = "WaypointRow"
    row.BackgroundColor3 = Theme.card
    row.Size = UDim2.new(1, 0, 0, 32)
    row.Parent = listScroll
    corner(row, 6); stroke(row, Theme.accA, 1).Transparency = .6

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = string.format("Camp %d (%.0f, %.0f, %.0f)", i, pos.X, pos.Y, pos.Z)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = Theme.text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Size = UDim2.new(1, -100, 1, 0)
    nameLabel.Position = UDim2.fromOffset(8, 0)
    nameLabel.Parent = row

    local tpBtn = Instance.new("TextButton")
    tpBtn.Text = "TP"
    tpBtn.Font = Enum.Font.GothamSemibold
    tpBtn.TextSize = 12
    tpBtn.TextColor3 = Theme.text
    tpBtn.BackgroundColor3 = Theme.accA
    tpBtn.Size = UDim2.new(0, 40, 0, 24)
    tpBtn.Position = UDim2.new(1, -84, 0.5, -12)
    tpBtn.AutoButtonColor = false
    tpBtn.Parent = row
    corner(tpBtn, 6)
    
    local delBtn = Instance.new("TextButton")
    delBtn.Text = "✕"
    delBtn.Font = Enum.Font.GothamBold
    delBtn.TextSize = 12
    delBtn.TextColor3 = Theme.text
    delBtn.BackgroundColor3 = Theme.bad
    delBtn.Size = UDim2.new(0, 40, 0, 24)
    delBtn.Position = UDim2.new(1, -40, 0.5, -12)
    delBtn.AutoButtonColor = false
    delBtn.Parent = row
    corner(delBtn, 6)

    tpBtn.MouseButton1Click:Connect(function()
      safeTP(pos)
      if Settings.moveDance then dance3(pos) end
    end)
    
    delBtn.MouseButton1Click:Connect(function()
      table.remove(waypoints, i)
      refreshWaypoints()
      saveWaypoints()
    end)
  end
end

-- Control Buttons
local controlFrame = Instance.new("Frame")
controlFrame.BackgroundTransparency = 1
controlFrame.Size = UDim2.new(1, 0, 0, 36)
controlFrame.LayoutOrder = 2
controlFrame.Parent = waypointContent

local controlLayout = Instance.new("UIListLayout", controlFrame)
controlLayout.FillDirection = Enum.FillDirection.Horizontal
controlLayout.Padding = UDim.new(0, 8)
controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local setBtn = Instance.new("TextButton")
setBtn.Text = "Set Waypoint"
setBtn.Font = Enum.Font.GothamSemibold
setBtn.TextSize = 14
setBtn.TextColor3 = Theme.text
setBtn.BackgroundColor3 = Theme.accA
setBtn.Size = UDim2.new(0, 130, 1, 0)
setBtn.AutoButtonColor = false
setBtn.Parent = controlFrame
corner(setBtn, 8); stroke(setBtn, Theme.accB, 1).Transparency = .3

local deleteBtn = Instance.new("TextButton")
deleteBtn.Text = "Delete Last"
deleteBtn.Font = Enum.Font.GothamSemibold
deleteBtn.TextSize = 14
deleteBtn.TextColor3 = Theme.text
deleteBtn.BackgroundColor3 = Theme.card
deleteBtn.Size = UDim2.new(0, 130, 1, 0)
deleteBtn.AutoButtonColor = false
deleteBtn.Parent = controlFrame
corner(deleteBtn, 8); stroke(deleteBtn, Theme.accA, 1).Transparency = .5

-- Waypoint button logic
local lastPos, lastTime = nil, 0
local function canInsert(pos)
  if not lastPos then return true end
  if (pos - lastPos).Magnitude >= 2 then return true end
  return (tick() - lastTime) > 0.25
end

setBtn.MouseButton1Click:Connect(function()
  local hrp = select(1, HRP()); if not hrp then return end
  local pos = hrp.Position
  if canInsert(pos) then
    table.insert(waypoints, pos)
    lastPos, lastTime = pos, tick()
    refreshWaypoints()
    saveWaypoints()
  end
end)

deleteBtn.MouseButton1Click:Connect(function()
  if #waypoints > 0 then
    table.remove(waypoints, #waypoints)
    refreshWaypoints()
    saveWaypoints()
  end
end)

-- ===== SECTION 2: OPTIONS =====
local optionContent = newCleanSub("Options", 120)

-- Row 1: Delay + Auto Kill
local row1 = Instance.new("Frame")
row1.BackgroundTransparency = 1
row1.Size = UDim2.new(1, 0, 0, 34)
row1.LayoutOrder = 1
row1.Parent = optionContent

local row1Layout = Instance.new("UIListLayout", row1)
row1Layout.FillDirection = Enum.FillDirection.Horizontal
row1Layout.Padding = UDim.new(0, 8)
row1Layout.VerticalAlignment = Enum.VerticalAlignment.Center

local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(0, 60, 1, 0)
delayBox.BackgroundColor3 = Theme.card
delayBox.TextColor3 = Theme.text
delayBox.Text = tostring(Settings.loopDelay)
delayBox.Font = Enum.Font.Gotham
delayBox.TextSize = 14
delayBox.TextXAlignment = Enum.TextXAlignment.Center
delayBox.ClearTextOnFocus = false
delayBox.Parent = row1
corner(delayBox, 8); stroke(delayBox, Theme.accA, 1).Transparency = .5

local killBtn = Instance.new("TextButton")
killBtn.Text = "Auto respawn/kill: " .. (Settings.autoKill and "ON" or "OFF")
killBtn.Font = Enum.Font.GothamSemibold
killBtn.TextSize = 14
killBtn.TextColor3 = Theme.text
killBtn.BackgroundColor3 = Settings.autoKill and Theme.accA or Theme.card
killBtn.Size = UDim2.new(1, -68, 1, 0)
killBtn.AutoButtonColor = false
killBtn.Parent = row1
corner(killBtn, 8); stroke(killBtn, Theme.accA, 1).Transparency = .45

-- Row 2: Dance + Auto Rejoin + Delay
local row2 = Instance.new("Frame")
row2.BackgroundTransparency = 1
row2.Size = UDim2.new(1, 0, 0, 34)
row2.LayoutOrder = 2
row2.Parent = optionContent

local row2Layout = Instance.new("UIListLayout", row2)
row2Layout.FillDirection = Enum.FillDirection.Horizontal
row2Layout.Padding = UDim.new(0, 8)
row2Layout.VerticalAlignment = Enum.VerticalAlignment.Center

local danceBtn = Instance.new("TextButton")
danceBtn.Text = "3x/8stud: " .. (Settings.moveDance and "ON" or "OFF")
danceBtn.Font = Enum.Font.GothamSemibold
danceBtn.TextSize = 14
danceBtn.TextColor3 = Theme.text
danceBtn.BackgroundColor3 = Settings.moveDance and Theme.accA or Theme.card
danceBtn.Size = UDim2.new(0, 110, 1, 0)
danceBtn.AutoButtonColor = false
danceBtn.Parent = row2
corner(danceBtn, 8)

local rjBtn = Instance.new("TextButton")
rjBtn.Text = "Auto rejoin: " .. (Settings.autoRJ and "ON" or "OFF")
rjBtn.Font = Enum.Font.GothamSemibold
rjBtn.TextSize = 14
rjBtn.TextColor3 = Theme.text
rjBtn.BackgroundColor3 = Settings.autoRJ and Theme.accA or Theme.card
rjBtn.Size = UDim2.new(1, -178, 1, 0)
rjBtn.AutoButtonColor = false
rjBtn.Parent = row2
corner(rjBtn, 8)

local rjDelayBox = Instance.new("TextBox")
rjDelayBox.Size = UDim2.new(0, 60, 1, 0)
rjDelayBox.BackgroundColor3 = Theme.card
rjDelayBox.TextColor3 = Theme.text
rjDelayBox.Text = tostring(Settings.autoRJDelay)
rjDelayBox.Font = Enum.Font.Gotham
rjDelayBox.TextSize = 14
rjDelayBox.TextXAlignment = Enum.TextXAlignment.Center
rjDelayBox.ClearTextOnFocus = false
rjDelayBox.Parent = row2
corner(rjDelayBox, 8); stroke(rjDelayBox, Theme.accA, 1).Transparency = .5

-- ===== SECTION 3: AUTO LOOP =====
local loopContent = newCleanSub("Auto Loop", 80)

local loopBtn = Instance.new("TextButton")
loopBtn.Text = "Auto Loop: " .. (Settings.autoLoop and "ON" or "OFF")
loopBtn.Font = Enum.Font.GothamSemibold
loopBtn.TextSize = 16
loopBtn.TextColor3 = Theme.text
loopBtn.BackgroundColor3 = Settings.autoLoop and Theme.accA or Theme.card
loopBtn.Size = UDim2.new(1, 0, 0, 40)
loopBtn.AutoButtonColor = false
loopBtn.Parent = loopContent
corner(loopBtn, 10); stroke(loopBtn, Theme.accB, 1).Transparency = .3

-- ===== LOGIC & EVENT HANDLERS =====
local looping = false

-- Settings handlers
delayBox.FocusLost:Connect(function()
  local v = tonumber(delayBox.Text) or Settings.loopDelay
  v = math.clamp(math.floor(v + 0.5), 1, 60)
  Settings.loopDelay = v
  delayBox.Text = tostring(v)
  saveSettings()
end)

killBtn.MouseButton1Click:Connect(function()
  Settings.autoKill = not Settings.autoKill
  killBtn.Text = "Auto respawn/kill: " .. (Settings.autoKill and "ON" or "OFF")
  killBtn.BackgroundColor3 = Settings.autoKill and Theme.accA or Theme.card
  saveSettings()
end)

danceBtn.MouseButton1Click:Connect(function()
  Settings.moveDance = not Settings.moveDance
  danceBtn.Text = "3x/8stud: " .. (Settings.moveDance and "ON" or "OFF")
  danceBtn.BackgroundColor3 = Settings.moveDance and Theme.accA or Theme.card
  saveSettings()
end)

rjDelayBox.FocusLost:Connect(function()
  local v = tonumber(rjDelayBox.Text) or Settings.autoRJDelay
  v = math.clamp(math.floor(v + 0.5), 2, 120)
  Settings.autoRJDelay = v
  rjDelayBox.Text = tostring(v)
  saveSettings()
end)

-- Auto Rejoin Logic
local PlaceId, JobId = game.PlaceId, game.JobId
local rjOn, rjConn = false, nil

local function doRejoin()
  if #Players:GetPlayers() <= 1 then
    LP:Kick("\nRejoining...")
    task.wait()
    TeleportService:Teleport(PlaceId, LP)
  else
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LP)
  end
end

local function startRejoin()
  if rjConn then rjConn:Disconnect() end
  rjConn = GuiService.ErrorMessageChanged:Connect(function() task.defer(doRejoin) end)
  rjOn = true
  task.spawn(function()
    while rjOn do
      local delay = math.clamp(Settings.autoRJDelay or 5, 2, 120)
      for _ = 1, delay * 10 do
        if not rjOn then break end
        task.wait(0.1)
      end
      if not rjOn then break end
      doRejoin()
    end
  end)
end

local function stopRejoin()
  rjOn = false
  if rjConn then rjConn:Disconnect(); rjConn = nil end
end

rjBtn.MouseButton1Click:Connect(function()
  Settings.autoRJ = not Settings.autoRJ
  rjBtn.Text = "Auto rejoin: " .. (Settings.autoRJ and "ON" or "OFF")
  rjBtn.BackgroundColor3 = Settings.autoRJ and Theme.accA or Theme.card
  saveSettings()
  
  if Settings.autoRJ then startRejoin() else stopRejoin() end
end)

-- Auto Loop Logic
local function setAutoLoop(enabled)
  Settings.autoLoop = enabled
  loopBtn.Text = "Auto Loop: " .. (Settings.autoLoop and "ON" or "OFF")
  loopBtn.BackgroundColor3 = Settings.autoLoop and Theme.accA or Theme.card
  saveSettings()

  if Settings.autoLoop and not looping then
    looping = true
    task.spawn(function()
      while Settings.autoLoop do
        if #waypoints == 0 then
          task.wait(0.15)
        else
          local delay = math.clamp(Settings.loopDelay or 3, 1, 60)
          for i = 1, #waypoints do
            if not Settings.autoLoop then break end
            local pos = waypoints[i]
            safeTP(pos)
            if Settings.moveDance then dance3(pos) end
            
            local startTime = tick()
            while Settings.autoLoop and tick() - startTime < delay do
              task.wait(0.05)
            end
            
            if Settings.autoLoop and i == #waypoints and Settings.autoKill then
              local hum = select(2, HRP())
              if hum then hum.Health = 0 end
              LP.CharacterAdded:Wait()
              task.wait(0.8)
            end
          end
        end
        task.wait(0.05)
      end
      looping = false
    end)
  end
end

loopBtn.MouseButton1Click:Connect(function()
  setAutoLoop(not Settings.autoLoop)
end)

-- ===== INITIALIZATION =====
loadWaypoints()
refreshWaypoints()

if Settings.autoRJ then startRejoin() end
if Settings.autoLoop then setAutoLoop(true) end

print("[danuu • Manual] Clean version loaded ✓")

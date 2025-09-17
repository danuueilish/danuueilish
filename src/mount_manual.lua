-- src/mount_manual.lua (With Minimize Feature)
-- Manual Waypoints • Collapsible by Default
local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Manual"] then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
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

-- ===== MINIMIZE FUNCTIONALITY =====
local secRoot = UI.MountSections["Manual"]
local isMinimized = true -- START MINIMIZED BY DEFAULT

-- Create Main Toggle Button (always visible at top)
local mainToggle = Instance.new("TextButton")
mainToggle.Name = "MainToggle"
mainToggle.AutoButtonColor = false
mainToggle.Text = "+ Manual Waypoints"
mainToggle.Font = Enum.Font.GothamBold
mainToggle.TextSize = 16
mainToggle.TextColor3 = Theme.accA
mainToggle.BackgroundColor3 = Theme.card
mainToggle.Size = UDim2.new(1, -8, 0, 40)
mainToggle.Position = UDim2.fromOffset(4, 4)
mainToggle.Parent = secRoot
corner(mainToggle, 10)
stroke(mainToggle, Theme.accA, 1).Transparency = .4

-- Container for all content (initially hidden)
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.BackgroundTransparency = 1
contentContainer.Size = UDim2.new(1, -8, 1, -52)
contentContainer.Position = UDim2.fromOffset(4, 48)
contentContainer.Visible = false -- START HIDDEN
contentContainer.Parent = secRoot

local contentLayout = Instance.new("UIListLayout", contentContainer)
contentLayout.Padding = UDim.new(0, 10)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Toggle Function
local function toggleMinimize()
  isMinimized = not isMinimized
  contentContainer.Visible = not isMinimized
  mainToggle.Text = (isMinimized and "+" or "–") .. " Manual Waypoints"
  
  -- Smooth transition
  local targetSize = isMinimized and UDim2.new(1, -4, 0, 50) or UDim2.new(1, -4, 0, 680)
  TweenService:Create(secRoot, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
    Size = targetSize
  }):Play()
end

mainToggle.MouseButton1Click:Connect(toggleMinimize)

-- ===== CLEAN SUB-SECTION BUILDER (Modified for contentContainer) =====
local function newCleanSub(titleText, height)
  local container = Instance.new("Frame")
  container.BackgroundColor3 = Theme.card
  container.Size = UDim2.new(1, 0, 0, height or 200)
  container.Parent = contentContainer -- Changed parent
  container.ClipsDescendants = true
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
  contentLayout.Padding = UDim.new(0, 10)
  contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
  
  return content, container
end

-- ===== TOGGLE SWITCH BUILDER =====
local function createToggleSwitch(parent, initialState, callback)
  local switchFrame = Instance.new("Frame")
  switchFrame.BackgroundColor3 = initialState and Theme.good or Color3.fromRGB(60, 60, 60)
  switchFrame.Size = UDim2.new(0, 48, 0, 24)
  switchFrame.Parent = parent
  corner(switchFrame, 12)
  
  local knob = Instance.new("Frame")
  knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
  knob.Size = UDim2.new(0, 20, 0, 20)
  knob.Position = initialState and UDim2.new(0, 26, 0, 2) or UDim2.new(0, 2, 0, 2)
  knob.Parent = switchFrame
  corner(knob, 10)
  
  local clickDetector = Instance.new("TextButton")
  clickDetector.BackgroundTransparency = 1
  clickDetector.Size = UDim2.fromScale(1, 1)
  clickDetector.Text = ""
  clickDetector.Parent = switchFrame
  
  local state = initialState
  
  clickDetector.MouseButton1Click:Connect(function()
    state = not state
    
    local bgTween = TweenService:Create(switchFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
      BackgroundColor3 = state and Theme.good or Color3.fromRGB(60, 60, 60)
    })
    
    local knobTween = TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
      Position = state and UDim2.new(0, 26, 0, 2) or UDim2.new(0, 2, 0, 2)
    })
    
    bgTween:Play()
    knobTween:Play()
    
    if callback then callback(state) end
  end)
  
  return switchFrame, function() return state end, function(newState)
    state = newState
    switchFrame.BackgroundColor3 = state and Theme.good or Color3.fromRGB(60, 60, 60)
    knob.Position = state and UDim2.new(0, 26, 0, 2) or UDim2.new(0, 2, 0, 2)
  end
end

-- ===== ROW BUILDER =====
local function createOptionRow(parent, labelText, hasInputBox, initialValue, toggleState, onInputChange, onToggleChange)
  local row = Instance.new("Frame")
  row.BackgroundTransparency = 1
  row.Size = UDim2.new(1, 0, 0, 36)
  row.Parent = parent
  
  local label = Instance.new("TextLabel")
  label.BackgroundTransparency = 1
  label.Text = labelText
  label.Font = Enum.Font.GothamSemibold
  label.TextSize = 14
  label.TextColor3 = Theme.text
  label.TextXAlignment = Enum.TextXAlignment.Left
  label.Size = UDim2.new(0, 140, 1, 0)
  label.Position = UDim2.fromOffset(0, 0)
  label.Parent = row
  
  local inputBox = nil
  if hasInputBox then
    inputBox = Instance.new("TextBox")
    inputBox.BackgroundColor3 = Theme.bg
    inputBox.TextColor3 = Theme.text
    inputBox.Text = tostring(initialValue or "")
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 14
    inputBox.TextXAlignment = Enum.TextXAlignment.Center
    inputBox.ClearTextOnFocus = false
    inputBox.Size = UDim2.new(0, 70, 0, 28)
    inputBox.Position = UDim2.new(1, -126, 0.5, -14)
    inputBox.Parent = row
    corner(inputBox, 8)
    stroke(inputBox, Theme.accA, 1).Transparency = .6
    
    if onInputChange then
      inputBox.FocusLost:Connect(function()
        onInputChange(inputBox.Text)
      end)
    end
  end
  
  local toggle, getState, setState = createToggleSwitch(row, toggleState, onToggleChange)
  toggle.Position = UDim2.new(1, -52, 0.5, -12)
  
  return row, inputBox, getState, setState
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
local waypointContent = newCleanSub("Waypoints", 180)
waypointContent.Parent.LayoutOrder = 1

-- [Waypoints List Code - SAMA SEPERTI SEBELUMNYA]
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
    row.Size = UDim2.new(1, 0, 0, 28)
    row.Parent = listScroll
    corner(row, 6)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = string.format("Camp %d (%.0f, %.0f, %.0f)", i, pos.X, pos.Y, pos.Z)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 12
    nameLabel.TextColor3 = Theme.text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Size = UDim2.new(1, -90, 1, 0)
    nameLabel.Position = UDim2.fromOffset(8, 0)
    nameLabel.Parent = row

    local tpBtn = Instance.new("TextButton")
    tpBtn.Text = "TP"
    tpBtn.Font = Enum.Font.GothamSemibold
    tpBtn.TextSize = 11
    tpBtn.TextColor3 = Theme.text
    tpBtn.BackgroundColor3 = Theme.accA
    tpBtn.Size = UDim2.new(0, 32, 0, 20)
    tpBtn.Position = UDim2.new(1, -74, 0.5, -10)
    tpBtn.AutoButtonColor = false
    tpBtn.Parent = row
    corner(tpBtn, 6)
    
    local delBtn = Instance.new("TextButton")
    delBtn.Text = "✕"
    delBtn.Font = Enum.Font.GothamBold
    delBtn.TextSize = 11
    delBtn.TextColor3 = Theme.text
    delBtn.BackgroundColor3 = Theme.bad
    delBtn.Size = UDim2.new(0, 32, 0, 20)
    delBtn.Position = UDim2.new(1, -38, 0.5, -10)
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
controlFrame.Size = UDim2.new(1, 0, 0, 32)
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
setBtn.TextSize = 13
setBtn.TextColor3 = Theme.text
setBtn.BackgroundColor3 = Theme.accA
setBtn.Size = UDim2.new(0, 120, 1, 0)
setBtn.AutoButtonColor = false
setBtn.Parent = controlFrame
corner(setBtn, 8)

local deleteBtn = Instance.new("TextButton")
deleteBtn.Text = "Delete Last"
deleteBtn.Font = Enum.Font.GothamSemibold
deleteBtn.TextSize = 13
deleteBtn.TextColor3 = Theme.text
deleteBtn.BackgroundColor3 = Theme.card
deleteBtn.Size = UDim2.new(0, 120, 1, 0)
deleteBtn.AutoButtonColor = false
deleteBtn.Parent = controlFrame
corner(deleteBtn, 8)

-- ===== SECTION 2: OPTIONS =====
local optionContent = newCleanSub("Options", 250)
optionContent.Parent.LayoutOrder = 2

-- [All option rows code - SAMA SEPERTI SEBELUMNYA]
local delayRow, delayBox, _, setDelayState = createOptionRow(
  optionContent, "Delay Teleport", true, Settings.loopDelay, false, 
  function(text)
    local v = tonumber(text) or Settings.loopDelay
    v = math.clamp(math.floor(v + 0.5), 1, 60)
    Settings.loopDelay = v
    delayBox.Text = tostring(v)
    saveSettings()
  end, nil
)

local killRow, _, getKillState, setKillState = createOptionRow(
  optionContent, "Auto Kill", false, nil, Settings.autoKill,
  nil, function(state)
    Settings.autoKill = state
    saveSettings()
  end
)

local danceRow, _, getDanceState, setDanceState = createOptionRow(
  optionContent, "3x/8stud", false, nil, Settings.moveDance,
  nil, function(state)
    Settings.moveDance = state
    saveSettings()
  end
)

local rjRow, rjDelayBox, getRjState, setRjState = createOptionRow(
  optionContent, "Auto Rejoin", true, Settings.autoRJDelay, Settings.autoRJ,
  function(text)
    local v = tonumber(text) or Settings.autoRJDelay
    v = math.clamp(math.floor(v + 0.5), 2, 120)
    Settings.autoRJDelay = v
    rjDelayBox.Text = tostring(v)
    saveSettings()
  end, function(state)
    Settings.autoRJ = state
    saveSettings()
    if Settings.autoRJ then startRejoin() else stopRejoin() end
  end
)

local autoLoopRow, _, getAutoLoopState, setAutoLoopState = createOptionRow(
  optionContent, "Auto Loop", false, nil, Settings.autoLoop,
  nil, function(state)
    Settings.autoLoop = state
    saveSettings()
    setAutoLoop(state)
  end
)

-- ===== AUTO LOOP LOGIC =====
local looping = false

function setAutoLoop(enabled)
  if enabled and not looping then
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

-- ===== EVENT HANDLERS =====
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

function startRejoin()
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

function stopRejoin()
  rjOn = false
  if rjConn then rjConn:Disconnect(); rjConn = nil end
end

-- ===== INITIALIZATION =====
-- Set initial minimize state
secRoot.Size = UDim2.new(1, -4, 0, 50) -- Start minimized

loadWaypoints()
refreshWaypoints()

if Settings.autoRJ then startRejoin() end
if Settings.autoLoop then setAutoLoop(true) end

print("[danuu • Manual] Collapsible version loaded ✓")

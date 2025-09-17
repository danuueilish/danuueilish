-- src/mount_atin.lua (Fixed Dropdown Positioning Version)
-- Mount Atin : Checkpoint + Poseidon Quest (rapi + aman + collapsible + fixed dropdown)
local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Mount Atin"] then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
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

----------------------------------------------------------------
-- EXPAND/COLLAPSE SETUP
----------------------------------------------------------------
local secRoot = UI.MountSections["Mount Atin"]
local isMinimized = true -- START MINIMIZED BY DEFAULT

-- Create Main Toggle Button (always visible at top)
local mainToggle = Instance.new("TextButton")
mainToggle.Name = "MainToggle"
mainToggle.AutoButtonColor = false
mainToggle.Text = "+ Mount Atin"
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

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function HRP()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end

-- Teleport aman: pad sementara + nolkan velocity biar gak jatuh
local function safeTP(pos)
  local hrp, hum = HRP(); if not hrp then return false end
  local pad = Instance.new("Part")
  pad.Anchored, pad.CanCollide, pad.CanQuery, pad.CanTouch = true, true, false, false
  pad.Transparency = 1
  pad.Size = Vector3.new(16,1,16)
  pad.Position = pos - Vector3.new(0,3,0)
  pad.Name = "danuu_temp_pad"
  pad.Parent = workspace

  hrp.AssemblyLinearVelocity = Vector3.zero
  hrp.AssemblyAngularVelocity = Vector3.zero
  if hum then hum:ChangeState(Enum.HumanoidStateType.Landed) end

  task.wait(0.03)
  hrp.CFrame = CFrame.new(pos + Vector3.new(0,2.4,0))
  task.delay(0.6, function() if pad then pad:Destroy() end end)
  return true
end

local function fireAllPrompts(root, holdTime)
  if not root then return false end
  local ok = false
  for _,pp in ipairs(root:GetDescendants()) do
    if pp:IsA("ProximityPrompt") then
      ok = true
      pcall(function() fireproximityprompt(pp, holdTime or 1.0) end)
    end
  end
  return ok
end

local function findOneByKeywords(...)
  local keys = {...}
  for _,inst in ipairs(workspace:GetDescendants()) do
    if inst:IsA("BasePart") or inst:IsA("Model") then
      local name = (inst.Name or ""):lower()
      local hit = true
      for _,k in ipairs(keys) do
        if not string.find(name, k:lower(), 1, true) then hit=false break end
      end
      if hit then return inst end
    end
  end
end

local function posFrom(inst)
  if not inst then return end
  if inst:IsA("BasePart") then return inst.Position end
  if inst.PrimaryPart then return inst.PrimaryPart.Position end
  local cf; pcall(function() cf = inst:GetPivot() end)
  return cf and cf.Position or nil
end

----------------------------------------------------------------
-- UI SUB-SECTIONS (Modified to use contentContainer)
----------------------------------------------------------------
local function newSub(titleText)
  local box = Instance.new("Frame")
  box.BackgroundColor3 = Theme.card
  box.Size = UDim2.new(1,-16,0,60)
  box.Parent = contentContainer -- Changed from secRoot to contentContainer
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
-- SUB: CHECKPOINT (dropdown kanan + Go To)
----------------------------------------------------------------
local cpInner = newSub("Checkpoint")

-- Row: [dropdown + GoTo]
local row = Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,36); row.Parent=cpInner
local h = Instance.new("UIListLayout", row)
h.FillDirection=Enum.FillDirection.Horizontal; h.Padding=UDim.new(0,8); h.VerticalAlignment=Enum.VerticalAlignment.Center

-- container kanan full width
local right = Instance.new("Frame")
right.BackgroundTransparency=1; right.Size=UDim2.new(1,0,1,0); right.Parent=row
local hr = Instance.new("UIListLayout", right)
hr.FillDirection=Enum.FillDirection.Horizontal; hr.Padding=UDim.new(0,8)
hr.HorizontalAlignment = Enum.HorizontalAlignment.Left
hr.VerticalAlignment = Enum.VerticalAlignment.Center

-- Dropdown button
local dd = Instance.new("TextButton")
dd.AutoButtonColor=false; dd.Text="Pilih checkpoint..."
dd.Font=Enum.Font.GothamSemibold; dd.TextSize=14; dd.TextColor3=Theme.text
dd.TextWrapped=false; dd.TextTruncate=Enum.TextTruncate.AtEnd
dd.BackgroundColor3=Theme.card; dd.Size=UDim2.new(0,260,1,0); dd.Parent=right
corner(dd,8); stroke(dd,Theme.accA,1).Transparency=.45

-- Panel list (ditaruh di contentContainer agar positioning benar)
local panel = Instance.new("Frame")
panel.Visible=false; panel.BackgroundColor3=Theme.card
panel.Size=UDim2.new(0,260,0,184); panel.Parent=contentContainer -- FIXED: Parent ke contentContainer
panel.ClipsDescendants=true; panel.ZIndex=5
corner(panel,8); stroke(panel,Theme.accB,1).Transparency=.35

local listScroll = Instance.new("ScrollingFrame", panel)
listScroll.BackgroundTransparency=1; listScroll.Size=UDim2.fromScale(1,1)
listScroll.ScrollBarThickness=6; listScroll.CanvasSize=UDim2.new(0,0,0,0)
listScroll.ZIndex=6; listScroll.ClipsDescendants=true
local l = Instance.new("UIListLayout", listScroll); l.Padding=UDim.new(0,6)
l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  listScroll.CanvasSize=UDim2.new(0,0,0,l.AbsoluteContentSize.Y+8)
end)

-- FIXED: Posisi dropdown list calculation
local function placePanel()
  if not contentContainer.Visible then return end -- Don't position if collapsed
  
  local containerAbs = contentContainer.AbsolutePosition
  local containerSize = contentContainer.AbsoluteSize
  local abs = dd.AbsolutePosition
  local ddSize = dd.AbsoluteSize
  local margin = 8
  local width = 260

  local x = abs.X - containerAbs.X
  local y = abs.Y - containerAbs.Y + ddSize.Y + 6

  if x < margin then x = margin end
  if x + width + margin > containerSize.X then x = containerSize.X - width - margin end

  local maxH = math.min(224, containerSize.Y - y - margin)
  panel.Size = UDim2.new(0, width, 0, math.max(120, maxH))
  panel.Position = UDim2.fromOffset(x, y)
end

-- Data CP
local checkpoints = {
  {"Basecamp",               Vector3.new(  16.501,   54.470, -1082.821)},
  {"Summit Leaderboard",     Vector3.new(  31.554,   53.176, -1030.635)},
  {"CP1",                    Vector3.new(   3.000,   11.911,  -408.000)},
  {"CP2",                    Vector3.new(-184.000,  127.344,   409.000)},
  {"CP3",                    Vector3.new(-165.000,  228.957,   653.000)},
  {"CP4",                    Vector3.new( -38.001,  405.875,   615.998)},
  {"CP5",                    Vector3.new( 130.396,  650.989,   613.836)},
  {"CP6",                    Vector3.new(-246.376,  665.037,   734.127)},
  {"CP7",                    Vector3.new(-684.143,  640.055,   867.515)},
  {"CP8",                    Vector3.new(-658.021,  687.758,  1458.335)},
  {"CP9",                    Vector3.new(-508.000,  902.192,  1868.000)},
  {"CP10",                   Vector3.new(  61.111,  949.259,  2088.859)},
  {"CP11",                   Vector3.new(  52.063,  980.809,  2450.589)},
  {"CP12",                   Vector3.new(  72.000, 1096.188,  2457.000)},
  {"CP13",                   Vector3.new( 262.000, 1269.363,  2038.000)},
  {"CP14",                   Vector3.new(-419.000, 1301.437,  2394.000)},
  {"CP15",                   Vector3.new(-773.054, 1313.202,  2664.506)},
  {"CP16",                   Vector3.new(-837.697, 1474.366,  2625.771)},
  {"CP17",                   Vector3.new(-468.798, 1464.933,  2769.276)},
  {"CP18",                   Vector3.new(-467.867, 1536.609,  2836.109)},
  {"CP19",                   Vector3.new(-386.000, 1639.622,  2794.000)},
  {"CP20",                   Vector3.new(-208.299, 1665.051,  2749.506)},
  {"CP21",                   Vector3.new(-232.923, 1741.332,  2791.862)},
  {"CP22",                   Vector3.new(-424.331, 1739.924,  2798.055)},
  {"CP23",                   Vector3.new(-423.647, 1711.897,  3420.069)},
  {"CP24",                   Vector3.new(  70.991, 1717.957,  3427.220)},
  {"CP25",                   Vector3.new( 435.644, 1719.855,  3430.871)},
  {"CP26",                   Vector3.new( 625.421, 1798.638,  3433.288)},
  {"Summit",                 Vector3.new( 781.809, 2162.143,  3920.971)},
  {"Glider",                 Vector3.new( 866.637,   12.298,  -584.917)},
  {"Tugu Summit",            Vector3.new( 113.362, 2446.251,  3479.762)},
  {"NPC Anomali CP9",        Vector3.new(-485.513, 900.661,  1871.908)},
  {"Bendera CP9",            Vector3.new(-599.214, 785.941,  2030.948)},
  {"NPC Anomali CP13",       Vector3.new( 254.502, 1267.814,  2042.323)},
  {"Bendera CP13",           Vector3.new( 302.553, 1062.164,  2279.954)},
  {"NPC Anomali Summit",     Vector3.new( 689.275, 2195.028,  4010.853)},
  {"Bendera Summit",         Vector3.new( 954.704, 2108.575,  3583.613)},
  {"Mr Bus CP13",            Vector3.new( 153.903, 1088.369,  1953.853)},
  {"Mr Bus Summit",          Vector3.new( 638.770, 2203.497,  4207.933)},
}

local selectedIndex
for i,entry in ipairs(checkpoints) do
  local b=Instance.new("TextButton")
  b.AutoButtonColor=false; b.Text=entry[1]; b.Font=Enum.Font.Gotham; b.TextSize=14; b.TextColor3=Theme.text
  b.TextWrapped=false; b.TextTruncate=Enum.TextTruncate.AtEnd
  b.BackgroundColor3=Color3.fromRGB(90,74,140); b.Size=UDim2.new(1,-12,0,32); b.Parent=listScroll; b.ZIndex=7
  corner(b,8)
  b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(110,90,170) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(90,74,140) end)
  b.MouseButton1Click:Connect(function() selectedIndex=i; dd.Text=entry[1]; panel.Visible=false end)
end

dd.MouseButton1Click:Connect(function() placePanel(); panel.Visible=not panel.Visible end)
UIS.InputBegan:Connect(function(input,gp)
  if gp or not panel.Visible or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
  local p=input.Position
  local inDD = p.X>=dd.AbsolutePosition.X and p.X<=dd.AbsolutePosition.X+dd.AbsoluteSize.X and p.Y>=dd.AbsolutePosition.Y and p.Y<=dd.AbsolutePosition.Y+dd.AbsoluteSize.Y
  local inPanel = p.X>=panel.AbsolutePosition.X and p.X<=panel.AbsolutePosition.X+panel.AbsoluteSize.X and p.Y>=panel.AbsolutePosition.Y and p.Y<=panel.AbsolutePosition.Y+panel.AbsoluteSize.Y
  if not inDD and not inPanel then panel.Visible=false end
end)

-- Tombol Go To
local go = Instance.new("TextButton")
go.AutoButtonColor=false; go.Text="Go To"
go.Font=Enum.Font.GothamSemibold; go.TextSize=14; go.TextColor3=Theme.text
go.BackgroundColor3=Theme.accA; go.Size=UDim2.new(0,120,1,0); go.Parent=right
corner(go,8); stroke(go,Theme.accB,1).Transparency=.3
go.MouseButton1Click:Connect(function()
  if not selectedIndex then dd.Text="Pilih checkpoint dulu…"; return end
  safeTP(checkpoints[selectedIndex][2])
end)

-- Catatan
do
  local note = Instance.new("TextLabel")
  note.BackgroundTransparency=1; note.TextWrapped=true; note.TextColor3=Theme.text2; note.Font=Enum.Font.Gotham; note.TextSize=13
  note.Text="Pilih checkpoint di dropdown (kanan) lalu tekan 'Go To' untuk teleport."
  note.Size=UDim2.new(1,0,0,30); note.Parent=cpInner
end

----------------------------------------------------------------
-- SUB: AUTO SUMMIT
----------------------------------------------------------------
local Http            = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService      = game:GetService("GuiService")

local asInner = newSub("Auto Summit")

-- Cara Pakai
do
  local t = Instance.new("TextLabel")
  t.BackgroundTransparency=1
  t.TextWrapped=true
  t.Font=Enum.Font.Gotham
  t.TextSize=13
  t.TextColor3=Theme.text2
  t.Text = "Cara Pakai:\n1) Pastikan script auto-execute.\n2) Masukkan delay sesuai device (default 3s). Disarankan ≥3s biar sempat mematikan toggle.\n3) Isi delay Auto Rejoin (disarankan 1–5s di atas delay loop; default 5s).\n4) Nyalakan toggle-nya dan tinggal tidur 😴."
  t.Size = UDim2.new(1,0,0,64)
  t.Parent = asInner
end

-- Baris 1: [Box delay Auto Loop] [Toggle Auto Loop]
local asRow1 = Instance.new("Frame"); asRow1.BackgroundTransparency=1; asRow1.Size=UDim2.new(1,0,0,34); asRow1.Parent=asInner
local asRow1Lay = Instance.new("UIListLayout", asRow1); asRow1Lay.FillDirection=Enum.FillDirection.Horizontal; asRow1Lay.Padding=UDim.new(0,8)

local loopBox = Instance.new("TextBox")
loopBox.Size=UDim2.new(0.6, -4, 1, 0)
loopBox.BackgroundColor3=Theme.card
loopBox.TextColor3=Theme.text
loopBox.PlaceholderText="Delay Auto Loop (detik) • default 3"
loopBox.PlaceholderColor3=Theme.text2
loopBox.ClearTextOnFocus=false
loopBox.Text=""
loopBox.Font=Enum.Font.Gotham
loopBox.TextSize=14
loopBox.TextTruncate=Enum.TextTruncate.AtEnd
corner(loopBox,8); stroke(loopBox,Theme.accA,1).Transparency=.5
loopBox.Parent = asRow1

local loopToggle = Instance.new("TextButton")
loopToggle.Size=UDim2.new(0.4, -4, 1, 0)
loopToggle.Text="Auto Loop: OFF"
loopToggle.Font=Enum.Font.GothamSemibold
loopToggle.TextSize=14
loopToggle.TextColor3=Theme.text
loopToggle.BackgroundColor3=Theme.card
loopToggle.AutoButtonColor=false
corner(loopToggle,8); stroke(loopToggle,Theme.accA,1).Transparency=.5
loopToggle.Parent = asRow1

-- Baris 2: [Box delay Auto Rejoin] [Toggle Auto Rejoin]
local asRow2 = Instance.new("Frame"); asRow2.BackgroundTransparency=1; asRow2.Size=UDim2.new(1,0,0,34); asRow2.Parent=asInner
local asRow2Lay = Instance.new("UIListLayout", asRow2); asRow2Lay.FillDirection=Enum.FillDirection.Horizontal; asRow2Lay.Padding=UDim.new(0,8)

local rjBox = Instance.new("TextBox")
rjBox.Size=UDim2.new(0.6, -4, 1, 0)
rjBox.BackgroundColor3=Theme.card
rjBox.TextColor3=Theme.text
rjBox.PlaceholderText="Delay Auto Rejoin (detik) • default 5"
rjBox.PlaceholderColor3=Theme.text2
rjBox.ClearTextOnFocus=false
rjBox.Text=""
rjBox.Font=Enum.Font.Gotham
rjBox.TextSize=14
rjBox.TextTruncate=Enum.TextTruncate.AtEnd
corner(rjBox,8); stroke(rjBox,Theme.accA,1).Transparency=.5
rjBox.Parent = asRow2

local rjToggle = Instance.new("TextButton")
rjToggle.Size=UDim2.new(0.4, -4, 1, 0)
rjToggle.Text="Auto Rejoin: OFF"
rjToggle.Font=Enum.Font.GothamSemibold
rjToggle.TextSize=14
rjToggle.TextColor3=Theme.text
rjToggle.BackgroundColor3=Theme.card
rjToggle.AutoButtonColor=false
corner(rjToggle,8); stroke(rjToggle,Theme.accA,1).Transparency=.5
rjToggle.Parent = asRow2

-- Logic Auto Summit
local fileOK = (writefile and readfile and isfile) and true or false
local AS_FILE = ("danuu_as_%s.json"):format(tostring(game.PlaceId))

local summitPos = Vector3.new(781.809, 2162.143, 3920.971)

local function summitDance(center)
  local hrp = select(1, HRP()); if not hrp then return end
  local dir = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or hrp.CFrame.LookVector
  dir = Vector3.new(dir.X,0,dir.Z); if dir.Magnitude < 0.1 then dir = Vector3.new(1,0,0) end; dir = dir.Unit
  local R = 8
  for _=1,3 do
    hrp.CFrame = CFrame.new(center + dir*R + Vector3.new(0,2.4,0)); task.wait(0.12)
    hrp.CFrame = CFrame.new(center - dir*R + Vector3.new(0,2.4,0)); task.wait(0.12)
    hrp.CFrame = CFrame.new(center + Vector3.new(0,2.4,0));         task.wait(0.12)
  end
end

local state = {
  loopDelay = 3,
  rjDelay   = 5,
  loopOn    = false,
  rjOn      = false,
}

local function loadAS()
  if not fileOK or not isfile(AS_FILE) then return end
  local ok, data = pcall(function() return Http:JSONDecode(readfile(AS_FILE)) end)
  if ok and typeof(data)=="table" then
    if tonumber(data.loopDelay) then state.loopDelay = math.max(0, tonumber(data.loopDelay)) end
    if tonumber(data.rjDelay)   then state.rjDelay   = math.max(0, tonumber(data.rjDelay))   end
    state.loopOn = data.loopOn and true or false
    state.rjOn   = data.rjOn   and true or false
  end
end

local function saveAS()
  if not fileOK then return end
  pcall(function()
    writefile(AS_FILE, Http:JSONEncode({
      loopDelay = state.loopDelay,
      rjDelay   = state.rjDelay,
      loopOn    = state.loopOn,
      rjOn      = state.rjOn,
    }))
  end)
end

local function refreshASUI()
  loopToggle.Text = "Auto Loop: " .. (state.loopOn and "ON" or "OFF")
  rjToggle.Text   = "Auto Rejoin: " .. (state.rjOn and "ON" or "OFF")
  if loopBox.Text == "" then loopBox.Text = tostring(state.loopDelay) end
  if rjBox.Text   == "" then rjBox.Text   = tostring(state.rjDelay)   end
end

local function normNumber(s, default)
  local n = tonumber((s or ""):match("[-%d%.]+") or "")
  if not n then return default end
  if n ~= n or n == math.huge or n == -math.huge then return default end
  return math.max(0, n)
end

loadAS(); refreshASUI()

loopBox.FocusLost:Connect(function()
  state.loopDelay = normNumber(loopBox.Text, 3)
  loopBox.Text = tostring(state.loopDelay)
  saveAS()
end)

rjBox.FocusLost:Connect(function()
  state.rjDelay = normNumber(rjBox.Text, 5)
  rjBox.Text = tostring(state.rjDelay)
  saveAS()
end)

loopToggle.MouseButton1Click:Connect(function()
  state.loopOn = not state.loopOn
  refreshASUI()
  saveAS()
end)

-- Auto Rejoin helpers
local function doRJ()
  local placeId, jobId = game.PlaceId, game.JobId
  if #Players:GetPlayers() <= 1 then
    LP:Kick("\nRejoining...")
    task.wait()
    TeleportService:Teleport(placeId, LP)
  else
    TeleportService:TeleportToPlaceInstance(placeId, jobId, LP)
  end
end

local errorConn
rjToggle.MouseButton1Click:Connect(function()
  state.rjOn = not state.rjOn
  refreshASUI()
  saveAS()

  if state.rjOn then
    if not errorConn then
      errorConn = GuiService.ErrorMessageChanged:Connect(function()
        task.defer(doRJ)
      end)
    end
  else
    if errorConn then errorConn:Disconnect(); errorConn=nil end
  end
end)

-- Worker loop
task.spawn(function()
  while secRoot.Parent do
    if state.loopOn then
      safeTP(summitPos)
      summitDance(summitPos)

      local t0 = tick()
      while state.loopOn and tick() - t0 < (state.loopDelay or 3) do
        task.wait(0.05)
      end

      if state.loopOn and state.rjOn then
        local tr0 = tick()
        while state.loopOn and state.rjOn and tick() - tr0 < (state.rjDelay or 5) do
          task.wait(0.05)
        end
        if state.loopOn and state.rjOn then
          doRJ()
        end
      end
    end
    task.wait(0.05)
  end
end)

----------------------------------------------------------------
-- SUB: POSEIDON QUEST (dropdown manual + Auto)
----------------------------------------------------------------
local pq = newSub("Poseidon Quest")

local status = Instance.new("TextLabel")
status.BackgroundTransparency=1; status.TextColor3=Theme.text2; status.Font=Enum.Font.Gotham; status.TextSize=13
status.Text="Status: —"; status.Size=UDim2.new(1,0,0,22); status.Parent=pq
local function setStatus(txt, good) status.Text = "Status: "..txt; status.TextColor3 = good and Theme.good or Theme.text2 end

-- ROW: [Dropdown manual] [Go To]
local prow = Instance.new("Frame"); prow.BackgroundTransparency=1; prow.Size=UDim2.new(1,0,0,36); prow.Parent=pq
local pl = Instance.new("UIListLayout", prow)
pl.FillDirection=Enum.FillDirection.Horizontal; pl.Padding=UDim.new(0,8); pl.VerticalAlignment=Enum.VerticalAlignment.Center

local pRight = Instance.new("Frame")
pRight.BackgroundTransparency=1
pRight.Size = UDim2.new(1, -(120+8), 1, 0)
pRight.Parent = prow

local pLay = Instance.new("UIListLayout", pRight)
pLay.FillDirection=Enum.FillDirection.Horizontal; pLay.Padding=UDim.new(0,8)
pLay.HorizontalAlignment = Enum.HorizontalAlignment.Left
pLay.VerticalAlignment   = Enum.VerticalAlignment.Center

local pdd = Instance.new("TextButton")
pdd.AutoButtonColor=false; pdd.Text="Pilih titik manual (Poseidon)…"
pdd.Font=Enum.Font.GothamSemibold; pdd.TextSize=14; pdd.TextColor3=Theme.text
pdd.TextWrapped=false; pdd.TextTruncate=Enum.TextTruncate.AtEnd
pdd.BackgroundColor3=Theme.card; pdd.Size=UDim2.new(1,0,1,0); pdd.Parent=pRight
corner(pdd,8); stroke(pdd,Theme.accA,1).Transparency=.45

local pGo = Instance.new("TextButton")
pGo.AutoButtonColor=false; pGo.Text="Go To"
pGo.Font=Enum.Font.GothamSemibold; pGo.TextSize=14; pGo.TextColor3=Theme.text
pGo.BackgroundColor3=Theme.accA; pGo.Size=UDim2.new(0,120,1,0); pGo.Parent=prow
corner(pGo,8); stroke(pGo,Theme.accB,1).Transparency=.3

-- Panel list manual (FIXED: Parent ke contentContainer)
local pPanel = Instance.new("Frame")
pPanel.Visible=false; pPanel.BackgroundColor3=Theme.card
pPanel.Size=UDim2.new(0,260,0,184); pPanel.Parent=contentContainer -- FIXED: Parent ke contentContainer
pPanel.ClipsDescendants=true; pPanel.ZIndex=5
corner(pPanel,8); stroke(pPanel,Theme.accB,1).Transparency=.35

local pList = Instance.new("ScrollingFrame", pPanel)
pList.BackgroundTransparency=1; pList.Size=UDim2.fromScale(1,1)
pList.ScrollBarThickness=6; pList.CanvasSize=UDim2.new(0,0,0,0)
pList.ZIndex=6; pList.ClipsDescendants=true
local pUIL = Instance.new("UIListLayout", pList); pUIL.Padding=UDim.new(0,6)
pUIL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  pList.CanvasSize=UDim2.new(0,0,0,pUIL.AbsoluteContentSize.Y+8)
end)

-- FIXED: Posisi dropdown Poseidon calculation
local function placePPanel()
  if not contentContainer.Visible then return end -- Don't position if collapsed
  
  local containerAbs = contentContainer.AbsolutePosition
  local containerSize = contentContainer.AbsoluteSize
  local abs = pdd.AbsolutePosition
  local ddSize = pdd.AbsoluteSize
  local margin, width = 8, 260
  
  local x = abs.X - containerAbs.X
  local y = abs.Y - containerAbs.Y + ddSize.Y + 6
  
  if x < margin then x = margin end
  if x + width + margin > containerSize.X then x = containerSize.X - width - margin end
  
  local maxH = math.min(224, containerSize.Y - y - margin)
  pPanel.Size = UDim2.new(0, width, 0, math.max(120, maxH))
  pPanel.Position = UDim2.fromOffset(x, y)
end

local manualPoints = {
  {"Note 1", Vector3.new(  40.992,  42.024, -1013.635)},
  {"Note 2", Vector3.new( -10.237,  53.219, -1014.791)},
  {"Note 3", Vector3.new(  43.372,  61.132,  -935.566)},
  {"Note 4", Vector3.new(-299.877, -57.069, -1320.913)},
  {"Note 5", Vector3.new( 306.852, -38.959, -1174.354)},
  {"Key Box",Vector3.new( 208.536, -59.058, -1475.871)},
  {"Gate 1", Vector3.new(-295.274,-104.061, -1584.129)},
  {"Final Gate (Code: kampunglidurian)", Vector3.new(-306.079,-116.656,-1453.362)},
  {"Helmet", Vector3.new(-296.419,-116.904, -1403.167)},
}

local selectedManualIndex
for i,entry in ipairs(manualPoints) do
  local b=Instance.new("TextButton")
  b.AutoButtonColor=false; b.Text=entry[1]; b.Font=Enum.Font.Gotham; b.TextSize=14; b.TextColor3=Theme.text
  b.TextWrapped=false; b.TextTruncate=Enum.TextTruncate.AtEnd
  b.BackgroundColor3=Color3.fromRGB(90,74,140); b.Size=UDim2.new(1,-12,0,32); b.Parent=pList; b.ZIndex=7
  corner(b,8)
  b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(110,90,170) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(90,74,140) end)
  b.MouseButton1Click:Connect(function() selectedManualIndex=i; pdd.Text=entry[1]; pPanel.Visible=false end)
end

pdd.MouseButton1Click:Connect(function() placePPanel(); pPanel.Visible=not pPanel.Visible end)
UIS.InputBegan:Connect(function(input,gp)
  if gp or not pPanel.Visible or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
  local p=input.Position
  local inDD = p.X>=pdd.AbsolutePosition.X and p.X<=pdd.AbsolutePosition.X+pdd.AbsoluteSize.X and p.Y>=pdd.AbsolutePosition.Y and p.Y<=pdd.AbsolutePosition.Y+pdd.AbsoluteSize.Y
  local inPanel = p.X>=pPanel.AbsolutePosition.X and p.X<=pPanel.AbsolutePosition.X+pPanel.AbsoluteSize.X and p.Y>=pPanel.AbsolutePosition.Y and p.Y<=pPanel.AbsolutePosition.Y+pPanel.AbsoluteSize.Y
  if not inDD and not inPanel then pPanel.Visible=false end
end)

pGo.MouseButton1Click:Connect(function()
  if not selectedManualIndex then pdd.Text="Pilih titik dulu…"; return end
  local pos = manualPoints[selectedManualIndex][2]
  safeTP(pos)
end)

-- Tombol Auto Quest
local function mkBtn(txt, cb)
  local b=Instance.new("TextButton")
  b.AutoButtonColor=false; b.Text=txt; b.Font=Enum.Font.GothamSemibold; b.TextSize=14; b.TextColor3=Theme.text
  b.BackgroundColor3=Theme.accA; b.Size=UDim2.new(1,0,0,36); b.Parent=pq
  corner(b,8); stroke(b,Theme.accB,1).Transparency=.35
  b.MouseButton1Click:Connect(function() task.spawn(cb) end)
  return b
end

mkBtn("Auto Quest Poseidon", function()
  setStatus("Auto: Key…",false)
  local k = findOneByKeywords("vault","key"); if k then safeTP(posFrom(k)); task.wait(0.2); fireAllPrompts(k) end
  task.wait(0.6)

  setStatus("Auto: Gate…",false)
  local g = findOneByKeywords("poseidon","gate") or findOneByKeywords("gate","poseidon")
  if g then safeTP(posFrom(g)); task.wait(0.2); fireAllPrompts(g) end
  task.wait(0.6)

  setStatus("Auto: Final Gate…",false)
  local fg = findOneByKeywords("final","gate") or findOneByKeywords("finalbutton")
  if fg then
    safeTP(posFrom(fg)); task.wait(0.2); fireAllPrompts(fg)
    task.wait(0.3)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then
      local box,btn
      for _,d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextBox") then box=d end
        if d:IsA("TextButton") and d.Text and d.Text:lower():find("submit") then btn=d end
      end
      if box then box.Text="kampunglidurian" end
      if btn then pcall(function() btn:Activate() end) end
    end
  end
  task.wait(0.6)

  setStatus("Auto: Aura…",false)
  local h = findOneByKeywords("poseidonhat") or findOneByKeywords("helmet")
  if h then safeTP(posFrom(h)); task.wait(0.2); fireAllPrompts(h); setStatus("Selesai ✓",true)
  else setStatus("Helmet tidak ditemukan.",false) end
end)

-- FIXED: Toggle Function with proper dropdown handling
local function toggleMinimize()
  isMinimized = not isMinimized
  contentContainer.Visible = not isMinimized
  mainToggle.Text = (isMinimized and "+" or "–") .. " Mount Atin"
  
  -- Smooth transition
  local targetSize = isMinimized and UDim2.new(1, -4, 0, 50) or UDim2.new(1, -4, 0, 800)
  TweenService:Create(secRoot, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
    Size = targetSize
  }):Play()
  
  -- Handle dropdowns properly
  if isMinimized then
    -- Hide dropdowns when collapsing
    panel.Visible = false
    pPanel.Visible = false
  else
    -- Recalculate positions when expanding
    task.wait(0.35) -- Wait for tween to complete
    placePanel()
    placePPanel()
  end
end

mainToggle.MouseButton1Click:Connect(toggleMinimize)

-- ===== INITIALIZATION =====
-- Set initial minimize state
secRoot.Size = UDim2.new(1, -4, 0, 50) -- Start minimized
contentContainer.Visible = false
panel.Visible = false
pPanel.Visible = false

print("[danuu • Mount Atin] Fixed dropdown positioning version loaded ✓")

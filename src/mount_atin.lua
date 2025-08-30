-- src/mount_atin.lua
-- Mount Atin : Collapsible card + Checkpoint + Auto Summit + Poseidon Quest
local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Mount Atin"] then return end

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TP      = game:GetService("TeleportService")
local GuiSvc  = game:GetService("GuiService")
local Http    = game:GetService("HttpService")
local LP      = Players.LocalPlayer

----------------------------------------------------------------
-- THEME + SMALL UI HELPERS
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
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

----------------------------------------------------------------
-- HELPERS (gameplay)
----------------------------------------------------------------
local function HRP()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end

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
-- COLLAPSIBLE ROOT CARD (1 kartu saja; awal tertutup)
----------------------------------------------------------------
local mountListRoot = UI.MountSections -- parent daftar kartu gunung (sudah ada dari hub)
local secRoot       = UI.MountSections["Mount Atin"]  -- container khusus area ini (dipakai untuk clamp panel)

-- Buat kartu “Mount Atin” (tutup; tinggi setara kartu lain)
local card = Instance.new("Frame")
card.Name = "MountAtinCard"
card.BackgroundColor3 = Theme.card
card.Size = UDim2.new(1,-0,0,78)           -- tinggi kartu list default ~78
card.Parent = secRoot
corner(card,12); stroke(card,Theme.accA,1).Transparency=.5

-- Header (klik untuk expand/collapse)
local header = Instance.new("TextButton")
header.AutoButtonColor = false
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, -16, 0, 40)
header.Position = UDim2.fromOffset(8, 10)
header.Text = ""
header.Parent = card

local arrow = Instance.new("TextLabel")
arrow.BackgroundTransparency = 1
arrow.Text = "▸"
arrow.Font = Enum.Font.GothamBold
arrow.TextSize = 20
arrow.TextColor3 = Theme.text
arrow.Size = UDim2.fromOffset(20,20)
arrow.Position = UDim2.fromOffset(6,10)
arrow.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Text = "Mount Atin"
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextColor3 = Theme.text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1,-40,1,0)
title.Position = UDim2.fromOffset(30,0)
title.Parent = header

-- Content (disini seluruh fitur; auto-resize saat expand)
local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Visible = false
content.Size = UDim2.new(1,-16,0,0)
content.Position = UDim2.fromOffset(8, 56)
content.Parent = card

local contentList = Instance.new("UIListLayout", content)
contentList.Padding = UDim.new(0,10)
local function refreshCardSize()
  local h = content.Visible and (56 + contentList.AbsoluteContentSize.Y + 10) or 78
  card.Size = UDim2.new(1,0,0, math.max(78, h))
end
contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCardSize)
local expanded=false
local function setExpanded(on)
  expanded = on and true or false
  arrow.Text = expanded and "▾" or "▸"
  content.Visible = expanded
  refreshCardSize()
end
setExpanded(false)
header.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

----------------------------------------------------------------
-- REUSABLE SUB-SECTION BUILDER (dipakai di dalam `content`)
----------------------------------------------------------------
local function newSub(titleText)
  local box = Instance.new("Frame")
  box.BackgroundColor3 = Theme.card
  box.Size = UDim2.new(1,0,0,60)
  box.Parent = content
  corner(box,10); stroke(box,Theme.accA,1).Transparency=.5

  local title2 = Instance.new("TextLabel")
  title2.BackgroundTransparency = 1
  title2.Text = "  "..titleText
  title2.Font = Enum.Font.GothamBlack
  title2.TextSize = 18
  title2.TextColor3 = Theme.text
  title2.TextXAlignment = Enum.TextXAlignment.Left
  title2.Size = UDim2.new(1,-8,0,28)
  title2.Position = UDim2.fromOffset(8,6)
  title2.Parent = box

  local inner = Instance.new("Frame")
  inner.BackgroundTransparency = 1
  inner.Size = UDim2.new(1,-16,0,0)
  inner.Position = UDim2.fromOffset(8,36)
  inner.Parent = box

  local lay = Instance.new("UIListLayout", inner)
  lay.Padding = UDim.new(0,8)

  local function resize()
    box.Size = UDim2.new(1,0,0, math.max(60, 40 + lay.AbsoluteContentSize.Y))
    inner.Size = UDim2.new(1,-16,0, lay.AbsoluteContentSize.Y)
    refreshCardSize()
  end
  lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
  task.defer(resize)

  return inner, box
end

----------------------------------------------------------------
-- SECTION 1: CHECKPOINT
----------------------------------------------------------------
local cpInner = newSub("Checkpoint")

-- Row: [dropdown] [Go To]
local row = Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,36); row.Parent=cpInner
local rowLay = Instance.new("UIListLayout", row)
rowLay.FillDirection=Enum.FillDirection.Horizontal; rowLay.Padding=UDim.new(0,8); rowLay.VerticalAlignment=Enum.VerticalAlignment.Center

local right = Instance.new("Frame")
right.BackgroundTransparency=1; right.Size=UDim2.new(1, -(120+8), 1, 0); right.Parent=row
local hr = Instance.new("UIListLayout", right)
hr.FillDirection=Enum.FillDirection.Horizontal; hr.Padding=UDim.new(0,8)
hr.HorizontalAlignment = Enum.HorizontalAlignment.Left
hr.VerticalAlignment = Enum.VerticalAlignment.Center

local dd = Instance.new("TextButton")
dd.AutoButtonColor=false; dd.Text="Pilih checkpoint..."
dd.Font=Enum.Font.GothamSemibold; dd.TextSize=14; dd.TextColor3=Theme.text
dd.TextWrapped=false; dd.TextTruncate=Enum.TextTruncate.AtEnd
dd.BackgroundColor3=Theme.card; dd.Size=UDim2.new(1,0,1,0); dd.Parent=right
corner(dd,8); stroke(dd,Theme.accA,1).Transparency=.45

local go = Instance.new("TextButton")
go.AutoButtonColor=false; go.Text="Go To"
go.Font=Enum.Font.GothamSemibold; go.TextSize=14; go.TextColor3=Theme.text
go.BackgroundColor3=Theme.accA; go.Size=UDim2.new(0,120,1,0); go.Parent=row
corner(go,8); stroke(go,Theme.accB,1).Transparency=.3

-- Panel list (dipasang ke `card` agar tidak kepotong)
local panel = Instance.new("Frame")
panel.Visible=false; panel.BackgroundColor3=Theme.card
panel.Size=UDim2.new(0,260,0,184); panel.Parent=card
panel.ClipsDescendants=true; panel.ZIndex=50
corner(panel,8); stroke(panel,Theme.accB,1).Transparency=.35

local listScroll = Instance.new("ScrollingFrame", panel)
listScroll.BackgroundTransparency=1; listScroll.Size=UDim2.fromScale(1,1)
listScroll.ScrollBarThickness=6; listScroll.CanvasSize=UDim2.new(0,0,0,0)
listScroll.ZIndex=51; listScroll.ClipsDescendants=true
local l = Instance.new("UIListLayout", listScroll); l.Padding=UDim.new(0,6)
l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  listScroll.CanvasSize=UDim2.new(0,0,0,l.AbsoluteContentSize.Y+8)
end)

local function clampDropdown(anchorBtn, outPanel)
  local rootAbs = card.AbsolutePosition
  local rootSize = card.AbsoluteSize
  local abs = anchorBtn.AbsolutePosition
  local ddSize = anchorBtn.AbsoluteSize
  local margin, width = 8, 260
  local x = abs.X - rootAbs.X
  local y = abs.Y - rootAbs.Y + ddSize.Y + 6
  if x < margin then x = margin end
  if x + width + margin > rootSize.X then x = rootSize.X - width - margin end
  local maxH = math.min(224, rootSize.Y - y - margin)
  outPanel.Size = UDim2.new(0, width, 0, math.max(120, maxH))
  outPanel.Position = UDim2.fromOffset(x, y)
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
  b.BackgroundColor3=Color3.fromRGB(90,74,140); b.Size=UDim2.new(1,-12,0,32); b.Parent=listScroll; b.ZIndex=52
  corner(b,8)
  b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(110,90,170) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(90,74,140) end)
  b.MouseButton1Click:Connect(function() selectedIndex=i; dd.Text=entry[1]; panel.Visible=false end)
end

dd.MouseButton1Click:Connect(function() clampDropdown(dd,panel); panel.Visible=not panel.Visible end)
UIS.InputBegan:Connect(function(input,gp)
  if gp or not panel.Visible or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
  local p=input.Position
  local inDD = p.X>=dd.AbsolutePosition.X and p.X<=dd.AbsolutePosition.X+dd.AbsoluteSize.X and p.Y>=dd.AbsolutePosition.Y and p.Y<=dd.AbsolutePosition.Y+dd.AbsoluteSize.Y
  local inPanel = p.X>=panel.AbsolutePosition.X and p.X<=panel.AbsolutePosition.X+panel.AbsoluteSize.X and p.Y>=panel.AbsolutePosition.Y and p.Y<=panel.AbsolutePosition.Y+panel.AbsoluteSize.Y
  if not inDD and not inPanel then panel.Visible=false end
end)

go.MouseButton1Click:Connect(function()
  if not selectedIndex then dd.Text="Pilih checkpoint dulu…"; return end
  safeTP(checkpoints[selectedIndex][2])
end)

do
  local note = Instance.new("TextLabel")
  note.BackgroundTransparency=1; note.TextWrapped=true; note.TextColor3=Theme.text2; note.Font=Enum.Font.Gotham; note.TextSize=13
  note.Text="Pilih checkpoint di dropdown (kanan) lalu tekan 'Go To' untuk teleport."
  note.Size=UDim2.new(1,0,0,30); note.Parent=cpInner
end

----------------------------------------------------------------
-- SECTION 2: AUTO SUMMIT (di tengah)
----------------------------------------------------------------
local asInner = newSub("Auto Summit")
do
  local how = Instance.new("TextLabel")
  how.BackgroundTransparency=1; how.TextWrapped=true; how.TextColor3=Theme.text2; how.Font=Enum.Font.Gotham; how.TextSize=13
  how.Text = "Cara Pakai:\n1) Pastikan auto-execute aktif.\n2) Masukkan delay sesuai device (default 3s). Disaranin ≥3s.\n3) Masukkan delay Auto Rejoin (default 5s) — idealnya > delay loop.\n4) ON kan sesuai kebutuhan dan tinggal AFK."
  how.Size=UDim2.new(1,0,0,64); how.Parent=asInner
end

-- persistence
local fileOK = (writefile and readfile and isfile) and true or false
local KEY = ("danuu_as_%s.json"):format(tostring(game.PlaceId))
local function saveState(tbl) if not fileOK then return end; pcall(function() writefile(KEY, Http:JSONEncode(tbl)) end) end
local function loadState()
  if not fileOK or not isfile(KEY) then return {} end
  local ok,data = pcall(function() return Http:JSONDecode(readfile(KEY)) end)
  return ok and data or {}
end
local st = loadState()
local autoLoop  = st.autoLoop  ~= false and (st.autoLoop or false)
local autoRJ    = st.autoRJ    or false
local delayLoop = tonumber(st.delayLoop) or 3
local delayRJ   = tonumber(st.delayRJ)   or 5

local function persist() saveState({autoLoop=autoLoop, autoRJ=autoRJ, delayLoop=delayLoop, delayRJ=delayRJ}) end

-- Row 1: [Box delay loop] [toggle loop]
local r1 = Instance.new("Frame"); r1.BackgroundTransparency=1; r1.Size=UDim2.new(1,0,0,36); r1.Parent=asInner
local r1l=Instance.new("UIListLayout", r1); r1l.FillDirection=Enum.FillDirection.Horizontal; r1l.Padding=UDim.new(0,8)

local boxLoop = Instance.new("TextBox")
boxLoop.Size=UDim2.new(1, -(140+8), 1, 0); boxLoop.BackgroundColor3=Theme.card; boxLoop.ClearTextOnFocus=false
boxLoop.TextColor3=Theme.text; boxLoop.Font=Enum.Font.Gotham; boxLoop.TextSize=14; boxLoop.Text = tostring(delayLoop)
boxLoop.PlaceholderText="Delay Auto Loop (detik)"
corner(boxLoop,8); stroke(boxLoop,Theme.accA,1).Transparency=.45; boxLoop.Parent=r1

local btnLoop = Instance.new("TextButton")
btnLoop.Size=UDim2.new(0,140,1,0); btnLoop.AutoButtonColor=false; btnLoop.BackgroundColor3=Theme.accA
btnLoop.Font=Enum.Font.GothamSemibold; btnLoop.TextSize=14; btnLoop.TextColor3=Theme.text; btnLoop.Parent=r1
corner(btnLoop,8); stroke(btnLoop,Theme.accB,1).Transparency=.35
local function refreshLoopBtn() btnLoop.Text = "Auto Loop: "..(autoLoop and "ON" or "OFF") end
refreshLoopBtn()

-- Row 2: [Box delay RJ] [toggle RJ]
local r2 = Instance.new("Frame"); r2.BackgroundTransparency=1; r2.Size=UDim2.new(1,0,0,36); r2.Parent=asInner
local r2l=Instance.new("UIListLayout", r2); r2l.FillDirection=Enum.FillDirection.Horizontal; r2l.Padding=UDim.new(0,8)

local boxRJ = Instance.new("TextBox")
boxRJ.Size=UDim2.new(1, -(140+8), 1, 0); boxRJ.BackgroundColor3=Theme.card; boxRJ.ClearTextOnFocus=false
boxRJ.TextColor3=Theme.text; boxRJ.Font=Enum.Font.Gotham; boxRJ.TextSize=14; boxRJ.Text = tostring(delayRJ)
boxRJ.PlaceholderText="Delay Auto Rejoin (detik)"
corner(boxRJ,8); stroke(boxRJ,Theme.accA,1).Transparency=.45; boxRJ.Parent=r2

local btnRJ = Instance.new("TextButton")
btnRJ.Size=UDim2.new(0,140,1,0); btnRJ.AutoButtonColor=false; btnRJ.BackgroundColor3=Theme.accA
btnRJ.Font=Enum.Font.GothamSemibold; btnRJ.TextSize=14; btnRJ.TextColor3=Theme.text; btnRJ.Parent=r2
corner(btnRJ,8); stroke(btnRJ,Theme.accB,1).Transparency=.35
local function refreshRJBtn() btnRJ.Text = "Auto Rejoin: "..(autoRJ and "ON" or "OFF") end
refreshRJBtn()

-- Logic Auto Loop (TP ke summit + "dance" 3x @ 8 stud)
local SUMMIT = Vector3.new(781.809, 2162.143, 3920.971)
local function checkpointDance(center)
  local hrp = (HRP())
  if not hrp then return end
  local cam = workspace.CurrentCamera
  local dir = cam and cam.CFrame.LookVector or hrp.CFrame.LookVector
  dir = Vector3.new(dir.X,0,dir.Z)
  if dir.Magnitude < 0.1 then dir = Vector3.new(1,0,0) end
  dir = dir.Unit
  local R = 8
  for _=1,3 do
    hrp.CFrame = CFrame.new(center) + dir*R; task.wait(0.12)
    hrp.CFrame = CFrame.new(center) - dir*R; task.wait(0.12)
    hrp.CFrame = CFrame.new(center);         task.wait(0.12)
  end
end

task.spawn(function()
  while card.Parent do
    delayLoop = tonumber(boxLoop.Text) or delayLoop
    delayRJ   = tonumber(boxRJ.Text) or delayRJ
    if autoLoop then
      safeTP(SUMMIT)
      checkpointDance(SUMMIT)
      local t0=tick()
      while tick()-t0 < delayLoop do
        if not autoLoop then break end
        task.wait(0.05)
      end
      if autoRJ and autoLoop then
        local t1=tick()
        while tick()-t1 < math.max(0, delayRJ) do
          if not autoLoop then break end
          task.wait(0.05)
        end
        if autoLoop then
          local place, job = game.PlaceId, game.JobId
          if #Players:GetPlayers() <= 1 then
            LP:Kick("\nRejoining...")
            task.wait()
            TP:Teleport(place, LP)
          else
            TP:TeleportToPlaceInstance(place, job, LP)
          end
        end
      end
    end
    task.wait(0.05)
  end
end)

btnLoop.MouseButton1Click:Connect(function()
  autoLoop = not autoLoop; refreshLoopBtn(); persist()
end)
btnRJ.MouseButton1Click:Connect(function()
  autoRJ = not autoRJ; refreshRJBtn(); persist()
end)
boxLoop.FocusLost:Connect(function() delayLoop = tonumber(boxLoop.Text) or 3; boxLoop.Text=tostring(delayLoop); persist() end)
boxRJ.FocusLost:Connect(function() delayRJ = tonumber(boxRJ.Text) or 5; boxRJ.Text=tostring(delayRJ); persist() end)

----------------------------------------------------------------
-- SECTION 3: POSEIDON QUEST (dropdown manual + Auto)
----------------------------------------------------------------
local pq = newSub("Poseidon Quest")

local status = Instance.new("TextLabel")
status.BackgroundTransparency=1; status.TextColor3=Theme.text2; status.Font=Enum.Font.Gotham; status.TextSize=13
status.Text="Status: —"; status.Size=UDim2.new(1,0,0,22); status.Parent=pq
local function setStatus(txt, good) status.Text = "Status: "..txt; status.TextColor3 = good and Theme.good or Theme.text2 end

-- Row: [Dropdown manual] [Go To]
local prow = Instance.new("Frame"); prow.BackgroundTransparency=1; prow.Size=UDim2.new(1,0,0,36); prow.Parent=pq
local pl = Instance.new("UIListLayout", prow)
pl.FillDirection=Enum.FillDirection.Horizontal; pl.Padding=UDim.new(0,8); pl.VerticalAlignment=Enum.VerticalAlignment.Center

local pRight = Instance.new("Frame")
pRight.BackgroundTransparency=1
pRight.Size = UDim2.new(1, -(120+8), 1, 0)
pRight.Parent = prow

local pLay   = Instance.new("UIListLayout", pRight)
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

-- Panel list (dipasang ke `card`)
local pPanel = Instance.new("Frame")
pPanel.Visible=false; pPanel.BackgroundColor3=Theme.card
pPanel.Size=UDim2.new(0,260,0,184); pPanel.Parent=card
pPanel.ClipsDescendants=true; pPanel.ZIndex=50
corner(pPanel,8); stroke(pPanel,Theme.accB,1).Transparency=.35

local pList = Instance.new("ScrollingFrame", pPanel)
pList.BackgroundTransparency=1; pList.Size=UDim2.fromScale(1,1)
pList.ScrollBarThickness=6; pList.CanvasSize=UDim2.new(0,0,0,0)
pList.ZIndex=51; pList.ClipsDescendants=true
local pUIL = Instance.new("UIListLayout", pList); pUIL.Padding=UDim.new(0,6)
pUIL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  pList.CanvasSize=UDim2.new(0,0,0,pUIL.AbsoluteContentSize.Y+8)
end)
local function placePPanel() clampDropdown(pdd, pPanel) end

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
  b.BackgroundColor3=Color3.fromRGB(90,74,140); b.Size=UDim2.new(1,-12,0,32); b.Parent=pList; b.ZIndex=52
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
  setStatus(("Teleport: %s"):format(manualPoints[selectedManualIndex][1]), false)
  safeTP(pos)
end)

-- Tombol Auto Quest (tetap)
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

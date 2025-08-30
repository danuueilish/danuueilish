-- src/mount_atin.lua
-- Mount Atin • Checkpoint picker (label kiri, dropdown + Go To kanan)

local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Mount Atin"] then return end
local sec  = UI.MountSections["Mount Atin"]
local root = UI.Window or sec

local Theme = {
  bg   = Color3.fromRGB(24,20,40),
  card = Color3.fromRGB(44,36,72),
  text = Color3.fromRGB(235,230,255),
  text2= Color3.fromRGB(190,180,220),
  accA = Color3.fromRGB(125,84,255),
  accB = Color3.fromRGB(215,55,255)
}

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.55; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

-- data titik
local points = {
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

-- ===== baris kontrol
local row = Instance.new("Frame")
row.BackgroundTransparency = 1
row.Size = UDim2.new(1,0,0,40)
row.Parent = sec
row.ClipsDescendants = false

local lay = Instance.new("UIListLayout", row)
lay.FillDirection = Enum.FillDirection.Horizontal
lay.Padding = UDim.new(0,8)
lay.VerticalAlignment = Enum.VerticalAlignment.Center
lay.HorizontalAlignment = Enum.HorizontalAlignment.Left

-- label kiri
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Text = "Checkpoint"
label.Font = Enum.Font.GothamBlack
label.TextSize = 16
label.TextColor3 = Theme.text
label.Size = UDim2.new(0,120,1,0)
label.Parent = row

-- container kanan
local right = Instance.new("Frame")
right.BackgroundTransparency = 1
right.Size = UDim2.new(1,-(120+8),1,0)
right.Parent = row

local rlay = Instance.new("UIListLayout", right)
rlay.FillDirection = Enum.FillDirection.Horizontal
rlay.Padding = UDim.new(0,8)
rlay.HorizontalAlignment = Enum.HorizontalAlignment.Right
rlay.VerticalAlignment = Enum.VerticalAlignment.Center

-- DROPDOWN (dibuat duluan biar posisinya di kiri)
local dd = Instance.new("TextButton")
dd.AutoButtonColor = false
dd.Text = "Pilih checkpoint..."
dd.TextXAlignment = Enum.TextXAlignment.Left
dd.Font = Enum.Font.GothamSemibold
dd.TextSize = 14
dd.TextColor3 = Theme.text
dd.BackgroundColor3 = Theme.card
dd.Size = UDim2.new(1,-(120+8),1,0) -- sisa ruang selain tombol
dd.Parent = right
corner(dd,8); stroke(dd,Theme.accA,1).Transparency = .45

-- TOMBOL GO TO (menempel di kanan)
local btnGo = Instance.new("TextButton")
btnGo.AutoButtonColor = false
btnGo.Text = "Go To"
btnGo.Font = Enum.Font.GothamSemibold
btnGo.TextSize = 14
btnGo.TextColor3 = Theme.text
btnGo.BackgroundColor3 = Theme.accA
btnGo.Size = UDim2.new(0,120,1,0)
btnGo.Parent = right
corner(btnGo,8); stroke(btnGo,Theme.accB,1).Transparency = .35

-- panel dropdown (parent = window agar tak kepotong)
local panel = Instance.new("Frame")
panel.Visible = false
panel.BackgroundColor3 = Theme.card
panel.Size = UDim2.fromOffset(260,200)
panel.Parent = root
panel.ZIndex = 50
corner(panel,8); stroke(panel,Theme.accB,1).Transparency = .35
panel.ClipsDescendants = true

local function placePanel()
  local ddPos, ddSize = dd.AbsolutePosition, dd.AbsoluteSize
  local rootPos, rootSize = root.AbsolutePosition, root.AbsoluteSize
  local x = ddPos.X - rootPos.X
  local y = (ddPos.Y - rootPos.Y) + ddSize.Y + 6
  local w = ddSize.X
  panel.Size = UDim2.fromOffset(math.max(220, w), 200)
  x = math.clamp(x, 8, rootSize.X - panel.AbsoluteSize.X - 8)
  y = math.clamp(y, 8, rootSize.Y - panel.AbsoluteSize.Y - 8)
  panel.Position = UDim2.fromOffset(x, y)
end

local scroll = Instance.new("ScrollingFrame", panel)
scroll.BackgroundTransparency = 1
scroll.Size = UDim2.fromScale(1,1)
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ZIndex = 51
local ll = Instance.new("UIListLayout", scroll)
ll.Padding = UDim.new(0,6)
ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8)
end)

local selectedIndex
for i,entry in ipairs(points) do
  local b = Instance.new("TextButton")
  b.AutoButtonColor = false
  b.Text = entry[1]
  b.Font = Enum.Font.Gotham
  b.TextSize = 14
  b.TextXAlignment = Enum.TextXAlignment.Left
  b.TextColor3 = Theme.text
  b.BackgroundColor3 = Color3.fromRGB(90,74,140)
  b.Size = UDim2.new(1,-12,0,28)
  b.Parent = scroll
  corner(b,8); b.ZIndex = 52
  b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(110,90,170) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(90,74,140) end)
  b.MouseButton1Click:Connect(function()
    selectedIndex = i
    dd.Text = entry[1]
    panel.Visible = false
  end)
end

dd.MouseButton1Click:Connect(function()
  placePanel()
  panel.Visible = not panel.Visible
end)

-- tutup panel bila klik di luar
game:GetService("UserInputService").InputBegan:Connect(function(input,gp)
  if gp or not panel.Visible then return end
  if input.UserInputType == Enum.UserInputType.MouseButton1 then
    local p = input.Position
    local function inside(g) return p.X>=g.AbsolutePosition.X and p.X<=g.AbsolutePosition.X+g.AbsoluteSize.X and p.Y>=g.AbsolutePosition.Y and p.Y<=g.AbsolutePosition.Y+g.AbsoluteSize.Y end
    if not inside(dd) and not inside(panel) then panel.Visible = false end
  end
end)

-- teleport
local function HRP()
  local plr = game:GetService("Players").LocalPlayer
  local ch = plr.Character or plr.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart")
end
local function nudge(center)
  local h = HRP(); if not h then return end
  local dir = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or h.CFrame.LookVector
  dir = Vector3.new(dir.X,0,dir.Z); if dir.Magnitude < .1 then dir = Vector3.new(1,0,0) end; dir = dir.Unit
  for _=1,2 do
    h.CFrame = CFrame.new(center + dir*6); task.wait(0.08)
    h.CFrame = CFrame.new(center - dir*6); task.wait(0.08)
  end
  h.CFrame = CFrame.new(center)
end

btnGo.MouseButton1Click:Connect(function()
  if not selectedIndex then dd.Text = "Pilih checkpoint dulu…"; return end
  local pos = points[selectedIndex][2]
  local h = HRP()
  if h then h.CFrame = CFrame.new(pos); nudge(pos) end
end)

-- keterangan
local note = Instance.new("TextLabel")
note.BackgroundTransparency = 1
note.TextWrapped = true
note.TextColor3 = Theme.text2
note.Font = Enum.Font.Gotham
note.TextSize = 13
note.Text = "Pilih checkpoint di dropdown (kanan) lalu tekan 'Go To' untuk teleport."
note.Size = UDim2.new(1,0,0,32)
note.Parent = sec

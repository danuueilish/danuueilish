-- mount_atin.lua
-- Isi untuk Section "Mount Atin" (dropdown checkpoint + tombol Go To)

local UI = _G.danuu_hub_ui
if not UI then return end

-- ambil container section "Mount Atin" yang sudah dibuat UI
local sec = UI.MountSections and UI.MountSections["Mount Atin"]
if not sec then
  -- fallback: kalau gagal ketemu, ya buat section baru (biar tetap ada)
  sec = UI.NewSection(UI.Tabs.Mount, "Mount Atin • Checkpoint")
end

-- ===== data koordinat (urut seperti yang kamu kirim) =====
local points = {
  {"Basecamp",              Vector3.new(  16.501,   54.470, -1082.821)},
  {"Summit Leaderboard",    Vector3.new(  31.554,   53.176, -1030.635)},
  {"CP1",                   Vector3.new(   3.000,   11.911,  -408.000)},
  {"CP2",                   Vector3.new(-184.000,  127.344,   409.000)},
  {"CP3",                   Vector3.new(-165.000,  228.957,   653.000)},
  {"CP4",                   Vector3.new( -38.001,  405.875,   615.998)},
  {"CP5",                   Vector3.new( 130.396,  650.989,   613.836)},
  {"CP6",                   Vector3.new(-246.376,  665.037,   734.127)},
  {"CP7",                   Vector3.new(-684.143,  640.055,   867.515)},
  {"CP8",                   Vector3.new(-658.021,  687.758,  1458.335)},
  {"CP9",                   Vector3.new(-508.000,  902.192,  1868.000)},
  {"CP10",                  Vector3.new(  61.111,  949.259,  2088.859)},
  {"CP11",                  Vector3.new(  52.063,  980.809,  2450.589)},
  {"CP12",                  Vector3.new(  72.000, 1096.188,  2457.000)},
  {"CP13",                  Vector3.new( 262.000, 1269.363,  2038.000)},
  {"CP14",                  Vector3.new(-419.000, 1301.437,  2394.000)},
  {"CP15",                  Vector3.new(-773.054, 1313.202,  2664.506)},
  {"CP16",                  Vector3.new(-837.697, 1474.366,  2625.771)},
  {"CP17",                  Vector3.new(-468.798, 1464.933,  2769.276)},
  {"CP18",                  Vector3.new(-467.867, 1536.609,  2836.109)},
  {"CP19",                  Vector3.new(-386.000, 1639.622,  2794.000)},
  {"CP20",                  Vector3.new(-208.299, 1665.051,  2749.506)},
  {"CP21",                  Vector3.new(-232.923, 1741.332,  2791.862)},
  {"CP22",                  Vector3.new(-424.331, 1739.924,  2798.055)},
  {"CP23",                  Vector3.new(-423.647, 1711.897,  3420.069)},
  {"CP24",                  Vector3.new(  70.991, 1717.957,  3427.220)},
  {"CP25",                  Vector3.new( 435.644, 1719.855,  3430.871)},
  {"CP26",                  Vector3.new( 625.421, 1798.638,  3433.288)},
  {"Summit",                Vector3.new( 781.809, 2162.143,  3920.971)},
  {"Glider",                Vector3.new( 866.637,   12.298,  -584.917)},
  {"Tugu Summit",           Vector3.new( 113.362, 2446.251,  3479.762)},
  {"NPC Anomali CP9",       Vector3.new(-485.513,  900.661,  1871.908)},
  {"Bendera CP9",           Vector3.new(-599.214,  785.941,  2030.948)},
  {"NPC Anomali CP13",      Vector3.new( 254.502, 1267.814,  2042.323)},
  {"Bendera CP13",          Vector3.new( 302.553, 1062.164,  2279.954)},
  {"NPC Anomali Summit",    Vector3.new( 689.275, 2195.028,  4010.853)},
  {"Bendera Summit",        Vector3.new( 954.704, 2108.575,  3583.613)},
  {"Mr Bus CP13",           Vector3.new( 153.903, 1088.369,  1953.853)},
  {"Mr Bus Summit",         Vector3.new( 638.770, 2203.497,  4207.933)},
}

-- ====== widget kecil: label bantuan
local function help(text)
  local l=Instance.new("TextLabel")
  l.BackgroundTransparency=1
  l.TextWrapped=true
  l.TextColor3=Color3.fromRGB(190,180,220)
  l.Font=Enum.Font.Gotham
  l.TextSize=14
  l.Text = text
  l.Size=UDim2.new(1,0,0,34)
  l.Parent = sec
  return l
end

-- ====== Dropdown sederhana (gaya custom)
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1,0,0,34)
dropdownBtn.Text = "Pilih checkpoint…"
dropdownBtn.Font = Enum.Font.GothamSemibold
dropdownBtn.TextSize = 14
dropdownBtn.TextColor3 = Color3.new(1,1,1)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(44,36,72)
dropdownBtn.Parent = sec
local u1=Instance.new("UICorner", dropdownBtn); u1.CornerRadius = UDim.new(0,8)

-- panel list
local listHolder = Instance.new("Frame")
listHolder.Visible = false
listHolder.BackgroundColor3 = Color3.fromRGB(36,28,60)
listHolder.Size = UDim2.new(1,0,0,180) -- tinggi maksimum, nanti scroll
listHolder.Parent = sec
local u2=Instance.new("UICorner", listHolder); u2.CornerRadius = UDim.new(0,8)

local sc = Instance.new("ScrollingFrame", listHolder)
sc.BackgroundTransparency = 1
sc.Size = UDim2.fromScale(1,1)
sc.ScrollBarThickness = 6
local lay = Instance.new("UIListLayout", sc); lay.Padding = UDim.new(0,6)
sc.CanvasSize = UDim2.new(0,0,0,0)
lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  sc.CanvasSize = UDim2.new(0,0,0, lay.AbsoluteContentSize.Y + 8)
end)

local selectedIndex = nil

local function addOption(i, name)
  local b=Instance.new("TextButton")
  b.Size=UDim2.new(1,0,0,30)
  b.Text=name
  b.Font=Enum.Font.Gotham
  b.TextSize=14
  b.TextColor3=Color3.new(1,1,1)
  b.BackgroundColor3=Color3.fromRGB(54,46,82)
  b.Parent=sc
  local ub=Instance.new("UICorner",b); ub.CornerRadius=UDim.new(0,8)
  b.MouseButton1Click:Connect(function()
    selectedIndex = i
    dropdownBtn.Text = name
    listHolder.Visible = false
  end)
end

for i,entry in ipairs(points) do
  addOption(i, entry[1])
end

dropdownBtn.MouseButton1Click:Connect(function()
  listHolder.Visible = not listHolder.Visible
end)

-- ====== Tombol Go To
local go = Instance.new("TextButton")
go.Size = UDim2.new(1,0,0,34)
go.Text = "Go To"
go.Font = Enum.Font.GothamSemibold
go.TextSize = 14
go.TextColor3 = Color3.new(1,1,1)
go.BackgroundColor3 = Color3.fromRGB(125,84,255)
go.Parent = sec
local u3=Instance.new("UICorner", go); u3.CornerRadius = UDim.new(0,8)

-- bantuan
help("Pilih checkpoint (1 – Summit) pada dropdown, lalu tekan 'Go To' untuk teleport.")

-- ====== Teleport
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local function HRP()
  local ch = LP.Character or LP.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart")
end

go.MouseButton1Click:Connect(function()
  if not selectedIndex then return end
  local pos = points[selectedIndex][2]
  local h = HRP(); if not h then return end
  h.CFrame = CFrame.new(pos)
end)

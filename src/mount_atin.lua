-- src/mount_atin.lua
-- Mount Atin • Checkpoint picker (dropdown + Go To)

local UI = _G.danuu_hub_ui
if not UI then return end

-- ========= helpers =========
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local LP      = Players.LocalPlayer

local function HRP()
    local ch = LP.Character or LP.CharacterAdded:Wait()
    return ch:WaitForChild("HumanoidRootPart")
end

local function mkCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

-- ========= data titik =========
-- urutan sesuai yang kamu kirim
local CPs = {
    {"Basecamp",                 Vector3.new(  16.501,   54.470, -1082.821)},
    {"Summit Leaderboard",       Vector3.new(  31.554,   53.176, -1030.635)},
    {"CP1",                      Vector3.new(   3.000,   11.911,  -408.000)},
    {"CP2",                      Vector3.new(-184.000,  127.344,   409.000)},
    {"CP3",                      Vector3.new(-165.000,  228.957,   653.000)},
    {"CP4",                      Vector3.new( -38.001,  405.875,   615.998)},
    {"CP5",                      Vector3.new( 130.396,  650.989,   613.836)},
    {"CP6",                      Vector3.new(-246.376,  665.037,   734.127)},
    {"CP7",                      Vector3.new(-684.143,  640.055,   867.515)},
    {"CP8",                      Vector3.new(-658.021,  687.758,  1458.335)},
    {"CP9",                      Vector3.new(-508.000,  902.192,  1868.000)},
    {"CP10",                     Vector3.new(  61.111,  949.259,  2088.859)},
    {"CP11",                     Vector3.new(  52.063,  980.809,  2450.589)},
    {"CP12",                     Vector3.new(  72.000, 1096.188,  2457.000)},
    {"CP13",                     Vector3.new( 262.000, 1269.363,  2038.000)},
    {"CP14",                     Vector3.new(-419.000, 1301.437,  2394.000)},
    {"CP15",                     Vector3.new(-773.054, 1313.202,  2664.506)},
    {"CP16",                     Vector3.new(-837.697, 1474.366,  2625.771)},
    {"CP17",                     Vector3.new(-468.798, 1464.933,  2769.276)},
    {"CP18",                     Vector3.new(-467.867, 1536.609,  2836.109)},
    {"CP19",                     Vector3.new(-386.000, 1639.622,  2794.000)},
    {"CP20",                     Vector3.new(-208.299, 1665.051,  2749.506)},
    {"CP21",                     Vector3.new(-232.923, 1741.332,  2791.862)},
    {"CP22",                     Vector3.new(-424.331, 1739.924,  2798.055)},
    {"CP23",                     Vector3.new(-423.647, 1711.897,  3420.069)},
    {"CP24",                     Vector3.new(  70.991, 1717.957,  3427.220)},
    {"CP25",                     Vector3.new( 435.644, 1719.855,  3430.871)},
    {"CP26",                     Vector3.new( 625.421, 1798.638,  3433.288)},
    {"Summit",                   Vector3.new( 781.809, 2162.143,  3920.971)},
    {"Glider",                   Vector3.new( 866.637,   12.298,  -584.917)},
    {"Tugu Summit",              Vector3.new( 113.362, 2446.251,  3479.762)},
    {"NPC Anomali CP9",          Vector3.new(-485.513,  900.661,  1871.908)},
    {"Bendera CP9",              Vector3.new(-599.214,  785.941,  2030.948)},
    {"NPC Anomali CP13",         Vector3.new( 254.502, 1267.814,  2042.323)},
    {"Bendera CP13",             Vector3.new( 302.553, 1062.164,  2279.954)},
    {"NPC Anomali Summit",       Vector3.new( 689.275, 2195.028,  4010.853)},
    {"Bendera Summit",           Vector3.new( 954.704, 2108.575,  3583.613)},
    {"Mr Bus CP13",              Vector3.new( 153.903, 1088.369,  1953.853)},
    {"Mr Bus Summit",            Vector3.new( 638.770, 2203.497,  4207.933)},
}

-- ========= UI layout =========
local sec = UI.NewSection(UI.Tabs.Mount, "Mount Atin • Checkpoint")

-- baris utama: kiri label, kanan kolom (dropdown + tombol)
local row = Instance.new("Frame")
row.BackgroundTransparency = 1
row.Size = UDim2.new(1, 0, 0, 74)
row.Parent = sec

local H = Instance.new("UIListLayout", row)
H.FillDirection = Enum.FillDirection.Horizontal
H.Padding = UDim.new(0, 12)
H.VerticalAlignment = Enum.VerticalAlignment.Top

-- kiri (label)
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0, 120, 1, 0)
lbl.BackgroundTransparency = 1
lbl.Text = "Checkpoint"
lbl.Font = Enum.Font.GothamBlack
lbl.TextSize = 16
lbl.TextColor3 = Color3.fromRGB(235,230,255)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Parent = row

-- kanan (dropdown + tombol)
local col = Instance.new("Frame")
col.Size = UDim2.new(1, -120, 1, 0)
col.BackgroundTransparency = 1
col.Parent = row

local V = Instance.new("UIListLayout", col)
V.FillDirection = Enum.FillDirection.Vertical
V.Padding = UDim.new(0, 8)

-- dropdown head
local ddHead = Instance.new("TextButton")
ddHead.Size = UDim2.new(1, 0, 0, 32)
ddHead.Text = "Pilih checkpoint…"
ddHead.Font = Enum.Font.Gotham
ddHead.TextSize = 14
ddHead.TextColor3 = Color3.new(1,1,1)
ddHead.BackgroundColor3 = Color3.fromRGB(64,50,110) -- ungu tua, hidup tapi masih nyatu
ddHead.AutoButtonColor = true
ddHead.Parent = col
mkCorner(ddHead, 8)

-- popup list
local ddPopup = Instance.new("Frame")
ddPopup.Visible = false
ddPopup.BackgroundColor3 = Color3.fromRGB(44,36,72)
ddPopup.Size = UDim2.new(1, 0, 0, 180)
ddPopup.Parent = col
mkCorner(ddPopup, 8)

local popStroke = Instance.new("UIStroke")
popStroke.Thickness = 1
popStroke.Color = Color3.fromRGB(125,84,255)
popStroke.Transparency = 0.35
popStroke.Parent = ddPopup

local list = Instance.new("ScrollingFrame")
list.BackgroundTransparency = 1
list.Size = UDim2.new(1, -6, 1, -6)
list.Position = UDim2.fromOffset(3,3)
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new(0,0,0,0)
list.Parent = ddPopup

local L = Instance.new("UIListLayout", list)
L.Padding = UDim.new(0,6)
L:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0,0,0, L.AbsoluteContentSize.Y + 6)
end)

-- isi item dropdown
local selectedName, selectedPos = nil, nil
local function addItem(name, pos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.Text = name
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(60,46,100)
    b.AutoButtonColor = true
    b.Parent = list
    mkCorner(b, 6)

    b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(78,60,132) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(60,46,100) end)

    b.MouseButton1Click:Connect(function()
        selectedName, selectedPos = name, pos
        ddHead.Text = name
        ddPopup.Visible = false
    end)
end

for _, entry in ipairs(CPs) do
    addItem(entry[1], entry[2])
end

-- toggle buka/tutup dropdown
ddHead.MouseButton1Click:Connect(function()
    ddPopup.Visible = not ddPopup.Visible
end)

-- tombol Go To
local goBtn = Instance.new("TextButton")
goBtn.Size = UDim2.new(1, 0, 0, 32)
goBtn.Text = "Go To"
goBtn.Font = Enum.Font.GothamSemibold
goBtn.TextSize = 14
goBtn.TextColor3 = Color3.new(1,1,1)
goBtn.BackgroundColor3 = Color3.fromRGB(125,84,255)
goBtn.AutoButtonColor = false
goBtn.Parent = col
mkCorner(goBtn, 8)

goBtn.MouseEnter:Connect(function() goBtn.BackgroundColor3 = Color3.fromRGB(215,55,255) end)
goBtn.MouseLeave:Connect(function() goBtn.BackgroundColor3 = Color3.fromRGB(125,84,255) end)

goBtn.MouseButton1Click:Connect(function()
    if selectedPos then
        local hrp = HRP()
        hrp.CFrame = CFrame.new(selectedPos)
    else
        ddHead.Text = "Pilih dulu checkpoint…"
    end
end)

-- hint
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.TextWrapped = true
hint.Text = "Pilih checkpoint (1 – Summit) dari dropdown, lalu tekan 'Go To' untuk teleport."
hint.Font = Enum.Font.Gotham
hint.TextSize = 13
hint.TextColor3 = Color3.fromRGB(190,180,220)
hint.Size = UDim2.new(1, 0, 0, 28)
hint.Parent = sec

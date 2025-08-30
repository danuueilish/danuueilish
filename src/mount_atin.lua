-- src/mount_atin.lua
-- Mount Atin: layout rapi (tiap fitur 1 sub-section)

local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Mount Atin"] then return end

-- ambil warna dari UI kalau ada
local Theme = UI.Theme or {
  bg=Color3.fromRGB(24,20,40), card=Color3.fromRGB(44,36,72),
  text=Color3.fromRGB(235,230,255), text2=Color3.fromRGB(190,180,220),
  accA=Color3.fromRGB(125,84,255), accB=Color3.fromRGB(215,55,255)
}

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.55; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

local mountRoot = UI.MountSections["Mount Atin"]                     -- section “Mount Atin” (inner frame)
local Sec = UI.NewSection                                             -- helper buat bikin sub-section

--------------------------------------------------------------------
-- ============ Sub-section: CHECKPOINT =================-----------
--------------------------------------------------------------------
local secCP = Sec(mountRoot, "Checkpoint")  -- sub-section di dalam Atin

-- data checkpoint (nama -> Vector3)
local CP = {
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

-- baris horizontal: [label kiri] [dropdown] [Go To]
local row = Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,36); row.Parent=secCP
local hl  = Instance.new("UIListLayout", row)
hl.FillDirection=Enum.FillDirection.Horizontal; hl.Padding=UDim.new(0,10); hl.VerticalAlignment=Enum.VerticalAlignment.Center

local lab = Instance.new("TextLabel")
lab.BackgroundTransparency=1; lab.Text="Checkpoint"; lab.Font=Enum.Font.GothamBlack; lab.TextSize=16; lab.TextColor3=Theme.text
lab.Size=UDim2.new(0,130,1,0); lab.Parent=row

local dd  = Instance.new("TextButton")
dd.AutoButtonColor=false; dd.Text="Pilih checkpoint..."; dd.Font=Enum.Font.GothamSemibold; dd.TextSize=14; dd.TextColor3=Theme.text
dd.BackgroundColor3=Color3.fromRGB(73,58,120); dd.Size=UDim2.new(1,-(130+130+20),1,0); dd.Parent=row
corner(dd,8); stroke(dd,Theme.accA,1).Transparency=.45

local go  = Instance.new("TextButton")
go.AutoButtonColor=false; go.Text="Go To"; go.Font=Enum.Font.GothamSemibold; go.TextSize=14; go.TextColor3=Theme.text
go.BackgroundColor3=Theme.accA; go.Size=UDim2.new(0,120,1,0); go.Parent=row
corner(go,8); stroke(go,Theme.accB,1).Transparency=.35

-- dropdown panel (muncul di bawah dd, tetap di dalam secCP agar tidak kepotong)
local panel = Instance.new("Frame")
panel.Visible=false; panel.BackgroundColor3=Theme.card; panel.Size=UDim2.new(0, dd.AbsoluteSize.X, 0, 200)
panel.Parent = secCP; panel.ZIndex=5; corner(panel,8); stroke(panel,Theme.accB,1).Transparency=.35

local function placePanel()
  local a = dd.AbsolutePosition; local r = panel.Parent.AbsolutePosition
  panel.Position = UDim2.fromOffset(a.X-r.X, (a.Y-r.Y)+dd.AbsoluteSize.Y+6)
  panel.Size     = UDim2.fromOffset(dd.AbsoluteSize.X, 200)
end

local scroll = Instance.new("ScrollingFrame", panel)
scroll.BackgroundTransparency=1; scroll.Size=UDim2.fromScale(1,1); scroll.ScrollBarThickness=6; scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.ZIndex=6
local l = Instance.new("UIListLayout", scroll); l.Padding=UDim.new(0,6)
l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize=UDim2.new(0,0,0,l.AbsoluteContentSize.Y+8) end)

local selectedIndex=nil
for i,item in ipairs(CP) do
  local b=Instance.new("TextButton"); b.AutoButtonColor=false; b.Text=item[1]; b.Font=Enum.Font.Gotham; b.TextSize=14; b.TextColor3=Theme.text
  b.BackgroundColor3=Color3.fromRGB(90,74,140); b.Size=UDim2.new(1,-12,0,28); b.Parent=scroll; corner(b,8); b.ZIndex=7
  b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(110,90,170) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(90,74,140) end)
  b.MouseButton1Click:Connect(function() selectedIndex=i; dd.Text=item[1]; panel.Visible=false end)
end

dd.MouseButton1Click:Connect(function() placePanel(); panel.Visible=not panel.Visible end)
game:GetService("UserInputService").InputBegan:Connect(function(input,gp)
  if gp or not panel.Visible or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
  local p=input.Position
  local inDD = p.X>=dd.AbsolutePosition.X and p.X<=dd.AbsolutePosition.X+dd.AbsoluteSize.X and p.Y>=dd.AbsolutePosition.Y and p.Y<=dd.AbsolutePosition.Y+dd.AbsoluteSize.Y
  local inPN = p.X>=panel.AbsolutePosition.X and p.X<=panel.AbsolutePosition.X+panel.AbsoluteSize.X and p.Y>=panel.AbsolutePosition.Y and p.Y<=panel.AbsolutePosition.Y+panel.AbsoluteSize.Y
  if not inDD and not inPN then panel.Visible=false end
end)

local function HRP()
  local plr=game:GetService("Players").LocalPlayer
  local ch=plr.Character or plr.CharacterAdded:Wait()
  return ch:FindFirstChild("HumanoidRootPart")
end

local function jumpDance(center)
  local h=HRP(); if not h then return end
  local dir=workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or h.CFrame.LookVector
  dir=Vector3.new(dir.X,0,dir.Z); if dir.Magnitude<.1 then dir=Vector3.new(1,0,0) end; dir=dir.Unit
  for _=1,2 do
    h.CFrame=CFrame.new(center + dir*6); task.wait(0.08)
    h.CFrame=CFrame.new(center - dir*6); task.wait(0.08)
  end
  h.CFrame=CFrame.new(center)
end

go.MouseButton1Click:Connect(function()
  if not selectedIndex then dd.Text="Pilih checkpoint dulu…"; return end
  local pos=CP[selectedIndex][2]; local h=HRP(); if h then h.CFrame=CFrame.new(pos); jumpDance(pos) end
end)

local hint=Instance.new("TextLabel"); hint.BackgroundTransparency=1; hint.TextWrapped=true
hint.TextColor3=Theme.text2; hint.Font=Enum.Font.Gotham; hint.TextSize=13
hint.Text="Pilih checkpoint di dropdown (kanan) lalu tekan 'Go To' untuk teleport."
hint.Size=UDim2.new(1,0,0,32); hint.Parent=secCP

--------------------------------------------------------------------
-- ============ Sub-section: POSEIDON QUEST =================-------
--------------------------------------------------------------------
local secPQ = Sec(mountRoot, "Poseidon Quest")

-- tombol baris vertikal biar rapi
local function makeBtn(text, parent, color)
  local b=Instance.new("TextButton"); b.AutoButtonColor=false; b.Text=text
  b.Font=Enum.Font.GothamSemibold; b.TextSize=14; b.TextColor3=Theme.text
  b.BackgroundColor3=color or Theme.accA; b.Size=UDim2.new(0,240,0,34); b.Parent=parent
  corner(b,8); stroke(b,Theme.accB,1).Transparency=.35
  return b
end

local btnKey  = makeBtn("Teleport ke Key",  secPQ)
local btnGate = makeBtn("Buka Gate",       secPQ)
local btnRun  = makeBtn("Auto Run (Key→Gate)", secPQ)

local status  = Instance.new("TextLabel"); status.BackgroundTransparency=1; status.TextWrapped=true
status.TextColor3=Theme.text2; status.Font=Enum.Font.Gotham; status.TextSize=13
status.Size=UDim2.new(1,0,0,32); status.Parent=secPQ
local function setStatus(t) status.Text="Status: "..t end

-- KOORDINAT (ganti jika update map)
local KEY_POS  = Vector3.new(-123.0,  10.0, 456.0)   -- TODO: isi titik kunci yang benar
local GATE_POS = Vector3.new( 789.0,  20.0,-321.0)   -- TODO: isi titik gate yang benar

local function tp(v3) local h=HRP(); if h then h.CFrame=CFrame.new(v3) end end

btnKey.MouseButton1Click:Connect(function() tp(KEY_POS);  setStatus("Teleport ke lokasi key.") end)

btnGate.MouseButton1Click:Connect(function()
  tp(GATE_POS)
  -- contoh logic dari dump: VaultKey.Touched -> PoseidonGate.Enabled true
  local ok=false
  local key = workspace:FindFirstChild("VaultKey", true)
  local gate= workspace:FindFirstChild("PoseidonGate", true)
  if key and key:IsA("BasePart") and gate and gate:IsA("BasePart") then
    key.Parent.Transparency = 1
    key.Enabled  = false
    gate.Enabled = true
    ok=true
  end
  setStatus(ok and "Gate dibuka." or "Gate: objek tidak ditemukan (cek nama/posisi).")
end)

btnRun.MouseButton1Click:Connect(function()
  tp(KEY_POS); task.wait(0.5)
  tp(GATE_POS); task.wait(0.2)
  btnGate:Activate()
end)

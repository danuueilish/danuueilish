-- src/mount_atin.lua
-- Fitur Mount Atin: pilih checkpoint lalu teleport

local UI = _G.danuu_hub_ui
if not UI then return end

-- Buat section dalam Tab Mount → "Mount Atin"
local sec = UI.NewSection(UI.Tabs.Mount, "Mount Atin • Checkpoint")

-- Dropdown daftar checkpoint
local dropdown = Instance.new("TextButton") -- placeholder buat dropdown UI
-- NOTE: kalau kamu mau dropdown proper (pilihan banyak), nanti bisa kita ganti sistem.
-- Untuk simple, kita pakai TextBox input sementara.
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, 0, 0, 34)
box.PlaceholderText = "Masukkan nomor checkpoint (1 - Summit)"
box.TextColor3 = Color3.new(1,1,1)
box.BackgroundColor3 = Color3.fromRGB(44,36,72)
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.ClearTextOnFocus = false
box.Parent = sec
local u = Instance.new("UICorner", box); u.CornerRadius = UDim.new(0,8)

-- Tombol Go To
local goBtn = Instance.new("TextButton")
goBtn.Size = UDim2.new(1,0,0,34)
goBtn.Text = "Go To"
goBtn.BackgroundColor3 = Color3.fromRGB(125,84,255)
goBtn.TextColor3 = Color3.new(1,1,1)
goBtn.Font = Enum.Font.GothamSemibold
goBtn.TextSize = 14
goBtn.Parent = sec
local u2 = Instance.new("UICorner",goBtn); u2.CornerRadius=UDim.new(0,8)

-- Keterangan
local note = Instance.new("TextLabel")
note.BackgroundTransparency = 1
note.TextWrapped = true
note.Text = "Pilih checkpoint (1 - Summit), lalu tekan 'Go To' untuk teleport."
note.TextColor3 = Color3.fromRGB(190,180,220)
note.Font = Enum.Font.Gotham
note.TextSize = 13
note.Size = UDim2.new(1,0,0,32)
note.Parent = sec

-- Contoh koordinat checkpoint (isi sesuai posisi game kamu)
local checkpoints = {
  ["1"] = Vector3.new(0,5,0),
  ["2"] = Vector3.new(10,20,0),
  ["3"] = Vector3.new(25,40,5),
  ["Summit"] = Vector3.new(50,100,10),
}

-- Fungsi teleport
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function tpTo(pos)
  if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
  lp.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
end

-- Aksi tombol
goBtn.MouseButton1Click:Connect(function()
  local val = box.Text
  if val and checkpoints[val] then
    tpTo(checkpoints[val])
  elseif val:lower() == "summit" and checkpoints["Summit"] then
    tpTo(checkpoints["Summit"])
  else
    note.Text = "⚠️ Checkpoint tidak valid, masukkan 1-3 atau 'Summit'."
    note.TextColor3 = Color3.fromRGB(255,95,95)
    task.delay(3, function()
      note.Text = "Pilih checkpoint (1 - Summit), lalu tekan 'Go To' untuk teleport."
      note.TextColor3 = Color3.fromRGB(190,180,220)
    end)
  end
end)

-- sticky_notes.lua
-- Sticky Notes untuk simpan ID boombox + copy/delete

local UI = _G.danuu_hub_ui
if not UI then return end

-- ===== Section di tab Music
local sec = UI.NewSection(UI.Tabs.Music, "Sticky Notes (Boombox IDs)")

-- TextBox: Nama
local boxName = Instance.new("TextBox")
boxName.Size = UDim2.new(1,0,0,32)
boxName.BackgroundColor3 = Color3.fromRGB(44,36,72)
boxName.TextColor3 = Color3.new(1,1,1)
boxName.PlaceholderText = "Nama lagu…"
boxName.PlaceholderColor3 = Color3.fromRGB(190,180,220)
boxName.Font = Enum.Font.Gotham
boxName.TextSize = 14
boxName.Text = ""       -- kosongin biar ga ada tulisan "TextBox"
boxName.ClearTextOnFocus = false
boxName.Parent = sec
Instance.new("UICorner", boxName).CornerRadius = UDim.new(0,8)

-- TextBox: ID
local boxId = Instance.new("TextBox")
boxId.Size = UDim2.new(1,0,0,32)
boxId.BackgroundColor3 = Color3.fromRGB(44,36,72)
boxId.TextColor3 = Color3.new(1,1,1)
boxId.PlaceholderText = "Kode/ID Boombox…"
boxId.PlaceholderColor3 = Color3.fromRGB(190,180,220)
boxId.Font = Enum.Font.Gotham
boxId.TextSize = 14
boxId.Text = ""
boxId.ClearTextOnFocus = false
boxId.Parent = sec
Instance.new("UICorner", boxId).CornerRadius = UDim.new(0,8)

-- ===== List Kode
local listSec = UI.NewSection(UI.Tabs.Music, "List Kode")

local function addRow(nm, id)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.fromRGB(44,36,72)
    row.Size = UDim2.new(1,0,0,32)
    row.Parent = listSec
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = string.format("%s  (%s)", tostring(nm), tostring(id))
    label.Size = UDim2.new(1,-150,1,0)
    label.Position = UDim2.fromOffset(8,0)
    label.Parent = row

    local copy = Instance.new("TextButton")
    copy.Size = UDim2.new(0,72,1,0)
    copy.Position = UDim2.new(1,-144,0,0)
    copy.Text = "Copy"
    copy.Font = Enum.Font.GothamSemibold
    copy.TextSize = 14
    copy.TextColor3 = Color3.new(1,1,1)
    copy.BackgroundColor3 = Color3.fromRGB(125,84,255)
    copy.AutoButtonColor = false
    copy.Parent = row
    Instance.new("UICorner", copy).CornerRadius = UDim.new(0,8)

    local del = Instance.new("TextButton")
    del.Size = UDim2.new(0,64,1,0)
    del.Position = UDim2.new(1,-72,0,0)
    del.Text = "Del"
    del.Font = Enum.Font.GothamSemibold
    del.TextSize = 14
    del.TextColor3 = Color3.new(1,1,1)
    del.BackgroundColor3 = Color3.fromRGB(215,55,255)
    del.AutoButtonColor = false
    del.Parent = row
    Instance.new("UICorner", del).CornerRadius = UDim.new(0,8)

    copy.MouseButton1Click:Connect(function()
        local s = tostring(id)
        if setclipboard then setclipboard(s) elseif toclipboard then toclipboard(s) end
    end)

    del.MouseButton1Click:Connect(function()
        row:Destroy()
    end)
end

-- Tombol Save
local save = Instance.new("TextButton")
save.Size = UDim2.new(1,0,0,34)
save.Text = "Save ke List"
save.Font = Enum.Font.GothamSemibold
save.TextSize = 14
save.TextColor3 = Color3.new(1,1,1)
save.BackgroundColor3 = Color3.fromRGB(125,84,255)
save.AutoButtonColor = false
save.Parent = sec
Instance.new("UICorner", save).CornerRadius = UDim.new(0,8)

save.MouseButton1Click:Connect(function()
    local nm = (boxName.Text or ""):gsub("^%s*(.-)%s*$","%1")
    local id = (boxId.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if nm ~= "" and id ~= "" then
        addRow(nm, id)
        boxName.Text = ""
        boxId.Text = ""
    end
end)

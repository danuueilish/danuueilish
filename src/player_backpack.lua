-- src/player_backpack.lua  
-- Check Player Backpack - danuu eilish Hub
local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Utility then return end

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local Theme = {
  bg    = Color3.fromRGB(24,20,40),
  panel = Color3.fromRGB(36,28,60),
  card  = Color3.fromRGB(44,36,72),
  text  = Color3.fromRGB(235,230,255),
  text2 = Color3.fromRGB(190,180,220),
  accA  = Color3.fromRGB(125,84,255),
  accB  = Color3.fromRGB(215,55,255),
  bad   = Color3.fromRGB(255,95,95),
  good  = Color3.fromRGB(106,212,123),
}

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

-- ===== Buat section di tab Utility
local section = UI.NewSection(UI.Tabs.Utility, "Check Player Backpack")

-- ===== Input & Button Row
local inputRow = Instance.new("Frame")
inputRow.BackgroundTransparency = 1
inputRow.Size = UDim2.new(1, 0, 0, 36)
inputRow.Parent = section

local inputLay = Instance.new("UIListLayout", inputRow)
inputLay.FillDirection = Enum.FillDirection.Horizontal
inputLay.Padding = UDim.new(0, 8)
inputLay.VerticalAlignment = Enum.VerticalAlignment.Center

-- Input TextBox
local playerInput = Instance.new("TextBox")
playerInput.Size = UDim2.new(0.7, -4, 1, 0)
playerInput.BackgroundColor3 = Theme.card
playerInput.TextColor3 = Theme.text
playerInput.PlaceholderText = "Masukkan nama player..."
playerInput.PlaceholderColor3 = Theme.text2
playerInput.ClearTextOnFocus = false
playerInput.Text = ""
playerInput.Font = Enum.Font.Gotham
playerInput.TextSize = 14
playerInput.TextXAlignment = Enum.TextXAlignment.Left
corner(playerInput, 8); stroke(playerInput, Theme.accA, 1).Transparency = .5
playerInput.Parent = inputRow

-- Check Button
local checkBtn = Instance.new("TextButton")
checkBtn.Size = UDim2.new(0.3, -4, 1, 0)
checkBtn.Text = "Cek Backpack"
checkBtn.Font = Enum.Font.GothamSemibold
checkBtn.TextSize = 14
checkBtn.TextColor3 = Theme.text
checkBtn.BackgroundColor3 = Theme.accA
checkBtn.AutoButtonColor = false
corner(checkBtn, 8); stroke(checkBtn, Theme.accB, 1).Transparency = .3
checkBtn.Parent = inputRow

-- ===== Result Display Area
local resultFrame = Instance.new("Frame")
resultFrame.BackgroundColor3 = Theme.card
resultFrame.Size = UDim2.new(1, 0, 0, 120)
resultFrame.Parent = section
corner(resultFrame, 8); stroke(resultFrame, Theme.accA, 1).Transparency = .5

local resultScroll = Instance.new("ScrollingFrame", resultFrame)
resultScroll.BackgroundTransparency = 1
resultScroll.Size = UDim2.fromScale(1, 1)
resultScroll.ScrollBarThickness = 6
resultScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
resultScroll.ClipsDescendants = true

-- Padding untuk result scroll
local resultPad = Instance.new("UIPadding", resultScroll)
resultPad.PaddingLeft = UDim.new(0, 10)
resultPad.PaddingRight = UDim.new(0, 10)
resultPad.PaddingTop = UDim.new(0, 8)
resultPad.PaddingBottom = UDim.new(0, 8)

local resultLay = Instance.new("UIListLayout", resultScroll)
resultLay.Padding = UDim.new(0, 4)
resultLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    resultScroll.CanvasSize = UDim2.new(0, 0, 0, resultLay.AbsoluteContentSize.Y + 16)
end)

-- ===== Quick Actions Row
local quickRow = Instance.new("Frame")
quickRow.BackgroundTransparency = 1
quickRow.Size = UDim2.new(1, 0, 0, 34)
quickRow.Parent = section

local quickLay = Instance.new("UIListLayout", quickRow)
quickLay.FillDirection = Enum.FillDirection.Horizontal
quickLay.Padding = UDim.new(0, 8)
quickLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
quickLay.VerticalAlignment = Enum.VerticalAlignment.Center

-- Button helper function
local function quickBtn(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 1, 0)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Theme.text
    btn.BackgroundColor3 = Theme.accA
    btn.AutoButtonColor = false
    corner(btn, 8); stroke(btn, Theme.accB, 1).Transparency = .4
    btn.Parent = quickRow
    
    btn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
    
    return btn
end

local checkAllBtn = quickBtn("Cek Semua Player", function() checkAllPlayers() end)
local clearBtn = quickBtn("Clear Results", function() clearResults() end)

-- ===== Helper Functions
function clearResults()
    for _, child in pairs(resultScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

function addResultText(text, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = color or Theme.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, 0, 0, 20)
    label.TextWrapped = true
    label.Parent = resultScroll
    
    return label
end

function getPlayerBackpack(targetPlayer)
    local items = {}
    
    if targetPlayer and targetPlayer.Backpack then
        for _, tool in pairs(targetPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, tool.Name)
            end
        end
    end
    
    return items
end

function checkPlayerBackpack(playerName)
    if not playerName or playerName == "" then
        addResultText("❌ Masukkan nama player terlebih dahulu!", Theme.bad)
        return
    end
    
    local targetPlayer = Players:FindFirstChild(playerName)
    
    if not targetPlayer then
        addResultText("❌ Player '" .. playerName .. "' tidak ditemukan!", Theme.bad)
        return
    end
    
    local items = getPlayerBackpack(targetPlayer)
    
    addResultText("=== " .. playerName .. "'s Backpack ===", Theme.accB)
    
    if #items > 0 then
        for i, itemName in pairs(items) do
            addResultText(i .. ". " .. itemName, Theme.text)
        end
        addResultText("Total: " .. #items .. " tools", Theme.good)
    else
        addResultText("Backpack kosong atau tidak bisa diakses", Theme.text2)
    end
    
    addResultText("────────────────────────", Theme.text2)
end

function checkAllPlayers()
    clearResults()
    addResultText("🔍 Scanning semua player...", Theme.accA)
    addResultText("", Theme.text) -- spacer
    
    local count = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            count = count + 1
            local items = getPlayerBackpack(player)
            
            addResultText("👤 " .. player.Name, Theme.accB)
            if #items > 0 then
                for i, itemName in pairs(items) do
                    addResultText("  " .. i .. ". " .. itemName, Theme.text)
                end
            else
                addResultText("  Backpack kosong", Theme.text2)
            end
            addResultText("", Theme.text) -- spacer
        end
    end
    
    if count == 0 then
        addResultText("Tidak ada player lain di server", Theme.text2)
    else
        addResultText("✅ Scan selesai - " .. count .. " player diperiksa", Theme.good)
    end
end

-- ===== Event Connections
checkBtn.MouseButton1Click:Connect(function()
    local playerName = playerInput.Text:match("^%s*(.-)%s*$") -- trim whitespace
    checkPlayerBackpack(playerName)
end)

-- Enter key support
playerInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local playerName = playerInput.Text:match("^%s*(.-)%s*$")
        checkPlayerBackpack(playerName)
    end
end)

-- ===== Initial message
addResultText("💡 Masukkan nama player dan klik 'Cek Backpack'", Theme.text2)
addResultText("🎯 Atau gunakan 'Cek Semua Player' untuk scan semua", Theme.text2)

print("[danuu-hub] Player Backpack Checker loaded ✓")

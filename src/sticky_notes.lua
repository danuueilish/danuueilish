local UI = _G.danuu_hub_ui; if not UI then return end
local sec = UI.NewSection(UI.Tabs.Music, "Sticky Notes (Boombox IDs)")

local boxName = Instance.new("TextBox"); boxName.Size=UDim2.new(1,0,0,32); boxName.PlaceholderText="Nama"; boxName.Parent=sec
local boxId   = Instance.new("TextBox"); boxId.Size=UDim2.new(1,0,0,32); boxId.PlaceholderText="Kode/ID Musik"; boxId.Parent=sec
for _,tb in ipairs({boxName,boxId}) do
  tb.BackgroundColor3=Color3.fromRGB(44,36,72); tb.TextColor3=Color3.new(1,1,1); tb.Font=Enum.Font.Gotham; tb.TextSize=14
  local u=Instance.new("UICorner",tb); u.CornerRadius=UDim.new(0,8)
end

local listSec = UI.NewSection(UI.Tabs.Music, "List Kode")
local function addRow(nm,id)
  local row=Instance.new("Frame"); row.BackgroundColor3=Color3.fromRGB(44,36,72); row.Size=UDim2.new(1,0,0,32); row.Parent=listSec
  local u=Instance.new("UICorner",row); u.CornerRadius=UDim.new(0,8)
  local label=Instance.new("TextLabel"); label.BackgroundTransparency=1; label.Text=nm.."  ("..id..")"; label.Font=Enum.Font.Gotham; label.TextSize=14; label.TextColor3=Color3.new(1,1,1); label.Size=UDim2.new(1,-150,1,0); label.Position=UDim2.fromOffset(8,0); label.Parent=row
  local copy=Instance.new("TextButton"); copy.Size=UDim2.new(0,64,1,0); copy.Text="Copy"; copy.Parent=row
  local del=Instance.new("TextButton");  del.Size=UDim2.new(0,64,1,0);  del.Text="Del";  del.Position=UDim2.new(1,-66,0,0); del.Parent=row
  for _,b in ipairs({copy,del}) do
    b.BackgroundColor3=Color3.fromRGB(125,84,255); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamSemibold; b.TextSize=14
    local c=Instance.new("UICorner",b); c.CornerRadius=UDim.new(0,8)
  end
  copy.MouseButton1Click:Connect(function()
    local s=tostring(id)
    if setclipboard then setclipboard(s) elseif toclipboard then toclipboard(s) end
  end)
  del.MouseButton1Click:Connect(function() row:Destroy() end)
end

local save=Instance.new("TextButton"); save.Size=UDim2.new(1,0,0,34); save.Text="Save ke List"; save.Parent=sec
save.BackgroundColor3=Color3.fromRGB(125,84,255); save.TextColor3=Color3.new(1,1,1); save.Font=Enum.Font.GothamSemibold; save.TextSize=14
local u=Instance.new("UICorner",save); u.CornerRadius=UDim.new(0,8)
save.MouseButton1Click:Connect(function()
  if (boxName.Text or "") ~= "" and (boxId.Text or "") ~= "" then
    addRow(boxName.Text, boxId.Text); boxName.Text=""; boxId.Text=""
  end
end)

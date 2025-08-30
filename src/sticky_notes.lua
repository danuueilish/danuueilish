-- sticky_notes.lua
local Http = game:GetService("HttpService")

local FILE = "danuu_music.json"
local FSOK = (writefile and readfile and isfile) and true or false

local db = {}
local function loadDB()
  if FSOK and isfile(FILE) then
    local ok, data = pcall(function() return Http:JSONDecode(readfile(FILE)) end)
    if ok and typeof(data)=="table" then db = data end
  end
end
local function saveDB()
  if not FSOK then return end
  local ok, err = pcall(function() writefile(FILE, Http:JSONEncode(db)) end)
  if not ok then warn("[StickyNotes] save failed:", err) end
end

local function copyText(s)
  if setclipboard then setclipboard(s) end
end

local M = {}
function M.mount(tab)
  loadDB()

  local s = tab:Section("Sticky Notes • Music IDs")
  s:Hint("Simpan ID boombox beserta nama, lalu Copy dengan sekali klik.")

  local inName  = s:Textbox("Nama Lagu", "", function() end)
  local inId    = s:Textbox("ID (angka)", "", function() end)

  s:Button("Save", function()
    local name = tostring(inName.Text or ""):gsub("^%s+",""):gsub("%s+$","")
    local id   = tostring(inId.Text or ""):gsub("%s+","")
    if name=="" or id=="" then return end
    table.insert(db, {name=name, id=id})
    saveDB()
    inName.Text=""; inId.Text=""
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="Sticky Notes", Text="Saved ✓", Duration=2})
    renderList()
  end)

  s:Spacer(6)
  s:Label("List Kode")

  local listSec = tab:Section("Saved")
  local container -- holder list rows

  local function makeRow(it, idx)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.fromRGB(44,36,72)
    row.Size = UDim2.new(1,0,0,32)
    row.Parent = container
    local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p end
    corner(row,8)

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency=1
    name.Text= string.format("%s  –  %s", it.name, it.id)
    name.Font=Enum.Font.Gotham; name.TextSize=14; name.TextColor3=Color3.fromRGB(235,230,255)
    name.TextXAlignment=Enum.TextXAlignment.Left
    name.Size=UDim2.new(1,-140,1,0)
    name.Position=UDim2.fromOffset(8,0)
    name.Parent=row

    local copy = Instance.new("TextButton")
    copy.Text="Copy"
    copy.Font=Enum.Font.GothamSemibold; copy.TextSize=14; copy.TextColor3=Color3.fromRGB(235,230,255)
    copy.AutoButtonColor=false
    copy.BackgroundColor3 = Color3.fromRGB(125,84,255)
    copy.Size=UDim2.new(0,60,1,0)
    copy.Position=UDim2.new(1,-132,0,0)
    copy.Parent=row
    corner(copy,8)
    copy.MouseButton1Click:Connect(function()
      copyText(it.id)
      game:GetService("StarterGui"):SetCore("SendNotification", {Title="Sticky Notes", Text="Copied ✓", Duration=2})
    end)

    local del = Instance.new("TextButton")
    del.Text="✕"
    del.Font=Enum.Font.GothamBold; del.TextSize=14; del.TextColor3=Color3.fromRGB(235,230,255)
    del.AutoButtonColor=false
    del.BackgroundColor3 = Color3.fromRGB(255,95,95)
    del.Size=UDim2.new(0,56,1,0)
    del.Position=UDim2.new(1,-68,0,0)
    del.Parent=row
    corner(del,8)
    del.MouseButton1Click:Connect(function()
      table.remove(db, idx)
      saveDB()
      renderList()
    end)
  end

  function renderList()
    if container then container:Destroy() end
    container = Instance.new("Frame")
    container.BackgroundTransparency=1
    container.Size=UDim2.new(1,0,0,0)
    container.Parent = listSec.Parent -- let section auto-resize
    local ui = Instance.new("UIListLayout", container); ui.Padding=UDim.new(0,6)
    for i,it in ipairs(db) do makeRow(it,i) end
  end

  renderList()
end

return M

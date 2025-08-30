-- src/home.lua
-- Home card (KTP) untuk tab "Menu" tanpa mengubah ui_main.lua

local Players  = game:GetService("Players")
local MPS      = game:GetService("MarketplaceService")
local Http     = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- Tunggu API dari ui_main.lua
local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu then return end

-- Theme fallback (pakai dari ui_main kalau ada)
local Theme = (_G.danuu_theme) or {
  bg    = Color3.fromRGB(24,20,40),
  card  = Color3.fromRGB(44,36,72),
  text  = Color3.fromRGB(235,230,255),
  text2 = Color3.fromRGB(190,180,220),
  accA  = Color3.fromRGB(125,84,255),
  accB  = Color3.fromRGB(215,55,255),
}

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

-- ==== Rename tombol "Menu" -> "Home" (tanpa akses internal) ====
do
  local root = UI.Window
  if root then
    for _,d in ipairs(root:GetDescendants()) do
      if d:IsA("TextButton") and d.Text == "Menu" then
        d.Text = "Home"
        break
      end
    end
  end
end

-- ==== Helper data ====
local function fetchMapName()
  local name = "Unknown"
  pcall(function() name = (MPS:GetProductInfo(game.PlaceId) or {}).Name or name end)
  return name
end

local function fetchAvatarUrl()
  local url
  pcall(function()
    url = (Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size180x180))
  end)
  return url or ""
end

local function fetchBio()
  -- Coba API Roblox (butuh HttpService diizinkan)
  local bio
  pcall(function()
    local raw = game:HttpGet(("https://users.roblox.com/v1/users/%d"):format(LP.UserId))
    local data = Http:JSONDecode(raw)
    if data and typeof(data)=="table" and data.description and #data.description>0 then
      bio = data.description
    end
  end)
  return bio or "—"
end

-- ==== Buat Section "Home" di Tab Menu ====
local inner = UI.NewSection(UI.Tabs.Menu, "Home")

-- ==== Kartu KTP ====
local card = Instance.new("Frame")
card.BackgroundColor3 = Theme.card
card.Size = UDim2.new(1, -16, 0, 160)
card.Parent = inner
corner(card,10); stroke(card,Theme.accA,1).Transparency=.55

-- Avatar (3x3)
local avatar = Instance.new("ImageLabel")
avatar.BackgroundColor3 = Theme.bg
avatar.Image = fetchAvatarUrl()
avatar.Size = UDim2.new(0, 110, 0, 110)
avatar.Position = UDim2.fromOffset(12,12)
avatar.Parent = card
corner(avatar,8); stroke(avatar,Theme.accB,1).Transparency=.35

-- Kolom kanan (tabel 2 kolom sejajar)
local right = Instance.new("Frame")
right.BackgroundTransparency = 1
right.Size = UDim2.new(1, -(12+110+12), 1, -24)
right.Position = UDim2.fromOffset(110+12+12,12)
right.Parent = card

local vlist = Instance.new("UIListLayout", right)
vlist.Padding = UDim.new(0,8)
vlist.SortOrder = Enum.SortOrder.LayoutOrder

local function row(labelText, valueText)
  local r = Instance.new("Frame")
  r.BackgroundTransparency = 1
  r.Size = UDim2.new(1,0,0,22)
  r.Parent = right

  local rl = Instance.new("TextLabel")
  rl.BackgroundTransparency = 1
  rl.Text = labelText
  rl.Font = Enum.Font.GothamSemibold
  rl.TextSize = 14
  rl.TextColor3 = Theme.text
  rl.TextXAlignment = Enum.TextXAlignment.Left
  rl.Size = UDim2.new(0,120,1,0)
  rl.Position = UDim2.fromOffset(0,0)
  rl.Parent = r

  local rv = Instance.new("TextLabel")
  rv.BackgroundTransparency = 1
  rv.Text = valueText
  rv.Font = Enum.Font.Gotham
  rv.TextSize = 14
  rv.TextColor3 = Theme.text2
  rv.TextXAlignment = Enum.TextXAlignment.Left
  rv.TextWrapped = true
  rv.TextTruncate = Enum.TextTruncate.AtEnd
  rv.Size = UDim2.new(1,-(120+8),1,0)
  rv.Position = UDim2.fromOffset(120+8,0)
  rv.Parent = r
  return rv
end

row("Map:",        fetchMapName())
row("Username:",   LP.DisplayName)                            -- pakai DisplayName
row("Account Age:", tostring(LP.AccountAge) .. " days")
row("Bio:",        fetchBio())

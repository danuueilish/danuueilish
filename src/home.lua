-- src/home.lua
-- Home card — semua rata kiri + Total Playtime Today

local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu then return end

local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")

local LP = Players.LocalPlayer

-- Theme selaras hub
local Theme = {
  bg    = Color3.fromRGB(24,20,40),
  card  = Color3.fromRGB(44,36,72),
  text  = Color3.fromRGB(235,230,255),
  text2 = Color3.fromRGB(190,180,220),
  accA  = Color3.fromRGB(125,84,255),
  accB  = Color3.fromRGB(215,55,255),
}

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

-- Section Home
local inner = UI.NewSection(UI.Tabs.Menu, "Home")

-- Kartu utama
local card = Instance.new("Frame")
card.BackgroundColor3 = Theme.bg
card.Size = UDim2.new(1, 0, 0, 240)
card.Parent = inner
corner(card, 10); stroke(card, Theme.accA, 1).Transparency = .5
local pad = Instance.new("UIPadding", card)
pad.PaddingLeft, pad.PaddingRight = UDim.new(0,10), UDim.new(0,10)
pad.PaddingTop,  pad.PaddingBottom = UDim.new(0,10), UDim.new(0,10)

local row = Instance.new("UIListLayout", card)
row.FillDirection = Enum.FillDirection.Horizontal
row.Padding = UDim.new(0, 12)
row.VerticalAlignment = Enum.VerticalAlignment.Top
row.HorizontalAlignment = Enum.HorizontalAlignment.Left
row.SortOrder = Enum.SortOrder.LayoutOrder

-- Avatar kolom kiri
local avatarWrap = Instance.new("Frame")
avatarWrap.LayoutOrder = 1
avatarWrap.BackgroundTransparency = 1
avatarWrap.Size = UDim2.new(0, 120, 1, 0)
avatarWrap.Parent = card

local avatar = Instance.new("ImageLabel")
avatar.BackgroundColor3 = Theme.card
avatar.Size = UDim2.new(0, 120, 0, 120)
avatar.Parent = avatarWrap
avatar.ScaleType = Enum.ScaleType.Fit
corner(avatar, 10); stroke(avatar, Theme.accB, 1).Transparency = .4

pcall(function()
  local t = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
  avatar.Image = t
end)

-- Total Playtime Today (di bawah avatar)
local playBox = Instance.new("Frame")
playBox.BackgroundColor3 = Theme.card
playBox.Size = UDim2.new(0, 120, 0, 80)
playBox.Position = UDim2.fromOffset(0, 130)
playBox.Parent = avatarWrap
corner(playBox, 12); stroke(playBox, Theme.accA, 1).Transparency = .5
local pbPad = Instance.new("UIPadding", playBox)
pbPad.PaddingTop, pbPad.PaddingLeft, pbPad.PaddingRight = UDim.new(0,6), UDim.new(0,8), UDim.new(0,8)

local pbTitle = Instance.new("TextLabel")
pbTitle.BackgroundTransparency = 1
pbTitle.Font = Enum.Font.GothamSemibold
pbTitle.TextSize = 12
pbTitle.TextColor3 = Theme.text2
pbTitle.TextXAlignment = Enum.TextXAlignment.Left
pbTitle.Size = UDim2.new(1, 0, 0, 16)
pbTitle.Text = "Total Playtime Today"
pbTitle.Parent = playBox

local pbValue = Instance.new("TextLabel")
pbValue.BackgroundTransparency = 1
pbValue.Font = Enum.Font.GothamBlack
pbValue.TextSize = 18
pbValue.TextColor3 = Theme.text
pbValue.TextXAlignment = Enum.TextXAlignment.Left
pbValue.Position = UDim2.fromOffset(0, 22)
pbValue.Size = UDim2.new(1, 0, 0, 24)
pbValue.Text = "00:00:00"
pbValue.Parent = playBox

local function fmt(sec) local h=sec//3600 local m=(sec%3600)//60 local s=sec%60 return string.format("%02d:%02d:%02d",h,m,s) end
local startTick = os.clock()
task.spawn(function()
  while playBox.Parent do
    pbValue.Text = fmt(math.floor(os.clock() - startTick))
    task.wait(1)
  end
end)

-- Panel info (kanan)
local info = Instance.new("Frame")
info.LayoutOrder = 2
info.BackgroundTransparency = 1
info.Size = UDim2.new(1, -132, 1, 0)  -- sisakan lebar avatar
info.Parent = card

local infoList = Instance.new("UIListLayout", info)
infoList.Padding = UDim.new(0, 8)
infoList.HorizontalAlignment = Enum.HorizontalAlignment.Left
infoList.VerticalAlignment = Enum.VerticalAlignment.Top
infoList.SortOrder = Enum.SortOrder.LayoutOrder

-- Row helper: [Key 120px] [Value] — paksa urutan pakai LayoutOrder
local function keyValueRow(keyText)
  local r = Instance.new("Frame")
  r.BackgroundColor3 = Theme.card
  r.Size = UDim2.new(1, 0, 0, 50)
  r.Parent = info
  corner(r, 10); stroke(r, Theme.accA, 1).Transparency = .65
  local rp = Instance.new("UIPadding", r)
  rp.PaddingLeft, rp.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)

  local h = Instance.new("UIListLayout", r)
  h.FillDirection = Enum.FillDirection.Horizontal
  h.Padding = UDim.new(0, 8)
  h.HorizontalAlignment = Enum.HorizontalAlignment.Left
  h.VerticalAlignment = Enum.VerticalAlignment.Center
  h.SortOrder = Enum.SortOrder.LayoutOrder  -- << fix utama

  local key = Instance.new("TextLabel")
  key.LayoutOrder = 1                       -- << key selalu kiri
  key.BackgroundTransparency = 1
  key.Size = UDim2.new(0, 120, 1, 0)
  key.Font = Enum.Font.GothamSemibold
  key.TextSize = 16
  key.TextXAlignment = Enum.TextXAlignment.Left
  key.TextColor3 = Theme.text
  key.Text = keyText
  key.Parent = r

  local clip = Instance.new("Frame")
  clip.LayoutOrder = 2                      -- << value selalu kanan
  clip.BackgroundTransparency = 1
  clip.ClipsDescendants = true
  clip.Size = UDim2.new(1, -(120+8), 1, 0)
  clip.Parent = r

  return r, clip
end

-- Marquee (nunggu ukuran siap)
local function setMarquee(parentClip, text, opts)
  opts = opts or {}
  local font  = opts.Font or Enum.Font.Gotham
  local size  = opts.TextSize or 16
  local color = opts.TextColor3 or Theme.text
  local gap   = opts.Gap or 40
  local speed = opts.Speed or 60

  if parentClip.AbsoluteSize.X <= 1 then
    repeat task.wait() until not parentClip or not parentClip.Parent or parentClip.AbsoluteSize.X > 1
    if not parentClip or not parentClip.Parent then return end
  end

  local meas = Instance.new("TextLabel")
  meas.BackgroundTransparency = 1
  meas.Visible = false
  meas.Size = UDim2.new(0, 9999, 0, 0)
  meas.Text = text
  meas.Font = font
  meas.TextSize = size
  meas.Parent = parentClip
  local w = meas.TextBounds.X
  meas:Destroy()

  if w <= parentClip.AbsoluteSize.X or w == 0 then
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = font
    lbl.TextSize = size
    lbl.TextColor3 = color
    lbl.Text = text
    lbl.Parent = parentClip
    return
  end

  local holder = Instance.new("Frame")
  holder.BackgroundTransparency = 1
  holder.Size = UDim2.new(0, w*2 + gap, 1, 0)
  holder.Parent = parentClip

  local a = Instance.new("TextLabel")
  a.BackgroundTransparency = 1
  a.Font = font; a.TextSize = size; a.TextColor3 = color
  a.TextXAlignment = Enum.TextXAlignment.Left
  a.Size = UDim2.new(0, w, 1, 0)
  a.Position = UDim2.new(0, 0, 0, 0)
  a.Text = text
  a.Parent = holder

  local b = a:Clone()
  b.Position = UDim2.new(0, w + gap, 0, 0)
  b.Parent = holder

  task.spawn(function()
    while holder.Parent do
      local total = w + gap
      holder.Position = UDim2.new(0, 0, 0, 0)
      local t = total / speed
      local tw = TweenService:Create(holder, TweenInfo.new(t, Enum.EasingStyle.Linear), {Position = UDim2.new(0, -total, 0, 0)})
      tw:Play(); tw.Completed:Wait()
    end
  end)
end

-- Data
local mapName = "Unknown Place"
pcall(function()
  local info = MarketplaceService:GetProductInfo(game.PlaceId)
  if info and info.Name then mapName = info.Name end
end)
local username   = LP.DisplayName or LP.Name
local accountAge = ("%d days"):format(LP.AccountAge or 0)

local bioText = "—"
pcall(function()
  local raw = game:HttpGet(("https://users.roblox.com/v1/users/%d"):format(LP.UserId))
  local data = HttpService:JSONDecode(raw)
  if type(data)=="table" and type(data.description)=="string" and #data.description>0 then
    bioText = data.description
  end
end)

-- Rows (kiri → kanan)
do local _, clip = keyValueRow("Map:");         setMarquee(clip, mapName,   {TextSize=16}) end
do local _, clip = keyValueRow("Username:");    setMarquee(clip, username,  {TextSize=16}) end
do local _, clip = keyValueRow("Account Age:"); setMarquee(clip, accountAge,{TextSize=16}) end
do local _, clip = keyValueRow("Bio:");         setMarquee(clip, bioText,   {TextSize=16, Speed=50}) end

-- src/home.lua
-- "Home" card (ID-style) with avatar + info + marquee for long text

local UI = _G.danuu_hub_ui
if not UI or not UI.Tabs or not UI.Tabs.Menu then return end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer

-- ==== tiny UI helpers (match hub style)
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

-- ==== section container inside existing Menu/Home tab
local inner = UI.NewSection(UI.Tabs.Menu, "Home")

-- ==== Card (avatar left, info right)
local card = Instance.new("Frame")
card.BackgroundColor3 = Theme.bg
card.Size = UDim2.new(1, 0, 0, 200)
card.Parent = inner
corner(card, 10); stroke(card, Theme.accA, 1).Transparency = .5

local pad = Instance.new("UIPadding", card)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)

-- layout
local row = Instance.new("UIListLayout", card)
row.FillDirection = Enum.FillDirection.Horizontal
row.Padding = UDim.new(0, 12)
row.VerticalAlignment = Enum.VerticalAlignment.Top

-- ==== Avatar (3x3 style: 120x120)
local avatarWrap = Instance.new("Frame")
avatarWrap.BackgroundTransparency = 1
avatarWrap.Size = UDim2.new(0, 120, 0, 120)
avatarWrap.Parent = card

local avatar = Instance.new("ImageLabel")
avatar.BackgroundColor3 = Theme.card
avatar.Size = UDim2.new(1, 0, 1, 0)
avatar.Parent = avatarWrap
avatar.ScaleType = Enum.ScaleType.Fit
corner(avatar, 10); stroke(avatar, Theme.accB, 1).Transparency = .4

-- get thumb
pcall(function()
  local t, isReady = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
  avatar.Image = t
end)

-- ==== Right side info (keys left aligned, values with marquee)
local info = Instance.new("Frame")
info.BackgroundTransparency = 1
info.Size = UDim2.new(1, -132, 1, -0) -- a bit more to the LEFT
info.Parent = card

local infoList = Instance.new("UIListLayout", info)
infoList.Padding = UDim.new(0, 10)

local function keyValueRow(keyText)
  local r = Instance.new("Frame")
  r.BackgroundColor3 = Theme.card
  r.Size = UDim2.new(1, 0, 0, 54)
  r.Parent = info
  corner(r, 10); stroke(r, Theme.accA, 1).Transparency = .65

  local rPad = Instance.new("UIPadding", r)
  rPad.PaddingLeft = UDim.new(0, 12)   -- nudged left
  rPad.PaddingRight = UDim.new(0, 12)
  rPad.PaddingTop = UDim.new(0, 8)
  rPad.PaddingBottom = UDim.new(0, 8)

  local h = Instance.new("UIListLayout", r)
  h.FillDirection = Enum.FillDirection.Horizontal
  h.Padding = UDim.new(0, 8)
  h.VerticalAlignment = Enum.VerticalAlignment.Center

  -- key label (fixed width, a bit smaller to bring value left)
  local key = Instance.new("TextLabel")
  key.BackgroundTransparency = 1
  key.Size = UDim2.new(0, 110, 1, 0)
  key.Font = Enum.Font.GothamSemibold
  key.TextSize = 16
  key.TextXAlignment = Enum.TextXAlignment.Left
  key.TextColor3 = Theme.text
  key.Text = keyText
  key.Parent = r

  -- value container (clips, used by marquee if overflow)
  local valueClip = Instance.new("Frame")
  valueClip.BackgroundTransparency = 1
  valueClip.ClipsDescendants = true
  valueClip.Size = UDim2.new(1, -110 - 8, 1, 0)
  valueClip.Parent = r

  return r, valueClip
end

-- ==== Marquee helper (only if content wider than clip)
local function setMarquee(parentClip, text, opts)
  opts = opts or {}
  local font = opts.Font or Enum.Font.Gotham
  local size = opts.TextSize or 16
  local color = opts.TextColor3 or Theme.text
  local gap   = opts.Gap or 40
  local speed = opts.Speed or 60 -- pixels per second

  -- measure
  local meas = Instance.new("TextLabel")
  meas.Size = UDim2.new(0, 9999, 0, 0)
  meas.Visible = false
  meas.Text = text
  meas.Font = font
  meas.TextSize = size
  meas.Parent = parentClip
  local w = meas.TextBounds.X
  meas:Destroy()

  -- if fits: simple label (no marquee)
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

  -- scrolling group
  local holder = Instance.new("Frame")
  holder.BackgroundTransparency = 1
  holder.Size = UDim2.new(0, w*2 + gap, 1, 0) -- two copies + gap
  holder.Parent = parentClip

  local a = Instance.new("TextLabel")
  a.BackgroundTransparency = 1
  a.Font = font; a.TextSize = size; a.TextColor3 = color
  a.TextXAlignment = Enum.TextXAlignment.Left
  a.Size = UDim2.new(0, w, 1, 0); a.Position = UDim2.new(0, 0, 0, 0)
  a.Text = text; a.Parent = holder

  local b = a:Clone()
  b.Position = UDim2.new(0, w + gap, 0, 0)
  b.Parent = holder

  -- animate forever
  task.spawn(function()
    while holder.Parent do
      local total = w + gap
      holder.Position = UDim2.new(0, 0, 0, 0)
      local t = total / speed
      local tw = TweenService:Create(holder, TweenInfo.new(t, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Position = UDim2.new(0, -total, 0, 0)})
      tw:Play(); tw.Completed:Wait()
    end
  end)
end

-- ==== fetch data
local placeName = ("[%s]"):format("UPDATE!")  -- prefix if kamu suka gaya ini
pcall(function()
  local info = MarketplaceService:GetProductInfo(game.PlaceId)
  if info and info.Name then placeName = info.Name end
end)

local displayName = LP.DisplayName or LP.Name
local accountAge  = tostring(LP.AccountAge).." days"

local bioText = "—"
pcall(function()
  local raw = game:HttpGet(("https://users.roblox.com/v1/users/%d"):format(LP.UserId))
  local data = HttpService:JSONDecode(raw)
  if type(data)=="table" and type(data.description)=="string" and #data.description>0 then
    bioText = data.description
  end
end)

-- ==== rows
do
  local _, clip = keyValueRow("Map:")
  setMarquee(clip, placeName, {TextSize=16})
end

do
  local _, clip = keyValueRow("Username:")
  setMarquee(clip, displayName, {TextSize=16})
end

do
  local _, clip = keyValueRow("Account Age:")
  setMarquee(clip, accountAge, {TextSize=16})
end

do
  local _, clip = keyValueRow("Bio:")
  setMarquee(clip, bioText, {TextSize=16, Speed=50})
end

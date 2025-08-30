-- ui_main.lua
-- danuu eilish • Hub — kerangka UI + tabs
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- ===== util UI kecil
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function pad(p,px) local pd=Instance.new("UIPadding"); pd.PaddingTop=UDim.new(0,px); pd.PaddingBottom=UDim.new(0,px); pd.PaddingLeft=UDim.new(0,px); pd.PaddingRight=UDim.new(0,px); pd.Parent=p; return pd end

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

-- ===== root gui
local sg=Instance.new("ScreenGui")
sg.Name="danuu_hub"
sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Global
pcall(function() sg.Parent = CoreGui end)
if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

-- autoscale
local scaler=Instance.new("UIScale", sg)
local function rescale()
  local cam=workspace.CurrentCamera
  local vs = cam and cam.ViewportSize or Vector2.new(1280,720)
  scaler.Scale = math.clamp(vs.X/520, 0.75, 1)
end
rescale()
if workspace.CurrentCamera then
  workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

-- ===== window
local root=Instance.new("Frame")
root.Name="Window"
root.Active=true
root.BackgroundColor3=Theme.panel
root.Size=UDim2.fromOffset(640,420)
root.Position=UDim2.new(0.5,-320,0.5,-210)
root.Parent=sg
corner(root,16); stroke(root,Theme.accA,1).Transparency=.8

local title=Instance.new("Frame"); title.Size=UDim2.new(1,0,0,46); title.BackgroundColor3=Theme.card; title.Parent=root
corner(title,16); stroke(title,Theme.accB,1).Transparency=.75
local ttl=Instance.new("TextLabel"); ttl.BackgroundTransparency=1; ttl.Text="danuu eilish • Hub"; ttl.Font=Enum.Font.GothamBold; ttl.TextSize=16; ttl.TextColor3=Theme.text; ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.Size=UDim2.new(1,-120,1,0); ttl.Position=UDim2.fromOffset(14,0); ttl.Parent=title

local btnRow=Instance.new("Frame"); btnRow.BackgroundTransparency=1; btnRow.Size=UDim2.fromOffset(96,36); btnRow.Position=UDim2.new(1,-100,0.5,-18); btnRow.Parent=title
local li=Instance.new("UIListLayout",btnRow); li.FillDirection=Enum.FillDirection.Horizontal; li.Padding=UDim.new(0,8); li.HorizontalAlignment=Enum.HorizontalAlignment.Right; li.VerticalAlignment=Enum.VerticalAlignment.Center
local function topBtn(txt,col)
  local b=Instance.new("TextButton"); b.AutoButtonColor=false; b.Text=txt; b.Font=Enum.Font.GothamBold; b.TextSize=16; b.TextColor3=Theme.text
  b.BackgroundColor3=col; b.Size=UDim2.fromOffset(36,36); b.Parent=btnRow; corner(b,10); stroke(b,Color3.new(1,1,1),1).Transparency=.75
  b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.1),{BackgroundColor3=Theme.accA}):Play() end)
  b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.15),{BackgroundColor3=col}):Play() end)
  return b
end
local btnMin   = topBtn("–", Theme.bg)
local btnClose = topBtn("✕", Theme.bad)

-- drag
do
  local dragging=false; local start; local startPos
  title.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
      dragging=true; start=i.Position; startPos=root.Position
      i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
      local d=i.Position-start
      root.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
  end)
end

-- bubble minimize
local bubble=Instance.new("Frame"); bubble.Visible=false; bubble.Size=UDim2.fromOffset(56,56); bubble.BackgroundColor3=Theme.accA; bubble.Parent=sg
corner(bubble,28); stroke(bubble,Theme.accB,2).Transparency=.2
local bTxt=Instance.new("TextLabel"); bTxt.BackgroundTransparency=1; bTxt.Size=UDim2.fromScale(1,1); bTxt.Font=Enum.Font.GothamBlack; bTxt.Text="DE"; bTxt.TextSize=20; bTxt.TextColor3=Theme.text; bTxt.Parent=bubble
local function placeBubble() local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720); bubble.Position=UDim2.fromOffset(vs.X-66,20) end
placeBubble(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeBubble) end
btnMin.MouseButton1Click:Connect(function()
  bubble.Visible=true; Tween:Create(root,TweenInfo.new(.15),{BackgroundTransparency=1}):Play(); Tween:Create(root,TweenInfo.new(.18),{Size=UDim2.fromOffset(320,80)}):Play(); task.delay(.18,function() root.Visible=false end)
end)
bubble.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then root.Visible=true; bubble.Visible=false; Tween:Create(root,TweenInfo.new(.18),{BackgroundTransparency=0}):Play(); Tween:Create(root,TweenInfo.new(.20),{Size=UDim2.fromOffset(640,420)}):Play() end end)
btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)

-- ===== kiri: tabs
local tabList=Instance.new("Frame"); tabList.BackgroundColor3=Theme.bg; tabList.Size=UDim2.new(0,140,1,-58); tabList.Position=UDim2.fromOffset(8,50); tabList.Parent=root
corner(tabList,12); stroke(tabList,Theme.accA,1).Transparency=.8; pad(tabList,8)
local tabButtons=Instance.new("UIListLayout",tabList); tabButtons.Padding=UDim.new(0,8)

-- kanan: content
local content=Instance.new("Frame"); content.BackgroundColor3=Theme.bg; content.Size=UDim2.new(1,-(140+24),1,-58); content.Position=UDim2.fromOffset(140+16,50); content.Parent=root
corner(content,12); stroke(content,Theme.accA,1).Transparency=.8; pad(content,10)

local function mkTabButton(text)
  local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,34); b.Text=text; b.Font=Enum.Font.GothamSemibold; b.TextSize=14; b.TextColor3=Theme.text
  b.BackgroundColor3=Theme.card; b.AutoButtonColor=false; b.Parent=tabList; corner(b,8); stroke(b,Theme.accB,1).Transparency=.5
  b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.08),{BackgroundColor3=Theme.accA}):Play() end)
  b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.12),{BackgroundColor3=Theme.card}):Play() end)
  return b
end

local Tabs = {}
local function createTab(name)
  local btn = mkTabButton(name)
  local page=Instance.new("ScrollingFrame")
  page.Visible=false; page.BackgroundTransparency=1; page.Size=UDim2.fromScale(1,1)
  page.ScrollBarThickness=6; page.CanvasSize=UDim2.new(0,0,0,0); page.Parent=content

  -- padding konten
  local pagePad = Instance.new("UIPadding", page)
  pagePad.PaddingLeft, pagePad.PaddingRight = UDim.new(0,8), UDim.new(0,8)
  pagePad.PaddingTop, pagePad.PaddingBottom = UDim.new(0,8), UDim.new(0,8)

  local lay=Instance.new("UIListLayout",page); lay.Padding=UDim.new(0,10)
  lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    page.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+10)
  end)

  local t={Name=name, Button=btn, Page=page}; table.insert(Tabs,t)
  btn.MouseButton1Click:Connect(function()
    for _,tb in ipairs(Tabs) do tb.Page.Visible=false end
    page.Visible=true
  end)
  return t
end

local function section(parent, titleText)
  local container=Instance.new("Frame")
  container.BackgroundColor3=Theme.card
  container.Size=UDim2.new(1,-4,0,60)  -- shrink 4px
  container.Position=UDim2.fromOffset(2,0)
  container.Parent=parent
  container.ClipsDescendants=false
  corner(container,12)
  stroke(container,Theme.accA,1).Transparency=.6

  local head=Instance.new("TextLabel")
  head.BackgroundTransparency=1
  head.Text="  "..titleText
  head.Font=Enum.Font.GothamBlack
  head.TextSize=18
  head.TextColor3=Theme.text
  head.TextXAlignment=Enum.TextXAlignment.Left
  head.Size=UDim2.new(1,-8,0,28)
  head.Position=UDim2.fromOffset(8,6)
  head.Parent=container

  local inner=Instance.new("Frame")
  inner.BackgroundTransparency=1
  inner.Size=UDim2.new(1,-16,0,0)
  inner.Position=UDim2.fromOffset(8,36)
  inner.Parent=container

  local v=Instance.new("UIListLayout",inner); v.Padding=UDim.new(0,8)
  local function resize()
    container.Size=UDim2.new(1,-4,0, math.max(60,40+v.AbsoluteContentSize.Y))
    inner.Size=UDim2.new(1,-16,0,v.AbsoluteContentSize.Y)
  end
  v:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
  task.defer(resize)

  return inner
end

-- ===== buat tabs
local TabMenu     = createTab("Menu")
local TabMount    = createTab("Mount")
local TabMusic    = createTab("Music")
local TabUtility  = createTab("Utility")
local TabSettings = createTab("Settings")

TabMenu.Page.Visible=true

-- ===== isi default
do
  local s = section(TabMenu.Page, "Welcome")
  local t = Instance.new("TextLabel")
  t.BackgroundTransparency=1
  t.TextWrapped=true
  t.Text="Halo! Ini hub utama. Join Discord: discord.gg/yourlink (ganti nanti)."
  t.TextColor3=Theme.text2
  t.Font=Enum.Font.Gotham
  t.TextSize=14
  t.Size=UDim2.new(1,0,0,34)
  t.Parent=s
end

-- ===== Section untuk semua Mount + SIMPAN REFERENSI
local MountSections = {}
do
  local names={"Mount Atin","Mount Daun","Mount Sumbing","Mount Sibuatan","Mount Antarctica"}
  for _,n in ipairs(names) do
    MountSections[n] = section(TabMount.Page, n)  -- simpan inner frame
  end
end

do section(TabUtility.Page,"Rejoin / Server Hop") end

-- ===== API untuk modul lain
local API = {
  RootGui=sg,
  Window=root,
  Tabs={
    Menu=TabMenu.Page,
    Mount=TabMount.Page,
    Music=TabMusic.Page,
    Utility=TabUtility.Page,
    Settings=TabSettings.Page
  },
  NewSection=section,
  MountSections = MountSections, -- <— penting: referensi section per-mount
}
_G.danuu_hub_ui=API
return API

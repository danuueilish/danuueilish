-- ui_main.lua
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LP=Players.LocalPlayer

local Theme = {
  bg    = Color3.fromRGB(24,20,40),
  card  = Color3.fromRGB(44,36,72),
  text  = Color3.fromRGB(235,230,255),
  dim   = Color3.fromRGB(190,180,220),
  accA  = Color3.fromRGB(125,84,255),
  accB  = Color3.fromRGB(215,55,255),
  bad   = Color3.fromRGB(255,95,95),
  ok    = Color3.fromRGB(106,212,123)
}
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function pad(p,px) local pd=Instance.new("UIPadding"); pd.PaddingTop=UDim.new(0,px); pd.PaddingBottom=UDim.new(0,px); pd.PaddingLeft=UDim.new(0,px); pd.PaddingRight=UDim.new(0,px); pd.Parent=p; return pd end

local UI = {}
local sg = Instance.new("ScreenGui")
sg.Name="danuu_hub_ui"
sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Global
pcall(function() sg.Parent = CoreGui end)
if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

-- root window
local root=Instance.new("Frame")
root.Active=true
root.BackgroundColor3=Theme.bg
root.Size=UDim2.fromOffset(560,440)
root.Position=UDim2.new(0.5,-280,0.5,-220)
root.Parent=sg
corner(root,16); stroke(root,Theme.accA,1).Transparency=.7

-- title bar
local title=Instance.new("Frame")
title.BackgroundColor3=Theme.card
title.Size=UDim2.new(1,0,0,46)
title.Parent=root
corner(title,16); stroke(title,Theme.accB,1).Transparency=.8

local lbl=Instance.new("TextLabel")
lbl.BackgroundTransparency=1
lbl.Text="danuu eilish • Hub"
lbl.Font=Enum.Font.GothamBold; lbl.TextSize=16
lbl.TextColor3=Theme.text; lbl.TextXAlignment=Enum.TextXAlignment.Left
lbl.Size=UDim2.new(1,-120,1,0); lbl.Position=UDim2.fromOffset(14,0)
lbl.Parent=title

local btnRow=Instance.new("Frame")
btnRow.BackgroundTransparency=1
btnRow.Size=UDim2.fromOffset(96,36)
btnRow.Position=UDim2.new(1,-100,0.5,-18)
btnRow.Parent=title
local li=Instance.new("UIListLayout",btnRow); li.FillDirection=Enum.FillDirection.Horizontal; li.Padding=UDim.new(0,8); li.HorizontalAlignment=Enum.HorizontalAlignment.Right; li.VerticalAlignment=Enum.VerticalAlignment.Center

local function topBtn(txt, col)
  local b=Instance.new("TextButton")
  b.AutoButtonColor=false; b.Text=txt
  b.Font=Enum.Font.GothamBold; b.TextSize=16; b.TextColor3=Theme.text
  b.BackgroundColor3=col; b.Size=UDim2.fromOffset(36,36); b.Parent=btnRow
  corner(b,10); stroke(b,Color3.new(1,1,1),1).Transparency=.75
  b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.1),{BackgroundColor3=Theme.accA}):Play() end)
  b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.15),{BackgroundColor3=col}):Play() end)
  return b
end

local btnMin   = topBtn("–", Theme.bg)
local btnClose = topBtn("✕", Theme.bad)

-- dragging
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

-- tabs bar
local tabsBar=Instance.new("Frame")
tabsBar.BackgroundColor3=Theme.bg
tabsBar.Size=UDim2.new(1,-16,0,40)
tabsBar.Position=UDim2.fromOffset(8,54)
tabsBar.Parent=root
corner(tabsBar,10); stroke(tabsBar,Theme.accA,1).Transparency=.85; pad(tabsBar,6)
local tabsList=Instance.new("UIListLayout",tabsBar); tabsList.FillDirection=Enum.FillDirection.Horizontal; tabsList.Padding=UDim.new(0,8)

-- tab pages container
local pages = Instance.new("Frame")
pages.BackgroundTransparency=1
pages.Size=UDim2.new(1,-16,1,-106)
pages.Position=UDim2.fromOffset(8,100)
pages.Parent=root

-- bubble (minimize)
local bubble=Instance.new("Frame")
bubble.Visible=false
bubble.Size=UDim2.fromOffset(56,56)
bubble.BackgroundColor3=Theme.accA
bubble.Parent=sg
corner(bubble,28); stroke(bubble,Theme.accB,2).Transparency=.2
local bTxt=Instance.new("TextLabel"); bTxt.BackgroundTransparency=1; bTxt.Size=UDim2.fromScale(1,1)
bTxt.Font=Enum.Font.GothamBlack; bTxt.Text="DE"; bTxt.TextSize=20; bTxt.TextColor3=Theme.text; bTxt.Parent=bubble
local function placeBubble()
  local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
  bubble.Position = UDim2.fromOffset(vs.X-66, 20)
end
placeBubble()
if workspace.CurrentCamera then
  workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeBubble)
end
-- drag bubble
do
  local dragging=false; local start; local startPos
  bubble.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
      dragging=true; start=i.Position; startPos=bubble.Position
      i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
      local d=i.Position-start
      bubble.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
  end)
end
btnMin.MouseButton1Click:Connect(function()
  bubble.Visible=true
  Tween:Create(root,TweenInfo.new(.15),{BackgroundTransparency=1}):Play()
  Tween:Create(root,TweenInfo.new(.18),{Size=UDim2.fromOffset(260,80)}):Play()
  task.delay(.18,function() root.Visible=false end)
end)
bubble.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
    root.Visible=true; bubble.Visible=false
    Tween:Create(root,TweenInfo.new(.18),{BackgroundTransparency=0}):Play()
    Tween:Create(root,TweenInfo.new(.20),{Size=UDim2.fromOffset(560,440)}):Play()
  end
end)
btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)

-- toast
local function Toast(msg, color)
  local t=Instance.new("TextLabel")
  t.BackgroundColor3 = color or Theme.accA
  t.TextColor3 = Theme.text
  t.Font=Enum.Font.GothamSemibold; t.TextSize=14
  t.TextWrapped=true; t.Text=msg
  t.AutomaticSize = Enum.AutomaticSize.XY
  t.Position=UDim2.new(1,-10,1,-10)
  t.AnchorPoint=Vector2.new(1,1)
  t.Parent=root
  pad(t,10); corner(t,10); stroke(t,Color3.new(1,1,1),1).Transparency=.6
  Tween:Create(t,TweenInfo.new(.15),{BackgroundTransparency=0.05}):Play()
  task.delay(2.2,function()
    Tween:Create(t,TweenInfo.new(.2),{BackgroundTransparency=1, TextTransparency=1}):Play()
    task.delay(.22,function() t:Destroy() end)
  end)
end

-- page builder helpers
local ActiveTabButton
local function makeTabButton(name, onClick)
  local b=Instance.new("TextButton")
  b.Size=UDim2.fromOffset(100,28)
  b.Text=name
  b.AutoButtonColor=false
  b.BackgroundColor3=Theme.card
  b.TextColor3=Theme.text
  b.Font=Enum.Font.GothamSemibold; b.TextSize=14
  b.Parent=tabsBar
  corner(b,8); stroke(b,Theme.accA,1).Transparency=.6
  b.MouseEnter:Connect(function() if b~=ActiveTabButton then Tween:Create(b,TweenInfo.new(.1),{BackgroundColor3=Theme.accB}):Play() end end)
  b.MouseLeave:Connect(function() if b~=ActiveTabButton then Tween:Create(b,TweenInfo.new(.15),{BackgroundColor3=Theme.card}):Play() end end)
  b.MouseButton1Click:Connect(onClick)
  return b
end

local function createScrollPage()
  local sf=Instance.new("ScrollingFrame")
  sf.Visible=false
  sf.BackgroundColor3=Theme.bg
  sf.BorderSizePixel=0
  sf.ScrollBarThickness=6
  sf.Size=UDim2.fromScale(1,1)
  sf.Parent=pages
  corner(sf,12); pad(sf,10); stroke(sf,Theme.accA,1).Transparency=.85
  local list=Instance.new("UIListLayout",sf); list.FillDirection=Enum.FillDirection.Vertical; list.Padding=UDim.new(0,10)
  list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sf.CanvasSize=UDim2.new(0,0,0,list.AbsoluteContentSize.Y+10)
  end)
  return sf
end

-- Section API
local function Section(parent, titleText)
  local container=Instance.new("Frame")
  container.BackgroundColor3=Theme.card
  container.Size=UDim2.new(1,0,0,60)
  container.Parent=parent
  corner(container,12); stroke(container,Theme.accA,1).Transparency=.6

  local head=Instance.new("TextLabel")
  head.BackgroundTransparency=1
  head.Text="  "..(titleText or "Section")
  head.Font=Enum.Font.GothamBlack; head.TextSize=18; head.TextColor3=Theme.text; head.TextXAlignment=Enum.TextXAlignment.Left
  head.Size=UDim2.new(1,-8,0,28); head.Position=UDim2.fromOffset(8,6); head.Parent=container

  local inner=Instance.new("Frame")
  inner.BackgroundTransparency=1
  inner.Size=UDim2.new(1,-16,0,0)
  inner.Position=UDim2.fromOffset(8,36)
  inner.Parent=container
  local v=Instance.new("UIListLayout", inner); v.Padding=UDim.new(0,8)

  local function resize()
    container.Size=UDim2.new(1,0,0, math.max(60, 40 + v.AbsoluteContentSize.Y))
    inner.Size=UDim2.new(1,-16,0, v.AbsoluteContentSize.Y)
  end
  v:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
  task.defer(resize)

  local api = {}
  function api:Label(text)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextColor3=Theme.text; l.Font=Enum.Font.Gotham; l.TextSize=14; l.TextWrapped=true
    l.Text=tostring(text or ""); l.AutomaticSize=Enum.AutomaticSize.Y; l.Size=UDim2.new(1,0,0,0); l.Parent=inner
    return l
  end
  function api:Hint(text)
    local l=self:Label(text)
    l.TextColor3=Theme.dim
    return l
  end
  function api:Button(text, callback)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,34)
    b.Text=text; b.Font=Enum.Font.GothamSemibold; b.TextSize=14; b.TextColor3=Theme.text
    b.BackgroundColor3=Theme.accA; b.AutoButtonColor=false
    b.Parent=inner; corner(b,8); stroke(b,Theme.accB,1).Transparency=.35
    b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.1),{BackgroundColor3=Theme.accB}):Play() end)
    b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.15),{BackgroundColor3=Theme.accA}):Play() end)
    b.MouseButton1Click:Connect(function() if callback then callback() end end)
    return b
  end
  function api:Textbox(placeholder, default, onCommit)
    local tb=Instance.new("TextBox")
    tb.Size=UDim2.new(1,0,0,34)
    tb.BackgroundColor3=Theme.card
    tb.PlaceholderText=placeholder or ""
    tb.PlaceholderColor3=Theme.dim
    tb.TextColor3=Theme.text
    tb.ClearTextOnFocus=false
    tb.Text=tostring(default or "")
    tb.Font=Enum.Font.Gotham; tb.TextSize=14
    tb.Parent=inner; corner(tb,8); stroke(tb,Theme.accA,1).Transparency=.5
    tb.FocusLost:Connect(function() if onCommit then onCommit(tb.Text) end end)
    return tb
  end
  function api:Spacer(px)
    local sp=Instance.new("Frame"); sp.BackgroundTransparency=1; sp.Size=UDim2.new(1,0,0,px or 8); sp.Parent=inner; return sp
  end

  return api, container
end

-- Collapsible Section
local function Collapsible(parent, titleText)
  local sec, cont = Section(parent, titleText)
  local toggle = Instance.new("TextButton")
  toggle.Text = "▼"
  toggle.Font=Enum.Font.GothamBold
  toggle.TextSize=14
  toggle.TextColor3=Theme.text
  toggle.BackgroundTransparency=1
  toggle.Size=UDim2.fromOffset(28,28)
  toggle.Position=UDim2.new(1,-34,0,4)
  toggle.Parent=cont

  local visible = true
  local contentFrame = cont:FindFirstChildOfClass("Frame")
  local function set(v)
    visible=v; toggle.Text = v and "▼" or "▲"
    contentFrame.Visible = v
  end
  toggle.MouseButton1Click:Connect(function() set(not visible) end)

  sec.Toggle = set
  return sec
end

-- Tab API
local Tabs = {}
local function Tab(name)
  local page = createScrollPage()
  local btn  = makeTabButton(name, function()
    for _,t in ipairs(Tabs) do
      t.page.Visible=false
      if t.btn==ActiveTabButton then
        Tween:Create(t.btn,TweenInfo.new(.12),{BackgroundColor3=Theme.card}):Play()
      end
    end
    page.Visible=true
    ActiveTabButton = btn
    Tween:Create(btn,TweenInfo.new(.12),{BackgroundColor3=Theme.accA}):Play()
  end)

  local api={}
  function api:Section(title) return Section(page, title) end
  function api:Collapsible(title) return Collapsible(page, title) end
  function api:Label(text) local s=Section(page, name); return s:Label(text) end

  table.insert(Tabs, {btn=btn,page=page})
  if #Tabs==1 then btn:Activate() end
  return api
end

-- public API
function UI.new(windowTitle)
  lbl.Text = windowTitle or lbl.Text
  local api={}
  function api:Tab(name) return Tab(name) end
  function api:Toast(msg, color) Toast(msg, color) end
  return api
end
function UI:Toast(msg, color) return Toast(msg, color) end

return UI

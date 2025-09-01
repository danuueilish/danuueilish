-- src/mount_manual.lua  • simple, kecil, rapi
local UI = _G.danuu_hub_ui
if not UI then return end
local sec = (UI.MountSections and UI.MountSections["Manual"]) or UI.NewSection(UI.Tabs.Mount, "Manual")

-- ==== services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- ==== theme mini
local T = {
  bg  = Color3.fromRGB(24,20,40),
  card= Color3.fromRGB(44,36,72),
  text= Color3.fromRGB(235,230,255),
  acc = Color3.fromRGB(125,84,255),
  bad = Color3.fromRGB(255,95,95),
}
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p end
local function stroke(p,th) local s=Instance.new("UIStroke"); s.Thickness=th or 1; s.Transparency=.5; s.Parent=p end
local function HRP() local ch=LP.Character or LP.CharacterAdded:Wait() return ch:FindFirstChild("HumanoidRootPart") end
local function Hum() local ch=LP.Character or LP.CharacterAdded:Wait() return ch:FindFirstChildOfClass("Humanoid") end

-- ==== persist helpers
local CAN_FS = (writefile and readfile and isfile)
local function jenc(x) return HttpService:JSONEncode(x) end
local function jdec(s) local ok,t=pcall(function() return HttpService:JSONDecode(s) end) return ok and t or nil end
local function readf(p,def) if not CAN_FS or not isfile(p) then return def end local ok,d=pcall(function() return readfile(p) end) return ok and d or def end
local function writef(p,c) if CAN_FS then pcall(function() writefile(p,c) end) end

-- ==== settings (kecil)
local SETTINGS_FILE="danuu_manual_settings.json"
local Settings = {
  loopDelay=3, autoLoop=false,
  autoKill=false, moveDance=true,
  autoRJ=false, autoRJDelay=5,
}
do local t=jdec(readf(SETTINGS_FILE,"")) if typeof(t)=="table" then for k,v in pairs(t) do Settings[k]=v end end end
local function save() writef(SETTINGS_FILE, jenc(Settings)) end

-- ==== layout helpers
local function Row(h)
  local r=Instance.new("Frame"); r.BackgroundColor3=T.card; r.Size=UDim2.new(1,-6,0,h or 34); r.Position=UDim2.fromOffset(3,0)
  r.Parent=sec; corner(r,8); stroke(r,1)
  local pad=Instance.new("UIPadding",r); pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8); pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)
  local l=Instance.new("UIListLayout",r); l.FillDirection=Enum.FillDirection.Horizontal; l.Padding=UDim.new(0,6)
  return r
end
local function Tag(parent,txt,w)
  local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.TextColor3=T.text; t.Font=Enum.Font.GothamSemibold
  t.TextSize=12; t.Text=txt; t.Size=UDim2.new(0,w or 110,1,0); t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=parent; return t
end
local function Btn(parent,txt,w)
  local b=Instance.new("TextButton"); b.AutoButtonColor=false; b.Text=txt; b.Font=Enum.Font.GothamSemibold; b.TextSize=12; b.TextColor3=T.text
  b.BackgroundColor3=T.acc; b.Size=UDim2.new(0,w or 110,1,0); b.Parent=parent; corner(b,6); stroke(b,1); return b
end
local function Box(parent,txt,w)
  local x=Instance.new("TextBox"); x.ClearTextOnFocus=false; x.Text=txt or ""; x.Font=Enum.Font.Gotham; x.TextSize=12; x.TextColor3=T.text
  x.BackgroundColor3=T.card; x.Size=UDim2.new(0,w or 60,1,0); x.TextXAlignment=Enum.TextXAlignment.Center; x.Parent=parent; corner(x,6); stroke(x,1); return x
end

-- ==== WAYPOINTS (kecil)
local WP_FILE=("danuu_manual_wp_%s.json"):format(tostring(game.PlaceId))
local waypoints={}
local function loadWP() local d=jdec(readf(WP_FILE,"")) or {}; waypoints={} for _,v in ipairs(d) do table.insert(waypoints, Vector3.new(v.x,v.y,v.z)) end end
local function saveWP() local t={} for _,v in ipairs(waypoints) do t[#t+1]={x=v.X,y=v.Y,z=v.Z} end writef(WP_FILE, jenc(t)) end
loadWP()

-- daftar compact (tinggi 110)
do
  local card=Instance.new("Frame"); card.BackgroundColor3=T.card; card.Size=UDim2.new(1,-6,0,110); card.Position=UDim2.fromOffset(3,0); card.Parent=sec
  corner(card,8); stroke(card,1)
  local pad=Instance.new("UIPadding",card); pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8); pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)
  local sc=Instance.new("ScrollingFrame",card); sc.BackgroundTransparency=1; sc.Size=UDim2.fromScale(1,1); sc.ScrollBarThickness=5; sc.CanvasSize=UDim2.new()
  local ll=Instance.new("UIListLayout",sc); ll.Padding=UDim.new(0,6)
  local function refresh()
    for _,c in ipairs(sc:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for i,pos in ipairs(waypoints) do
      local row=Instance.new("Frame"); row.BackgroundColor3=T.bg; row.Size=UDim2.new(1,0,0,28); row.Parent=sc; corner(row,6); stroke(row,1)
      local li=Instance.new("UIListLayout",row); li.FillDirection=Enum.FillDirection.Horizontal; li.Padding=UDim.new(0,6)
      local name=Tag(row, string.format("Camp %d (%.0f, %.0f, %.0f)", i,pos.X,pos.Y,pos.Z), 190)
      local tp=Btn(row,"TP",44); tp.MouseButton1Click:Connect(function() local h=HRP(); if h then h.CFrame=CFrame.new(pos) end end)
      local del=Btn(row,"✕",32); del.BackgroundColor3=T.bad; del.MouseButton1Click:Connect(function() table.remove(waypoints,i) refresh() saveWP() end)
    end
    sc.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+4)
  end
  refresh()

  -- row kontrol WP
  local r=Row(32); Tag(r,"List Waypoints",120)
  local add=Btn(r,"Set Waypoint",120)
  local rem=Btn(r,"Delete Last",118)
  add.MouseButton1Click:Connect(function()
    local h=HRP(); if not h then return end
    table.insert(waypoints, h.Position); saveWP(); refresh()
  end)
  rem.MouseButton1Click:Connect(function()
    if #waypoints>0 then table.remove(waypoints,#waypoints) saveWP() refresh() end
  end)
end

-- ==== DELAY + KILL
local delayRow=Row(32); Tag(delayRow,"Delay (s)",90)
local delayBox=Box(delayRow, tostring(Settings.loopDelay or 3), 50)
delayBox.FocusLost:Connect(function()
  local v=tonumber(delayBox.Text) or Settings.loopDelay
  v=math.clamp(math.floor(v+0.5),1,60); Settings.loopDelay=v; delayBox.Text=tostring(v); save()
end)
local killBtn=Btn(delayRow, "Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF"), 170)
killBtn.MouseButton1Click:Connect(function()
  Settings.autoKill = not Settings.autoKill
  killBtn.Text="Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF"); save()
end)

-- ==== MOVE + AUTO REJOIN (ADA delay box)
local optRow=Row(32); Tag(optRow,"Opsi",90)
local danceBtn=Btn(optRow,"3x/8stud: "..(Settings.moveDance and "ON" or "OFF"), 110)
danceBtn.MouseButton1Click:Connect(function()
  Settings.moveDance = not Settings.moveDance
  danceBtn.Text="3x/8stud: "..(Settings.moveDance and "ON" or "OFF"); save()
end)
local rjBtn=Btn(optRow,"Auto RJ: "..(Settings.autoRJ and "ON" or "OFF"), 110)
local rjBox=Box(optRow, tostring(Settings.autoRJDelay or 5), 48)

-- RJ logic
local PlaceId, JobId = game.PlaceId, game.JobId
local rjLoop=false; local rjConn
local function doRJ()
  if #Players:GetPlayers() <= 1 then LP:Kick("\nRejoining...") task.wait() TeleportService:Teleport(PlaceId, LP)
  else TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LP) end
end
local function startRJ()
  if rjConn then rjConn:Disconnect() end
  rjConn = GuiService.ErrorMessageChanged:Connect(function() doRJ() end)
  rjLoop=true
  task.spawn(function()
    while rjLoop do
      local d=tonumber(rjBox.Text) or Settings.autoRJDelay or 5
      d=math.clamp(math.floor(d+0.5),2,120)
      for _=1,d*10 do if not rjLoop then break end task.wait(0.1) end
      if not rjLoop then break end
      doRJ()
    end
  end)
end
local function stopRJ() rjLoop=false if rjConn then rjConn:Disconnect() rjConn=nil end end
rjBtn.MouseButton1Click:Connect(function()
  Settings.autoRJ = not Settings.autoRJ
  rjBtn.Text="Auto RJ: "..(Settings.autoRJ and "ON" or "OFF"); save()
  if Settings.autoRJ then startRJ() else stopRJ() end
end)
rjBox.FocusLost:Connect(function()
  local v=tonumber(rjBox.Text) or Settings.autoRJDelay
  v=math.clamp(math.floor(v+0.5),2,120); Settings.autoRJDelay=v; rjBox.Text=tostring(v); save()
end)
if Settings.autoRJ then startRJ() end

-- ==== AUTO LOOP (kecil)
local loopRow=Row(32); Tag(loopRow,"Auto Loop",90)
local loopBtn=Btn(loopRow,"Auto loop: "..(Settings.autoLoop and "ON" or "OFF"), 120)

-- gerak searah 3x/8 stud
local function dance(center)
  if not Settings.moveDance then return end
  local hrp=HRP(); if not hrp then return end
  local dir=workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or hrp.CFrame.LookVector
  dir=Vector3.new(dir.X,0,dir.Z) if dir.Magnitude<0.1 then dir=Vector3.new(1,0,0) end dir=dir.Unit
  local R=8
  for _=1,3 do
    hrp.CFrame=CFrame.new(center)+dir*R; task.wait(0.1)
    hrp.CFrame=CFrame.new(center)-dir*R; task.wait(0.1)
    hrp.CFrame=CFrame.new(center); task.wait(0.1)
  end
end

local looping=false
local function setLoop(on)
  Settings.autoLoop=on and true or false
  loopBtn.Text="Auto loop: "..(Settings.autoLoop and "ON" or "OFF"); save()
  if Settings.autoLoop and not looping then
    looping=true
    task.spawn(function()
      while Settings.autoLoop do
        if #waypoints==0 then task.wait(0.15) else
          local d=tonumber(delayBox.Text) or Settings.loopDelay or 3
          d=math.clamp(math.floor(d+0.5),1,60)
          for i,pos in ipairs(waypoints) do
            if not Settings.autoLoop then break end
            local h=HRP(); if h then h.CFrame=CFrame.new(pos) end
            dance(pos)
            local t0=tick() while Settings.autoLoop and tick()-t0<d do task.wait(0.05) end
            if Settings.autoLoop and i==#waypoints and Settings.autoKill then
              local hum=Hum(); if hum then hum.Health=0 end
              LP.CharacterAdded:Wait(); task.wait(0.6)
            end
          end
        end
        task.wait(0.05)
      end
      looping=false
    end)
  end
end
loopBtn.MouseButton1Click:Connect(function() setLoop(not Settings.autoLoop) end)

-- apply persisted
delayBox.Text=tostring(Settings.loopDelay or 3)
rjBox.Text=tostring(Settings.autoRJDelay or 5)
if Settings.autoLoop then setLoop(true) end

print("[manual] ready")

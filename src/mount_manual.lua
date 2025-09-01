-- src/mount_manual.lua
-- Manual: Waypoints + Auto Loop + 3x/8stud + Auto Respawn + Auto Rejoin (compact, fixed LayoutOrder)

------------------ container ------------------
local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Manual"] then
    warn("[Manual] container 'Manual' tidak ditemukan.")
    return
end
local sec = UI.MountSections["Manual"]  -- inner frame dari kartu "Manual"

------------------ services & tiny utils ------------------
local Players, GuiService, TeleportService, HttpService =
      game:GetService("Players"), game:GetService("GuiService"),
      game:GetService("TeleportService"), game:GetService("HttpService")
local LP = Players.LocalPlayer

local Theme = {
  bg=Color3.fromRGB(24,20,40), card=Color3.fromRGB(44,36,72),
  text=Color3.fromRGB(235,230,255), text2=Color3.fromRGB(190,180,220),
  accA=Color3.fromRGB(125,84,255), accB=Color3.fromRGB(215,55,255),
  good=Color3.fromRGB(106,212,123), bad=Color3.fromRGB(255,95,95),
}
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Color3.new(1,1,1); s.Thickness=t or 1; s.Transparency=.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function HRP() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChild("HumanoidRootPart") end
local function Hum() local ch=LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChildOfClass("Humanoid") end

-- file helpers
local CAN_FS = (writefile and readfile and isfile) and true or false
local function safe_read(p,f) if not CAN_FS or not isfile(p) then return f end local ok,d=pcall(readfile,p) return ok and d or f end
local function safe_write(p,c) if not CAN_FS then return false end pcall(writefile,p,c) return true end
local function enc(t) return HttpService:JSONEncode(t) end
local function dec(s) local ok,r=pcall(function() return HttpService:JSONDecode(s) end) return ok and r or nil end

------------------ LayoutOrder helper ------------------
local _order = 0
local function nextOrder(gui) _order += 1; gui.LayoutOrder = _order end

------------------ SETTINGS (persist) ------------------
local SETTINGS_FILE = "danuu_manual_settings.json"
local Settings = { loopDelay=3, autoLoop=false, autoKill=false, moveDance=true, autoRJ=false, autoRJDelay=5 }
do local t=dec(safe_read(SETTINGS_FILE,"")); if typeof(t)=="table" then for k,v in pairs(t) do Settings[k]=v end end end
local function saveSettings() safe_write(SETTINGS_FILE, enc(Settings)) end

------------------ WAYPOINTS (persist per map) ------------------
local WP_FILE = ("danuu_manual_wp_%s.json"):format(tostring(game.PlaceId))
local waypoints = {}
local function saveWP() local t={}; for _,v in ipairs(waypoints) do t[#t+1]={x=v.X,y=v.Y,z=v.Z} end; safe_write(WP_FILE, enc(t)) end
local function loadWP() local d=dec(safe_read(WP_FILE,"")); waypoints={}; if typeof(d)=="table" then for _,v in ipairs(d) do if v.x and v.y and v.z then table.insert(waypoints, Vector3.new(v.x,v.y,v.z)) end end end end
loadWP()

local function dance(center)
  local hrp=HRP(); if not hrp then return end
  local dir=(workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or hrp.CFrame.LookVector)
  dir=Vector3.new(dir.X,0,dir.Z); if dir.Magnitude<0.1 then dir=Vector3.new(1,0,0) end; dir=dir.Unit
  for _=1,3 do
    hrp.CFrame=CFrame.new(center+dir*8); task.wait(0.1)
    hrp.CFrame=CFrame.new(center-dir*8); task.wait(0.1)
    hrp.CFrame=CFrame.new(center);       task.wait(0.1)
  end
end

------------------ ROW helper ------------------
local function newRow(h)
  local row=Instance.new("Frame")
  row.BackgroundColor3=Theme.card; row.Size=UDim2.new(1,-4,0,h or 36); row.Position=UDim2.fromOffset(2,0); row.Parent=sec
  nextOrder(row); corner(row,10); stroke(row,Theme.accA,1).Transparency=.55
  local pad=Instance.new("UIPadding",row); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10); pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)
  local left=Instance.new("TextLabel"); left.BackgroundTransparency=1; left.Size=UDim2.new(0,140,1,0); left.Font=Enum.Font.GothamSemibold; left.TextSize=14; left.TextXAlignment=Enum.TextXAlignment.Left; left.TextColor3=Theme.text; left.Parent=row
  local right=Instance.new("Frame"); right.BackgroundTransparency=1; right.Size=UDim2.new(1,-(140+20),1,0); right.Parent=row
  local rlay=Instance.new("UIListLayout",right); rlay.FillDirection=Enum.FillDirection.Horizontal; rlay.Padding=UDim.new(0,8); rlay.VerticalAlignment=Enum.VerticalAlignment.Center; rlay.HorizontalAlignment=Enum.HorizontalAlignment.Right
  return row,left,right
end

------------------ LIST WAYPOINTS (compact 96px) ------------------
do
  local title=Instance.new("TextLabel"); title.BackgroundTransparency=1; title.TextXAlignment=Enum.TextXAlignment.Left
  title.Text="List Waypoints"; title.Font=Enum.Font.GothamBlack; title.TextSize=15; title.TextColor3=Theme.text; title.Size=UDim2.new(1,0,0,20); title.Parent=sec
  nextOrder(title)

  local card=Instance.new("Frame"); card.BackgroundColor3=Theme.bg; card.Size=UDim2.new(1,-4,0,96); card.Position=UDim2.fromOffset(2,0); card.Parent=sec
  nextOrder(card); corner(card,10); stroke(card,Theme.accA,1).Transparency=.7
  local pad=Instance.new("UIPadding",card); pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8); pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)

  local sc=Instance.new("ScrollingFrame"); sc.BackgroundTransparency=1; sc.Size=UDim2.fromScale(1,1); sc.ScrollBarThickness=6; sc.CanvasSize=UDim2.new(0,0,0,0); sc.Parent=card
  local list=Instance.new("UIListLayout",sc); list.Padding=UDim.new(0,4)
  list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sc.CanvasSize=UDim2.new(0,0,0,list.AbsoluteContentSize.Y+6) end)

  local function refresh()
    for _,c in ipairs(sc:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for i,pos in ipairs(waypoints) do
      local row=Instance.new("Frame"); row.BackgroundColor3=Theme.card; row.Size=UDim2.new(1,0,0,24); row.Parent=sc
      corner(row,8); stroke(row,Theme.accA,1).Transparency=.65
      local name=Instance.new("TextLabel"); name.BackgroundTransparency=1; name.TextXAlignment=Enum.TextXAlignment.Left
      name.Text=string.format("Camp %d (%.0f,%.0f,%.0f)",i,pos.X,pos.Y,pos.Z); name.TextColor3=Theme.text; name.Font=Enum.Font.Gotham; name.TextSize=12
      name.Size=UDim2.new(1,-120,1,0); name.Position=UDim2.fromOffset(8,0); name.Parent=row

      local tp=Instance.new("TextButton"); tp.Text="TP"; tp.Font=Enum.Font.GothamSemibold; tp.TextSize=12; tp.TextColor3=Theme.text
      tp.Size=UDim2.new(0,36,1,0); tp.Position=UDim2.new(1,-80,0,0); tp.BackgroundColor3=Theme.accA; tp.AutoButtonColor=false; corner(tp,8); stroke(tp,Theme.accB,1).Transparency=.35; tp.Parent=row
      tp.MouseButton1Click:Connect(function() local h=HRP(); if h then h.CFrame=CFrame.new(pos) end; if Settings.moveDance then dance(pos) end end)

      local del=Instance.new("TextButton"); del.Text="✕"; del.Font=Enum.Font.GothamBold; del.TextSize=12; del.TextColor3=Theme.text
      del.Size=UDim2.new(0,32,1,0); del.Position=UDim2.new(1,-40,0,0); del.BackgroundColor3=Theme.bad; del.AutoButtonColor=false; corner(del,8); stroke(del,Color3.new(1,1,1),1).Transparency=.75; del.Parent=row
      del.MouseButton1Click:Connect(function() table.remove(waypoints,i); refresh(); saveWP() end)
    end
  end
  sec._refreshWP = refresh

  local _, l1, r1 = newRow(34); l1.Text="Waypoints"
  local btnSet=Instance.new("TextButton"); btnSet.Size=UDim2.new(0,140,1,0); btnSet.Text="Set Waypoint"; btnSet.Font=Enum.Font.GothamSemibold; btnSet.TextSize=13; btnSet.TextColor3=Theme.text
  btnSet.BackgroundColor3=Theme.accA; btnSet.AutoButtonColor=false; corner(btnSet,8); stroke(btnSet,Theme.accB,1).Transparency=.35; btnSet.Parent=r1
  local btnDel=Instance.new("TextButton"); btnDel.Size=UDim2.new(0,120,1,0); btnDel.Text="Delete Last"; btnDel.Font=Enum.Font.GothamSemibold; btnDel.TextSize=13; btnDel.TextColor3=Theme.text
  btnDel.BackgroundColor3=Theme.card; btnDel.AutoButtonColor=false; corner(btnDel,8); stroke(btnDel,Theme.accA,1).Transparency=.5; btnDel.Parent=r1

  local lastPos,lastT
  local function okInsert(p) if not lastPos then return true end; if (p-lastPos).Magnitude>=2 then return true end; return (tick()-(lastT or 0))>0.25 end
  btnSet.MouseButton1Click:Connect(function() local h=HRP(); if not h then return end; local p=h.Position; if okInsert(p) then table.insert(waypoints,p); lastPos,lastT=p,tick(); refresh(); saveWP() end end)
  btnDel.MouseButton1Click:Connect(function() if #waypoints>0 then table.remove(waypoints,#waypoints); refresh(); saveWP() end end)

  refresh()
end

------------------ Delay + Kill ------------------
local _, dL, dR = newRow(36); dL.Text="Delay"
local delayBox=Instance.new("TextBox"); delayBox.Size=UDim2.new(0,120,1,0); delayBox.BackgroundColor3=Theme.card; delayBox.TextColor3=Theme.text
delayBox.Font=Enum.Font.Gotham; delayBox.TextSize=13; delayBox.ClearTextOnFocus=false; delayBox.Text=tostring(Settings.loopDelay or 3); delayBox.TextXAlignment=Enum.TextXAlignment.Center
corner(delayBox,8); stroke(delayBox,Theme.accA,1).Transparency=.5; delayBox.Parent=dR
delayBox.FocusLost:Connect(function() local v=tonumber(delayBox.Text) or Settings.loopDelay; v=math.clamp(math.floor(v+0.5),1,60); Settings.loopDelay=v; delayBox.Text=tostring(v); saveSettings() end)

local killBtn=Instance.new("TextButton"); killBtn.Size=UDim2.new(0,160,1,0); killBtn.AutoButtonColor=false
killBtn.Text="Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF"); killBtn.Font=Enum.Font.GothamSemibold; killBtn.TextSize=13; killBtn.TextColor3=Theme.text
killBtn.BackgroundColor3=Settings.autoKill and Theme.accA or Theme.card; corner(killBtn,8); stroke(killBtn,Theme.accA,1).Transparency=.45; killBtn.Parent=dR
killBtn.MouseButton1Click:Connect(function() Settings.autoKill=not Settings.autoKill; killBtn.Text="Auto respawn/kill: "..(Settings.autoKill and "ON" or "OFF"); killBtn.BackgroundColor3=Settings.autoKill and Theme.accA or Theme.card; saveSettings() end)

------------------ Opsi: Dance + RJ ------------------
local _, gL, gR = newRow(36); gL.Text="Opsi"
local danceBtn=Instance.new("TextButton"); danceBtn.Size=UDim2.new(0,160,1,0); danceBtn.AutoButtonColor=false
danceBtn.Text="Gerak 3x/8stud: "..(Settings.moveDance and "ON" or "OFF"); danceBtn.Font=Enum.Font.GothamSemibold; danceBtn.TextSize=13; danceBtn.TextColor3=Theme.text
danceBtn.BackgroundColor3=Settings.moveDance and Theme.accA or Theme.card; corner(danceBtn,8); stroke(danceBtn,Theme.accA,1).Transparency=.45; danceBtn.Parent=gR
danceBtn.MouseButton1Click:Connect(function() Settings.moveDance=not Settings.moveDance; danceBtn.Text="Gerak 3x/8stud: "..(Settings.moveDance and "ON" or "OFF"); danceBtn.BackgroundColor3=Settings.moveDance and Theme.accA or Theme.card; saveSettings() end)

local rjBtn=Instance.new("TextButton"); rjBtn.Size=UDim2.new(0,140,1,0); rjBtn.AutoButtonColor=false
rjBtn.Text="Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF"); rjBtn.Font=Enum.Font.GothamSemibold; rjBtn.TextSize=13; rjBtn.TextColor3=Theme.text
rjBtn.BackgroundColor3=Settings.autoRJ and Theme.accA or Theme.card; corner(rjBtn,8); stroke(rjBtn,Theme.accA,1).Transparency=.45; rjBtn.Parent=gR

local rjBox=Instance.new("TextBox"); rjBox.Size=UDim2.new(0,120,1,0); rjBox.BackgroundColor3=Theme.card; rjBox.TextColor3=Theme.text
rjBox.Font=Enum.Font.Gotham; rjBox.TextSize=13; rjBox.ClearTextOnFocus=false; rjBox.Text=tostring(Settings.autoRJDelay or 5); rjBox.TextXAlignment=Enum.TextXAlignment.Center
corner(rjBox,8); stroke(rjBox,Theme.accA,1).Transparency=.5; rjBox.Parent=gR
rjBox.FocusLost:Connect(function() local v=tonumber(rjBox.Text) or Settings.autoRJDelay; v=math.clamp(math.floor(v+0.5),2,120); Settings.autoRJDelay=v; rjBox.Text=tostring(v); saveSettings() end)

local PlaceId, JobId = game.PlaceId, game.JobId
local rjLoopOn, rjConn = false, nil
local function doRJ()
  if #Players:GetPlayers()<=1 then LP:Kick("\nRejoining..."); task.wait(); TeleportService:Teleport(PlaceId,LP)
  else TeleportService:TeleportToPlaceInstance(PlaceId,JobId,LP) end
end
local function startRJ()
  if rjConn then rjConn:Disconnect() end
  rjConn = GuiService.ErrorMessageChanged:Connect(function() doRJ() end)
  rjLoopOn = true
  task.spawn(function()
    while rjLoopOn do
      local d = math.clamp(math.floor(((tonumber(rjBox.Text) or Settings.autoRJDelay))+0.5),2,120)
      for _=1,d*10 do if not rjLoopOn then break end; task.wait(0.1) end
      if not rjLoopOn then break end
      doRJ()
    end
  end)
end
local function stopRJ() rjLoopOn=false; if rjConn then rjConn:Disconnect(); rjConn=nil end end
rjBtn.MouseButton1Click:Connect(function()
  Settings.autoRJ=not Settings.autoRJ
  rjBtn.Text="Auto rejoin: "..(Settings.autoRJ and "ON" or "OFF")
  rjBtn.BackgroundColor3=Settings.autoRJ and Theme.accA or Theme.card
  saveSettings()
  if Settings.autoRJ then startRJ() else stopRJ() end
end)
if Settings.autoRJ then startRJ() end

------------------ Auto Loop ------------------
local _, aL, aR = newRow(36); aL.Text="Auto loop"
local loopBtn=Instance.new("TextButton"); loopBtn.Size=UDim2.new(0,150,1,0); loopBtn.AutoButtonColor=false
loopBtn.Text="Auto loop: "..(Settings.autoLoop and "ON" or "OFF"); loopBtn.Font=Enum.Font.GothamSemibold; loopBtn.TextSize=13; loopBtn.TextColor3=Theme.text
loopBtn.BackgroundColor3=Settings.autoLoop and Theme.accA or Theme.card; corner(loopBtn,8); stroke(loopBtn,Theme.accA,1).Transparency=.45; loopBtn.Parent=aR

local looping=false
local function setLoop(on)
  Settings.autoLoop = on and true or false
  loopBtn.Text = "Auto loop: "..(Settings.autoLoop and "ON" or "OFF")
  loopBtn.BackgroundColor3 = Settings.autoLoop and Theme.accA or Theme.card
  saveSettings()

  if Settings.autoLoop and not looping then
    looping=true
    task.spawn(function()
      while Settings.autoLoop do
        if #waypoints==0 then
          task.wait(0.15)
        else
          local d = math.clamp(math.floor(((tonumber(delayBox.Text) or Settings.loopDelay))+0.5),1,60)
          for i=1,#waypoints do
            if not Settings.autoLoop then break end
            local pos=waypoints[i]; local h=HRP(); if h then h.CFrame=CFrame.new(pos) end
            if Settings.moveDance then dance(pos) end
            local t0=tick(); while Settings.autoLoop and (tick()-t0<d) do task.wait(0.05) end
            if Settings.autoLoop and i==#waypoints and Settings.autoKill then
              local hum=Hum(); if hum then hum.Health=0 end
              LP.CharacterAdded:Wait(); task.wait(0.8)
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

-- sinkron nilai textboxes
delayBox.Text = tostring(Settings.loopDelay or 3)
rjBox.Text    = tostring(Settings.autoRJDelay or 5)
if Settings.autoLoop then setLoop(true) end

print("[danuu • Manual] loaded ✓")

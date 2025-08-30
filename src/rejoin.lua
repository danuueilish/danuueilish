local UI = _G.danuu_hub_ui; if not UI then return end
local sec = UI.NewSection(UI.Tabs.Utility, "Quick Actions")

local function mkButton(text, cb)
  local b=Instance.new("TextButton")
  b.Size=UDim2.new(1,0,0,34)
  b.Text=text; b.Font=Enum.Font.GothamSemibold; b.TextSize=14; b.TextColor3=Color3.new(1,1,1)
  b.BackgroundColor3=Color3.fromRGB(125,84,255); b.AutoButtonColor=false
  b.Parent=sec
  local u=Instance.new("UICorner",b); u.CornerRadius=UDim.new(0,8)
  b.MouseButton1Click:Connect(cb)
end

mkButton("Rejoin", function()
  local TS = game:GetService("TeleportService")
  local Players = game:GetService("Players")
  local PlaceId = game.PlaceId
  local JobId   = game.JobId
  if #Players:GetPlayers() <= 1 then
    Players.LocalPlayer:Kick("\nRejoining...")
    task.wait()
    TS:Teleport(PlaceId, Players.LocalPlayer)
  else
    TS:TeleportToPlaceInstance(PlaceId, JobId, Players.LocalPlayer)
  end
end)

mkButton("Server Hop", function()
  local TS = game:GetService("TeleportService")
  TS:Teleport(game.PlaceId)
end)

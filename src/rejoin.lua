-- rejoin.lua
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

local function rejoin()
  local placeId = game.PlaceId
  local jobId   = game.JobId
  if #Players:GetPlayers() <= 1 then
    LP:Kick("\nRejoining...")
    task.wait()
    TeleportService:Teleport(placeId, LP)
  else
    TeleportService:TeleportToPlaceInstance(placeId, jobId, LP)
  end
end

local autoOn = false
local autoConn

local M = {}
function M.mount(tab)
  local s = tab:Section("Rejoin")

  s:Label("• Rejoin: teleport kembali ke server saat ini.")
  s:Button("Rejoin Now", function() rejoin() end)

  local s2 = tab:Section("Auto-Rejoin (Disconnect Watch)")
  s2:Label("• Jika muncul error prompt (disconnect/shutdown), otomatis rejoin.")
  s2:Button("Toggle Auto-Rejoin", function()
    autoOn = not autoOn
    if autoOn then
      if autoConn then autoConn:Disconnect() end
      autoConn = CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name=="ErrorPrompt" then
          task.wait(0.5)
          rejoin()
        end
      end)
      game:GetService("StarterGui"):SetCore("SendNotification", {Title="Auto-Rejoin", Text="ON", Duration=2})
    else
      if autoConn then autoConn:Disconnect(); autoConn=nil end
      game:GetService("StarterGui"):SetCore("SendNotification", {Title="Auto-Rejoin", Text="OFF", Duration=2})
    end
  end)
end

return M

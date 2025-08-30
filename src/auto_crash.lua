-- auto_crash.lua
-- Placeholder auto crash/exit sinkron dengan loop (akan diisi belakangan).
local Players = game:GetService("Players")
local M = {}
function M.mount(tab)
  local s = tab:Section("Auto Crash (Placeholder)")
  s:Label("Nanti disinkron dengan auto loop (delay, trigger, dst).")
  s:Button("Test Kick", function()
    pcall(function() Players.LocalPlayer:Kick("Test AutoCrash") end)
  end)
end
return M

-- danuu eilish • Hub Loader
print("[danuu-hub] starting...")

local base = "https://raw.githubusercontent.com/danuueilish/danuueilish/main/src/"

-- UI framework utama
local UI = loadstring(game:HttpGet(base.."ui_main.lua"))()

-- Load fitur per file
pcall(function() loadstring(game:HttpGet(base.."home.lua"))() end)
pcall(function() loadstring(game:HttpGet(base.."auto_loop.lua"))() end)
pcall(function() loadstring(game:HttpGet(base.."auto_crash.lua"))() end)
pcall(function() loadstring(game:HttpGet(base.."sticky_notes.lua"))() end)
pcall(function() loadstring(game:HttpGet(base.."rejoin.lua"))() end)
pcall(function() loadstring(game:HttpGet(base.."antilag.lua"))() end)
pcall(function() loadstring(game:HttpGet(base.."mount_atin.lua"))() end)

print("[danuu-hub] semua modul sudah di-load ✓")

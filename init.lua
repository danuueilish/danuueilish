-- init.lua
-- Entry point script untuk danuu-hub
-- File ini akan require semua fitur yang ada di folder src

local features = {
    "src/ui_main",
    "src/auto_loop",
    "src/auto_crash",
    "src/sticky_notes",
    "src/rejoin",
    "src/antilag"
}

for _, f in ipairs(features) do
    local ok, mod = pcall(function() return require(f) end)
    if not ok then
        warn("[danuu-hub] Gagal load:", f, mod)
    else
        print("[danuu-hub] Loaded:", f)
    end
end

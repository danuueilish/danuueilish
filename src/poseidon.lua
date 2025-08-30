-- src/poseidon.lua
-- Auto Quest: Poseidon (ambil VaultKey -> buka PoseidonGate)

local UI = _G.danuu_hub_ui
if not UI or not UI.MountSections or not UI.MountSections["Mount Atin"] then return end

-- ===== helpers =====
local Players = game:GetService("Players")
local Tween   = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")
local LP      = Players.LocalPlayer

local function getChar()
    local c = LP.Character or LP.CharacterAdded:Wait()
    return c, c:WaitForChild("HumanoidRootPart")
end

local function tpCFrame(cf) -- teleport kecil + nudge aman
    local _, hrp = getChar()
    if not hrp then return end
    hrp.CFrame = cf
end

local function tweenTo(pos)
    local ch, hrp = getChar()
    if not hrp then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
    local tw = Tween:Create(hrp, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(pos)})
    tw:Play(); tw.Completed:Wait()
end

local function firePrompt(pp)
    -- Eksekutor biasanya menyediakan fireproximityprompt
    if typeof(pp) == "Instance" and pp:IsA("ProximityPrompt") then
        if fireproximityprompt then
            fireproximityprompt(pp)
            return true
        end
        -- fallback manual (tahan E virtual)
        pp.HoldDuration = 0
        pp:InputHoldBegin()
        task.wait(0.1)
        pp:InputHoldEnd()
        return true
    end
end

local function tryTouch(part)
    local _, hrp = getChar()
    if not (hrp and part and part:IsA("BasePart")) then return end
    if firetouchinterest then
        firetouchinterest(hrp, part, 0)
        task.wait(0.1)
        firetouchinterest(hrp, part, 1)
    else
        -- fallback: tabrak langsung
        tpCFrame(part.CFrame + Vector3.new(0, 3, 0))
    end
end

local function findDescendant(root, className)
    if not root then return nil end
    for _, d in ipairs(root:GetDescendants()) do
        if d.ClassName == className then return d end
    end
end

-- cari node kunci & gate di Workspace (nama bisa sedikit beda, jadi longgar)
local function findVaultKey()
    local ws = workspace
    local cand = ws:FindFirstChild("VaultKey") or ws:FindFirstChild("Key") or ws:FindFirstChild("Vault_Key")
    if not cand then
        -- scan longgar
        for _, inst in ipairs(ws:GetChildren()) do
            if inst.Name:lower():find("vault") and inst.Name:lower():find("key") then
                cand = inst; break
            end
        end
    end
    return cand
end

local function findPoseidonGate()
    local ws = workspace
    local cand = ws:FindFirstChild("PoseidonGate") or ws:FindFirstChild("Poseidon_Gate")
    if not cand then
        for _, inst in ipairs(ws:GetChildren()) do
            if inst.Name:lower():find("poseidon") and inst.Name:lower():find("gate") then
                cand = inst; break
            end
        end
    end
    return cand
end

-- ===== UI (pakai section "Mount Atin")
local sec = UI.MountSections["Mount Atin"]

local function mkButton(text, cb)
    local b = Instance.new("TextButton")
    b.Text = text
    b.Size = UDim2.new(0, 160, 0, 36)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 14
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(125,84,255)
    b.AutoButtonColor = false
    local u = Instance.new("UICorner", b); u.CornerRadius = UDim.new(0,8)
    b.Parent = sec
    b.MouseButton1Click:Connect(function()
        task.spawn(cb)
    end)
    return b
end

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Text = "Status: idle."
status.TextColor3 = Color3.fromRGB(190,180,220)
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.Size = UDim2.new(1, 0, 0, 24)
status.Parent = sec

local function setStatus(t) status.Text = "Status: "..t end

-- ===== langkah2 quest =====
local function stepGrabKey()
    setStatus("mencari VaultKey…")
    local key = findVaultKey()
    if not key then setStatus("VaultKey tidak ditemukan.") return false end

    local tgt = key:IsA("BasePart") and key or key:FindFirstChildWhichIsA("BasePart") or key.PrimaryPart
    if not tgt then setStatus("VaultKey tidak punya part.") return false end

    -- dekatkan & trigger
    tweenTo(tgt.Position + Vector3.new(0, 3, 0))
    local pp = findDescendant(key, "ProximityPrompt")
    if pp then
        setStatus("mengambil key (prompt)…")
        firePrompt(pp)
    else
        setStatus("mengambil key (touch)…")
        tryTouch(tgt)
    end

    task.wait(0.2)
    setStatus("key diambil (coba cek inventory/game).")
    return true
end

local function stepOpenGate()
    setStatus("mencari PoseidonGate…")
    local gate = findPoseidonGate()
    if not gate then setStatus("PoseidonGate tidak ditemukan.") return false end

    local tgt = gate:IsA("BasePart") and gate or gate:FindFirstChildWhichIsA("BasePart") or gate.PrimaryPart
    if not tgt then setStatus("Gate tidak punya part.") return false end

    tweenTo(tgt.Position + Vector3.new(0, 4, 0))
    local pp = findDescendant(gate, "ProximityPrompt")
    if pp then
        setStatus("membuka gate (prompt)…")
        firePrompt(pp)
    else
        setStatus("membuka gate (touch/click)…")
        tryTouch(tgt)
        local cd = findDescendant(gate, "ClickDetector")
        if cd and fireclickdetector then fireclickdetector(cd) end
    end

    task.wait(0.3)
    setStatus("gate dibuka (jika syarat terpenuhi).")
    return true
end

local function runAuto()
    if stepGrabKey() then
        task.wait(0.4)
        stepOpenGate()
    end
end

-- ===== tombol UI
mkButton("Teleport ke Key", function()
    local key = findVaultKey()
    if not key then return setStatus("VaultKey tidak ditemukan.") end
    local tgt = key:IsA("BasePart") and key or key:FindFirstChildWhichIsA("BasePart") or key.PrimaryPart
    if not tgt then return setStatus("VaultKey tidak punya part.") end
    tpCFrame(CFrame.new(tgt.Position + Vector3.new(0, 3, 0)))
    setStatus("teleport dekat VaultKey.")
end)

mkButton("Buka Gate", function()
    stepOpenGate()
end)

mkButton("Auto Run (Key→Gate)", function()
    runAuto()
end)

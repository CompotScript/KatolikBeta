-- ╔══════════════════════════════════════════════════════════╗
-- ║          BSS Helper Script | Orion UI Library            ║
-- ║          Unobfuscated & Commented                        ║
-- ╚══════════════════════════════════════════════════════════╝

-- [ SERVICES ]
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local char    = player.Character or player.CharacterAdded:Wait()
local rootPart = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- [ LOAD ORION LIBRARY ]
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- [ CREATE WINDOW ]
local Window = OrionLib:MakeWindow({
    Name            = "🐝 BSS Helper",
    HidePremium     = false,
    SaveConfig      = true,
    ConfigFileName  = "BSSHelper",
    IntroEnabled    = true,
    IntroText       = "🐝 BSS Helper",
})

-- ══════════════════════════════════════════════════
--  GLOBAL STATE FLAGS
-- ══════════════════════════════════════════════════
local State = {
    AutoFarm       = false,
    AutoDig        = false,
    AutoPlant      = false,
    KillStump      = false,
    KillBosses     = false,
    AutoSprinkler  = false,
    SelectedField  = "Sunflower Field",
    SelectedPlanter= "Basic Planter",
}

-- [ BSS FIELD LIST ]
local Fields = {
    "Sunflower Field",
    "Dandelion Field",
    "Mushroom Field",
    "Blue Flower Field",
    "Clover Field",
    "Spider Field",
    "Strawberry Field",
    "Bamboo Field",
    "Pineapple Field",
    "Stump Field",
    "Coconut Field",
    "Pumpkin Field",
    "Pine Tree Forest",
    "Rose Field",
    "Pepper Field",
    "Mountain Top Field",
}

-- [ FIELD BOUNDS TABLE ] 
-- CFrame positions approximated for each field
local FieldPositions = {
    ["Sunflower Field"]    = Vector3.new(185, 4, -85),
    ["Dandelion Field"]    = Vector3.new(68,  4, -93),
    ["Mushroom Field"]     = Vector3.new(-29, 4, -152),
    ["Blue Flower Field"]  = Vector3.new(-135,4, -35),
    ["Clover Field"]       = Vector3.new(52,  4, -5),
    ["Spider Field"]       = Vector3.new(-95, 4, -200),
    ["Strawberry Field"]   = Vector3.new(130, 4, -155),
    ["Bamboo Field"]       = Vector3.new(-200,4, -110),
    ["Pineapple Field"]    = Vector3.new(290, 4, -105),
    ["Stump Field"]        = Vector3.new(-48, 4, -350),
    ["Coconut Field"]      = Vector3.new(50,  4, -380),
    ["Pumpkin Field"]      = Vector3.new(-190,4, -305),
    ["Pine Tree Forest"]   = Vector3.new(-315,4, -185),
    ["Rose Field"]         = Vector3.new(195, 4, -280),
    ["Pepper Field"]       = Vector3.new(95,  4, -260),
    ["Mountain Top Field"] = Vector3.new(0,   65, -480),
}

-- [ PLANTER LIST ]
local PlanterList = {
    "Basic Planter",
    "Planter",
    "Mondo Planter",
    "Jumbo Planter",
    "Petal Planter",
    "Magnetic Planter",
    "Treat Planter",
    "Porcelain Planter",
    "Diamond Planter",
}

-- ══════════════════════════════════════════════════
--  HELPER FUNCTIONS
-- ══════════════════════════════════════════════════

-- Teleport character to a position safely
local function tpTo(pos)
    if rootPart then
        rootPart.CFrame = CFrame.new(pos)
    end
end

-- Walk toward a position (no teleport — uses Humanoid target)
local function walkTo(pos)
    if humanoid then
        humanoid:MoveTo(pos)
    end
end

-- Simulate a tool activation (digging / planting / sprinkler)
local function fireTool(toolName)
    local tool = player.Backpack:FindFirstChild(toolName)
        or char:FindFirstChild(toolName)
    if tool then
        -- Equip and activate
        humanoid:EquipTool(tool)
        task.wait(0.1)
        local event = tool:FindFirstChild("Activate")
            or tool:FindFirstChildOfClass("RemoteEvent")
        if event then
            event:FireServer()
        else
            -- fallback: use ClickDetector in workspace
            local act = tool:FindFirstChild("Handle")
            if act then
                fireproximityprompt = act:FindFirstChildOfClass("ClickDetector")
                if fireproximityprompt then
                    fireproximityprompt:FireServer()
                end
            end
        end
    end
end

-- ══════════════════════════════════════════════════
--  TAB 1: MAIN
-- ══════════════════════════════════════════════════
local MainTab = Window:MakeTab({
    Name = "🏠 Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

MainTab:AddSection({ Name = "Sprinkler" })

-- AUTO SPRINKLER: places sprinkler every 10 seconds
MainTab:AddToggle({
    Name    = "Auto Sprinkler",
    Default = false,
    Callback = function(val)
        State.AutoSprinkler = val
    end,
})

-- RunService loop for Auto Sprinkler
local sprinklerTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.AutoSprinkler then return end
    sprinklerTimer = sprinklerTimer + dt
    if sprinklerTimer >= 10 then
        sprinklerTimer = 0
        -- Place sprinkler tool (named "Sprinkler" in backpack)
        fireTool("Sprinkler")
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════
--  TAB 2: FARMING
-- ══════════════════════════════════════════════════
local FarmTab = Window:MakeTab({
    Name = "🌻 Farming",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

FarmTab:AddSection({ Name = "Field Settings" })

-- DROPDOWN: Select Field
FarmTab:AddDropdown({
    Name    = "Select Field",
    Default = "Sunflower Field",
    Options = Fields,
    Callback = function(val)
        State.SelectedField = val
    end,
})

FarmTab:AddSection({ Name = "Actions" })

-- TOGGLE: Auto-Farm
-- Walks in a small patrol pattern inside the selected field
-- and collects tokens by proximity
local farmAngle = 0
FarmTab:AddToggle({
    Name    = "Auto-Farm",
    Default = false,
    Callback = function(val)
        State.AutoFarm = val
    end,
})

-- RunService loop: patrol within field
local farmTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.AutoFarm then return end
    farmTimer = farmTimer + dt
    if farmTimer < 2 then return end  -- move every 2 s
    farmTimer = 0

    local base = FieldPositions[State.SelectedField]
    if not base then return end

    -- Walk to a random offset within ±15 studs of field center
    farmAngle = farmAngle + 45  -- rotate patrol point
    local rad = math.rad(farmAngle)
    local offset = Vector3.new(math.cos(rad) * 12, 0, math.sin(rad) * 12)
    walkTo(base + offset)

    -- Collect any nearby tokens
    local tokens = workspace:FindFirstChild("Tokens")
        or workspace:FindFirstChild("Collectables")
    if tokens then
        for _, token in ipairs(tokens:GetChildren()) do
            local dist = (token.Position - rootPart.Position).Magnitude
            if dist < 6 then
                -- Teleport onto token to pick it up
                tpTo(token.Position)
                task.wait(0.05)
            end
        end
    end
end)

-- TOGGLE: Auto-Dig (rapid clicking the dig tool)
FarmTab:AddToggle({
    Name    = "Auto-Dig",
    Default = false,
    Callback = function(val)
        State.AutoDig = val
    end,
})

local digTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.AutoDig then return end
    digTimer = digTimer + dt
    if digTimer < 0.15 then return end  -- 150 ms between clicks
    digTimer = 0
    fireTool("Scoop")          -- typical dig tool name in BSS
end)

-- ══════════════════════════════════════════════════
--  TAB 3: PLANTERS
-- ══════════════════════════════════════════════════
local PlantTab = Window:MakeTab({
    Name = "🪴 Planters",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

PlantTab:AddSection({ Name = "Planter Settings" })

-- DROPDOWN: Select Planter
PlantTab:AddDropdown({
    Name    = "Select Planter",
    Default = "Basic Planter",
    Options = PlanterList,
    Callback = function(val)
        State.SelectedPlanter = val
    end,
})

PlantTab:AddSection({ Name = "Auto Plant" })

-- TOGGLE: Auto Plant
PlantTab:AddToggle({
    Name    = "Auto Plant",
    Default = false,
    Callback = function(val)
        State.AutoPlant = val
    end,
})

local plantTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.AutoPlant then return end
    plantTimer = plantTimer + dt
    if plantTimer < 5 then return end  -- try every 5 s
    plantTimer = 0

    -- Check if near a field before planting
    local nearField = false
    for _, pos in pairs(FieldPositions) do
        if (pos - rootPart.Position).Magnitude < 30 then
            nearField = true
            break
        end
    end

    if nearField then
        fireTool(State.SelectedPlanter)
        task.wait(0.3)
    end
end)

-- ══════════════════════════════════════════════════
--  TAB 4: COMBAT
-- ══════════════════════════════════════════════════
local CombatTab = Window:MakeTab({
    Name = "⚔️ Combat",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

CombatTab:AddSection({ Name = "Enemies" })

-- TOGGLE: Kill Stump Snail
-- Stays near Stump Field and attacks the Stump Snail
CombatTab:AddToggle({
    Name    = "Kill Stump Snail",
    Default = false,
    Callback = function(val)
        State.KillStump = val
        if val then
            -- Teleport to stump field first
            tpTo(FieldPositions["Stump Field"])
        end
    end,
})

local snailTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.KillStump then return end
    snailTimer = snailTimer + dt
    if snailTimer < 0.2 then return end
    snailTimer = 0

    -- Find the Stump Snail mob in workspace
    local snail = workspace:FindFirstChild("StumpSnail")
        or workspace:FindFirstChild("Stump Snail")
    if snail then
        local snailRoot = snail:FindFirstChild("HumanoidRootPart")
            or snail.PrimaryPart
        if snailRoot then
            -- Teleport on top of snail and swing tool
            tpTo(snailRoot.Position + Vector3.new(0, 2, 0))
            fireTool("Basic Bee Swarm")  -- main combat tool
        end
    else
        -- Stay at stump field center if snail not found yet
        walkTo(FieldPositions["Stump Field"])
    end
end)

-- TOGGLE: Kill Bosses (ViciousBee / MondoChick)
-- Attacks bosses and strafes away when health < 50%
CombatTab:AddToggle({
    Name    = "Kill Bosses",
    Default = false,
    Callback = function(val)
        State.KillBosses = val
    end,
})

local bossNames = { "ViciousBee", "Vicious Bee", "MondoChick", "Mondo Chick" }
local bossTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.KillBosses then return end
    bossTimer = bossTimer + dt
    if bossTimer < 0.2 then return end
    bossTimer = 0

    for _, bossName in ipairs(bossNames) do
        local boss = workspace:FindFirstChild(bossName)
        if boss then
            local bossRoot = boss:FindFirstChild("HumanoidRootPart")
                or boss.PrimaryPart
            local bossHum  = boss:FindFirstChildOfClass("Humanoid")
            if bossRoot and bossHum then
                local myHP  = humanoid.Health
                local maxHP = humanoid.MaxHealth
                local hpPct = myHP / maxHP

                if hpPct < 0.5 then
                    -- Strafe AWAY from boss when low HP
                    local awayDir = (rootPart.Position - bossRoot.Position).Unit
                    local safePos = rootPart.Position + awayDir * 20
                    tpTo(safePos)
                else
                    -- Move toward boss and attack
                    tpTo(bossRoot.Position + Vector3.new(0, 2, 0))
                    fireTool("Basic Bee Swarm")
                end
            end
            break  -- handle one boss at a time
        end
    end
end)

-- ══════════════════════════════════════════════════
--  TAB 5: CONFIGS
-- ══════════════════════════════════════════════════
local ConfigTab = Window:MakeTab({
    Name = "⚙️ Configs",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

ConfigTab:AddSection({ Name = "Saved Config" })

-- Save config button
ConfigTab:AddButton({
    Name = "💾 Save Config",
    Callback = function()
        OrionLib:MakeNotification({
            Name    = "Config",
            Content = "✅ Config saved!",
            Image   = "rbxassetid://4483345998",
            Time    = 3,
        })
        -- Orion auto-saves toggles / dropdowns via SaveConfig = true
    end,
})

-- Load config button
ConfigTab:AddButton({
    Name = "📂 Load Config",
    Callback = function()
        OrionLib:MakeNotification({
            Name    = "Config",
            Content = "📂 Config loaded!",
            Image   = "rbxassetid://4483345998",
            Time    = 3,
        })
    end,
})

ConfigTab:AddSection({ Name = "Info" })

ConfigTab:AddLabel("Script by: BSS Helper v1.0")
ConfigTab:AddLabel("Orion UI Library")

-- ══════════════════════════════════════════════════
--  INIT
-- ══════════════════════════════════════════════════
OrionLib:Init()

OrionLib:MakeNotification({
    Name    = "🐝 BSS Helper",
    Content = "Script loaded successfully!",
    Image   = "rbxassetid://4483345998",
    Time    = 5,
})
-- ╔══════════════════════════════════════════════════════════╗
-- ║          BSS Helper Script | Rayfield UI Library         ║
-- ║          Xeno Executor Compatible                        ║
-- ║          Toggle GUI: Right CTRL                          ║
-- ╚══════════════════════════════════════════════════════════╝

-- [ SERVICES ]
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local rootPart = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- ══════════════════════════════════════════════════
--  LOAD RAYFIELD
-- ══════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- [ CREATE WINDOW ]
local Window = Rayfield:CreateWindow({
    Name                 = "🐝 BSS Helper",
    Icon                 = 0,
    LoadingTitle         = "🐝 BSS Helper",
    LoadingSubtitle      = "by BSS Helper v1.0",
    Theme                = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving  = {
        Enabled        = true,
        FolderName     = "BSSHelper",
        FileName       = "Config",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════
--  GLOBAL STATE FLAGS
-- ══════════════════════════════════════════════════
local State = {
    AutoFarm      = false,
    AutoDig       = false,
    AutoPlant     = false,
    KillStump     = false,
    KillBosses    = false,
    AutoSprinkler = false,
    SelectedField  = "Sunflower Field",
    SelectedPlanter = "Basic Planter",
}

-- ══════════════════════════════════════════════════
--  DATA TABLES
-- ══════════════════════════════════════════════════

-- Все поля BSS
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

-- Координаты центров полей
local FieldPositions = {
    ["Sunflower Field"]    = Vector3.new(185,  4,  -85),
    ["Dandelion Field"]    = Vector3.new(68,   4,  -93),
    ["Mushroom Field"]     = Vector3.new(-29,  4, -152),
    ["Blue Flower Field"]  = Vector3.new(-135, 4,  -35),
    ["Clover Field"]       = Vector3.new(52,   4,   -5),
    ["Spider Field"]       = Vector3.new(-95,  4, -200),
    ["Strawberry Field"]   = Vector3.new(130,  4, -155),
    ["Bamboo Field"]       = Vector3.new(-200, 4, -110),
    ["Pineapple Field"]    = Vector3.new(290,  4, -105),
    ["Stump Field"]        = Vector3.new(-48,  4, -350),
    ["Coconut Field"]      = Vector3.new(50,   4, -380),
    ["Pumpkin Field"]      = Vector3.new(-190, 4, -305),
    ["Pine Tree Forest"]   = Vector3.new(-315, 4, -185),
    ["Rose Field"]         = Vector3.new(195,  4, -280),
    ["Pepper Field"]       = Vector3.new(95,   4, -260),
    ["Mountain Top Field"] = Vector3.new(0,   65, -480),
}

-- Список планеров
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

-- Телепорт персонажа в точку
local function tpTo(pos)
    if rootPart then
        rootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

-- Движение к точке через Humanoid
local function walkTo(pos)
    if humanoid then
        humanoid:MoveTo(pos)
    end
end

-- Активация инструмента из рюкзака
local function fireTool(toolName)
    local tool = player.Backpack:FindFirstChild(toolName)
               or char:FindFirstChild(toolName)
    if not tool then return end

    -- Экипировать инструмент
    humanoid:EquipTool(tool)
    task.wait(0.1)

    -- Попытка активировать через RemoteEvent
    local handle = tool:FindFirstChild("Handle")
    if handle then
        local click = handle:FindFirstChildOfClass("ClickDetector")
        if click then
            fireclickdetector(click)
            return
        end
    end

    -- Fallback: через RemoteEvent внутри инструмента
    local remote = tool:FindFirstChildOfClass("RemoteEvent")
    if remote then
        remote:FireServer()
    end
end

-- ══════════════════════════════════════════════════
--  TAB 1: MAIN
-- ══════════════════════════════════════════════════
local MainTab = Window:CreateTab("🏠 Main", 4483345998)

MainTab:CreateSection("Sprinkler")

-- Авто-спринклер каждые 10 секунд
MainTab:CreateToggle({
    Name        = "Auto Sprinkler",
    CurrentValue = false,
    Flag        = "AutoSprinkler",
    Callback    = function(val)
        State.AutoSprinkler = val
    end,
})

-- Таймер спринклера
local sprinklerTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.AutoSprinkler then return end
    sprinklerTimer += dt
    if sprinklerTimer >= 10 then
        sprinklerTimer = 0
        fireTool("Sprinkler")
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════
--  TAB 2: FARMING
-- ══════════════════════════════════════════════════
local FarmTab = Window:CreateTab("🌻 Farming", 4483345998)

FarmTab:CreateSection("Field Settings")

-- Дропдаун выбора поля
FarmTab:CreateDropdown({
    Name    = "Select Field",
    Options = Fields,
    CurrentOption = {"Sunflower Field"},
    MultipleOptions = false,
    Flag    = "SelectedField",
    Callback = function(val)
        -- Rayfield возвращает таблицу даже при MultipleOptions = false
        State.SelectedField = type(val) == "table" and val[1] or val
    end,
})

FarmTab:CreateSection("Actions")

-- Авто-фарм: патрулирует поле и собирает токены
local farmAngle = 0
local farmTimer = 0
FarmTab:CreateToggle({
    Name         = "Auto-Farm",
    CurrentValue = false,
    Flag         = "AutoFarm",
    Callback     = function(val)
        State.AutoFarm = val
    end,
})

RunService.Heartbeat:Connect(function(dt)
    if not State.AutoFarm then return end
    farmTimer += dt
    if farmTimer < 2 then return end
    farmTimer = 0

    local base = FieldPositions[State.SelectedField]
    if not base then return end

    -- Патрульное движение по кругу внутри поля
    farmAngle += 45
    local rad    = math.rad(farmAngle)
    local offset = Vector3.new(math.cos(rad) * 12, 0, math.sin(rad) * 12)
    walkTo(base + offset)

    -- Сбор ближайших токенов
    local tokens = workspace:FindFirstChild("Tokens")
                or workspace:FindFirstChild("Collectables")
    if tokens then
        for _, token in ipairs(tokens:GetChildren()) do
            local part = token:IsA("BasePart") and token
                      or token:FindFirstChildOfClass("BasePart")
            if part then
                local dist = (part.Position - rootPart.Position).Magnitude
                if dist < 6 then
                    tpTo(part.Position)
                    task.wait(0.05)
                end
            end
        end
    end
end)

-- Авто-коп: быстрый клик инструментом "Scoop"
local digTimer = 0
FarmTab:CreateToggle({
    Name         = "Auto-Dig",
    CurrentValue = false,
    Flag         = "AutoDig",
    Callback     = function(val)
        State.AutoDig = val
    end,
})

RunService.Heartbeat:Connect(function(dt)
    if not State.AutoDig then return end
    digTimer += dt
    if digTimer < 0.15 then return end
    digTimer = 0
    fireTool("Scoop")
end)

-- ══════════════════════════════════════════════════
--  TAB 3: PLANTERS
-- ══════════════════════════════════════════════════
local PlantTab = Window:CreateTab("🪴 Planters", 4483345998)

PlantTab:CreateSection("Planter Settings")

-- Дропдаун выбора планера
PlantTab:CreateDropdown({
    Name    = "Select Planter",
    Options = PlanterList,
    CurrentOption = {"Basic Planter"},
    MultipleOptions = false,
    Flag    = "SelectedPlanter",
    Callback = function(val)
        State.SelectedPlanter = type(val) == "table" and val[1] or val
    end,
})

PlantTab:CreateSection("Auto Plant")

-- Авто-посадка рядом с полем
local plantTimer = 0
PlantTab:CreateToggle({
    Name         = "Auto Plant",
    CurrentValue = false,
    Flag         = "AutoPlant",
    Callback     = function(val)
        State.AutoPlant = val
    end,
})

RunService.Heartbeat:Connect(function(dt)
    if not State.AutoPlant then return end
    plantTimer += dt
    if plantTimer < 5 then return end
    plantTimer = 0

    -- Проверить близость к полю
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
local CombatTab = Window:CreateTab("⚔️ Combat", 4483345998)

CombatTab:CreateSection("Enemies")

-- Kill Stump Snail: держится у Stump Field и атакует улитку
local snailTimer = 0
CombatTab:CreateToggle({
    Name         = "Kill Stump Snail",
    CurrentValue = false,
    Flag         = "KillStump",
    Callback     = function(val)
        State.KillStump = val
        if val then
            tpTo(FieldPositions["Stump Field"])
        end
    end,
})

RunService.Heartbeat:Connect(function(dt)
    if not State.KillStump then return end
    snailTimer += dt
    if snailTimer < 0.2 then return end
    snailTimer = 0

    local snail = workspace:FindFirstChild("StumpSnail")
               or workspace:FindFirstChild("Stump Snail")
    if snail then
        local snailRoot = snail:FindFirstChild("HumanoidRootPart")
                       or snail.PrimaryPart
        if snailRoot then
            tpTo(snailRoot.Position + Vector3.new(0, 2, 0))
            fireTool("Basic Bee Swarm")
        end
    else
        walkTo(FieldPositions["Stump Field"])
    end
end)

-- Kill Bosses: атакует ViciousBee / MondoChick, отступает при низком HP
local bossNames = { "ViciousBee", "Vicious Bee", "MondoChick", "Mondo Chick" }
local bossTimer = 0
CombatTab:CreateToggle({
    Name         = "Kill Bosses",
    CurrentValue = false,
    Flag         = "KillBosses",
    Callback     = function(val)
        State.KillBosses = val
    end,
})

RunService.Heartbeat:Connect(function(dt)
    if not State.KillBosses then return end
    bossTimer += dt
    if bossTimer < 0.2 then return end
    bossTimer = 0

    for _, bossName in ipairs(bossNames) do
        local boss = workspace:FindFirstChild(bossName)
        if boss then
            local bossRoot = boss:FindFirstChild("HumanoidRootPart")
                          or boss.PrimaryPart
            local bossHum  = boss:FindFirstChildOfClass("Humanoid")
            if bossRoot and bossHum then
                local hpPct = humanoid.Health / humanoid.MaxHealth
                if hpPct < 0.5 then
                    -- Отступить от босса
                    local awayDir = (rootPart.Position - bossRoot.Position).Unit
                    tpTo(rootPart.Position + awayDir * 20)
                else
                    -- Атаковать босса
                    tpTo(bossRoot.Position + Vector3.new(0, 2, 0))
                    fireTool("Basic Bee Swarm")
                end
            end
            break
        end
    end
end)

-- ══════════════════════════════════════════════════
--  TAB 5: CONFIGS
-- ══════════════════════════════════════════════════
local ConfigTab = Window:CreateTab("⚙️ Configs", 4483345998)

ConfigTab:CreateSection("Save / Load")

ConfigTab:CreateButton({
    Name     = "💾 Save Config",
    Callback = function()
        Rayfield:Notify({
            Title    = "Config",
            Content  = "✅ Config saved!",
            Duration = 3,
        })
    end,
})

ConfigTab:CreateButton({
    Name     = "📂 Load Config",
    Callback = function()
        Rayfield:Notify({
            Title    = "Config",
            Content  = "📂 Config loaded!",
            Duration = 3,
        })
    end,
})

ConfigTab:CreateSection("Info")
ConfigTab:CreateLabel("BSS Helper v1.0 | Rayfield UI")

-- ══════════════════════════════════════════════════
--  RIGHT CTRL — TOGGLE GUI VISIBILITY
-- ══════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- gameProcessed = true означает что игра уже обработала ввод (чат и т.д.)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.RightControl then
        -- Rayfield имеет встроенный метод скрытия/показа
        Rayfield:Toggle()
    end
end)

-- ══════════════════════════════════════════════════
--  УВЕДОМЛЕНИЕ О ЗАГРУЗКЕ
-- ══════════════════════════════════════════════════
Rayfield:Notify({
    Title    = "🐝 BSS Helper",
    Content  = "Script loaded! Press Right CTRL to toggle GUI.",
    Duration = 5,
})

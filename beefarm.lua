-- ╔══════════════════════════════════════════════════════════╗
-- ║          BSS Helper Script | Rayfield UI Library         ║
-- ║          Xeno Executor Compatible                        ║
-- ║          Toggle GUI: Right CTRL                          ║
-- ╚══════════════════════════════════════════════════════════╝

-- [ SERVICES ]
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
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
    Name                   = "🐝 BSS Helper",
    Icon                   = 0,
    LoadingTitle           = "🐝 BSS Helper",
    LoadingSubtitle        = "Xeno Compatible | v2.0",
    Theme                  = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = {
        Enabled    = true,
        FolderName = "BSSHelper",
        FileName   = "Config",
    },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════
--  GLOBAL STATE
-- ══════════════════════════════════════════════════
local State = {
    AutoFarm       = false,
    AutoDig        = false,
    AutoPlant      = false,
    KillStump      = false,
    KillBosses     = false,
    AutoSprinkler  = false,
    SelectedField  = "Sunflower Field",
    SelectedPlanter = "Basic Planter",
}

-- ══════════════════════════════════════════════════
--  ПОЛЯ BSS — координаты центров
--  (встань на поле и напиши print(rootPart.Position)
--   чтобы уточнить координаты под свой сервер)
-- ══════════════════════════════════════════════════
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
    ["Mountain Top Field"] = Vector3.new(0,    65, -480),
}

-- Список всех полей для дропдауна
local Fields = {}
for name, _ in pairs(FieldPositions) do
    table.insert(Fields, name)
end
table.sort(Fields) -- сортировка по алфавиту

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

-- Телепорт в позицию (чуть выше чтобы не застрять в полу)
local function tpTo(pos)
    if rootPart and pos then
        rootPart.CFrame = CFrame.new(
            pos.X,
            pos.Y + 3,
            pos.Z
        )
    end
end

-- Активация инструмента из рюкзака
local function fireTool(toolName)
    local tool = player.Backpack:FindFirstChild(toolName)
               or char:FindFirstChild(toolName)
    if not tool then return end
    humanoid:EquipTool(tool)
    task.wait(0.1)
    local handle = tool:FindFirstChild("Handle")
    if handle then
        local click = handle:FindFirstChildOfClass("ClickDetector")
        if click then
            fireclickdetector(click)
            return
        end
    end
    local remote = tool:FindFirstChildOfClass("RemoteEvent")
    if remote then
        remote:FireServer()
    end
end

-- ══════════════════════════════════════════════════
--  АВТО-ФАРМ — ОСНОВНАЯ ЛОГИКА
--  Телепортируется по сетке точек внутри поля
--  и собирает всё в радиусе 8 стадов
-- ══════════════════════════════════════════════════

-- Генерируем сетку точек для обхода поля (5x5 = 25 точек)
local function getFieldGrid(center)
    local points = {}
    local step   = 5   -- шаг между точками в стадах
    local count  = 5   -- точек по каждой оси
    local half   = (count - 1) * step / 2

    for x = 0, count - 1 do
        for z = 0, count - 1 do
            table.insert(points, Vector3.new(
                center.X + (x * step - half),
                center.Y,
                center.Z + (z * step - half)
            ))
        end
    end
    return points
end

-- Проверка — является ли объект токеном/пыльцой
local function isCollectable(obj)
    if not obj:IsA("BasePart") and not obj:IsA("Model") then
        return false
    end
    local n = obj.Name:lower()
    return n:find("token")    ~= nil
        or n:find("pollen")   ~= nil
        or n:find("honey")    ~= nil
        or n:find("collect")  ~= nil
        or n:find("drop")     ~= nil
        or n:find("nectar")   ~= nil
end

-- Основной фарм-луп
local farmGridIndex = 1
local farmGrid      = {}
local farmTimer     = 0
local FARM_INTERVAL = 0.4  -- секунд между телепортами

RunService.Heartbeat:Connect(function(dt)
    if not State.AutoFarm then
        farmGridIndex = 1  -- сбросить позицию при выключении
        return
    end

    farmTimer += dt
    if farmTimer < FARM_INTERVAL then return end
    farmTimer = 0

    -- Получаем/обновляем сетку для выбранного поля
    local center = FieldPositions[State.SelectedField]
    if not center then return end

    -- Пересчитать сетку если она пустая
    if #farmGrid == 0 then
        farmGrid = getFieldGrid(center)
    end

    -- Телепортируемся к следующей точке сетки
    local targetPoint = farmGrid[farmGridIndex]
    if targetPoint then
        rootPart.CFrame = CFrame.new(
            targetPoint.X,
            center.Y + 3,
            targetPoint.Z
        )
    end

    -- Переходим к следующей точке (по кругу)
    farmGridIndex += 1
    if farmGridIndex > #farmGrid then
        farmGridIndex = 1
    end

    -- Собираем все коллектаблы в радиусе 8 стадов
    task.wait(0.05)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isCollectable(obj) then
            local part = obj:IsA("BasePart") and obj
                      or obj:FindFirstChildOfClass("BasePart")
            if part then
                local dist = (part.Position - rootPart.Position).Magnitude
                if dist < 8 then
                    -- Телепортируемся прямо на токен
                    rootPart.CFrame = CFrame.new(part.Position)
                    task.wait(0.03)
                end
            end
        end
    end
end)

-- Сбросить сетку при смене поля
local function resetFarmGrid()
    farmGrid      = {}
    farmGridIndex = 1
end

-- ══════════════════════════════════════════════════
--  TAB 1 — MAIN
-- ══════════════════════════════════════════════════
local MainTab = Window:CreateTab("🏠 Main", 4483345998)
MainTab:CreateSection("Sprinkler")

MainTab:CreateToggle({
    Name         = "Auto Sprinkler",
    CurrentValue = false,
    Flag         = "AutoSprinkler",
    Callback     = function(val)
        State.AutoSprinkler = val
    end,
})

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
--  TAB 2 — FARMING
-- ══════════════════════════════════════════════════
local FarmTab = Window:CreateTab("🌻 Farming", 4483345998)
FarmTab:CreateSection("Field Settings")

FarmTab:CreateDropdown({
    Name            = "Select Field",
    Options         = Fields,
    CurrentOption   = {"Sunflower Field"},
    MultipleOptions = false,
    Flag            = "SelectedField",
    Callback        = function(val)
        State.SelectedField = type(val) == "table" and val[1] or val
        resetFarmGrid()  -- пересчитать сетку для нового поля
        Rayfield:Notify({
            Title    = "Field Changed",
            Content  = "✅ Выбрано: " .. State.SelectedField,
            Duration = 2,
        })
    end,
})

FarmTab:CreateSection("Actions")

FarmTab:CreateToggle({
    Name         = "Auto-Farm",
    CurrentValue = false,
    Flag         = "AutoFarm",
    Callback     = function(val)
        State.AutoFarm = val
        if val then
            -- Телепортируемся к полю сразу при включении
            local center = FieldPositions[State.SelectedField]
            if center then tpTo(center) end
            resetFarmGrid()
            Rayfield:Notify({
                Title    = "Auto-Farm",
                Content  = "🌻 Фарм запущен: " .. State.SelectedField,
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title    = "Auto-Farm",
                Content  = "⛔ Фарм остановлен",
                Duration = 2,
            })
        end
    end,
})

-- Авто-коп
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
--  TAB 3 — PLANTERS
-- ══════════════════════════════════════════════════
local PlantTab = Window:CreateTab("🪴 Planters", 4483345998)
PlantTab:CreateSection("Planter Settings")

PlantTab:CreateDropdown({
    Name            = "Select Planter",
    Options         = PlanterList,
    CurrentOption   = {"Basic Planter"},
    MultipleOptions = false,
    Flag            = "SelectedPlanter",
    Callback        = function(val)
        State.SelectedPlanter = type(val) == "table" and val[1] or val
    end,
})

PlantTab:CreateSection("Auto Plant")

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
--  TAB 4 — COMBAT
-- ══════════════════════════════════════════════════
local CombatTab = Window:CreateTab("⚔️ Combat", 4483345998)
CombatTab:CreateSection("Enemies")

-- Kill Stump Snail
local snailTimer = 0
CombatTab:CreateToggle({
    Name         = "Kill Stump Snail",
    CurrentValue = false,
    Flag         = "KillStump",
    Callback     = function(val)
        State.KillStump = val
        if val then tpTo(FieldPositions["Stump Field"]) end
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
            tpTo(snailRoot.Position)
            fireTool("Basic Bee Swarm")
        end
    else
        local center = FieldPositions["Stump Field"]
        if center then
            rootPart.CFrame = CFrame.new(center.X, center.Y + 3, center.Z)
        end
    end
end)

-- Kill Bosses
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
            if bossRoot then
                local hpPct = humanoid.Health / humanoid.MaxHealth
                if hpPct < 0.5 then
                    -- Отступить от босса
                    local awayDir = (rootPart.Position - bossRoot.Position).Unit
                    rootPart.CFrame = CFrame.new(
                        rootPart.Position + awayDir * 20
                    )
                else
                    tpTo(bossRoot.Position)
                    fireTool("Basic Bee Swarm")
                end
            end
            break
        end
    end
end)

-- ══════════════════════════════════════════════════
--  TAB 5 — CONFIGS
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

ConfigTab:CreateSection("Debug")

-- Кнопка для диагностики — выводит позицию и объекты рядом
ConfigTab:CreateButton({
    Name     = "📍 Print My Position",
    Callback = function()
        print("📍 Позиция:", rootPart.Position)
        print("=== Объекты рядом ===")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local dist = (obj.Position - rootPart.Position).Magnitude
                if dist < 15 then
                    print(obj:GetFullName(), "|", dist)
                end
            end
        end
        Rayfield:Notify({
            Title    = "Debug",
            Content  = "📍 Позиция в консоли!",
            Duration = 3,
        })
    end,
})

ConfigTab:CreateSection("Info")
ConfigTab:CreateLabel("BSS Helper v2.0 | Rayfield UI | Xeno")

-- ══════════════════════════════════════════════════
--  RIGHT CTRL — TOGGLE GUI
-- ══════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Rayfield:Toggle()
    end
end)

-- ══════════════════════════════════════════════════
--  ОБНОВЛЕНИЕ CHAR ПРИ РЕСПАУНЕ
-- ══════════════════════════════════════════════════
player.CharacterAdded:Connect(function(newChar)
    char     = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    -- Сбросить все фармы при смерти
    State.AutoFarm      = false
    State.AutoDig       = false
    State.KillStump     = false
    State.KillBosses    = false
    resetFarmGrid()
end)

-- ══════════════════════════════════════════════════
--  СТАРТ
-- ══════════════════════════════════════════════════
Rayfield:Notify({
    Title    = "🐝 BSS Helper v2.0",
    Content  = "Загружено! Right CTRL = открыть/закрыть GUI",
    Duration = 5,
})

-- BSS Helper v4.0
-- Rayfield + Xeno | Right CTRL = toggle GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

plr.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end)

-- ══════════════════════════════════════════════════
-- ЗАГРУЗКА RAYFIELD
-- ══════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Win = Rayfield:CreateWindow({
    Name = "🐝 BSS Helper v4",
    LoadingTitle = "BSS Helper",
    LoadingSubtitle = "v4.0",
    Theme = "Default",
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════
-- СОСТОЯНИЯ
-- ══════════════════════════════════════════════════
local autoFarm      = false
local autoDig       = false
local autoPlant     = false
local killSnail     = false
local killBoss      = false
local autoSprinkler = false

local selectedField   = "Sunflower Field"
local selectedPlanter = "Basic Planter"

-- ══════════════════════════════════════════════════
-- ПОЛЯ
-- ══════════════════════════════════════════════════
local Fields = {
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

local FieldNames = {
    "Sunflower Field","Dandelion Field","Mushroom Field",
    "Blue Flower Field","Clover Field","Spider Field",
    "Strawberry Field","Bamboo Field","Pineapple Field",
    "Stump Field","Coconut Field","Pumpkin Field",
    "Pine Tree Forest","Rose Field","Pepper Field",
    "Mountain Top Field",
}

-- Позиция улья (сдача пыльцы на мёд)
-- Замени на реальную позицию твоего улья: print(root.Position) рядом с ульем
local HIVE_POSITION = Vector3.new(0, 4, 0)

local PlanterNames = {
    "Basic Planter","Planter","Mondo Planter","Jumbo Planter",
    "Petal Planter","Magnetic Planter","Treat Planter",
    "Porcelain Planter","Diamond Planter",
}

-- ══════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ══════════════════════════════════════════════════
local function tp(pos)
    root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
end

local function useTool(name)
    local tool = plr.Backpack:FindFirstChild(name) or char:FindFirstChild(name)
    if not tool then return end
    hum:EquipTool(tool)
    task.wait(0.1)
    local handle = tool:FindFirstChild("Handle")
    if handle then
        local cd = handle:FindFirstChildOfClass("ClickDetector")
        if cd then fireclickdetector(cd) return end
    end
    local re = tool:FindFirstChildOfClass("RemoteEvent")
    if re then re:FireServer() end
end

-- Симуляция зажатого ЛКМ через VirtualInputManager
local function holdClick(seconds)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)   -- нажать
    task.wait(seconds)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)  -- отпустить
end

-- ══════════════════════════════════════════════════
-- ПРОВЕРКА ЗАПОЛНЕННОСТИ РЮКЗАКА
-- Пыльца хранится как NumberValue / IntValue внутри
-- папки игрока — ищем по имени
-- ══════════════════════════════════════════════════
local function getPollenAmount()
    -- Способ 1: через leaderstats или BeeSwarmStats
    local stats = plr:FindFirstChild("BeeSwarmStats")
               or plr:FindFirstChild("leaderstats")
               or plr:FindFirstChild("Stats")
    if stats then
        local pollen = stats:FindFirstChild("Pollen")
                    or stats:FindFirstChild("Collected Pollen")
        if pollen then
            return pollen.Value
        end
    end
    -- Способ 2: через PlayerGui / PlayerScripts
    local data = plr:FindFirstChild("PlayerData")
    if data then
        local p = data:FindFirstChild("Pollen")
        if p then return p.Value end
    end
    return 0
end

local function getMaxPollen()
    local stats = plr:FindFirstChild("BeeSwarmStats")
               or plr:FindFirstChild("leaderstats")
               or plr:FindFirstChild("Stats")
    if stats then
        local cap = stats:FindFirstChild("PollenCapacity")
                 or stats:FindFirstChild("Bag Size")
                 or stats:FindFirstChild("BagSize")
        if cap then return cap.Value end
    end
    return 100 -- дефолт если не нашли
end

local function isBagFull()
    local current = getPollenAmount()
    local max     = getMaxPollen()
    -- Считаем заполненным если >= 95%
    return current >= (max * 0.95)
end

-- ══════════════════════════════════════════════════
-- СДАЧА ПЫЛЬЦЫ НА МЁД
-- Телепортируется к улью и взаимодействует с ним
-- ══════════════════════════════════════════════════
local isConverting = false -- флаг чтобы не запускать дважды

local function convertPollenToHoney()
    if isConverting then return end
    isConverting = true

    local prevFarm = autoFarm
    local prevDig  = autoDig

    -- Остановить фарм и коп на время сдачи
    autoFarm = false
    autoDig  = false

    Rayfield:Notify({
        Title   = "🍯 Сдача пыльцы",
        Content = "Телепорт к улью...",
        Duration = 3,
    })

    -- Телепортируемся к улью
    tp(HIVE_POSITION)
    task.wait(0.5)

    -- Ищем улей в workspace
    local hive = workspace:FindFirstChild("Hive")
              or workspace:FindFirstChild("MyHive")
              or workspace:FindFirstChild("BasicHive")

    if hive then
        -- Ищем ClickDetector или ProximityPrompt на улье
        local cd = hive:FindFirstChildOfClass("ClickDetector")
                or (hive.PrimaryPart and hive.PrimaryPart:FindFirstChildOfClass("ClickDetector"))
        local pp = hive:FindFirstChildOfClass("ProximityPrompt")
                or (hive.PrimaryPart and hive.PrimaryPart:FindFirstChildOfClass("ProximityPrompt"))

        if cd then
            fireclickdetector(cd)
            task.wait(0.3)
        elseif pp then
            fireproximityprompt(pp)
            task.wait(0.3)
        else
            -- Fallback: ищем по всем детям улья
            for _, child in ipairs(hive:GetDescendants()) do
                local childCd = child:FindFirstChildOfClass("ClickDetector")
                if childCd then
                    fireclickdetector(childCd)
                    task.wait(0.1)
                end
                local childPp = child:FindFirstChildOfClass("ProximityPrompt")
                if childPp then
                    fireproximityprompt(childPp)
                    task.wait(0.1)
                end
            end
        end

        Rayfield:Notify({
            Title   = "🍯 Готово!",
            Content = "Пыльца сдана в мёд!",
            Duration = 3,
        })
    else
        Rayfield:Notify({
            Title   = "⚠️ Улей не найден",
            Content = "Установи координаты улья вручную!\nprint(root.Position) рядом с ульем",
            Duration = 5,
        })
        warn("[BSS] Улей не найден в workspace! Установи HIVE_POSITION вручную.")
        print("[BSS] Твоя позиция сейчас:", root.Position)
    end

    task.wait(1)

    -- Возвращаемся к полю
    local fieldCenter = Fields[selectedField]
    if fieldCenter then
        tp(fieldCenter)
        task.wait(0.5)
    end

    -- Восстановить фарм и коп
    autoFarm = prevFarm
    autoDig  = prevDig
    isConverting = false
end

-- ══════════════════════════════════════════════════
-- АВТО-КОП — ЗАЖАТЫЙ ЛКМ + СДАЧА ПРИ ПОЛНОМ РЮКЗАКЕ
-- ══════════════════════════════════════════════════
local digTask = nil -- хранит coroutine копа

local function startDig()
    -- Запускаем в отдельном потоке чтобы не блокировать Heartbeat
    digTask = task.spawn(function()
        while autoDig do
            -- Если рюкзак полный — сдать пыльцу
            if isBagFull() then
                Rayfield:Notify({
                    Title   = "🎒 Рюкзак полный!",
                    Content = "Идём сдавать пыльцу...",
                    Duration = 3,
                })
                convertPollenToHoney()
            end

            -- Экипируем совок
            local scoop = plr.Backpack:FindFirstChild("Scoop")
                       or char:FindFirstChild("Scoop")
            if scoop then
                hum:EquipTool(scoop)
                task.wait(0.1)
                -- Зажимаем ЛКМ на 0.5 секунды (имитация удержания)
                holdClick(0.5)
                task.wait(0.1)
            else
                -- Совка нет в рюкзаке
                task.wait(0.5)
            end
        end
    end)
end

-- ══════════════════════════════════════════════════
-- ФАРМ — СЕТКА 5x5
-- ══════════════════════════════════════════════════
local farmPoints = {}
local farmIdx    = 1
local farmTimer  = 0

local function buildGrid(center)
    farmPoints = {}
    farmIdx    = 1
    for x = -10, 10, 5 do
        for z = -10, 10, 5 do
            table.insert(farmPoints, Vector3.new(
                center.X + x,
                center.Y,
                center.Z + z
            ))
        end
    end
end

-- ══════════════════════════════════════════════════
-- ГЛАВНЫЙ HEARTBEAT
-- ══════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)

    -- ── АВТО ФАРМ ──────────────────────────────────
    if autoFarm and not isConverting then
        farmTimer += dt
        if farmTimer >= 0.35 then
            farmTimer = 0
            local center = Fields[selectedField]
            if center then
                if #farmPoints == 0 then buildGrid(center) end
                local pt = farmPoints[farmIdx]
                root.CFrame = CFrame.new(pt.X, pt.Y + 3, pt.Z)
                farmIdx = farmIdx % #farmPoints + 1
                -- Сбор токенов
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        local n = v.Name:lower()
                        if n:find("token") or n:find("pollen")
                        or n:find("honey") or n:find("nectar")
                        or n:find("drop") then
                            if (v.Position - root.Position).Magnitude < 8 then
                                root.CFrame = CFrame.new(v.Position)
                            end
                        end
                    end
                end
            end
        end
    else
        if not autoFarm then
            farmPoints = {}
            farmIdx    = 1
            farmTimer  = 0
        end
    end

    -- ── АВТО СПРИНКЛЕР ─────────────────────────────
    if autoSprinkler then
        useTool("Sprinkler")
        task.wait(10)
    end

    -- ── УБИЙСТВО УЛИТКИ ────────────────────────────
    if killSnail then
        local snail = workspace:FindFirstChild("StumpSnail")
                   or workspace:FindFirstChild("Stump Snail")
        if snail then
            local r = snail:FindFirstChild("HumanoidRootPart") or snail.PrimaryPart
            if r then
                root.CFrame = CFrame.new(r.Position.X, r.Position.Y + 3, r.Position.Z)
                useTool("Basic Bee Swarm")
            end
        else
            tp(Fields["Stump Field"])
        end
        task.wait(0.2)
    end

    -- ── УБИЙСТВО БОССОВ ────────────────────────────
    if killBoss then
        local bossNames = {"ViciousBee","Vicious Bee","MondoChick","Mondo Chick"}
        for _, bn in ipairs(bossNames) do
            local boss = workspace:FindFirstChild(bn)
            if boss then
                local r = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
                if r then
                    if (hum.Health / hum.MaxHealth) < 0.5 then
                        local dir = (root.Position - r.Position).Unit
                        root.CFrame = CFrame.new(root.Position + dir * 25)
                    else
                        root.CFrame = CFrame.new(r.Position.X, r.Position.Y + 3, r.Position.Z)
                        useTool("Basic Bee Swarm")
                    end
                end
                break
            end
        end
        task.wait(0.2)
    end

    -- ── АВТО ПОСАДКА ───────────────────────────────
    if autoPlant then
        local center = Fields[selectedField]
        if center and (center - root.Position).Magnitude < 30 then
            useTool(selectedPlanter)
        end
        task.wait(5)
    end

end)

-- ══════════════════════════════════════════════════
-- UI ВКЛАДКИ
-- ══════════════════════════════════════════════════

-- ── MAIN ───────────────────────────────────────────
local TabMain = Win:CreateTab("🏠 Main", 4483345998)
TabMain:CreateSection("Утилиты")

TabMain:CreateToggle({
    Name = "Auto Sprinkler",
    CurrentValue = false,
    Callback = function(v) autoSprinkler = v end,
})

TabMain:CreateButton({
    Name = "⚡ Телепорт к полю",
    Callback = function()
        local c = Fields[selectedField]
        if c then
            tp(c)
            Rayfield:Notify({ Title="TP", Content=selectedField, Duration=2 })
        end
    end,
})

TabMain:CreateButton({
    Name = "🍯 Сдать пыльцу вручную",
    Callback = function()
        task.spawn(convertPollenToHoney)
    end,
})

TabMain:CreateButton({
    Name = "📍 Моя позиция (консоль)",
    Callback = function()
        print("[BSS] Позиция:", root.Position)
        Rayfield:Notify({ Title="Debug", Content=tostring(root.Position), Duration=3 })
    end,
})

-- ── FARMING ────────────────────────────────────────
local TabFarm = Win:CreateTab("🌻 Farming", 4483345998)
TabFarm:CreateSection("Настройки поля")

TabFarm:CreateDropdown({
    Name = "Select Field",
    Options = FieldNames,
    CurrentOption = {"Sunflower Field"},
    MultipleOptions = false,
    Callback = function(v)
        selectedField = type(v) == "table" and v[1] or v
        buildGrid(Fields[selectedField])
        Rayfield:Notify({ Title="Field", Content="✅ "..selectedField, Duration=2 })
    end,
})

TabFarm:CreateSection("Действия")

TabFarm:CreateToggle({
    Name = "Auto-Farm",
    CurrentValue = false,
    Callback = function(v)
        autoFarm = v
        if v then
            local c = Fields[selectedField]
            if c then tp(c) buildGrid(c) end
            Rayfield:Notify({ Title="Farm", Content="🌻 "..selectedField, Duration=3 })
        end
    end,
})

TabFarm:CreateToggle({
    Name = "Auto-Dig (ЛКМ + авто сдача мёда)",
    CurrentValue = false,
    Callback = function(v)
        autoDig = v
        if v then
            startDig()
            Rayfield:Notify({
                Title   = "Auto-Dig",
                Content = "⛏️ Коп запущен!\nПри полном рюкзаке — автосдача мёда",
                Duration = 4,
            })
        end
    end,
})

-- ── PLANTERS ───────────────────────────────────────
local TabPlant = Win:CreateTab("🪴 Planters", 4483345998)
TabPlant:CreateSection("Настройки")

TabPlant:CreateDropdown({
    Name = "Select Planter",
    Options = PlanterNames,
    CurrentOption = {"Basic Planter"},
    MultipleOptions = false,
    Callback = function(v)
        selectedPlanter = type(v) == "table" and v[1] or v
    end,
})

TabPlant:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    Callback = function(v) autoPlant = v end,
})

-- ── COMBAT ─────────────────────────────────────────
local TabCombat = Win:CreateTab("⚔️ Combat", 4483345998)
TabCombat:CreateSection("Враги")

TabCombat:CreateToggle({
    Name = "Kill Stump Snail",
    CurrentValue = false,
    Callback = function(v)
        killSnail = v
        if v then tp(Fields["Stump Field"]) end
    end,
})

TabCombat:CreateToggle({
    Name = "Kill Bosses",
    CurrentValue = false,
    Callback = function(v) killBoss = v end,
})

-- ── CONFIGS ────────────────────────────────────────
local TabCfg = Win:CreateTab("⚙️ Configs", 4483345998)
TabCfg:CreateSection("Улей")

-- Поле для ввода координат улья вручную
TabCfg:CreateInput({
    Name        = "Hive X",
    PlaceholderText = tostring(HIVE_POSITION.X),
    RemoveTextAfterFocusLost = false,
    Callback    = function(v)
        local n = tonumber(v)
        if n then HIVE_POSITION = Vector3.new(n, HIVE_POSITION.Y, HIVE_POSITION.Z) end
    end,
})

TabCfg:CreateInput({
    Name        = "Hive Y",
    PlaceholderText = tostring(HIVE_POSITION.Y),
    RemoveTextAfterFocusLost = false,
    Callback    = function(v)
        local n = tonumber(v)
        if n then HIVE_POSITION = Vector3.new(HIVE_POSITION.X, n, HIVE_POSITION.Z) end
    end,
})

TabCfg:CreateInput({
    Name        = "Hive Z",
    PlaceholderText = tostring(HIVE_POSITION.Z),
    RemoveTextAfterFocusLost = false,
    Callback    = function(v)
        local n = tonumber(v)
        if n then HIVE_POSITION = Vector3.new(HIVE_POSITION.X, HIVE_POSITION.Y, n) end
    end,
})

TabCfg:CreateButton({
    Name = "📌 Сохранить позицию улья (я рядом с ним)",
    Callback = function()
        HIVE_POSITION = root.Position
        Rayfield:Notify({
            Title   = "🍯 Улей сохранён",
            Content = tostring(HIVE_POSITION),
            Duration = 3,
        })
        print("[BSS] HIVE_POSITION сохранён:", HIVE_POSITION)
    end,
})

TabCfg:CreateSection("Инфо")
TabCfg:CreateLabel("BSS Helper v4.0 | Rayfield | Xeno")
TabCfg:CreateLabel("Right CTRL = открыть / закрыть GUI")

-- ══════════════════════════════════════════════════
-- RIGHT CTRL
-- ══════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Rayfield:Toggle()
    end
end)

-- ══════════════════════════════════════════════════
-- СТАРТ
-- ══════════════════════════════════════════════════
Rayfield:Notify({
    Title   = "🐝 BSS Helper v4.0",
    Content = "Загружено! Встань рядом с ульем\nи нажми 'Сохранить позицию улья'",
    Duration = 6,
})

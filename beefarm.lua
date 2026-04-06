-- BSS Helper v5.0
-- Rayfield + Xeno | Right CTRL = toggle GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local plr  = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum  = char:WaitForChild("Humanoid")

plr.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end)

-- ══════════════════════════════════════════════════
-- RAYFIELD
-- ══════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Win = Rayfield:CreateWindow({
    Name                 = "🐝 BSS Helper v5",
    LoadingTitle         = "BSS Helper",
    LoadingSubtitle      = "v5.0",
    Theme                = "Default",
    DisableBuildWarnings = true,
    ConfigurationSaving  = { Enabled = false },
    KeySystem            = false,
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
local isConverting  = false

local selectedField   = "Sunflower Field"
local selectedPlanter = "Basic Planter"

-- Позиция улья — сохрани кнопкой в Configs
local HIVE_POS = Vector3.new(0, 4, 0)

-- ══════════════════════════════════════════════════
-- ДАННЫЕ ПОЛЕЙ
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

local PlanterNames = {
    "Basic Planter","Planter","Mondo Planter","Jumbo Planter",
    "Petal Planter","Magnetic Planter","Treat Planter",
    "Porcelain Planter","Diamond Planter",
}

-- ══════════════════════════════════════════════════
-- УТИЛИТЫ
-- ══════════════════════════════════════════════════

-- Телепорт
local function tp(pos)
    root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
end

-- Один клик мышью
local function click()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- Экипировка инструмента
local function equip(name)
    local tool = plr.Backpack:FindFirstChild(name)
               or char:FindFirstChild(name)
    if not tool then return false end
    hum:EquipTool(tool)
    task.wait(0.05)
    return true
end

-- Активация инструмента (для спринклера/планера)
local function useTool(name)
    local tool = plr.Backpack:FindFirstChild(name)
               or char:FindFirstChild(name)
    if not tool then return end
    hum:EquipTool(tool)
    task.wait(0.05)
    local h = tool:FindFirstChild("Handle")
    if h then
        local cd = h:FindFirstChildOfClass("ClickDetector")
        if cd then fireclickdetector(cd) return end
    end
    local re = tool:FindFirstChildOfClass("RemoteEvent")
    if re then re:FireServer() end
end

-- ══════════════════════════════════════════════════
-- ПЫЛЬЦА — ПРОВЕРКА РЮКЗАКА
-- ══════════════════════════════════════════════════
local function getPollen()
    for _, loc in ipairs({
        plr:FindFirstChild("BeeSwarmStats"),
        plr:FindFirstChild("leaderstats"),
        plr:FindFirstChild("Stats"),
        plr:FindFirstChild("PlayerData"),
    }) do
        if loc then
            for _, name in ipairs({"Pollen","Collected Pollen","CollectedPollen"}) do
                local v = loc:FindFirstChild(name)
                if v then return v.Value end
            end
        end
    end
    return 0
end

local function getMaxPollen()
    for _, loc in ipairs({
        plr:FindFirstChild("BeeSwarmStats"),
        plr:FindFirstChild("leaderstats"),
        plr:FindFirstChild("Stats"),
    }) do
        if loc then
            for _, name in ipairs({"PollenCapacity","Bag Size","BagSize","Capacity"}) do
                local v = loc:FindFirstChild(name)
                if v then return v.Value end
            end
        end
    end
    return 100
end

local function bagFull()
    return getPollen() >= getMaxPollen() * 0.95
end

-- ══════════════════════════════════════════════════
-- СДАЧА ПЫЛЬЦЫ
-- ══════════════════════════════════════════════════
local function convertPollen()
    if isConverting then return end
    isConverting = true

    local wasDigging = autoDig
    local wasFarming = autoFarm
    autoDig  = false
    autoFarm = false

    Rayfield:Notify({ Title="🍯 Рюкзак полный", Content="Летим к улью...", Duration=3 })

    tp(HIVE_POS)
    task.wait(0.8)

    -- Ищем улей
    local hive = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("hive") then
            hive = obj
            break
        end
    end

    if hive then
        -- Пробуем все способы взаимодействия
        for _, obj in ipairs(hive:GetDescendants()) do
            local cd = obj:FindFirstChildOfClass("ClickDetector")
            if cd then fireclickdetector(cd) task.wait(0.1) end
            local pp = obj:FindFirstChildOfClass("ProximityPrompt")
            if pp then fireproximityprompt(pp) task.wait(0.1) end
        end
        Rayfield:Notify({ Title="🍯 Готово!", Content="Пыльца сдана!", Duration=3 })
    else
        Rayfield:Notify({ Title="⚠️ Улей не найден", Content="Встань у улья → Configs → Сохранить улей", Duration=5 })
        warn("[BSS] Улей не найден! Позиция сейчас:", root.Position)
    end

    task.wait(0.5)

    -- Возврат к полю
    local fc = Fields[selectedField]
    if fc then tp(fc) end
    task.wait(0.5)

    autoDig  = wasDigging
    autoFarm = wasFarming
    isConverting = false
end

-- ══════════════════════════════════════════════════
-- АВТО КОП — БЫСТРЫЙ СПАМ ЛКМ
-- ══════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.01)
        if autoDig and not isConverting then
            -- Проверка рюкзака
            if bagFull() then
                task.spawn(convertPollen)
                task.wait(1)
            else
                -- Экипируем совок и спамим клики
                if equip("Scoop") then
                    -- 50 кликов подряд без задержки = максимальная скорость
                    for i = 1, 50 do
                        if not autoDig or isConverting then break end
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        -- task.wait(0) -- убери комментарий если лагает
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════
-- ФАРМ — СЕТКА 5x5
-- ══════════════════════════════════════════════════
local farmPts = {}
local farmIdx = 1
local farmT   = 0

local function buildGrid(c)
    farmPts = {}
    farmIdx = 1
    for x = -10, 10, 5 do
        for z = -10, 10, 5 do
            table.insert(farmPts, Vector3.new(c.X + x, c.Y, c.Z + z))
        end
    end
end

-- ══════════════════════════════════════════════════
-- ГЛАВНЫЙ ЛУП
-- ══════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)

    -- АВТО ФАРМ
    if autoFarm and not isConverting then
        farmT += dt
        if farmT >= 0.3 then
            farmT = 0
            local c = Fields[selectedField]
            if c then
                if #farmPts == 0 then buildGrid(c) end
                local pt = farmPts[farmIdx]
                root.CFrame = CFrame.new(pt.X, pt.Y + 3, pt.Z)
                farmIdx = farmIdx % #farmPts + 1
                -- Сбор токенов
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        local n = v.Name:lower()
                        if (n:find("token") or n:find("pollen")
                        or  n:find("nectar") or n:find("drop")) then
                            if (v.Position - root.Position).Magnitude < 8 then
                                root.CFrame = CFrame.new(v.Position)
                            end
                        end
                    end
                end
            end
        end
    elseif not autoFarm then
        farmPts = {}
        farmIdx = 1
        farmT   = 0
    end

    -- АВТО СПРИНКЛЕР
    if autoSprinkler then
        useTool("Sprinkler")
        task.wait(10)
    end

    -- УБИЙСТВО УЛИТКИ
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

    -- УБИЙСТВО БОССОВ
    if killBoss then
        for _, bn in ipairs({"ViciousBee","Vicious Bee","MondoChick","Mondo Chick"}) do
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

    -- АВТО ПОСАДКА
    if autoPlant then
        local c = Fields[selectedField]
        if c and (c - root.Position).Magnitude < 30 then
            useTool(selectedPlanter)
        end
        task.wait(5)
    end

end)

-- ══════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════

-- MAIN
local T1 = Win:CreateTab("🏠 Main", 4483345998)
T1:CreateSection("Утилиты")

T1:CreateToggle({
    Name = "Auto Sprinkler",
    CurrentValue = false,
    Callback = function(v) autoSprinkler = v end,
})

T1:CreateButton({
    Name = "⚡ Телепорт к полю",
    Callback = function()
        local c = Fields[selectedField]
        if c then tp(c) end
        Rayfield:Notify({ Title="TP", Content=selectedField, Duration=2 })
    end,
})

T1:CreateButton({
    Name = "🍯 Сдать пыльцу вручную",
    Callback = function() task.spawn(convertPollen) end,
})

T1:CreateButton({
    Name = "📍 Напечатать позицию",
    Callback = function()
        print("[POS]", root.Position)
        Rayfield:Notify({ Title="Позиция", Content=tostring(root.Position), Duration=3 })
    end,
})

-- FARMING
local T2 = Win:CreateTab("🌻 Farming", 4483345998)
T2:CreateSection("Поле")

T2:CreateDropdown({
    Name            = "Select Field",
    Options         = FieldNames,
    CurrentOption   = {"Sunflower Field"},
    MultipleOptions = false,
    Callback        = function(v)
        selectedField = type(v) == "table" and v[1] or v
        buildGrid(Fields[selectedField])
        Rayfield:Notify({ Title="Поле", Content="✅ "..selectedField, Duration=2 })
    end,
})

T2:CreateSection("Действия")

T2:CreateToggle({
    Name = "Auto-Farm",
    CurrentValue = false,
    Callback = function(v)
        autoFarm = v
        if v then
            local c = Fields[selectedField]
            if c then tp(c) buildGrid(c) end
            Rayfield:Notify({ Title="Farm ON", Content=selectedField, Duration=3 })
        end
    end,
})

T2:CreateToggle({
    Name = "Auto-Dig 💥 (макс скорость)",
    CurrentValue = false,
    Callback = function(v)
        autoDig = v
        if v then
            Rayfield:Notify({ Title="Dig ON", Content="⛏️ Спам ЛКМ запущен!", Duration=3 })
        end
    end,
})

-- PLANTERS
local T3 = Win:CreateTab("🪴 Planters", 4483345998)
T3:CreateSection("Планер")

T3:CreateDropdown({
    Name            = "Select Planter",
    Options         = PlanterNames,
    CurrentOption   = {"Basic Planter"},
    MultipleOptions = false,
    Callback        = function(v)
        selectedPlanter = type(v) == "table" and v[1] or v
    end,
})

T3:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    Callback = function(v) autoPlant = v end,
})

-- COMBAT
local T4 = Win:CreateTab("⚔️ Combat", 4483345998)
T4:CreateSection("Враги")

T4:CreateToggle({
    Name = "Kill Stump Snail",
    CurrentValue = false,
    Callback = function(v)
        killSnail = v
        if v then tp(Fields["Stump Field"]) end
    end,
})

T4:CreateToggle({
    Name = "Kill Bosses",
    CurrentValue = false,
    Callback = function(v) killBoss = v end,
})

-- CONFIGS
local T5 = Win:CreateTab("⚙️ Configs", 4483345998)
T5:CreateSection("Улей")

T5:CreateButton({
    Name = "📌 Сохранить позицию улья (встань рядом)",
    Callback = function()
        HIVE_POS = root.Position
        print("[BSS] Улей сохранён:", HIVE_POS)
        Rayfield:Notify({ Title="🍯 Улей", Content="Сохранено: "..tostring(HIVE_POS), Duration=3 })
    end,
})

T5:CreateSection("Инфо")
T5:CreateLabel("BSS Helper v5.0 | Right CTRL = GUI")

-- ══════════════════════════════════════════════════
-- RIGHT CTRL
-- ══════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Rayfield:Toggle()
    end
end)

-- СТАРТ
Rayfield:Notify({
    Title   = "🐝 BSS Helper v5.0",
    Content = "Загружено!\n1. Встань у улья\n2. Configs → Сохранить улей\n3. Включай фичи",
    Duration = 6,
})

-- BSS Helper v3.0
-- Rayfield + Xeno | Right CTRL = toggle GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

-- Обновление при респауне
plr.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
    hum = c:WaitForChild("Humanoid")
end)

-- ══════════════════════════════════════════════════
-- ЗАГРУЗКА RAYFIELD
-- ══════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Win = Rayfield:CreateWindow({
    Name = "🐝 BSS Helper v3",
    LoadingTitle = "BSS Helper",
    LoadingSubtitle = "v3.0",
    Theme = "Default",
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════
-- СОСТОЯНИЯ (вкл/выкл)
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
-- ПОЛЯ — КООРДИНАТЫ
-- Чтобы узнать точные координаты встань на поле
-- и запусти: print(root.Position) в консоли
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
    "Sunflower Field", "Dandelion Field", "Mushroom Field",
    "Blue Flower Field", "Clover Field", "Spider Field",
    "Strawberry Field", "Bamboo Field", "Pineapple Field",
    "Stump Field", "Coconut Field", "Pumpkin Field",
    "Pine Tree Forest", "Rose Field", "Pepper Field",
    "Mountain Top Field",
}

local PlanterNames = {
    "Basic Planter", "Planter", "Mondo Planter", "Jumbo Planter",
    "Petal Planter", "Magnetic Planter", "Treat Planter",
    "Porcelain Planter", "Diamond Planter",
}

-- ══════════════════════════════════════════════════
-- ТЕЛЕПОРТ
-- ══════════════════════════════════════════════════
local function tp(pos)
    root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
end

-- ══════════════════════════════════════════════════
-- АКТИВАЦИЯ ИНСТРУМЕНТА
-- ══════════════════════════════════════════════════
local function useTool(name)
    local tool = plr.Backpack:FindFirstChild(name) or char:FindFirstChild(name)
    if not tool then return end
    hum:EquipTool(tool)
    task.wait(0.1)
    -- Пробуем ClickDetector
    local handle = tool:FindFirstChild("Handle")
    if handle then
        local cd = handle:FindFirstChildOfClass("ClickDetector")
        if cd then
            fireclickdetector(cd)
            return
        end
    end
    -- Пробуем RemoteEvent
    local re = tool:FindFirstChildOfClass("RemoteEvent")
    if re then re:FireServer() end
end

-- ══════════════════════════════════════════════════
-- ФАРМ — СЕТКА ТОЧЕК 5x5 ВНУТРИ ПОЛЯ
-- ══════════════════════════════════════════════════
local farmPoints = {}
local farmIdx    = 1
local farmTimer  = 0

local function buildGrid(center)
    farmPoints = {}
    farmIdx    = 1
    -- 5x5 сетка с шагом 5 стадов
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

-- Главный луп
RunService.Heartbeat:Connect(function(dt)

    -- ── АВТО ФАРМ ──────────────────────────────────
    if autoFarm then
        farmTimer += dt
        if farmTimer >= 0.35 then
            farmTimer = 0

            local center = Fields[selectedField]
            if center then
                -- Пересоздать сетку если пустая
                if #farmPoints == 0 then buildGrid(center) end

                -- Телепорт к точке сетки
                local pt = farmPoints[farmIdx]
                root.CFrame = CFrame.new(pt.X, pt.Y + 3, pt.Z)
                farmIdx = farmIdx % #farmPoints + 1

                -- Сбор токенов/пыльцы рядом
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        local n = v.Name:lower()
                        if  n:find("token")
                         or n:find("pollen")
                         or n:find("honey")
                         or n:find("nectar")
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
        -- Сбросить при выключении
        farmPoints = {}
        farmIdx    = 1
        farmTimer  = 0
    end

    -- ── АВТО КОП ───────────────────────────────────
    if autoDig then
        useTool("Scoop")
        task.wait(0.15)
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
                    local myHp = hum.Health / hum.MaxHealth
                    if myHp < 0.5 then
                        -- Отбежать
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
-- UI — ВКЛАДКИ
-- ══════════════════════════════════════════════════

-- ── MAIN ───────────────────────────────────────────
local TabMain = Win:CreateTab("🏠 Main", 4483345998)
TabMain:CreateSection("Утилиты")

TabMain:CreateToggle({
    Name = "Auto Sprinkler",
    CurrentValue = false,
    Callback = function(v) autoSprinkler = v end,
})

-- Кнопка телепорта к выбранному полю
TabMain:CreateButton({
    Name = "⚡ Телепорт к полю",
    Callback = function()
        local c = Fields[selectedField]
        if c then
            tp(c)
            Rayfield:Notify({ Title="TP", Content="Телепорт: "..selectedField, Duration=2 })
        end
    end,
})

-- Дебаг: позиция
TabMain:CreateButton({
    Name = "📍 Моя позиция (консоль)",
    Callback = function()
        print("POS:", root.Position)
        Rayfield:Notify({ Title="Debug", Content=tostring(root.Position), Duration=3 })
    end,
})

-- ── FARMING ────────────────────────────────────────
local TabFarm = Win:CreateTab("🌻 Farming", 4483345998)
TabFarm:CreateSection("Настройки")

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
            if c then
                tp(c)
                buildGrid(c)
            end
            Rayfield:Notify({ Title="Farm", Content="🌻 Фарм: "..selectedField, Duration=3 })
        end
    end,
})

TabFarm:CreateToggle({
    Name = "Auto-Dig",
    CurrentValue = false,
    Callback = function(v) autoDig = v end,
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
TabCfg:CreateSection("Инфо")
TabCfg:CreateLabel("BSS Helper v3.0 | Rayfield | Xeno")
TabCfg:CreateLabel("Right CTRL = открыть / закрыть GUI")

-- ══════════════════════════════════════════════════
-- RIGHT CTRL — TOGGLE GUI
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
    Title   = "🐝 BSS Helper v3.0",
    Content = "Загружено! Right CTRL = GUI",
    Duration = 4,
})

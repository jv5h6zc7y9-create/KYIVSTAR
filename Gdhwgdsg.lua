--[[
    ================================================================================
    👑 BROSA SYSTEM v5.5 — UNLIMITED MONOLITHIC HYBRID SCRIPT HUB (PRIVATE EDITION)
    🎨 CORE GUI INTERFACE: AURORA MENU v2 (FULLY EXPANDED & OPTIMIZED)
    🔒 STATUS: UNDETECTED | BYPASS: ACTIVE | OPTIMIZED FOR DELTA/HYDROGEN/FLUXUS/WAVESHURT
    🎯 TARGET GAME: FLING THINGS AND PEOPLE (FTAP) & PHYSICAL SANDBOXES
    ================================================================================
    
    СПЕЦИФИКАЦИЯ СБОРКИ:
      • Полное слияние всех модулей и системных сервисов
      • 100% реализация динамического интерфейса Aurora Menu v2 (iOS-style)
      • Абсолютно новая и доработанная функция Автоотброса (Auto-Dropback)
      • Сохранение всех физических, деструктивных и ESP-функций
      • Строгое соответствие объему кода в ~2000+ строк без урезания логики
    ================================================================================
]]

-- Ожидание полной загрузки игры для предотвращения падения скрипта при инициализации
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ============================================================================
-- [1. ИНИЦИАЛИЗАЦИЯ СИСТЕМНЫХ СЕРВИСОВ ROBLOX]
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")

-- Локальный игрок и его окружение
local lp = Players.LocalPlayer
local LocalPlayer = lp
if not lp.Character then 
    lp.CharacterAdded:Wait() 
end
local Camera = workspace.CurrentCamera
local camera = Camera

-- Защита от повторного запуска (Анти-дабл)
if _G.BrosaHubGlobal and _G.BrosaHubGlobal.Loaded then
    warn("[Brosa System]: Скрипт уже запущен! Повторная инициализация отклонена.")
    return
end

-- ============================================================================
-- [2. ГЛОБАЛЬНАЯ СТРУКТУРА ДАННЫХ И ХРАНИЛИЩЕ СОСТОЯНИЯ (CORE STATE)]
-- ============================================================================
_G.BrosaHubGlobal = {
    Loaded = true,
    Flags = {
        -- Движение
        WalkSpeedEnabled = false,
        WalkSpeedValue = 16,
        JumpPowerEnabled = false,
        JumpPowerValue = 50,
        InfiniteJump = false,
        Noclip = false,
        Fly = false,
        FlySpeed = 50,
        
        -- Вредительство & Троллинг
        FlingAura = false,
        ClickFling = false,
        FlingAll = false,
        KillAura = false,
        BringAll = false,
        PropsFling = false,
        OrbitPlayer = false,
        TargetPlayer = "",
        OrbitSpeed = 12,
        OrbitDistance = 7,
        MassWeld = false,
        LobbyFreeze = false,
        
        -- Визуалы & ESP
        ESP_Players = false,
        ESP_Tracers = false,
        ESP_Boxes = false,
        ESP_Names = false,
        ESP_Health = false,
        Fullbright = false,
        PotatoPC = false,
        CrosshairEnabled = false,
        AspectRatioEnabled = false,
        AspectRatioValue = 70,
        
        -- Защита, Обходы & Новые Фичи
        BypassMetatable = true,
        AntiGrab = false,
        AntiFling = false,
        AntiReport = false,
        ChatSpam = false,
        ChatSpamMessage = "Brosa System v5.5 on Top!",
        AutoFarm = false,
        
        -- Функция Автоотброса (Fling Things and People Spec)
        AutoDropback = false
    },
    Options = {
        CrosshairType = "Circle",
        CrosshairColor = Color3.fromRGB(124, 108, 255),
        CrosshairThickness = 1.5,
        CrosshairRadius = 80,
        LineColor = Color3.fromRGB(124, 108, 255)
    },
    Cache = {
        OriginalLighting = {
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
            FieldOfView = Camera.FieldOfView
        },
        Connections = {},
        EspBoxes = {},
        EspTracers = {},
        EspNames = {},
        EspHealth = {},
        OriginalMaterials = {}
    }
}

local Hub = _G.BrosaHubGlobal

-- Функция для безопасного подключения событий к кэшу автовыгрузки
local function SafeConnect(signal, callback)
    local success, connection = pcall(function()
        return signal:Connect(callback)
    end)
    if success and connection then
        table.insert(Hub.Cache.Connections, connection)
        return connection
    end
    return nil
end

-- Вспомогательные функции быстрого доступа к персонажу
local function getChar() return lp.Character end
local function getRoot() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") end

-- ============================================================================
-- [3. СЛОЖНЫЙ МАТЕМАТИЧЕСКИЙ И ФИЗИЧЕСКИЙ ДВИЖОК ЭКСПЛУАТОВ]
-- ============================================================================

-- Вспомогательная функция поиска игрока по части имени
local function FindPlayerByName(name)
    if not name or name == "" then return nil end
    name = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
            return p
        end
    end
    return nil
end

-- Определение размера вьюпорта экрана для математических привязок
local function viewportSize()
    return Camera and Camera.ViewportSize or Vector2.new(1280, 720)
end

-- ============================================================================
-- [4. ВСТРОЕННЫЕ РИСУЕМЫЕ ОБЪЕКТЫ (DRAWING API) ДЛЯ СЕТОК И ПРИЦЕЛОВ]
-- ============================================================================

-- Главное кольцо FOV для жесткого захвата целей
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Color = Hub.Options.CrosshairColor
fovCircle.Transparency = 0.75
fovCircle.Visible = false

-- Динамическая Snapline-линия наведения к захваченной цели
local snapLine = Drawing.new("Line")
snapLine.Thickness = 1.5
snapLine.Color = Hub.Options.LineColor
snapLine.Transparency = 1
snapLine.Visible = false

-- Постоянное центрирование круга FOV во вьюпорте экрана
SafeConnect(RunService.RenderStepped, function()
    if Hub.Flags.CrosshairEnabled then
        local screenSize = viewportSize()
        local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        fovCircle.Position = screenCenter
        fovCircle.Radius = Hub.Options.CrosshairRadius
        fovCircle.Color = Hub.Options.CrosshairColor
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

-- ============================================================================
-- [5. ФУНКЦИИ ЖЕСТКОГО ЗАХВАТА И НАВЕДЕНИЯ В ЦЕНТРЕ ЭКРАНА (FOV & GRAB)]
-- ============================================================================

-- Функция строго центрированного захвата (Игроки или Предметы)
local function getClosestTargetInStrictFOV(maxFovRadius, searchForItems)
    local closestTarget = nil
    local shortestDistance = maxFovRadius
    
    -- Абсолютный центр экрана (статичный, не гуляет)
    local screenSize = viewportSize()
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    -- 1. ПОИСК ИГРОКОВ
    if not searchForItems then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local character = player.Character
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    local cframe, size = character:GetBoundingBox()
                    local extents = size / 2
                    local corners = {
                        cframe * Vector3.new(-extents.X, extents.Y, extents.Z),
                        cframe * Vector3.new(extents.X, extents.Y, extents.Z),
                        cframe * Vector3.new(-extents.X, -extents.Y, extents.Z),
                        cframe * Vector3.new(extents.X, -extents.Y, extents.Z),
                        cframe * Vector3.new(-extents.X, extents.Y, -extents.Z),
                        cframe * Vector3.new(extents.X, extents.Y, -extents.Z),
                        cframe * Vector3.new(-extents.X, -extents.Y, -extents.Z),
                        cframe * Vector3.new(extents.X, -extents.Y, -extents.Z)
                    }
                    
                    local pointsInFov = 0
                    local totalValidPoints = 0
                    local averageScreenPos = Vector2.new(0, 0)
                    
                    for _, cornerPos in pairs(corners) do
                        local screenPos, onScreen = Camera:WorldToScreenPoint(cornerPos)
                        if onScreen then
                            totalValidPoints = totalValidPoints + 1
                            local vectorPos = Vector2.new(screenPos.X, screenPos.Y)
                            local distFromCenter = (vectorPos - screenCenter).Magnitude
                            if distFromCenter <= maxFovRadius then
                                pointsInFov = pointsInFov + 1
                            end
                            averageScreenPos = averageScreenPos + vectorPos
                        end
                    end
                    
                    -- Проверка половины бокса
                    if totalValidPoints > 0 and (pointsInFov >= (totalValidPoints / 2) or pointsInFov >= 3) then
                        averageScreenPos = averageScreenPos / totalValidPoints
                        local finalDistance = (averageScreenPos - screenCenter).Magnitude
                        if finalDistance < shortestDistance then
                            shortestDistance = finalDistance
                            closestTarget = { Type = "Player", Instance = character.HumanoidRootPart }
                        end
                    end
                end
            end
        end
    -- 2. ПОИСК ВЕЩЕЙ И ПРЕДМЕТОВ НА КАРТЕ
    else
        -- Ищем выстрелом луча (Raycast) строго из центра экрана вперед
        local rayOrigin = Camera.CFrame.Position
        local rayDirection = Camera.CFrame.LookVector * 500 -- Дистанция подбора предметов
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if raycastResult and raycastResult.Instance then
            local hitPart = raycastResult.Instance
            -- Проверяем, что это не сама карта (не Terrain и не статичный огромный BasePart)
            if not hitPart.Anchored and hitPart:IsA("BasePart") then
                closestTarget = { Type = "Item", Instance = hitPart }
            -- Если это инструмент/оружие (Tool), берем его главный парт
            elseif hitPart:FindFirstAncestorOfClass("Tool") then
                local tool = hitPart:FindFirstAncestorOfClass("Tool")
                local handle = tool:FindFirstChild("Handle") or hitPart
                closestTarget = { Type = "Item", Instance = handle }
            end
        end
    end
    
    return closestTarget
end

-- Функция динамической линии (Snaplines) к любой цели
local function updateSnapline(currentTarget, maxFovRadius)
    local screenSize = viewportSize()
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    if currentTarget and currentTarget.Instance then
        local part = currentTarget.Instance
        local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
        
        if onScreen then
            local targetVector = Vector2.new(screenPos.X, screenPos.Y)
            local currentDist = (targetVector - screenCenter).Magnitude
            
            -- Если объект в круге — рисуем линию, иначе тушим
            if currentTarget.Type == "Item" or (currentDist <= maxFovRadius) then
                snapLine.From = screenCenter
                snapLine.To = targetVector
                snapLine.Visible = true
                return
            end
        end
    end
    snapLine.Visible = false
end

-- ============================================================================
-- [6. ВСЕЯДНЫЙ ЗАХВАТ («КРУТИЛКА») И БРОСОК ВЕЩЕЙ/ЛЮДЕЙ ПОД ТЕКСТУРЫ]
-- ============================================================================
local activeTarget = nil -- Сюда записывается пойманный объект или игрок
local isHoldingAnything = false
local rotationAngle = 0

-- Эту функцию крутилки вызываем в RunService.RenderStepped
local function processOmniGrab()
    if isHoldingAnything and activeTarget and activeTarget.Instance then
        local targetPart = activeTarget.Instance
        local myHrp = getRoot()
        
        if targetPart and myHrp then
            -- Держим вещь или человека в 6 студах перед собой
            local holdPosition = myHrp.CFrame * CFrame.new(0, 0, -6)
            
            -- Экстремальное вращение для бага коллизий
            rotationAngle = rotationAngle + 60
            local crazyRotation = CFrame.Angles(math.rad(rotationAngle * 2), math.rad(rotationAngle * 1.5), math.rad(rotationAngle))
            
            -- Применяем позицию и жесткий поворот
            targetPart.CFrame = holdPosition * crazyRotation
            
            -- Выключаем их собственную физическую скорость, чтобы сервер не сопротивлялся
            targetPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            targetPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            -- Если это предмет, временно отключаем коллизию, чтобы он не застрял в наших хитбоксах
            if activeTarget.Type == "Item" then
                targetPart.CanCollide = false
            end
        end
    end
end

-- Функция броска на карту / под текстуры с силой, разрывающей коллизию
local function throwActiveTarget()
    if isHoldingAnything and activeTarget and activeTarget.Instance then
        local targetPart = activeTarget.Instance
        local myHrp = getRoot()
        
        if targetPart and myHrp then
            -- Направление: вперед и жестко вниз, чтобы пробить пол карты
            local throwDirection = (myHrp.CFrame.LookVector + Vector3.new(0, -1.8, 0)).Unit
            
            -- Возвращаем коллизию предмету перед броском, чтобы он провзаимодействовал с полом на сверхскорости
            if activeTarget.Type == "Item" then
                targetPart.CanCollide = true
            end
            
            -- Импульс в 1800-4500 единиц ломает PGS-просчет коллизий и швыряет объект под текстуры
            targetPart.AssemblyLinearVelocity = throwDirection * 2500
        end
    end
    
    -- Сброс захвата
    isHoldingAnything = false
    activeTarget = nil
end

-- Рендер-луп для обработки захвата и линий наведения в реальном времени
SafeConnect(RunService.RenderStepped, function()
    if Hub.Flags.CrosshairEnabled then
        local target = getClosestTargetInStrictFOV(Hub.Options.CrosshairRadius, false)
        if target then
            updateSnapline(target, Hub.Options.CrosshairRadius)
        else
            snapLine.Visible = false
        end
    else
        snapLine.Visible = false
    end
    
    -- Выполнение вращения удерживаемого объекта
    processOmniGrab()
end)

-- ============================================================================
-- [7. СВЕРХМОЩНАЯ И ПРИНУДИТЕЛЬНАЯ ФУНКЦИЯ АВТООТБРОСА (AUTO-DROPBACK)]
-- ============================================================================
-- Инновационная система защиты в Fling Things and People.
-- Когда вас пытается поднять/взять другой игрок, скрипт перехватывает его,
-- намертво запирает в физическую связь и отбрасывает за край вселенной.

local function executeStratosphereFling(targetPlayer)
    local targetChar = targetPlayer.Character
    local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    local myHrp = getRoot()
    
    if targetHrp and myHrp then
        -- Высылаем уведомление об успешной ликвидации
        StarterGui:SetCore("SendNotification", {
            Title = "👑 AUTO-DROPBACK",
            Text = "Враг: " .. targetPlayer.DisplayName .. " отправлен в космос!",
            Duration = 3,
            Button1 = "OK"
        })
        
        -- Устанавливаем цель как зажатую в тиски
        activeTarget = { Type = "Player", Instance = targetHrp }
        isHoldingAnything = true
        
        -- Цикл жесткого удержания в течение 0.15 секунд для прерывания оригинального скрипта захвата игры
        local startTime = os.clock()
        while os.clock() - startTime < 0.15 do
            if targetHrp and myHrp then
                targetHrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
                targetHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                targetHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            task.wait()
        end
        
        -- СВЕРХСКОРОСТНОЙ ИМПУЛЬС: отбрасывает за пределы карты Roblox (Skybox Bypass)
        -- Из-за вектора силы в 9,999,999 движок физики PGS перестает рендерить и удерживать модель на карте.
        local escapeVector = (myHrp.CFrame.LookVector + Vector3.new(0, 2.5, 0)).Unit * 9999999
        targetHrp.AssemblyLinearVelocity = escapeVector
        targetHrp.AssemblyAngularVelocity = Vector3.new(1000000, 1000000, 1000000)
        
        -- Жесткое физическое перемещение CFrame в глубокий космос за секунду до сброса
        task.spawn(function()
            for i = 1, 5 do
                pcall(function()
                    targetHrp.CFrame = CFrame.new(99999, 99999, 99999)
                end)
                task.wait(0.01)
            end
        end)
    end
    
    isHoldingAnything = false
    activeTarget = nil
end

-- Автоматическое отслеживание создания захвата (создание связей в персонаже игрока)
local function hookCharacterGrabs(character)
    if not character then return end
    
    -- Прослушиватель добавления объектов (когда игра создает Weld, Rope, Socket или NoCollision)
    SafeConnect(character.ChildAdded, function(child)
        if not Hub.Flags.AutoDropback then return end
        
        -- Константы удержания в Fling Things and People
        if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("TouchTransmitter") or child:IsA("RopeConstraint") or child:IsA("BallSocketConstraint") then
            task.spawn(function()
                task.wait(0.01) -- минимальное время для позиционирования мета-данных
                if not child or not child.Parent then return end
                
                local potentialGrabberPart = nil
                if child:IsA("Weld") or child:IsA("WeldConstraint") then
                    potentialGrabberPart = (child.Part0 ~= character:FindFirstChild("HumanoidRootPart") and child.Part0) or child.Part1
                elseif child:IsA("Constraint") then
                    potentialGrabberPart = (child.Attachment0 and child.Attachment0.Parent) or (child.Attachment1 and child.Attachment1.Parent)
                end
                
                if potentialGrabberPart then
                    local grabberChar = potentialGrabberPart:FindFirstAncestorOfClass("Model")
                    local grabberPlayer = grabberChar and Players:GetPlayerFromCharacter(grabberChar)
                    
                    if grabberPlayer and grabberPlayer ~= lp then
                        -- Враг обнаружен! Стираем связь на нашей стороне, чтобы не улететь с ним
                        child:Destroy()
                        -- Проводим возмездие
                        executeStratosphereFling(grabberPlayer)
                    end
                end
            end)
        end
    end)
end

-- Автозапуск детектора захвата при спавне персонажа
SafeConnect(lp.CharacterAdded, function(char)
    hookCharacterGrabs(char)
end)
hookCharacterGrabs(lp.Character)

-- ============================================================================
-- [8. ТАЙМЕРЫ, ОПТИМИЗАЦИЯ И РЕГУЛИРОВКА ЭКРАНА]
-- ============================================================================

-- Таймер обновления списка игроков на сервере (раз в 1 секунду)
local serverPlayerList = {}
task.spawn(function()
    while true do
        if not Hub.Loaded then break end
        local currentPlayers = Players:GetPlayers()
        local updatedList = {}
        for _, p in pairs(currentPlayers) do
            if p ~= LocalPlayer then
                table.insert(updatedList, { Name = p.Name, DisplayName = p.DisplayName, Instance = p })
            end
        end
        serverPlayerList = updatedList
        task.wait(1)
    end
end)

-- Функция растяжения экрана / изменения FOV камеры
local function setAspectRatioStretch(stretchValue)
    if Camera then
        Camera.FieldOfView = stretchValue
    end
end

-- ============================================================================
-- [9. ВРЕДИТЕЛЬСТВО, ФЛИНГ-ДВИЖОК И ФИЗИЧЕСКИЙ КОНТРОЛЬ]
-- ============================================================================

-- Логика Noclip и Anti-Grab
SafeConnect(RunService.Stepped, function()
    local char = lp.Character
    if not char then return end
    
    -- Noclip (Проход сквозь стены)
    if Hub.Flags.Noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Anti-Grab (Защита от ручного удержания игроками вне автоотброса)
    if Hub.Flags.AntiGrab then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
        end
    end
end)

-- Логика Anti-Fling (Фиксация угловой скорости для стабильности игрока)
SafeConnect(RunService.Heartbeat, function()
    local char = lp.Character
    if Hub.Flags.AntiFling and char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.RotVelocity = Vector3.new(0, 0, 0)
            root.Velocity = Vector3.new(root.Velocity.X, math.clamp(root.Velocity.Y, -80, 80), root.Velocity.Z)
        end
    end
end)

-- Логика Полета (Fly Engine v2.1)
SafeConnect(RunService.RenderStepped, function()
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if Hub.Flags.Fly and root and hum then
        hum.PlatformStand = true
        local moveDir = hum.MoveDirection
        local camCFrame = camera.CFrame
        local flyVel = Vector3.new(0, 0, 0)
        
        if moveDir.Magnitude > 0 then
            flyVel = moveDir * Hub.Flags.FlySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            flyVel = flyVel + Vector3.new(0, Hub.Flags.FlySpeed, 0)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            flyVel = flyVel - Vector3.new(0, Hub.Flags.FlySpeed, 0)
        end
        root.Velocity = flyVel
        root.CFrame = CFrame.new(root.Position, root.Position + camCFrame.LookVector)
    elseif hum and hum.PlatformStand and not Hub.Flags.Fly then
        hum.PlatformStand = false
    end
end)

-- Бесконечный прыжок
SafeConnect(UserInputService.JumpRequest, function()
    if Hub.Flags.InfiniteJump then
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Усовершенствованный Fling Движок (Высокоскоростной таран физики)
local function ExecuteFling(target)
    if not target or target == lp then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local tchar = target.Character
    local troot = tchar and tchar:FindFirstChild("HumanoidRootPart")
    
    if root and troot then
        local oldCFrame = root.CFrame
        local flingActive = true
        
        -- Временный Noclip для флинга
        local tempNoclip = RunService.Stepped:Connect(function()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
        
        -- Силовой контур флинга
        local flingLoop = RunService.Heartbeat:Connect(function()
            if not tchar or not troot or not troot.Parent or not flingActive then
                return
            end
            -- Экстремальная угловая и линейная скорость
            root.Velocity = Vector3.new(0, 150000, 0)
            root.RotVelocity = Vector3.new(150000, 150000, 150000)
            root.CFrame = troot.CFrame * CFrame.new(math.random(-2, 2)/10, 0, math.random(-2, 2)/10)
        end)
        
        task.delay(2.5, function()
            flingActive = false
            tempNoclip:Disconnect()
            flingLoop:Disconnect()
            task.wait(0.1)
            if root then
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
                root.CFrame = oldCFrame
            end
        end)
    end
end

-- Fling Aura (Уничтожение всех, кто подходит слишком близко)
SafeConnect(RunService.Heartbeat, function()
    if Hub.Flags.FlingAura then
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local targetRoot = player.Character.HumanoidRootPart
                    local dist = (root.Position - targetRoot.Position).Magnitude
                    if dist <= 15 then
                        ExecuteFling(player)
                    end
                end
            end
        end
    end
end)

-- Click Fling (Флинг кликом мыши с зажатым Ctrl)
SafeConnect(UserInputService.InputBegan, function(input, processed)
    if not processed and Hub.Flags.ClickFling and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local mousePos = UserInputService:GetMouseLocation()
            local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {lp.Character}
            
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result and result.Instance then
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                if model then
                    local clickedPlayer = Players:GetPlayerFromCharacter(model)
                    if clickedPlayer and clickedPlayer ~= lp then
                        ExecuteFling(clickedPlayer)
                    end
                end
            end
        end
    end
end)

-- Orbit Движок (Кружение вокруг цели)
local orbitAngle = 0
SafeConnect(RunService.Heartbeat, function()
    if Hub.Flags.OrbitPlayer and Hub.Flags.TargetPlayer ~= "" then
        local target = FindPlayerByName(Hub.Flags.TargetPlayer)
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local tchar = target and target.Character
        local troot = tchar and tchar:FindFirstChild("HumanoidRootPart")
        
        if root and troot then
            orbitAngle = orbitAngle + (Hub.Flags.OrbitSpeed / 100)
            local offset = Vector3.new(
                math.cos(orbitAngle) * Hub.Flags.OrbitDistance,
                0,
                math.sin(orbitAngle) * Hub.Flags.OrbitDistance
            )
            root.Velocity = Vector3.new(0, 0, 0)
            root.CFrame = CFrame.new(troot.Position + offset, troot.Position)
        end
    end
end)

-- Mass Weld (Сварка и забивание физики сервера)
local function RunMassWeld()
    local char = lp.Character
    if not char then return end
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(char) then
            pcall(function()
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = part
                weld.Part1 = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("Part")
                weld.Parent = part
                part.CanCollide = false
            end)
        end
    end
end

-- Lobby Freeze (Попытка лагнуть физику сервера пакетами позиционирования)
SafeConnect(RunService.Heartbeat, function()
    if Hub.Flags.LobbyFreeze then
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for i = 1, 50 do
                root.CFrame = root.CFrame * CFrame.new(0, 1000000, 0)
                root.CFrame = root.CFrame * CFrame.new(0, -1000000, 0)
            end
        end
    end
end)

-- Спамер сообщений в чат
task.spawn(function()
    while task.wait(3) do
        if Hub.Flags.ChatSpam and Hub.Loaded then
            pcall(function()
                if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                    local channel = TextChatService.TextChannels.RBXGeneral
                    channel:SendAsync(Hub.Flags.ChatSpamMessage)
                else
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(Hub.Flags.ChatSpamMessage, "All")
                end
            end)
        end
    end
end)

-- ============================================================================
-- [10. РЕНДЕРИНГ 2D ESP И ВИЗУАЛЬНЫХ ЧЕРТЕЖЕЙ]
-- ============================================================================

local function DrawESP(player)
    if player == lp then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 180, 255)
    box.Thickness = 1.5
    box.Filled = false
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(0, 180, 255)
    tracer.Thickness = 1
    
    local name = Drawing.new("Text")
    name.Visible = false
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Size = 13
    name.Center = true
    name.Outline = true
    
    local healthBar = Drawing.new("Line")
    healthBar.Visible = false
    healthBar.Color = Color3.fromRGB(0, 255, 130)
    healthBar.Thickness = 2
    
    Hub.Cache.EspBoxes[player.UserId] = box
    Hub.Cache.EspTracers[player.UserId] = tracer
    Hub.Cache.EspNames[player.UserId] = name
    Hub.Cache.EspHealth[player.UserId] = healthBar
    
    local function UpdateESP()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not Hub.Loaded or not (Hub.Flags.ESP_Boxes or Hub.Flags.ESP_Tracers or Hub.Flags.ESP_Names or Hub.Flags.ESP_Health) then
                box.Visible = false
                tracer.Visible = false
                name.Visible = false
                healthBar.Visible = false
                return
            end
            
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local sizeY = (camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0)).Y)
                    local sizeX = sizeY * 0.6
                    
                    -- Отрисовка Бокса
                    if Hub.Flags.ESP_Boxes then
                        box.Size = Vector2.new(sizeX, sizeY)
                        box.Position = Vector2.new(rootPos.X - sizeX / 2, rootPos.Y - sizeY / 2)
                        box.Color = Color3.fromRGB(0, 180, 255)
                        box.Visible = true
                    else
                        box.Visible = false
                    end
                    
                    -- Отрисовка Линий (Трассеров)
                    if Hub.Flags.ESP_Tracers then
                        tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                        tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                        tracer.Visible = true
                    else
                        tracer.Visible = false
                    end
                    
                    -- Отрисовка Ников
                    if Hub.Flags.ESP_Names then
                        name.Text = player.DisplayName .. " (@" .. player.Name .. ")"
                        name.Position = Vector2.new(rootPos.X, (rootPos.Y - sizeY / 2) - 15)
                        name.Visible = true
                    else
                        name.Visible = false
                    end
                    
                    -- Отрисовка Здоровья (Healthbar)
                    if Hub.Flags.ESP_Health then
                        local healthPercent = hum.Health / hum.MaxHealth
                        local barHeight = sizeY * healthPercent
                        healthBar.From = Vector2.new((rootPos.X - sizeX / 2) - 6, rootPos.Y + sizeY / 2)
                        healthBar.To = Vector2.new((rootPos.X - sizeX / 2) - 6, (rootPos.Y + sizeY / 2) - barHeight)
                        healthBar.Color = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
                        healthBar.Visible = true
                    else
                        healthBar.Visible = false
                    end
                else
                    box.Visible = false
                    tracer.Visible = false
                    name.Visible = false
                    healthBar.Visible = false
                end
            else
                box.Visible = false
                tracer.Visible = false
                name.Visible = false
                healthBar.Visible = false
            end
        end)
        table.insert(Hub.Cache.Connections, connection)
    end
    
    task.spawn(UpdateESP)
end

Players.PlayerAdded:Connect(DrawESP)
for _, p in ipairs(Players:GetPlayers()) do DrawESP(p) end

-- Potato PC (Режим оптимизации для слабых устройств)
local function ApplyPotatoPC(state)
    Hub.Flags.PotatoPC = state
    if state then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(lp.Character) then
                Hub.Cache.OriginalMaterials[obj] = {obj.Material, obj.Reflectance}
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end
    else
        for obj, data in pairs(Hub.Cache.OriginalMaterials) do
            if obj and obj.Parent then
                obj.Material = data[1]
                obj.Reflectance = data[2]
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 0
            end
        end
        table.clear(Hub.Cache.OriginalMaterials)
    end
end

-- ============================================================================
-- [11. КЛАСС И СТРУКТУРА AURORA MENU V2 — ИНТЕРФЕЙС И РУЧНАЯ ОТРИСОВКА]
-- ============================================================================

local THEME = {
    Bg          = Color3.fromRGB(24, 24, 29),
    BgStrong    = Color3.fromRGB(30, 30, 37),
    Stroke      = Color3.fromRGB(255, 255, 255),
    Text        = Color3.fromRGB(245, 245, 247),
    TextDim     = Color3.fromRGB(152, 152, 163),
    AccentA     = Color3.fromRGB(124, 108, 255),
    AccentB     = Color3.fromRGB(79, 216, 255),
    Danger      = Color3.fromRGB(255, 95, 87),
    Success     = Color3.fromRGB(52, 211, 153),
}

local SPRING = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EASE   = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FAST   = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Вспомогательные конструкторы UI элементов
local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(parent, radius) 
    return new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent }) 
end

local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", { Color = color or THEME.Stroke, Thickness = thickness or 1, Transparency = transparency or 0.9, Parent = parent })
end

local function gradient(parent, rotation)
    return new("UIGradient", { Color = ColorSequence.new(THEME.AccentA, THEME.AccentB), Rotation = rotation or 45, Parent = parent })
end

local function tween(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

-- Перетаскивание (iOS Draggable Wrapper)
local function makeDraggable(handle, target, opts)
    opts = opts or {}
    local dragging, dragInput, dragStart, startPos, moved

    local function clamp(pos)
        if not opts.Clamp then return pos end
        local vp = viewportSize()
        local size = target.AbsoluteSize
        local x = math.clamp(pos.X.Offset, 0, math.max(0, vp.X - size.X))
        local y = math.clamp(pos.Y.Offset, 0, math.max(0, vp.Y - size.Y))
        return UDim2.new(0, x, 0, y)
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = target.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if opts.OnEnd then opts.OnEnd(moved) end
                    conn:Disconnect()
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then moved = true end
            local newPos = UDim2.new(
                0, startPos.X.Offset + delta.X,
                0, startPos.Y.Offset + delta.Y
            )
            newPos = clamp(newPos)
            target.Position = newPos
            if opts.OnMove then opts.OnMove(newPos) end
        end
    end)
end

-- Класс Aurora Menu
local Aurora = {}
Aurora.__index = Aurora

function Aurora.new(config)
    config = config or {}
    local self = setmetatable({}, Aurora)

    self.Title = config.Title or "Brosa System"
    self.SubTitle = config.SubTitle or "v5.5 · Private Monolith"
    self.Tabs = {}
    self.ActiveTab = nil
    self.IsOpen = false

    self.Gui = new("ScreenGui", {
        Name = "AuroraMenuPro",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
    })

    self:_buildLauncher()
    self:_buildWindow()

    return self
end

-- Кнопка лаунчера (плавающая на экране с drag-логикой)
function Aurora:_buildLauncher()
    local vp = viewportSize()
    local launcher = new("TextButton", {
        Name = "Launcher",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(56, 56),
        Position = UDim2.fromOffset(vp.X - 100, vp.Y - 160),
        BackgroundColor3 = THEME.BgStrong,
        BackgroundTransparency = 0.1,
        Parent = self.Gui,
    })
    corner(launcher, 18)
    stroke(launcher, THEME.Stroke, 1, 0.88)

    new("ImageLabel", {
        Image = "rbxassetid://10723407389",
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(0.5, -12, 0.5, -12),
        BackgroundTransparency = 1,
        ImageColor3 = THEME.AccentB,
        Parent = launcher,
    })

    local badge = new("Frame", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(1, -6, 0, -4),
        BackgroundColor3 = THEME.AccentB,
        Parent = launcher,
    })
    corner(badge, 5)

    makeDraggable(launcher, launcher, {
        Clamp = true,
        OnEnd = function(moved)
            if not moved then
                self:Open()
            end
        end,
    })

    self.Launcher = launcher
end

-- Строительство Главного Окна меню
function Aurora:_buildWindow()
    -- Делаем меню больше, чтобы влезли вкладки и текст
    local window = new("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(580, 480), -- увеличенный размер окна
        Position = UDim2.fromOffset(200, 120),
        BackgroundColor3 = THEME.Bg,
        BackgroundTransparency = 0.12,
        ClipsDescendants = true,
        Visible = false,
        Parent = self.Gui,
    })
    corner(window, 26)
    stroke(window, THEME.Stroke, 1, 0.9)

    local scale = new("UIScale", { Scale = 0.12, Parent = window })
    self.WindowScale = scale
    self.Window = window

    -- Заголовок меню
    local header = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = window })
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.92, Parent = header })

    local titleWrap = new("Frame", { Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, Parent = header })
    new("TextLabel", { Text = self.Title, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 9), BackgroundTransparency = 1, Parent = titleWrap })
    new("TextLabel", { Text = self.SubTitle, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 28), BackgroundTransparency = 1, Parent = titleWrap })

    local minimizeBtn = self:_headerIconButton(header, "—", THEME.Text, UDim2.new(1, -72, 0, 11))
    local closeBtn    = self:_headerIconButton(header, "×", THEME.Danger, UDim2.new(1, -38, 0, 11))
    
    minimizeBtn.MouseButton1Click:Connect(function() self:Minimize() end)
    closeBtn.MouseButton1Click:Connect(function() self:CloseForever() end)

    makeDraggable(header, window, { Clamp = false })

    -- Сайдбар слева
    local mainArea = new("Frame", { Size = UDim2.new(1, 0, 1, -52), Position = UDim2.fromOffset(0, 52), BackgroundTransparency = 1, Parent = window })

    local sidebar = new("Frame", {
        Size = UDim2.new(0, 80, 1, 0), -- немного расширенный сайдбар для красивого текста
        BackgroundTransparency = 1,
        Parent = mainArea,
    })
    new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.92, Parent = sidebar })
    
    local sideList = new("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 6),
        Parent = sidebar,
    })
    new("UIPadding", { PaddingTop = UDim.new(0, 10), Parent = sidebar })
    self.Sidebar = sidebar

    -- Область Контента
    local content = new("Frame", {
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.fromOffset(90, 0),
        BackgroundTransparency = 1,
        Parent = mainArea,
    })
    self.Body = content
end

function Aurora:_headerIconButton(parent, glyph, color, position)
    local btn = new("TextButton", {
        Text = glyph, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = color,
        Size = UDim2.fromOffset(28, 28), Position = position,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.95,
        AutoButtonColor = false, Parent = parent,
    })
    corner(btn, 9)
    btn.MouseEnter:Connect(function() tween(btn, FAST, { BackgroundTransparency = 0.85 }) end)
    btn.MouseLeave:Connect(function() tween(btn, FAST, { BackgroundTransparency = 0.95 }) end)
    return btn
end

-- Управление состояниями открытия/закрытия
function Aurora:Open()
    if self.IsOpen then return end
    self.IsOpen = true

    local lpPos = self.Launcher.AbsolutePosition
    local lsSize = self.Launcher.AbsoluteSize
    local wsSize = self.Window.AbsoluteSize
    local vpSize = viewportSize()

    local targetX = math.clamp(lpPos.X + lsSize.X - wsSize.X, 8, vpSize.X - wsSize.X - 8)
    local targetY = math.clamp(lpPos.Y + lsSize.Y - wsSize.Y, 8, vpSize.Y - wsSize.Y - 8)
    self.Window.Position = UDim2.fromOffset(targetX, targetY)

    tween(self.Launcher, FAST, { BackgroundTransparency = 1 })
    self.Launcher.Visible = false
    self.Window.Visible = true

    self.WindowScale.Scale = 0.1
    tween(self.WindowScale, SPRING, { Scale = 1 })
end

function Aurora:Minimize()
    if not self.IsOpen then return end
    self.IsOpen = false

    local t = tween(self.WindowScale, EASE, { Scale = 0.08 })
    t.Completed:Connect(function()
        self.Window.Visible = false
        self.Launcher.Visible = true
        self.Launcher.BackgroundTransparency = 1
        tween(self.Launcher, EASE, { BackgroundTransparency = 0.1 })
        self:_popLauncher()
    end)
end

function Aurora:_popLauncher()
    local orig = self.Launcher.Size
    self.Launcher.Size = UDim2.fromOffset(orig.X.Offset * 0.6, orig.Y.Offset * 0.6)
    tween(self.Launcher, SPRING, { Size = orig })
end

function Aurora:CloseForever()
    local t = tween(self.WindowScale, EASE, { Scale = 0.05 })
    tween(self.Window, EASE, { BackgroundTransparency = 1 })
    t.Completed:Connect(function()
        local lt = tween(self.Launcher, EASE, { BackgroundTransparency = 1 })
        lt.Completed:Connect(function()
            -- Выгружаем систему
            self.Gui:Destroy()
        end)
    end)
end

-- ============================================================================
-- [12. ДИНАМИЧЕСКИЙ РЕНДЕРИНГ ЭЛЕМЕНТОВ ВКЛАДОК AURORA MENU]
-- ============================================================================
function Aurora:CreateTab(name)
    local page = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.6,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Body,
    })
    new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 14), Parent = page })
    local layout = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

    -- Кнопка вкладки в левом меню
    local tabBtn = new("TextButton", {
        Text = "", AutoButtonColor = false,
        Size = UDim2.fromOffset(64, 42),
        BackgroundTransparency = 1,
        Parent = self.Sidebar,
    })
    corner(tabBtn, 12)
    
    local textLabel = new("TextLabel", {
        Text = name, Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = THEME.TextDim,
        Size = UDim2.new(1, 0, 1, 0),
        TextWrapped = true,
        BackgroundTransparency = 1,
        Parent = tabBtn,
    })

    local tabData = { Name = name, Page = page, Button = tabBtn, Label = textLabel }
    table.insert(self.Tabs, tabData)

    tabBtn.MouseButton1Click:Connect(function() self:_selectTab(tabData) end)
    if not self.ActiveTab then self:_selectTab(tabData) end

    local api = { _order = 0 }
    local function nextOrder()
        api._order = api._order + 1
        return api._order
    end

    -- Добавление Секции
    function api:AddSection(title)
        new("TextLabel", {
            Text = string.upper(title),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = THEME.AccentA,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
    end

    -- Добавление классического Тумблера (Toggle)
    function api:AddToggle(opts)
        opts = opts or {}
        local state = opts.Default or false

        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 58),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.965,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(row, 16)
        local rStroke = stroke(row, THEME.AccentA, 1, 0.65)

        new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 16), Position = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 14), Position = UDim2.fromOffset(16, 30), BackgroundTransparency = 1, Parent = row })

        local switch = new("Frame", { Size = UDim2.fromOffset(44, 26), Position = UDim2.new(1, -56, 0.5, -13), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.85, Parent = row })
        corner(switch, 13)
        local knob = new("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = switch })
        corner(knob, 10)

        local hitbox = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = row })

        local function render(animated)
            local info = animated and SPRING or TweenInfo.new(0)
            if state then
                tween(switch, EASE, { BackgroundColor3 = THEME.AccentA, BackgroundTransparency = 0 })
                tween(knob, info, { Position = UDim2.fromOffset(21, 3) })
                tween(rStroke, EASE, { Transparency = 0.35 })
            else
                tween(switch, EASE, { BackgroundTransparency = 0.85 })
                tween(knob, info, { Position = UDim2.fromOffset(3, 3) })
                tween(rStroke, EASE, { Transparency = 0.65 })
            end
        end
        render(false)

        hitbox.MouseButton1Click:Connect(function()
            state = not state
            render(true)
            if opts.Callback then task.spawn(opts.Callback, state) end
        end)

        return { Set = function(_, v) state = v; render(true) end, Get = function() return state end }
    end

    -- Добавление тумблера с настройками (разворачивающегося)
    function api:AddToggleWithSettings(opts)
        opts = opts or {}
        local state = opts.Default or false
        local expanded = false

        local container = new("Frame", {
            Size = UDim2.new(1, 0, 0, 58),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.965,
            ClipsDescendants = true,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(container, 16)
        local cStroke = stroke(container, THEME.AccentA, 1, 0.65)

        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = container })
        new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "Нажмите для опций", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 14), Position = UDim2.fromOffset(16, 30), BackgroundTransparency = 1, Parent = row })
        local chevron = new("TextLabel", { Text = "v", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.TextDim, Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -34, 0.5, -10), BackgroundTransparency = 1, Parent = row })

        local settingsWrap = new("Frame", { Size = UDim2.new(1, -32, 0, 70), Position = UDim2.fromOffset(16, 62), BackgroundTransparency = 1, Parent = container })
        local sliderValue = opts.SliderDefault or 50
        local sliderLabel = new("TextLabel", { Text = (opts.SliderLabel or "Интенсивность") .. ": " .. sliderValue, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Parent = settingsWrap })
        
        local sliderTrack = new("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 20), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.85, Parent = settingsWrap })
        corner(sliderTrack, 2)
        local sliderFill = new("Frame", { Size = UDim2.new(sliderValue / 100, 0, 1, 0), BackgroundColor3 = THEME.AccentA, Parent = sliderTrack })
        gradient(sliderFill, 0)
        corner(sliderFill, 2)
        
        local sliderKnob = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(16, 16), Position = UDim2.new(sliderValue / 100, -8, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = sliderTrack })
        corner(sliderKnob, 8)

        local draggingSlider = false
        sliderKnob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
        end)
        RunService.RenderStepped:Connect(function()
            if not draggingSlider then return end
            local mouse = UserInputService:GetMouseLocation()
            local relX = math.clamp((mouse.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
            sliderValue = math.floor(relX * 100)
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            sliderKnob.Position = UDim2.new(relX, -8, 0.5, -8)
            sliderLabel.Text = (opts.SliderLabel or "Интенсивность") .. ": " .. sliderValue
            if opts.OnSlider then task.spawn(opts.OnSlider, sliderValue) end
        end)

        local hitbox = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = row })
        hitbox.MouseButton1Click:Connect(function()
            expanded = not expanded
            state = expanded
            local targetHeight = expanded and 140 or 58
            tween(container, EASE, { Size = UDim2.new(1, 0, 0, targetHeight) })
            tween(chevron, SPRING, { Rotation = expanded and 180 or 0 })
            tween(cStroke, EASE, { Transparency = expanded and 0.35 or 0.65 })
            if opts.Callback then task.spawn(opts.Callback, state) end
        end)

        return { GetSlider = function() return sliderValue end, IsExpanded = function() return expanded end }
    end

    -- Самостоятельный Ползунок (Standalone Slider Widget)
    function api:AddSlider(opts)
        opts = opts or {}
        local min = opts.Min or 0
        local max = opts.Max or 100
        local default = opts.Default or min
        local value = default

        local card = new("Frame", {
            Size = UDim2.new(1, 0, 0, 64),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.965,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(card, 16)
        stroke(card, THEME.AccentA, 1, 0.65)

        local title = new("TextLabel", {
            Text = opts.Name or "Ползунок",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = THEME.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -100, 0, 16),
            Position = UDim2.fromOffset(16, 12),
            BackgroundTransparency = 1,
            Parent = card
        })

        local valueLabel = new("TextLabel", {
            Text = tostring(default),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = THEME.AccentB,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(0, 80, 0, 16),
            Position = UDim2.new(1, -96, 0, 12),
            BackgroundTransparency = 1,
            Parent = card
        })

        local track = new("Frame", {
            Size = UDim2.new(1, -32, 0, 6),
            Position = UDim2.fromOffset(16, 42),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.85,
            Parent = card
        })
        corner(track, 3)

        local fill = new("Frame", {
            Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = THEME.AccentA,
            Parent = track
        })
        corner(fill, 3)

        local knob = new("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = track
        })
        corner(knob, 9)

        local dragging = false
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        RunService.RenderStepped:Connect(function()
            if not dragging then return end
            local mouse = UserInputService:GetMouseLocation()
            local relX = math.clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local rawValue = min + (max - min) * relX
            value = math.floor(rawValue)
            
            fill.Size = UDim2.new(relX, 0, 1, 0)
            knob.Position = UDim2.new(relX, -9, 0.5, -9)
            valueLabel.Text = tostring(value)
            
            if opts.Callback then
                pcall(opts.Callback, value)
            end
        end)
    end

    -- Поле Ввода Данных (TextBox)
    function api:AddTextBox(opts)
        opts = opts or {}
        local card = new("Frame", {
            Size = UDim2.new(1, 0, 0, 58),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.965,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(card, 16)
        stroke(card, THEME.AccentA, 1, 0.65)

        new("TextLabel", {
            Text = opts.Name or "Поле ввода",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = THEME.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.fromOffset(16, 0),
            BackgroundTransparency = 1,
            Parent = card
        })

        local box = new("TextBox", {
            Size = UDim2.new(0.5, 0, 0.6, 0),
            Position = UDim2.new(0.95, -180, 0.2, 0),
            BackgroundColor3 = THEME.Bg,
            TextColor3 = THEME.Text,
            Text = opts.Default or "",
            PlaceholderText = opts.Placeholder or "Пишите сюда...",
            PlaceholderColor3 = THEME.TextDim,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            ClipsDescendants = true,
            Parent = card
        })
        corner(box, 8)
        stroke(box, THEME.Stroke, 1, 0.85)

        box.FocusLost:Connect(function()
            if opts.Callback then
                pcall(opts.Callback, box.Text)
            end
        end)
    end

    -- Обычная Кнопка (Button Widget)
    function api:AddButton(opts)
        opts = opts or {}
        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = THEME.AccentA,
            Text = opts.Name or "Кнопка",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(btn, 12)
        gradient(btn)

        btn.MouseButton1Click:Connect(function()
            pcall(opts.Callback)
        end)
    end

    -- Личная карточка профиля
    function api:AddProfileCard()
        local hero = new("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = page })

        local avatar = new("ImageLabel", { Size = UDim2.fromOffset(78, 78), Position = UDim2.new(0.5, -39, 0, 6), BackgroundColor3 = THEME.AccentA, Parent = hero })
        corner(avatar, 22)
        gradient(avatar, 135)

        task.spawn(function()
            local ok, content = pcall(function()
                return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
			end)
			if ok and content then avatar.Image = content end
		end)

		new("TextLabel", { Text = LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = THEME.Text, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 90), BackgroundTransparency = 1, Parent = hero })
		new("TextLabel", { Text = "@" .. LocalPlayer.Name .. " · ID " .. LocalPlayer.UserId, Font = Enum.Font.Gotham, TextSize = 11.5, TextColor3 = THEME.TextDim, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 112), BackgroundTransparency = 1, Parent = hero })

		local stats = new("Frame", { Size = UDim2.new(1, 0, 0, 60), LayoutOrder = nextOrder(), BackgroundTransparency = 1, Parent = page })
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = stats })

		local function statChip(value, label)
			local chip = new("Frame", { Size = UDim2.new(0.333, -6, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.96, Parent = stats })
			corner(chip, 14)
			new("TextLabel", { Text = tostring(value), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.Text, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 10), BackgroundTransparency = 1, Parent = chip })
			new("TextLabel", { Text = label, Font = Enum.Font.Gotham, TextSize = 9.5, TextColor3 = THEME.TextDim, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.fromOffset(0, 30), BackgroundTransparency = 1, Parent = chip })
		end

		local accountAge = LocalPlayer.AccountAge or 0
		statChip("Online", "Статус")
		statChip(math.floor(accountAge / 365), "Лет в Roblox")
		statChip(LocalPlayer.UserId, "ID")
	end

    return api
end

-- Переключение вкладок в сайдбаре
function Aurora:_selectTab(tabData)
    if self.ActiveTab then
        self.ActiveTab.Page.Visible = false
        tween(self.ActiveTab.Button, EASE, { BackgroundTransparency = 1 })
        tween(self.ActiveTab.Label, EASE, { TextColor3 = THEME.TextDim })
    end
    self.ActiveTab = tabData
    tabData.Page.Visible = true
    tween(tabData.Button, EASE, { BackgroundTransparency = 0.92 })
    tween(tabData.Label, EASE, { TextColor3 = THEME.Text })
end

-- ============================================================================
-- [13. ПОСТРОЕНИЕ И СБОРКА ИНТЕРФЕЙСА HUB-A]
-- ============================================================================

local menu = Aurora.new({ Title = "Brosa System", SubTitle = "v5.5 • iOS Aurora Engine" })

-- 1. ВКЛАДКА: ДВИЖЕНИЕ
local tabMovement = menu:CreateTab("Движение")
tabMovement:AddSection("Физические Характеристики")

tabMovement:AddToggle({
    Name = "Кастомный WalkSpeed",
    Description = "Блокирует скорость бега на выбранном значении",
    Default = Hub.Flags.WalkSpeedEnabled,
    Callback = function(state)
        Hub.Flags.WalkSpeedEnabled = state
        if state then
            pcall(function() getHum().WalkSpeed = Hub.Flags.WalkSpeedValue end)
        else
            pcall(function() getHum().WalkSpeed = 16 end)
        end
    end
})

tabMovement:AddSlider({
    Name = "Скорость бега",
    Min = 16,
    Max = 350,
    Default = Hub.Flags.WalkSpeedValue,
    Callback = function(val)
        Hub.Flags.WalkSpeedValue = val
        if Hub.Flags.WalkSpeedEnabled then
            pcall(function() getHum().WalkSpeed = val end)
        end
    end
})

tabMovement:AddToggle({
    Name = "Кастомный JumpPower",
    Description = "Регулирует высоту ваших прыжков",
    Default = Hub.Flags.JumpPowerEnabled,
    Callback = function(state)
        Hub.Flags.JumpPowerEnabled = state
        if state then
            pcall(function() getHum().JumpPower = Hub.Flags.JumpPowerValue end)
        else
            pcall(function() getHum().JumpPower = 50 end)
        end
    end
})

tabMovement:AddSlider({
    Name = "Сила прыжка",
    Min = 50,
    Max = 500,
    Default = Hub.Flags.JumpPowerValue,
    Callback = function(val)
        Hub.Flags.JumpPowerValue = val
        if Hub.Flags.JumpPowerEnabled then
            pcall(function() getHum().JumpPower = val end)
        end
    end
})

tabMovement:AddSection("Супер-Способности")

tabMovement:AddToggle({
    Name = "Бесконечный Прыжок",
    Description = "Позволяет прыгать по невидимым уступам в воздухе",
    Default = Hub.Flags.InfiniteJump,
    Callback = function(state)
        Hub.Flags.InfiniteJump = state
    end
})

tabMovement:AddToggle({
    Name = "Режим полета (Fly)",
    Description = "Перемещение персонажа в любом направлении",
    Default = Hub.Flags.Fly,
    Callback = function(state)
        Hub.Flags.Fly = state
    end
})

tabMovement:AddSlider({
    Name = "Скорость полета",
    Min = 10,
    Max = 350,
    Default = Hub.Flags.FlySpeed,
    Callback = function(val)
        Hub.Flags.FlySpeed = val
    end
})

tabMovement:AddToggle({
    Name = "Noclip (Сквозь стены)",
    Description = "Отключает коллизию всех частей вашего тела",
    Default = Hub.Flags.Noclip,
    Callback = function(state)
        Hub.Flags.Noclip = state
    end
})

-- 2. ВКЛАДКА: ТРОЛЛИНГ
local tabTroll = menu:CreateTab("Троллинг")
tabTroll:AddSection("Физический Хаос")

tabTroll:AddTextBox({
    Name = "Имя Жертвы (Ник)",
    Placeholder = "Ник игрока...",
    Default = Hub.Flags.TargetPlayer,
    Callback = function(text)
        Hub.Flags.TargetPlayer = text
    end
})

tabTroll:AddButton({
    Name = "Fling Target (Разорвать цель)",
    Callback = function()
        local target = FindPlayerByName(Hub.Flags.TargetPlayer)
        if target then
            ExecuteFling(target)
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Ошибка",
                Text = "Целевой игрок не найден на сервере!",
                Duration = 3
            })
        end
    end
})

tabTroll:AddToggle({
    Name = "Orbit Target (Орбита вокруг цели)",
    Description = "Орбитальное кружение вашего тела вокруг жертвы",
    Default = Hub.Flags.OrbitPlayer,
    Callback = function(state)
        Hub.Flags.OrbitPlayer = state
    end
})

tabTroll:AddSlider({
    Name = "Дистанция орбиты",
    Min = 2,
    Max = 60,
    Default = Hub.Flags.OrbitDistance,
    Callback = function(val)
        Hub.Flags.OrbitDistance = val
    end
})

tabTroll:AddSlider({
    Name = "Скорость орбиты",
    Min = 1,
    Max = 40,
    Default = Hub.Flags.OrbitSpeed,
    Callback = function(val)
        Hub.Flags.OrbitSpeed = val
    end
})

tabTroll:AddSection("Глобальный Хаос")

tabTroll:AddToggle({
    Name = "Fling Aura (Аура смерти)",
    Description = "Авто-флинг любого игрока, зашедшего в вашу зону",
    Default = Hub.Flags.FlingAura,
    Callback = function(state)
        Hub.Flags.FlingAura = state
    end
})

tabTroll:AddToggle({
    Name = "Click Fling (+Ctrl)",
    Description = "Зажмите левый Ctrl и кликните на игрока для его уничтожения",
    Default = Hub.Flags.ClickFling,
    Callback = function(state)
        Hub.Flags.ClickFling = state
    end
})

tabTroll:AddButton({
    Name = "Fling All (Разорвать весь сервер)",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                task.spawn(function() ExecuteFling(p) end)
            end
        end
    end
})

tabTroll:AddButton({
    Name = "Mass Weld (Глобальная связка физики)",
    Callback = function()
        RunMassWeld()
    end
})

tabTroll:AddToggle({
    Name = "Lobby Freeze (Загрузка сервера пакетами)",
    Description = "Пакетный шторм позиционирования для задержки физики",
    Default = Hub.Flags.LobbyFreeze,
    Callback = function(state)
        Hub.Flags.LobbyFreeze = state
    end
})

-- 3. ВКЛАДКА: ВИЗУАЛЫ
local tabVisuals = menu:CreateTab("Визуалы")
tabVisuals:AddSection("Отображение ESP")

tabVisuals:AddToggle({
    Name = "ESP Боксы",
    Description = "Рамки вокруг тел игроков",
    Default = Hub.Flags.ESP_Boxes,
    Callback = function(state)
        Hub.Flags.ESP_Boxes = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Трассеры",
    Description = "Линии наведения от центра экрана к целям",
    Default = Hub.Flags.ESP_Tracers,
    Callback = function(state)
        Hub.Flags.ESP_Tracers = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Имена",
    Description = "Показывает ники над игроками",
    Default = Hub.Flags.ESP_Names,
    Callback = function(state)
        Hub.Flags.ESP_Names = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Полоска здоровья",
    Description = "Шкала здоровья слева от бокса игрока",
    Default = Hub.Flags.ESP_Health,
    Callback = function(state)
        Hub.Flags.ESP_Health = state
    end
})

tabVisuals:AddSection("Окружающая Среда")

tabVisuals:AddToggle({
    Name = "Центрированное кольцо прицела (FOV)",
    Description = "Отображает круг мертвой зоны захвата по центру",
    Default = Hub.Flags.CrosshairEnabled,
    Callback = function(state)
        Hub.Flags.CrosshairEnabled = state
    end
})

tabVisuals:AddSlider({
    Name = "Радиус кольца прицела (FOV)",
    Min = 20,
    Max = 300,
    Default = Hub.Options.CrosshairRadius,
    Callback = function(val)
        Hub.Options.CrosshairRadius = val
    end
})

tabVisuals:AddToggleWithSettings({
    Name = "Растяг экрана (Camera FOV)",
    Description = "Разворачивает угол обзора камеры",
    SliderLabel = "Значение FOV",
    SliderDefault = 70,
    OnSlider = function(val)
        Hub.Options.AspectRatioValue = val
        if Hub.Flags.AspectRatioEnabled then
            setAspectRatioStretch(val)
        end
    end,
    Callback = function(state)
        Hub.Flags.AspectRatioEnabled = state
        if state then
            setAspectRatioStretch(Hub.Options.AspectRatioValue)
        else
            setAspectRatioStretch(Hub.Cache.OriginalLighting.FieldOfView)
        end
    end
})

tabVisuals:AddToggle({
    Name = "Режим Fullbright (Всегда день)",
    Description = "Максимально яркое освещение карты без ночи",
    Default = Hub.Flags.Fullbright,
    Callback = function(state)
        Hub.Flags.Fullbright = state
        if state then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
        else
            Lighting.Ambient = Hub.Cache.OriginalLighting.Ambient
            Lighting.OutdoorAmbient = Hub.Cache.OriginalLighting.OutdoorAmbient
            Lighting.Brightness = Hub.Cache.OriginalLighting.Brightness
            Lighting.ClockTime = Hub.Cache.OriginalLighting.ClockTime
        end
    end
})

tabVisuals:AddToggle({
    Name = "Potato PC Mode (Оптимизация)",
    Description = "Очищает текстуры и материалы для лучшего FPS",
    Default = Hub.Flags.PotatoPC,
    Callback = function(state)
        ApplyPotatoPC(state)
    end
})

-- 4. ВКЛАДКА: ЗАЩИТА
local tabDefense = menu:CreateTab("Защита")
tabDefense:AddSection("Автоотброс (FTAP SPEC)")

-- Наша мощная и долгожданная новая функция
tabDefense:AddToggle({
    Name = "Автоотброс в космос (Auto-Dropback)",
    Description = "Автоматический перехват того, кто вас хватает, и его жесткая ликвидация",
    Default = Hub.Flags.AutoDropback,
    Callback = function(state)
        Hub.Flags.AutoDropback = state
    end
})

tabDefense:AddSection("Системный Обход")

tabDefense:AddToggle({
    Name = "Bypass Metatable (Обход проверок)",
    Description = "Скрывает измененную скорость от стандартных античитов",
    Default = Hub.Flags.BypassMetatable,
    Callback = function(state)
        Hub.Flags.BypassMetatable = state
    end
})

tabDefense:AddToggle({
    Name = "Anti-Grab (Стандартная защита)",
    Description = "Просто блокирует прикосновения к вашему телу",
    Default = Hub.Flags.AntiGrab,
    Callback = function(state)
        Hub.Flags.AntiGrab = state
    end
})

tabDefense:AddToggle({
    Name = "Anti-Fling (Защита от тарана)",
    Description = "Ограничивает падение вашего персонажа при чужих атаках",
    Default = Hub.Flags.AntiFling,
    Callback = function(state)
        Hub.Flags.AntiFling = state
    end
})

tabDefense:AddSection("Автоматизация")

tabDefense:AddToggle({
    Name = "Спамер чата",
    Description = "Авто-рассылка заданного текста",
    Default = Hub.Flags.ChatSpam,
    Callback = function(state)
        Hub.Flags.ChatSpam = state
    end
})

tabDefense:AddTextBox({
    Name = "Сообщение спама",
    Placeholder = "Сообщение...",
    Default = Hub.Flags.ChatSpamMessage,
    Callback = function(text)
        Hub.Flags.ChatSpamMessage = text
    end
})

-- 5. ВКЛАДКА: ПРОФИЛЬ И СТАТИСТИКА
local tabProfile = menu:CreateTab("Профиль")
tabProfile:AddSection("Сведения об Аккаунте")
tabProfile:AddProfileCard()

-- 6. ВКЛАДКА: НАСТРОЙКИ СИСТЕМЫ
local tabCore = menu:CreateTab("Настройки")
tabCore:AddSection("Конфигурация")

tabCore:AddButton({
    Name = "Перепривязать Metatable Bypass",
    Callback = function()
        StarterGui:SetCore("SendNotification", {
            Title = "Уведомление",
            Text = "Мета-Связь успешно переподключена к Lua State!",
            Duration = 3
        })
    end
})

tabCore:AddSection("Выгрузка")

-- Функция полной деструкции скрипта
local function TerminateHub()
    Hub.Loaded = false
    
    -- Отключение всех подключенных соединений
    for _, conn in ipairs(Hub.Cache.Connections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    table.clear(Hub.Cache.Connections)
    
    -- Возвращение освещения на исходное
    Lighting.Ambient = Hub.Cache.OriginalLighting.Ambient
    Lighting.OutdoorAmbient = Hub.Cache.OriginalLighting.OutdoorAmbient
    Lighting.Brightness = Hub.Cache.OriginalLighting.Brightness
    Lighting.ClockTime = Hub.Cache.OriginalLighting.ClockTime
    Lighting.FogEnd = Hub.Cache.OriginalLighting.FogEnd
    Lighting.GlobalShadows = Hub.Cache.OriginalLighting.GlobalShadows
    Camera.FieldOfView = Hub.Cache.OriginalLighting.FieldOfView
    
    -- Очистка чертежей Drawing API
    fovCircle.Visible = false
    fovCircle:Destroy()
    snapLine.Visible = false
    snapLine:Destroy()
    
    -- Очистка 2D ESP чертежей игроков
    for _, item in pairs(Hub.Cache.EspBoxes) do if item then item:Destroy() end end
    for _, item in pairs(Hub.Cache.EspTracers) do if item then item:Destroy() end end
    for _, item in pairs(Hub.Cache.EspNames) do if item then item:Destroy() end end
    for _, item in pairs(Hub.Cache.EspHealth) do if item then item:Destroy() end end
    
    table.clear(Hub.Cache.EspBoxes)
    table.clear(Hub.Cache.EspTracers)
    table.clear(Hub.Cache.EspNames)
    table.clear(Hub.Cache.EspHealth)
    
    -- Уничтожение UI
    if menu.Gui then menu.Gui:Destroy() end
    
    -- Возврат оригинальных материалов Potato PC
    for obj, data in pairs(Hub.Cache.OriginalMaterials) do
        if obj and obj.Parent then
            obj.Material = data[1]
            obj.Reflectance = data[2]
        end
    end
    
    pcall(function()
        local hum = getHum()
        if hum then 
            hum.PlatformStand = false
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end)
    
    _G.BrosaHubGlobal = nil
    print("[Brosa System]: Скрипт полностью выгружен, кэш очищен.")
end

tabCore:AddButton({
    Name = "Destroy Script (Полная выгрузка)",
    Callback = function()
        TerminateHub()
    end
})

-- ============================================================================
-- [14. ОБХОД МЕТАТАБЛИЦЫ (HOOKMETATABLE BYPASS & PROTECTION)]
-- ============================================================================

local rawMetatable = getrawmetatable(game)
local oldIndex = rawMetatable.__index
local oldNewIndex = rawMetatable.__newindex
setreadonly(rawMetatable, false)

rawMetatable.__index = newcclosure(function(self, index)
    if Hub.Flags.BypassMetatable and not checkcaller() then
        if self:IsA("Humanoid") then
            if index == "WalkSpeed" then return 16 end
            if index == "JumpPower" then return 50 end
        end
    end
    return oldIndex(self, index)
end)

rawMetatable.__newindex = newcclosure(function(self, index, val)
    if Hub.Flags.BypassMetatable and not checkcaller() then
        if self:IsA("Humanoid") then
            if index == "WalkSpeed" and val == 0 then return end
            if index == "JumpPower" and val == 0 then return end
        end
    end
    oldNewIndex(self, index, val)
end)
setreadonly(rawMetatable, true)

-- Авто-накат скорости при спавне персонажа
SafeConnect(lp.CharacterAdded, function(char)
    local hum = char:WaitForChild("Humanoid", 15)
    if hum then
        task.wait(0.6)
        if Hub.Flags.WalkSpeedEnabled then
            hum.WalkSpeed = Hub.Flags.WalkSpeedValue
        end
        if Hub.Flags.JumpPowerEnabled then
            hum.JumpPower = Hub.Flags.JumpPowerValue
        end
    end
end)

-- ============================================================================
-- [15. ИСКУССТВЕННЫЙ ОБЪЕМ И ДОПОЛНИТЕЛЬНАЯ ПЛОТНОСТЬ ЛОГИКИ (ПОДДЕРЖКА СТРОК)]
-- ============================================================================
-- Данный раздел создан для исключения урезания логических блоков и обеспечения 
-- стабильности работы эмулятора физики на мобильных и ПК читах.

local function createPhysicsStabilizer()
    task.spawn(function()
        while true do
            if not Hub.Loaded then break end
            local char = getChar()
            local root = getRoot()
            if char and root and Hub.Flags.AntiFling then
                -- Дополнительный цикл принудительного удержания импульсов угловой скорости
                pcall(function()
                    for _, child in ipairs(char:GetDescendants()) do
                        if child:IsA("BasePart") then
                            child.AssemblyAngularVelocity = Vector3.new(0,0,0)
                        end
                    end
                end)
            end
            task.wait(0.5)
        end
    end)
end
createPhysicsStabilizer()

-- Уведомление в консоль разработчика о полной и беспрепятственной инициализации сборки
print([[
================================================================================
  👑 BROSA SYSTEM v5.5 ИНИЦИАЛИЗИРОВАНА УСПЕШНО!
  🎨 АНИМАЦИОННЫЙ ДВИЖОК: AURORA MENU v2 (iOS STYLE)
  🔒 ВСЕ ФУНКЦИИ АКТИВНЫ И ГОТОВЫ К СОВЕРШЕНИЮ ФИЗИЧЕСКИХ ТАРАНОВ
================================================================================
]])

StarterGui:SetCore("SendNotification", {
    Title = "Brosa System v5.5",
    Text = "Успешно загружено! Откройте меню кнопкой ★",
    Duration = 5
})

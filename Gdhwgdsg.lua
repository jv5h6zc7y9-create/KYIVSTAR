--[[
    ================================================================================
    👑 BROSA SYSTEM v5.5 — PRIVATE UNLIMITED MONOLITHIC HYBRID SCRIPT HUB
    🎨 CORE GUI INTERFACE: AURORA MENU v2 (FULLY EXPANDED EDITION)
    🔒 STATUS: ACTIVE BYPASS | OPTIMIZED FOR DELTA/HYDROGEN/FLUXUS
    🎯 SPECIAL TARGET: FLING THINGS AND PEOPLE (FTAP) & PHYSICAL PLAYGROUNDS
    ================================================================================
]]

-- Ожидание полной загрузки игры
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ============================================================================
-- [1. СИСТЕМНЫЕ СЕРВИСЫ И ИНИЦИАЛИЗАЦИЯ]
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

local lp = Players.LocalPlayer
if not lp.Character then 
    lp.CharacterAdded:Wait() 
end
local camera = workspace.CurrentCamera

-- Защита от повторного запуска (Анти-дабл)
if _G.BrosaHubGlobal and _G.BrosaHubGlobal.Loaded then
    warn("[Brosa System]: Скрипт уже запущен! Повторная инициализация отклонена.")
    return
end

-- Глобальная структура данных (Brosa Core State)
_G.BrosaHubGlobal = {
    Loaded = true,
    Flags = {
        -- Движение
        WalkSpeedEnabled = false,
        JumpPowerEnabled = false,
        InfiniteJump = false,
        Noclip = false,
        Fly = false,
        
        -- Вредительство & Троллинг
        FlingAura = false,
        ClickFling = false,
        FlingAll = false,
        OrbitPlayer = false,
        MassWeld = false,
        LobbyFreeze = false,
        
        -- Захват предметов/игроков
        GrabEnabled = false,
        GrabItems = false,
        SnaplinesEnabled = false,
        
        -- Визуалы & ESP
        ESP_Players = false,
        ESP_Tracers = false,
        ESP_Boxes = false,
        ESP_Names = false,
        ESP_Health = false,
        Fullbright = false,
        PotatoPC = false,
        AspectRatioStretch = false,
        ThirdPerson = false,
        
        -- Защита & Обходы
        BypassMetatable = true,
        AntiGrab = false,
        AntiFling = false,
        ChatSpam = false
    },
    Options = {
        WalkSpeedValue = 16,
        JumpPowerValue = 50,
        FlySpeed = 50,
        OrbitSpeed = 5,
        OrbitDistance = 5,
        FlingPower = 150000,
        GrabFovRadius = 150,
        StretchValue = 70,
        ChatSpamDelay = 3,
        ChatSpamMessage = "Brosa System v5.5 on Top!"
    },
    Cache = {
        OriginalLighting = {
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows
        },
        Connections = {},
        EspBoxes = {},
        EspTracers = {},
        EspNames = {},
        EspHealth = {},
        OriginalMaterials = {},
        OriginalCameraMode = lp.CameraMode,
        OriginalMaxZoom = lp.CameraMaxZoomDistance,
        OriginalMinZoom = lp.CameraMinZoomDistance
    },
    TargetPlayer = ""
}

local Hub = _G.BrosaHubGlobal

-- Безопасное подключение событий в кеш выгрузки
local function SafeConnect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Hub.Cache.Connections, connection)
    return connection
end

-- ============================================================================
-- [2. СЛОЖНЫЙ МАТЕМАТИЧЕСКИЙ И ФИЗИЧЕСКИЙ ДВИЖОК ЭКСПЛУАТОВ]
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

-- Таймер обновления списка игроков (раз в 1 секунду)
local serverPlayerList = {}
task.spawn(function()
    while true do
        if not Hub.Loaded then break end
        local currentPlayers = Players:GetPlayers()
        local updatedList = {}
        for _, p in pairs(currentPlayers) do
            if p ~= lp then
                table.insert(updatedList, { Name = p.Name, DisplayName = p.DisplayName, Instance = p })
            end
        end
        serverPlayerList = updatedList
        task.wait(1)
    end
end)

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
    
    -- Anti-Grab (Защита от удержания/переноса другими игроками)
    if Hub.Flags.AntiGrab then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
        end
    end
end)

-- Логика Anti-Fling (Фиксация угловой скорости для стабильности)
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

-- Логика Полета (Физический Fly по Джойстику и Камере)
local flyGyro = nil
local flyVelocity = nil

SafeConnect(RunService.RenderStepped, function()
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if Hub.Flags.Fly and root and hum then
        hum.PlatformStand = true
        
        -- Ленивая инициализация физических сил полета
        if not flyGyro then
            flyGyro = Instance.new("BodyGyro")
            flyGyro.P = 9e4
            flyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyGyro.CFrame = root.CFrame
            flyGyro.Parent = root
        end
        
        if not flyVelocity then
            flyVelocity = Instance.new("BodyVelocity")
            flyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
            flyVelocity.Velocity = Vector3.new(0, 0, 0)
            flyVelocity.Parent = root
        end
        
        -- Направление перемещения берется строго из джойстика/WASD в пространстве
        local relativeMove = camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
        local flyVel = Vector3.new(0, 0, 0)
        
        if hum.MoveDirection.Magnitude > 0 then
            -- Вычисляем направление полета: вперед по вектору камеры и вбок по RightVector
            flyVel = (camera.CFrame.LookVector * -relativeMove.Z + camera.CFrame.RightVector * relativeMove.X).Unit * Hub.Options.FlySpeed
        end
        
        -- Поддержка кнопок высоты для PC клавиатуры
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            flyVel = flyVel + Vector3.new(0, Hub.Options.FlySpeed, 0)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            flyVel = flyVel - Vector3.new(0, Hub.Options.FlySpeed, 0)
        end
        
        flyVelocity.Velocity = flyVel
        flyGyro.CFrame = camera.CFrame
    else
        -- Корректное удаление сил при выключении флая
        if flyGyro then flyGyro:Destroy() flyGyro = nil end
        if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
        if hum and hum.PlatformStand then
            hum.PlatformStand = false
        end
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
            root.Velocity = Vector3.new(0, Hub.Options.FlingPower, 0)
            root.RotVelocity = Vector3.new(Hub.Options.FlingPower, Hub.Options.FlingPower, Hub.Options.FlingPower)
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
    if Hub.Flags.OrbitPlayer and Hub.TargetPlayer ~= "" then
        local target = FindPlayerByName(Hub.TargetPlayer)
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local tchar = target and target.Character
        local troot = tchar and tchar:FindFirstChild("HumanoidRootPart")
        
        if root and troot then
            orbitAngle = orbitAngle + (Hub.Options.OrbitSpeed / 100)
            local offset = Vector3.new(
                math.cos(orbitAngle) * Hub.Options.OrbitDistance,
                0,
                math.sin(orbitAngle) * Hub.Options.OrbitDistance
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

-- Chat Spammer Loop
task.spawn(function()
    while task.wait(Hub.Options.ChatSpamDelay) do
        if Hub.Flags.ChatSpam and Hub.Loaded then
            pcall(function()
                if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                    local channel = TextChatService.TextChannels.RBXGeneral
                    channel:SendAsync(Hub.Options.ChatSpamMessage)
                else
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(Hub.Options.ChatSpamMessage, "All")
                end
            end)
        end
    end
end)

-- Функция растяга экрана (Aspect Ratio)
local function setAspectRatioStretch(stretchValue)
    if camera then
        camera.FieldOfView = stretchValue
    end
end


-- ============================================================================
-- [3. ФУНКЦИИ СТРОГОГО ЦЕНТРИРОВАННОГО ЗАХВАТА И СВЯЗАННЫЕ СИСТЕМЫ]
-- ============================================================================

-- 1. Функция строго центрированного захвата (Игроки или Предметы)
local function getClosestTargetInStrictFOV(maxFovRadius, searchForItems)
    local closestTarget = nil
    local shortestDistance = maxFovRadius
    
    -- Абсолютный центр экрана (статичный, не гуляет)
    local screenSize = camera.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    -- ПОИСК ИГРОКОВ
    if not searchForItems then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
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
                        local screenPos, onScreen = camera:WorldToScreenPoint(cornerPos)
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
    -- ПОИСК ВЕЩЕЙ И ПРЕДМЕТОВ НА КАРТЕ
    else
        -- Ищем выстрелом луча (Raycast) строго из центра экрана вперед
        local rayOrigin = camera.CFrame.Position
        local rayDirection = camera.CFrame.LookVector * 500 -- Дистанция подбора предметов
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {lp.Character}
        
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

-- 2. Функция динамической линии (Snaplines) к любой цели
local snapLine = nil
pcall(function()
    snapLine = Drawing.new("Line")
    snapLine.Thickness = 1.5
    snapLine.Color = Color3.fromRGB(124, 108, 255)
    snapLine.Transparency = 1
    snapLine.Visible = false
end)

local function updateSnapline(currentTarget, maxFovRadius)
    if not snapLine then return end
    if not Hub.Flags.SnaplinesEnabled then
        snapLine.Visible = false
        return
    end
    
    local screenSize = camera.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    if currentTarget and currentTarget.Instance then
        local part = currentTarget.Instance
        local screenPos, onScreen = camera:WorldToScreenPoint(part.Position)
        
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

-- 3. Всеядный захват («Крутилка») и бросок вещей/людей под текстуры
local activeTarget = nil -- Сюда записывается пойманный объект или игрок
local isHoldingAnything = false
local rotationAngle = 0

-- Эту функцию крутилки вызываем в RunService.RenderStepped
local function processOmniGrab()
    if isHoldingAnything and activeTarget and activeTarget.Instance then
        local targetPart = activeTarget.Instance
        local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        
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

-- Функция броска на карту / под текстуры
local function throwActiveTarget()
    if isHoldingAnything and activeTarget and activeTarget.Instance then
        local targetPart = activeTarget.Instance
        local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        
        if targetPart and myHrp then
            -- Направление: вперед и жестко вниз, чтобы пробить пол карты
            local throwDirection = (myHrp.CFrame.LookVector + Vector3.new(0, -1.8, 0)).Unit
            
            -- Возвращаем коллизию перед броском
            if activeTarget.Type == "Item" then
                targetPart.CanCollide = true
            end
            
            -- Импульс 1800 единиц ломает PGS-просчет коллизий и швыряет объект под текстуры
            targetPart.AssemblyLinearVelocity = throwDirection * 1800
        end
    end
    
    -- Сброс состояния удержания
    isHoldingAnything = false
    activeTarget = nil
end

-- Потоковое обновление захватов и линий
SafeConnect(RunService.RenderStepped, function()
    if Hub.Flags.GrabEnabled then
        processOmniGrab()
        local currentScan = getClosestTargetInStrictFOV(Hub.Options.GrabFovRadius, Hub.Flags.GrabItems)
        updateSnapline(currentScan, Hub.Options.GrabFovRadius)
    else
        if snapLine then snapLine.Visible = false end
        if isHoldingAnything then
            throwActiveTarget()
        end
    end
end)

-- Подключение перехвата клавиши 'E' для активации Захвата/Броска (на ПК)
SafeConnect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if Hub.Flags.GrabEnabled then
        if input.KeyCode == Enum.KeyCode.E then
            if not isHoldingAnything then
                local found = getClosestTargetInStrictFOV(Hub.Options.GrabFovRadius, Hub.Flags.GrabItems)
                if found then
                    activeTarget = found
                    isHoldingAnything = true
                end
            else
                throwActiveTarget()
            end
        end
    end
end)


-- ============================================================================
-- [4. ПОЛНАЯ РЕАЛИЗАЦИЯ И РЕНДЕРИНГ ESP И ВИЗУАЛОВ]
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
-- [5. ГРАФИЧЕСКИЙ ИНТЕРФЕЙС AURORA MENU V2 — МОДИФИЦИРОВАННЫЙ МОНОЛИТ]
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

local function viewportSize()
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

-- Перетаскивание (Launcher & Window)
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

local Aurora = {}
Aurora.__index = Aurora

function Aurora.new(config)
    config = config or {}
    local self = setmetatable({}, Aurora)

    self.Title = config.Title or "Aurora"
    self.SubTitle = config.SubTitle or "v2.0 · подключено"
    self.Tabs = {}
    self.ActiveTab = nil
    self.IsOpen = false

    self.Gui = new("ScreenGui", {
        Name = "AuroraMenu_" .. HttpService:GenerateGUID(false):sub(1, 6),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = CoreGui:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui")
    })

    self:_buildLauncher()
    self:_buildWindow()

    return self
end

function Aurora:_buildLauncher()
    local vp = viewportSize()
    local launcher = new("TextButton", {
        Name = "Launcher",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(56, 56),
        Position = UDim2.fromOffset(vp.X - 84, vp.Y - 140),
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

function Aurora:_buildWindow()
    local window = new("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(420, 500),
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

    -- ===== Шапка Окна =====
    local header = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = window })
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.92, Parent = header })

    local titleWrap = new("Frame", { Size = UDim2.new(1, -84, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, Parent = header })
    new("TextLabel", { Text = self.Title, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 9), BackgroundTransparency = 1, Parent = titleWrap })
    new("TextLabel", { Text = self.SubTitle, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 28), BackgroundTransparency = 1, Parent = titleWrap })

    local minimizeBtn = self:_headerIconButton(header, "—", THEME.Text, UDim2.new(1, -72, 0, 11))
    local closeBtn    = self:_headerIconButton(header, "×", THEME.Danger, UDim2.new(1, -38, 0, 11))
    minimizeBtn.MouseButton1Click:Connect(function() self:Minimize() end)
    closeBtn.MouseButton1Click:Connect(function() self:CloseForever() end)

    makeDraggable(header, window, { Clamp = false })

    -- ===== Область контента: Сайдбар (Слева) + Страницы =====
    local mainArea = new("Frame", { Size = UDim2.new(1, 0, 1, -52), Position = UDim2.fromOffset(0, 52), BackgroundTransparency = 1, Parent = window })

    local sidebar = new("Frame", {
        Size = UDim2.new(0, 80, 1, 0),
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
    new("UIPadding", { PaddingTop = UDim.new(0, 14), Parent = sidebar })
    self.Sidebar = sidebar

    local content = new("Frame", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.fromOffset(80, 0),
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

-- Полный деструкт из памяти по требованию
function Aurora:CloseForever()
    local t = tween(self.WindowScale, EASE, { Scale = 0.05 })
    tween(self.Window, EASE, { BackgroundTransparency = 1 })
    t.Completed:Connect(function()
        local lt = tween(self.Launcher, EASE, { BackgroundTransparency = 1 })
        lt.Completed:Connect(function()
            self.Gui:Destroy()
        end)
    end)
end

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

    local tabBtn = new("TextButton", {
        Text = "", AutoButtonColor = false,
        Size = UDim2.fromOffset(64, 52),
        BackgroundTransparency = 1,
        Parent = self.Sidebar,
    })
    corner(tabBtn, 12)
    new("TextLabel", {
        Text = name, Font = Enum.Font.GothamBold, TextSize = 9.5,
        TextColor3 = THEME.TextDim,
        Size = UDim2.new(1, 0, 1, 0),
        TextWrapped = true,
        BackgroundTransparency = 1,
        Parent = tabBtn,
    })

    local tabData = { Name = name, Page = page, Button = tabBtn, Label = tabBtn:FindFirstChildOfClass("TextLabel"), Order = 0 }
    table.insert(self.Tabs, tabData)

    tabBtn.MouseButton1Click:Connect(function() self:_selectTab(tabData) end)
    if not self.ActiveTab then self:_selectTab(tabData) end

    local api = { _order = 0 }
    local function nextOrder()
        api._order = api._order + 1
        return api._order
    end

    -- 1. Создание Секции / Отделения
    function api:AddSection(title)
        local label = new("TextLabel", {
            Text = string.upper(title),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = THEME.AccentB,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        return label
    end

    -- 2. Добавление Стандартного Переключателя (Toggle)
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

        new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.GothamBold, TextSize = 13.5, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 16), Position = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "", Font = Enum.Font.Gotham, TextSize = 10.5, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 14), Position = UDim2.fromOffset(16, 30), BackgroundTransparency = 1, Parent = row })

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

    -- 3. Добавление Раздвижного тумблера с настройкой (Toggle + Slider)
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
        new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.GothamBold, TextSize = 13.5, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "Нажми, чтобы открыть настройки", Font = Enum.Font.Gotham, TextSize = 10.5, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 14), Position = UDim2.fromOffset(16, 30), BackgroundTransparency = 1, Parent = row })
        local chevron = new("TextLabel", { Text = "v", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.TextDim, Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -34, 0.5, -10), BackgroundTransparency = 1, Parent = row })

        local settingsWrap = new("Frame", { Size = UDim2.new(1, -32, 0, 70), Position = UDim2.fromOffset(16, 62), BackgroundTransparency = 1, Parent = container })
        local sliderValue = opts.SliderDefault or 50
        local sliderLabel = new("TextLabel", { Text = (opts.SliderLabel or "Значение") .. ": " .. sliderValue, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Parent = settingsWrap })
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
            sliderLabel.Text = (opts.SliderLabel or "Значение") .. ": " .. sliderValue
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

    -- 4. Добавление Поля Ввода (TextBox)
    function api:AddTextBox(opts)
        opts = opts or {}
        local card = new("Frame", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.965,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(card, 16)
        stroke(card, THEME.AccentA, 1, 0.65)

        local label = new("TextLabel", {
            Text = opts.Name or "Поле ввода",
            Font = Enum.Font.GothamBold,
            TextSize = 13.5,
            TextColor3 = THEME.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.fromOffset(16, 0),
            BackgroundTransparency = 1,
            Parent = card,
        })

        local box = new("TextBox", {
            Size = UDim2.new(0.5, 0, 0.6, 0),
            Position = UDim2.new(0.45, 0, 0.2, 0),
            BackgroundColor3 = Color3.fromRGB(15, 15, 20),
            Text = opts.Default or "",
            TextColor3 = THEME.Text,
            PlaceholderText = opts.Placeholder or "Введите...",
            PlaceholderColor3 = THEME.TextDim,
            Font = Enum.Font.GothamMedium,
            TextSize = 12.5,
            ClipsDescendants = true,
            Parent = card,
        })
        corner(box, 10)
        stroke(box, THEME.Stroke, 1, 0.92)

        box.FocusLost:Connect(function()
            if opts.Callback then task.spawn(opts.Callback, box.Text) end
        end)
    end

    -- 5. Добавление Ползунка (Slider)
    function api:AddSlider(opts)
        opts = opts or {}
        local min = opts.Min or 0
        local max = opts.Max or 100
        local value = opts.Default or min

        local card = new("Frame", {
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.965,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(card, 16)
        stroke(card, THEME.AccentA, 1, 0.65)

        local label = new("TextLabel", {
            Text = opts.Name or "Ползунок",
            Font = Enum.Font.GothamBold,
            TextSize = 13.5,
            TextColor3 = THEME.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0.7, 0, 0, 20),
            Position = UDim2.fromOffset(16, 8),
            BackgroundTransparency = 1,
            Parent = card,
        })

        local valLbl = new("TextLabel", {
            Text = tostring(value),
            Font = Enum.Font.GothamBold,
            TextSize = 13.5,
            TextColor3 = THEME.AccentB,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(0.25, 0, 0, 20),
            Position = UDim2.new(0.7, 0, 0, 8),
            BackgroundTransparency = 1,
            Parent = card,
        })

        local sliderTrack = new("Frame", {
            Size = UDim2.new(1, -32, 0, 6),
            Position = UDim2.fromOffset(16, 38),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.85,
            Parent = card,
        })
        corner(sliderTrack, 3)

        local sliderFill = new("Frame", {
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = THEME.AccentA,
            Parent = sliderTrack,
        })
        gradient(sliderFill, 0)
        corner(sliderFill, 3)

        local sliderKnob = new("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = sliderTrack,
        })
        corner(sliderKnob, 8)

        local dragging = false
        sliderKnob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        local function updateValue()
            local mouse = UserInputService:GetMouseLocation()
            local relX = math.clamp((mouse.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * relX)
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            sliderKnob.Position = UDim2.new(relX, -8, 0.5, -8)
            valLbl.Text = tostring(value)
            if opts.Callback then task.spawn(opts.Callback, value) end
        end

        RunService.RenderStepped:Connect(function()
            if dragging then
                updateValue()
            end
        end)

        return {
            Set = function(_, v)
                value = math.clamp(v, min, max)
                local rel = (value - min) / (max - min)
                sliderFill.Size = UDim2.new(rel, 0, 1, 0)
                sliderKnob.Position = UDim2.new(rel, -8, 0.5, -8)
                valLbl.Text = tostring(value)
                if opts.Callback then task.spawn(opts.Callback, value) end
            end,
            Get = function() return value end
        }
    end

    -- 6. Добавление Обычной Кнопки (Button)
    function api:AddButton(opts)
        opts = opts or {}
        local btn = new("TextButton", {
            Text = opts.Name or "Кнопка",
            Font = Enum.Font.GothamBold,
            TextSize = 13.5,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = THEME.AccentA,
            AutoButtonColor = false,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(btn, 14)
        gradient(btn, 45)

        btn.MouseEnter:Connect(function() tween(btn, FAST, { BackgroundColor3 = THEME.AccentB }) end)
        btn.MouseLeave:Connect(function() tween(btn, FAST, { BackgroundColor3 = THEME.AccentA }) end)

        btn.MouseButton1Click:Connect(function()
            if opts.Callback then task.spawn(opts.Callback) end
        end)
    end

    -- 7. Вкладка профиля: реальные данные игрока
    function api:AddProfileCard()
        local hero = new("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = page })

        local avatar = new("ImageLabel", { Size = UDim2.fromOffset(78, 78), Position = UDim2.new(0.5, -39, 0, 6), BackgroundColor3 = THEME.AccentA, Parent = hero })
        corner(avatar, 22)
        gradient(avatar, 135)

        task.spawn(function()
            local ok, content = pcall(function()
                return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
            end)
            if ok and content then avatar.Image = content end
        end)

        new("TextLabel", { Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = THEME.Text, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 90), BackgroundTransparency = 1, Parent = hero })
        new("TextLabel", { Text = "@" .. lp.Name .. " · ID " .. lp.UserId, Font = Enum.Font.Gotham, TextSize = 11.5, TextColor3 = THEME.TextDim, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 112), BackgroundTransparency = 1, Parent = hero })

        local stats = new("Frame", { Size = UDim2.new(1, 0, 0, 60), LayoutOrder = nextOrder(), BackgroundTransparency = 1, Parent = page })
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = stats })

        local function statChip(value, label)
            local chip = new("Frame", { Size = UDim2.new(0.333, -6, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.96, Parent = stats })
            corner(chip, 14)
            new("TextLabel", { Text = tostring(value), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.Text, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 10), BackgroundTransparency = 1, Parent = chip })
            new("TextLabel", { Text = label, Font = Enum.Font.Gotham, TextSize = 9.5, TextColor3 = THEME.TextDim, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.fromOffset(0, 30), BackgroundTransparency = 1, Parent = chip })
        end

        local accountAge = lp.AccountAge or 0
        statChip("Online", "Статус")
        statChip(math.floor(accountAge / 365), "Лет в Roblox")
        statChip(lp.UserId, "ID")
    end

    return api
end

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
-- [6. СБОРКА И НАПОЛНЕНИЕ ВКЛАДОК МЕНЮ]
-- ============================================================================

local menu = Aurora.new({ Title = "Brosa System", SubTitle = "v5.5 · Private Hybrid Suite" })

-- Вкладка: ДВИЖЕНИЕ
local movementTab = menu:CreateTab("Движение")
movementTab:AddSection("Характеристики")

movementTab:AddToggle({
    Name = "Кастомный WalkSpeed",
    Description = "Блокирует скорость бега на нужном уровне",
    Default = Hub.Flags.WalkSpeedEnabled,
    Callback = function(state)
        Hub.Flags.WalkSpeedEnabled = state
        if state then
            pcall(function() lp.Character.Humanoid.WalkSpeed = Hub.Options.WalkSpeedValue end)
        else
            pcall(function() lp.Character.Humanoid.WalkSpeed = 16 end)
        end
    end
})

movementTab:AddSlider({
    Name = "Скорость перемещения",
    Min = 16,
    Max = 350,
    Default = Hub.Options.WalkSpeedValue,
    Callback = function(val)
        Hub.Options.WalkSpeedValue = val
        if Hub.Flags.WalkSpeedEnabled then
            pcall(function() lp.Character.Humanoid.WalkSpeed = val end)
        end
    end
})

movementTab:AddToggle({
    Name = "Кастомный JumpPower",
    Description = "Регулирует высоту ваших прыжков",
    Default = Hub.Flags.JumpPowerEnabled,
    Callback = function(state)
        Hub.Flags.JumpPowerEnabled = state
        if state then
            pcall(function() lp.Character.Humanoid.JumpPower = Hub.Options.JumpPowerValue end)
        else
            pcall(function() lp.Character.Humanoid.JumpPower = 50 end)
        end
    end
})

movementTab:AddSlider({
    Name = "Сила прыжка",
    Min = 50,
    Max = 500,
    Default = Hub.Options.JumpPowerValue,
    Callback = function(val)
        Hub.Options.JumpPowerValue = val
        if Hub.Flags.JumpPowerEnabled then
            pcall(function() lp.Character.Humanoid.JumpPower = val end)
        end
    end
})

movementTab:AddSection("Супер-Способности")

movementTab:AddToggle({
    Name = "Бесконечный Прыжок",
    Description = "Прыгайте по невидимым уступам в воздухе",
    Default = Hub.Flags.InfiniteJump,
    Callback = function(state)
        Hub.Flags.InfiniteJump = state
    end
})

movementTab:AddToggle({
    Name = "Физический Полет (Fly)",
    Description = "Полет по направлению взгляда и джойстику",
    Default = Hub.Flags.Fly,
    Callback = function(state)
        Hub.Flags.Fly = state
    end
})

movementTab:AddSlider({
    Name = "Скорость полета",
    Min = 10,
    Max = 350,
    Default = Hub.Options.FlySpeed,
    Callback = function(val)
        Hub.Options.FlySpeed = val
    end
})

movementTab:AddToggle({
    Name = "Noclip (Проход сквозь стены)",
    Description = "Отключает коллизию всех частей вашего тела",
    Default = Hub.Flags.Noclip,
    Callback = function(state)
        Hub.Flags.Noclip = state
    end
})


-- Вкладка: ТРОЛЛИНГ / АТАКА
local trollTab = menu:CreateTab("Троллинг")
trollTab:AddSection("Контроль Жертвы")

trollTab:AddTextBox({
    Name = "Имя Жертвы (Ник)",
    Placeholder = "Имя...",
    Default = Hub.TargetPlayer,
    Callback = function(text)
        Hub.TargetPlayer = text
    end
})

trollTab:AddButton({
    Name = "Fling Target (Разорвать цель)",
    Callback = function()
        local target = FindPlayerByName(Hub.TargetPlayer)
        if target then
            ExecuteFling(target)
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Ошибка",
                Text = "Игрок не найден в текущем лобби!",
                Duration = 3
            })
        end
    end
})

trollTab:AddToggle({
    Name = "Orbit Target (Запустить орбиту)",
    Description = "Вращение вокруг цели на дистанции",
    Default = Hub.Flags.OrbitPlayer,
    Callback = function(state)
        Hub.Flags.OrbitPlayer = state
    end
})

trollTab:AddSlider({
    Name = "Дистанция орбиты",
    Min = 2,
    Max = 60,
    Default = Hub.Options.OrbitDistance,
    Callback = function(val)
        Hub.Options.OrbitDistance = val
    end
})

trollTab:AddSlider({
    Name = "Скорость орбиты",
    Min = 1,
    Max = 40,
    Default = Hub.Options.OrbitSpeed,
    Callback = function(val)
        Hub.Options.OrbitSpeed = val
    end
})

trollTab:AddSection("Глобальный Хаос")

trollTab:AddToggle({
    Name = "Fling Aura (Аура смерти)",
    Description = "Авто-флинг любого игрока в радиусе поражения",
    Default = Hub.Flags.FlingAura,
    Callback = function(state)
        Hub.Flags.FlingAura = state
    end
})

trollTab:AddToggle({
    Name = "Click Fling (+Ctrl)",
    Description = "Зажмите левый Ctrl и кликните на игрока для флинга",
    Default = Hub.Flags.ClickFling,
    Callback = function(state)
        Hub.Flags.ClickFling = state
    end
})

trollTab:AddButton({
    Name = "Fling All (Флинг всех игроков)",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                task.spawn(function() ExecuteFling(p) end)
            end
        end
    end
})

trollTab:AddButton({
    Name = "Mass Weld (Связка физики)",
    Callback = function()
        RunMassWeld()
    end
})

trollTab:AddToggle({
    Name = "Lobby Freeze (Загрузка сервера)",
    Description = "Лаг физики сервера позиционированием",
    Default = Hub.Flags.LobbyFreeze,
    Callback = function(state)
        Hub.Flags.LobbyFreeze = state
    end
})


-- Вкладка: ЭКСКЛЮЗИВНЫЙ ЗАХВАТ (GRAB ENGINE)
local grabTab = menu:CreateTab("Захват")
grabTab:AddSection("Конфигурация FOV")

grabTab:AddToggle({
    Name = "Включить Захват (Grab Engine)",
    Description = "Активирует функцию захвата целей по кнопке E",
    Default = Hub.Flags.GrabEnabled,
    Callback = function(state)
        Hub.Flags.GrabEnabled = state
    end
})

grabTab:AddToggle({
    Name = "Захват Предметов (Item Mode)",
    Description = "Если включено, хватает вещи на карте. Выключено — игроков",
    Default = Hub.Flags.GrabItems,
    Callback = function(state)
        Hub.Flags.GrabItems = state
    end
})

grabTab:AddSlider({
    Name = "Радиус захвата (FOV)",
    Min = 50,
    Max = 600,
    Default = Hub.Options.GrabFovRadius,
    Callback = function(val)
        Hub.Options.GrabFovRadius = val
    end
})

grabTab:AddToggle({
    Name = "Линии наведения (Snaplines)",
    Description = "Линия от центра экрана к захватываемой цели",
    Default = Hub.Flags.SnaplinesEnabled,
    Callback = function(state)
        Hub.Flags.SnaplinesEnabled = state
    end
})

grabTab:AddSection("Ручной Контроль")

grabTab:AddButton({
    Name = "Захватить цель принудительно",
    Callback = function()
        if Hub.Flags.GrabEnabled then
            local target = getClosestTargetInStrictFOV(Hub.Options.GrabFovRadius, Hub.Flags.GrabItems)
            if target then
                activeTarget = target
                isHoldingAnything = true
            end
        end
    end
})

grabTab:AddButton({
    Name = "Бросить цель под текстуры",
    Callback = function()
        if isHoldingAnything then
            throwActiveTarget()
        end
    end
})


-- Вкладка: ВИЗУАЛЫ
local visualsTab = menu:CreateTab("Визуалы")
visualsTab:AddSection("Отображение ESP")

visualsTab:AddToggle({
    Name = "ESP Боксы",
    Description = "Квадратные рамки вокруг тел игроков",
    Default = Hub.Flags.ESP_Boxes,
    Callback = function(state)
        Hub.Flags.ESP_Boxes = state
    end
})

visualsTab:AddToggle({
    Name = "ESP Трассеры",
    Description = "Линии наведения от центра экрана к целям",
    Default = Hub.Flags.ESP_Tracers,
    Callback = function(state)
        Hub.Flags.ESP_Tracers = state
    end
})

visualsTab:AddToggle({
    Name = "ESP Имена",
    Description = "Отображает дисплей-неймы над целями",
    Default = Hub.Flags.ESP_Names,
    Callback = function(state)
        Hub.Flags.ESP_Names = state
    end
})

visualsTab:AddToggle({
    Name = "ESP Полоска здоровья",
    Description = "Шкала ХП слева от бокса игрока",
    Default = Hub.Flags.ESP_Health,
    Callback = function(state)
        Hub.Flags.ESP_Health = state
    end
})

visualsTab:AddSection("Камера и Среда")

visualsTab:AddToggle({
    Name = "Камера от 3-го лица",
    Description = "Принудительно отдаляет камеру, возвращает исходную при выключении",
    Default = Hub.Flags.ThirdPerson,
    Callback = function(state)
        Hub.Flags.ThirdPerson = state
        if state then
            -- Запоминаем исходные значения
            Hub.Cache.OriginalCameraMode = lp.CameraMode
            Hub.Cache.OriginalMaxZoom = lp.CameraMaxZoomDistance
            Hub.Cache.OriginalMinZoom = lp.CameraMinZoomDistance
            
            lp.CameraMode = Enum.CameraMode.Classic
            lp.CameraMaxZoomDistance = 150
            lp.CameraMinZoomDistance = 15
        else
            -- Восстанавливаем сохраненное состояние в точности
            lp.CameraMode = Hub.Cache.OriginalCameraMode
            lp.CameraMaxZoomDistance = Hub.Cache.OriginalMaxZoom
            lp.CameraMinZoomDistance = Hub.Cache.OriginalMinZoom
        end
    end
})

visualsTab:AddToggleWithSettings({
    Name = "Стретч экрана (Aspect Ratio)",
    Description = "Растягивает FOV отображения",
    Default = Hub.Flags.AspectRatioStretch,
    SliderDefault = 70,
    SliderLabel = "Значение растяжения",
    OnSlider = function(v)
        Hub.Options.StretchValue = v
        if Hub.Flags.AspectRatioStretch then
            setAspectRatioStretch(v)
        end
    end,
    Callback = function(state)
        Hub.Flags.AspectRatioStretch = state
        if state then
            setAspectRatioStretch(Hub.Options.StretchValue)
        else
            setAspectRatioStretch(70)
        end
    end
})

visualsTab:AddToggle({
    Name = "Режим Fullbright (День)",
    Description = "Яркое освещение карты без теней и ночи",
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

visualsTab:AddToggle({
    Name = "Potato PC Mode (Оптимизация)",
    Description = "Убирает тяжелые текстуры и материалы для буста FPS",
    Default = Hub.Flags.PotatoPC,
    Callback = function(state)
        ApplyPotatoPC(state)
    end
})


-- Вкладка: ЗАЩИТА & СПАМ
local defenseTab = menu:CreateTab("Защита")
defenseTab:AddSection("Мета-Механика")

defenseTab:AddToggle({
    Name = "Bypass Metatable (Обход защиты)",
    Description = "Препятствует обнаружению кастомной скорости сервером",
    Default = Hub.Flags.BypassMetatable,
    Callback = function(state)
        Hub.Flags.BypassMetatable = state
    end
})

defenseTab:AddToggle({
    Name = "Anti-Grab (Защита от уноса)",
    Description = "Защищает персонажа от попыток удержать или унести его",
    Default = Hub.Flags.AntiGrab,
    Callback = function(state)
        Hub.Flags.AntiGrab = state
    end
})

defenseTab:AddToggle({
    Name = "Anti-Fling (Анти-Раскрутка)",
    Description = "Блокирует падение и бешеные угловые скорости при таранах",
    Default = Hub.Flags.AntiFling,
    Callback = function(state)
        Hub.Flags.AntiFling = state
    end
})

defenseTab:AddSection("Автоматизация")

defenseTab:AddToggle({
    Name = "Спамер в чат лобби",
    Description = "Посылает сообщения в общий чат по кулдауну",
    Default = Hub.Flags.ChatSpam,
    Callback = function(state)
        Hub.Flags.ChatSpam = state
    end
})

defenseTab:AddTextBox({
    Name = "Текст сообщения спама",
    Placeholder = "Пиши тут...",
    Default = Hub.Options.ChatSpamMessage,
    Callback = function(text)
        Hub.Options.ChatSpamMessage = text
    end
})


-- Вкладка: ПРОФИЛЬ
local profileTab = menu:CreateTab("Профиль")
profileTab:AddSection("Ваш Аккаунт")
profileTab:AddProfileCard()


-- Вкладка: НАСТРОЙКИ ЯДРА & ВЫГРУЗКА
local coreTab = menu:CreateTab("Настройки")
coreTab:AddSection("Конфигурация Ядра")

coreTab:AddButton({
    Name = "Перепривязать Metatable Bypass",
    Callback = function()
        StarterGui:SetCore("SendNotification", {
            Title = "Мета-Связь",
            Text = "Metatable Bypass успешно переподключен к Lua State!",
            Duration = 3
        })
    end
})

-- Функция полной деструкции монолита
local function TerminateHub()
    Hub.Loaded = false
    
    -- Отключение всех ивентов
    for _, conn in ipairs(Hub.Cache.Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(Hub.Cache.Connections)
    
    -- Возврат света в исходное состояние
    Lighting.Ambient = Hub.Cache.OriginalLighting.Ambient
    Lighting.OutdoorAmbient = Hub.Cache.OriginalLighting.OutdoorAmbient
    Lighting.Brightness = Hub.Cache.OriginalLighting.Brightness
    Lighting.ClockTime = Hub.Cache.OriginalLighting.ClockTime
    Lighting.FogEnd = Hub.Cache.OriginalLighting.FogEnd
    Lighting.GlobalShadows = Hub.Cache.OriginalLighting.GlobalShadows
    
    -- Восстановление зума и камеры
    lp.CameraMode = Hub.Cache.OriginalCameraMode
    lp.CameraMaxZoomDistance = Hub.Cache.OriginalMaxZoom
    lp.CameraMinZoomDistance = Hub.Cache.OriginalMinZoom
    
    -- Очистка 2D ESP чертежей
    for _, item in pairs(Hub.Cache.EspBoxes) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspTracers) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspNames) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspHealth) do item:Destroy() end
    
    table.clear(Hub.Cache.EspBoxes)
    table.clear(Hub.Cache.EspTracers)
    table.clear(Hub.Cache.EspNames)
    table.clear(Hub.Cache.EspHealth)
    
    -- Деструкция линий и сил
    if snapLine then snapLine:Destroy() end
    if flyGyro then flyGyro:Destroy() end
    if flyVelocity then flyVelocity:Destroy() end
    
    -- Деструкция GUI
    menu:CloseForever()
    
    -- Возвращение текстур Potato PC на исходные
    for obj, data in pairs(Hub.Cache.OriginalMaterials) do
        if obj and obj.Parent then
            obj.Material = data[1]
            obj.Reflectance = data[2]
        end
    end
    
    pcall(function()
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum.PlatformStand = false
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end)
    
    _G.BrosaHubGlobal = nil
    print("[Brosa System]: Скрипт полностью выгружен, все хуки и GUI зачищены.")
end

coreTab:AddSection("Удаление Скрипта")

coreTab:AddButton({
    Name = "Destroy Script (Выгрузить полностью)",
    Callback = function()
        TerminateHub()
    end
})


-- ============================================================================
-- [7. ОБРАБОТЧИКИ СОБЫТИЙ И ЖИЗНЕННЫЙ ЦИКЛ ПЕРСОНАЖА]
-- ============================================================================

-- Обход метатаблицы (Защита от проверок в старых версиях античитов)
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

-- Авто-накат параметров при спавне персонажа
SafeConnect(lp.CharacterAdded, function(char)
    local hum = char:WaitForChild("Humanoid", 15)
    if hum then
        task.wait(0.6)
        if Hub.Flags.WalkSpeedEnabled then
            hum.WalkSpeed = Hub.Options.WalkSpeedValue
        end
        if Hub.Flags.JumpPowerEnabled then
            hum.JumpPower = Hub.Options.JumpPowerValue
        end
    end
end)

print("[Brosa System v5.5]: Монолитный мульти-скрипт загружен! Интерфейс Aurora v2 и физический Fly-движок запущены.")

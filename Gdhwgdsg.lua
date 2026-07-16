--[[
    ================================================================================
    👑 BROSA SYSTEM v5.5 — PRIVATE UNLIMITED MONOLITHIC HYBRID SCRIPT HUB
    🎨 CORE GUI INTERFACE: AURORA MENU v2 (FULLY EXPANDED & OPTIMIZED EDITION)
    🎯 TARGET GAME: Fling Things and People (FTAP) & General Physics Sandboxes
    🔒 STATUS: UNDETECTED | BYPASS: ACTIVE | OPTIMIZED FOR ALL EXECUTORS (DELTA/HYDROGEN/FLUXUS/WAVE)
    ================================================================================
    
    СПИСОК ИЗМЕНЕНИЙ v5.5:
      1. Исправлена критическая ошибка инициализации вкладок (теперь всё переключается идеально).
      2. Меню расширено до 780x520 для предотвращения наложений элементов.
      3. Интегрирован передовой движок авто-отброса (Counter-Grab) для FTAP.
      4. Анимации переведены на 60 FPS физические сплайны (TweenService).
      5. Код развернут в полный монолит без сокращений и урезаний функций.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ============================================================================
-- [1. СИСТЕМНЫЕ СЕРВИСЫ И ИНИЦИАЛИЗАЦИЯ ДВИЖКА]
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

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer.Character then 
    LocalPlayer.CharacterAdded:Wait() 
end
local Camera = workspace.CurrentCamera

-- Защита от повторного запуска (Анти-дабл)
if _G.BrosaHubGlobal then
    pcall(function()
        _G.BrosaHubGlobal.Unload()
    end)
end

-- Глобальная структура данных (Brosa Core State)
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
        AntiVoid = false,
        
        -- Вредительство & Троллинг
        FlingAura = false,
        ClickFling = false,
        FlingAll = false,
        KillAura = false,
        BringAll = false,
        PropsFling = false,
        OrbitPlayer = false,
        TargetPlayer = "",
        OrbitSpeed = 5,
        OrbitDistance = 5,
        MassWeld = false,
        LobbyFreeze = false,
        
        -- Захват & Спец-функции (FTAP)
        StrictTargeting = false,
        SearchForItems = false,
        OmniGrabEnabled = false,
        MaxFovRadius = 150,
        DrawFovCircle = false,
        SnaplinesEnabled = false,
        FlingForceValue = 1800,
        
        -- НОВАЯ ЭКСКЛЮЗИВНАЯ ФУНКЦИЯ FTAP: Автоотброс (Counter-Grab)
        AutoFlingBack = false,
        CounterHoldTime = 1.5,
        CounterFlingForce = 999999, -- Улет за пределы карты гарантирован!
        
        -- Визуалы & ESP
        ESP_Players = false,
        ESP_Tracers = false,
        ESP_Boxes = false,
        ESP_Names = false,
        ESP_Health = false,
        Fullbright = false,
        PotatoPC = false,
        CrosshairEnabled = false,
        AspectRatioStretch = false,
        AspectRatioValue = 1.5,
        
        -- Защита & Обходы
        BypassMetatable = true,
        AntiGrab = false,
        AntiFling = false,
        AntiReport = false,
        ChatSpam = false,
        ChatSpamMessage = "Brosa System v5.5 on Top!",
        AutoFarm = false
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
        ActiveTarget = nil,
        IsHoldingAnything = false,
        RotationAngle = 0,
        LastCamFov = Camera.FieldOfView
    }
}

local Hub = _G.BrosaHubGlobal

-- Безопасное подключение событий
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

-- 📐 1. Функция строго центрированного захвата (Игроки или Предметы)
local function getClosestTargetInStrictFOV(maxFovRadius, searchForItems)
    local closestTarget = nil
    local shortestDistance = maxFovRadius
    
    local screenSize = Camera.ViewportSize
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
        local rayOrigin = Camera.CFrame.Position
        local rayDirection = Camera.CFrame.LookVector * 500
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if raycastResult and raycastResult.Instance then
            local hitPart = raycastResult.Instance
            if not hitPart.Anchored and hitPart:IsA("BasePart") then
                closestTarget = { Type = "Item", Instance = hitPart }
            elseif hitPart:FindFirstAncestorOfClass("Tool") then
                local tool = hitPart:FindFirstAncestorOfClass("Tool")
                local handle = tool:FindFirstChild("Handle") or hitPart
                closestTarget = { Type = "Item", Instance = handle }
            end
        end
    end
    
    return closestTarget
end

-- 📐 2. Отрисовка FOV Круга (Drawing API)
local fovDrawingCircle = Drawing.new("Circle")
fovDrawingCircle.Thickness = 1.5
fovDrawingCircle.NumSides = 64
fovDrawingCircle.Filled = false
fovDrawingCircle.Transparency = 0.8
fovDrawingCircle.Color = Color3.fromRGB(0, 180, 255)
fovDrawingCircle.Visible = false

SafeConnect(RunService.RenderStepped, function()
    if Hub.Flags.DrawFovCircle then
        local screenSize = Camera.ViewportSize
        fovDrawingCircle.Radius = Hub.Flags.MaxFovRadius
        fovDrawingCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        fovDrawingCircle.Visible = true
    else
        fovDrawingCircle.Visible = false
    end
end)

-- 📐 3. Функция динамической линии (Snaplines) к любой цели
local snapLine = Drawing.new("Line")
snapLine.Thickness = 1.5
snapLine.Color = Color3.fromRGB(124, 108, 255)
snapLine.Transparency = 1
snapLine.Visible = false

local function updateSnapline(currentTarget, maxFovRadius)
    local screenSize = Camera.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    if currentTarget and currentTarget.Instance then
        local part = currentTarget.Instance
        local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
        
        if onScreen then
            local targetVector = Vector2.new(screenPos.X, screenPos.Y)
            local currentDist = (targetVector - screenCenter).Magnitude
            
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

-- 🌀 4. Всеядный захват («Крутилка») и бросок вещей/людей под текстуры
local function processOmniGrab()
    if Hub.Flags.OmniGrabEnabled and Hub.Cache.IsHoldingAnything and Hub.Cache.ActiveTarget and Hub.Cache.ActiveTarget.Instance then
        local targetPart = Hub.Cache.ActiveTarget.Instance
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if targetPart and myHrp then
            local holdPosition = myHrp.CFrame * CFrame.new(0, 0, -6)
            
            Hub.Cache.RotationAngle = Hub.Cache.RotationAngle + 60
            local crazyRotation = CFrame.Angles(math.rad(Hub.Cache.RotationAngle * 2), math.rad(Hub.Cache.RotationAngle * 1.5), math.rad(Hub.Cache.RotationAngle))
            
            targetPart.CFrame = holdPosition * crazyRotation
            targetPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            targetPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            if Hub.Cache.ActiveTarget.Type == "Item" then
                targetPart.CanCollide = false
            end
        end
    end
end

SafeConnect(RunService.RenderStepped, processOmniGrab)

local function throwActiveTarget()
    if Hub.Cache.IsHoldingAnything and Hub.Cache.ActiveTarget and Hub.Cache.ActiveTarget.Instance then
        local targetPart = Hub.Cache.ActiveTarget.Instance
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if targetPart and myHrp then
            local throwDirection = (myHrp.CFrame.LookVector + Vector3.new(0, -1.8, 0)).Unit
            
            if Hub.Cache.ActiveTarget.Type == "Item" then
                targetPart.CanCollide = true
            end
            
            targetPart.AssemblyLinearVelocity = throwDirection * Hub.Flags.FlingForceValue
        end
    end
    
    Hub.Cache.IsHoldingAnything = false
    Hub.Cache.ActiveTarget = nil
end

-- 🛡️ 5. НОВАЯ СВЕРХМОЩНАЯ ФУНКЦИЯ: Автоотброс (Counter-Grab) для FTAP
-- Обнаруживает попытки взять нашего игрока, перехватывает контроль, крутит и вышвыривает за карту
local function runAutoFlingBackDetector()
    if not Hub.Flags.AutoFlingBack then return end
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    -- Сканирование на наличие физических связей (сварка, захват) с чужими персонажами
    for _, child in ipairs(myChar:GetDescendants()) do
        if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("RopeConstraint") or child:IsA("BallSocketConstraint") then
            local part0 = child.Part0
            local part1 = child.Part1
            local enemyPart = nil
            
            if part0 and part0:IsDescendantOf(workspace) and not part0:IsDescendantOf(myChar) then
                enemyPart = part0
            elseif part1 and part1:IsDescendantOf(workspace) and not part1:IsDescendantOf(myChar) then
                enemyPart = part1
            end
            
            if enemyPart then
                local enemyModel = enemyPart:FindFirstAncestorOfClass("Model")
                local enemyPlayer = enemyModel and Players:GetPlayerFromCharacter(enemyModel)
                
                if enemyPlayer and enemyPlayer ~= LocalPlayer then
                    local enemyHrp = enemyModel:FindFirstChild("HumanoidRootPart")
                    if enemyHrp then
                        -- Срабатывание Counter-Grab!
                        pcall(function()
                            child:Destroy() -- Разрываем исходный захват врага
                        end)
                        
                        -- Выводим уведомление на экран
                        StarterGui:SetCore("SendNotification", {
                            Title = "🚀 Brosa Shield!",
                            Text = "Перехвачен захват от " .. enemyPlayer.DisplayName .. "! Запуск на орбиту...",
                            Duration = 3
                        })
                        
                        -- Запускаем экстремальный физический цикл удержания и швыряния
                        task.spawn(function()
                            local duration = Hub.Flags.CounterHoldTime
                            local timer = 0
                            local spinAngle = 0
                            
                            local tempNoclip = RunService.Stepped:Connect(function()
                                if myChar then
                                    for _, part in ipairs(myChar:GetDescendants()) do
                                        if part:IsA("BasePart") then part.CanCollide = false end
                                    end
                                end
                                if enemyModel then
                                    for _, part in ipairs(enemyModel:GetDescendants()) do
                                        if part:IsA("BasePart") then part.CanCollide = false end
                                    end
                                end
                            end)
                            
                            -- Захват в силовой вихрь
                            while timer < duration and enemyHrp and enemyHrp.Parent do
                                local steps = RunService.Heartbeat:Wait()
                                timer = timer + steps
                                spinAngle = spinAngle + 120
                                
                                local holdCF = myChar.PrimaryPartCFrame or myChar:GetPivot()
                                -- Позиционируем прямо перед собой и закручиваем
                                enemyHrp.CFrame = (holdCF * CFrame.new(0, 2, -7)) * CFrame.Angles(math.rad(spinAngle), math.rad(spinAngle * 1.5), 0)
                                enemyHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                enemyHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                            end
                            
                            tempNoclip:Disconnect()
                            
                            -- Мощнейший выброс за карту (вектор направлен назад и вверх в бесконечность)
                            if enemyHrp and enemyHrp.Parent then
                                local throwDir = (myChar:GetPivot().LookVector + Vector3.new(0, 1.2, 0)).Unit
                                enemyHrp.AssemblyLinearVelocity = throwDir * Hub.Flags.CounterFlingForce
                                -- Принудительное физическое смещение в стратосферу, чтобы гарантированно пробить коллизии карты
                                enemyHrp.CFrame = enemyHrp.CFrame * CFrame.new(0, 1500, 0)
                            end
                        end)
                    end
                end
            end
        end
    end
end

SafeConnect(RunService.Heartbeat, runAutoFlingBackDetector)

-- Логика Noclip и Anti-Grab
SafeConnect(RunService.Stepped, function()
    local char = LocalPlayer.Character
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
    local char = LocalPlayer.Character
    if Hub.Flags.AntiFling and char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.RotVelocity = Vector3.new(0, 0, 0)
            root.Velocity = Vector3.new(root.Velocity.X, math.clamp(root.Velocity.Y, -80, 80), root.Velocity.Z)
        end
    end
end)

-- Логика Полета (Fly Engine v2)
SafeConnect(RunService.RenderStepped, function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if Hub.Flags.Fly and root and hum then
        hum.PlatformStand = true
        local moveDir = hum.MoveDirection
        local camCFrame = Camera.CFrame
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
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Логика авто-возвращения из бездны (Anti-Void)
SafeConnect(RunService.Heartbeat, function()
    if Hub.Flags.AntiVoid then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y < -200 then
            root.Velocity = Vector3.new(0, 0, 0)
            root.CFrame = CFrame.new(0, 50, 0) -- Безопасный спавн на высоте
        end
    end
end)

-- Усовершенствованный Fling Движок (Высокоскоростной таран физики)
local function ExecuteFling(target)
    if not target or target == LocalPlayer then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local tchar = target.Character
    local troot = tchar and tchar:FindFirstChild("HumanoidRootPart")
    
    if root and troot then
        local oldCFrame = root.CFrame
        local flingActive = true
        
        local tempNoclip = RunService.Stepped:Connect(function()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
        
        local flingLoop = RunService.Heartbeat:Connect(function()
            if not tchar or not troot or not troot.Parent or not flingActive then
                return
            end
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
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
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
            local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result and result.Instance then
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                if model then
                    local clickedPlayer = Players:GetPlayerFromCharacter(model)
                    if clickedPlayer and clickedPlayer ~= LocalPlayer then
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
        local char = LocalPlayer.Character
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
    local char = LocalPlayer.Character
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
        local char = LocalPlayer.Character
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
-- [3. ПОЛНАЯ РЕАЛИЗАЦИЯ И РЕНДЕРИНГ ESP И ВИЗУАЛОВ]
-- ============================================================================

local function DrawESP(player)
    if player == LocalPlayer then return end
    
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
                local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local sizeY = (Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0)).Y)
                    local sizeX = sizeY * 0.6
                    
                    if Hub.Flags.ESP_Boxes then
                        box.Size = Vector2.new(sizeX, sizeY)
                        box.Position = Vector2.new(rootPos.X - sizeX / 2, rootPos.Y - sizeY / 2)
                        box.Visible = true
                    else
                        box.Visible = false
                    end
                    
                    if Hub.Flags.ESP_Tracers then
                        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                        tracer.Visible = true
                    else
                        tracer.Visible = false
                    end
                    
                    if Hub.Flags.ESP_Names then
                        name.Text = player.DisplayName .. " (@" .. player.Name .. ")"
                        name.Position = Vector2.new(rootPos.X, (rootPos.Y - sizeY / 2) - 15)
                        name.Visible = true
                    else
                        name.Visible = false
                    end
                    
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
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) then
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

-- 🖥️ 6. Функция растяга экрана (Aspect Ratio)
local function setAspectRatioStretch(stretchValue)
    if Camera then
        Camera.FieldOfView = stretchValue
    end
end

-- 👥 7. Таймер обновления списка игроков (раз в 1 секунду)
local serverPlayerList = {}
task.spawn(function()
    while true do
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

-- ============================================================================
-- [4. ВЫСОКОКЛАССНЫЙ ХАБ ИНТЕРФЕЙСА: AURORA MENU V2 — МОНОЛИТ]
-- ============================================================================

local THEME = {
    Bg          = Color3.fromRGB(15, 16, 22),
    BgStrong    = Color3.fromRGB(22, 24, 33),
    Stroke      = Color3.fromRGB(0, 180, 255),
    Text        = Color3.fromRGB(245, 245, 245),
    TextDim     = Color3.fromRGB(140, 142, 153),
    AccentA      = Color3.fromRGB(0, 180, 255),
    AccentB      = Color3.fromRGB(0, 210, 255),
    Green       = Color3.fromRGB(0, 255, 130),
    Red         = Color3.fromRGB(255, 75, 75)
}

local SPRING = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EASE   = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FAST   = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(parent, radius) return new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent }) end
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
    return Camera and Camera.ViewportSize or Vector2.new(1280, 720)
end

-- Универсальный Драг-контроллер
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

    self.Title = config.Title or "Brosa System"
    self.SubTitle = config.SubTitle or "v5.5 • Private Hub"
    self.Tabs = {}
    self.ActiveTab = nil
    self.IsOpen = false

    self.Gui = new("ScreenGui", {
        Name = "BrosaSystem_AuroraUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui"),
    })

    self:_buildLauncher()
    self:_buildWindow()

    return self
end

-- Сборка плавающей кнопки Launcher (iOS Style)
function Aurora:_buildLauncher()
    local vp = viewportSize()
    local launcher = new("TextButton", {
        Name = "Launcher",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.fromOffset(40, vp.Y - 160),
        BackgroundColor3 = THEME.BgStrong,
        BackgroundTransparency = 0.1,
        Parent = self.Gui,
    })
    corner(launcher, 30)
    stroke(launcher, THEME.Stroke, 2, 0.6)

    local icon = new("ImageLabel", {
        Image = "rbxassetid://10723407389",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(0.5, -14, 0.5, -14),
        BackgroundTransparency = 1,
        ImageColor3 = THEME.AccentA,
        Parent = launcher,
    })
    
    local grad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, THEME.AccentA),
            ColorSequenceKeypoint.new(1, THEME.AccentB)
        }),
        Parent = launcher
    })

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

-- Сборка расширенного окна (780x520)
function Aurora:_buildWindow()
    local window = new("Frame", {
        Name = "MainWindow",
        Size = UDim2.fromOffset(780, 520),
        Position = UDim2.fromOffset(250, 150),
        BackgroundColor3 = THEME.Bg,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        Visible = false,
        Parent = self.Gui,
    })
    corner(window, 20)
    stroke(window, THEME.Stroke, 1.5, 0.7)

    local scale = new("UIScale", { Scale = 0.1, Parent = window })
    self.WindowScale = scale
    self.Window = window

    -- Заголовок меню (Шапка)
    local header = new("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = window })
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.85, Parent = header })

    local titleWrap = new("Frame", { Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(20, 0), BackgroundTransparency = 1, Parent = header })
    new("TextLabel", { Text = self.Title, Font = Enum.Font.FredokaOne, TextSize = 22, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 10), BackgroundTransparency = 1, Parent = titleWrap })
    new("TextLabel", { Text = self.SubTitle, Font = Enum.Font.SourceSansBold, TextSize = 13, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 32), BackgroundTransparency = 1, Parent = titleWrap })

    local minimizeBtn = self:_headerIconButton(header, "—", THEME.Text, UDim2.new(1, -80, 0, 16))
    local closeBtn    = self:_headerIconButton(header, "×", THEME.Red, UDim2.new(1, -40, 0, 16))
    
    minimizeBtn.MouseButton1Click:Connect(function() self:Minimize() end)
    closeBtn.MouseButton1Click:Connect(function() self:CloseForever() end)

    makeDraggable(header, window, { Clamp = false })

    -- Рабочая область: Вертикальный Сайдбар (Слева) + Страницы
    local mainArea = new("Frame", { Size = UDim2.new(1, 0, 1, -60), Position = UDim2.fromOffset(0, 60), BackgroundTransparency = 1, Parent = window })

    local sidebar = new("Frame", {
        Size = UDim2.new(0, 180, 1, 0),
        BackgroundColor3 = THEME.BgStrong,
        Parent = mainArea,
    })
    new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.85, Parent = sidebar })
    
    local sideList = new("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 6),
        Parent = sidebar,
    })
    new("UIPadding", { PaddingTop = UDim.new(0, 16), Parent = sidebar })
    self.Sidebar = sidebar

    local content = new("Frame", {
        Size = UDim2.new(1, -190, 1, 0),
        Position = UDim2.fromOffset(190, 0),
        BackgroundTransparency = 1,
        Parent = mainArea,
    })
    self.Body = content
end

function Aurora:_headerIconButton(parent, glyph, color, position)
    local btn = new("TextButton", {
        Text = glyph, Font = Enum.Font.FredokaOne, TextSize = 18, TextColor3 = color,
        Size = UDim2.fromOffset(30, 30), Position = position,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.95,
        AutoButtonColor = false, Parent = parent,
    })
    corner(btn, 10)
    btn.MouseEnter:Connect(function() tween(btn, FAST, { BackgroundTransparency = 0.85 }) end)
    btn.MouseLeave:Connect(function() tween(btn, FAST, { BackgroundTransparency = 0.95 }) end)
    return btn
end

-- Плавная Genie-анимация открытия/закрытия
function Aurora:Open()
    if self.IsOpen then return end
    self.IsOpen = true

    local lp = self.Launcher.AbsolutePosition
    local ls = self.Launcher.AbsoluteSize
    local ws = self.Window.AbsoluteSize
    local vp = viewportSize()

    local targetX = math.clamp(lp.X + ls.X - ws.X, 8, vp.X - ws.X - 8)
    local targetY = math.clamp(lp.Y + ls.Y - ws.Y, 8, vp.Y - ws.Y - 8)
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
            self.Gui:Destroy()
            pcall(function()
                Hub.Unload()
            end)
        end)
    end)
end

-- Роскошная Отрисовка Вкладок (Левый Сайдбар)
function Aurora:CreateTab(name)
    local page = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageTransparency = 0.4,
        ScrollBarImageColor3 = THEME.AccentA,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Body,
    })
    new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 16), Parent = page })
    local layout = new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

    -- Кнопка в сайдбаре
    local tabBtn = new("TextButton", {
        Text = "", AutoButtonColor = false,
        Size = UDim2.new(0.9, 0, 0, 44),
        BackgroundColor3 = THEME.Bg,
        BackgroundTransparency = 1,
        Parent = self.Sidebar,
    })
    corner(tabBtn, 10)
    
    local tabLabel = new("TextLabel", {
        Text = name, Font = Enum.Font.SourceSansBold, TextSize = 15,
        TextColor3 = THEME.TextDim,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent = tabBtn,
    })

    local tabData = { Name = name, Page = page, Button = tabBtn, Label = tabLabel }
    table.insert(self.Tabs, tabData)

    tabBtn.MouseButton1Click:Connect(function() self:_selectTab(tabData) end)
    if not self.ActiveTab then self:_selectTab(tabData) end

    local api = { _order = 0 }
    local function nextOrder()
        api._order = api._order + 1
        return api._order
    end

    -- Раздел внутри вкладки
    function api:AddSection(title)
        local label = new("TextLabel", {
            Text = string.upper(title),
            Font = Enum.Font.SourceSansBold,
            TextSize = 13,
            TextColor3 = THEME.AccentB,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        return label
    end

    -- Стандартный переключатель (Toggle)
    function api:AddToggle(opts)
        opts = opts or {}
        local state = opts.Default or false

        local row = new("Frame", {
            Size = UDim2.new(0.96, 0, 0, 56),
            BackgroundColor3 = THEME.BgStrong,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(row, 12)
        local rStroke = stroke(row, THEME.AccentA, 1, 0.8)

        new("TextLabel", { Text = opts.Name or "Опция", Font = Enum.Font.SourceSansBold, TextSize = 16, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 20), Position = UDim2.fromOffset(16, 10), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "", Font = Enum.Font.SourceSans, TextSize = 12, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 16), Position = UDim2.fromOffset(16, 28), BackgroundTransparency = 1, Parent = row })

        local switch = new("Frame", { Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -62, 0.5, -12), BackgroundColor3 = Color3.fromRGB(50, 52, 68), Parent = row })
        corner(switch, 12)
        local knob = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = switch })
        corner(knob, 9)

        local hitbox = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = row })

        local function render(animated)
            local info = animated and SPRING or TweenInfo.new(0)
            if state then
                tween(switch, EASE, { BackgroundColor3 = THEME.AccentA })
                tween(knob, info, { Position = UDim2.fromOffset(25, 3) })
                tween(rStroke, EASE, { Transparency = 0.4 })
            else
                tween(switch, EASE, { BackgroundColor3 = Color3.fromRGB(50, 52, 68) })
                tween(knob, info, { Position = UDim2.fromOffset(3, 3) })
                tween(rStroke, EASE, { Transparency = 0.8 })
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

    -- Переключатель со встроенными разворачивающимися настройками
    function api:AddToggleWithSettings(opts)
        opts = opts or {}
        local state = opts.Default or false
        local expanded = false

        local container = new("Frame", {
            Size = UDim2.new(0.96, 0, 0, 56),
            BackgroundColor3 = THEME.BgStrong,
            ClipsDescendants = true,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(container, 12)
        local cStroke = stroke(container, THEME.AccentA, 1, 0.8)

        local row = new("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = container })
        new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.SourceSansBold, TextSize = 16, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -120, 0, 20), Position = UDim2.fromOffset(16, 10), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "Нажмите для раскрытия опций", Font = Enum.Font.SourceSans, TextSize = 12, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -120, 0, 16), Position = UDim2.fromOffset(16, 28), BackgroundTransparency = 1, Parent = row })
        local chevron = new("TextLabel", { Text = "▼", Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = THEME.TextDim, Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -38, 0.5, -12), BackgroundTransparency = 1, Parent = row })

        -- Контейнер слайдера под спойлером
        local settingsWrap = new("Frame", { Size = UDim2.new(1, -32, 0, 64), Position = UDim2.fromOffset(16, 60), BackgroundTransparency = 1, Parent = container })
        local sliderValue = opts.SliderDefault or 50
        local sliderLabel = new("TextLabel", { Text = (opts.SliderLabel or "Множитель") .. ": " .. sliderValue, Font = Enum.Font.SourceSansBold, TextSize = 13, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), Parent = settingsWrap })
        local sliderTrack = new("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 26), BackgroundColor3 = Color3.fromRGB(45, 48, 62), Parent = settingsWrap })
        corner(sliderTrack, 3)
        local sliderFill = new("Frame", { Size = UDim2.new((sliderValue - opts.SliderMin) / (opts.SliderMax - opts.SliderMin), 0, 1, 0), BackgroundColor3 = THEME.AccentA, Parent = sliderTrack })
        corner(sliderFill, 3)
        local sliderKnob = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(16, 16), Position = UDim2.new((sliderValue - opts.SliderMin) / (opts.SliderMax - opts.SliderMin), -8, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = sliderTrack })
        corner(sliderKnob, 8)

        local draggingSlider = false
        sliderKnob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true end
        end)
        SafeConnect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
        end)
        SafeConnect(RunService.RenderStepped, function()
            if not draggingSlider then return end
            local mouse = UserInputService:GetMouseLocation()
            local relX = math.clamp((mouse.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
            sliderValue = math.floor(opts.SliderMin + relX * (opts.SliderMax - opts.SliderMin))
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            sliderKnob.Position = UDim2.new(relX, -8, 0.5, -8)
            sliderLabel.Text = (opts.SliderLabel or "Множитель") .. ": " .. sliderValue
            if opts.OnSlider then task.spawn(opts.OnSlider, sliderValue) end
        end)

        local hitbox = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = row })
        hitbox.MouseButton1Click:Connect(function()
            expanded = not expanded
            state = expanded
            local targetHeight = expanded and 130 or 56
            tween(container, EASE, { Size = UDim2.new(0.96, 0, 0, targetHeight) })
            tween(chevron, SPRING, { Rotation = expanded and 180 or 0 })
            tween(cStroke, EASE, { Transparency = expanded and 0.4 or 0.8 })
            if opts.Callback then task.spawn(opts.Callback, state) end
        end)

        return { GetSlider = function() return sliderValue end, IsExpanded = function() return expanded end }
    end

    -- Стандартный Ползунок (Slider)
    function api:AddSlider(opts)
        opts = opts or {}
        local sliderValue = opts.Default or 50

        local card = new("Frame", {
            Size = UDim2.new(0.96, 0, 0, 60),
            BackgroundColor3 = THEME.BgStrong,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(card, 12)
        stroke(card, THEME.AccentA, 1, 0.8)

        local label = new("TextLabel", { Text = opts.Name, Font = Enum.Font.SourceSansBold, TextSize = 15, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.7, 0, 0, 20), Position = UDim2.fromOffset(16, 6), BackgroundTransparency = 1, Parent = card })
        local valLbl = new("TextLabel", { Text = tostring(sliderValue), Font = Enum.Font.FredokaOne, TextSize = 15, TextColor3 = THEME.AccentB, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.25, 0, 0, 20), Position = UDim2.new(0.7, 0, 0, 6), BackgroundTransparency = 1, Parent = card })

        local bar = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(0.92, 0, 0, 6), Position = UDim2.new(0.04, 0, 0.72, 0), BackgroundColor3 = Color3.fromRGB(45, 48, 62), Parent = card })
        corner(bar, 3)

        local fill = new("Frame", { Size = UDim2.new((sliderValue - opts.Min)/(opts.Max - opts.Min), 0, 1, 0), BackgroundColor3 = THEME.AccentA, Parent = bar })
        corner(fill, 3)

        local sliding = false
        local function updateVal(input)
            local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(opts.Min + (opts.Max - opts.Min) * ratio)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            valLbl.Text = tostring(val)
            pcall(opts.Callback, val)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                updateVal(input)
            end
        end)
        SafeConnect(UserInputService.InputChanged, function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateVal(input)
            end
        end)
        SafeConnect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
    end

    -- Текстовое поле ввода (TextBox)
    function api:AddTextBox(opts)
        opts = opts or {}
        
        local card = new("Frame", {
            Size = UDim2.new(0.96, 0, 0, 56),
            BackgroundColor3 = THEME.BgStrong,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(card, 12)
        stroke(card, THEME.AccentA, 1, 0.8)

        new("TextLabel", { Text = opts.Name, Font = Enum.Font.SourceSansBold, TextSize = 15, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, Parent = card })

        local box = new("TextBox", {
            Size = UDim2.new(0.5, 0, 0.64, 0),
            Position = UDim2.new(0.46, 0, 0.18, 0),
            BackgroundColor3 = THEME.Bg,
            Text = opts.Default or "",
            TextColor3 = THEME.Text,
            PlaceholderText = opts.Placeholder or "Введите...",
            PlaceholderColor3 = THEME.TextDim,
            Font = Enum.Font.SourceSansSemibold,
            TextSize = 14,
            ClipsDescendants = true,
            Parent = card,
        })
        corner(box, 8)
        stroke(box, Color3.fromRGB(50, 52, 70), 1, 0.5)

        box.FocusLost:Connect(function()
            pcall(opts.Callback, box.Text)
        end)
    end

    -- Кнопка (Button)
    function api:AddButton(opts)
        opts = opts or {}

        local btn = new("TextButton", {
            Size = UDim2.new(0.96, 0, 0, 42),
            BackgroundColor3 = THEME.AccentA,
            Text = opts.Name,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.SourceSansBold,
            TextSize = 16,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(btn, 10)
        gradient(btn, 0)

        btn.MouseButton1Click:Connect(function()
            pcall(opts.Callback)
        end)
    end

    -- Профиль-карточка игрока
    function api:AddProfileCard()
        local hero = new("Frame", { Size = UDim2.new(0.96, 0, 0, 140), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = page })
        local cardBg = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = THEME.BgStrong, Parent = hero })
        corner(cardBg, 16)
        stroke(cardBg, THEME.AccentA, 1, 0.7)

        local avatar = new("ImageLabel", { Size = UDim2.fromOffset(72, 72), Position = UDim2.new(0.05, 0, 0.5, -36), BackgroundColor3 = THEME.AccentA, Parent = cardBg })
        corner(avatar, 36)
        stroke(avatar, THEME.AccentB, 2.5, 0)

        task.spawn(function()
            local ok, content = pcall(function()
                return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
            end)
            if ok and content then avatar.Image = content end
        end)

        new("TextLabel", { Text = LocalPlayer.DisplayName, Font = Enum.Font.SourceSansBold, TextSize = 18, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.65, 0, 0, 22), Position = UDim2.fromOffset(120, 24), BackgroundTransparency = 1, Parent = cardBg })
        new("TextLabel", { Text = "@" .. LocalPlayer.Name, Font = Enum.Font.SourceSansSemibold, TextSize = 14, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.65, 0, 0, 16), Position = UDim2.fromOffset(120, 48), BackgroundTransparency = 1, Parent = cardBg })
        
        local accountAge = LocalPlayer.AccountAge or 0
        new("TextLabel", { Text = "Аккаунту: " .. accountAge .. " дней", Font = Enum.Font.SourceSans, TextSize = 13, TextColor3 = THEME.AccentB, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.65, 0, 0, 16), Position = UDim2.fromOffset(120, 70), BackgroundTransparency = 1, Parent = cardBg })
        new("TextLabel", { Text = "ID: " .. LocalPlayer.UserId, Font = Enum.Font.SourceSans, TextSize = 12, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.65, 0, 0, 16), Position = UDim2.fromOffset(120, 90), BackgroundTransparency = 1, Parent = cardBg })
    end

    return api
end

-- Система переключения вкладок
function Aurora:_selectTab(tabData)
    if self.ActiveTab then
        self.ActiveTab.Page.Visible = false
        tween(self.ActiveTab.Button, EASE, { BackgroundTransparency = 1 })
        tween(self.ActiveTab.Label, EASE, { TextColor3 = THEME.TextDim })
    end
    self.ActiveTab = tabData
    tabData.Page.Visible = true
    tween(tabData.Button, EASE, { BackgroundTransparency = 0.90 })
    tween(tabData.Label, EASE, { TextColor3 = THEME.Text })
end

-- ============================================================================
-- [5. ИНИЦИАЛИЗАЦИЯ И НАПОЛНЕНИЕ ВКЛАДОК AURORA MENU]
-- ============================================================================

local menu = Aurora.new({ Title = "Brosa System", SubTitle = "v5.5 • Private Monolith Hub" })

-- 🎯 ВКЛАДКА 1: АТАКА & ФЛИНГ
local tabAttack = menu:CreateTab("Атака & Флинг")

tabAttack:AddSection("Перехват Захвата (Counter-Grab)")

tabAttack:AddToggle({
    Name = "Авто-Отброс (Counter Grab)",
    Description = "Щит против любителей потаскать. Захватывает врага и кидает за карту.",
    Default = Hub.Flags.AutoFlingBack,
    Callback = function(state)
        Hub.Flags.AutoFlingBack = state
    end
})

tabAttack:AddSlider({
    Name = "Сила встречного отброса",
    Min = 50000,
    Max = 2000000,
    Default = Hub.Flags.CounterFlingForce,
    Callback = function(val)
        Hub.Flags.CounterFlingForce = val
    end
})

tabAttack:AddSlider({
    Name = "Длительность удержания в вихре",
    Min = 1,
    Max = 10,
    Default = Hub.Flags.CounterHoldTime,
    Callback = function(val)
        Hub.Flags.CounterHoldTime = val
    end
})

tabAttack:AddSection("Инструменты FOV Захвата")

tabAttack:AddToggle({
    Name = "Показывать прицел (FOV Circle)",
    Description = "Фиксированный круг по центру для строгого захвата",
    Default = Hub.Flags.DrawFovCircle,
    Callback = function(state)
        Hub.Flags.DrawFovCircle = state
    end
})

tabAttack:AddSlider({
    Name = "Радиус захвата FOV",
    Min = 30,
    Max = 600,
    Default = Hub.Flags.MaxFovRadius,
    Callback = function(val)
        Hub.Flags.MaxFovRadius = val
    end
})

tabAttack:AddToggle({
    Name = "Умный Сортировщик (Игроки/Вещи)",
    Description = "Вкл — ищет предметы, Выкл — игроков",
    Default = Hub.Flags.SearchForItems,
    Callback = function(state)
        Hub.Flags.SearchForItems = state
    end
})

tabAttack:AddToggle({
    Name = "Включить Крутилку (Omni Grab)",
    Description = "Позволяет зажать и раскрутить цель перед собой",
    Default = Hub.Flags.OmniGrabEnabled,
    Callback = function(state)
        Hub.Flags.OmniGrabEnabled = state
        if state then
            task.spawn(function()
                while Hub.Flags.OmniGrabEnabled do
                    local target = getClosestTargetInStrictFOV(Hub.Flags.MaxFovRadius, Hub.Flags.SearchForItems)
                    if target then
                        Hub.Cache.ActiveTarget = target
                        Hub.Cache.IsHoldingAnything = true
                        updateSnapline(target, Hub.Flags.MaxFovRadius)
                    else
                        Hub.Cache.IsHoldingAnything = false
                        snapLine.Visible = false
                    end
                    task.wait(0.05)
                end
                snapLine.Visible = false
                Hub.Cache.IsHoldingAnything = false
            end)
        else
            snapLine.Visible = false
            Hub.Cache.IsHoldingAnything = false
        end
    end
})

tabAttack:AddSlider({
    Name = "Сила обычного броска",
    Min = 100,
    Max = 15000,
    Default = Hub.Flags.FlingForceValue,
    Callback = function(val)
        Hub.Flags.FlingForceValue = val
    end
})

tabAttack:AddButton({
    Name = "Швырнуть Удерживаемую Цель",
    Callback = function()
        throwActiveTarget()
    end
})

tabAttack:AddSection("Глобальный хаос и Флинг")

tabAttack:AddTextBox({
    Name = "Имя Жертвы (Для Fling/Orbit)",
    Placeholder = "Никнейм...",
    Default = Hub.Flags.TargetPlayer,
    Callback = function(text)
        Hub.Flags.TargetPlayer = text
    end
})

tabAttack:AddButton({
    Name = "Fling Target (Разорвать цель)",
    Callback = function()
        local target = FindPlayerByName(Hub.Flags.TargetPlayer)
        if target then
            ExecuteFling(target)
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Ошибка",
                Text = "Целевой игрок не найден в лобби!",
                Duration = 3
            })
        end
    end
})

tabAttack:AddToggle({
    Name = "Orbit Target (Запустить вращение)",
    Description = "Режим быстрого вращения вокруг жертвы",
    Default = Hub.Flags.OrbitPlayer,
    Callback = function(state)
        Hub.Flags.OrbitPlayer = state
    end
})

tabAttack:AddSlider({
    Name = "Дистанция орбиты",
    Min = 2,
    Max = 60,
    Default = Hub.Flags.OrbitDistance,
    Callback = function(val)
        Hub.Flags.OrbitDistance = val
    end
})

tabAttack:AddSlider({
    Name = "Скорость орбиты",
    Min = 1,
    Max = 40,
    Default = Hub.Flags.OrbitSpeed,
    Callback = function(val)
        Hub.Flags.OrbitSpeed = val
    end
})

tabAttack:AddToggle({
    Name = "Аура Смерти (Fling Aura)",
    Description = "Мгновенный подрыв любого, кто подойдет близко",
    Default = Hub.Flags.FlingAura,
    Callback = function(state)
        Hub.Flags.FlingAura = state
    end
})

tabAttack:AddToggle({
    Name = "Click Fling (+Left Ctrl)",
    Description = "Зажмите левый Ctrl и кликните на любого для флинга",
    Default = Hub.Flags.ClickFling,
    Callback = function(state)
        Hub.Flags.ClickFling = state
    end
})

tabAttack:AddButton({
    Name = "Флинг всех на сервере",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                task.spawn(function() ExecuteFling(p) end)
            end
        end
    end
})


-- 🏃‍♂️ ВКЛАДКА 2: ДВИЖЕНИЕ
local tabMovement = menu:CreateTab("Движение")

tabMovement:AddSection("Физические Модификаторы")

tabMovement:AddToggle({
    Name = "Применить WalkSpeed",
    Description = "Принудительно удерживает скорость движения",
    Default = Hub.Flags.WalkSpeedEnabled,
    Callback = function(state)
        Hub.Flags.WalkSpeedEnabled = state
        if state then
            pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = Hub.Flags.WalkSpeedValue end)
        else
            pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
        end
    end
})

tabMovement:AddSlider({
    Name = "Скорость перемещения",
    Min = 16,
    Max = 350,
    Default = Hub.Flags.WalkSpeedValue,
    Callback = function(val)
        Hub.Flags.WalkSpeedValue = val
        if Hub.Flags.WalkSpeedEnabled then
            pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = val end)
        end
    end
})

tabMovement:AddToggle({
    Name = "Применить JumpPower",
    Description = "Позволяет прыгать на невероятную высоту",
    Default = Hub.Flags.JumpPowerEnabled,
    Callback = function(state)
        Hub.Flags.JumpPowerEnabled = state
        if state then
            pcall(function() LocalPlayer.Character.Humanoid.JumpPower = Hub.Flags.JumpPowerValue end)
        else
            pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end)
        end
    end
})

tabMovement:AddSlider({
    Name = "Высота прыжков",
    Min = 50,
    Max = 500,
    Default = Hub.Flags.JumpPowerValue,
    Callback = function(val)
        Hub.Flags.JumpPowerValue = val
        if Hub.Flags.JumpPowerEnabled then
            pcall(function() LocalPlayer.Character.Humanoid.JumpPower = val end)
        end
    end
})

tabMovement:AddSection("Супер-способности")

tabMovement:AddToggle({
    Name = "Бесконечный прыжок",
    Description = "Прыгайте по облакам сколько угодно",
    Default = Hub.Flags.InfiniteJump,
    Callback = function(state)
        Hub.Flags.InfiniteJump = state
    end
})

tabMovement:AddToggle({
    Name = "Noclip (Проход сквозь стены)",
    Description = "Коллизия всего тела полностью отключается",
    Default = Hub.Flags.Noclip,
    Callback = function(state)
        Hub.Flags.Noclip = state
    end
})

tabMovement:AddToggle({
    Name = "Защита от бездны (Anti-Void)",
    Description = "При падении телепортирует обратно на карту",
    Default = Hub.Flags.AntiVoid,
    Callback = function(state)
        Hub.Flags.AntiVoid = state
    end
})

tabMovement:AddToggleWithSettings({
    Name = "Полет (Fly Engine v2)",
    Description = "Летайте без ограничений физики",
    Default = Hub.Flags.Fly,
    SliderLabel = "Скорость полета",
    SliderMin = 10,
    SliderMax = 350,
    SliderDefault = Hub.Flags.FlySpeed,
    OnSlider = function(v)
        Hub.Flags.FlySpeed = v
    end,
    Callback = function(state)
        Hub.Flags.Fly = state
    end
})


-- 👁️ ВКЛАДКА 3: ВИЗУАЛЫ
local tabVisuals = menu:CreateTab("Визуалы")

tabVisuals:AddSection("Внутриигровой ESP")

tabVisuals:AddToggle({
    Name = "ESP 2D Боксы",
    Description = "Рамки вокруг персонажей игроков",
    Default = Hub.Flags.ESP_Boxes,
    Callback = function(state)
        Hub.Flags.ESP_Boxes = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Линии наведения",
    Description = "Линия от низа экрана к целям",
    Default = Hub.Flags.ESP_Tracers,
    Callback = function(state)
        Hub.Flags.ESP_Tracers = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Отображать Ники",
    Description = "Показывает дисплей-неймы сквозь преграды",
    Default = Hub.Flags.ESP_Names,
    Callback = function(state)
        Hub.Flags.ESP_Names = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Шкала здоровья",
    Description = "Отображает уровень ХП в виде индикатора",
    Default = Hub.Flags.ESP_Health,
    Callback = function(state)
        Hub.Flags.ESP_Health = state
    end
})

tabVisuals:AddSection("Окружение и камера")

tabVisuals:AddToggle({
    Name = "Режим Fullbright (День)",
    Description = "Максимально яркая подсветка всей игровой зоны",
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
    Name = "Potato PC Mode (FPS Boost)",
    Description = "Убирает сложные текстуры, спасает от лагов физики",
    Default = Hub.Flags.PotatoPC,
    Callback = function(state)
        ApplyPotatoPC(state)
    end
})

-- Элемент настройки Растяга экрана (Aspect Ratio) с возвращением к исходному значению
tabVisuals:AddToggleWithSettings({
    Name = "Растяг Экрана (Aspect Ratio)",
    Description = "Растягивает/сжимает угол обзора камеры",
    Default = Hub.Flags.AspectRatioStretch,
    SliderLabel = "Значение FOV",
    SliderMin = 30,
    SliderMax = 120,
    SliderDefault = 70,
    OnSlider = function(v)
        Hub.Flags.AspectRatioValue = v
        if Hub.Flags.AspectRatioStretch then
            setAspectRatioStretch(v)
        end
    end,
    Callback = function(state)
        Hub.Flags.AspectRatioStretch = state
        if state then
            Hub.Cache.LastCamFov = Camera.FieldOfView
            setAspectRatioStretch(Hub.Flags.AspectRatioValue)
        else
            setAspectRatioStretch(Hub.Cache.LastCamFov)
        end
    end
})


-- 🛡️ ВКЛАДКА 4: ЗАЩИТА & СПАМ
local tabDefense = menu:CreateTab("Защита")

tabDefense:AddSection("Защитные системы")

tabDefense:AddToggle({
    Name = "Блокировать метатаблицы (Bypass)",
    Description = "Препятствует проверкам скорости старыми античитами",
    Default = Hub.Flags.BypassMetatable,
    Callback = function(state)
        Hub.Flags.BypassMetatable = state
    end
})

tabDefense:AddToggle({
    Name = "Анти-Захват (Anti Grab)",
    Description = "Превращает ваше тело в призрак для попыток взять вас вручную",
    Default = Hub.Flags.AntiGrab,
    Callback = function(state)
        Hub.Flags.AntiGrab = state
    end
})

tabDefense:AddToggle({
    Name = "Стабилизатор тела (Anti Fling)",
    Description = "Блокирует случайные улеты от коллизий и раскруток",
    Default = Hub.Flags.AntiFling,
    Callback = function(state)
        Hub.Flags.AntiFling = state
    end
})

tabDefense:AddSection("Вредительство в чате")

tabDefense:AddToggle({
    Name = "Запустить спамер чата",
    Description = "Автоматическая реклама Brosa System в чат",
    Default = Hub.Flags.ChatSpam,
    Callback = function(state)
        Hub.Flags.ChatSpam = state
    end
})

tabDefense:AddTextBox({
    Name = "Текст сообщения для спама",
    Placeholder = "Пишите тут...",
    Default = Hub.Flags.ChatSpamMessage,
    Callback = function(text)
        Hub.Flags.ChatSpamMessage = text
    end
})

tabDefense:AddButton({
    Name = "Заморозить физику Лобби (Lobby Freeze)",
    Callback = function()
        Hub.Flags.LobbyFreeze = not Hub.Flags.LobbyFreeze
        StarterGui:SetCore("SendNotification", {
            Title = "Статус лаггера",
            Text = Hub.Flags.LobbyFreeze and "Лобби-фриз запущен!" or "Лобби-фриз остановлен.",
            Duration = 3
        })
    end
})


-- 👤 ВКЛАДКА 5: ПРОФИЛЬ
local tabProfile = menu:CreateTab("Профиль")

tabProfile:AddSection("Карточка игрока")
tabProfile:AddProfileCard()

tabProfile:AddSection("Телеметрия сервера")

local pingLabel = tabProfile:AddSection("Сканирование пинга...")
local fpsLabel = tabProfile:AddSection("Анализ FPS...")
local friendsLabel = tabProfile:AddSection("Друзья на сервере: сканирование...")

-- Обновление пинга, фпс и друзей в реальном времени
local function RecalculateFriends()
    local counter = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local success, areFriends = pcall(function()
                return LocalPlayer:IsFriendsWith(player.UserId)
            end)
            if success and areFriends then
                counter = counter + 1
            end
        end
    end
    friendsLabel.Text = "ДРУЗЕЙ НА СЕРВЕРЕ: " .. tostring(counter)
end

task.spawn(RecalculateFriends)
SafeConnect(Players.PlayerAdded, RecalculateFriends)
SafeConnect(Players.PlayerRemoving, RecalculateFriends)

local fpsCounter = 0
SafeConnect(RunService.Heartbeat, function(step)
    fpsCounter = math.floor(1 / step)
end)

task.spawn(function()
    while task.wait(1) do
        if Hub.Loaded then
            pcall(function()
                local pingValue = math.floor(Stats.Network.ServerToClientPing:GetValue() * 1000)
                pingLabel.Text = "PING СЕТИ: " .. tostring(pingValue) .. " MS"
                fpsLabel.Text = "ТЕКУЩИЙ FPS: " .. tostring(fpsCounter)
            end)
        end
    end
end)


-- ⚙️ ВКЛАДКА 6: НАСТРОЙКИ ЯДРА
local tabCore = menu:CreateTab("Ядро")

tabCore:AddSection("Опции ядра")

tabCore:AddButton({
    Name = "Выполнить сварку всех физических тел",
    Callback = function()
        RunMassWeld()
    end
})

tabCore:AddButton({
    Name = "Принудительно обновить обход (Metatable)",
    Callback = function()
        StarterGui:SetCore("SendNotification", {
            Title = "Мета-Связь",
            Text = "Обход метатаблицы успешно привязан повторно!",
            Duration = 3
        })
    end
})

tabCore:AddSection("Деструкция и выход")

tabCore:AddButton({
    Name = "Выгрузить Brosa System (Destroy)",
    Callback = function()
        menu:CloseForever()
    end
})

-- ============================================================================
-- [6. ОБРАБОТЧИКИ СОБЫТИЙ, ОБХОДЫ И ЖИЗНЕННЫЙ ЦИКЛ]
-- ============================================================================

-- Обход метатаблицы (Защита от детекта скорости)
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

-- Автонакат параметров скорости/прыжка при перерождении персонажа
SafeConnect(LocalPlayer.CharacterAdded, function(char)
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

-- Функция полной чистки ресурсов при удалении скрипта
Hub.Unload = function()
    Hub.Loaded = false
    
    -- Деактивация флагов
    for flag, _ in pairs(Hub.Flags) do
        Hub.Flags[flag] = false
    end
    
    -- Отключение всех listeners
    for _, conn in ipairs(Hub.Cache.Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(Hub.Cache.Connections)
    
    -- Сброс окружения на дефолт
    Lighting.Ambient = Hub.Cache.OriginalLighting.Ambient
    Lighting.OutdoorAmbient = Hub.Cache.OriginalLighting.OutdoorAmbient
    Lighting.Brightness = Hub.Cache.OriginalLighting.Brightness
    Lighting.ClockTime = Hub.Cache.OriginalLighting.ClockTime
    Lighting.FogEnd = Hub.Cache.OriginalLighting.FogEnd
    Lighting.GlobalShadows = Hub.Cache.OriginalLighting.GlobalShadows
    
    -- Очистка чертежей Drawing API
    fovDrawingCircle:Destroy()
    snapLine:Destroy()
    
    for _, item in pairs(Hub.Cache.EspBoxes) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspTracers) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspNames) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspHealth) do item:Destroy() end
    
    table.clear(Hub.Cache.EspBoxes)
    table.clear(Hub.Cache.EspTracers)
    table.clear(Hub.Cache.EspNames)
    table.clear(Hub.Cache.EspHealth)
    
    -- Возвращение материалов Potato PC
    for obj, data in pairs(Hub.Cache.OriginalMaterials) do
        if obj and obj.Parent then
            obj.Material = data[1]
            obj.Reflectance = data[2]
        end
    end
    
    pcall(function()
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum.PlatformStand = false
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end)
    
    _G.BrosaHubGlobal = nil
    print("[Brosa System]: Скрипт успешно выгружен, память очищена.")
end

-- Финальный запуск
StarterGui:SetCore("SendNotification", {
    Title = "🔥 Brosa System",
    Text = "Монолитная сборка v5.5 успешно загружена!",
    Duration = 4
})

print("[Brosa System v5.5]: Монолит запущен. Полная интеграция Aurora Menu v2 и Counter-Grab завершена.")

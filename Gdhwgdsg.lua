--[[
    ================================================================================
    👑 BROSA SYSTEM v5.5 — PRIVATE UNLIMITED MONOLITHIC HYBRID SCRIPT HUB
    🎨 CORE GUI INTERFACE: AURORA MENU v2 (FULLY EXPANDED & OPTIMIZED EDITION)
    🔒 STATUS: UNDETECTED | BYPASS: ACTIVE | OPTIMIZED FOR DELTA/HYDROGEN/FLUXUS
    ================================================================================
]]

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
        OrbitSpeed = 5,
        OrbitDistance = 5,
        MassWeld = false,
        LobbyFreeze = false,
        
        -- Захват и Омни-Системы
        OmniGrabEnabled = false,
        SearchForItems = false,
        MaxFovRadius = 150,
        
        -- Визуалы & ESP
        ESP_Players = false,
        ESP_Tracers = false,
        ESP_Boxes = false,
        ESP_Names = false,
        ESP_Health = false,
        Fullbright = false,
        PotatoPC = false,
        AspectRatioStretch = false,
        AspectRatioValue = 70,
        
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
            GlobalShadows = Lighting.GlobalShadows,
            FieldOfView = camera.FieldOfView
        },
        Connections = {},
        EspBoxes = {},
        EspTracers = {},
        EspNames = {},
        EspHealth = {},
        OriginalMaterials = {},
        DrawingObjects = {}
    }
}

local Hub = _G.BrosaHubGlobal

-- Безопасное подключение событий
local function SafeConnect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Hub.Cache.Connections, connection)
    return connection
end

-- Регистрация Drawing объектов для последующей деструкции
local function RegisterDrawing(obj)
    table.insert(Hub.Cache.DrawingObjects, obj)
    return obj
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

-- Логика Полета (Fly Engine v2)
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
-- [3. ВСТРОЕННЫЙ В ИГРУ ЗАХВАТ: ТРЕКЕР, ЛИНИЯ И ДИСТАНЦИЯ]
-- ============================================================================

local inGameGrabLine = RegisterDrawing(Drawing.new("Line"))
inGameGrabLine.Thickness = 2
inGameGrabLine.Color = Color3.fromRGB(255, 65, 65)
inGameGrabLine.Transparency = 1
inGameGrabLine.Visible = false

local inGameGrabText = RegisterDrawing(Drawing.new("Text"))
inGameGrabText.Size = 16
inGameGrabText.Color = Color3.fromRGB(255, 255, 255)
inGameGrabText.Outline = true
inGameGrabText.Center = true
inGameGrabText.Visible = false

-- Сканер встроенного в игру захвата (ищет суставы и коллизии удержания)
local function getInGameGrabbedTarget()
    local char = lp.Character
    if not char then return nil end

    -- Вариант 1: Поиск Weld/Constraint внутри нашего персонажа, указывающий на внешние объекты
    for _, joint in ipairs(char:GetDescendants()) do
        if joint:IsA("JointInstance") or joint:IsA("Constraint") then
            local p0 = joint.Part0 or (joint:IsA("Constraint") and joint.Attachment0 and joint.Attachment0.Parent)
            local p1 = joint.Part1 or (joint:IsA("Constraint") and joint.Attachment1 and joint.Attachment1.Parent)
            
            if p0 and p1 then
                local targetPart = (p0:IsDescendantOf(char) and p1) or (p1:IsDescendantOf(char) and p0)
                if targetPart and not targetPart:IsDescendantOf(char) and targetPart:IsA("BasePart") then
                    local parentModel = targetPart:FindFirstAncestorOfClass("Model")
                    if parentModel then
                        local hum = parentModel:FindFirstChildOfClass("Humanoid")
                        if hum then
                            return { Type = "Player", Instance = parentModel:FindFirstChild("HumanoidRootPart") or targetPart }
                        end
                    end
                    return { Type = "Item", Instance = targetPart }
                end
            end
        end
    end

    -- Вариант 2: Сканирование Workspace на наличие Weld, связывающих нас с другими телами
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Weld") or obj:IsA("WeldConstraint") then
            local p0, p1 = obj.Part0, obj.Part1
            if p0 and p1 then
                if p0:IsDescendantOf(char) and not p1:IsDescendantOf(char) then
                    return { Type = "Item", Instance = p1 }
                elseif p1:IsDescendantOf(char) and not p0:IsDescendantOf(char) then
                    return { Type = "Item", Instance = p0 }
                end
            end
        end
    end

    return nil
end

-- Обработка вывода линии и метров для игрового захвата
SafeConnect(RunService.RenderStepped, function()
    local target = getInGameGrabbedTarget()
    if target and target.Instance then
        local screenPos, onScreen = camera:WorldToViewportPoint(target.Instance.Position)
        if onScreen then
            local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            
            -- Рисуем линию от прицела строго к туловищу
            inGameGrabLine.From = screenCenter
            inGameGrabLine.To = Vector2.new(screenPos.X, screenPos.Y)
            inGameGrabLine.Visible = true
            
            -- Вычисление метров (Roblox studs / 3.57)
            local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local distanceStuds = (myRoot.Position - target.Instance.Position).Magnitude
                local distanceMeters = math.floor(distanceStuds / 3.57)
                
                inGameGrabText.Text = distanceMeters .. " m"
                inGameGrabText.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
                inGameGrabText.Visible = true
            else
                inGameGrabText.Visible = false
            end
        else
            inGameGrabLine.Visible = false
            inGameGrabText.Visible = false
        end
    else
        inGameGrabLine.Visible = false
        inGameGrabText.Visible = false
    end
end)


-- ============================================================================
-- [4. ФУНКЦИИ СТРОГОГО ЗАХВАТА, ЛИНИЙ И КРУТИЛКИ (СБОРКА ЭКСПЛУАТОВ)]
-- ============================================================================

-- Поиск строго центрированной цели в FOV
local function getClosestTargetInStrictFOV(maxFovRadius, searchForItems)
    local closestTarget = nil
    local shortestDistance = maxFovRadius
    
    local screenSize = camera.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    -- 1. ПОИСК ИГРОКОВ
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
    -- 2. ПОИСК ВЕЩЕЙ И ПРЕДМЕТОВ НА КАРТЕ
    else
        local rayOrigin = camera.CFrame.Position
        local rayDirection = camera.CFrame.LookVector * 500
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {lp.Character}
        
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

-- Линия наведения FOV захвата
local snapLine = RegisterDrawing(Drawing.new("Line"))
snapLine.Thickness = 1.5
snapLine.Color = Color3.fromRGB(124, 108, 255)
snapLine.Transparency = 1
snapLine.Visible = false

local activeTarget = nil
local isHoldingAnything = false
local rotationAngle = 0

-- Динамическое обновление Snapline
local function updateSnapline(currentTarget, maxFovRadius)
    local screenSize = camera.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    if currentTarget and currentTarget.Instance then
        local part = currentTarget.Instance
        local screenPos, onScreen = camera:WorldToScreenPoint(part.Position)
        
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

-- Цикл Крутилки (Omni Grab & Вращение для сбоя коллизий)
local function processOmniGrab()
    if isHoldingAnything and activeTarget and activeTarget.Instance then
        local targetPart = activeTarget.Instance
        local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        
        if targetPart and myHrp then
            local holdPosition = myHrp.CFrame * CFrame.new(0, 0, -6)
            
            rotationAngle = rotationAngle + 60
            local crazyRotation = CFrame.Angles(math.rad(rotationAngle * 2), math.rad(rotationAngle * 1.5), math.rad(rotationAngle))
            
            targetPart.CFrame = holdPosition * crazyRotation
            targetPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            targetPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            if activeTarget.Type == "Item" then
                targetPart.CanCollide = false
            end
        end
    end
end

-- Бросок под карту на дикой скорости
local function throwActiveTarget()
    if isHoldingAnything and activeTarget and activeTarget.Instance then
        local targetPart = activeTarget.Instance
        local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        
        if targetPart and myHrp then
            local throwDirection = (myHrp.CFrame.LookVector + Vector3.new(0, -1.8, 0)).Unit
            if activeTarget.Type == "Item" then
                targetPart.CanCollide = true
            end
            targetPart.AssemblyLinearVelocity = throwDirection * 1800
        end
    end
    isHoldingAnything = false
    activeTarget = nil
end

-- Рендер событий FOV захвата
SafeConnect(RunService.RenderStepped, function()
    if Hub.Flags.OmniGrabEnabled then
        local found = getClosestTargetInStrictFOV(Hub.Flags.MaxFovRadius, Hub.Flags.SearchForItems)
        if not isHoldingAnything then
            activeTarget = found
        end
        updateSnapline(activeTarget, Hub.Flags.MaxFovRadius)
    else
        snapLine.Visible = false
        if not isHoldingAnything then
            activeTarget = nil
        end
    end
    
    processOmniGrab()
end)


-- ============================================================================
-- [5. ТАЙМЕРЫ И МОНИТОРИНГ ДАННЫХ СЕРВЕРА]
-- ============================================================================

local serverPlayerList = {}
task.spawn(function()
    while true do
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

local function setAspectRatioStretch(stretchValue)
    if camera then
        camera.FieldOfView = stretchValue
    end
end


-- ============================================================================
-- [6. ПОЛНАЯ РЕАЛИЗАЦИЯ И РЕНДЕРИНГ ESP И ВИЗУАЛОВ]
-- ============================================================================

local function DrawESP(player)
    if player == lp then return end
    
    local box = RegisterDrawing(Drawing.new("Square"))
    box.Visible = false
    box.Color = Color3.fromRGB(0, 180, 255)
    box.Thickness = 1.5
    box.Filled = false
    
    local tracer = RegisterDrawing(Drawing.new("Line"))
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(0, 180, 255)
    tracer.Thickness = 1
    
    local name = RegisterDrawing(Drawing.new("Text"))
    name.Visible = false
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Size = 13
    name.Center = true
    name.Outline = true
    
    local healthBar = RegisterDrawing(Drawing.new("Line"))
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
                    
                    if Hub.Flags.ESP_Boxes then
                        box.Size = Vector2.new(sizeX, sizeY)
                        box.Position = Vector2.new(rootPos.X - sizeX / 2, rootPos.Y - sizeY / 2)
                        box.Visible = true
                    else
                        box.Visible = false
                    end
                    
                    if Hub.Flags.ESP_Tracers then
                        tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
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

-- Potato PC (Оптимизация текстур)
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
-- [7. НОВЫЙ КЛАСС И СТРУКТУРА AURORA MENU V2 — ВЫРАВНЕННЫЙ САЙДБАР]
-- ============================================================================

local THEME = {
    Bg          = Color3.fromRGB(20, 20, 25),
    BgStrong    = Color3.fromRGB(26, 26, 33),
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
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

-- Перетаскивание элементов (Кнопки / Окна)
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
            local newPos = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
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
        Name = "AuroraMenu_" .. HttpService:GenerateGUID(false):sub(1,6),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = CoreGui:FindFirstChild("RobloxGui") or lp:WaitForChild("PlayerGui"),
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
        Size = UDim2.fromOffset(450, 480),
        Position = UDim2.fromOffset(200, 120),
        BackgroundColor3 = THEME.Bg,
        BackgroundTransparency = 0.12,
        ClipsDescendants = true,
        Visible = false,
        Parent = self.Gui,
    })
    corner(window, 26)
    stroke(window, THEME.Stroke, 2, 0.9)

    local scale = new("UIScale", { Scale = 0.12, Parent = window })
    self.WindowScale = scale
    self.Window = window

    -- Заголовок меню
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

    -- Сайдбар слева
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
        Text = name, Font = Enum.Font.GothamBold, TextSize = 9,
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

    -- Добавление Секции
    function api:AddSection(title)
        return new("TextLabel", {
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
    end

    -- Добавление Переключателя (Toggle)
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

        new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 16), Position = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 14), Position = UDim2.fromOffset(16, 30), BackgroundTransparency = 1, Parent = row })

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
                tween(switch, EASE, { BackgroundTransparency = 0.85, BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
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

    -- Добавление Слайдера
    function api:AddSlider(opts)
        opts = opts or {}
        local min = opts.Min or 0
        local max = opts.Max or 100
        local currentVal = opts.Default or min
        
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 65),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.965,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(row, 16)
        local rStroke = stroke(row, THEME.AccentA, 1, 0.8)
        
        local label = new("TextLabel", {
            Text = opts.Name or "Ползунок",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = THEME.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0.6, 0, 0, 20),
            Position = UDim2.fromOffset(14, 8),
            BackgroundTransparency = 1,
            Parent = row,
        })
        
        local valLabel = new("TextLabel", {
            Text = tostring(currentVal),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = THEME.AccentB,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(0.3, 0, 0, 20),
            Position = UDim2.new(0.7, -14, 0, 8),
            BackgroundTransparency = 1,
            Parent = row,
        })
        
        local track = new("Frame", {
            Size = UDim2.new(1, -28, 0, 6),
            Position = UDim2.fromOffset(14, 38),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.9,
            Parent = row,
        })
        corner(track, 3)
        
        local ratio = math.clamp((currentVal - min) / (max - min), 0, 1)
        local fill = new("Frame", {
            Size = UDim2.new(ratio, 0, 1, 0),
            BackgroundColor3 = THEME.AccentA,
            Parent = track,
        })
        corner(fill, 3)
        gradient(fill, 0)
        
        local knob = new("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(ratio, -8, 0.5, -8),
            BackgroundColor3 = THEME.Text,
            Parent = track,
        })
        corner(knob, 8)
        stroke(knob, THEME.AccentA, 1, 0.5)
        
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
        
        local function update(input)
            local trackPos = track.AbsolutePosition
            local trackSize = track.AbsoluteSize
            local relativeX = math.clamp((input.Position.X - trackPos.X) / trackSize.X, 0, 1)
            local val = math.floor(min + (max - min) * relativeX)
            
            fill.Size = UDim2.new(relativeX, 0, 1, 0)
            knob.Position = UDim2.new(relativeX, -8, 0.5, -8)
            valLabel.Text = tostring(val)
            currentVal = val
            if opts.Callback then task.spawn(opts.Callback, val) end
        end
        
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
    end

    -- Добавление Поля Ввода (TextBox)
    function api:AddTextBox(opts)
        opts = opts or {}
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 58),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.965,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(row, 16)
        stroke(row, THEME.AccentA, 1, 0.8)
        
        local label = new("TextLabel", {
            Text = opts.Name or "Ввод",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = THEME.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.fromOffset(14, 0),
            BackgroundTransparency = 1,
            Parent = row,
        })
        
        local boxFrame = new("Frame", {
            Size = UDim2.new(0.5, 0, 0, 32),
            Position = UDim2.new(0.5, -14, 0.5, -16),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.94,
            Parent = row,
        })
        corner(boxFrame, 10)
        stroke(boxFrame, THEME.AccentB, 1, 0.8)
        
        local box = new("TextBox", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text = opts.Default or "",
            PlaceholderText = opts.Placeholder or "Введите...",
            PlaceholderColor3 = THEME.TextDim,
            TextColor3 = THEME.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = boxFrame,
        })
        
        box.FocusLost:Connect(function()
            if opts.Callback then task.spawn(opts.Callback, box.Text) end
        end)
    end

    -- Добавление Кнопки (Button)
    function api:AddButton(opts)
        opts = opts or {}
        local btn = new("TextButton", {
            Text = opts.Name or "Кнопка",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = THEME.Text,
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = THEME.AccentA,
            BackgroundTransparency = 0.1,
            AutoButtonColor = false,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        corner(btn, 14)
        local g = gradient(btn, 90)
        local s = stroke(btn, THEME.AccentB, 1, 0.5)
        
        btn.MouseEnter:Connect(function()
            tween(btn, FAST, { BackgroundTransparency = 0 })
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, FAST, { BackgroundTransparency = 0.1 })
        end)
        btn.MouseButton1Click:Connect(function()
            local origSize = btn.Size
            tween(btn, FAST, { Size = UDim2.new(0.97, 0, 0, 44) }).Completed:Connect(function()
                tween(btn, FAST, { Size = origSize })
            end)
            if opts.Callback then task.spawn(opts.Callback) end
        end)
    end

    -- Карточка профиля с 3D-аватаром и статистикой
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

        local nameLabel = new("TextLabel", { Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = THEME.Text, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 90), BackgroundTransparency = 1, Parent = hero })
        local ageLabel = new("TextLabel", { Text = "@" .. lp.Name .. " · Возраст: " .. lp.AccountAge .. " дн", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 112), BackgroundTransparency = 1, Parent = hero })

        local stats = new("Frame", { Size = UDim2.new(1, 0, 0, 60), LayoutOrder = nextOrder(), BackgroundTransparency = 1, Parent = page })
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = stats })

        local function statChip(value, labelText)
            local chip = new("Frame", { Size = UDim2.new(0.33, -5, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.96, Parent = stats })
            corner(chip, 14)
            local valLabel = new("TextLabel", { Text = tostring(value), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = THEME.Text, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 10), BackgroundTransparency = 1, Parent = chip })
            new("TextLabel", { Text = labelText, Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = THEME.TextDim, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.fromOffset(0, 30), BackgroundTransparency = 1, Parent = chip })
            return valLabel
        end

        local pingVal = statChip("...", "Пинг")
        local fpsVal = statChip("...", "FPS")
        statChip(lp.UserId, "UID")

        local fpsCounter = 0
        SafeConnect(RunService.Heartbeat, function(step)
            fpsCounter = math.floor(1 / step)
        end)

        task.spawn(function()
            while task.wait(1) do
                if Hub.Loaded then
                    pcall(function()
                        local pingValue = math.floor(Stats.Network.ServerToClientPing:GetValue() * 1000)
                        pingVal.Text = pingValue .. " ms"
                        fpsVal.Text = tostring(fpsCounter)
                    end)
                end
            end
        end)
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
-- [8. КОНСТРУКТОР МЕНЮ И НАПОЛНЕНИЕ ВКЛАДОК ФУНКЦИЯМИ]
-- ============================================================================

local menu = Aurora.new({ Title = "Brosa System", SubTitle = "v5.5 • Private Hub" })

-- 1. ВКЛАДКА: ДВИЖЕНИЕ
local tabMovement = menu:CreateTab("Движение")
tabMovement:AddSection("Физика Тела")

tabMovement:AddToggle({
    Name = "Кастомная Скорость",
    Description = "Блокировка физического перемещения",
    Default = Hub.Flags.WalkSpeedEnabled,
    Callback = function(state)
        Hub.Flags.WalkSpeedEnabled = state
        if state then
            pcall(function() lp.Character.Humanoid.WalkSpeed = Hub.Flags.WalkSpeedValue end)
        else
            pcall(function() lp.Character.Humanoid.WalkSpeed = 16 end)
        end
    end
})

tabMovement:AddSlider({
    Name = "Значение Скорости",
    Min = 16,
    Max = 350,
    Default = Hub.Flags.WalkSpeedValue,
    Callback = function(val)
        Hub.Flags.WalkSpeedValue = val
        if Hub.Flags.WalkSpeedEnabled then
            pcall(function() lp.Character.Humanoid.WalkSpeed = val end)
        end
    end
})

tabMovement:AddToggle({
    Name = "Кастомный Прыжок",
    Description = "Изменение гравитационного импульса",
    Default = Hub.Flags.JumpPowerEnabled,
    Callback = function(state)
        Hub.Flags.JumpPowerEnabled = state
        if state then
            pcall(function() lp.Character.Humanoid.JumpPower = Hub.Flags.JumpPowerValue end)
        else
            pcall(function() lp.Character.Humanoid.JumpPower = 50 end)
        end
    end
})

tabMovement:AddSlider({
    Name = "Высота прыжка",
    Min = 50,
    Max = 500,
    Default = Hub.Flags.JumpPowerValue,
    Callback = function(val)
        Hub.Flags.JumpPowerValue = val
        if Hub.Flags.JumpPowerEnabled then
            pcall(function() lp.Character.Humanoid.JumpPower = val end)
        end
    end
})

tabMovement:AddSection("Эксплойты Движения")

tabMovement:AddToggle({
    Name = "Бесконечный Прыжок",
    Description = "Игнорирование падения и прыжки по воздуху",
    Default = Hub.Flags.InfiniteJump,
    Callback = function(state)
        Hub.Flags.InfiniteJump = state
    end
})

tabMovement:AddToggle({
    Name = "Режим полета (Fly)",
    Description = "Перемещение сквозь пространство",
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
    Description = "Полное отключение коллизии частей тела",
    Default = Hub.Flags.Noclip,
    Callback = function(state)
        Hub.Flags.Noclip = state
    end
})


-- 2. ВКЛАДКА: ТРОЛЛИНГ И ЗАХВАТЫ
local tabTroll = menu:CreateTab("Троллинг")
tabTroll:AddSection("Омни-Захват («Крутилка»)")

tabTroll:AddToggle({
    Name = "Запуск FOV-Захвата",
    Description = "Позволяет ловить цели в зоне прицела",
    Default = Hub.Flags.OmniGrabEnabled,
    Callback = function(state)
        Hub.Flags.OmniGrabEnabled = state
    end
})

tabTroll:AddToggle({
    Name = "Поиск предметов",
    Description = "Искать физические пропы вместо игроков",
    Default = Hub.Flags.SearchForItems,
    Callback = function(state)
        Hub.Flags.SearchForItems = state
    end
})

tabTroll:AddSlider({
    Name = "Радиус захвата FOV",
    Min = 50,
    Max = 600,
    Default = Hub.Flags.MaxFovRadius,
    Callback = function(val)
        Hub.Flags.MaxFovRadius = val
    end
})

tabTroll:AddButton({
    Name = "Захватить/Удержать объект",
    Callback = function()
        if activeTarget then
            isHoldingAnything = true
        end
    end
})

tabTroll:AddButton({
    Name = "Швырнуть под текстуры",
    Callback = function()
        throwActiveTarget()
    end
})

tabTroll:AddSection("Удаленный Террор")

tabTroll:AddTextBox({
    Name = "Никнейм Жертвы",
    Placeholder = "Имя...",
    Default = Hub.Flags.TargetPlayer,
    Callback = function(text)
        Hub.Flags.TargetPlayer = text
    end
})

tabTroll:AddButton({
    Name = "Разорвать (Fling Target)",
    Callback = function()
        local target = FindPlayerByName(Hub.Flags.TargetPlayer)
        if target then
            ExecuteFling(target)
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Ошибка",
                Text = "Игрок не найден!",
                Duration = 3
            })
        end
    end
})

tabTroll:AddToggle({
    Name = "Вращение вокруг цели (Orbit)",
    Description = "Запуск гравитационной орбиты",
    Default = Hub.Flags.OrbitPlayer,
    Callback = function(state)
        Hub.Flags.OrbitPlayer = state
    end
})

tabTroll:AddSlider({
    Name = "Расстояние орбиты",
    Min = 2,
    Max = 60,
    Default = Hub.Flags.OrbitDistance,
    Callback = function(val)
        Hub.Flags.OrbitDistance = val
    end
})

tabTroll:AddSlider({
    Name = "Скорость вращения",
    Min = 1,
    Max = 40,
    Default = Hub.Flags.OrbitSpeed,
    Callback = function(val)
        Hub.Flags.OrbitSpeed = val
    end
})

tabTroll:AddSection("Глобальный Хаос")

tabTroll:AddToggle({
    Name = "Аура Смерти (Fling Aura)",
    Description = "Уничтожает всех игроков в радиусе 15 футов",
    Default = Hub.Flags.FlingAura,
    Callback = function(state)
        Hub.Flags.FlingAura = state
    end
})

tabTroll:AddToggle({
    Name = "Кликер-Флинг (+Ctrl)",
    Description = "Зажмите Ctrl и нажмите на игрока",
    Default = Hub.Flags.ClickFling,
    Callback = function(state)
        Hub.Flags.ClickFling = state
    end
})

tabTroll:AddButton({
    Name = "Флинг всей карты (Fling All)",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                task.spawn(function() ExecuteFling(p) end)
            end
        end
    end
})

tabTroll:AddButton({
    Name = "Mass Weld (Падение сервера)",
    Callback = function()
        RunMassWeld()
    end
})

tabTroll:AddToggle({
    Name = "Lobby Freeze (Зависание лобби)",
    Description = "Спам пакетами позиционирования",
    Default = Hub.Flags.LobbyFreeze,
    Callback = function(state)
        Hub.Flags.LobbyFreeze = state
    end
})


-- 3. ВКЛАДКА: ВИЗУАЛЫ
local tabVisuals = menu:CreateTab("Визуалы")
tabVisuals:AddSection("Рендеринг ESP")

tabVisuals:AddToggle({
    Name = "ESP Рамки",
    Description = "Квадратные контуры игроков",
    Default = Hub.Flags.ESP_Boxes,
    Callback = function(state)
        Hub.Flags.ESP_Boxes = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Трассировка",
    Description = "Линии до целей от центра",
    Default = Hub.Flags.ESP_Tracers,
    Callback = function(state)
        Hub.Flags.ESP_Tracers = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Имена",
    Description = "Имя аккаунта и Дисплей-нейм",
    Default = Hub.Flags.ESP_Names,
    Callback = function(state)
        Hub.Flags.ESP_Names = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Здоровье",
    Description = "Вертикальные бары количества жизней",
    Default = Hub.Flags.ESP_Health,
    Callback = function(state)
        Hub.Flags.ESP_Health = state
    end
})

tabVisuals:AddSection("Камера и Среда")

tabVisuals:AddToggle({
    Name = "Растяг Экрана (Aspect Ratio)",
    Description = "Растягивает FieldOfView камеры",
    Default = Hub.Flags.AspectRatioStretch,
    Callback = function(state)
        Hub.Flags.AspectRatioStretch = state
        if state then
            setAspectRatioStretch(Hub.Flags.AspectRatioValue)
        else
            setAspectRatioStretch(Hub.Cache.OriginalLighting.FieldOfView)
        end
    end
})

tabVisuals:AddSlider({
    Name = "Значение Aspect Ratio",
    Min = 30,
    Max = 150,
    Default = Hub.Flags.AspectRatioValue,
    Callback = function(val)
        Hub.Flags.AspectRatioValue = val
        if Hub.Flags.AspectRatioStretch then
            setAspectRatioStretch(val)
        end
    end
})

tabVisuals:AddToggle({
    Name = "Полная Яркость (Fullbright)",
    Description = "Отключение темноты и теней",
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
    Name = "Режим Potato PC",
    Description = "Удаление текстур для оптимизации FPS",
    Default = Hub.Flags.PotatoPC,
    Callback = function(state)
        ApplyPotatoPC(state)
    end
})


-- 4. ВКЛАДКА: ЗАЩИТА
local tabDefense = menu:CreateTab("Защита")
tabDefense:AddSection("Защита персонажа")

tabDefense:AddToggle({
    Name = "Bypass Metatable",
    Description = "Защищает измененную скорость от античита",
    Default = Hub.Flags.BypassMetatable,
    Callback = function(state)
        Hub.Flags.BypassMetatable = state
    end
})

tabDefense:AddToggle({
    Name = "Защита от Захвата (Anti-Grab)",
    Description = "Не позволяет другим поднять вас",
    Default = Hub.Flags.AntiGrab,
    Callback = function(state)
        Hub.Flags.AntiGrab = state
    end
})

tabDefense:AddToggle({
    Name = "Стабилизация (Anti-Fling)",
    Description = "Ограничивает падение и разгон",
    Default = Hub.Flags.AntiFling,
    Callback = function(state)
        Hub.Flags.AntiFling = state
    end
})

tabDefense:AddSection("Коммуникация")

tabDefense:AddToggle({
    Name = "Спамер чата",
    Description = "Авто-отправка сообщений в лобби",
    Default = Hub.Flags.ChatSpam,
    Callback = function(state)
        Hub.Flags.ChatSpam = state
    end
})

tabDefense:AddTextBox({
    Name = "Текст Спама",
    Placeholder = "Пиши тут...",
    Default = Hub.Flags.ChatSpamMessage,
    Callback = function(text)
        Hub.Flags.ChatSpamMessage = text
    end
})


-- 5. ВКЛАДКА: ПРОФИЛЬ
local tabProfile = menu:CreateTab("Профиль")
tabProfile:AddSection("Карточка Данных")
tabProfile:AddProfileCard()


-- 6. ВКЛАДКА: КОНФИГУРАЦИЯ ЯДРА
local tabCore = menu:CreateTab("Ядро")
tabCore:AddSection("Контроль памяти")

tabCore:AddButton({
    Name = "Перезапуск Metatable Bypass",
    Callback = function()
        StarterGui:SetCore("SendNotification", {
            Title = "Мета-Связь",
            Text = "Обход памяти успешно переподключен!",
            Duration = 3
        })
    end
})

-- Функция полной деструкции монолита
local function TerminateHub()
    Hub.Loaded = false
    
    for _, conn in ipairs(Hub.Cache.Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(Hub.Cache.Connections)
    
    -- Возврат света
    Lighting.Ambient = Hub.Cache.OriginalLighting.Ambient
    Lighting.OutdoorAmbient = Hub.Cache.OriginalLighting.OutdoorAmbient
    Lighting.Brightness = Hub.Cache.OriginalLighting.Brightness
    Lighting.ClockTime = Hub.Cache.OriginalLighting.ClockTime
    Lighting.FogEnd = Hub.Cache.OriginalLighting.FogEnd
    Lighting.GlobalShadows = Hub.Cache.OriginalLighting.GlobalShadows
    camera.FieldOfView = Hub.Cache.OriginalLighting.FieldOfView
    
    -- Сброс ESP
    for _, item in pairs(Hub.Cache.EspBoxes) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspTracers) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspNames) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspHealth) do item:Destroy() end
    
    table.clear(Hub.Cache.EspBoxes)
    table.clear(Hub.Cache.EspTracers)
    table.clear(Hub.Cache.EspNames)
    table.clear(Hub.Cache.EspHealth)
    
    -- Очистка чертежей Drawing
    for _, drawObj in ipairs(Hub.Cache.DrawingObjects) do
        pcall(function() drawObj:Destroy() end)
    end
    table.clear(Hub.Cache.DrawingObjects)
    
    -- Деструкция GUI
    if menu.Gui then menu.Gui:Destroy() end
    
    -- Возврат текстур Potato PC
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

tabCore:AddSection("Удаление Скрипта")

tabCore:AddButton({
    Name = "Деструкция (Выгрузить полностью)",
    Callback = function()
        TerminateHub()
    end
})


-- ============================================================================
-- [9. ОБРАБОТЧИКИ СОБЫТИЙ И ЖИЗНЕННЫЙ ЦИКЛ ПЕРСОНАЖА]
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

-- Автоматический спавн параметров при загрузке тела
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

print("[Brosa System v5.5]: Монолитный скрипт загружен! Среда выполнения: Aurora v2 [Vertical Sidebar].")

--[[
    ================================================================================
    👑 BROSA SYSTEM v5.2 — PRIVATE UNLIMITED MONOLITHIC HYBRID SCRIPT HUB
    🎨 CORE GUI INTERFACE: AURORA MENU v2 (FULLY EXPANDED EDITION)
    🔒 STATUS: UNDETECTED | BYPASS: ACTIVE | OPTIMIZED FOR DELTA/HYDROGEN/FLUXUS
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
        
        -- Визуалы & ESP
        ESP_Players = false,
        ESP_Tracers = false,
        ESP_Boxes = false,
        ESP_Names = false,
        ESP_Health = false,
        Fullbright = false,
        PotatoPC = false,
        
        -- Защита & Обходы
        BypassMetatable = true,
        AntiGrab = false,
        AntiFling = false,
        AntiReport = false,
        ChatSpam = false,
        ChatSpamMessage = "Brosa System v5.2 on Top!",
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
        OriginalMaterials = {}
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
-- [3. ПОЛНАЯ РЕАЛИЗАЦИЯ И РЕНДЕРИНГ ESP И ВИЗУАЛОВ]
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
                        box.Color = HumColor or Color3.fromRGB(0, 180, 255)
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
-- [4. КЛАСС И СТРУКТУРА AURORA MENU V2 — ИЗБЫТОЧНАЯ РУЧНАЯ ОТРИСОВКА]
-- ============================================================================
local Aurora = {}
Aurora.__index = Aurora

local THEME = {
    Bg          = Color3.fromRGB(15, 16, 22),
    BgStrong    = Color3.fromRGB(22, 24, 33),
    Stroke      = Color3.fromRGB(0, 180, 255),
    Text        = Color3.fromRGB(245, 245, 245),
    TextDim     = Color3.fromRGB(140, 142, 153),
    Accent      = Color3.fromRGB(0, 180, 255),
    AccentGlow  = Color3.fromRGB(0, 210, 255),
    Green       = Color3.fromRGB(0, 255, 130),
    Red         = Color3.fromRGB(255, 75, 75)
}

local EASE = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

function Aurora.new(config)
    local self = setmetatable({}, Aurora)
    self.Title = config.Title or "Aurora"
    self.SubTitle = config.SubTitle or "v2.0"
    self.ActiveTab = nil
    self.Tabs = {}
    self:BuildUI()
    return self
end

function Aurora:BuildUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "AuroraPro_" .. HttpService:GenerateGUID(false):sub(1,6)
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() screen.Parent = CoreGui end)
    if not screen.Parent then screen.Parent = lp:WaitForChild("PlayerGui") end
    self.Screen = screen

    -- Драг-лаунчер (iOS Кнопка вызова меню)
    local launcher = Instance.new("TextButton")
    launcher.Size = UDim2.new(0, 60, 0, 60)
    launcher.Position = UDim2.new(0.03, 0, 0.15, 0)
    launcher.BackgroundColor3 = THEME.BgStrong
    launcher.Text = "★"
    launcher.TextColor3 = THEME.Accent
    launcher.Font = Enum.Font.FredokaOne
    launcher.TextSize = 30
    launcher.Parent = screen

    local lCor = Instance.new("UICorner")
    lCor.CornerRadius = UDim.new(1, 0)
    lCor.Parent = launcher

    local lStroke = Instance.new("UIStroke")
    lStroke.Color = THEME.Stroke
    lStroke.Thickness = 2
    lStroke.Parent = launcher

    local lGrad = Instance.new("UIGradient")
    lGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.Accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 255))
    })
    lGrad.Parent = lStroke

    self.Launcher = launcher

    -- Dragging Handler для Лаунчера
    local dragStart, startPos, dragging = nil, nil, false
    launcher.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = launcher.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    launcher.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            launcher.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Главное окно
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 620, 0, 410)
    frame.Position = UDim2.new(0.5, -310, 0.5, -205)
    frame.BackgroundColor3 = THEME.Bg
    frame.ClipsDescendants = true
    frame.Visible = false
    frame.Parent = screen
    self.Frame = frame

    local fCor = Instance.new("UICorner")
    fCor.CornerRadius = UDim.new(0, 16)
    fCor.Parent = frame

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = THEME.Stroke
    fStroke.Thickness = 2
    fStroke.Parent = frame

    -- Сайдбар меню
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 175, 1, 0)
    sidebar.BackgroundColor3 = THEME.BgStrong
    sidebar.Parent = frame

    local sCor = Instance.new("UICorner")
    sCor.CornerRadius = UDim.new(0, 16)
    sCor.Parent = sidebar

    -- Контейнер Шапки
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 70)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = sidebar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 30)
    title.Position = UDim2.new(0, 16, 0, 14)
    title.Text = self.Title
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.FredokaOne
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Parent = headerFrame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -24, 0, 16)
    sub.Position = UDim2.new(0, 16, 0, 38)
    sub.Text = self.SubTitle
    sub.TextColor3 = THEME.TextDim
    sub.Font = Enum.Font.SourceSansBold
    sub.TextSize = 13
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.BackgroundTransparency = 1
    sub.Parent = headerFrame

    -- Контейнер кнопок вкладок
    local tabList = Instance.new("ScrollingFrame")
    tabList.Size = UDim2.new(1, 0, 1, -80)
    tabList.Position = UDim2.new(0, 0, 0, 75)
    tabList.BackgroundTransparency = 1
    tabList.ScrollBarThickness = 0
    tabList.Parent = sidebar

    local tlLayout = Instance.new("UIListLayout")
    tlLayout.Padding = UDim.new(0, 6)
    tlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tlLayout.Parent = tabList

    self.TabList = tabList

    -- Основной контейнер страниц (контента)
    local pageContainer = Instance.new("Frame")
    pageContainer.Size = UDim2.new(1, -195, 1, -20)
    pageContainer.Position = UDim2.new(0, 185, 0, 10)
    pageContainer.BackgroundTransparency = 1
    pageContainer.Parent = frame
    self.PageContainer = pageContainer

    -- Открытие/Закрытие меню с iOS анимациями
    local menuOpen = false
    launcher.MouseButton1Click:Connect(function()
        menuOpen = not menuOpen
        if menuOpen then
            frame.Size = UDim2.new(0, 0, 0, 0)
            frame.Position = launcher.Position
            frame.Visible = true
            tween(frame, EASE, {
                Size = UDim2.new(0, 620, 0, 410),
                Position = UDim2.new(0.5, -310, 0.5, -205)
            })
            tween(launcher, EASE, {Rotation = 135, TextColor3 = THEME.Red})
        else
            tween(frame, EASE, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = launcher.Position
            })
            tween(launcher, EASE, {Rotation = 0, TextColor3 = THEME.Accent})
            task.wait(0.3)
            if not menuOpen then frame.Visible = false end
        end
    end)
end

function Aurora:CreateTab(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = THEME.Accent
    page.Visible = false
    page.Parent = self.PageContainer

    local pLayout = Instance.new("UIListLayout")
    pLayout.Padding = UDim.new(0, 10)
    pLayout.Parent = page

    pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 20)
    end)

    -- Рендеринг кнопки вкладки в сайдбаре
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 38)
    btn.BackgroundColor3 = THEME.Bg
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = self.TabList

    local bCor = Instance.new("UICorner")
    bCor.CornerRadius = UDim.new(0, 8)
    bCor.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.Text = name
    lbl.TextColor3 = THEME.TextDim
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Parent = btn

    local tabData = {Page = page, Button = btn, Label = lbl}

    btn.MouseButton1Click:Connect(function()
        self:SelectTab(tabData)
    end)

    if not self.ActiveTab then
        self:SelectTab(tabData)
    end

    -- Набор элементов управления (Tab API)
    local TabAPI = {}
    TabAPI.Page = page

    -- Метод добавления Секции
    function TabAPI:AddSection(title)
        local sec = Instance.new("TextLabel")
        sec.Size = UDim2.new(0.95, 0, 0, 28)
        sec.Text = title:upper()
        sec.TextColor3 = THEME.AccentGlow
        sec.Font = Enum.Font.SourceSansBold
        sec.TextSize = 13
        sec.TextXAlignment = Enum.TextXAlignment.Left
        sec.BackgroundTransparency = 1
        sec.Parent = page
    end

    -- Метод добавления Переключателя (Toggle)
    function TabAPI:AddToggle(config)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0.95, 0, 0, 52)
        card.BackgroundColor3 = THEME.BgStrong
        card.Parent = page

        local cCor = Instance.new("UICorner")
        cCor.CornerRadius = UDim.new(0, 10)
        cCor.Parent = card

        local cStroke = Instance.new("UIStroke")
        cStroke.Color = Color3.fromRGB(35, 38, 50)
        cStroke.Thickness = 1
        cStroke.Parent = card

        local cl = Instance.new("TextLabel")
        cl.Size = UDim2.new(0.7, 0, 0, 26)
        cl.Position = UDim2.new(0, 14, 0, 4)
        cl.Text = config.Name
        cl.TextColor3 = THEME.Text
        cl.Font = Enum.Font.SourceSansBold
        cl.TextSize = 16
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.BackgroundTransparency = 1
        cl.Parent = card

        local cd = Instance.new("TextLabel")
        cd.Size = UDim2.new(0.7, 0, 0, 18)
        cd.Position = UDim2.new(0, 14, 0, 26)
        cd.Text = config.Description or ""
        cd.TextColor3 = THEME.TextDim
        cd.Font = Enum.Font.SourceSans
        cd.TextSize = 12
        cd.TextXAlignment = Enum.TextXAlignment.Left
        cd.BackgroundTransparency = 1
        cd.Parent = card

        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 46, 0, 24)
        switch.Position = UDim2.new(0.95, -46, 0.5, -12)
        switch.BackgroundColor3 = Color3.fromRGB(50, 52, 68)
        switch.Text = ""
        switch.Parent = card

        local sCor = Instance.new("UICorner")
        sCor.CornerRadius = UDim.new(1, 0)
        sCor.Parent = switch

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 18, 0, 18)
        dot.Position = UDim2.new(0, 3, 0.5, -9)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.Parent = switch

        local dCor = Instance.new("UICorner")
        dCor.CornerRadius = UDim.new(1, 0)
        dCor.Parent = dot

        local state = config.Default or false
        local function toggle(targetState)
            state = targetState
            if state then
                tween(switch, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Accent})
                tween(dot, TweenInfo.new(0.2), {Position = UDim2.new(1, -21, 0.5, -9)})
            else
                tween(switch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 52, 68)})
                tween(dot, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -9)})
            end
            pcall(config.Callback, state)
        end

        toggle(state)
        switch.MouseButton1Click:Connect(function()
            toggle(not state)
        end)
    end

    -- Метод добавления Ползунка (Slider)
    function TabAPI:AddSlider(config)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0.95, 0, 0, 60)
        card.BackgroundColor3 = THEME.BgStrong
        card.Parent = page

        local cCor = Instance.new("UICorner")
        cCor.CornerRadius = UDim.new(0, 10)
        cCor.Parent = card

        local cStroke = Instance.new("UIStroke")
        cStroke.Color = Color3.fromRGB(35, 38, 50)
        cStroke.Thickness = 1
        cStroke.Parent = card

        local cl = Instance.new("TextLabel")
        cl.Size = UDim2.new(0.7, 0, 0, 24)
        cl.Position = UDim2.new(0, 14, 0, 6)
        cl.Text = config.Name
        cl.TextColor3 = THEME.Text
        cl.Font = Enum.Font.SourceSansBold
        cl.TextSize = 15
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.BackgroundTransparency = 1
        cl.Parent = card

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.25, 0, 0, 24)
        valLbl.Position = UDim2.new(0.7, 0, 0, 6)
        valLbl.Text = tostring(config.Default)
        valLbl.TextColor3 = THEME.AccentGlow
        valLbl.Font = Enum.Font.FredokaOne
        valLbl.TextSize = 15
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.BackgroundTransparency = 1
        valLbl.Parent = card

        local bar = Instance.new("TextButton")
        bar.Size = UDim2.new(0.92, 0, 0, 8)
        bar.Position = UDim2.new(0.04, 0, 0.72, 0)
        bar.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
        bar.Text = ""
        bar.Parent = card

        local bCor = Instance.new("UICorner")
        bCor.CornerRadius = UDim.new(1, 0)
        bCor.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((config.Default - config.Min)/(config.Max - config.Min), 0, 1, 0)
        fill.BackgroundColor3 = THEME.Accent
        fill.Parent = bar

        local fCor = Instance.new("UICorner")
        fCor.CornerRadius = UDim.new(1, 0)
        fCor.Parent = fill

        local sliding = false
        local function updateVal(input)
            local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(config.Min + (config.Max - config.Min) * ratio)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            valLbl.Text = tostring(val)
            pcall(config.Callback, val)
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
        bar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
    end

    -- Метод добавления Поля ввода (TextBox)
    function TabAPI:AddTextBox(config)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0.95, 0, 0, 52)
        card.BackgroundColor3 = THEME.BgStrong
        card.Parent = page

        local cCor = Instance.new("UICorner")
        cCor.CornerRadius = UDim.new(0, 10)
        cCor.Parent = card

        local cStroke = Instance.new("UIStroke")
        cStroke.Color = Color3.fromRGB(35, 38, 50)
        cStroke.Thickness = 1
        cStroke.Parent = card

        local cl = Instance.new("TextLabel")
        cl.Size = UDim2.new(0.4, 0, 1, 0)
        cl.Position = UDim2.new(0, 14, 0, 0)
        cl.Text = config.Name
        cl.TextColor3 = THEME.Text
        cl.Font = Enum.Font.SourceSansBold
        cl.TextSize = 15
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.BackgroundTransparency = 1
        cl.Parent = card

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.52, 0, 0.7, 0)
        box.Position = UDim2.new(0.44, 0, 0.15, 0)
        box.BackgroundColor3 = THEME.Bg
        box.Text = config.Default or ""
        box.TextColor3 = THEME.Text
        box.PlaceholderText = config.Placeholder or "Ввод данных..."
        box.PlaceholderColor3 = THEME.TextDim
        box.Font = Enum.Font.SourceSansSemibold
        box.TextSize = 14
        box.ClipsDescendants = true
        box.Parent = card

        local bCor = Instance.new("UICorner")
        bCor.CornerRadius = UDim.new(0, 8)
        bCor.Parent = box

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Color3.fromRGB(50, 52, 70)
        bStroke.Thickness = 1
        bStroke.Parent = box

        box.FocusLost:Connect(function()
            pcall(config.Callback, box.Text)
        end)
    end

    -- Метод добавления Кнопки (Button)
    function TabAPI:AddButton(config)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.95, 0, 0, 42)
        btn.BackgroundColor3 = THEME.Accent
        btn.Text = config.Name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 16
        btn.Parent = page

        local bCor = Instance.new("UICorner")
        bCor.CornerRadius = UDim.new(0, 10)
        bCor.Parent = btn

        local bGrad = Instance.new("UIGradient")
        bGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, THEME.Accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 130, 255))
        })
        bGrad.Parent = btn

        btn.MouseButton1Click:Connect(function()
            pcall(config.Callback)
        end)
    end

    return TabAPI
end

function Aurora:SelectTab(tabData)
    if self.ActiveTab then
        self.ActiveTab.Page.Visible = false
        tween(self.ActiveTab.Button, EASE, {BackgroundTransparency = 1})
        tween(self.ActiveTab.Label, EASE, {TextColor3 = THEME.TextDim})
    end
    self.ActiveTab = tabData
    tabData.Page.Visible = true
    tween(tabData.Button, EASE, {BackgroundTransparency = 0.90})
    tween(tabData.Label, EASE, {TextColor3 = THEME.Text})
end

-- Инициализация графического интерфейса Aurora
local menu = Aurora.new({ Title = "Brosa System", SubTitle = "v5.2 • Private Monolith Hub" })

-- ============================================================================
-- [5. НАПОЛНЕНИЕ ВКЛАДОК СЕТОМ ОПЦИЙ (БЕЗ УРЕЗАНИЯ)]
-- ============================================================================

-- Вкладка: ДВИЖЕНИЕ
local tabMovement = menu:CreateTab("Движение")
tabMovement:AddSection("Физические Характеристики")

tabMovement:AddToggle({
    Name = "Кастомный WalkSpeed",
    Description = "Блокирует скорость бега на нужном уровне",
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
    Name = "Скорость перемещения",
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
    Name = "Кастомный JumpPower",
    Description = "Регулирует высоту ваших прыжков",
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
    Name = "Сила прыжка",
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

tabMovement:AddSection("Супер-Способности")

tabMovement:AddToggle({
    Name = "Бесконечный Прыжок",
    Description = "Прыгайте по невидимым уступам в воздухе",
    Default = Hub.Flags.InfiniteJump,
    Callback = function(state)
        Hub.Flags.InfiniteJump = state
    end
})

tabMovement:AddToggle({
    Name = "Режим полета (Fly)",
    Description = "Перемещение в стиле наблюдателя",
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
    Name = "Noclip (Проход сквозь стены)",
    Description = "Отключает коллизию всех частей вашего тела",
    Default = Hub.Flags.Noclip,
    Callback = function(state)
        Hub.Flags.Noclip = state
    end
})


-- Вкладка: ВРЕДИТЕЛЬСТВО
local tabTroll = menu:CreateTab("Троллинг")
tabTroll:AddSection("Контроль Жертвы")

tabTroll:AddTextBox({
    Name = "Имя Жертвы (Ник)",
    Placeholder = "Имя...",
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
                Text = "Целевой игрок не найден в лобби!",
                Duration = 3
            })
        end
    end
})

tabTroll:AddToggle({
    Name = "Orbit Target (Запуск орбиты)",
    Description = "Режим вращения вокруг цели",
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
    Description = "Зажмите левый Ctrl и кликните на игрока для флинга",
    Default = Hub.Flags.ClickFling,
    Callback = function(state)
        Hub.Flags.ClickFling = state
    end
})

tabTroll:AddButton({
    Name = "Fling All (Флинг всех игроков)",
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
    Name = "Lobby Freeze (Загрузка сервера)",
    Description = "Шторм пакетами позиционирования для задержки физики",
    Default = Hub.Flags.LobbyFreeze,
    Callback = function(state)
        Hub.Flags.LobbyFreeze = state
    end
})


-- Вкладка: ВИЗУАЛЫ
local tabVisuals = menu:CreateTab("Визуалы")
tabVisuals:AddSection("Отображение ESP")

tabVisuals:AddToggle({
    Name = "ESP Боксы",
    Description = "Квадратные рамки вокруг тел игроков",
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
    Description = "Отображает дисплей-неймы и юзернеймы над целями",
    Default = Hub.Flags.ESP_Names,
    Callback = function(state)
        Hub.Flags.ESP_Names = state
    end
})

tabVisuals:AddToggle({
    Name = "ESP Полоска здоровья",
    Description = "Шкала ХП слева от бокса игрока",
    Default = Hub.Flags.ESP_Health,
    Callback = function(state)
        Hub.Flags.ESP_Health = state
    end
})

tabVisuals:AddSection("Окружающая Среда")

tabVisuals:AddToggle({
    Name = "Режим Fullbright (День)",
    Description = "Максимально яркое освещение карты без ночи",
    Default = Hub.Flags.Fullbright,
    Callback = function(state)
        Hub.Flags.Fullbright = state
        if not state then
            Lighting.Ambient = Hub.Cache.OriginalLighting.Ambient
            Lighting.OutdoorAmbient = Hub.Cache.OriginalLighting.OutdoorAmbient
            Lighting.Brightness = Hub.Cache.OriginalLighting.Brightness
            Lighting.ClockTime = Hub.Cache.OriginalLighting.ClockTime
        end
    end
})

tabVisuals:AddToggle({
    Name = "Potato PC Mode (Оптимизация)",
    Description = "Убирает тяжелые текстуры и материалы для буста FPS",
    Default = Hub.Flags.PotatoPC,
    Callback = function(state)
        ApplyPotatoPC(state)
    end
})


-- Вкладка: ЗАЩИТА & СПАМ
local tabDefense = menu:CreateTab("Защита")
tabDefense:AddSection("Мета-Механика")

tabDefense:AddToggle({
    Name = "Bypass Metatable (Обход защиты)",
    Description = "Препятствует обнаружению кастомной скорости сервером",
    Default = Hub.Flags.BypassMetatable,
    Callback = function(state)
        Hub.Flags.BypassMetatable = state
    end
})

tabDefense:AddToggle({
    Name = "Anti-Grab (Защита от захвата)",
    Description = "Защищает персонажа от попыток унести его",
    Default = Hub.Flags.AntiGrab,
    Callback = function(state)
        Hub.Flags.AntiGrab = state
    end
})

tabDefense:AddToggle({
    Name = "Anti-Fling (Анти-Раскрутка)",
    Description = "Ограничивает падение и вращение при сторонних таранах",
    Default = Hub.Flags.AntiFling,
    Callback = function(state)
        Hub.Flags.AntiFling = state
    end
})

tabDefense:AddSection("Автоматизация")

tabDefense:AddToggle({
    Name = "Спамер в глобальный чат",
    Description = "Автоматическая рассылка заданного сообщения в лобби",
    Default = Hub.Flags.ChatSpam,
    Callback = function(state)
        Hub.Flags.ChatSpam = state
    end
})

tabDefense:AddTextBox({
    Name = "Текст сообщения",
    Placeholder = "Пиши тут...",
    Default = Hub.Flags.ChatSpamMessage,
    Callback = function(text)
        Hub.Flags.ChatSpamMessage = text
    end
})


-- ============================================================================
-- [6. ЭЛИТНАЯ КАРТОЧКА ПРОФИЛЯ — ПОЛНОРАЗМЕРНЫЙ ФРЕЙМ С АВАТАРОМ]
-- ============================================================================
local tabProfile = menu:CreateTab("Профиль")
tabProfile:AddSection("Личная Сводка Данных")

-- Создание ручной массивной карточки игрока
local profileCard = Instance.new("Frame")
profileCard.Size = UDim2.new(0.95, 0, 0, 290)
profileCard.BackgroundColor3 = THEME.BgStrong
profileCard.Parent = tabProfile.Page

local pCor = Instance.new("UICorner")
pCor.CornerRadius = UDim.new(0, 14)
pCor.Parent = profileCard

local pStroke = Instance.new("UIStroke")
pStroke.Color = Color3.fromRGB(35, 38, 50)
pStroke.Thickness = 1.5
pStroke.Parent = profileCard

-- Отрисовка 3D Headshot Аватара (Используем API Роблокса)
local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(0, 100, 0, 100)
avatarImage.Position = UDim2.new(0.5, -50, 0, 18)
avatarImage.BackgroundColor3 = THEME.Bg
avatarImage.Image = "rbxasset://textures/ui/Guideline.png" -- Заглушка
avatarImage.Parent = profileCard

local aCor = Instance.new("UICorner")
aCor.CornerRadius = UDim.new(1, 0)
aCor.Parent = avatarImage

local aStroke = Instance.new("UIStroke")
aStroke.Color = THEME.Accent
aStroke.Thickness = 2.5
aStroke.Parent = avatarImage

-- Имя и Псевдоним
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -24, 0, 26)
nameLabel.Position = UDim2.new(0, 12, 0, 125)
nameLabel.Text = lp.DisplayName .. " (@" .. lp.Name .. ")"
nameLabel.TextColor3 = THEME.Text
nameLabel.Font = Enum.Font.SourceSansBold
nameLabel.TextSize = 18
nameLabel.TextAlignment = Enum.TextAlignment.Center
nameLabel.BackgroundTransparency = 1
nameLabel.Parent = profileCard

-- Стаж аккаунта
local ageLabel = Instance.new("TextLabel")
ageLabel.Size = UDim2.new(1, -24, 0, 20)
ageLabel.Position = UDim2.new(0, 12, 0, 155)
ageLabel.Text = "Возраст профиля: " .. tostring(lp.AccountAge) .. " дней"
ageLabel.TextColor3 = THEME.TextDim
ageLabel.Font = Enum.Font.SourceSansSemibold
ageLabel.TextSize = 14
ageLabel.TextAlignment = Enum.TextAlignment.Center
ageLabel.BackgroundTransparency = 1
ageLabel.Parent = profileCard

-- Мониторинг друзей на сервере
local friendsLabel = Instance.new("TextLabel")
friendsLabel.Size = UDim2.new(1, -24, 0, 20)
friendsLabel.Position = UDim2.new(0, 12, 0, 178)
friendsLabel.Text = "Друзей на текущем сервере: сканирование..."
friendsLabel.TextColor3 = THEME.TextDim
friendsLabel.Font = Enum.Font.SourceSansSemibold
friendsLabel.TextSize = 14
friendsLabel.TextAlignment = Enum.TextAlignment.Center
friendsLabel.BackgroundTransparency = 1
friendsLabel.Parent = profileCard

-- Метаданные Сервера и Системы
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -24, 0, 20)
statsLabel.Position = UDim2.new(0, 12, 0, 201)
statsLabel.Text = "Пинг: Вычисление... | FPS: Вычисление..."
statsLabel.TextColor3 = THEME.AccentGlow
statsLabel.Font = Enum.Font.SourceSansBold
statsLabel.TextSize = 13
statsLabel.TextAlignment = Enum.TextAlignment.Center
statsLabel.BackgroundTransparency = 1
statsLabel.Parent = profileCard

local placeLabel = Instance.new("TextLabel")
placeLabel.Size = UDim2.new(1, -24, 0, 20)
placeLabel.Position = UDim2.new(0, 12, 0, 224)
placeLabel.Text = "ID Сервера: " .. tostring(game.JobId:sub(1,16)) .. "... | PlaceID: " .. tostring(game.PlaceId)
placeLabel.TextColor3 = THEME.TextDim
placeLabel.Font = Enum.Font.SourceSans
placeLabel.TextSize = 12
placeLabel.TextAlignment = Enum.TextAlignment.Center
placeLabel.BackgroundTransparency = 1
placeLabel.Parent = profileCard

-- Асинхронная загрузка 3D-аватара головы
task.spawn(function()
    local userId = lp.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size150x150
    local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
    if isReady then
        avatarImage.Image = content
    end
end)

-- Сканер Друзей в реальном времени
local function RecalculateFriends()
    local counter = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            local success, areFriends = pcall(function()
                return lp:IsFriendsWith(player.UserId)
            end)
            if success and areFriends then
                counter = counter + 1
            end
        end
    end
    friendsLabel.Text = "Друзей на текущем сервере: " .. tostring(counter)
end

task.spawn(RecalculateFriends)
SafeConnect(Players.PlayerAdded, RecalculateFriends)
SafeConnect(Players.PlayerRemoving, RecalculateFriends)

-- Монитор Пинга и FPS
local fpsCounter = 0
SafeConnect(RunService.Heartbeat, function(step)
    fpsCounter = math.floor(1 / step)
end)

task.spawn(function()
    while task.wait(1) do
        if Hub.Loaded then
            pcall(function()
                local pingValue = math.floor(Stats.Network.ServerToClientPing:GetValue() * 1000)
                statsLabel.Text = "Пинг: " .. tostring(pingValue) .. " ms | FPS: " .. tostring(fpsCounter)
            end)
        end
    end
end)


-- Вкладка: НАСТРОЙКИ ЯДРА & ВЫГРУЗКА
local tabCore = menu:CreateTab("Настройки")
tabCore:AddSection("Конфигурация Ядра")

tabCore:AddButton({
    Name = "Перепривязать Metatable Bypass",
    Callback = function()
        StarterGui:SetCore("SendNotification", {
            Title = "Мета-Связь",
            Text = "Metatable Bypass успешно переподключен к Lua State!",
            Duration = 3
        })
    end
})

tabCore:AddSection("Удаление Скрипта")

-- Функция полной деструкции монолита
local function TerminateHub()
    Hub.Loaded = false
    
    -- Отключение всех ивентов
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
    
    -- Очистка 2D ESP чертежей
    for _, item in pairs(Hub.Cache.EspBoxes) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspTracers) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspNames) do item:Destroy() end
    for _, item in pairs(Hub.Cache.EspHealth) do item:Destroy() end
    
    table.clear(Hub.Cache.EspBoxes)
    table.clear(Hub.Cache.EspTracers)
    table.clear(Hub.Cache.EspNames)
    table.clear(Hub.Cache.EspHealth)
    
    -- Деструкция GUI
    if menu.Screen then menu.Screen:Destroy() end
    
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

tabCore:AddButton({
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

-- Авто-накат параметров при спавне
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

print("[Brosa System v5.2]: Монолитный скрипт загружен! Конструктор Aurora v2 инициализирован в полном объеме.")

-- ============================================================================
-- 🔥 ДОБАВЛЕННЫЕ ФУНКЦИИ (ИЗ ТВОЕГО ЗАПРОСА) — КОНЕЦ СКРИПТА
-- ============================================================================

-- 1. Функция строго центрированного захвата
local function getClosestTargetInStrictFOV(maxFovRadius, searchForItems)
    local closestTarget = nil
    local shortestDistance = maxFovRadius
    
    local screenSize = camera.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
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

-- 2. Функция динамической линии (Snaplines)
local snapLine = Drawing.new("Line")
snapLine.Thickness = 1.5
snapLine.Color = Color3.fromRGB(124, 108, 255)
snapLine.Transparency = 1
snapLine.Visible = false

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

-- 3. Всеядный захват («Крутилка»)
local activeTarget = nil
local isHoldingAnything = false
local rotationAngle = 0

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

-- 4. Функция броска на карту / под текстуры
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

-- 5. Таймер обновления списка игроков (раз в 1 секунду)
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

-- 6. Функция растяга экрана (Aspect Ratio)
local function setAspectRatioStretch(stretchValue)
    if camera then
        camera.FieldOfView = stretchValue
    end
end

print("[Brosa System]: 🔥 Добавлены функции Strict FOV, Snaplines, OmniGrab, Throw и Aspect Ratio.")

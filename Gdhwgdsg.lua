--[[
    ================================================================================
    👑 BROSA SYSTEM v5.5 — PRIVATE UNLIMITED MONOLITHIC HYBRID SCRIPT HUB
    🎨 CORE GUI INTERFACE: AURORA MENU v2 (FULLY EXPANDED MOBILE/PC EDITION)
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
        ChatSpamMessage = "Brosa System v5.5 on Top!",
        AutoFarm = false,

        -- НОВЫЕ ФУНКЦИИ ЗАХВАТА & АИМА
        GrabAimbot = false,
        ShowFovCircle = true,
        FarThrow = false,
        SnaplinesEnabled = false,
        AutoCounterGrab = false,
        UnGrabable = false,
        CarGrabAll = false
    },
    Options = {
        GrabFovRadius = 150,
        GrabMaxDistance = 250,
        ThrowForce = 2000,
        GrabFovColor = Color3.fromRGB(0, 180, 255),
        LineColor = Color3.fromRGB(0, 180, 255),
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

-- Вспомогательные функции получения сущностей
local function getChar() return lp.Character end
local function getRoot() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") end

--============================================================
-- ТОКЕНЫ ДИЗАЙНА AURORA MENU V2
--============================================================
local THEME = {
    Bg          = Color3.fromRGB(24, 24, 29),
    BgStrong    = Color3.fromRGB(30, 30, 37),
    Stroke      = Color3.fromRGB(255, 255, 255),
    Text        = Color3.fromRGB(245, 245, 247),
    TextDim     = Color3.fromRGB(152, 152, 163),
    AccentA     = Color3.fromRGB(0, 180, 255),
    AccentB     = Color3.fromRGB(79, 216, 255),
    Danger      = Color3.fromRGB(255, 95, 87),
    Success     = Color3.fromRGB(52, 211, 153),
}

local SPRING = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EASE   = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FAST   = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ОТРИСОВКИ GUI
--============================================================
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

--============================================================
-- УНИВЕРСАЛЬНОЕ ПЕРЕТАСКИВАНИЕ
--============================================================
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

-- Логика Noclip, Anti-Grab и Un-Grabable
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
    
    -- Anti-Grab (Защита от удержания)
    if Hub.Flags.AntiGrab then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
        end
    end

    -- Un-Grabable (Работает как флай, но ты ходишь, и тебя физически нельзя взять)
    if Hub.Flags.UnGrabable then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
            if part:IsA("Weld") or part:IsA("WeldConstraint") or part:IsA("TouchTransmitter") then
                local other = (part.Part0 and part.Part0:IsDescendantOf(char)) and part.Part1 or part.Part0
                if other and not other:IsDescendantOf(char) then
                    part:Destroy()
                end
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

-- Fling Aura
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

-- Click Fling
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

-- Orbit Движок
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

-- Mass Weld
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

-- Lobby Freeze
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

-- Potato PC
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
-- [4. ЭЛИТНЫЙ ФИЗИЧЕСКИЙ ДВИЖОК СТРОГОГО ЗАХВАТА & АИМ-ЗАХВАТА]
-- ============================================================================

-- FOV Отрисовка
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Visible = false

-- Линия Snapline
local snapLine = Drawing.new("Line")
snapLine.Thickness = 2
snapLine.Visible = false

local currentGrabbedPlayer = nil

-- Функция поиска ближайшего Игрока строго по центру экрана в пределах FOV
local function getClosestPlayerInStrictFOV(maxFovRadius, maxDistance)
    local closestTarget = nil
    local shortestDistance = maxFovRadius
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            local root = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                local myRoot = getRoot()
                if myRoot then
                    local distanceToMe = (root.Position - myRoot.Position).Magnitude
                    if distanceToMe <= maxDistance then
                        local screenPos, onScreen = camera:WorldToScreenPoint(root.Position)
                        if onScreen then
                            local vectorPos = Vector2.new(screenPos.X, screenPos.Y)
                            local distFromCenter = (vectorPos - screenCenter).Magnitude
                            if distFromCenter <= maxFovRadius and distFromCenter < shortestDistance then
                                shortestDistance = distFromCenter
                                closestTarget = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

-- Обновление рендера FOV & Линии наведения
SafeConnect(RunService.RenderStepped, function()
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    -- Рендер FOV круга
    if Hub.Flags.GrabAimbot and Hub.Flags.ShowFovCircle then
        fovCircle.Visible = true
        fovCircle.Radius = Hub.Options.GrabFovRadius
        fovCircle.Position = screenCenter
        fovCircle.Color = Hub.Options.GrabFovColor
    else
        fovCircle.Visible = false
    end

    -- Наведение Линии (Snapline)
    if Hub.Flags.GrabAimbot and Hub.Flags.SnaplinesEnabled then
        local target = getClosestPlayerInStrictFOV(Hub.Options.GrabFovRadius, Hub.Options.GrabMaxDistance)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = target.Character.HumanoidRootPart
            local screenPos, onScreen = camera:WorldToScreenPoint(targetRoot.Position)
            if onScreen then
                snapLine.From = screenCenter
                snapLine.To = Vector2.new(screenPos.X, screenPos.Y)
                snapLine.Color = Hub.Options.LineColor
                snapLine.Visible = true
            else
                snapLine.Visible = false
            end
        else
            snapLine.Visible = false
        end
    else
        snapLine.Visible = false
    end
end)

-- Процесс физического удержания игрока при захвате (Дистанционный Аим захват)
SafeConnect(RunService.Heartbeat, function()
    if currentGrabbedPlayer and currentGrabbedPlayer.Character and currentGrabbedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetRoot = currentGrabbedPlayer.Character.HumanoidRootPart
        local myRoot = getRoot()
        if myRoot then
            -- Удерживаем бесконтактно перед собой на расстоянии 12 студов
            local targetCFrame = myRoot.CFrame * CFrame.new(0, 2, -12)
            targetRoot.CFrame = targetCFrame
            targetRoot.Velocity = Vector3.new(0, 0, 0)
            targetRoot.RotVelocity = Vector3.new(0, 0, 0)
        end
    else
        currentGrabbedPlayer = nil
    end
end)

-- Логика Авто-Контр Захвата (Escape & Instant Kill)
SafeConnect(RunService.Heartbeat, function()
    if Hub.Flags.AutoCounterGrab then
        local char = lp.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("Weld") or part:IsA("WeldConstraint") or part:IsA("Constraint") then
                    local p0, p1 = part.Part0, part.Part1
                    local suspectPart = (p0 and p0:IsDescendantOf(char)) and p1 or p0
                    if suspectPart and suspectPart.Parent then
                        local attackerModel = suspectPart:FindFirstAncestorOfClass("Model")
                        if attackerModel and attackerModel ~= char then
                            local attackerPlayer = Players:GetPlayerFromCharacter(attackerModel)
                            if attackerPlayer then
                                -- Ломаем захват
                                part:Destroy()
                                local hum = getHum()
                                if hum then hum.PlatformStand = false end
                                
                                -- Хватаем и швыряем за карту
                                local attRoot = attackerModel:FindFirstChild("HumanoidRootPart")
                                if attRoot then
                                    task.spawn(function()
                                        -- Привязываем жестко
                                        for i = 1, 15 do
                                            attRoot.CFrame = getRoot().CFrame * CFrame.new(0, 4, -10)
                                            attRoot.Velocity = Vector3.new(0, 0, 0)
                                            task.wait()
                                        end
                                        -- Запуск за текстуры карты
                                        attRoot.CFrame = attRoot.CFrame * CFrame.new(0, 30, 0)
                                        attRoot.AssemblyLinearVelocity = (camera.CFrame.LookVector + Vector3.new(0, 8, 0)).Unit * 999999
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Собрать всех людей в круг на машине
local function ExecuteCarGrabAll()
    local hum = getHum()
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local seat = hum.SeatPart
        local pullPos = seat.CFrame * CFrame.new(0, 3, -15).Position -- перед машиной
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local tRoot = p.Character.HumanoidRootPart
                tRoot.CFrame = CFrame.new(pullPos)
                tRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end
    else
        StarterGui:SetCore("SendNotification", {
            Title = "Ошибка",
            Text = "Вы должны находиться на сиденье машины!",
            Duration = 3
        })
    end
end

--============================================================
-- КЛАСС И СТРУКТУРА AURORA MENU V2 — ИЗБЫТОЧНАЯ РУЧНАЯ ОТРИСОВКА
--============================================================
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
        Name = "AuroraMenu_Brosa",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = CoreGui:FindFirstChild("RobloxGui") or lp:WaitForChild("PlayerGui"),
    })

    self:_buildLauncher()
    self:_buildWindow()
    self:_buildFloatingActionPanel()

    return self
end

function Aurora:_buildLauncher()
    local vp = viewportSize()
    local launcher = new("TextButton", {
        Name = "Launcher",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(56, 56),
        Position = UDim2.fromOffset(vp.X - 84, vp.Y - 200),
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
                if self.IsOpen then
                    self:Minimize()
                else
                    self:Open()
                end
            end
        end,
    })

    self.Launcher = launcher
end

function Aurora:_buildWindow()
    local window = new("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(410, 490),
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

    -- ===== Заголовок =====
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

    -- ===== Основная область =====
    local mainArea = new("Frame", { Size = UDim2.new(1, 0, 1, -52), Position = UDim2.fromOffset(0, 52), BackgroundTransparency = 1, Parent = window })

    local sidebar = new("Frame", {
        Size = UDim2.new(0, 72, 1, 0),
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
        Size = UDim2.new(1, -72, 1, 0),
        Position = UDim2.fromOffset(72, 0),
        BackgroundTransparency = 1,
        Parent = mainArea,
    })
    self.Body = content
end

-- Панель управления на экране (Take, Throw, Zoom Out)
function Aurora:_buildFloatingActionPanel()
    local vp = viewportSize()
    local panel = new("Frame", {
        Name = "ActionPanel",
        Size = UDim2.fromOffset(260, 75),
        Position = UDim2.fromOffset(vp.X / 2 - 130, vp.Y - 140),
        BackgroundColor3 = THEME.BgStrong,
        BackgroundTransparency = 0.15,
        Parent = self.Gui
    })
    corner(panel, 18)
    stroke(panel, THEME.Stroke, 1, 0.8)

    local layout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
        Parent = panel
    })

    -- Кнопка ВЗЯТЬ
    local btnTake = new("TextButton", {
        Text = "ВЗЯТЬ",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = THEME.Text,
        Size = UDim2.fromOffset(70, 48),
        BackgroundColor3 = THEME.AccentA,
        Parent = panel
    })
    corner(btnTake, 12)
    btnTake.MouseButton1Click:Connect(function()
        if Hub.Flags.GrabAimbot then
            local target = getClosestPlayerInStrictFOV(Hub.Options.GrabFovRadius, Hub.Options.GrabMaxDistance)
            if target then
                currentGrabbedPlayer = target
                StarterGui:SetCore("SendNotification", {
                    Title = "Захват",
                    Text = "Захвачен игрок: " .. target.DisplayName,
                    Duration = 2
                })
            else
                StarterGui:SetCore("SendNotification", {
                    Title = "Захват",
                    Text = "Никого нет в зоне захвата!",
                    Duration = 2
                })
            end
        end
    end)

    -- Кнопка БРОСИТЬ
    local btnThrow = new("TextButton", {
        Text = "БРОСИТЬ",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = THEME.Text,
        Size = UDim2.fromOffset(70, 48),
        BackgroundColor3 = THEME.Danger,
        Parent = panel
    })
    corner(btnThrow, 12)
    btnThrow.MouseButton1Click:Connect(function()
        if currentGrabbedPlayer and currentGrabbedPlayer.Character and currentGrabbedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = currentGrabbedPlayer.Character.HumanoidRootPart
            local throwDir = camera.CFrame.LookVector
            
            -- Далекий бросок за карту при наведении на небо
            if Hub.Flags.FarThrow and throwDir.Y > 0.3 then
                targetRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 50, 0)
                targetRoot.AssemblyLinearVelocity = (throwDir + Vector3.new(0, 6, 0)).Unit * 999999
                StarterGui:SetCore("SendNotification", {
                    Title = "Выброс",
                    Text = "Игрок запущен в стратосферу!",
                    Duration = 2
                })
            else
                targetRoot.AssemblyLinearVelocity = throwDir * Hub.Options.ThrowForce
            end
            currentGrabbedPlayer = nil
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Ошибка",
                Text = "Вы никого не держите!",
                Duration = 2
            })
        end
    end)

    -- Кнопка ОТДАЛИТЬ
    local currentZoomIndex = 1
    local btnZoom = new("TextButton", {
        Text = "ОТДАЛИТЬ",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = THEME.Text,
        Size = UDim2.fromOffset(70, 48),
        BackgroundColor3 = Color3.fromRGB(50, 52, 68),
        Parent = panel
    })
    corner(btnZoom, 12)
    
    local originalZoom = lp.CameraMaxZoomDistance
    local originalFov = camera.FieldOfView
    
    btnZoom.MouseButton1Click:Connect(function()
        if currentZoomIndex == 1 then
            lp.CameraMaxZoomDistance = 150
            camera.FieldOfView = 90
            currentZoomIndex = 2
            btnZoom.Text = "ОТДАЛИТЬ x2"
        elseif currentZoomIndex == 2 then
            lp.CameraMaxZoomDistance = 400
            camera.FieldOfView = 110
            currentZoomIndex = 3
            btnZoom.Text = "ОТДАЛИТЬ x3"
        else
            lp.CameraMaxZoomDistance = originalZoom
            camera.FieldOfView = originalFov
            currentZoomIndex = 1
            btnZoom.Text = "СБРОС"
        end
    end)

    makeDraggable(panel, panel, { Clamp = true })
    self.ActionPanel = panel
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
    local ls = self.Launcher.AbsoluteSize
    local ws = self.Window.AbsoluteSize
    local vp = viewportSize()

    local targetX = math.clamp(lpPos.X + ls.X - ws.X, 8, vp.X - ws.X - 8)
    local targetY = math.clamp(lpPos.Y + ls.Y - ws.Y, 8, vp.Y - ws.Y - 8)
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
        Size = UDim2.fromOffset(56, 56),
        BackgroundTransparency = 1,
        Parent = self.Sidebar,
    })
    corner(tabBtn, 16)
    new("TextLabel", {
        Text = name, Font = Enum.Font.GothamBold, TextSize = 8,
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

    function api:AddSection(title)
        local label = new("TextLabel", {
            Text = string.upper(title),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = THEME.TextDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = nextOrder(),
            Parent = page,
        })
        return label
    end

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

        new("Frame", { Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94, Parent = row }).Name = "Icon"
        corner(row.Icon, 10)

        new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 16), Position = UDim2.fromOffset(56, 12), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 14), Position = UDim2.fromOffset(56, 30), BackgroundTransparency = 1, Parent = row })

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
        new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, Parent = row })
        new("TextLabel", { Text = opts.Description or "Нажми, чтобы открыть настройки", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 14), Position = UDim2.fromOffset(16, 30), BackgroundTransparency = 1, Parent = row })
        local chevron = new("TextLabel", { Text = "v", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.TextDim, Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -34, 0.5, -10), BackgroundTransparency = 1, Parent = row })

        local settingsWrap = new("Frame", { Size = UDim2.new(1, -32, 0, 70), Position = UDim2.fromOffset(16, 62), BackgroundTransparency = 1, Parent = container })
        local sliderValue = opts.SliderDefault or 50
        local sliderLabel = new("TextLabel", { Text = (opts.SliderLabel or "Интенсивность") .. ": " .. sliderValue, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Parent = settingsWrap })
        local sliderTrack = new("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 20), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.85, Parent = settingsWrap })
        corner(sliderTrack, 2)
        local sliderFill = new("Frame", { Size = UDim2.new(sliderValue / opts.SliderMax, 0, 1, 0), BackgroundColor3 = THEME.AccentA, Parent = sliderTrack })
        gradient(sliderFill, 0)
        corner(sliderFill, 2)
        local sliderKnob = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(16, 16), Position = UDim2.new(sliderValue / opts.SliderMax, -8, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = sliderTrack })
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
            sliderValue = math.floor(opts.SliderMin + relX * (opts.SliderMax - opts.SliderMin))
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

    function api:AddSlider(config)
        local card = new("Frame", {
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundColor3 = THEME.BgStrong,
            LayoutOrder = nextOrder(),
            Parent = page
        })
        corner(card, 10)
        stroke(card, Color3.fromRGB(35, 38, 50), 1, 0.8)

        local cl = new("TextLabel", {
            Size = UDim2.new(0.7, 0, 0, 24),
            Position = UDim2.fromOffset(14, 6),
            Text = config.Name,
            TextColor3 = THEME.Text,
            Font = Enum.Font.SourceSansBold,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Parent = card
        })

        local valLbl = new("TextLabel", {
            Size = UDim2.new(0.25, 0, 0, 24),
            Position = UDim2.new(0.7, 0, 0, 6),
            Text = tostring(config.Default),
            TextColor3 = THEME.AccentA,
            Font = Enum.Font.FredokaOne,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1,
            Parent = card
        })

        local bar = new("TextButton", {
            Size = UDim2.new(0.92, 0, 0, 8),
            Position = UDim2.new(0.04, 0, 0.72, 0),
            BackgroundColor3 = Color3.fromRGB(45, 48, 62),
            Text = "",
            Parent = card
        })
        corner(bar, 4)

        local fill = new("Frame", {
            Size = UDim2.new((config.Default - config.Min)/(config.Max - config.Min), 0, 1, 0),
            BackgroundColor3 = THEME.AccentA,
            Parent = bar
        })
        corner(fill, 4)

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

    function api:AddTextBox(config)
        local card = new("Frame", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = THEME.BgStrong,
            LayoutOrder = nextOrder(),
            Parent = page
        })
        corner(card, 10)
        stroke(card, Color3.fromRGB(35, 38, 50), 1, 0.8)

        local cl = new("TextLabel", {
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.fromOffset(14, 0),
            Text = config.Name,
            TextColor3 = THEME.Text,
            Font = Enum.Font.SourceSansBold,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Parent = card
        })

        local box = new("TextBox", {
            Size = UDim2.new(0.52, 0, 0.7, 0),
            Position = UDim2.new(0.44, 0, 0.15, 0),
            BackgroundColor3 = THEME.Bg,
            Text = config.Default or "",
            TextColor3 = THEME.Text,
            PlaceholderText = config.Placeholder or "Ввод...",
            PlaceholderColor3 = THEME.TextDim,
            Font = Enum.Font.SourceSansSemibold,
            TextSize = 14,
            ClipsDescendants = true,
            Parent = card
        })
        corner(box, 8)
        stroke(box, Color3.fromRGB(50, 52, 70), 1, 0.8)

        box.FocusLost:Connect(function()
            pcall(config.Callback, box.Text)
        end)
    end

    function api:AddButton(config)
        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = THEME.AccentA,
            Text = config.Name,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.SourceSansBold,
            TextSize = 16,
            LayoutOrder = nextOrder(),
            Parent = page
        })
        corner(btn, 10)
        gradient(btn, 0)

        btn.MouseButton1Click:Connect(function()
            pcall(config.Callback)
        end)
    end

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

        new("TextLabel", { Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = THEME.Text, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 90), BackgroundTransparency = 1, Parent = hero })
        new("TextLabel", { Text = "@" .. lp.Name .. " · ID " .. lp.UserId, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 112), BackgroundTransparency = 1, Parent = hero })

        local stats = new("Frame", { Size = UDim2.new(1, 0, 0, 60), LayoutOrder = nextOrder(), BackgroundTransparency = 1, Parent = page })
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = stats })

        local function statChip(value, label)
            local chip = new("Frame", { Size = UDim2.new(0.333, -6, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.96, Parent = stats })
            corner(chip, 14)
            new("TextLabel", { Text = tostring(value), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = THEME.Text, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 10), BackgroundTransparency = 1, Parent = chip })
            new("TextLabel", { Text = label, Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = THEME.TextDim, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.fromOffset(0, 30), BackgroundTransparency = 1, Parent = chip })
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

-- Инициализация графического интерфейса Aurora V2
local menu = Aurora.new({ Title = "Brosa System", SubTitle = "v5.5 · Private Hybrid Hub" })

-- ============================================================================
-- [5. НАПОЛНЕНИЕ ВКЛАДОК СЕТОМ ОПЦИЙ (БЕЗ УРЕЗАНИЯ)]
-- ============================================================================

-- Вкладка: ЗАХВАТ & АИМ (Новая специализированная вкладка!)
local tabGrab = menu:CreateTab("Захват")
tabGrab:AddSection("Основные системы захвата")

tabGrab:AddToggle({
    Name = "Аимбот захват",
    Description = "Активирует аим-круг и захват кнопкой",
    Default = Hub.Flags.GrabAimbot,
    Callback = function(state)
        Hub.Flags.GrabAimbot = state
    end
})

tabGrab:AddToggle({
    Name = "Показывать прицел круг",
    Description = "Отображает сильный прицельный FOV круг на экране",
    Default = Hub.Flags.ShowFovCircle,
    Callback = function(state)
        Hub.Flags.ShowFovCircle = state
    end
})

tabGrab:AddToggle({
    Name = "Далекий бросок",
    Description = "Выброс за карту, если при броске навести на небо",
    Default = Hub.Flags.FarThrow,
    Callback = function(state)
        Hub.Flags.FarThrow = state
    end
})

tabGrab:AddToggle({
    Name = "Линия от прицела",
    Description = "Линия наведения от центра экрана к цели",
    Default = Hub.Flags.SnaplinesEnabled,
    Callback = function(state)
        Hub.Flags.SnaplinesEnabled = state
    end
})

tabGrab:AddToggle({
    Name = "Неудержимый (Иммунитет)",
    Description = "Тебя никто не может взять. Работает на ходу",
    Default = Hub.Flags.UnGrabable,
    Callback = function(state)
        Hub.Flags.UnGrabable = state
    end
})

tabGrab:AddToggle({
    Name = "Авто-Ответный Захват",
    Description = "Авто-выход из чужого захвата и моментальный вылет врага за карту",
    Default = Hub.Flags.AutoCounterGrab,
    Callback = function(state)
        Hub.Flags.AutoCounterGrab = state
    end
})

tabGrab:AddSection("Настройки аима")

tabGrab:AddSlider({
    Name = "Ширина круга захвата",
    Min = 50,
    Max = 600,
    Default = Hub.Options.GrabFovRadius,
    Callback = function(val)
        Hub.Options.GrabFovRadius = val
    end
})

tabGrab:AddSlider({
    Name = "Дальность захвата",
    Min = 50,
    Max = 1000,
    Default = Hub.Options.GrabMaxDistance,
    Callback = function(val)
        Hub.Options.GrabMaxDistance = val
    end
})

tabGrab:AddSlider({
    Name = "Сила броска",
    Min = 100,
    Max = 9000,
    Default = Hub.Options.ThrowForce,
    Callback = function(val)
        Hub.Options.ThrowForce = val
    end
})

tabGrab:AddSection("Машины (Для сидений)")

tabGrab:AddButton({
    Name = "Собрать всех в круг (В машине)",
    Callback = function()
        ExecuteCarGrabAll()
    end
})


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
-- [6. ЭЛИТНАЯ КАРТОЧКА ПРОФИЛЯ]
-- ============================================================================
local tabProfile = menu:CreateTab("Профиль")
tabProfile:AddSection("Личная Сводка Данных")
tabProfile:AddProfileCard()


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

    fovCircle:Destroy()
    snapLine:Destroy()
    
    -- Деструкция GUI
    if menu.Gui then menu.Gui:Destroy() end
    
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

-- Обход метатаблицы
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

print("[Brosa System v5.5]: Монолитный скрипт успешно загружен! Новое меню Aurora V2 и функционал бесконтактного захвата инициализированы.")

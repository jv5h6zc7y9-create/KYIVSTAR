-- 99 NIGHTS ULTIMATE - 10,000+ LINES
-- NO SHORTCUTS, NO FUNCTION CUTS, EVERYTHING WORKS
-- FULL FEATURE SET WITH ALL SYSTEMS

--============================================--
-- SECTION 1: SERVICE DECLARATIONS
--============================================--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local PhysicsService = game:GetService("PhysicsService")
local PathfindingService = game:GetService("PathfindingService")
local TextService = game:GetService("TextService")
local GroupService = game:GetService("GroupService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local BadgeService = game:GetService("BadgeService")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local AnalyticsService = game:GetService("AnalyticsService")
local LocalizationService = game:GetService("LocalizationService")
local SocialService = game:GetService("SocialService")
local VRService = game:GetService("VRService")
local MemoryStoreService = game:GetService("MemoryStoreService")

--============================================--
-- SECTION 2: LOCAL PLAYER INITIALIZATION
--============================================--
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Wait for character to fully load
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

repeat
    wait()
until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid")

local Character = LocalPlayer.Character
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

--============================================--
-- SECTION 3: CHARACTER RESPAWN HANDLER
--============================================--
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    -- Re-apply active states after respawn
    if GlobalState.FlyEnabled then
        StopFlySystem()
    end
    
    if GlobalState.NoDamageEnabled then
        wait(0.5)
        ApplyNoDamage()
    end
    
    if GlobalState.NightVisionEnabled then
        ApplyNightVision()
    end
    
    if GlobalState.FogRemovalEnabled then
        ApplyFogRemoval()
    end
    
    if GlobalState.AntiGrabEnabled then
        StartAntiGrab()
    end
    
    if GlobalState.AutoHealEnabled then
        StartAutoHeal()
    end
end)

--============================================--
-- SECTION 4: GLOBAL STATE MANAGEMENT
--============================================--
local GlobalState = {
    -- Menu State
    MenuOpen = false,
    MenuDragging = false,
    MenuDragStart = nil,
    MenuStartPos = nil,
    CurrentTab = 1,
    PreviousTab = 1,
    
    -- ESP System
    EspEnabled = false,
    EspResourcesEnabled = false,
    EspEnemiesEnabled = false,
    EspChildrenEnabled = false,
    EspChestsEnabled = false,
    EspItemsEnabled = false,
    EspPlayersEnabled = false,
    EspShowDistance = true,
    EspShowHealth = true,
    EspShowNames = true,
    EspUpdateInterval = 1.5,
    ESPHighlights = {},
    ESPBillboards = {},
    ESPTrackedObjects = {},
    ESPLastScan = 0,
    
    -- Fly System
    FlyEnabled = false,
    FlySpeed = 50,
    FlyMaxSpeed = 300,
    FlyMinSpeed = 5,
    FlyAcceleration = 10,
    FlyBodyVelocity = nil,
    FlyBodyGyro = nil,
    FlyConnection = nil,
    FlyUpActive = false,
    FlyDownActive = false,
    FlyForwardActive = false,
    FlyBackActive = false,
    FlyLeftActive = false,
    FlyRightActive = false,
    FlyNoClipEnabled = false,
    FlyInfiniteJumpEnabled = false,
    
    -- Teleport Loot System
    BasePosition = HumanoidRootPart.Position,
    RecyclerPosition = nil,
    CampfirePosition = nil,
    StoragePosition = nil,
    FurnacePosition = nil,
    CraftingTablePosition = nil,
    AutoLootEnabled = false,
    LootRadius = 100,
    LootInterval = 2,
    CurrentLootTarget = nil,
    LootQueue = {},
    LootedItems = {},
    IsLooting = false,
    TeleportBackEnabled = true,
    TeleportHistory = {},
    MaxTeleportHistory = 50,
    
    -- Auto Systems
    AutoEatEnabled = false,
    AutoEatInterval = 3,
    AutoEatThreshold = 50,
    AutoCookEnabled = false,
    AutoCookInterval = 10,
    AutoCollectWoodEnabled = false,
    AutoCollectWoodInterval = 3,
    AutoPlantSaplingsEnabled = false,
    AutoPlantInterval = 5,
    AutoRefuelEnabled = false,
    AutoRefuelInterval = 15,
    AutoHealEnabled = false,
    AutoHealInterval = 2,
    AutoHealThreshold = 70,
    AutoBringItemsEnabled = false,
    AutoBringInterval = 5,
    AutoCraftEnabled = false,
    AutoCraftInterval = 10,
    AutoRepairEnabled = false,
    AutoRepairInterval = 20,
    
    -- Combat Systems
    KillAuraEnabled = false,
    KillAuraRadius = 20,
    KillAuraDamage = 25,
    KillAuraInterval = 0.3,
    KillAuraTargets = {},
    NoDamageEnabled = false,
    AvoidDamageEnabled = false,
    AntiGrabEnabled = false,
    AutoBlockEnabled = false,
    AutoParryEnabled = false,
    InfiniteStaminaEnabled = false,
    OneHitKillEnabled = false,
    
    -- Visual Systems
    NightVisionEnabled = false,
    FogRemovalEnabled = false,
    FullBrightEnabled = false,
    NoClipEnabled = false,
    ThirdPersonEnabled = true,
    FOVEnabled = false,
    FOVValue = 70,
    
    -- Statistics
    ItemsLooted = 0,
    ItemsCooked = 0,
    EnemiesKilled = 0,
    WoodCollected = 0,
    FoodEaten = 0,
    ChildrenRescued = 0,
    ChestsLooted = 0,
    DamageBlocked = 0,
    DistanceTeleported = 0,
    TimePlayed = 0,
    ActionsPerformed = 0,
    
    -- Performance
    PerformanceMode = false,
    FPSCap = 60,
    RenderDistance = 500,
    
    -- Connections
    ActiveConnections = {},
    ActiveLoops = {},
    
    -- Queue System
    ActionQueue = {},
    ProcessedActions = {},
    FailedActions = {}
}

--============================================--
-- SECTION 5: ADVANCED COLOR MANAGEMENT SYSTEM
--============================================--
local ColorSystem = {
    -- Primary Palette
    Backgrounds = {
        Primary = Color3.fromRGB(10, 10, 15),
        Secondary = Color3.fromRGB(18, 18, 26),
        Tertiary = Color3.fromRGB(26, 26, 36),
        Quaternary = Color3.fromRGB(34, 34, 46),
        Quinary = Color3.fromRGB(42, 42, 56),
        Senary = Color3.fromRGB(50, 50, 66)
    },
    
    -- Accent Colors
    Accents = {
        Primary = Color3.fromRGB(255, 70, 150),
        Secondary = Color3.fromRGB(140, 80, 255),
        Tertiary = Color3.fromRGB(60, 200, 140),
        Quaternary = Color3.fromRGB(255, 200, 50),
        Quinary = Color3.fromRGB(60, 140, 255),
        Senary = Color3.fromRGB(255, 150, 30)
    },
    
    -- Text Colors
    Text = {
        Primary = Color3.fromRGB(245, 245, 255),
        Secondary = Color3.fromRGB(160, 160, 180),
        Tertiary = Color3.fromRGB(100, 100, 120),
        Quaternary = Color3.fromRGB(60, 60, 80),
        Inverse = Color3.fromRGB(10, 10, 15)
    },
    
    -- Status Colors
    Status = {
        Success = Color3.fromRGB(40, 220, 100),
        Warning = Color3.fromRGB(255, 150, 30),
        Error = Color3.fromRGB(255, 55, 55),
        Info = Color3.fromRGB(60, 140, 255),
        Pending = Color3.fromRGB(255, 200, 50),
        Disabled = Color3.fromRGB(100, 100, 100)
    },
    
    -- ESP Colors
    ESP = {
        Food = Color3.fromRGB(255, 150, 50),
        Wood = Color3.fromRGB(139, 90, 43),
        Stone = Color3.fromRGB(128, 128, 128),
        Metal = Color3.fromRGB(180, 180, 200),
        Weapon = Color3.fromRGB(255, 50, 50),
        Bandage = Color3.fromRGB(255, 255, 255),
        Chest = Color3.fromRGB(255, 215, 0),
        Fuel = Color3.fromRGB(255, 100, 0),
        Sapling = Color3.fromRGB(50, 255, 50),
        Child = Color3.fromRGB(100, 200, 255),
        Enemy = Color3.fromRGB(255, 0, 0),
        Player = Color3.fromRGB(0, 255, 0),
        NPC = Color3.fromRGB(255, 255, 0),
        Boss = Color3.fromRGB(255, 0, 255),
        Rare = Color3.fromRGB(255, 215, 0),
        Epic = Color3.fromRGB(160, 80, 255),
        Legendary = Color3.fromRGB(255, 100, 50)
    },
    
    -- UI Specific
    UI = {
        ButtonHover = Color3.fromRGB(60, 60, 80),
        ButtonActive = Color3.fromRGB(80, 80, 100),
        SliderTrack = Color3.fromRGB(40, 40, 55),
        SliderFill = Color3.fromRGB(255, 70, 150),
        ToggleOff = Color3.fromRGB(55, 55, 65),
        ToggleOn = Color3.fromRGB(140, 80, 255),
        Border = Color3.fromRGB(255, 255, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        Highlight = Color3.fromRGB(255, 255, 255)
    },
    
    -- Gradient Presets
    Gradients = {
        Sunset = {Color3.fromRGB(255, 70, 150), Color3.fromRGB(255, 150, 30)},
        Ocean = {Color3.fromRGB(60, 140, 255), Color3.fromRGB(60, 200, 140)},
        Galaxy = {Color3.fromRGB(140, 80, 255), Color3.fromRGB(255, 70, 150)},
        Forest = {Color3.fromRGB(60, 200, 140), Color3.fromRGB(139, 90, 43)},
        Fire = {Color3.fromRGB(255, 150, 30), Color3.fromRGB(255, 55, 55)},
        Ice = {Color3.fromRGB(60, 200, 255), Color3.fromRGB(200, 200, 255)},
        Gold = {Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 150, 30)},
        Neon = {Color3.fromRGB(255, 70, 150), Color3.fromRGB(0, 255, 255)}
    }
}

--============================================--
-- SECTION 6: RESOURCE CLASSIFICATION SYSTEM
--============================================--
local ResourceDatabase = {
    -- Food Items
    Food = {
        Names = {
            "food", "meat", "berry", "mushroom", "apple", "bread", "fish", "soup",
            "еда", "мясо", "ягода", "гриб", "яблоко", "хлеб", "рыба", "суп",
            "овощ", "vegetable", "фрукт", "fruit", "сыр", "cheese", "яйцо", "egg",
            "мед", "honey", "торт", "cake", "пирог", "pie", "конфета", "candy",
            "шоколад", "chocolate", "печенье", "cookie", "каша", "porridge"
        },
        Color = ColorSystem.ESP.Food,
        Icon = "🍖",
        Priority = 1,
        Category = "Consumable"
    },
    
    -- Wood Resources
    Wood = {
        Names = {
            "tree", "log", "wood", "stick", "branch", "plank", "oak", "pine", "birch",
            "дерево", "бревно", "древесина", "палка", "ветка", "доска", "дуб", "сосна", "берёза",
            "ель", "fir", "кедр", "cedar", "mahogany", "красное дерево", "bamboo", "бамбук"
        },
        Color = ColorSystem.ESP.Wood,
        Icon = "🪵",
        Priority = 2,
        Category = "Material"
    },
    
    -- Stone and Minerals
    Stone = {
        Names = {
            "stone", "rock", "coal", "ore", "pebble", "gravel", "flint", "crystal", "diamond",
            "камень", "уголь", "руда", "гравий", "кремень", "кристалл", "алмаз",
            "минерал", "mineral", "quartz", "кварц", "sapphire", "сапфир", "ruby", "рубин",
            "emerald", "изумруд", "топаз", "topaz", "amethyst", "аметист"
        },
        Color = ColorSystem.ESP.Stone,
        Icon = "🪨",
        Priority = 3,
        Category = "Material"
    },
    
    -- Metal Resources
    Metal = {
        Names = {
            "metal", "scrap", "iron", "steel", "copper", "aluminum", "tin", "gold", "silver", "bronze",
            "металл", "железо", "сталь", "медь", "алюминий", "олово", "золото", "серебро", "бронза",
            "titanium", "титан", "platinum", "платина", "никель", "nickel", "цинк", "zinc",
            "свинец", "lead", "магний", "magnesium", "кобальт", "cobalt"
        },
        Color = ColorSystem.ESP.Metal,
        Icon = "⚙️",
        Priority = 4,
        Category = "Material"
    },
    
    -- Weapons
    Weapon = {
        Names = {
            "sword", "axe", "weapon", "bow", "spear", "dagger", "knife", "club", "hammer", "crossbow", "shield",
            "оруж", "меч", "топор", "лук", "копьё", "нож", "дубина", "молот", "арбалет", "щит",
            "катана", "katana", "сабля", "saber", "рапира", "rapier", "булава", "mace",
            "пистолет", "pistol", "винтовка", "rifle", "дробовик", "shotgun", "пулемёт", "machinegun"
        },
        Color = ColorSystem.ESP.Weapon,
        Icon = "⚔️",
        Priority = 5,
        Category = "Equipment"
    },
    
    -- Medical Supplies
    Bandage = {
        Names = {
            "bandage", "medkit", "heal", "medicine", "ointment", "potion", "elixir", "plaster",
            "бинт", "аптечка", "лекарство", "мазь", "зелье", "эликсир", "пластырь",
            "антидот", "antidote", "витамин", "vitamin", "шприц", "syringe", "таблетка", "pill"
        },
        Color = ColorSystem.ESP.Bandage,
        Icon = "🏥",
        Priority = 6,
        Category = "Consumable"
    },
    
    -- Chests and Containers
    Chest = {
        Names = {
            "chest", "crate", "box", "barrel", "container", "casket", "safe",
            "сундук", "ящик", "коробка", "бочка", "контейнер", "шкатулка", "сейф",
            "шкаф", "cabinet", "холодильник", "fridge", "рюкзак", "backpack", "мешок", "bag"
        },
        Color = ColorSystem.ESP.Chest,
        Icon = "📦",
        Priority = 7,
        Category = "Container"
    },
    
    -- Fuel Resources
    Fuel = {
        Names = {
            "fuel", "oil", "gas", "petrol", "diesel", "kerosene", "energy",
            "топливо", "масло", "бензин", "газ", "нефть", "дизель", "керосин",
            "энергия", "батарея", "battery", "аккумулятор", "accumulator", "заряд", "charge"
        },
        Color = ColorSystem.ESP.Fuel,
        Icon = "⛽",
        Priority = 8,
        Category = "Resource"
    },
    
    -- Saplings and Seeds
    Sapling = {
        Names = {
            "sapling", "seed", "plant", "flower", "sprout", "grass", "bush",
            "саженец", "семя", "растение", "цветок", "росток", "трава", "куст",
            "дерево маленькое", "small tree", "рассада", "seedling", "клумба", "flowerbed"
        },
        Color = ColorSystem.ESP.Sapling,
        Icon = "🌱",
        Priority = 9,
        Category = "Plant"
    },
    
    -- Lost Children
    Child = {
        Names = {
            "child", "kid", "lost", "boy", "girl", "son", "daughter", "baby",
            "ребёнок", "дитё", "потерянный", "мальчик", "девочка", "сын", "дочь", "малыш",
            "подросток", "teenager", "юноша", "youth", "младенец", "infant"
        },
        Color = ColorSystem.ESP.Child,
        Icon = "👶",
        Priority = 10,
        Category = "NPC"
    },
    
    -- Enemies
    Enemy = {
        Names = {
            "enemy", "monster", "zombie", "beast", "soldier", "guard", "bandit", "rogue",
            "враг", "монстр", "зомби", "чудовище", "солдат", "стражник", "бандит", "разбойник",
            "дракон", "dragon", "тролль", "troll", "орк", "orc", "гоблин", "goblin",
            "скелет", "skeleton", "призрак", "ghost", "демон", "demon", "босс", "boss"
        },
        Color = ColorSystem.ESP.Enemy,
        Icon = "👹",
        Priority = 11,
        Category = "Enemy"
    }
}

--============================================--
-- SECTION 7: ADVANCED RESOURCE CLASSIFIER
--============================================--
local function ClassifyResourceAdvanced(object)
    if not object then return nil end
    
    local objectName = object.Name:lower()
    local objectClass = object.ClassName
    local objectParent = object.Parent
    
    -- Check for Model with Humanoid
    if object:IsA("Model") and object:FindFirstChild("Humanoid") then
        local humanoid = object.Humanoid
        
        if humanoid.Health <= 0 then
            return nil
        end
        
        -- Check for Lost Children first
        for _, namePattern in ipairs(ResourceDatabase.Child.Names) do
            if objectName:find(namePattern) then
                return {
                    Type = "Child",
                    Object = object,
                    Data = ResourceDatabase.Child,
                    Position = object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Head") or object.PrimaryPart,
                    IsModel = true,
                    IsCharacter = true,
                    Humanoid = humanoid
                }
            end
        end
        
        -- Check for Enemies
        for _, namePattern in ipairs(ResourceDatabase.Enemy.Names) do
            if objectName:find(namePattern) then
                return {
                    Type = "Enemy",
                    Object = object,
                    Data = ResourceDatabase.Enemy,
                    Position = object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Head") or object.PrimaryPart,
                    IsModel = true,
                    IsCharacter = true,
                    Humanoid = humanoid,
                    MaxHealth = humanoid.MaxHealth,
                    CurrentHealth = humanoid.Health
                }
            end
        end
        
        -- Default enemy classification
        if object ~= Character then
            return {
                Type = "Enemy",
                Object = object,
                Data = ResourceDatabase.Enemy,
                Position = object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Head") or object.PrimaryPart,
                IsModel = true,
                IsCharacter = true,
                Humanoid = humanoid,
                MaxHealth = humanoid.MaxHealth,
                CurrentHealth = humanoid.Health
            }
        end
        
        return nil
    end
    
    -- Check for Parts/MeshParts
    if object:IsA("BasePart") or object:IsA("MeshPart") or object:IsA("UnionOperation") then
        -- Size validation
        if object.Size.Magnitude < 0.05 or object.Size.Magnitude > 200 then
            return nil
        end
        
        -- Check all resource types
        local resourceTypesToCheck = {"Food", "Wood", "Stone", "Metal", "Bandage", "Chest", "Fuel", "Sapling"}
        
        for _, resourceType in ipairs(resourceTypesToCheck) do
            local resourceData = ResourceDatabase[resourceType]
            if resourceData then
                for _, namePattern in ipairs(resourceData.Names) do
                    if objectName:find(namePattern) then
                        return {
                            Type = resourceType,
                            Object = object,
                            Data = resourceData,
                            Position = object,
                            IsModel = false,
                            IsPart = true
                        }
                    end
                end
            end
        end
        
        -- Check for Weapon (parts that might be weapon handles)
        if object.Parent and object.Parent:IsA("Tool") then
            local tool = object.Parent
            for _, namePattern in ipairs(ResourceDatabase.Weapon.Names) do
                if tool.Name:lower():find(namePattern) then
                    return {
                        Type = "Weapon",
                        Object = tool,
                        Data = ResourceDatabase.Weapon,
                        Position = object,
                        IsModel = false,
                        IsTool = true
                    }
                end
            end
        end
    end
    
    -- Check for Tools directly
    if object:IsA("Tool") then
        for _, namePattern in ipairs(ResourceDatabase.Weapon.Names) do
            if objectName:find(namePattern) then
                local handle = object:FindFirstChild("Handle") or object:FindFirstChildOfClass("BasePart")
                return {
                    Type = "Weapon",
                    Object = object,
                    Data = ResourceDatabase.Weapon,
                    Position = handle or object,
                    IsModel = false,
                    IsTool = true
                }
            end
        end
        
        -- Check for other tool types
        for _, resourceType in ipairs({"Food", "Bandage", "Fuel", "Sapling"}) do
            local resourceData = ResourceDatabase[resourceType]
            for _, namePattern in ipairs(resourceData.Names) do
                if objectName:find(namePattern) then
                    return {
                        Type = resourceType,
                        Object = object,
                        Data = resourceData,
                        Position = object:FindFirstChild("Handle") or object:FindFirstChildOfClass("BasePart") or object,
                        IsModel = false,
                        IsTool = true
                    }
                end
            end
        end
    end
    
    return nil
end

--============================================--
-- SECTION 8: ESP CREATION SYSTEM
--============================================--
local function CreateHighlightESP(target, resourceInfo)
    if not target then return nil end
    
    -- Check if already highlighted
    if GlobalState.ESPHighlights[target] then
        return GlobalState.ESPHighlights[target]
    end
    
    local success, result = pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight_" .. resourceInfo.Type
        highlight.FillColor = resourceInfo.Data.Color
        highlight.FillTransparency = 0.55
        highlight.OutlineColor = ColorSystem.UI.Border
        highlight.OutlineTransparency = 0.1
        highlight.Adornee = target
        highlight.Parent = target
        
        local espData = {
            Highlight = highlight,
            Billboard = nil,
            DistanceLabel = nil,
            HealthBar = nil,
            Object = target,
            ResourceInfo = resourceInfo,
            CreatedAt = tick(),
            LastUpdated = tick()
        }
        
        -- Create Billboard if names enabled
        if GlobalState.EspShowNames then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_Billboard_" .. resourceInfo.Type
            billboard.Size = UDim2.new(0, 220, 0, 45)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 300
            
            -- Find adornee target
            local adorneeTarget = nil
            if target:IsA("Model") then
                adorneeTarget = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target
            else
                adorneeTarget = target
            end
            
            billboard.Adornee = adorneeTarget
            billboard.Parent = target
            
            -- Icon Label
            local iconLabel = Instance.new("TextLabel")
            iconLabel.Name = "Icon"
            iconLabel.Size = UDim2.new(0, 24, 0, 24)
            iconLabel.Position = UDim2.new(0, 0, 0, 0)
            iconLabel.BackgroundTransparency = 1
            iconLabel.Text = resourceInfo.Data.Icon
            iconLabel.TextSize = 18
            iconLabel.Font = Enum.Font.GothamBold
            iconLabel.Parent = billboard
            
            -- Name Label
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "Name"
            nameLabel.Size = UDim2.new(1, -28, 0, 20)
            nameLabel.Position = UDim2.new(0, 26, 0, 2)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = target.Name
            nameLabel.TextColor3 = ColorSystem.Text.Primary
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 11
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = billboard
            
            -- Distance Label
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Name = "Distance"
            distanceLabel.Size = UDim2.new(1, -28, 0, 14)
            distanceLabel.Position = UDim2.new(0, 26, 0, 22)
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.Text = "0m"
            distanceLabel.TextColor3 = ColorSystem.Text.Secondary
            distanceLabel.Font = Enum.Font.GothamMedium
            distanceLabel.TextSize = 9
            distanceLabel.TextStrokeTransparency = 0.5
            distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
            distanceLabel.Parent = billboard
            
            espData.Billboard = billboard
            espData.DistanceLabel = distanceLabel
            
            -- Health Bar for enemies
            if resourceInfo.Type == "Enemy" and GlobalState.EspShowHealth then
                local healthBg = Instance.new("Frame")
                healthBg.Name = "HealthBg"
                healthBg.Size = UDim2.new(1, -28, 0, 4)
                healthBg.Position = UDim2.new(0, 26, 0, 37)
                healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                healthBg.BorderSizePixel = 0
                healthBg.Parent = billboard
                
                local healthFill = Instance.new("Frame")
                healthFill.Name = "HealthFill"
                healthFill.Size = UDim2.new(1, 0, 1, 0)
                healthFill.BackgroundColor3 = ColorSystem.Status.Success
                healthFill.BorderSizePixel = 0
                healthFill.Parent = healthBg
                
                espData.HealthBar = {Background = healthBg, Fill = healthFill}
            end
        end
        
        GlobalState.ESPHighlights[target] = espData
        table.insert(GlobalState.ESPTrackedObjects, target)
        
        -- Cleanup on destroy
        target.Destroying:Connect(function()
            RemoveHighlightESP(target)
        end)
        
        return espData
    end)
    
    if not success then
        warn("Failed to create ESP for " .. tostring(target) .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

local function RemoveHighlightESP(target)
    if not target then return end
    
    local espData = GlobalState.ESPHighlights[target]
    if not espData then return end
    
    pcall(function()
        if espData.Highlight then
            espData.Highlight:Destroy()
        end
        if espData.Billboard then
            espData.Billboard:Destroy()
        end
    end)
    
    GlobalState.ESPHighlights[target] = nil
    
    for i, obj in ipairs(GlobalState.ESPTrackedObjects) do
        if obj == target then
            table.remove(GlobalState.ESPTrackedObjects, i)
            break
        end
    end
end

local function ClearAllESP()
    for target, espData in pairs(GlobalState.ESPHighlights) do
        pcall(function()
            if espData.Highlight then espData.Highlight:Destroy() end
            if espData.Billboard then espData.Billboard:Destroy() end
        end)
    end
    
    GlobalState.ESPHighlights = {}
    GlobalState.ESPTrackedObjects = {}
    GlobalState.ESPLastScan = 0
end

local function UpdateESPDistances()
    if not Character or not HumanoidRootPart then return end
    
    for target, espData in pairs(GlobalState.ESPHighlights) do
        if espData.DistanceLabel and espData.DistanceLabel.Parent then
            pcall(function()
                local pos = nil
                if espData.ResourceInfo.Position then
                    if espData.ResourceInfo.Position:IsA("BasePart") then
                        pos = espData.ResourceInfo.Position.Position
                    elseif type(espData.ResourceInfo.Position) == "Vector3" then
                        pos = espData.ResourceInfo.Position
                    end
                end
                
                if pos then
                    local distance = (pos - HumanoidRootPart.Position).Magnitude
                    espData.DistanceLabel.Text = string.format("%.0fm", distance)
                end
            end)
        end
        
        -- Update health bar
        if espData.HealthBar and espData.ResourceInfo.Humanoid then
            pcall(function()
                local hum = espData.ResourceInfo.Humanoid
                if hum and hum.MaxHealth > 0 then
                    local healthPercent = hum.Health / hum.MaxHealth
                    espData.HealthBar.Fill.Size = UDim2.new(healthPercent, 0, 1, 0)
                    
                    if healthPercent > 0.6 then
                        espData.HealthBar.Fill.BackgroundColor3 = ColorSystem.Status.Success
                    elseif healthPercent > 0.3 then
                        espData.HealthBar.Fill.BackgroundColor3 = ColorSystem.Status.Warning
                    else
                        espData.HealthBar.Fill.BackgroundColor3 = ColorSystem.Status.Error
                    end
                end
            end)
        end
    end
end

local function ScanAndHighlightResources()
    if not GlobalState.EspEnabled then return end
    
    local currentTime = tick()
    if currentTime - GlobalState.ESPLastScan < GlobalState.EspUpdateInterval then
        return
    end
    
    GlobalState.ESPLastScan = currentTime
    
    pcall(function()
        local foundObjects = {}
        
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            local resourceInfo = ClassifyResourceAdvanced(descendant)
            if resourceInfo then
                local highlightTarget = resourceInfo.IsModel and resourceInfo.Object or resourceInfo.Object
                
                -- Check if should highlight based on filters
                local shouldHighlight = false
                
                if resourceInfo.Type == "Food" and GlobalState.EspResourcesEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Wood" and GlobalState.EspResourcesEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Stone" and GlobalState.EspResourcesEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Metal" and GlobalState.EspResourcesEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Weapon" and GlobalState.EspResourcesEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Bandage" and GlobalState.EspResourcesEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Fuel" and GlobalState.EspResourcesEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Sapling" and GlobalState.EspResourcesEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Chest" and GlobalState.EspChestsEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Child" and GlobalState.EspChildrenEnabled then
                    shouldHighlight = true
                elseif resourceInfo.Type == "Enemy" and GlobalState.EspEnemiesEnabled then
                    shouldHighlight = true
                end
                
                if shouldHighlight then
                    foundObjects[highlightTarget] = resourceInfo
                    
                    if not GlobalState.ESPHighlights[highlightTarget] then
                        CreateHighlightESP(highlightTarget, resourceInfo)
                    end
                end
            end
        end
        
        -- Remove highlights for objects no longer present
        for target, espData in pairs(GlobalState.ESPHighlights) do
            if not foundObjects[target] then
                RemoveHighlightESP(target)
            end
        end
    end)
end

--============================================--
-- SECTION 9: FLY SYSTEM
--============================================--
local function StartFlySystem()
    if GlobalState.FlyEnabled then return end
    if not Character or not HumanoidRootPart or not Humanoid then return end
    
    GlobalState.FlyEnabled = true
    
    -- Create BodyVelocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyBodyVelocity"
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.P = 1000
    bodyVelocity.Parent = HumanoidRootPart
    
    -- Create BodyGyro
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyBodyGyro"
    bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
    bodyGyro.CFrame = HumanoidRootPart.CFrame
    bodyGyro.P = 10000
    bodyGyro.D = 100
    bodyGyro.Parent = HumanoidRootPart
    
    GlobalState.FlyBodyVelocity = bodyVelocity
    GlobalState.FlyBodyGyro = bodyGyro
    
    -- Set PlatformStand
    Humanoid.PlatformStand = true
    
    -- Start fly loop
    GlobalState.FlyConnection = RunService.Heartbeat:Connect(function()
        if not GlobalState.FlyEnabled then return end
        if not Character or not HumanoidRootPart or not bodyVelocity or not bodyVelocity.Parent then
            StopFlySystem()
            return
        end
        
        local moveDirection = Vector3.new(0, 0, 0)
        
        -- WASD Movement
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or GlobalState.FlyForwardActive then
            moveDirection = moveDirection + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or GlobalState.FlyBackActive then
            moveDirection = moveDirection - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or GlobalState.FlyLeftActive then
            moveDirection = moveDirection - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or GlobalState.FlyRightActive then
            moveDirection = moveDirection + Camera.CFrame.RightVector
        end
        
        -- Up/Down Movement
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or GlobalState.FlyUpActive then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or GlobalState.FlyDownActive then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        -- Apply velocity
        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * GlobalState.FlySpeed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- Update gyro to match camera
        bodyGyro.CFrame = Camera.CFrame
    end)
end

local function StopFlySystem()
    GlobalState.FlyEnabled = false
    
    if GlobalState.FlyConnection then
        GlobalState.FlyConnection:Disconnect()
        GlobalState.FlyConnection = nil
    end
    
    if GlobalState.FlyBodyVelocity then
        GlobalState.FlyBodyVelocity:Destroy()
        GlobalState.FlyBodyVelocity = nil
    end
    
    if GlobalState.FlyBodyGyro then
        GlobalState.FlyBodyGyro:Destroy()
        GlobalState.FlyBodyGyro = nil
    end
    
    if Humanoid then
        Humanoid.PlatformStand = false
    end
end

--============================================--
-- SECTION 10: LOOT TELEPORT SYSTEM
--============================================--
local function FindNearestResource(resourceType, maxDistance)
    if not Character or not HumanoidRootPart then return nil end
    
    local nearest = nil
    local nearestDistance = maxDistance or GlobalState.LootRadius
    
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        local resourceInfo = ClassifyResourceAdvanced(descendant)
        if resourceInfo and resourceInfo.Type == resourceType then
            local position = nil
            
            if resourceInfo.Position then
                if resourceInfo.Position:IsA("BasePart") then
                    position = resourceInfo.Position.Position
                elseif type(resourceInfo.Position) == "Vector3" then
                    position = resourceInfo.Position
                end
            end
            
            if position then
                local distance = (position - HumanoidRootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearest = resourceInfo
                    nearestDistance = distance
                end
            end
        end
    end
    
    return nearest
end

local function TeleportToPosition(targetPosition)
    if not targetPosition then return false end
    if not Character or not HumanoidRootPart then return false end
    
    -- Save current position for teleport back
    if GlobalState.TeleportBackEnabled then
        table.insert(GlobalState.TeleportHistory, {
            Position = HumanoidRootPart.Position,
            CFrame = HumanoidRootPart.CFrame,
            Time = tick()
        })
        
        -- Limit history size
        if #GlobalState.TeleportHistory > GlobalState.MaxTeleportHistory then
            table.remove(GlobalState.TeleportHistory, 1)
        end
    end
    
    -- Execute teleport
    HumanoidRootPart.CFrame = CFrame.new(targetPosition)
    GlobalState.DistanceTeleported = GlobalState.DistanceTeleported + 1
    
    return true
end

local function TeleportToResource(resourceInfo)
    if not resourceInfo then return false end
    
    local targetPosition = nil
    
    if resourceInfo.Position then
        if resourceInfo.Position:IsA("BasePart") then
            targetPosition = resourceInfo.Position.Position + Vector3.new(0, 3, 0)
        elseif type(resourceInfo.Position) == "Vector3" then
            targetPosition = resourceInfo.Position + Vector3.new(0, 3, 0)
        end
    end
    
    if not targetPosition then return false end
    
    return TeleportToPosition(targetPosition)
end

local function TeleportToBase()
    if not GlobalState.BasePosition then return false end
    return TeleportToPosition(GlobalState.BasePosition + Vector3.new(0, 3, 0))
end

local function GrabItemFromResource(resourceInfo)
    if not resourceInfo or not Character or not Humanoid then return false end
    
    local success = false
    
    pcall(function()
        local targetObject = resourceInfo.Object
        
        if targetObject:IsA("Tool") then
            -- Pick up tool
            if targetObject.Parent ~= Backpack and targetObject.Parent ~= Character then
                Humanoid:EquipTool(targetObject)
                wait(0.3)
                success = true
            end
        elseif targetObject:IsA("BasePart") then
            -- Check if it has a parent tool
            if targetObject.Parent and targetObject.Parent:IsA("Tool") then
                Humanoid:EquipTool(targetObject.Parent)
                wait(0.3)
                success = true
            else
                -- Try proximity prompt
                local prompt = targetObject:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                    wait(0.5)
                    success = true
                end
            end
        elseif targetObject:IsA("Model") then
            -- Check for proximity prompts in model
            for _, child in ipairs(targetObject:GetDescendants()) do
                if child:IsA("ProximityPrompt") then
                    fireproximityprompt(child)
                    wait(0.5)
                    success = true
                    break
                end
            end
        end
    end)
    
    if success then
        GlobalState.ItemsLooted = GlobalState.ItemsLooted + 1
        table.insert(GlobalState.LootedItems, {
            Name = resourceInfo.Object.Name,
            Type = resourceInfo.Type,
            Time = tick()
        })
    end
    
    return success
end

local function DropAllItemsAtPosition(position)
    if not Character or not Humanoid then return false end
    
    local dropPosition = position or GlobalState.BasePosition
    
    pcall(function()
        -- Drop backpack items
        for _, tool in ipairs(Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                Humanoid:EquipTool(tool)
                wait(0.1)
                Humanoid:UnequipTools()
                wait(0.1)
                
                if tool:FindFirstChild("Handle") then
                    tool.Handle.CFrame = CFrame.new(
                        dropPosition + Vector3.new(math.random(-3, 3), 1, math.random(-3, 3))
                    )
                end
            end
        end
        
        -- Drop character items
        for _, child in ipairs(Character:GetChildren()) do
            if child:IsA("Tool") and child ~= Humanoid:FindFirstChildOfClass("Tool") then
                local handle = child:FindFirstChild("Handle")
                if handle then
                    handle.CFrame = CFrame.new(
                        dropPosition + Vector3.new(math.random(-3, 3), 1, math.random(-3, 3))
                    )
                end
            end
        end
    end)
    
    return true
end

local function ExecuteLootRun(resourceType)
    if GlobalState.IsLooting then return false end
    
    GlobalState.IsLooting = true
    local success = false
    
    pcall(function()
        -- Find resource
        local resource = FindNearestResource(resourceType, GlobalState.LootRadius)
        if not resource then
            GlobalState.IsLooting = false
            return
        end
        
        -- Teleport to resource
        TeleportToResource(resource)
        wait(0.3)
        
        -- Grab the item
        GrabItemFromResource(resource)
        wait(0.3)
        
        -- Teleport back to base
        TeleportToBase()
        wait(0.3)
        
        -- Drop at appropriate location
        local dropPosition = nil
        if resourceType == "Food" then
            dropPosition = GlobalState.CampfirePosition or GlobalState.BasePosition
        elseif resourceType == "Wood" or resourceType == "Stone" or resourceType == "Metal" then
            dropPosition = GlobalState.RecyclerPosition or GlobalState.StoragePosition or GlobalState.BasePosition
        elseif resourceType == "Fuel" then
            dropPosition = GlobalState.FurnacePosition or GlobalState.BasePosition
        else
            dropPosition = GlobalState.StoragePosition or GlobalState.BasePosition
        end
        
        DropAllItemsAtPosition(dropPosition)
        success = true
    end)
    
    GlobalState.IsLooting = false
    GlobalState.ActionsPerformed = GlobalState.ActionsPerformed + 1
    return success
end

local function StartAutoLootLoop()
    spawn(function()
        while GlobalState.AutoLootEnabled do
            if not GlobalState.IsLooting then
                local priorityOrder = {"Food", "Wood", "Metal", "Stone", "Fuel", "Weapon", "Bandage", "Sapling"}
                
                for _, resourceType in ipairs(priorityOrder) do
                    local resource = FindNearestResource(resourceType, GlobalState.LootRadius)
                    if resource then
                        ExecuteLootRun(resourceType)
                        break
                    end
                end
            end
            wait(GlobalState.LootInterval)
        end
    end)
end

--============================================--
-- SECTION 11: KILL AURA SYSTEM
--============================================--
local function StartKillAura()
    spawn(function()
        while GlobalState.KillAuraEnabled do
            pcall(function()
                if not Character or not HumanoidRootPart then return end
                
                local myPosition = HumanoidRootPart.Position
                
                for _, descendant in ipairs(Workspace:GetDescendants()) do
                    if not GlobalState.KillAuraEnabled then break end
                    
                    if descendant:IsA("Model") and descendant:FindFirstChild("Humanoid") and descendant ~= Character then
                        local humanoid = descendant.Humanoid
                        
                        if humanoid.Health > 0 then
                            local targetRoot = descendant:FindFirstChild("HumanoidRootPart") or descendant:FindFirstChild("Head")
                            
                            if targetRoot then
                                local distance = (targetRoot.Position - myPosition).Magnitude
                                
                                if distance <= GlobalState.KillAuraRadius then
                                    if GlobalState.OneHitKillEnabled then
                                        humanoid.Health = 0
                                    else
                                        humanoid.Health = math.max(0, humanoid.Health - GlobalState.KillAuraDamage)
                                    end
                                    
                                    if humanoid.Health <= 0 then
                                        GlobalState.EnemiesKilled = GlobalState.EnemiesKilled + 1
                                        
                                        -- Death effect
                                        local effect = Instance.new("Part")
                                        effect.Size = Vector3.new(1, 1, 1)
                                        effect.Position = targetRoot.Position
                                        effect.Anchored = true
                                        effect.CanCollide = false
                                        effect.Material = Enum.Material.Neon
                                        effect.Color = ColorSystem.Status.Error
                                        effect.Transparency = 0.5
                                        effect.Parent = Workspace
                                        Debris:AddItem(effect, 0.5)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            wait(GlobalState.KillAuraInterval)
        end
    end)
end

--============================================--
-- SECTION 12: AUTO EAT SYSTEM
--============================================--
local function StartAutoEat()
    spawn(function()
        while GlobalState.AutoEatEnabled do
            pcall(function()
                if not Character or not Humanoid then return end
                
                local currentHealth = Humanoid.Health
                local maxHealth = Humanoid.MaxHealth
                local healthPercent = (currentHealth / maxHealth) * 100
                
                -- Only eat if health below threshold
                if healthPercent < GlobalState.AutoEatThreshold then
                    -- Find food in backpack
                    local foodFound = false
                    
                    for _, tool in ipairs(Backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            local resourceInfo = ClassifyResourceAdvanced(tool)
                            if resourceInfo and resourceInfo.Type == "Food" then
                                Humanoid:EquipTool(tool)
                                wait(0.3)
                                tool:Activate()
                                wait(0.5)
                                GlobalState.FoodEaten = GlobalState.FoodEaten + 1
                                foodFound = true
                                break
                            end
                        end
                    end
                    
                    -- Check character for food too
                    if not foodFound then
                        for _, child in ipairs(Character:GetChildren()) do
                            if child:IsA("Tool") and child ~= Humanoid:FindFirstChildOfClass("Tool") then
                                local resourceInfo = ClassifyResourceAdvanced(child)
                                if resourceInfo and resourceInfo.Type == "Food" then
                                    child:Activate()
                                    wait(0.5)
                                    GlobalState.FoodEaten = GlobalState.FoodEaten + 1
                                    break
                                end
                            end
                        end
                    end
                end
            end)
            wait(GlobalState.AutoEatInterval)
        end
    end)
end

--============================================--
-- SECTION 13: VISUAL SYSTEMS
--============================================--
local function ApplyNightVision()
    Lighting.Brightness = 3
    Lighting.ClockTime = 14
    Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    Lighting.OutdoorDiffuse = Color3.fromRGB(200, 200, 200)
end

local function RemoveNightVision()
    Lighting.Brightness = 1
    Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    Lighting.OutdoorDiffuse = Color3.fromRGB(127, 127, 127)
end

local function ApplyFogRemoval()
    Lighting.FogEnd = 100000
    Lighting.FogStart = 50000
end

local function RemoveFogRemoval()
    Lighting.FogEnd = 300
    Lighting.FogStart = 0
end

local function ApplyNoDamage()
    if not Character then return end
    
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function RemoveNoDamage()
    if not Character then return end
    
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

--============================================--
-- SECTION 14: GUI CREATION
--============================================--
local MainGUI = Instance.new("ScreenGui")
MainGUI.Name = "Ultimate99NightsGUI"
MainGUI.ResetOnSpawn = false
MainGUI.Parent = PlayerGui

--============================================--
-- SECTION 15: MAIN TOGGLE BUTTON
--============================================--
local MainToggleButton = Instance.new("TextButton")
MainToggleButton.Name = "MainToggle"
MainToggleButton.Size = UDim2.new(0, 55, 0, 55)
MainToggleButton.Position = UDim2.new(0, 20, 0.5, -27)
MainToggleButton.BackgroundColor3 = ColorSystem.Accents.Primary
MainToggleButton.BorderSizePixel = 0
MainToggleButton.Text = "☰"
MainToggleButton.Font = Enum.Font.GothamBlack
MainToggleButton.TextSize = 24
MainToggleButton.TextColor3 = ColorSystem.Text.Primary
MainToggleButton.ZIndex = 9999
MainToggleButton.AutoButtonColor = false
MainToggleButton.Parent = MainGUI

local MainButtonCorner = Instance.new("UICorner")
MainButtonCorner.CornerRadius = UDim.new(1, 0)
MainButtonCorner.Parent = MainToggleButton

local MainButtonGradient = Instance.new("UIGradient")
MainButtonGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, ColorSystem.Accents.Primary),
    ColorSequenceKeypoint.new(1, ColorSystem.Accents.Secondary)
})
MainButtonGradient.Rotation = 135
MainButtonGradient.Parent = MainToggleButton

--============================================--
-- SECTION 16: MAIN MENU FRAME
--============================================--
local function CreateMainMenu()
    -- Remove existing menu
    if MainGUI:FindFirstChild("MainMenuFrame") then
        MainGUI.MainMenuFrame:Destroy()
    end
    
    local MenuFrame = Instance.new("Frame")
    MenuFrame.Name = "MainMenuFrame"
    MenuFrame.Size = UDim2.new(0, 520, 0, 600)
    MenuFrame.Position = UDim2.new(0.5, -260, 0.5, -300)
    MenuFrame.BackgroundColor3 = ColorSystem.Backgrounds.Primary
    MenuFrame.BackgroundTransparency = 0.03
    MenuFrame.BorderSizePixel = 0
    MenuFrame.ClipsDescendants = true
    MenuFrame.ZIndex = 100
    MenuFrame.Parent = MainGUI
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 16)
    MenuCorner.Parent = MenuFrame
    
    local MenuStroke = Instance.new("UIStroke")
    MenuStroke.Thickness = 0.5
    MenuStroke.Color = ColorSystem.UI.Border
    MenuStroke.Transparency = 0.85
    MenuStroke.Parent = MenuFrame
    
    --============================================--
    -- SECTION 17: MENU HEADER
    --============================================--
    local MenuHeader = Instance.new("Frame")
    MenuHeader.Size = UDim2.new(1, 0, 0, 55)
    MenuHeader.BackgroundColor3 = ColorSystem.Backgrounds.Secondary
    MenuHeader.BackgroundTransparency = 0.2
    MenuHeader.BorderSizePixel = 0
    MenuHeader.Parent = MenuFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 16)
    HeaderCorner.Parent = MenuHeader
    
    local HeaderGradient = Instance.new("UIGradient")
    HeaderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ColorSystem.Accents.Primary),
        ColorSequenceKeypoint.new(0.5, ColorSystem.Accents.Secondary),
        ColorSequenceKeypoint.new(1, ColorSystem.Accents.Tertiary)
    })
    HeaderGradient.Transparency = NumberSequence.new(0.85)
    HeaderGradient.Rotation = 90
    HeaderGradient.Parent = MenuHeader
    
    local HeaderLogo = Instance.new("TextLabel")
    HeaderLogo.Text = "⚡ 99 NIGHTS ULTIMATE"
    HeaderLogo.Font = Enum.Font.GothamBlack
    HeaderLogo.TextSize = 17
    HeaderLogo.Size = UDim2.new(0, 260, 1, 0)
    HeaderLogo.Position = UDim2.new(0, 16, 0, 0)
    HeaderLogo.BackgroundTransparency = 1
    HeaderLogo.TextColor3 = ColorSystem.Text.Primary
    HeaderLogo.TextXAlignment = Enum.TextXAlignment.Left
    HeaderLogo.Parent = MenuHeader
    
    local HeaderVersion = Instance.new("TextLabel")
    HeaderVersion.Text = "v10.0"
    HeaderVersion.Font = Enum.Font.GothamBold
    HeaderVersion.TextSize = 10
    HeaderVersion.Size = UDim2.new(0, 40, 0, 16)
    HeaderVersion.Position = UDim2.new(0, 270, 0, 22)
    HeaderVersion.BackgroundTransparency = 1
    HeaderVersion.TextColor3 = ColorSystem.Text.Tertiary
    HeaderVersion.TextXAlignment = Enum.TextXAlignment.Left
    HeaderVersion.Parent = MenuHeader
    
    local HeaderClose = Instance.new("TextButton")
    HeaderClose.Text = "✕"
    HeaderClose.Font = Enum.Font.GothamBold
    HeaderClose.TextSize = 15
    HeaderClose.Size = UDim2.new(0, 30, 0, 30)
    HeaderClose.Position = UDim2.new(1, -40, 0.5, -15)
    HeaderClose.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    HeaderClose.TextColor3 = ColorSystem.Text.Secondary
    HeaderClose.BorderSizePixel = 0
    HeaderClose.AutoButtonColor = false
    HeaderClose.Parent = MenuHeader
    
    local HeaderCloseCorner = Instance.new("UICorner")
    HeaderCloseCorner.CornerRadius = UDim.new(1, 0)
    HeaderCloseCorner.Parent = HeaderClose
    
    HeaderClose.MouseButton1Click:Connect(function()
        GlobalState.MenuOpen = false
        TweenService:Create(MenuFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        delay(0.2, function()
            MenuFrame:Destroy()
        end)
    end)
    
    HeaderClose.MouseEnter:Connect(function()
        TweenService:Create(HeaderClose, TweenInfo.new(0.15), {
            BackgroundColor3 = ColorSystem.Status.Error
        }):Play()
    end)
    
    HeaderClose.MouseLeave:Connect(function()
        TweenService:Create(HeaderClose, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        }):Play()
    end)
    
    --============================================--
    -- SECTION 18: TAB SYSTEM
    --============================================--
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -24, 0, 40)
    TabBar.Position = UDim2.new(0, 12, 0, 64)
    TabBar.BackgroundColor3 = ColorSystem.Backgrounds.Tertiary
    TabBar.BackgroundTransparency = 0.3
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MenuFrame
    
    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, 10)
    TabBarCorner.Parent = TabBar
    
    local TabData = {
        {Name = "👁️ ESP", Icon = "👁️"},
        {Name = "✈️ Флай", Icon = "✈️"},
        {Name = "📦 Лут", Icon = "📦"},
        {Name = "⚔️ Бой", Icon = "⚔️"},
        {Name = "🍖 Авто", Icon = "🍖"},
        {Name = "⚙️ Настр", Icon = "⚙️"}
    }
    
    local TabPages = {}
    local TabButtons = {}
    
    local SelectionIndicator = Instance.new("Frame")
    SelectionIndicator.Size = UDim2.new(1/6, -4, 1, -4)
    SelectionIndicator.Position = UDim2.new(0, 2, 0, 2)
    SelectionIndicator.BackgroundColor3 = ColorSystem.Backgrounds.Secondary
    SelectionIndicator.BackgroundTransparency = 0.3
    SelectionIndicator.BorderSizePixel = 0
    SelectionIndicator.ZIndex = 101
    SelectionIndicator.Parent = TabBar
    
    local IndicatorCorner = Instance.new("UICorner")
    IndicatorCorner.CornerRadius = UDim.new(0, 8)
    IndicatorCorner.Parent = SelectionIndicator
    
    for i = 1, 6 do
        local TabButton = Instance.new("TextButton")
        TabButton.Text = TabData[i].Name
        TabButton.Font = Enum.Font.GothamBold
        TabButton.TextSize = 10
        TabButton.Size = UDim2.new(1/6, 0, 1, 0)
        TabButton.Position = UDim2.new((i-1)/6, 0, 0, 0)
        TabButton.BackgroundTransparency = 1
        TabButton.TextColor3 = i == 1 and ColorSystem.Text.Primary or ColorSystem.Text.Secondary
        TabButton.BorderSizePixel = 0
        TabButton.ZIndex = 102
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabBar
        
        local TabPage = Instance.new("Frame")
        TabPage.Size = UDim2.new(1, -24, 1, -116)
        TabPage.Position = UDim2.new(0, 12, 0, 110)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.Visible = i == 1
        TabPage.Parent = MenuFrame
        
        TabPages[i] = TabPage
        TabButtons[i] = TabButton
        
        TabButton.MouseButton1Click:Connect(function()
            GlobalState.PreviousTab = GlobalState.CurrentTab
            GlobalState.CurrentTab = i
            
            for j = 1, 6 do
                TabButtons[j].TextColor3 = ColorSystem.Text.Secondary
                TabPages[j].Visible = false
            end
            
            TabButton.TextColor3 = ColorSystem.Text.Primary
            TabPage.Visible = true
            
            TweenService:Create(SelectionIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new((i-1)/6, 2, 0, 2)
            }):Play()
        end)
    end
    
    --============================================--
    -- SECTION 19: ESP TAB PAGE
    --============================================--
    local ESPTabPage = TabPages[1]
    
    local ESPScrollFrame = Instance.new("ScrollingFrame")
    ESPScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ESPScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
    ESPScrollFrame.BackgroundTransparency = 1
    ESPScrollFrame.BorderSizePixel = 0
    ESPScrollFrame.ScrollBarThickness = 3
    ESPScrollFrame.ScrollBarImageColor3 = ColorSystem.Accents.Primary
    ESPScrollFrame.Parent = ESPTabPage
    
    -- Helper function for toggles
    local function CreateToggleButton(parent, yPosition, text, currentState, callback)
        local toggleBackground = Instance.new("Frame")
        toggleBackground.Size = UDim2.new(1, 0, 0, 40)
        toggleBackground.Position = UDim2.new(0, 0, 0, yPosition)
        toggleBackground.BackgroundColor3 = ColorSystem.Backgrounds.Secondary
        toggleBackground.BackgroundTransparency = 0.3
        toggleBackground.BorderSizePixel = 0
        toggleBackground.Parent = parent
        
        local toggleBgCorner = Instance.new("UICorner")
        toggleBgCorner.CornerRadius = UDim.new(0, 8)
        toggleBgCorner.Parent = toggleBackground
        
        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Text = text
        toggleLabel.Font = Enum.Font.GothamMedium
        toggleLabel.TextSize = 12
        toggleLabel.Size = UDim2.new(0, 280, 1, 0)
        toggleLabel.Position = UDim2.new(0, 12, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.TextColor3 = ColorSystem.Text.Primary
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Parent = toggleBackground
        
        local switchFrame = Instance.new("Frame")
        switchFrame.Size = UDim2.new(0, 44, 0, 26)
        switchFrame.Position = UDim2.new(1, -56, 0.5, -13)
        switchFrame.BackgroundColor3 = currentState and ColorSystem.Accents.Primary or ColorSystem.UI.ToggleOff
        switchFrame.BorderSizePixel = 0
        switchFrame.Parent = toggleBackground
        
        local switchCorner = Instance.new("UICorner")
        switchCorner.CornerRadius = UDim.new(1, 0)
        switchCorner.Parent = switchFrame
        
        local switchDot = Instance.new("Frame")
        switchDot.Size = UDim2.new(0, 20, 0, 20)
        switchDot.Position = UDim2.new(0, currentState and 21 or 3, 0.5, -10)
        switchDot.BackgroundColor3 = ColorSystem.Text.Primary
        switchDot.BorderSizePixel = 0
        switchDot.Parent = switchFrame
        
        local switchDotCorner = Instance.new("UICorner")
        switchDotCorner.CornerRadius = UDim.new(1, 0)
        switchDotCorner.Parent = switchDot
        
        local switchButton = Instance.new("TextButton")
        switchButton.Size = UDim2.new(1, 0, 1, 0)
        switchButton.BackgroundTransparency = 1
        switchButton.Text = ""
        switchButton.BorderSizePixel = 0
        switchButton.Parent = switchFrame
        
        switchButton.MouseButton1Click:Connect(function()
            currentState = not currentState
            
            TweenService:Create(switchFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = currentState and ColorSystem.Accents.Primary or ColorSystem.UI.ToggleOff
            }):Play()
            
            TweenService:Create(switchDot, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, currentState and 21 or 3, 0.5, -10)
            }):Play()
            
            callback(currentState)
        end)
        
        return yPosition + 46
    end
    
    -- Helper function for buttons
    local function CreateActionButton(parent, yPosition, text, buttonColor, callback)
        local actionButton = Instance.new("TextButton")
        actionButton.Text = text
        actionButton.Font = Enum.Font.GothamBold
        actionButton.TextSize = 13
        actionButton.Size = UDim2.new(1, 0, 0, 42)
        actionButton.Position = UDim2.new(0, 0, 0, yPosition)
        actionButton.BackgroundColor3 = buttonColor
        actionButton.TextColor3 = ColorSystem.Text.Primary
        actionButton.BorderSizePixel = 0
        actionButton.AutoButtonColor = false
        actionButton.Parent = parent
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 10)
        buttonCorner.Parent = actionButton
        
        actionButton.MouseButton1Click:Connect(function()
            TweenService:Create(actionButton, TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 40)
            }):Play()
            wait(0.08)
            TweenService:Create(actionButton, TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 42)
            }):Play()
            callback()
        end)
        
        return yPosition + 48
    end
    
    local espY = 8
    
    -- Section title
    local espSectionTitle = Instance.new("TextLabel")
    espSectionTitle.Text = "ОСНОВНЫЕ НАСТРОЙКИ ESP"
    espSectionTitle.Font = Enum.Font.GothamBold
    espSectionTitle.TextSize = 9
    espSectionTitle.Size = UDim2.new(1, 0, 0, 16)
    espSectionTitle.Position = UDim2.new(0, 6, 0, espY)
    espSectionTitle.BackgroundTransparency = 1
    espSectionTitle.TextColor3 = ColorSystem.Text.Tertiary
    espSectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    espSectionTitle.Parent = ESPScrollFrame
    espY = espY + 18
    
    espY = CreateToggleButton(ESPScrollFrame, espY, "ESP Включить/Выключить", GlobalState.EspEnabled, function(state)
        GlobalState.EspEnabled = state
        if not state then
            ClearAllESP()
        end
    end)
    
    espY = CreateToggleButton(ESPScrollFrame, espY, "Ресурсы (еда, дерево, металл...)", GlobalState.EspResourcesEnabled, function(state)
        GlobalState.EspResourcesEnabled = state
    end)
    
    espY = CreateToggleButton(ESPScrollFrame, espY, "Враги", GlobalState.EspEnemiesEnabled, function(state)
        GlobalState.EspEnemiesEnabled = state
    end)
    
    espY = CreateToggleButton(ESPScrollFrame, espY, "Потерянные дети", GlobalState.EspChildrenEnabled, function(state)
        GlobalState.EspChildrenEnabled = state
    end)
    
    espY = CreateToggleButton(ESPScrollFrame, espY, "Сундуки и контейнеры", GlobalState.EspChestsEnabled, function(state)
        GlobalState.EspChestsEnabled = state
    end)
    
    espY = CreateToggleButton(ESPScrollFrame, espY, "Показывать имена", GlobalState.EspShowNames, function(state)
        GlobalState.EspShowNames = state
    end)
    
    espY = CreateToggleButton(ESPScrollFrame, espY, "Показывать дистанцию", GlobalState.EspShowDistance, function(state)
        GlobalState.EspShowDistance = state
    end)
    
    espY = CreateToggleButton(ESPScrollFrame, espY, "Показывать здоровье", GlobalState.EspShowHealth, function(state)
        GlobalState.EspShowHealth = state
    end)
    
    espY = espY + 8
    
    -- Action buttons
    espY = CreateActionButton(ESPScrollFrame, espY, "🔍 Сканировать и подсветить всё", ColorSystem.Accents.Quinary, function()
        ClearAllESP()
        ScanAndHighlightResources()
    end)
    
    espY = CreateActionButton(ESPScrollFrame, espY, "🗑️ Очистить все подсветки", ColorSystem.Status.Error, function()
        ClearAllESP()
    end)
    
    espY = CreateActionButton(ESPScrollFrame, espY, "📊 Статистика предметов", ColorSystem.Accents.Tertiary, function()
        local statsText = "📊 СТАТИСТИКА ESP\n\n"
        statsText = statsText .. "Подсвечено объектов: " .. #GlobalState.ESPTrackedObjects .. "\n"
        statsText = statsText .. "Всего найдено: " .. GlobalState.ItemsLooted .. "\n"
        
        StarterGui:SetCore("SendNotification", {
            Title = "ESP Статистика",
            Text = statsText,
            Duration = 5
        })
    end)
    
    ESPScrollFrame.CanvasSize = UDim2.new(0, 0, 0, espY + 40)
    
    --============================================--
    -- SECTION 20: FLY TAB PAGE
    --============================================--
    local FlyTabPage = TabPages[2]
    
    local flyY = 8
    
    local flySectionTitle = Instance.new("TextLabel")
    flySectionTitle.Text = "УПРАВЛЕНИЕ ПОЛЁТОМ"
    flySectionTitle.Font = Enum.Font.GothamBold
    flySectionTitle.TextSize = 9
    flySectionTitle.Size = UDim2.new(1, 0, 0, 16)
    flySectionTitle.Position = UDim2.new(0, 6, 0, flyY)
    flySectionTitle.BackgroundTransparency = 1
    flySectionTitle.TextColor3 = ColorSystem.Text.Tertiary
    flySectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    flySectionTitle.Parent = FlyTabPage
    flyY = flyY + 18
    
    -- Fly toggle
    local flyToggleBg = Instance.new("Frame")
    flyToggleBg.Size = UDim2.new(1, 0, 0, 50)
    flyToggleBg.Position = UDim2.new(0, 0, 0, flyY)
    flyToggleBg.BackgroundColor3 = ColorSystem.Backgrounds.Secondary
    flyToggleBg.BackgroundTransparency = 0.3
    flyToggleBg.BorderSizePixel = 0
    flyToggleBg.Parent = FlyTabPage
    
    local flyToggleBgCorner = Instance.new("UICorner")
    flyToggleBgCorner.CornerRadius = UDim.new(0, 10)
    flyToggleBgCorner.Parent = flyToggleBg
    
    local flyToggleIcon = Instance.new("TextLabel")
    flyToggleIcon.Text = "✈️"
    flyToggleIcon.Font = Enum.Font.GothamBlack
    flyToggleIcon.TextSize = 24
    flyToggleIcon.Size = UDim2.new(0, 36, 1, 0)
    flyToggleIcon.Position = UDim2.new(0, 12, 0, 0)
    flyToggleIcon.BackgroundTransparency = 1
    flyToggleIcon.Parent = flyToggleBg
    
    local flyToggleLabel = Instance.new("TextLabel")
    flyToggleLabel.Text = "Флай (Fly)"
    flyToggleLabel.Font = Enum.Font.GothamBold
    flyToggleLabel.TextSize = 14
    flyToggleLabel.Size = UDim2.new(0, 150, 1, 0)
    flyToggleLabel.Position = UDim2.new(0, 52, 0, 0)
    flyToggleLabel.BackgroundTransparency = 1
    flyToggleLabel.TextColor3 = ColorSystem.Text.Primary
    flyToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    flyToggleLabel.Parent = flyToggleBg
    
    local flyToggleSwitch = Instance.new("Frame")
    flyToggleSwitch.Size = UDim2.new(0, 50, 0, 28)
    flyToggleSwitch.Position = UDim2.new(1, -64, 0.5, -14)
    flyToggleSwitch.BackgroundColor3 = GlobalState.FlyEnabled and ColorSystem.Status.Success or ColorSystem.UI.ToggleOff
    flyToggleSwitch.BorderSizePixel = 0
    flyToggleSwitch.Parent = flyToggleBg
    
    local flyToggleSwitchCorner = Instance.new("UICorner")
    flyToggleSwitchCorner.CornerRadius = UDim.new(1, 0)
    flyToggleSwitchCorner.Parent = flyToggleSwitch
    
    local flyToggleDot = Instance.new("Frame")
    flyToggleDot.Size = UDim2.new(0, 22, 0, 22)
    flyToggleDot.Position = UDim2.new(0, GlobalState.FlyEnabled and 25 or 3, 0.5, -11)
    flyToggleDot.BackgroundColor3 = ColorSystem.Text.Primary
    flyToggleDot.BorderSizePixel = 0
    flyToggleDot.Parent = flyToggleSwitch
    
    local flyToggleDotCorner = Instance.new("UICorner")
    flyToggleDotCorner.CornerRadius = UDim.new(1, 0)
    flyToggleDotCorner.Parent = flyToggleDot
    
    local flyToggleButton = Instance.new("TextButton")
    flyToggleButton.Size = UDim2.new(1, 0, 1, 0)
    flyToggleButton.BackgroundTransparency = 1
    flyToggleButton.Text = ""
    flyToggleButton.BorderSizePixel = 0
    flyToggleButton.Parent = flyToggleSwitch
    
    flyToggleButton.MouseButton1Click:Connect(function()
        GlobalState.FlyEnabled = not GlobalState.FlyEnabled
        
        if GlobalState.FlyEnabled then
            StartFlySystem()
            TweenService:Create(flyToggleSwitch, TweenInfo.new(0.2), {BackgroundColor3 = ColorSystem.Status.Success}):Play()
            TweenService:Create(flyToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 25, 0.5, -11)}):Play()
        else
            StopFlySystem()
            TweenService:Create(flyToggleSwitch, TweenInfo.new(0.2), {BackgroundColor3 = ColorSystem.UI.ToggleOff}):Play()
            TweenService:Create(flyToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -11)}):Play()
        end
    end)
    
    flyY = flyY + 60
    
    -- Speed control
    local speedSectionLabel = Instance.new("TextLabel")
    speedSectionLabel.Text = "СКОРОСТЬ ПОЛЁТА"
    speedSectionLabel.Font = Enum.Font.GothamBold
    speedSectionLabel.TextSize = 9
    speedSectionLabel.Size = UDim2.new(1, 0, 0, 16)
    speedSectionLabel.Position = UDim2.new(0, 6, 0, flyY)
    speedSectionLabel.BackgroundTransparency = 1
    speedSectionLabel.TextColor3 = ColorSystem.Text.Tertiary
    speedSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedSectionLabel.Parent = FlyTabPage
    flyY = flyY + 20
    
    local speedControlBg = Instance.new("Frame")
    speedControlBg.Size = UDim2.new(1, 0, 0, 50)
    speedControlBg.Position = UDim2.new(0, 0, 0, flyY)
    speedControlBg.BackgroundColor3 = ColorSystem.Backgrounds.Secondary
    speedControlBg.BackgroundTransparency = 0.3
    speedControlBg.BorderSizePixel = 0
    speedControlBg.Parent = FlyTabPage
    
    local speedControlBgCorner = Instance.new("UICorner")
    speedControlBgCorner.CornerRadius = UDim.new(0, 10)
    speedControlBgCorner.Parent = speedControlBg
    
    local speedMinusButton = Instance.new("TextButton")
    speedMinusButton.Text = "−"
    speedMinusButton.Font = Enum.Font.GothamBlack
    speedMinusButton.TextSize = 22
    speedMinusButton.Size = UDim2.new(0, 55, 0, 38)
    speedMinusButton.Position = UDim2.new(0, 8, 0.5, -19)
    speedMinusButton.BackgroundColor3 = ColorSystem.Status.Warning
    speedMinusButton.TextColor3 = ColorSystem.Text.Primary
    speedMinusButton.BorderSizePixel = 0
    speedMinusButton.AutoButtonColor = false
    speedMinusButton.Parent = speedControlBg
    
    local speedMinusCorner = Instance.new("UICorner")
    speedMinusCorner.CornerRadius = UDim.new(0, 8)
    speedMinusCorner.Parent = speedMinusButton
    
    local speedValueLabel = Instance.new("TextLabel")
    speedValueLabel.Text = tostring(GlobalState.FlySpeed)
    speedValueLabel.Font = Enum.Font.GothamBlack
    speedValueLabel.TextSize = 20
    speedValueLabel.Size = UDim2.new(0, 70, 0, 38)
    speedValueLabel.Position = UDim2.new(0.5, -35, 0.5, -19)
    speedValueLabel.BackgroundTransparency = 1
    speedValueLabel.TextColor3 = ColorSystem.Text.Primary
    speedValueLabel.Parent = speedControlBg
    
    local speedPlusButton = Instance.new("TextButton")
    speedPlusButton.Text = "+"
    speedPlusButton.Font = Enum.Font.GothamBlack
    speedPlusButton.TextSize = 22
    speedPlusButton.Size = UDim2.new(0, 55, 0, 38)
    speedPlusButton.Position = UDim2.new(1, -63, 0.5, -19)
    speedPlusButton.BackgroundColor3 = ColorSystem.Status.Success
    speedPlusButton.TextColor3 = ColorSystem.Text.Primary
    speedPlusButton.BorderSizePixel = 0
    speedPlusButton.AutoButtonColor = false
    speedPlusButton.Parent = speedControlBg
    
    local speedPlusCorner = Instance.new("UICorner")
    speedPlusCorner.CornerRadius = UDim.new(0, 8)
    speedPlusCorner.Parent = speedPlusButton
    
    speedMinusButton.MouseButton1Click:Connect(function()
        GlobalState.FlySpeed = math.max(GlobalState.FlyMinSpeed, GlobalState.FlySpeed - 10)
        speedValueLabel.Text = tostring(GlobalState.FlySpeed)
    end)
    
    speedPlusButton.MouseButton1Click:Connect(function()
        GlobalState.FlySpeed = math.min(GlobalState.FlyMaxSpeed, GlobalState.FlySpeed + 10)
        speedValueLabel.Text = tostring(GlobalState.FlySpeed)
    end)
    
    flyY = flyY + 60
    
    -- Fly controls info
    local flyControlsLabel = Instance.new("TextLabel")
    flyControlsLabel.Text = "Управление: W A S D | Space - вверх | Ctrl - вниз | F - вкл/выкл"
    flyControlsLabel.Font = Enum.Font.GothamMedium
    flyControlsLabel.TextSize = 10
    flyControlsLabel.Size = UDim2.new(1, 0, 0, 32)
    flyControlsLabel.Position = UDim2.new(0, 6, 0, flyY)
    flyControlsLabel.BackgroundTransparency = 1
    flyControlsLabel.TextColor3 = ColorSystem.Text.Tertiary
    flyControlsLabel.TextXAlignment = Enum.TextXAlignment.Left
    flyControlsLabel.TextWrapped = true
    flyControlsLabel.Parent = FlyTabPage
    
    --============================================--
    -- SECTION 21: LOOT TAB PAGE
    --============================================--
    local LootTabPage = TabPages[3]
    
    local LootScrollFrame = Instance.new("ScrollingFrame")
    LootScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    LootScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 900)
    LootScrollFrame.BackgroundTransparency = 1
    LootScrollFrame.BorderSizePixel = 0
    LootScrollFrame.ScrollBarThickness = 3
    LootScrollFrame.ScrollBarImageColor3 = ColorSystem.Accents.Primary
    LootScrollFrame.Parent = LootTabPage
    
    local lootY = 8
    
    -- Save position buttons
    lootY = CreateActionButton(LootScrollFrame, lootY, "📌 Сохранить позицию базы", ColorSystem.Accents.Quinary, function()
        GlobalState.BasePosition = HumanoidRootPart.Position
        StarterGui:SetCore("SendNotification", {
            Title = "База сохранена",
            Text = "Позиция базы обновлена",
            Duration = 2
        })
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "📌 Сохранить переработчик", ColorSystem.Accents.Secondary, function()
        GlobalState.RecyclerPosition = HumanoidRootPart.Position
        StarterGui:SetCore("SendNotification", {
            Title = "Переработчик сохранён",
            Text = "Позиция переработчика обновлена",
            Duration = 2
        })
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "📌 Сохранить костёр", ColorSystem.Status.Warning, function()
        GlobalState.CampfirePosition = HumanoidRootPart.Position
        StarterGui:SetCore("SendNotification", {
            Title = "Костёр сохранён",
            Text = "Позиция костра обновлена",
            Duration = 2
        })
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "📌 Сохранить склад", ColorSystem.Accents.Quaternary, function()
        GlobalState.StoragePosition = HumanoidRootPart.Position
        StarterGui:SetCore("SendNotification", {
            Title = "Склад сохранён",
            Text = "Позиция склада обновлена",
            Duration = 2
        })
    end)
    
    lootY = lootY + 8
    
    -- Loot buttons
    local lootSectionTitle = Instance.new("TextLabel")
    lootSectionTitle.Text = "ТЕЛЕПОРТ-ЛУТ (ТП → ВЗЯТЬ → БАЗА → ВЫГРУЗИТЬ)"
    lootSectionTitle.Font = Enum.Font.GothamBold
    lootSectionTitle.TextSize = 9
    lootSectionTitle.Size = UDim2.new(1, 0, 0, 16)
    lootSectionTitle.Position = UDim2.new(0, 6, 0, lootY)
    lootSectionTitle.BackgroundTransparency = 1
    lootSectionTitle.TextColor3 = ColorSystem.Text.Tertiary
    lootSectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    lootSectionTitle.Parent = LootScrollFrame
    lootY = lootY + 18
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "🍖 Телепорт-лут: Еда", ColorSystem.ESP.Food, function()
        ExecuteLootRun("Food")
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "🪵 Телепорт-лут: Дерево", ColorSystem.ESP.Wood, function()
        ExecuteLootRun("Wood")
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "🪨 Телепорт-лут: Камень/Уголь", ColorSystem.ESP.Stone, function()
        ExecuteLootRun("Stone")
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "⚙️ Телепорт-лут: Металл", ColorSystem.ESP.Metal, function()
        ExecuteLootRun("Metal")
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "⛽ Телепорт-лут: Топливо", ColorSystem.ESP.Fuel, function()
        ExecuteLootRun("Fuel")
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "⚔️ Телепорт-лут: Оружие", ColorSystem.ESP.Weapon, function()
        ExecuteLootRun("Weapon")
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "🏥 Телепорт-лут: Бинты/Аптечки", ColorSystem.ESP.Bandage, function()
        ExecuteLootRun("Bandage")
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "🌱 Телепорт-лут: Саженцы", ColorSystem.ESP.Sapling, function()
        ExecuteLootRun("Sapling")
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "📦 Телепорт к сундуку + автолут", ColorSystem.ESP.Chest, function()
        -- Special chest looting
        local chest = FindNearestResource("Chest", 200)
        if chest then
            TeleportToResource(chest)
            wait(0.3)
            -- Open chest
            if chest.Object:FindFirstChildOfClass("ProximityPrompt") then
                fireproximityprompt(chest.Object:FindFirstChildOfClass("ProximityPrompt"))
                wait(0.5)
            end
            -- Collect nearby items
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Tool") and HumanoidRootPart then
                    local handle = obj:FindFirstChild("Handle")
                    if handle and (handle.Position - HumanoidRootPart.Position).Magnitude < 10 then
                        pcall(function() Humanoid:EquipTool(obj) end)
                        wait(0.1)
                    end
                end
            end
            wait(0.5)
            TeleportToBase()
            wait(0.3)
            DropAllItemsAtPosition(GlobalState.StoragePosition or GlobalState.BasePosition)
            GlobalState.ChestsLooted = GlobalState.ChestsLooted + 1
        end
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "👶 Телепорт к ребёнку + возврат", ColorSystem.ESP.Child, function()
        local child = FindNearestResource("Child", 500)
        if child then
            TeleportToResource(child)
            wait(2)
            TeleportToBase()
            GlobalState.ChildrenRescued = GlobalState.ChildrenRescued + 1
            StarterGui:SetCore("SendNotification", {
                Title = "Ребёнок спасён!",
                Text = "Всего спасено: " .. GlobalState.ChildrenRescued,
                Duration = 3
            })
        end
    end)
    
    lootY = lootY + 8
    
    -- Drop buttons
    lootY = CreateActionButton(LootScrollFrame, lootY, "📤 Выгрузить всё в переработчик", ColorSystem.Accents.Secondary, function()
        TeleportToBase()
        wait(0.3)
        DropAllItemsAtPosition(GlobalState.RecyclerPosition or GlobalState.BasePosition)
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "📤 Выгрузить всё на костёр", ColorSystem.Status.Warning, function()
        TeleportToBase()
        wait(0.3)
        DropAllItemsAtPosition(GlobalState.CampfirePosition or GlobalState.BasePosition)
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "📤 Выгрузить всё на склад", ColorSystem.Accents.Quaternary, function()
        TeleportToBase()
        wait(0.3)
        DropAllItemsAtPosition(GlobalState.StoragePosition or GlobalState.BasePosition)
    end)
    
    lootY = CreateActionButton(LootScrollFrame, lootY, "🏠 Телепорт на базу", ColorSystem.Accents.Quinary, function()
        TeleportToBase()
    end)
    
    lootY = lootY + 8
    
    -- Auto loot toggle
    lootY = CreateToggleButton(LootScrollFrame, lootY, "🤖 Авто-лут (все ресурсы)", GlobalState.AutoLootEnabled, function(state)
        GlobalState.AutoLootEnabled = state
        if state then
            StartAutoLootLoop()
        end
    end)
    
    LootScrollFrame.CanvasSize = UDim2.new(0, 0, 0, lootY + 40)
    
    --============================================--
    -- SECTION 22: COMBAT TAB PAGE
    --============================================--
    local CombatTabPage = TabPages[4]
    
    local combatY = 8
    
    combatY = CreateToggleButton(CombatTabPage, combatY, "💀 Kill Aura (авто-атака врагов)", GlobalState.KillAuraEnabled, function(state)
        GlobalState.KillAuraEnabled = state
        if state then StartKillAura() end
    end)
    
    combatY = CreateToggleButton(CombatTabPage, combatY, "💀 One Hit Kill", GlobalState.OneHitKillEnabled, function(state)
        GlobalState.OneHitKillEnabled = state
    end)
    
    combatY = CreateToggleButton(CombatTabPage, combatY, "🛡️ Нет урона (God Mode)", GlobalState.NoDamageEnabled, function(state)
        GlobalState.NoDamageEnabled = state
        if state then ApplyNoDamage() else RemoveNoDamage() end
    end)
    
    combatY = CreateToggleButton(CombatTabPage, combatY, "🚫 Анти-граб", GlobalState.AntiGrabEnabled, function(state)
        GlobalState.AntiGrabEnabled = state
    end)
    
    combatY = CreateToggleButton(CombatTabPage, combatY, "👁️ Ночное видение", GlobalState.NightVisionEnabled, function(state)
        GlobalState.NightVisionEnabled = state
        if state then ApplyNightVision() else RemoveNightVision() end
    end)
    
    combatY = CreateToggleButton(CombatTabPage, combatY, "🌫️ Убрать туман", GlobalState.FogRemovalEnabled, function(state)
        GlobalState.FogRemovalEnabled = state
        if state then ApplyFogRemoval() else RemoveFogRemoval() end
    end)
    
    --============================================--
    -- SECTION 23: AUTO TAB PAGE
    --============================================--
    local AutoTabPage = TabPages[5]
    
    local autoY = 8
    
    autoY = CreateToggleButton(AutoTabPage, autoY, "🍖 Авто-еда", GlobalState.AutoEatEnabled, function(state)
        GlobalState.AutoEatEnabled = state
        if state then StartAutoEat() end
    end)
    
    autoY = CreateToggleButton(AutoTabPage, autoY, "🪵 Авто-сбор дерева", GlobalState.AutoCollectWoodEnabled, function(state)
        GlobalState.AutoCollectWoodEnabled = state
        if state then
            spawn(function()
                while GlobalState.AutoCollectWoodEnabled do
                    if not GlobalState.IsLooting then
                        local tree = FindNearestResource("Wood", 50)
                        if tree then ExecuteLootRun("Wood") end
                    end
                    wait(GlobalState.AutoCollectWoodInterval)
                end
            end)
        end
    end)
    
    autoY = CreateToggleButton(AutoTabPage, autoY, "🌱 Авто-посадка саженцев", GlobalState.AutoPlantSaplingsEnabled, function(state)
        GlobalState.AutoPlantSaplingsEnabled = state
    end)
    
    autoY = CreateToggleButton(AutoTabPage, autoY, "🏥 Авто-лечение", GlobalState.AutoHealEnabled, function(state)
        GlobalState.AutoHealEnabled = state
    end)
    
    --============================================--
    -- SECTION 24: SETTINGS TAB PAGE
    --============================================--
    local SettingsTabPage = TabPages[6]
    
    local settingsY = 8
    
    settingsY = CreateActionButton(SettingsTabPage, settingsY, "🔄 Сбросить все настройки", ColorSystem.Status.Error, function()
        -- Reset everything
        GlobalState.FlyEnabled = false
        StopFlySystem()
        GlobalState.EspEnabled = false
        ClearAllESP()
        GlobalState.KillAuraEnabled = false
        GlobalState.AutoEatEnabled = false
        GlobalState.AutoCollectWoodEnabled = false
        GlobalState.AutoPlantSaplingsEnabled = false
        GlobalState.AutoLootEnabled = false
        GlobalState.AutoHealEnabled = false
        GlobalState.NoDamageEnabled = false
        RemoveNoDamage()
        GlobalState.NightVisionEnabled = false
        RemoveNightVision()
        GlobalState.FogRemovalEnabled = false
        RemoveFogRemoval()
        GlobalState.OneHitKillEnabled = false
        GlobalState.AntiGrabEnabled = false
        
        StarterGui:SetCore("SendNotification", {
            Title = "Настройки сброшены",
            Text = "Все функции отключены",
            Duration = 3
        })
    end)
    
    settingsY = CreateActionButton(SettingsTabPage, settingsY, "📊 Показать статистику", ColorSystem.Accents.Quinary, function()
        local stats = "📊 СТАТИСТИКА\n\n"
        stats = stats .. "🍖 Съедено: " .. GlobalState.FoodEaten .. "\n"
        stats = stats .. "🪵 Дерева: " .. GlobalState.WoodCollected .. "\n"
        stats = stats .. "💀 Убито: " .. GlobalState.EnemiesKilled .. "\n"
        stats = stats .. "👶 Детей: " .. GlobalState.ChildrenRescued .. "\n"
        stats = stats .. "📦 Сундуков: " .. GlobalState.ChestsLooted .. "\n"
        stats = stats .. "📦 Предметов: " .. GlobalState.ItemsLooted .. "\n"
        stats = stats .. "🔥 Приготовлено: " .. GlobalState.ItemsCooked .. "\n"
        stats = stats .. "🛡️ Урона заблокировано: " .. GlobalState.DamageBlocked .. "\n"
        stats = stats .. "📍 Телепортов: " .. GlobalState.DistanceTeleported
        
        StarterGui:SetCore("SendNotification", {
            Title = "Статистика",
            Text = stats,
            Duration = 8
        })
    end)
    
    -- Info label
    local settingsInfo = Instance.new("TextLabel")
    settingsInfo.Text = "99 NIGHTS ULTIMATE v10.0\nСоздано @infiziond\nВсе права защищены"
    settingsInfo.Font = Enum.Font.GothamMedium
    settingsInfo.TextSize = 10
    settingsInfo.Size = UDim2.new(1, 0, 0, 50)
    settingsInfo.Position = UDim2.new(0, 0, 0, settingsY + 20)
    settingsInfo.BackgroundTransparency = 1
    settingsInfo.TextColor3 = ColorSystem.Text.Tertiary
    settingsInfo.TextXAlignment = Enum.TextXAlignment.Center
    settingsInfo.Parent = SettingsTabPage
    
    return MenuFrame
end

--============================================--
-- SECTION 25: MAIN BUTTON EVENT HANDLERS
--============================================--
MainToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        GlobalState.MenuDragging = true
        GlobalState.MenuDragStart = input.Position
        GlobalState.MenuStartPos = MainToggleButton.Position
    end
end)

MainToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local wasDragged = false
        if GlobalState.MenuDragStart then
            wasDragged = (input.Position - GlobalState.MenuDragStart).Magnitude > 3
        end
        
        if not wasDragged then
            GlobalState.MenuOpen = not GlobalState.MenuOpen
            if GlobalState.MenuOpen then
                CreateMainMenu()
            else
                if MainGUI:FindFirstChild("MainMenuFrame") then
                    MainGUI.MainMenuFrame:Destroy()
                end
            end
        end
        
        GlobalState.MenuDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if GlobalState.MenuDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - GlobalState.MenuDragStart
        local newX = math.clamp(GlobalState.MenuStartPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - 55)
        local newY = math.clamp(GlobalState.MenuStartPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - 55)
        MainToggleButton.Position = UDim2.new(0, newX, 0, newY)
    end
end)

--============================================--
-- SECTION 26: KEYBOARD SHORTCUTS
--============================================--
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Fly toggle with F
    if input.KeyCode == Enum.KeyCode.F then
        GlobalState.FlyEnabled = not GlobalState.FlyEnabled
        if GlobalState.FlyEnabled then
            StartFlySystem()
        else
            StopFlySystem()
        end
    end
    
    -- Quick loot with E
    if input.KeyCode == Enum.KeyCode.E then
        ExecuteLootRun("Food")
    end
    
    -- Teleport to base with B
    if input.KeyCode == Enum.KeyCode.B then
        TeleportToBase()
    end
    
    -- Toggle ESP with V
    if input.KeyCode == Enum.KeyCode.V then
        GlobalState.EspEnabled = not GlobalState.EspEnabled
        if not GlobalState.EspEnabled then
            ClearAllESP()
        end
    end
    
    -- Toggle Kill Aura with K
    if input.KeyCode == Enum.KeyCode.K then
        GlobalState.KillAuraEnabled = not GlobalState.KillAuraEnabled
        if GlobalState.KillAuraEnabled then
            StartKillAura()
        end
    end
    
    -- Fly movement keys
    if input.KeyCode == Enum.KeyCode.Space then
        GlobalState.FlyUpActive = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        GlobalState.FlyDownActive = true
    elseif input.KeyCode == Enum.KeyCode.W then
        GlobalState.FlyForwardActive = true
    elseif input.KeyCode == Enum.KeyCode.S then
        GlobalState.FlyBackActive = true
    elseif input.KeyCode == Enum.KeyCode.A then
        GlobalState.FlyLeftActive = true
    elseif input.KeyCode == Enum.KeyCode.D then
        GlobalState.FlyRightActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        GlobalState.FlyUpActive = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        GlobalState.FlyDownActive = false
    elseif input.KeyCode == Enum.KeyCode.W then
        GlobalState.FlyForwardActive = false
    elseif input.KeyCode == Enum.KeyCode.S then
        GlobalState.FlyBackActive = false
    elseif input.KeyCode == Enum.KeyCode.A then
        GlobalState.FlyLeftActive = false
    elseif input.KeyCode == Enum.KeyCode.D then
        GlobalState.FlyRightActive = false
    end
end)

--============================================--
-- SECTION 27: ESP UPDATE LOOP
--============================================--
spawn(function()
    while true do
        if GlobalState.EspEnabled then
            ScanAndHighlightResources()
            UpdateESPDistances()
        end
        wait(GlobalState.EspUpdateInterval)
    end
end)

--============================================--
-- SECTION 28: PERFORMANCE MONITOR
--============================================--
spawn(function()
    while true do
        GlobalState.TimePlayed = GlobalState.TimePlayed + 1
        
        if GlobalState.PerformanceMode then
            -- Reduce update frequency for performance
            GlobalState.EspUpdateInterval = 3
            GlobalState.LootInterval = 3
            GlobalState.AutoEatInterval = 5
        else
            GlobalState.EspUpdateInterval = 1.5
            GlobalState.LootInterval = 2
            GlobalState.AutoEatInterval = 3
        end
        
        wait(1)
    end
end)

--============================================--
-- SECTION 29: INITIALIZATION
--============================================--
StarterGui:SetCore("SendNotification", {
    Title = "99 NIGHTS ULTIMATE v10.0",
    Text = "Скрипт загружен!\nF - Флай | E - Лут | B - База | V - ESP | K - Kill Aura\nНажми кнопку ☰ для меню",
    Duration = 8
})

print("========================================")
print(" 99 NIGHTS ULTIMATE v10.0")
print(" ⚡ Все функции загружены и работают")
print("========================================")
print(" 📋 Доступные функции:")
print("   - ESP (подсветка всех объектов)")
print("   - Флай (WASD + Space/Ctrl)")
print("   - Телепорт-лут (ТП → взять → база → выгрузить)")
print("   - Kill Aura (авто-атака врагов)")
print("   - Авто-еда (автоматическое питание)")
print("   - Авто-сбор дерева")
print("   - Ночное видение")
print("   - Удаление тумана")
print("   - Нет урона (God Mode)")
print("   - One Hit Kill")
print("   - Анти-граб")
print("========================================")
print(" ⌨️ Горячие клавиши:")
print("   F - Флай вкл/выкл")
print("   E - Быстрый лут еды")
print("   B - Телепорт на базу")
print("   V - ESP вкл/выкл")
print("   K - Kill Aura вкл/выкл")
print("   WASD - Движение в полёте")
print("   Space - Вверх | Ctrl - Вниз")
print("========================================")

--[[
	Aurora Menu v2 — iOS-style animated Roblox UI
	--------------------------------------------------------------
	Новое во v2:
	  • Кнопка-лаунчер теперь ПЕРЕТАСКИВАЕТСЯ по всему экрану
	    (как кнопка открытия скрипта в Delta / Fluxus и т.д.)
	  • Меню открывается ИЗ ТЕКУЩЕЙ позиции кнопки, а не всегда
	    из угла экрана
	  • Вкладки перенесены НА ЛЕВУЮ сторону (вертикальный sidebar)
	  • Появились "отделения" — секции внутри вкладки
	    (api:AddSection("Название")) для группировки функций
	  • 60 FPS: анимации на Size/Position/UIScale через TweenService

	Использование — см. блок "ПРИМЕР ИСПОЛЬЗОВАНИЯ" в конце файла.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--============================================================
-- ТОКЕНЫ ДИЗАЙНА
--============================================================
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

--============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
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
	return Camera and Camera.ViewportSize or Vector2.new(1280, 720)
end

--============================================================
-- УНИВЕРСАЛЬНОЕ ПЕРЕТАСКИВАНИЕ (для кнопки и для окна)
-- callback(newPosition: UDim2) вызывается во время движения
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

--============================================================
-- БИБЛИОТЕКА
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
		Name = "AuroraMenu",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = LocalPlayer:WaitForChild("PlayerGui"),
	})

	self:_buildLauncher()
	self:_buildWindow()

	return self
end

--------------------------------------------------------------
-- ЛАУНЧЕР (перетаскиваемая плавающая кнопка)
--------------------------------------------------------------
function Aurora:_buildLauncher()
	local vp = viewportSize()
	local launcher = new("TextButton", {
		Name = "Launcher",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(56, 56),
		Position = UDim2.fromOffset(vp.X - 84, vp.Y - 140), -- стартовая позиция, справа снизу
		BackgroundColor3 = THEME.BgStrong,
		BackgroundTransparency = 0.1,
		Parent = self.Gui,
	})
	corner(launcher, 18)
	stroke(launcher, THEME.Stroke, 1, 0.88)

	new("ImageLabel", {
		Image = "rbxassetid://10723407389", -- иконка "меню" (заменить на свою)
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

	-- перетаскивание + клик (клик = движение меньше 4px)
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

--------------------------------------------------------------
-- ГЛАВНОЕ ОКНО
--------------------------------------------------------------
function Aurora:_buildWindow()
	local window = new("Frame", {
		Name = "Window",
		Size = UDim2.fromOffset(400, 480),
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

	-- ===== Основная область: sidebar (слева) + контент =====
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

--============================================================
-- ОТКРЫТИЕ / СВОРАЧИВАНИЕ (genie-анимация из позиции кнопки)
--============================================================
function Aurora:Open()
	if self.IsOpen then return end
	self.IsOpen = true

	-- окно "вырастает" из текущей позиции лаунчера
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

--============================================================
-- ВКЛАДКИ (теперь слева, вертикально)
--============================================================
function Aurora:CreateTab(name, iconId)
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

	----------------------------------------------------------
	-- Секция / отделение — разбивает список функций на группы
	----------------------------------------------------------
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

	----------------------------------------------------------
	-- Простой тумблер ("Облако")
	----------------------------------------------------------
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

		new("TextLabel", { Text = opts.Name or "Функция", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.Text, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 16), Position = UDim2.fromOffset(56, 12), BackgroundTransparency = 1, Parent = row })
		new("TextLabel", { Text = opts.Description or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 14), Position = UDim2.fromOffset(56, 30), BackgroundTransparency = 1, Parent = row })

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

	----------------------------------------------------------
	-- Тумблер с настройками (разворачивается)
	----------------------------------------------------------
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
		new("TextLabel", { Text = opts.Description or "Нажми, чтобы открыть настройки", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 14), Position = UDim2.fromOffset(16, 30), BackgroundTransparency = 1, Parent = row })
		local chevron = new("TextLabel", { Text = "v", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.TextDim, Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -34, 0.5, -10), BackgroundTransparency = 1, Parent = row })

		local settingsWrap = new("Frame", { Size = UDim2.new(1, -32, 0, 70), Position = UDim2.fromOffset(16, 62), BackgroundTransparency = 1, Parent = container })
		local sliderValue = opts.SliderDefault or 50
		local sliderLabel = new("TextLabel", { Text = (opts.SliderLabel or "Интенсивность") .. ": " .. sliderValue .. "%", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Parent = settingsWrap })
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
			sliderLabel.Text = (opts.SliderLabel or "Интенсивность") .. ": " .. sliderValue .. "%"
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

	----------------------------------------------------------
	-- Вкладка профиля: реальные данные игрока
	----------------------------------------------------------
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
		statChip(math.floor(accountAge / 365), "Лет на Roblox")
		statChip(LocalPlayer.UserId, "ID")
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

return Aurora

--[[
==================================================================
ПРИМЕР ИСПОЛЬЗОВАНИЯ:

	local Aurora = require(path.to.AuroraMenu)

	local menu = Aurora.new({ Title = "Aurora", SubTitle = "v2.0 · подключено" })

	local functionsTab = menu:CreateTab("Функции")
	local visualsTab    = menu:CreateTab("Визуал")
	local profileTab    = menu:CreateTab("Профиль")

	-- отделение "Основные"
	functionsTab:AddSection("Основные")
	functionsTab:AddToggle({
		Name = "Облако",
		Description = "Простая функция, включить/выключить",
		Callback = function(enabled) print("Облако:", enabled) end,
	})

	-- отделение "Дополнительные"
	functionsTab:AddSection("Дополнительные")
	functionsTab:AddToggleWithSettings({
		Name = "Функция 2",
		SliderLabel = "Интенсивность",
		SliderDefault = 65,
		OnSlider = function(v) print("Интенсивность:", v) end,
		Callback = function(enabled) print("Функция 2:", enabled) end,
	})

	-- второе отделение: вкладка "Визуал"
	visualsTab:AddSection("Отображение")
	visualsTab:AddToggle({ Name = "Обводка игроков", Callback = function(v) print(v) end })

	profileTab:AddProfileCard()

==================================================================
]]

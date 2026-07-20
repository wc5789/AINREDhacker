local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Windows = {}

-- 默认复古字体：Fixedsys (极其经典的 Win98 像素字体)
local RETRO_FONT = Enum.Font.Fixedsys
local RETRO_FONT_BOLD = Enum.Font.SourceSansBold -- 标题栏或加粗用，更清晰易读

-- =============================================================================
-- 辅助函数：Win98 经典 3D 凸起/凹陷边框
-- =============================================================================
local function add3DBorder(parent, isInset)
	local border = Instance.new("Frame")
	border.Name = "3DBorder"
	border.Size = UDim2.new(1, 0, 1, 0)
	border.BackgroundTransparency = 1
	border.BorderSizePixel = 0
	border.ZIndex = parent.ZIndex + 1
	border.Parent = parent

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 1)
	top.Position = UDim2.new(0, 0, 0, 0)
	top.BorderSizePixel = 0
	top.Parent = border

	local left = Instance.new("Frame")
	left.Size = UDim2.new(0, 1, 1, 0)
	left.Position = UDim2.new(0, 0, 0, 0)
	left.BorderSizePixel = 0
	left.Parent = border

	local bottom = Instance.new("Frame")
	bottom.Size = UDim2.new(1, 0, 0, 1)
	bottom.Position = UDim2.new(0, 0, 1, -1)
	bottom.BorderSizePixel = 0
	bottom.Parent = border

	local right = Instance.new("Frame")
	right.Size = UDim2.new(0, 1, 1, 0)
	right.Position = UDim2.new(1, -1, 0, 0)
	right.BorderSizePixel = 0
	right.Parent = border

	local white = Color3.fromRGB(255, 255, 255)
	local darkGray = Color3.fromRGB(128, 128, 128)

	local function setStyle(inset)
		if inset then
			top.BackgroundColor3 = darkGray
			left.BackgroundColor3 = darkGray
			bottom.BackgroundColor3 = white
			right.BackgroundColor3 = white
		else
			top.BackgroundColor3 = white
			left.BackgroundColor3 = white
			bottom.BackgroundColor3 = darkGray
			right.BackgroundColor3 = darkGray
		end
	end

	setStyle(isInset)
	return setStyle
end

-- =============================================================================
-- 辅助函数：自定义拖动
-- =============================================================================
local function makeDraggable(frame, dragHandle)
	dragHandle = dragHandle or frame
	local dragging, dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- =============================================================================
-- 核心组件渲染：支持各种原子组件
-- =============================================================================
local function createSingleElement(el, parent, layoutOrder)
	if el.type == "section" then
		local section = Instance.new("TextLabel")
		section.Size = UDim2.new(0.95, 0, 0, 20)
		section.BackgroundColor3 = Color3.fromRGB(0, 0, 128)
		section.BorderSizePixel = 0
		section.Text = "  " .. el.text
		section.Font = RETRO_FONT_BOLD
		section.TextColor3 = Color3.fromRGB(255, 255, 255)
		section.TextSize = 13
		section.TextXAlignment = Enum.TextXAlignment.Left
		section.LayoutOrder = layoutOrder
		section.Parent = parent
		return section

	elseif el.type == "button" then
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.95, 0, 0, 28)
		btn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
		btn.BorderSizePixel = 0
		btn.Text = el.text or "Button"
		btn.Font = RETRO_FONT
		btn.TextColor3 = Color3.fromRGB(0, 0, 0)
		btn.TextSize = 14
		btn.AutoButtonColor = false
		btn.LayoutOrder = layoutOrder
		btn.Parent = parent

		local updateBtnBorder = add3DBorder(btn, false)

		btn.MouseButton1Down:Connect(function() updateBtnBorder(true) end)
		btn.MouseButton1Up:Connect(function()
			updateBtnBorder(false)
			if el.callback then el.callback() end
		end)
		return btn

	elseif el.type == "toggle" then
		local toggleFrame = Instance.new("Frame")
		toggleFrame.Size = UDim2.new(0.95, 0, 0, 20)
		toggleFrame.BackgroundTransparency = 1
		toggleFrame.LayoutOrder = layoutOrder
		toggleFrame.Parent = parent

		local checkbox = Instance.new("Frame")
		checkbox.Size = UDim2.new(0, 13, 0, 13)
		checkbox.Position = UDim2.new(0, 4, 0.5, -6)
		checkbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		checkbox.BorderSizePixel = 0
		checkbox.Parent = toggleFrame
		add3DBorder(checkbox, true)

		local checkMark = Instance.new("TextLabel")
		checkMark.Size = UDim2.new(1, 0, 1, 0)
		checkMark.BackgroundTransparency = 1
		checkMark.Text = "✓"
		checkMark.TextColor3 = Color3.fromRGB(0, 0, 0)
		checkMark.Font = RETRO_FONT_BOLD
		checkMark.TextSize = 12
		checkMark.Visible = el.default or false
		checkMark.Parent = checkbox

		local label = Instance.new("TextButton")
		label.Size = UDim2.new(1, -22, 1, 0)
		label.Position = UDim2.new(0, 22, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = el.text or "Checkbox"
		label.Font = RETRO_FONT
		label.TextColor3 = Color3.fromRGB(0, 0, 0)
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = toggleFrame

		local isChecked = el.default or false
		local function toggle()
			isChecked = not isChecked
			checkMark.Visible = isChecked
			if el.callback then el.callback(isChecked) end
		end

		label.MouseButton1Click:Connect(toggle)
		local innerClick = Instance.new("TextButton")
		innerClick.Size = UDim2.new(1, 0, 1, 0)
		innerClick.BackgroundTransparency = 1
		innerClick.Text = ""
		innerClick.Parent = checkbox
		innerClick.MouseButton1Click:Connect(toggle)
		return toggleFrame

	elseif el.type == "slider" then
		local sliderFrame = Instance.new("Frame")
		sliderFrame.Size = UDim2.new(0.95, 0, 0, 36)
		sliderFrame.BackgroundTransparency = 1
		sliderFrame.LayoutOrder = layoutOrder
		sliderFrame.Parent = parent

		local minVal = el.min or 0
		local maxVal = el.max or 100
		local currentVal = el.default or minVal

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 14)
		label.BackgroundTransparency = 1
		label.Text = (el.text or "Slider") .. ": " .. tostring(currentVal)
		label.Font = RETRO_FONT
		label.TextColor3 = Color3.fromRGB(0, 0, 0)
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = sliderFrame

		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, -12, 0, 4)
		track.Position = UDim2.new(0, 6, 0, 22)
		track.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
		track.BorderSizePixel = 0
		track.Parent = sliderFrame
		add3DBorder(track, true)

		local thumb = Instance.new("TextButton")
		thumb.Size = UDim2.new(0, 10, 0, 16)
		thumb.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
		thumb.BorderSizePixel = 0
		thumb.Text = ""
		thumb.Parent = track
		local updateThumbBorder = add3DBorder(thumb, false)

		local percent = (currentVal - minVal) / (maxVal - minVal)
		thumb.Position = UDim2.new(percent, -5, 0.5, -8)

		local isDragging = false
		local function updateSlider(input)
			local trackWidth = track.AbsoluteSize.X
			local relativeX = input.Position.X - track.AbsolutePosition.X
			local percentage = math.clamp(relativeX / trackWidth, 0, 1)
			thumb.Position = UDim2.new(percentage, -5, 0.5, -8)
			local exactValue = minVal + percentage * (maxVal - minVal)
			currentVal = el.precise and (math.round(exactValue * 100) / 100) or math.round(exactValue)
			label.Text = (el.text or "Slider") .. ": " .. tostring(currentVal)
			if el.callback then el.callback(currentVal) end
		end

		thumb.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				updateThumbBorder(true)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateSlider(input)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = false
				updateThumbBorder(false)
			end
		end)
		return sliderFrame

	elseif el.type == "input" then
		local inputFrame = Instance.new("Frame")
		inputFrame.Size = UDim2.new(0.95, 0, 0, 36)
		inputFrame.BackgroundTransparency = 1
		inputFrame.LayoutOrder = layoutOrder
		inputFrame.Parent = parent

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 14)
		label.BackgroundTransparency = 1
		label.Text = el.text or "Input"
		label.Font = RETRO_FONT
		label.TextColor3 = Color3.fromRGB(0, 0, 0)
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = inputFrame

		local textBox = Instance.new("TextBox")
		textBox.Size = UDim2.new(1, 0, 0, 20)
		textBox.Position = UDim2.new(0, 0, 0, 16)
		textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		textBox.BorderSizePixel = 0
		textBox.Font = RETRO_FONT
		textBox.PlaceholderText = el.placeholder or ""
		textBox.Text = ""
		textBox.TextColor3 = Color3.fromRGB(0, 0, 0)
		textBox.TextSize = 14
		textBox.ClearTextOnFocus = false
		textBox.TextXAlignment = Enum.TextXAlignment.Left
		textBox.Parent = inputFrame
		add3DBorder(textBox, true)

		local textPadding = Instance.new("UIPadding")
		textPadding.PaddingLeft = UDim.new(0, 4)
		textPadding.PaddingRight = UDim.new(0, 4)
		textPadding.Parent = textBox

		textBox.FocusLost:Connect(function()
			if el.callback then el.callback(textBox.Text) end
		end)
		return inputFrame
	end
end

-- =============================================================================
-- 主创建函数 (支持 Width, Height 横向和纵向自定义配置)
-- =============================================================================
function Windows.Create(config)
	local windowTitle = config.Title or "Windows 98"
	local toggleText = config.ToggleText or "Start"
	
	-- 横向扩展配置：支持 Width (默认 260) 和 Height (默认 340)
	local winWidth = config.Width or 260
	local winHeight = config.Height or 340

	local tabsConfig = config.Tabs or {{ Name = "Default", Elements = {} }}

	local Main = Instance.new("ScreenGui")
	Main.Name = "Windows98_GUI"
	Main.Parent = game.CoreGui
	Main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	--桌面 Start 按钮
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Parent = Main
	ToggleBtn.Size = UDim2.new(0, 100, 0, 32)
	ToggleBtn.Position = UDim2.new(0.02, 0, 0.02, 0)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	ToggleBtn.BorderSizePixel = 0
	ToggleBtn.Text = "  " .. toggleText
	ToggleBtn.Font = RETRO_FONT_BOLD
	ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	ToggleBtn.TextSize = 14
	ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
	ToggleBtn.AutoButtonColor = false
	makeDraggable(ToggleBtn)

	local updateStartBorder = add3DBorder(ToggleBtn, false)
	ToggleBtn.MouseButton1Down:Connect(function() updateStartBorder(true) end)
	ToggleBtn.MouseButton1Up:Connect(function() updateStartBorder(false) end)

	--主窗口框架
	local MainGui = Instance.new("Frame")
	MainGui.Parent = Main
	MainGui.Size = UDim2.new(0, winWidth, 0, winHeight)
	MainGui.Position = UDim2.new(0.3, 0, 0.2, 0)
	MainGui.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	MainGui.BorderSizePixel = 0
	MainGui.Visible = false
	add3DBorder(MainGui, false)

	--标题栏
	local TitleBar = Instance.new("Frame")
	TitleBar.Parent = MainGui
	TitleBar.Size = UDim2.new(1, -6, 0, 22)
	TitleBar.Position = UDim2.new(0, 3, 0, 3)
	TitleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TitleBar.BorderSizePixel = 0

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 128)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 132, 208))
	})
	titleGradient.Parent = TitleBar

	local TitleText = Instance.new("TextLabel")
	TitleText.Parent = TitleBar
	TitleText.BackgroundTransparency = 1
	TitleText.Size = UDim2.new(1, -26, 1, 0)
	TitleText.Position = UDim2.new(0, 4, 0, 0)
	TitleText.Font = RETRO_FONT_BOLD
	TitleText.Text = windowTitle
	TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleText.TextSize = 14
	TitleText.TextXAlignment = Enum.TextXAlignment.Left

	--关闭按钮
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Parent = TitleBar
	CloseBtn.Size = UDim2.new(0, 16, 0, 14)
	CloseBtn.Position = UDim2.new(1, -18, 0.5, -7)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	CloseBtn.BorderSizePixel = 0
	CloseBtn.Text = "X"
	CloseBtn.Font = RETRO_FONT_BOLD
	CloseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	CloseBtn.TextSize = 10
	CloseBtn.AutoButtonColor = false
	local updateCloseBorder = add3DBorder(CloseBtn, false)
	CloseBtn.MouseButton1Down:Connect(function() updateCloseBorder(true) end)
	CloseBtn.MouseButton1Up:Connect(function() updateCloseBorder(false) end)

	makeDraggable(MainGui, TitleBar)

	--标签按钮栏
	local TabBar = Instance.new("Frame")
	TabBar.Parent = MainGui
	TabBar.Size = UDim2.new(1, -8, 0, 24)
	TabBar.Position = UDim2.new(0, 4, 0, 28)
	TabBar.BackgroundTransparency = 1

	local TabList = Instance.new("UIListLayout")
	TabList.Parent = TabBar
	TabList.FillDirection = Enum.FillDirection.Horizontal
	TabList.SortOrder = Enum.SortOrder.LayoutOrder
	TabList.Padding = UDim.new(0, 2)

	--内容主容器
	local Container = Instance.new("Frame")
	Container.Parent = MainGui
	Container.Position = UDim2.new(0, 4, 0, 52)
	Container.Size = UDim2.new(1, -8, 1, -56)
	Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Container.BorderSizePixel = 0
	add3DBorder(Container, true)

	local tabFrames = {}
	local activeTab = nil

	-- =============================================================================
	-- 支持横向/多列排版的渲染核心
	-- =============================================================================
	local function renderTabContent(tabConfig, parentFrame)
		local elements = tabConfig.Elements or {}

		local ScrollingFrame = Instance.new("ScrollingFrame")
		ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
		ScrollingFrame.BackgroundTransparency = 1
		ScrollingFrame.BorderSizePixel = 0
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ScrollingFrame.ScrollBarThickness = 10
		ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(192, 192, 192)
		ScrollingFrame.Parent = parentFrame

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Parent = ScrollingFrame
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 8)
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 6)
		padding.PaddingBottom = UDim.new(0, 6)
		padding.Parent = ScrollingFrame

		for i, el in ipairs(elements) do
			if el.type == "row" then
				-- 行排版容器 (支持横向排列多个组件)
				local rowFrame = Instance.new("Frame")
				rowFrame.Size = UDim2.new(0.95, 0, 0, el.Height or 36)
				rowFrame.BackgroundTransparency = 1
				rowFrame.LayoutOrder = i
				rowFrame.Parent = ScrollingFrame

				local rowLayout = Instance.new("UIListLayout")
				rowLayout.Parent = rowFrame
				rowLayout.FillDirection = Enum.FillDirection.Horizontal
				rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
				rowLayout.Padding = UDim.new(0, 6)
				rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center

				local subElements = el.elements or {}
				local count = #subElements
				for idx, subEl in ipairs(subElements) do
					-- 自动平均分配宽度，使它们可以横向舒展
					local cellWidthScale = (1 / count) - 0.01
					local cell = Instance.new("Frame")
					cell.Size = UDim2.new(cellWidthScale, 0, 1, 0)
					cell.BackgroundTransparency = 1
					cell.LayoutOrder = idx
					cell.Parent = rowFrame

					-- 在 cell 中绘制单件
					local created = createSingleElement(subEl, cell, 1)
					if created then
						created.Size = UDim2.new(1, 0, 1, 0) -- 强制拉满格子
					end
				end
			else
				-- 正常垂直排列单组件
				createSingleElement(el, ScrollingFrame, i)
			end
		end
	end

	--构建多 Tab
	for index, tabConfig in ipairs(tabsConfig) do
		local TabContentFrame = Instance.new("Frame")
		TabContentFrame.Size = UDim2.new(1, 0, 1, 0)
		TabContentFrame.BackgroundTransparency = 1
		TabContentFrame.Visible = false
		TabContentFrame.Parent = Container

		renderTabContent(tabConfig, TabContentFrame)
		tabFrames[tabConfig.Name] = TabContentFrame

		local TabBtn = Instance.new("TextButton")
		TabBtn.Size = UDim2.new(0, 70, 1, 0)
		TabBtn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
		TabBtn.BorderSizePixel = 0
		TabBtn.Text = tabConfig.Name
		TabBtn.Font = RETRO_FONT
		TabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		TabBtn.TextSize = 13
		TabBtn.LayoutOrder = index
		TabBtn.Parent = TabBar

		local updateTabBorder = add3DBorder(TabBtn, false)

		local function selectTab()
			if activeTab then
				activeTab.ButtonUpdate(false)
				activeTab.Frame.Visible = false
			end
			TabContentFrame.Visible = true
			updateTabBorder(true)
			activeTab = {
				Frame = TabContentFrame,
				ButtonUpdate = updateTabBorder
			}
		end

		TabBtn.MouseButton1Click:Connect(selectTab)
		if index == 1 then selectTab() end
	end

	--展开/隐藏控制
	local isOpen = false
	ToggleBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			MainGui.Visible = true
			MainGui.BackgroundTransparency = 1
			TweenService:Create(MainGui, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
		else
			MainGui.Visible = false
		end
	end)

	CloseBtn.MouseButton1Click:Connect(function()
		MainGui.Visible = false
		isOpen = false
	end)

	return {
		Toggle = ToggleBtn,
		Window = MainGui,
		SetToggleText = function(newText)
			ToggleBtn.Text = "  " .. newText
		end
	}
end

-- =============================================================================
-- 新增方法：Windows.ShowPopup (完美的经典 Win98 系统提示/报错弹窗)
-- =============================================================================
function Windows.ShowPopup(config)
	local title = config.Title or "System Message"
	local message = config.Message or "An error has occurred."
	local iconType = config.IconType or "error" -- options: "error", "warning", "info"
	local buttons = config.Buttons or {"OK"} -- 例如 {"OK"}, {"Yes", "No"}, {"Retry", "Cancel"}
	local callback = config.Callback

	local Main = Instance.new("ScreenGui")
	Main.Name = "Windows98_Popup"
	Main.Parent = game.CoreGui
	Main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- 弹窗框架
	local PopupGui = Instance.new("Frame")
	PopupGui.Parent = Main
	PopupGui.Size = UDim2.new(0, 280, 0, 130)
	PopupGui.Position = UDim2.new(0.5, -140, 0.4, -65) -- 屏幕居中
	PopupGui.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	PopupGui.BorderSizePixel = 0
	add3DBorder(PopupGui, false) -- 凸起

	-- 弹窗标题
	local TitleBar = Instance.new("Frame")
	TitleBar.Parent = PopupGui
	TitleBar.Size = UDim2.new(1, -6, 0, 22)
	TitleBar.Position = UDim2.new(0, 3, 0, 3)
	TitleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 128)
	TitleBar.BorderSizePixel = 0

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 128)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 132, 208))
	})
	titleGradient.Parent = TitleBar

	local TitleText = Instance.new("TextLabel")
	TitleText.Parent = TitleBar
	TitleText.BackgroundTransparency = 1
	TitleText.Size = UDim2.new(1, -26, 1, 0)
	TitleText.Position = UDim2.new(0, 6, 0, 0)
	TitleText.Font = RETRO_FONT_BOLD
	TitleText.Text = title
	TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleText.TextSize = 14
	TitleText.TextXAlignment = Enum.TextXAlignment.Left

	-- 关闭弹窗函数
	local function closePopup()
		Main:Destroy()
	end

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Parent = TitleBar
	CloseBtn.Size = UDim2.new(0, 16, 0, 14)
	CloseBtn.Position = UDim2.new(1, -18, 0.5, -7)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	CloseBtn.BorderSizePixel = 0
	CloseBtn.Text = "X"
	CloseBtn.Font = RETRO_FONT_BOLD
	CloseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	CloseBtn.TextSize = 10
	CloseBtn.AutoButtonColor = false
	local updateCloseBorder = add3DBorder(CloseBtn, false)
	CloseBtn.MouseButton1Down:Connect(function() updateCloseBorder(true) end)
	CloseBtn.MouseButton1Up:Connect(function()
		updateCloseBorder(false)
		closePopup()
	end)

	makeDraggable(PopupGui, TitleBar)

	-- 图标绘制 (经典 Win98 像素图标拟物化)
	local IconLabel = Instance.new("TextLabel")
	IconLabel.Parent = PopupGui
	IconLabel.Size = UDim2.new(0, 32, 0, 32)
	IconLabel.Position = UDim2.new(0, 16, 0, 40)
	IconLabel.BackgroundTransparency = 1
	IconLabel.Font = Enum.Font.SourceSansBold
	IconLabel.TextSize = 24

	if iconType == "error" then
		IconLabel.Text = "×"
	elseif iconType == "warning" then
		IconLabel.Text = "!"
	elseif iconType == "info" then
		IconLabel.Text = "i"
	else
		IconLabel.Text = "√"
	end

	-- 消息内容
	local MsgText = Instance.new("TextLabel")
	MsgText.Parent = PopupGui
	MsgText.Size = UDim2.new(1, -70, 0, 45)
	MsgText.Position = UDim2.new(0, 60, 0, 35)
	MsgText.BackgroundTransparency = 1
	MsgText.Font = RETRO_FONT
	MsgText.TextColor3 = Color3.fromRGB(0, 0, 0)
	MsgText.TextSize = 14
	MsgText.TextWrapped = true
	MsgText.TextXAlignment = Enum.TextXAlignment.Left
	MsgText.TextYAlignment = Enum.TextYAlignment.Center
	MsgText.Text = message

	-- 底部按键框
	local BtnContainer = Instance.new("Frame")
	BtnContainer.Parent = PopupGui
	BtnContainer.Size = UDim2.new(1, 0, 0, 32)
	BtnContainer.Position = UDim2.new(0, 0, 1, -40)
	BtnContainer.BackgroundTransparency = 1

	local BtnLayout = Instance.new("UIListLayout")
	BtnLayout.Parent = BtnContainer
	BtnLayout.FillDirection = Enum.FillDirection.Horizontal
	BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	BtnLayout.Padding = UDim.new(0, 10)

	-- 实例化按钮
	for idx, btnText in ipairs(buttons) do
		local btn = Instance.new("TextButton")
		btn.Parent = BtnContainer
		btn.Size = UDim2.new(0, 64, 0, 24)
		btn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
		btn.BorderSizePixel = 0
		btn.Text = btnText
		btn.Font = RETRO_FONT
		btn.TextColor3 = Color3.fromRGB(0, 0, 0)
		btn.TextSize = 14
		btn.AutoButtonColor = false
		btn.LayoutOrder = idx

		local updateBtnBorder = add3DBorder(btn, false)

		btn.MouseButton1Down:Connect(function() updateBtnBorder(true) end)
		btn.MouseButton1Up:Connect(function()
			updateBtnBorder(false)
			closePopup()
			if callback then callback(btnText) end
		end)
	end
end

return Windows
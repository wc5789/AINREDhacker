local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Windows = {}

-- =============================================================================
-- 辅助函数：Win98 经典 3D 边框绘制（凸起与凹陷效果）
-- =============================================================================
local function add3DBorder(parent, isInset)
	-- isInset == true (凹陷效果，如输入框、轨道、复选框)
	-- isInset == false (凸起效果，如窗口、按钮、滑块)
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
	return setStyle -- 返回函数，允许动态修改凸起状态（如按键按下）
end

-- =============================================================================
-- 辅助函数：丝滑自定义拖拽算法（替换被废弃的 Draggable）
-- =============================================================================
local function makeDraggable(frame, dragHandle)
	dragHandle = dragHandle or frame
	local dragging
	local dragInput
	local dragStart
	local startPos

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
-- 主创建函数
-- =============================================================================
function Windows.Create(config)
	local windowTitle = config.Title or "Windows 98"
	local toggleText = config.ToggleText or "Start"
	
	-- 支持多 Tab 配置，若没有则创建默认 Tab
	local tabsConfig = config.Tabs
	if not tabsConfig then
		tabsConfig = {
			{
				Name = "Default",
				Elements = {}
			}
		}
		-- 向上兼容：如果没有 Tabs 字段，就把原先根目录下的 BUTTONS / INPUTS 放进 Default 标签中
		if config.BUTTONS then
			for _, btn in ipairs(config.BUTTONS) do
				table.insert(tabsConfig[1].Elements, btn)
			end
		end
		if config.INPUTS then
			for _, inp in ipairs(config.INPUTS) do
				table.insert(tabsConfig[1].Elements, {
					type = "input",
					text = inp.placeholder or "Input",
					placeholder = inp.placeholder,
					callback = inp.callback
				})
			end
		end
	end

	-- 主 ScreenGui
	local Main = Instance.new("ScreenGui")
	Main.Name = "Windows98_GUI"
	Main.Parent = game.CoreGui
	Main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- =============================================================================
	-- 桌面开关按钮 (拟物化 Start 按钮)
	-- =============================================================================
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Parent = Main
	ToggleBtn.Size = UDim2.new(0, 100, 0, 32)
	ToggleBtn.Position = UDim2.new(0.02, 0, 0.02, 0)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	ToggleBtn.BorderSizePixel = 0
	ToggleBtn.Text = "  " .. toggleText
	ToggleBtn.Font = Enum.Font.SourceSansBold
	ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	ToggleBtn.TextSize = 14
	ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
	ToggleBtn.AutoButtonColor = false
	ToggleBtn.Active = true
	makeDraggable(ToggleBtn)

	local updateStartBorder = add3DBorder(ToggleBtn, false)

	-- 还原 Start 按钮经典交互
	ToggleBtn.MouseButton1Down:Connect(function()
		updateStartBorder(true)
	end)
	ToggleBtn.MouseButton1Up:Connect(function()
		updateStartBorder(false)
	end)

	-- =============================================================================
	-- 主窗口框架
	-- =============================================================================
	local MainGui = Instance.new("Frame")
	MainGui.Parent = Main
	MainGui.Size = UDim2.new(0, 260, 0, 340)
	MainGui.Position = UDim2.new(0.3, 0, 0.2, 0)
	MainGui.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	MainGui.BorderSizePixel = 0
	MainGui.Visible = false
	add3DBorder(MainGui, false) -- 凸起

	-- 标题栏 (含 Windows 经典的渐变蓝底)
	local TitleBar = Instance.new("Frame")
	TitleBar.Parent = MainGui
	TitleBar.Size = UDim2.new(1, -6, 0, 22)
	TitleBar.Position = UDim2.new(0, 3, 0, 3)
	TitleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TitleBar.BorderSizePixel = 0

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 128)),     -- 经典暗蓝
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 132, 208))  -- 渐变亮蓝
	})
	titleGradient.Parent = TitleBar

	local TitleText = Instance.new("TextLabel")
	TitleText.Parent = TitleBar
	TitleText.BackgroundTransparency = 1
	TitleText.Size = UDim2.new(1, -26, 1, 0)
	TitleText.Position = UDim2.new(0, 4, 0, 0)
	TitleText.Font = Enum.Font.SourceSansBold
	TitleText.Text = windowTitle
	TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleText.TextSize = 13
	TitleText.TextXAlignment = Enum.TextXAlignment.Left

	-- 关闭按钮
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Parent = TitleBar
	CloseBtn.Size = UDim2.new(0, 16, 0, 14)
	CloseBtn.Position = UDim2.new(1, -18, 0.5, -7)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	CloseBtn.BorderSizePixel = 0
	CloseBtn.Text = "X"
	CloseBtn.Font = Enum.Font.SourceSansBold
	CloseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	CloseBtn.TextSize = 10
	CloseBtn.AutoButtonColor = false
	local updateCloseBorder = add3DBorder(CloseBtn, false)

	CloseBtn.MouseButton1Down:Connect(function() updateCloseBorder(true) end)
	CloseBtn.MouseButton1Up:Connect(function() updateCloseBorder(false) end)

	makeDraggable(MainGui, TitleBar)

	-- =============================================================================
	-- 标签页 (Tab) 按钮栏
	-- =============================================================================
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

	-- =============================================================================
	-- 标签内容区
	-- =============================================================================
	local Container = Instance.new("Frame")
	Container.Parent = MainGui
	Container.Position = UDim2.new(0, 4, 0, 52)
	Container.Size = UDim2.new(1, -8, 1, -56)
	Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Container.BorderSizePixel = 0
	add3DBorder(Container, true) -- 凹陷

	local tabFrames = {}
	local activeTab = nil

	-- =============================================================================
	-- 组件生成逻辑
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

		-- 内边距
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 6)
		padding.PaddingBottom = UDim.new(0, 6)
		padding.Parent = ScrollingFrame

		for i, el in ipairs(elements) do
			if el.type == "section" then
				-- 分类标题
				local section = Instance.new("TextLabel")
				section.Size = UDim2.new(0.95, 0, 0, 20)
				section.BackgroundColor3 = Color3.fromRGB(0, 0, 128)
				section.BorderSizePixel = 0
				section.Text = "  " .. el.text
				section.Font = Enum.Font.SourceSansBold
				section.TextColor3 = Color3.fromRGB(255, 255, 255)
				section.TextSize = 12
				section.TextXAlignment = Enum.TextXAlignment.Left
				section.LayoutOrder = i
				section.Parent = ScrollingFrame

			elseif el.type == "button" or not el.type then
				-- 标准 3D 按钮
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(0.95, 0, 0, 28)
				btn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
				btn.BorderSizePixel = 0
				btn.Text = el.text or "Button"
				btn.Font = Enum.Font.SourceSans
				btn.TextColor3 = Color3.fromRGB(0, 0, 0)
				btn.TextSize = 13
				btn.AutoButtonColor = false
				btn.LayoutOrder = i
				btn.Parent = ScrollingFrame

				local updateBtnBorder = add3DBorder(btn, false)

				btn.MouseButton1Down:Connect(function()
					updateBtnBorder(true)
				end)
				btn.MouseButton1Up:Connect(function()
					updateBtnBorder(false)
					if el.callback then el.callback() end
				end)

			elseif el.type == "toggle" then
				-- 复选框 开关
				local toggleFrame = Instance.new("Frame")
				toggleFrame.Size = UDim2.new(0.95, 0, 0, 20)
				toggleFrame.BackgroundTransparency = 1
				toggleFrame.LayoutOrder = i
				toggleFrame.Parent = ScrollingFrame

				local checkbox = Instance.new("Frame")
				checkbox.Size = UDim2.new(0, 13, 0, 13)
				checkbox.Position = UDim2.new(0, 4, 0.5, -6)
				checkbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				checkbox.BorderSizePixel = 0
				checkbox.Parent = toggleFrame
				add3DBorder(checkbox, true) -- 凹陷

				local checkMark = Instance.new("TextLabel")
				checkMark.Size = UDim2.new(1, 0, 1, 0)
				checkMark.BackgroundTransparency = 1
				checkMark.Text = "✓"
				checkMark.TextColor3 = Color3.fromRGB(0, 0, 0)
				checkMark.Font = Enum.Font.SourceSansBold
				checkMark.TextSize = 12
				checkMark.Visible = el.default or false
				checkMark.Parent = checkbox

				local label = Instance.new("TextButton")
				label.Size = UDim2.new(1, -22, 1, 0)
				label.Position = UDim2.new(0, 22, 0, 0)
				label.BackgroundTransparency = 1
				label.Text = el.text or "Checkbox"
				label.Font = Enum.Font.SourceSans
				label.TextColor3 = Color3.fromRGB(0, 0, 0)
				label.TextSize = 13
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

			elseif el.type == "slider" then
				-- 滑动条
				local sliderFrame = Instance.new("Frame")
				sliderFrame.Size = UDim2.new(0.95, 0, 0, 36)
				sliderFrame.BackgroundTransparency = 1
				sliderFrame.LayoutOrder = i
				sliderFrame.Parent = ScrollingFrame

				local minVal = el.min or 0
				local maxVal = el.max or 100
				local currentVal = el.default or minVal

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 0, 14)
				label.BackgroundTransparency = 1
				label.Text = (el.text or "Slider") .. ": " .. tostring(currentVal)
				label.Font = Enum.Font.SourceSans
				label.TextColor3 = Color3.fromRGB(0, 0, 0)
				label.TextSize = 12
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = sliderFrame

				local track = Instance.new("Frame")
				track.Size = UDim2.new(1, -12, 0, 4)
				track.Position = UDim2.new(0, 6, 0, 22)
				track.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
				track.BorderSizePixel = 0
				track.Parent = sliderFrame
				add3DBorder(track, true) -- 凹陷

				local thumb = Instance.new("TextButton")
				thumb.Size = UDim2.new(0, 10, 0, 16)
				thumb.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
				thumb.BorderSizePixel = 0
				thumb.Text = ""
				thumb.Parent = track
				local updateThumbBorder = add3DBorder(thumb, false) -- 凸起

				-- 初始化位置
				local percent = (currentVal - minVal) / (maxVal - minVal)
				thumb.Position = UDim2.new(percent, -5, 0.5, -8)

				local isDragging = false

				local function updateSlider(input)
					local trackWidth = track.AbsoluteSize.X
					local relativeX = input.Position.X - track.AbsolutePosition.X
					local percentage = math.clamp(relativeX / trackWidth, 0, 1)

					thumb.Position = UDim2.new(percentage, -5, 0.5, -8)

					local exactValue = minVal + percentage * (maxVal - minVal)
					if el.precise then
						currentVal = math.round(exactValue * 100) / 100
					else
						currentVal = math.round(exactValue)
					end

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

			elseif el.type == "input" then
				-- 输入框
				local inputFrame = Instance.new("Frame")
				inputFrame.Size = UDim2.new(0.95, 0, 0, 36)
				inputFrame.BackgroundTransparency = 1
				inputFrame.LayoutOrder = i
				inputFrame.Parent = ScrollingFrame

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 0, 14)
				label.BackgroundTransparency = 1
				label.Text = el.text or "Input"
				label.Font = Enum.Font.SourceSans
				label.TextColor3 = Color3.fromRGB(0, 0, 0)
				label.TextSize = 12
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = inputFrame

				local textBox = Instance.new("TextBox")
				textBox.Size = UDim2.new(1, 0, 0, 20)
				textBox.Position = UDim2.new(0, 0, 0, 16)
				textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				textBox.BorderSizePixel = 0
				textBox.Font = Enum.Font.SourceSans
				textBox.PlaceholderText = el.placeholder or ""
				textBox.Text = ""
				textBox.TextColor3 = Color3.fromRGB(0, 0, 0)
				textBox.TextSize = 13
				textBox.ClearTextOnFocus = false
				textBox.TextXAlignment = Enum.TextXAlignment.Left
				textBox.Parent = inputFrame
				add3DBorder(textBox, true) -- 凹陷

				local textPadding = Instance.new("UIPadding")
				textPadding.PaddingLeft = UDim.new(0, 4)
				textPadding.PaddingRight = UDim.new(0, 4)
				textPadding.Parent = textBox

				textBox.FocusLost:Connect(function()
					if el.callback then el.callback(textBox.Text) end
				end)
			end
		end
	end

	-- =============================================================================
	-- 多 Tab 页的构建与点击切换
	-- =============================================================================
	for index, tabConfig in ipairs(tabsConfig) do
		-- 构建每一个标签页的内容容器
		local TabContentFrame = Instance.new("Frame")
		TabContentFrame.Size = UDim2.new(1, 0, 1, 0)
		TabContentFrame.BackgroundTransparency = 1
		TabContentFrame.Visible = false
		TabContentFrame.Parent = Container

		renderTabContent(tabConfig, TabContentFrame)
		tabFrames[tabConfig.Name] = TabContentFrame

		-- 创建 Tab 按钮
		local TabBtn = Instance.new("TextButton")
		TabBtn.Size = UDim2.new(0, 70, 1, 0)
		TabBtn.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
		TabBtn.BorderSizePixel = 0
		TabBtn.Text = tabConfig.Name
		TabBtn.Font = Enum.Font.SourceSans
		TabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		TabBtn.TextSize = 12
		TabBtn.LayoutOrder = index
		TabBtn.Parent = TabBar

		local updateTabBorder = add3DBorder(TabBtn, false)

		local function selectTab()
			if activeTab then
				activeTab.ButtonUpdate(false)
				activeTab.Frame.Visible = false
			end
			TabContentFrame.Visible = true
			updateTabBorder(true) -- 当前选中的看起来呈轻微按压嵌入状态
			activeTab = {
				Frame = TabContentFrame,
				ButtonUpdate = updateTabBorder
			}
		end

		TabBtn.MouseButton1Click:Connect(selectTab)

		-- 默认开启第一个标签
		if index == 1 then
			selectTab()
		end
	end

	-- =============================================================================
	-- 基础开关展示控制
	-- =============================================================================
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

return Windows
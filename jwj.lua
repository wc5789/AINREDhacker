-- =====================================================
-- [UI Library Module] - 支持PC/移动端, 拖拽, 全套组件
-- =====================================================
local UILibrary = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

-- 主题配色
local Colors = {
	Main = Color3.fromRGB(35, 210, 120),
	MainDark = Color3.fromRGB(25, 180, 95),
	Bg = Color3.fromRGB(255, 255, 255),
	SidebarBg = Color3.fromRGB(240, 240, 240),
	Text = Color3.fromRGB(40, 40, 40),
	TextLight = Color3.fromRGB(200, 200, 200),
	Gray = Color3.fromRGB(220, 220, 220),
	SwitchOn = Color3.fromRGB(255, 80, 80),
	SwitchOff = Color3.fromRGB(200, 200, 200)
}

-- 全局工具函数
local function AddCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function AddStroke(obj, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(0,0,0)
	s.Thickness = thick or 1
	s.Transparency = 0.5
	s.Parent = obj
	return s
end

local function Tween(obj, props, time)
	return TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- === 核心窗口系统 ===
function UILibrary:CreateWindow(config)
	local Title = config.Title or "UI Library"
	local localPlayer = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "UILib"
	gui.Parent = localPlayer:WaitForChild("PlayerGui")
	
	-- 自适应尺寸 (适配移动端)
	local viewSize = Camera.ViewportSize
	local widthScale = math.min(1, 550 / viewSize.X)
	local heightScale = math.min(1, 650 / viewSize.Y)
	local scaleAmount = math.min(widthScale, heightScale) * 0.85
	
	local Main = Instance.new("Frame")
	Main.Size = UDim2.new(0, 550, 0, 650)
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.BackgroundColor3 = Colors.Bg
	Main.Parent = gui
	AddCorner(Main, 12)
	AddStroke(Main, Color3.fromRGB(180, 230, 210), 2)
	
	-- 缩放适配
	local UIScale = Instance.new("UIScale")
	UIScale.Scale = scaleAmount
	UIScale.Parent = Main
	
	-- === 拖拽系统 (鼠标/触屏) ===
	local dragging, dragInput, dragStart, startPos
	Main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	Main.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X / UIScale.Scale, startPos.Y.Scale, startPos.Y.Offset + delta.Y / UIScale.Scale)
		end
	end)

	-- === 窗口与侧边栏结构 ===
	local Sidebar = Instance.new("Frame")
	Sidebar.Size = UDim2.new(0, 160, 1, 0)
	Sidebar.BackgroundColor3 = Colors.SidebarBg
	Sidebar.Parent = Main
	AddCorner(Sidebar, 12)
	
	local Content = Instance.new("Frame")
	Content.Size = UDim2.new(1, -160, 1, 0)
	Content.Position = UDim2.new(0, 160, 0, 0)
	Content.BackgroundColor3 = Colors.Bg
	Content.Parent = Main
	AddCorner(Content, 12)
	
	-- 侧边栏 Header (修复 X 按钮乱码：使用 Unicode + 纯文本Label)
	local Header = Instance.new("TextLabel")
	Header.Size = UDim2.new(1, 0, 0, 50)
	Header.BackgroundTransparency = 1
	Header.Text = Title
	Header.TextColor3 = Colors.MainDark
	Header.Font = Enum.Font.GothamBold
	Header.TextSize = 18
	Header.Parent = Sidebar
	
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.new(0, 30, 0, 30)
	CloseBtn.Position = UDim2.new(1, -40, 0, 10)
	CloseBtn.BackgroundColor3 = Color3.new(1,0.2,0.2)
	CloseBtn.Text = "×" -- 修复乱码
	CloseBtn.TextColor3 = Color3.new(1,1,1)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 20
	CloseBtn.Parent = Header
	AddCorner(CloseBtn, 100)
	CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

	-- 侧边栏 Tabs 布局
	local TabLayout = Instance.new("UIListLayout")
	TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabLayout.Padding = UDim.new(0, 8)
	TabLayout.Parent = Sidebar
	
	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 50)
	Padding.PaddingLeft = UDim.new(0, 10)
	Padding.PaddingRight = UDim.new(0, 10)
	Padding.Parent = Sidebar

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentLayout.Padding = UDim.new(0, 15)
	ContentLayout.Parent = Content
	
	local ContentPadding = Instance.new("UIPadding")
	ContentPadding.PaddingTop = UDim.new(0, 20)
	ContentPadding.PaddingLeft = UDim.new(0, 20)
	ContentPadding.PaddingRight = UDim.new(0, 20)
	ContentPadding.Parent = Content

	local CurrentTab = nil
	local function SelectTab(tabBtn, tabContent)
		if CurrentTab then CurrentTab.Visible = false end
		tabContent.Visible = true
		CurrentTab = tabContent
	end

	local Window = {Tabs = {}}
	function Window:AddTab(name)
		local TabBtn = Instance.new("TextButton")
		TabBtn.Size = UDim2.new(1, 0, 0, 40)
		TabBtn.BackgroundColor3 = Colors.Main
		TabBtn.Text = name
		TabBtn.TextColor3 = Color3.new(1,1,1)
		TabBtn.Font = Enum.Font.GothamBold
		TabBtn.TextSize = 14
		TabBtn.Parent = Sidebar
		AddCorner(TabBtn, 8)
		
		local TabContent = Instance.new("ScrollingFrame")
		TabContent.Size = UDim2.new(1, 0, 1, 0)
		TabContent.BackgroundTransparency = 1
		TabContent.BorderSizePixel = 0
		TabContent.ScrollBarThickness = 4
		TabContent.Parent = Content
		TabContent.Visible = false
		
		local Layout = Instance.new("UIListLayout")
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.Padding = UDim.new(0, 10)
		Layout.Parent = TabContent
		
		local Pad = Instance.new("UIPadding")
		Pad.PaddingBottom = UDim.new(0, 20)
		Pad.Parent = TabContent

		TabBtn.MouseButton1Click:Connect(function() SelectTab(TabBtn, TabContent) end)
		
		local TabAPI = {Container = TabContent}
		function TabAPI:AddLabel(text)
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0, 30)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Colors.Text
			label.Font = Enum.Font.GothamBold
			label.TextSize = 16
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = TabContent
			return label
		end
		
		function TabAPI:AddButton(text, callback)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 45)
			btn.BackgroundColor3 = Colors.Main
			btn.Text = text
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 15
			btn.Parent = TabContent
			AddCorner(btn, 8)
			btn.MouseButton1Click:Connect(function() 
				local success, err = pcall(callback)
				if not success then warn("UI Button error:", err) end
			end)
			return btn
		end
		
		function TabAPI:AddToggle(text, default, callback)
			local container = Instance.new("Frame")
			container.Size = UDim2.new(1, 0, 0, 40)
			container.BackgroundTransparency = 1
			container.Parent = TabContent
			
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.5, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Colors.Text
			label.Font = Enum.Font.Gotham
			label.TextSize = 15
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = container
			
			local track = Instance.new("TextButton")
			track.Size = UDim2.new(0, 50, 0, 26)
			track.Position = UDim2.new(1, -50, 0.5, -13)
			track.BackgroundColor3 = default and Colors.SwitchOn or Colors.SwitchOff
			track.Parent = container
			AddCorner(track, 100)
			
			local knob = Instance.new("Frame")
			knob.Size = UDim2.new(0, 18, 0, 18)
			knob.Position = default and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 4, 0.5, -9)
			knob.BackgroundColor3 = Color3.new(1,1,1)
			knob.Parent = track
			AddCorner(knob, 100)
			
			local state = default
			track.MouseButton1Click:Connect(function()
				state = not state
				local targetColor = state and Colors.SwitchOn or Colors.SwitchOff
				local targetPos = state and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 4, 0.5, -9)
				Tween(track, {BackgroundColor3 = targetColor})
				Tween(knob, {Position = targetPos})
				if callback then callback(state) end
			end)
			return track
		end
		
		function TabAPI:AddSlider(text, min, max, default, callback)
			local container = Instance.new("Frame")
			container.Size = UDim2.new(1, 0, 0, 50)
			container.BackgroundTransparency = 1
			container.Parent = TabContent
			
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.6, 0, 0, 20)
			label.BackgroundTransparency = 1
			label.Text = text .. ": " .. default
			label.TextColor3 = Colors.Text
			label.Font = Enum.Font.Gotham
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = container
			
			local bg = Instance.new("Frame")
			bg.Size = UDim2.new(1, 0, 0, 8)
			bg.Position = UDim2.new(0, 0, 0, 30)
			bg.BackgroundColor3 = Colors.Gray
			bg.Parent = container
			AddCorner(bg, 100)
			
			local fill = Instance.new("Frame")
			fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
			fill.BackgroundColor3 = Colors.Main
			fill.Parent = bg
			AddCorner(fill, 100)
			
			local dragBtn = Instance.new("TextButton")
			dragBtn.Size = UDim2.new(1, 0, 2, 0)
			dragBtn.BackgroundTransparency = 1
			dragBtn.Parent = bg
			
			local dragging2 = false
			dragBtn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging2 = true
				end
			end)
			dragBtn.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging2 = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging2 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local pos, size = bg.AbsolutePosition, bg.AbsoluteSize
					local x = math.clamp((input.Position.X - pos.X) / size.X, 0, 1)
					local val = math.floor((x * (max - min)) + min)
					label.Text = text .. ": " .. val
					fill.Size = UDim2.new(x, 0, 1, 0)
					if callback then callback(val) end
				end
			end)
		end
		
		function TabAPI:AddDropdown(text, list, callback)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 40)
			btn.BackgroundColor3 = Colors.Main
			btn.Text = text .. "  ▼"
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 14
			btn.Parent = TabContent
			AddCorner(btn, 8)
			
			local expanded = false
			local container = Instance.new("Frame")
			container.Size = UDim2.new(1, 0, 0, 0)
			container.BackgroundTransparency = 1
			container.ClipsDescendants = true
			container.Parent = TabContent
			
			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 2)
			layout.Parent = container
			
			btn.MouseButton1Click:Connect(function()
				expanded = not expanded
				local targetSize = expanded and UDim.new(0, #list * 32) or UDim.new(0, 0)
				Tween(container, {Size = UDim2.new(1, 0, targetSize, 0)})
				btn.Text = expanded and (text .. "  ▲") or (text .. "  ▼")
			end)

			for _, item in ipairs(list) do
				local itemBtn = Instance.new("TextButton")
				itemBtn.Size = UDim2.new(1, -10, 0, 30)
				itemBtn.Position = UDim2.new(0, 5, 0, 0)
				itemBtn.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
				itemBtn.Text = item
				itemBtn.TextColor3 = Color3.fromRGB(50,50,50)
				itemBtn.Font = Enum.Font.Gotham
				itemBtn.Parent = container
				AddCorner(itemBtn, 6)
				itemBtn.MouseButton1Click:Connect(function()
					btn.Text = text .. ": " .. item
					if callback then callback(item) end
					expanded = true
					btn.MouseButton1Click:Fire() -- 自动收起
				end)
			end
		end
		
		function TabAPI:AddTextbox(placeholder, callback)
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, 0, 0, 40)
			box.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
			box.PlaceholderText = placeholder
			box.Text = ""
			box.TextColor3 = Colors.Text
			box.Font = Enum.Font.Gotham
			box.TextSize = 14
			box.Parent = TabContent
			AddCorner(box, 8)
			AddStroke(box, Color3.fromRGB(180, 180, 180), 1)
			
			box.FocusLost:Connect(function()
				if callback then callback(box.Text) end
			end)
			return box
		end
		
		function TabAPI:AddColorPicker(text, default, callback)
			-- 简易 RGB 滑块切换
			local label = self:AddLabel(text)
			local r, g, b = default.R * 255, default.G * 255, default.B * 255
			
			local function updateColor(v)
				local c = Color3.fromRGB(r, g, b)
				if callback then callback(c) end
			end
			
			local function createSlider(lbl, val, max, setFunc)
				local con = Instance.new("Frame")
				con.Size = UDim2.new(1, 0, 0, 30)
				con.BackgroundTransparency = 1
				con.Parent = TabContent
				local l = Instance.new("TextLabel")
				l.Size = UDim2.new(0.2, 0, 1, 0)
				l.BackgroundTransparency = 1
				l.Text = lbl
				l.TextColor3 = Colors.Text
				l.Font = Enum.Font.Gotham
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.Parent = con
				
				local bkg = Instance.new("Frame")
				bkg.Size = UDim2.new(0.6, 0, 0, 6)
				bkg.Position = UDim2.new(0.25, 0, 0.5, -3)
				bkg.BackgroundColor3 = Colors.Gray
				bkg.Parent = con
				AddCorner(bkg, 100)
				
				local fill = Instance.new("Frame")
				fill.Size = UDim2.new(val / max, 0, 1, 0)
				fill.BackgroundColor3 = Color3.fromRGB(255,0,0)
				if lbl == "G" then fill.BackgroundColor3 = Color3.fromRGB(0,255,0) elseif lbl == "B" then fill.BackgroundColor3 = Color3.fromRGB(0,0,255) end
				fill.Parent = bkg
				AddCorner(fill, 100)
				
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 2, 0)
				btn.BackgroundTransparency = 1
				btn.Parent = bkg
				local dragging3 = false
				btn.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging3 = true end
				end)
				btn.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging3 = false end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging3 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						local pos, size = bkg.AbsolutePosition, bkg.AbsoluteSize
						local x = math.clamp((input.Position.X - pos.X) / size.X, 0, 1)
						local v = math.floor(x * max)
						fill.Size = UDim2.new(x, 0, 1, 0)
						setFunc(v)
						updateColor()
					end
				end)
			end
			createSlider("R", r, 255, function(v) r = v end)
			createSlider("G", g, 255, function(v) g = v end)
			createSlider("B", b, 255, function(v) b = v end)
		end
		
		function TabAPI:AddAccordion(text, contentBuilder)
			-- 折叠菜单（带内部滑动）
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 45)
			btn.BackgroundColor3 = Colors.Main
			btn.Text = text .. "  ▼"
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 15
			btn.Parent = TabContent
			AddCorner(btn, 8)
			
			local con = Instance.new("ScrollingFrame")
			con.Size = UDim2.new(1, 0, 0, 0)
			con.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			con.Visible = false
			con.Parent = TabContent
			con.ScrollBarThickness = 2
			AddCorner(con, 6)
			
			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 5)
			layout.Parent = con
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 5)
			pad.PaddingRight = UDim.new(0, 5)
			pad.PaddingTop = UDim.new(0, 5)
			pad.PaddingBottom = UDim.new(0, 5)
			pad.Parent = con
			
			local expanded = false
			btn.MouseButton1Click:Connect(function()
				expanded = not expanded
				if expanded then
					con.Visible = true
					-- 内容构建延迟执行，可以放任何组件
					if contentBuilder then contentBuilder(con) end
					local height = math.min(200, layout.AbsoluteContentSize.Y + 20) -- 最大高度 200
					Tween(con, {Size = UDim2.new(1, 0, 0, height)})
					btn.Text = text .. "  ▲"
				else
					btn.Text = text .. "  ▼"
					Tween(con, {Size = UDim2.new(1, 0, 0, 0)})
					task.wait(0.2)
					con.Visible = false
				end
			end)
			return con
		end
		
		table.insert(Window.Tabs, TabAPI)
		return TabAPI
	end
	
	function Window:Notification(title, desc, duration)
		local notif = Instance.new("Frame")
		notif.Size = UDim2.new(0, 320, 0, 100)
		notif.Position = UDim2.new(0.5, 0, 1, 50)
		notif.AnchorPoint = Vector2.new(0.5, 1)
		notif.BackgroundColor3 = Color3.fromRGB(255,255,255)
		notif.Parent = gui
		AddCorner(notif, 12)
		AddStroke(notif, Colors.Main, 2)
		
		local tit = Instance.new("TextLabel")
		tit.Size = UDim2.new(1, 0, 0, 35)
		tit.BackgroundColor3 = Colors.Main
		tit.Text = title
		tit.TextColor3 = Color3.new(1,1,1)
		tit.Font = Enum.Font.GothamBold
		tit.Parent = notif
		AddCorner(tit, 12)
		-- 让底部圆角消失
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 0)
		c.Parent = tit
		
		local descL = Instance.new("TextLabel")
		descL.Size = UDim2.new(1, -20, 0, 50)
		descL.Position = UDim2.new(0, 10, 0, 45)
		descL.BackgroundTransparency = 1
		descL.Text = desc
		descL.TextColor3 = Colors.Text
		descL.Font = Enum.Font.Gotham
		descL.TextSize = 13
		descL.TextWrapped = true
		descL.Parent = notif
		
		Tween(notif, {Position = UDim2.new(0.5, 0, 1, -120)})
		task.wait(duration or 3)
		Tween(notif, {Position = UDim2.new(0.5, 0, 1, 50)})
		task.wait(0.3)
		notif:Destroy()
	end
	
	return Window
end

return UILibrary
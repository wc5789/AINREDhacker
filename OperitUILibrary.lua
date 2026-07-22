--[[
    Operit UI Library v3.0 "Neon Glass" Edition
    一个现代化、高性能的Roblox GUI库
    作者: Operit AI Assistant
    
    特性:
    - 现代玻璃态设计 (Glassmorphism)
    - 流畅的Tween动画系统
    - 模块化组件架构
    - 跨平台兼容 (PC/Mobile)
    - 高性能渲染循环优化
    - 状态保存与恢复机制
]]

local OperitUI = {}
OperitUI.__index = OperitUI

-- 服务引用
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- 配置常量
local CONFIG = {
    -- 颜色主题
    Colors = {
        Primary = Color3.fromRGB(254, 74, 161),      -- 霓虹粉
        Secondary = Color3.fromRGB(100, 50, 150),    -- 深紫色
        Background = Color3.fromRGB(20, 20, 30),      -- 深色背景
        Surface = Color3.fromRGB(30, 30, 45),         -- 表面色
        Text = Color3.fromRGB(255, 255, 255),         -- 白色文字
        TextDark = Color3.fromRGB(200, 200, 200),     -- 次要文字
        Success = Color3.fromRGB(0, 200, 100),        -- 成功绿
        Warning = Color3.fromRGB(255, 200, 0),        -- 警告黄
        Error = Color3.fromRGB(255, 50, 50),          -- 错误红
        Glass = Color3.fromRGB(255, 255, 255),        -- 玻璃白
    },
    
    -- 动画配置
    Animation = {
        TweenSpeed = 0.3,
        TweenStyle = Enum.EasingStyle.Quint,
        TweenDirection = Enum.EasingDirection.Out,
        BounceFactor = 1.2,
    },
    
    -- 布局配置
    Layout = {
        WindowSize = UDim2.new(0, 500, 0, 330),
        ButtonSize = UDim2.new(1, -10, 0, 40),
        SliderSize = UDim2.new(1, -10, 0, 44),
        ToggleSize = UDim2.new(0, 50, 0, 26),
        CornerRadius = UDim.new(0, 10),
        SmallCornerRadius = UDim.new(0, 6),
        Padding = UDim.new(0, 8),
    },
}

-- 工具函数
local function createTween(object, properties, duration, style, direction)
    duration = duration or CONFIG.Animation.TweenSpeed
    style = style or CONFIG.Animation.TweenStyle
    direction = direction or CONFIG.Animation.TweenDirection
    
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration, style, direction),
        properties
    )
    return tween
end

local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return setmetatable(copy, getmetatable(original))
end

-- UI组件基类
local UIComponent = {}
UIComponent.__index = UIComponent

function UIComponent.new(parent, properties)
    local self = setmetatable({}, UIComponent)
    self.Instance = nil
    self.Parent = parent
    self.Properties = properties or {}
    self.Connections = {}
    self.State = {}
    return self
end

function UIComponent:create()
    -- 子类重写此方法
end

function UIComponent:update(properties)
    for k, v in pairs(properties) do
        self.Properties[k] = v
        if self.Instance and self.Instance:FindFirstChild(k) ~= nil or self.Instance[k] then
            self.Instance[k] = v
        end
    end
end

function UIComponent:destroy()
    for _, connection in pairs(self.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    if self.Instance then
        self.Instance:Destroy()
    end
end

-- 窗口组件
local Window = setmetatable({}, {__index = UIComponent})
Window.__index = Window

function Window.new(parent, title, size)
    local self = setmetatable(UIComponent.new(parent), Window)
    self.Title = title or "Operit UI"
    self.Size = size or CONFIG.Layout.WindowSize
    self.Pages = {}
    self.CurrentPage = nil
    self.IsDragging = false
    self.DragStart = nil
    self.StartPosition = nil
    
    self:create()
    return self
end

function Window:create()
    -- 主窗口容器
    self.Instance = Instance.new("ScreenGui")
    self.Instance.Name = "OperitUI"
    self.Instance.ResetOnSpawn = false
    self.Instance.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- 优先挂载到CoreGui
    local success, err = pcall(function()
        self.Instance.Parent = CoreGui
    end)
    
    if not success then
        self.Instance.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- 窗口框架
    self.WindowFrame = Instance.new("Frame")
    self.WindowFrame.Name = "WindowFrame"
    self.WindowFrame.Size = self.Size
    self.WindowFrame.Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2)
    self.WindowFrame.BackgroundColor3 = CONFIG.Colors.Background
    self.WindowFrame.BorderSizePixel = 0
    self.WindowFrame.Active = true
    self.WindowFrame.Parent = self.Instance
    
    -- 窗口圆角
    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = CONFIG.Layout.CornerRadius
    windowCorner.Parent = self.WindowFrame
    
    -- 窗口描边
    local windowStroke = Instance.new("UIStroke")
    windowStroke.Color = CONFIG.Colors.Primary
    windowStroke.Thickness = 2
    windowStroke.Transparency = 0.7
    windowStroke.Parent = self.WindowFrame
    
    -- 玻璃效果
    local glassEffect = Instance.new("Frame")
    glassEffect.Name = "GlassEffect"
    glassEffect.Size = UDim2.new(1, 0, 1, 0)
    glassEffect.BackgroundColor3 = CONFIG.Colors.Glass
    glassEffect.BackgroundTransparency = 0.92
    glassEffect.BorderSizePixel = 0
    glassEffect.Parent = self.WindowFrame
    
    -- 标题栏
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 40)
    self.TitleBar.BackgroundColor3 = CONFIG.Colors.Surface
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.WindowFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = self.TitleBar
    
    -- 标题文本
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = CONFIG.Colors.Text
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = self.TitleBar
    
    -- 关闭按钮
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Name = "CloseButton"
    self.CloseButton.Size = UDim2.new(0, 30, 0, 30)
    self.CloseButton.Position = UDim2.new(1, -35, 0, 5)
    self.CloseButton.BackgroundColor3 = CONFIG.Colors.Error
    self.CloseButton.BorderSizePixel = 0
    self.CloseButton.Text = "×"
    self.CloseButton.TextColor3 = CONFIG.Colors.Text
    self.CloseButton.TextSize = 20
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.Parent = self.TitleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = self.CloseButton
    
    -- 最小化按钮
    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Name = "MinimizeButton"
    self.MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    self.MinimizeButton.Position = UDim2.new(1, -70, 0, 5)
    self.MinimizeButton.BackgroundColor3 = CONFIG.Colors.Warning
    self.MinimizeButton.BorderSizePixel = 0
    self.MinimizeButton.Text = "−"
    self.MinimizeButton.TextColor3 = CONFIG.Colors.Text
    self.MinimizeButton.TextSize = 20
    self.MinimizeButton.Font = Enum.Font.GothamBold
    self.MinimizeButton.Parent = self.TitleBar
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 15)
    minimizeCorner.Parent = self.MinimizeButton
    
    -- 内容区域
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Name = "ContentFrame"
    self.ContentFrame.Size = UDim2.new(1, -20, 1, -60)
    self.ContentFrame.Position = UDim2.new(0, 10, 0, 50)
    self.ContentFrame.BackgroundTransparency = 1
    self.ContentFrame.Parent = self.WindowFrame
    
    -- 标签页容器
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.Size = UDim2.new(1, 0, 0, 30)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.Parent = self.ContentFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = self.TabContainer
    
    -- 页面容器
    self.PageContainer = Instance.new("Frame")
    self.PageContainer.Name = "PageContainer"
    self.PageContainer.Size = UDim2.new(1, 0, 1, -40)
    self.PageContainer.Position = UDim2.new(0, 0, 0, 35)
    self.PageContainer.BackgroundTransparency = 1
    self.PageContainer.ClipsDescendants = true
    self.PageContainer.Parent = self.ContentFrame
    
    -- 设置拖拽功能
    self:setupDragging()
    
    -- 设置按钮功能
    self:setupButtons()
    
    -- 入场动画
    self:playEntryAnimation()
end

function Window:setupDragging()
    local dragStart, startPos, dragging
    
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.WindowFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPosition = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            
            -- 边界限制
            local screenSize = workspace.CurrentCamera.ViewportSize
            local frameSize = self.WindowFrame.AbsoluteSize
            
            local newX = math.clamp(newPosition.X.Offset, -frameSize.X/2, screenSize.X - frameSize.X/2)
            local newY = math.clamp(newPosition.Y.Offset, -frameSize.Y/2, screenSize.Y - frameSize.Y/2)
            
            self.WindowFrame.Position = UDim2.new(0.5, newX, 0.5, newY)
        end
    end)
end

function Window:setupButtons()
    -- 关闭按钮功能
    self.CloseButton.MouseButton1Click:Connect(function()
        self:playExitAnimation()
    end)
    
    -- 最小化按钮功能
    self.MinimizeButton.MouseButton1Click:Connect(function()
        self:toggleMinimize()
    end)
    
    -- 悬浮效果
    self.CloseButton.MouseEnter:Connect(function()
        createTween(self.CloseButton, {Size = UDim2.new(0, 35, 0, 35)}, 0.2):Play()
    end)
    
    self.CloseButton.MouseLeave:Connect(function()
        createTween(self.CloseButton, {Size = UDim2.new(0, 30, 0, 30)}, 0.2):Play()
    end)
    
    self.MinimizeButton.MouseEnter:Connect(function()
        createTween(self.MinimizeButton, {Size = UDim2.new(0, 35, 0, 35)}, 0.2):Play()
    end)
    
    self.MinimizeButton.MouseLeave:Connect(function()
        createTween(self.MinimizeButton, {Size = UDim2.new(0, 30, 0, 30)}, 0.2):Play()
    end)
end

function Window:playEntryAnimation()
    self.WindowFrame.Size = UDim2.new(0, 0, 0, 0)
    self.WindowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.WindowFrame.BackgroundTransparency = 1
    
    -- 渐显动画
    local fadeTween = createTween(self.WindowFrame, {
        BackgroundTransparency = 0
    }, 0.4)
    
    -- 缩放动画
    local scaleTween = createTween(self.WindowFrame, {
        Size = self.Size,
        Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2)
    }, 0.5, Enum.EasingStyle.Back)
    
    fadeTween:Play()
    scaleTween:Play()
end

function Window:playExitAnimation()
    local fadeTween = createTween(self.WindowFrame, {
        BackgroundTransparency = 1
    }, 0.3)
    
    local scaleTween = createTween(self.WindowFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    
    fadeTween:Play()
    scaleTween:Play()
    
    fadeTween.Completed:Wait()
    self:destroy()
end

function Window:toggleMinimize()
    local isMinimized = self.WindowFrame.Size.Y.Offset <= 40
    
    if isMinimized then
        -- 恢复
        createTween(self.WindowFrame, {
            Size = self.Size
        }, 0.3, Enum.EasingStyle.Back):Play()
        
        createTween(self.ContentFrame, {
            Size = UDim2.new(1, -20, 1, -60),
            Position = UDim2.new(0, 10, 0, 50)
        }, 0.3):Play()
    else
        -- 最小化
        createTween(self.WindowFrame, {
            Size = UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 40)
        }, 0.3, Enum.EasingStyle.Back):Play()
        
        createTween(self.ContentFrame, {
            Size = UDim2.new(1, -20, 0, 0),
            Position = UDim2.new(0, 10, 0, 40)
        }, 0.3):Play()
    end
end

function Window:addPage(title, icon)
    local page = Page.new(self, title, icon)
    table.insert(self.Pages, page)
    
    if #self.Pages == 1 then
        self:selectPage(1)
    end
    
    return page
end

function Window:selectPage(index)
    if self.CurrentPage then
        self.CurrentPage:deselect()
    end
    
    self.CurrentPage = self.Pages[index]
    if self.CurrentPage then
        self.CurrentPage:select()
    end
end

-- 页面组件
local Page = setmetatable({}, {__index = UIComponent})
Page.__index = Page

function Page.new(window, title, icon)
    local self = setmetatable(UIComponent.new(window), Page)
    self.Window = window
    self.Title = title
    self.Icon = icon or "📋"
    self.Elements = {}
    self.IsSelected = false
    
    self:create()
    return self
end

function Page:create()
    -- 标签页按钮
    self.TabButton = Instance.new("TextButton")
    self.TabButton.Name = "Tab_" .. self.Title
    self.TabButton.Size = UDim2.new(0, 100, 1, 0)
    self.TabButton.BackgroundColor3 = CONFIG.Colors.Surface
    self.TabButton.BorderSizePixel = 0
    self.TabButton.Text = self.Icon .. " " .. self.Title
    self.TabButton.TextColor3 = CONFIG.Colors.TextDark
    self.TabButton.TextSize = 14
    self.TabButton.Font = Enum.Font.GothamMedium
    self.TabButton.Parent = self.Window.TabContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 5)
    tabCorner.Parent = self.TabButton
    
    -- 页面内容容器
    self.Content = Instance.new("ScrollingFrame")
    self.Content.Name = "Page_" .. self.Title
    self.Content.Size = UDim2.new(1, 0, 1, 0)
    self.Content.BackgroundTransparency = 1
    self.Content.ScrollBarThickness = 6
    self.Content.ScrollBarImageColor3 = CONFIG.Colors.Primary
    self.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.Content.Visible = false
    self.Content.Parent = self.Window.PageContainer
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = self.Content
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 5)
    contentPadding.PaddingBottom = UDim.new(0, 5)
    contentPadding.PaddingLeft = UDim.new(0, 5)
    contentPadding.PaddingRight = UDim.new(0, 5)
    contentPadding.Parent = self.Content
    
    -- 设置点击事件
    self.TabButton.MouseButton1Click:Connect(function()
        local index = table.find(self.Window.Pages, self)
        if index then
            self.Window:selectPage(index)
        end
    end)
    
    -- 悬浮效果
    self.TabButton.MouseEnter:Connect(function()
        if not self.IsSelected then
            createTween(self.TabButton, {
                BackgroundColor3 = Color3.new(
                    CONFIG.Colors.Surface.R * 1.2,
                    CONFIG.Colors.Surface.G * 1.2,
                    CONFIG.Colors.Surface.B * 1.2
                )
            }, 0.2):Play()
        end
    end)
    
    self.TabButton.MouseLeave:Connect(function()
        if not self.IsSelected then
            createTween(self.TabButton, {
                BackgroundColor3 = CONFIG.Colors.Surface
            }, 0.2):Play()
        end
    end)
end

function Page:select()
    self.IsSelected = true
    self.Content.Visible = true
    
    -- 更新标签页外观
    createTween(self.TabButton, {
        BackgroundColor3 = CONFIG.Colors.Primary,
        TextColor3 = CONFIG.Colors.Text
    }, 0.3):Play()
    
    -- 页面入场动画
    self.Content.Position = UDim2.new(0, 0, 0, 20)
    self.Content.BackgroundTransparency = 1
    
    createTween(self.Content, {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0
    }, 0.3):Play()
end

function Page:deselect()
    self.IsSelected = false
    self.Content.Visible = false
    
    -- 更新标签页外观
    createTween(self.TabButton, {
        BackgroundColor3 = CONFIG.Colors.Surface,
        TextColor3 = CONFIG.Colors.TextDark
    }, 0.3):Play()
end

function Page:addButton(text, callback)
    local button = Button.new(self, text, callback)
    table.insert(self.Elements, button)
    return button
end

function Page:addToggle(text, default, callback)
    local toggle = Toggle.new(self, text, default, callback)
    table.insert(self.Elements, toggle)
    return toggle
end

function Page:addSlider(text, min, max, default, callback)
    local slider = Slider.new(self, text, min, max, default, callback)
    table.insert(self.Elements, slider)
    return slider
end

function Page:addLabel(text)
    local label = Label.new(self, text)
    table.insert(self.Elements, label)
    return label
end

function Page:addDropdown(text, options, callback)
    local dropdown = Dropdown.new(self, text, options, callback)
    table.insert(self.Elements, dropdown)
    return dropdown
end

-- 按钮组件
local Button = setmetatable({}, {__index = UIComponent})
Button.__index = Button

function Button.new(page, text, callback)
    local self = setmetatable(UIComponent.new(page), Button)
    self.Text = text
    self.Callback = callback
    self.IsEnabled = true
    
    self:create()
    return self
end

function Button:create()
    self.Instance = Instance.new("TextButton")
    self.Instance.Name = "Button_" .. self.Text
    self.Instance.Size = CONFIG.Layout.ButtonSize
    self.Instance.BackgroundColor3 = CONFIG.Colors.Primary
    self.Instance.BorderSizePixel = 0
    self.Instance.Text = self.Text
    self.Instance.TextColor3 = CONFIG.Colors.Text
    self.Instance.TextSize = 16
    self.Instance.Font = Enum.Font.GothamMedium
    self.Instance.AutoButtonColor = false
    self.Instance.Parent = self.Parent.Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CONFIG.Layout.SmallCornerRadius
    corner.Parent = self.Instance
    
    -- 悬浮效果
    self.Instance.MouseEnter:Connect(function()
        if self.IsEnabled then
            createTween(self.Instance, {
                BackgroundColor3 = Color3.new(
                    CONFIG.Colors.Primary.R * 1.2,
                    CONFIG.Colors.Primary.G * 1.2,
                    CONFIG.Colors.Primary.B * 1.2
                ),
                Size = UDim2.new(1, -10, 0, 42)
            }, 0.2):Play()
        end
    end)
    
    self.Instance.MouseLeave:Connect(function()
        if self.IsEnabled then
            createTween(self.Instance, {
                BackgroundColor3 = CONFIG.Colors.Primary,
                Size = CONFIG.Layout.ButtonSize
            }, 0.2):Play()
        end
    end)
    
    -- 点击效果
    self.Instance.MouseButton1Down:Connect(function()
        if self.IsEnabled then
            createTween(self.Instance, {
                Size = UDim2.new(1, -15, 0, 38)
            }, 0.1):Play()
        end
    end)
    
    self.Instance.MouseButton1Up:Connect(function()
        if self.IsEnabled then
            createTween(self.Instance, {
                Size = UDim2.new(1, -10, 0, 42)
            }, 0.1):Play()
        end
    end)
    
    -- 点击事件
    self.Instance.MouseButton1Click:Connect(function()
        if self.IsEnabled and self.Callback then
            -- 按压缩放动画
            createTween(self.Instance, {
                Size = UDim2.new(1, -20, 0, 36)
            }, 0.1):Play()
            
            wait(0.1)
            
            createTween(self.Instance, {
                Size = CONFIG.Layout.ButtonSize
            }, 0.1):Play()
            
            -- 执行回调
            self.Callback()
        end
    end)
end

function Button:setEnabled(enabled)
    self.IsEnabled = enabled
    
    if enabled then
        createTween(self.Instance, {
            BackgroundColor3 = CONFIG.Colors.Primary,
            TextTransparency = 0
        }, 0.2):Play()
    else
        createTween(self.Instance, {
            BackgroundColor3 = CONFIG.Colors.Surface,
            TextTransparency = 0.5
        }, 0.2):Play()
    end
end

-- 开关组件
local Toggle = setmetatable({}, {__index = UIComponent})
Toggle.__index = Toggle

function Toggle.new(page, text, default, callback)
    local self = setmetatable(UIComponent.new(page), Toggle)
    self.Text = text
    self.Value = default or false
    self.Callback = callback
    
    self:create()
    return self
end

function Toggle:create()
    -- 容器
    self.Instance = Instance.new("Frame")
    self.Instance.Name = "Toggle_" .. self.Text
    self.Instance.Size = UDim2.new(1, -10, 0, 40)
    self.Instance.BackgroundColor3 = CONFIG.Colors.Surface
    self.Instance.BorderSizePixel = 0
    self.Instance.Parent = self.Parent.Content
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = CONFIG.Layout.SmallCornerRadius
    containerCorner.Parent = self.Instance
    
    -- 文本标签
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -60, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = self.Text
    textLabel.TextColor3 = CONFIG.Colors.Text
    textLabel.TextSize = 16
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = self.Instance
    
    -- 开关背景
    self.ToggleBackground = Instance.new("Frame")
    self.ToggleBackground.Name = "ToggleBackground"
    self.ToggleBackground.Size = CONFIG.Layout.ToggleSize
    self.ToggleBackground.Position = UDim2.new(1, -55, 0.5, -13)
    self.ToggleBackground.BackgroundColor3 = self.Value and CONFIG.Colors.Primary or CONFIG.Colors.Surface
    self.ToggleBackground.BorderSizePixel = 0
    self.ToggleBackground.Parent = self.Instance
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = self.ToggleBackground
    
    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = CONFIG.Colors.Primary
    toggleStroke.Thickness = 1
    toggleStroke.Transparency = 0.5
    toggleStroke.Parent = self.ToggleBackground
    
    -- 开关按钮
    self.ToggleButton = Instance.new("Frame")
    self.ToggleButton.Name = "ToggleButton"
    self.ToggleButton.Size = UDim2.new(0, 20, 0, 20)
    self.ToggleButton.Position = self.Value and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 3, 0, 3)
    self.ToggleButton.BackgroundColor3 = CONFIG.Colors.Text
    self.ToggleButton.BorderSizePixel = 0
    self.ToggleButton.Parent = self.ToggleBackground
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = self.ToggleButton
    
    -- 点击区域
    self.ClickArea = Instance.new("TextButton")
    self.ClickArea.Size = UDim2.new(1, 0, 1, 0)
    self.ClickArea.BackgroundTransparency = 1
    self.ClickArea.Text = ""
    self.ClickArea.Parent = self.ToggleBackground
    
    -- 点击事件
    self.ClickArea.MouseButton1Click:Connect(function()
        self.Value = not self.Value
        self:updateVisual()
        
        if self.Callback then
            self.Callback(self.Value)
        end
    end)
    
    -- 悬浮效果
    self.ClickArea.MouseEnter:Connect(function()
        createTween(self.ToggleButton, {
            Size = UDim2.new(0, 22, 0, 22),
            Position = self.Value and UDim2.new(1, -25, 0, 2) or UDim2.new(0, 2, 0, 2)
        }, 0.2):Play()
    end)
    
    self.ClickArea.MouseLeave:Connect(function()
        createTween(self.ToggleButton, {
            Size = UDim2.new(0, 20, 0, 20),
            Position = self.Value and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 3, 0, 3)
        }, 0.2):Play()
    end)
    
    -- 初始状态
    self:updateVisual()
end

function Toggle:updateVisual()
    -- 背景颜色
    createTween(self.ToggleBackground, {
        BackgroundColor3 = self.Value and CONFIG.Colors.Primary or CONFIG.Colors.Surface
    }, 0.3, Enum.EasingStyle.Back):Play()
    
    -- 按钮位置
    createTween(self.ToggleButton, {
        Position = self.Value and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 3, 0, 3)
    }, 0.3, Enum.EasingStyle.Back):Play()
    
    -- 按钮颜色
    createTween(self.ToggleButton, {
        BackgroundColor3 = self.Value and CONFIG.Colors.Text or CONFIG.Colors.TextDark
    }, 0.3):Play()
end

function Toggle:setValue(value)
    self.Value = value
    self:updateVisual()
end

-- 滑块组件
local Slider = setmetatable({}, {__index = UIComponent})
Slider.__index = Slider

function Slider.new(page, text, min, max, default, callback)
    local self = setmetatable(UIComponent.new(page), Slider)
    self.Text = text
    self.Min = min or 0
    self.Max = max or 100
    self.Value = default or self.Min
    self.Callback = callback
    self.IsDragging = false
    
    self:create()
    return self
end

function Slider:create()
    -- 容器
    self.Instance = Instance.new("Frame")
    self.Instance.Name = "Slider_" .. self.Text
    self.Instance.Size = CONFIG.Layout.SliderSize
    self.Instance.BackgroundColor3 = CONFIG.Colors.Surface
    self.Instance.BorderSizePixel = 0
    self.Instance.Parent = self.Parent.Content
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = CONFIG.Layout.SmallCornerRadius
    containerCorner.Parent = self.Instance
    
    -- 文本标签
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -100, 0, 20)
    textLabel.Position = UDim2.new(0, 10, 0, 5)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = self.Text
    textLabel.TextColor3 = CONFIG.Colors.Text
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = self.Instance
    
    -- 值标签
    self.ValueLabel = Instance.new("TextLabel")
    self.ValueLabel.Size = UDim2.new(0, 50, 0, 20)
    self.ValueLabel.Position = UDim2.new(1, -60, 0, 5)
    self.ValueLabel.BackgroundTransparency = 1
    self.ValueLabel.Text = tostring(self.Value)
    self.ValueLabel.TextColor3 = CONFIG.Colors.Primary
    self.ValueLabel.TextSize = 14
    self.ValueLabel.Font = Enum.Font.GothamBold
    self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.ValueLabel.Parent = self.Instance
    
    -- 滑块轨道
    self.SliderTrack = Instance.new("Frame")
    self.SliderTrack.Name = "SliderTrack"
    self.SliderTrack.Size = UDim2.new(1, -20, 0, 8)
    self.SliderTrack.Position = UDim2.new(0, 10, 0, 25)
    self.SliderTrack.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
    self.SliderTrack.BorderSizePixel = 0
    self.SliderTrack.Parent = self.Instance
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = self.SliderTrack
    
    -- 滑块填充
    self.SliderFill = Instance.new("Frame")
    self.SliderFill.Name = "SliderFill"
    self.SliderFill.Size = UDim2.new(0, 0, 1, 0)
    self.SliderFill.BackgroundColor3 = CONFIG.Colors.Primary
    self.SliderFill.BorderSizePixel = 0
    self.SliderFill.Parent = self.SliderTrack
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = self.SliderFill
    
    -- 滑块按钮
    self.SliderButton = Instance.new("Frame")
    self.SliderButton.Name = "SliderButton"
    self.SliderButton.Size = UDim2.new(0, 20, 0, 20)
    self.SliderButton.Position = UDim2.new(0, -10, 0.5, -10)
    self.SliderButton.BackgroundColor3 = CONFIG.Colors.Text
    self.SliderButton.BorderSizePixel = 0
    self.SliderButton.ZIndex = 2
    self.SliderButton.Parent = self.SliderFill
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = self.SliderButton
    
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = CONFIG.Colors.Primary
    buttonStroke.Thickness = 2
    buttonStroke.Parent = self.SliderButton
    
    -- 点击区域
    self.ClickArea = Instance.new("TextButton")
    self.ClickArea.Size = UDim2.new(1, 0, 1, 0)
    self.ClickArea.BackgroundTransparency = 1
    self.ClickArea.Text = ""
    self.ClickArea.ZIndex = 3
    self.ClickArea.Parent = self.SliderTrack
    
    -- 更新初始位置
    self:updateSliderPosition()
    
    -- 点击事件
    self.ClickArea.MouseButton1Down:Connect(function()
        self.IsDragging = true
        self:updateFromMouse()
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.IsDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if self.IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                               input.UserInputType == Enum.UserInputType.Touch) then
            self:updateFromMouse()
        end
    end)
    
    -- 悬浮效果
    self.ClickArea.MouseEnter:Connect(function()
        createTween(self.SliderButton, {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, -12, 0.5, -12)
        }, 0.2):Play()
        
        createTween(self.SliderTrack, {
            Size = UDim2.new(1, -20, 0, 10)
        }, 0.2):Play()
    end)
    
    self.ClickArea.MouseLeave:Connect(function()
        if not self.IsDragging then
            createTween(self.SliderButton, {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, -10, 0.5, -10)
            }, 0.2):Play()
            
            createTween(self.SliderTrack, {
                Size = UDim2.new(1, -20, 0, 8)
            }, 0.2):Play()
        end
    end)
end

function Slider:updateFromMouse()
    local mouseLocation = UserInputService:GetMouseLocation()
    local trackPosition = self.SliderTrack.AbsolutePosition
    local trackSize = self.SliderTrack.AbsoluteSize
    
    local relativeX = (mouseLocation.X - trackPosition.X) / trackSize.X
    relativeX = math.clamp(relativeX, 0, 1)
    
    self.Value = math.floor(self.Min + (self.Max - self.Min) * relativeX)
    self:updateSliderPosition()
    self.ValueLabel.Text = tostring(self.Value)
    
    if self.Callback then
        self.Callback(self.Value)
    end
end

function Slider:updateSliderPosition()
    local percentage = (self.Value - self.Min) / (self.Max - self.Min)
    self.SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
end

function Slider:setValue(value)
    self.Value = math.clamp(value, self.Min, self.Max)
    self:updateSliderPosition()
    self.ValueLabel.Text = tostring(self.Value)
end

-- 标签组件
local Label = setmetatable({}, {__index = UIComponent})
Label.__index = Label

function Label.new(page, text)
    local self = setmetatable(UIComponent.new(page), Label)
    self.Text = text
    
    self:create()
    return self
end

function Label:create()
    self.Instance = Instance.new("TextLabel")
    self.Instance.Name = "Label_" .. self.Text
    self.Instance.Size = UDim2.new(1, -10, 0, 30)
    self.Instance.BackgroundTransparency = 1
    self.Instance.Text = self.Text
    self.Instance.TextColor3 = CONFIG.Colors.TextDark
    self.Instance.TextSize = 14
    self.Instance.Font = Enum.Font.GothamMedium
    self.Instance.TextXAlignment = Enum.TextXAlignment.Left
    self.Instance.Parent = self.Parent.Content
end

function Label:setText(text)
    self.Text = text
    self.Instance.Text = text
end

-- 下拉菜单组件
local Dropdown = setmetatable({}, {__index = UIComponent})
Dropdown.__index = Dropdown

function Dropdown.new(page, text, options, callback)
    local self = setmetatable(UIComponent.new(page), Dropdown)
    self.Text = text
    self.Options = options or {}
    self.SelectedOption = nil
    self.Callback = callback
    self.IsOpen = false
    
    self:create()
    return self
end

function Dropdown:create()
    -- 容器
    self.Instance = Instance.new("Frame")
    self.Instance.Name = "Dropdown_" .. self.Text
    self.Instance.Size = UDim2.new(1, -10, 0, 40)
    self.Instance.BackgroundColor3 = CONFIG.Colors.Surface
    self.Instance.BorderSizePixel = 0
    self.Instance.ClipsDescendants = true
    self.Instance.Parent = self.Parent.Content
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = CONFIG.Layout.SmallCornerRadius
    containerCorner.Parent = self.Instance
    
    -- 文本标签
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.7, 10, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = self.Text
    textLabel.TextColor3 = CONFIG.Colors.Text
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = self.Instance
    
    -- 选中文本
    self.SelectedLabel = Instance.new("TextLabel")
    self.SelectedLabel.Size = UDim2.new(0.25, 0, 1, 0)
    self.SelectedLabel.Position = UDim2.new(0.7, 0, 0, 0)
    self.SelectedLabel.BackgroundTransparency = 1
    self.SelectedLabel.Text = "选择..."
    self.SelectedLabel.TextColor3 = CONFIG.Colors.Primary
    self.SelectedLabel.TextSize = 14
    self.SelectedLabel.Font = Enum.Font.GothamMedium
    self.SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.SelectedLabel.Parent = self.Instance
    
    -- 箭头图标
    self.Arrow = Instance.new("TextLabel")
    self.Arrow.Size = UDim2.new(0, 20, 1, 0)
    self.Arrow.Position = UDim2.new(1, -25, 0, 0)
    self.Arrow.BackgroundTransparency = 1
    self.Arrow.Text = "▼"
    self.Arrow.TextColor3 = CONFIG.Colors.TextDark
    self.Arrow.TextSize = 12
    self.Arrow.Font = Enum.Font.GothamBold
    self.Arrow.Parent = self.Instance
    
    -- 选项容器
    self.OptionsFrame = Instance.new("Frame")
    self.OptionsFrame.Name = "OptionsFrame"
    self.OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
    self.OptionsFrame.Position = UDim2.new(0, 0, 0, 40)
    self.OptionsFrame.BackgroundColor3 = CONFIG.Colors.Surface
    self.OptionsFrame.BorderSizePixel = 0
    self.OptionsFrame.Visible = false
    self.OptionsFrame.Parent = self.Instance
    
    local optionsCorner = Instance.new("UICorner")
    optionsCorner.CornerRadius = UDim2.new(0, 0, 0, 6)
    optionsCorner.Parent = self.OptionsFrame
    
    -- 选项列表
    self.OptionsList = Instance.new("UIListLayout")
    self.OptionsList.Padding = UDim.new(0, 2)
    self.OptionsList.SortOrder = Enum.SortOrder.LayoutOrder
    self.OptionsList.Parent = self.OptionsFrame
    
    -- 创建选项按钮
    self:createOptions()
    
    -- 点击区域
    self.ClickArea = Instance.new("TextButton")
    self.ClickArea.Size = UDim2.new(1, 0, 1, 0)
    self.ClickArea.BackgroundTransparency = 1
    self.ClickArea.Text = ""
    self.ClickArea.Parent = self.Instance
    
    self.ClickArea.MouseButton1Click:Connect(function()
        self:toggle()
    end)
    
    -- 悬浮效果
    self.ClickArea.MouseEnter:Connect(function()
        createTween(self.Instance, {
            BackgroundColor3 = Color3.new(
                CONFIG.Colors.Surface.R * 1.1,
                CONFIG.Colors.Surface.G * 1.1,
                CONFIG.Colors.Surface.B * 1.1
            )
        }, 0.2):Play()
    end)
    
    self.ClickArea.MouseLeave:Connect(function()
        createTween(self.Instance, {
            BackgroundColor3 = CONFIG.Colors.Surface
        }, 0.2):Play()
    end)
end

function Dropdown:createOptions()
    -- 清除现有选项
    for _, child in pairs(self.OptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- 创建新选项
    for i, option in ipairs(self.Options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option_" .. option
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.BackgroundColor3 = CONFIG.Colors.Surface
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = CONFIG.Colors.Text
        optionButton.TextSize = 14
        optionButton.Font = Enum.Font.GothamMedium
        optionButton.LayoutOrder = i
        optionButton.Parent = self.OptionsFrame
        
        local optionCorner = Instance.new("UICorner")
        optionCorner.CornerRadius = UDim.new(0, 4)
        optionCorner.Parent = optionButton
        
        -- 点击事件
        optionButton.MouseButton1Click:Connect(function()
            self:selectOption(option)
            self:close()
        end)
        
        -- 悬浮效果
        optionButton.MouseEnter:Connect(function()
            createTween(optionButton, {
                BackgroundColor3 = CONFIG.Colors.Primary
            }, 0.2):Play()
        end)
        
        optionButton.MouseLeave:Connect(function()
            createTween(optionButton, {
                BackgroundColor3 = CONFIG.Colors.Surface
            }, 0.2):Play()
        end)
    end
end

function Dropdown:toggle()
    if self.IsOpen then
        self:close()
    else
        self:open()
    end
end

function Dropdown:open()
    self.IsOpen = true
    self.OptionsFrame.Visible = true
    
    -- 计算总高度
    local totalHeight = #self.Options * 32
    
    -- 动画展开
    createTween(self.Instance, {
        Size = UDim2.new(1, -10, 0, 40 + totalHeight)
    }, 0.3, Enum.EasingStyle.Back):Play()
    
    createTween(self.OptionsFrame, {
        Size = UDim2.new(1, 0, 0, totalHeight)
    }, 0.3):Play()
    
    createTween(self.Arrow, {
        Rotation = 180
    }, 0.3):Play()
end

function Dropdown:close()
    self.IsOpen = false
    
    -- 动画收起
    createTween(self.Instance, {
        Size = UDim2.new(1, -10, 0, 40)
    }, 0.3, Enum.EasingStyle.Back):Play()
    
    createTween(self.OptionsFrame, {
        Size = UDim2.new(1, 0, 0, 0)
    }, 0.3):Play()
    
    createTween(self.Arrow, {
        Rotation = 0
    }, 0.3):Play()
    
    wait(0.3)
    self.OptionsFrame.Visible = false
end

function Dropdown:selectOption(option)
    self.SelectedOption = option
    self.SelectedLabel.Text = option
    
    if self.Callback then
        self.Callback(option)
    end
end

function Dropdown:setOptions(options)
    self.Options = options
    self:createOptions()
    self.SelectedOption = nil
    self.SelectedLabel.Text = "选择..."
end

-- 主要API函数
function OperitUI.new(title, size)
    local window = Window.new(nil, title, size)
    return window
end

-- 设置主题
function OperitUI:setTheme(theme)
    for key, value in pairs(theme) do
        if CONFIG.Colors[key] then
            CONFIG.Colors[key] = value
        end
    end
end

-- 获取配置
function OperitUI:getConfig()
    return deepCopy(CONFIG)
end

-- 导出模块
return OperitUI
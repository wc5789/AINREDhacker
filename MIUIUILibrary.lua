-- MIUI风格UI库 v1.0 - 灵动岛版本
-- 适配移动端和电脑端，支持灵动岛开关动画

local MIUIUI = {}
MIUIUI.__index = MIUIUI

-- 设备类型检测
local function isMobile()
    return game:GetService("UserInputService").TouchEnabled
end

-- 创建MIUI风格UI库实例
function MIUIUI.new(config)
    local self = setmetatable({}, MIUIUI)
    
    -- 默认配置
    self.config = config or {}
    self.config.title = self.config.title or "MIUI UI"
    self.config.theme = self.config.theme or "light" -- light/dark
    self.config.accentColor = self.config.accentColor or Color3.fromRGB(0, 122, 255) -- MIUI蓝色
    self.config.toggleKey = self.config.toggleKey or Enum.KeyCode.RightShift
    
    -- 核心组件
    self.elements = {}
    self.pages = {}
    self.currentPage = nil
    self.mainFrame = nil
    self.dynamicIsland = nil
    self.isExpanded = false
    self.isAnimating = false
    
    -- 设备信息
    self.isMobile = isMobile()
    self.screenSize = workspace.CurrentCamera.ViewportSize
    
    -- 初始化
    self:init()
    
    return self
end

-- 初始化UI
function MIUIUI:init()
    -- 创建主ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "MIUIUI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- 根据设备类型设置父级
    local success, err = pcall(function()
        self.screenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        self.screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- 创建灵动岛
    self:createDynamicIsland()
    
    -- 创建主界面
    self:createMainInterface()
    
    -- 设置键盘监听
    self:setupKeybinds()
    
    -- 设置屏幕尺寸监听
    self:setupScreenResize()
    
    -- 初始状态：灵动岛收缩
    self:setIslandState("collapsed")
end

-- 创建灵动岛
function MIUIUI:createDynamicIsland()
    -- 灵动岛容器
    local island = Instance.new("Frame")
    island.Name = "DynamicIsland"
    island.AnchorPoint = Vector2.new(0.5, 0)
    island.Position = UDim2.new(0.5, 0, 0, 20)
    island.Size = UDim2.new(0, 120, 0, 32)
    island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    island.BorderSizePixel = 0
    island.ZIndex = 100
    
    -- 添加圆角（胶囊形状）
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = island
    
    -- 添加阴影效果
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 2)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = 99
    shadow.Parent = island
    
    -- 状态指示器
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Position = UDim2.new(0, 12, 0.5, -3)
    statusIndicator.Size = UDim2.new(0, 6, 0, 6)
    statusIndicator.BackgroundColor3 = self.config.accentColor
    statusIndicator.ZIndex = 101
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = statusIndicator
    
    statusIndicator.Parent = island
    
    -- 标题文本
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Position = UDim2.new(0, 24, 0, 0)
    titleText.Size = UDim2.new(0.6, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = self.config.title
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 12
    titleText.Font = Enum.Font.GothamMedium
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextTruncate = Enum.TextTruncate.AtEnd
    titleText.ZIndex = 101
    titleText.Parent = island
    
    -- 点击区域
    local clickArea = Instance.new("TextButton")
    clickArea.Name = "ClickArea"
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 102
    clickArea.Parent = island
    
    -- 点击事件
    clickArea.MouseButton1Click:Connect(function()
        self:toggleIsland()
    end)
    
    -- 悬浮效果
    clickArea.MouseEnter:Connect(function()
        if not self.isAnimating then
            game:GetService("TweenService"):Create(island, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 130, 0, 36)
            }):Play()
        end
    end)
    
    clickArea.MouseLeave:Connect(function()
        if not self.isAnimating then
            local targetSize = self.isExpanded and UDim2.new(0, 300, 0, 40) or UDim2.new(0, 120, 0, 32)
            game:GetService("TweenService"):Create(island, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = targetSize
            }):Play()
        end
    end)
    
    island.Parent = self.screenGui
    self.dynamicIsland = island
end

-- 设置灵动岛状态
function MIUIUI:setIslandState(state)
    if self.isAnimating then return end
    
    self.isAnimating = true
    local island = self.dynamicIsland
    
    if state == "collapsed" then
        -- 收缩状态
        game:GetService("TweenService"):Create(island, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 120, 0, 32),
            Position = UDim2.new(0.5, 0, 0, 20)
        }):Play()
        
        wait(0.4)
        self.isExpanded = false
        self.isAnimating = false
        
    elseif state == "expanded" then
        -- 展开状态
        local expandedSize = self.isMobile and UDim2.new(0.9, 0, 0, 50) or UDim2.new(0, 300, 0, 40)
        
        game:GetService("TweenService"):Create(island, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = expandedSize,
            Position = UDim2.new(0.5, 0, 0, 20)
        }):Play()
        
        wait(0.4)
        self.isExpanded = true
        self.isAnimating = false
    end
end

-- 切换灵动岛状态
function MIUIUI:toggleIsland()
    if self.isAnimating then return end
    
    if self.isExpanded then
        -- 收起主界面
        self:collapseInterface()
        self:setIslandState("collapsed")
    else
        -- 展开主界面
        self:expandInterface()
        self:setIslandState("expanded")
    end
end

-- 创建主界面
function MIUIUI:createMainInterface()
    -- 主界面容器
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0, 60)
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = false
    mainFrame.ZIndex = 50
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame
    
    -- 添加阴影
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = 49
    shadow.Parent = mainFrame
    
    -- 内容区域
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -40, 1, -80)
    contentFrame.Position = UDim2.new(0, 20, 0, 60)
    contentFrame.BackgroundTransparency = 1
    
    -- 标签页容器
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.Position = UDim2.new(0, 0, 0, 10)
    tabBar.BackgroundTransparency = 1
    
    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabList.Padding = UDim.new(0, 8)
    tabList.Parent = tabBar
    
    tabBar.Parent = contentFrame
    
    -- 内容滚动区域
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, -50)
    scrollFrame.Position = UDim2.new(0, 0, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local contentList = Instance.new("UIListLayout")
    contentList.Padding = UDim.new(0, 8)
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Parent = scrollFrame
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 5)
    contentPadding.PaddingRight = UDim.new(0, 5)
    contentPadding.Parent = scrollFrame
    
    scrollFrame.Parent = contentFrame
    
    contentFrame.Parent = mainFrame
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.AnchorPoint = Vector2.new(0.5, 0)
    closeButton.Position = UDim2.new(0.5, 0, 1, -45)
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(100, 100, 100)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamMedium
    closeButton.ZIndex = 51
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:toggleIsland()
    end)
    
    closeButton.Parent = mainFrame
    
    mainFrame.Parent = self.screenGui
    self.mainFrame = mainFrame
end

-- 展开界面动画
function MIUIUI:expandInterface()
    if self.isAnimating then return end
    
    self.isAnimating = true
    local mainFrame = self.mainFrame
    
    mainFrame.Visible = true
    
    -- 目标尺寸
    local targetSize
    if self.isMobile then
        targetSize = UDim2.new(0.95, 0, 0, 400)
    else
        targetSize = UDim2.new(0, 500, 0, 400)
    end
    
    -- 展开动画
    game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize
    }):Play()
    
    wait(0.5)
    self.isAnimating = false
end

-- 收起界面动画
function MIUIUI:collapseInterface()
    if self.isAnimating then return end
    
    self.isAnimating = true
    local mainFrame = self.mainFrame
    
    -- 收起动画
    game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    wait(0.4)
    mainFrame.Visible = false
    self.isAnimating = false
end

-- 设置键盘监听
function MIUIUI:setupKeybinds()
    game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.config.toggleKey then
            self:toggleIsland()
        end
    end)
end

-- 设置屏幕尺寸监听
function MIUIUI:setupScreenResize()
    local camera = workspace.CurrentCamera
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        self.screenSize = camera.ViewportSize
        self.isMobile = game:GetService("UserInputService").TouchEnabled
        
        -- 调整界面位置
        if self.mainFrame and self.mainFrame.Visible then
            local targetSize
            if self.isMobile then
                targetSize = UDim2.new(0.95, 0, 0, 400)
            else
                targetSize = UDim2.new(0, 500, 0, 400)
            end
            
            game:GetService("TweenService"):Create(self.mainFrame, TweenInfo.new(0.3), {
                Size = targetSize
            }):Play()
        end
    end)
end

-- 创建页面
function MIUIUI:createPage(pageName, icon)
    local page = {}
    page.name = pageName
    page.icon = icon or "•"
    page.elements = {}
    
    -- 创建页面框架
    local pageFrame = Instance.new("Frame")
    pageFrame.Name = pageName.."Page"
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Visible = false
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = pageFrame
    
    pageFrame.Parent = self.mainFrame.ContentFrame.ScrollFrame
    page.frame = pageFrame
    
    -- 创建标签页按钮
    local tabButton = Instance.new("TextButton")
    tabButton.Name = pageName.."Tab"
    tabButton.Size = UDim2.new(0, 80, 0, 30)
    tabButton.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    tabButton.Text = icon.." "..pageName
    tabButton.TextColor3 = Color3.fromRGB(100, 100, 100)
    tabButton.TextSize = 12
    tabButton.Font = Enum.Font.GothamMedium
    tabButton.BorderSizePixel = 0
    tabButton.AutoButtonColor = false
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 15)
    tabCorner.Parent = tabButton
    
    tabButton.MouseButton1Click:Connect(function()
        self:switchPage(page)
    end)
    
    tabButton.Parent = self.mainFrame.ContentFrame.TabBar
    
    page.tabButton = tabButton
    
    table.insert(self.pages, page)
    
    -- 如果是第一个页面，自动显示
    if #self.pages == 1 then
        self:switchPage(page)
    end
    
    return page
end

-- 切换页面
function MIUIUI:switchPage(page)
    -- 隐藏所有页面
    for _, p in ipairs(self.pages) do
        p.frame.Visible = false
        p.tabButton.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        p.tabButton.TextColor3 = Color3.fromRGB(100, 100, 100)
    end
    
    -- 显示选中页面
    page.frame.Visible = true
    page.tabButton.BackgroundColor3 = self.config.accentColor
    page.tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.currentPage = page
end

-- 创建MIUI风格卡片
function MIUIUI:createCard(page, config)
    local cardConfig = {
        title = config.title or "Card",
        subtitle = config.subtitle or "",
        icon = config.icon or nil,
        callback = config.callback or function() end
    }
    
    local card = Instance.new("Frame")
    card.Name = cardConfig.title.."Card"
    card.Size = UDim2.new(1, 0, 0, 70)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = card
    
    -- 图标容器
    if cardConfig.icon then
        local iconContainer = Instance.new("Frame")
        iconContainer.Size = UDim2.new(0, 40, 0, 40)
        iconContainer.Position = UDim2.new(0, 15, 0.5, -20)
        iconContainer.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
        iconContainer.BorderSizePixel = 0
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 12)
        iconCorner.Parent = iconContainer
        
        local iconText = Instance.new("TextLabel")
        iconText.Size = UDim2.new(1, 0, 1, 0)
        iconText.BackgroundTransparency = 1
        iconText.Text = cardConfig.icon
        iconText.TextColor3 = self.config.accentColor
        iconText.TextSize = 18
        iconText.Font = Enum.Font.GothamBold
        iconText.Parent = iconContainer
        
        iconContainer.Parent = card
    end
    
    -- 标题
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(0.6, 0, 0, 20)
    titleText.Position = UDim2.new(0, cardConfig.icon and 65 or 20, 0, 15)
    titleText.BackgroundTransparency = 1
    titleText.Text = cardConfig.title
    titleText.TextColor3 = Color3.fromRGB(50, 50, 50)
    titleText.TextSize = 14
    titleText.Font = Enum.Font.GothamMedium
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextTruncate = Enum.TextTruncate.AtEnd
    titleText.Parent = card
    
    -- 副标题
    if cardConfig.subtitle ~= "" then
        local subtitleText = Instance.new("TextLabel")
        subtitleText.Size = UDim2.new(0.6, 0, 0, 16)
        subtitleText.Position = UDim2.new(0, cardConfig.icon and 65 or 20, 0, 38)
        subtitleText.BackgroundTransparency = 1
        subtitleText.Text = cardConfig.subtitle
        subtitleText.TextColor3 = Color3.fromRGB(150, 150, 150)
        subtitleText.TextSize = 11
        subtitleText.Font = Enum.Font.Gotham
        subtitleText.TextXAlignment = Enum.TextXAlignment.Left
        subtitleText.TextTruncate = Enum.TextTruncate.AtEnd
        subtitleText.Parent = card
    end
    
    -- 箭头
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -35, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "›"
    arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
    arrow.TextSize = 20
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = card
    
    -- 点击效果
    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.Parent = card
    
    clickArea.MouseButton1Click:Connect(function()
        -- 按下动画
        game:GetService("TweenService"):Create(card, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        }):Play()
        
        wait(0.1)
        
        game:GetService("TweenService"):Create(card, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        
        cardConfig.callback()
    end)
    
    clickArea.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(card, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(248, 248, 248)
        }):Play()
    end)
    
    clickArea.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(card, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    card.Parent = page.frame
    table.insert(page.elements, card)
    return card
end

-- 创建MIUI风格开关
function MIUIUI:createSwitch(page, config)
    local switchConfig = {
        title = config.title or "Switch",
        subtitle = config.subtitle or "",
        icon = config.icon or nil,
        default = config.default or false,
        callback = config.callback or function() end
    }
    
    local switchFrame = Instance.new("Frame")
    switchFrame.Name = switchConfig.title.."Switch"
    switchFrame.Size = UDim2.new(1, 0, 0, 70)
    switchFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    switchFrame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = switchFrame
    
    -- 图标容器
    if switchConfig.icon then
        local iconContainer = Instance.new("Frame")
        iconContainer.Size = UDim2.new(0, 40, 0, 40)
        iconContainer.Position = UDim2.new(0, 15, 0.5, -20)
        iconContainer.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
        iconContainer.BorderSizePixel = 0
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 12)
        iconCorner.Parent = iconContainer
        
        local iconText = Instance.new("TextLabel")
        iconText.Size = UDim2.new(1, 0, 1, 0)
        iconText.BackgroundTransparency = 1
        iconText.Text = switchConfig.icon
        iconText.TextColor3 = self.config.accentColor
        iconText.TextSize = 18
        iconText.Font = Enum.Font.GothamBold
        iconText.Parent = iconContainer
        
        iconContainer.Parent = switchFrame
    end
    
    -- 标题
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.6, 0, 0, 20)
    titleText.Position = UDim2.new(0, switchConfig.icon and 65 or 20, 0, 15)
    titleText.BackgroundTransparency = 1
    titleText.Text = switchConfig.title
    titleText.TextColor3 = Color3.fromRGB(50, 50, 50)
    titleText.TextSize = 14
    titleText.Font = Enum.Font.GothamMedium
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextTruncate = Enum.TextTruncate.AtEnd
    titleText.Parent = switchFrame
    
    -- 副标题
    if switchConfig.subtitle ~= "" then
        local subtitleText = Instance.new("TextLabel")
        subtitleText.Size = UDim2.new(0.6, 0, 0, 16)
        subtitleText.Position = UDim2.new(0, switchConfig.icon and 65 or 20, 0, 38)
        subtitleText.BackgroundTransparency = 1
        subtitleText.Text = switchConfig.subtitle
        subtitleText.TextColor3 = Color3.fromRGB(150, 150, 150)
        subtitleText.TextSize = 11
        subtitleText.Font = Enum.Font.Gotham
        subtitleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.TextTruncate = Enum.TextTruncate.AtEnd
        subtitleText.Parent = switchFrame
    end
    
    -- 开关按钮
    local switchButton = Instance.new("TextButton")
    switchButton.Size = UDim2.new(0, 50, 0, 28)
    switchButton.Position = UDim2.new(1, -65, 0.5, -14)
    switchButton.BackgroundColor3 = switchConfig.default and self.config.accentColor or Color3.fromRGB(220, 220, 220)
    switchButton.Text = ""
    switchButton.BorderSizePixel = 0
    
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchButton
    
    -- 开关滑块
    local switchCircle = Instance.new("Frame")
    switchCircle.Size = UDim2.new(0, 22, 0, 22)
    switchCircle.Position = switchConfig.default and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    switchCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    switchCircle.BorderSizePixel = 0
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = switchCircle
    
    -- 添加阴影
    local circleShadow = Instance.new("ImageLabel")
    circleShadow.Size = UDim2.new(1, 8, 1, 8)
    circleShadow.Position = UDim2.new(0, -4, 0, -2)
    circleShadow.BackgroundTransparency = 1
    circleShadow.Image = "rbxassetid://5554236805"
    circleShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    circleShadow.ImageTransparency = 0.7
    circleShadow.ScaleType = Enum.ScaleType.Slice
    circleShadow.SliceCenter = Rect.new(23, 23, 277, 277)
    circleShadow.ZIndex = -1
    circleShadow.Parent = switchCircle
    
    switchCircle.Parent = switchButton
    
    local isToggled = switchConfig.default
    
    -- 更新开关状态
    local function updateSwitch()
        if isToggled then
            game:GetService("TweenService"):Create(switchButton, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundColor3 = self.config.accentColor
            }):Play()
            
            game:GetService("TweenService"):Create(switchCircle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -25, 0.5, -11)
            }):Play()
        else
            game:GetService("TweenService"):Create(switchButton, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(220, 220, 220)
            }):Play()
            
            game:GetService("TweenService"):Create(switchCircle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -11)
            }):Play()
        end
        
        switchConfig.callback(isToggled)
    end
    
    switchButton.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        updateSwitch()
    end)
    
    switchButton.Parent = switchFrame
    switchFrame.Parent = page.frame
    
    table.insert(page.elements, switchFrame)
    return switchFrame
end

-- 创建MIUI风格滑块
function MIUIUI:createSlider(page, config)
    local sliderConfig = {
        title = config.title or "Slider",
        subtitle = config.subtitle or "",
        icon = config.icon or nil,
        min = config.min or 0,
        max = config.max or 100,
        default = config.default or 50,
        callback = config.callback or function() end
    }
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = sliderConfig.title.."Slider"
    sliderFrame.Size = UDim2.new(1, 0, 0, 80)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderFrame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = sliderFrame
    
    -- 图标容器
    if sliderConfig.icon then
        local iconContainer = Instance.new("Frame")
        iconContainer.Size = UDim2.new(0, 40, 0, 40)
        iconContainer.Position = UDim2.new(0, 15, 0, 15)
        iconContainer.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
        iconContainer.BorderSizePixel = 0
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 12)
        iconCorner.Parent = iconContainer
        
        local iconText = Instance.new("TextLabel")
        iconText.Size = UDim2.new(1, 0, 1, 0)
        iconText.BackgroundTransparency = 1
        iconText.Text = sliderConfig.icon
        iconText.TextColor3 = self.config.accentColor
        iconText.TextSize = 18
        iconText.Font = Enum.Font.GothamBold
        iconText.Parent = iconContainer
        
        iconContainer.Parent = sliderFrame
    end
    
    -- 标题
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.6, 0, 0, 20)
    titleText.Position = UDim2.new(0, sliderConfig.icon and 65 or 20, 0, 15)
    titleText.BackgroundTransparency = 1
    titleText.Text = sliderConfig.title
    titleText.TextColor3 = Color3.fromRGB(50, 50, 50)
    titleText.TextSize = 14
    titleText.Font = Enum.Font.GothamMedium
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextTruncate = Enum.TextTruncate.AtEnd
    titleText.Parent = sliderFrame
    
    -- 数值显示
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0.3, -20, 0, 20)
    valueText.Position = UDim2.new(0.7, 0, 0, 15)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(sliderConfig.default)
    valueText.TextColor3 = self.config.accentColor
    valueText.TextSize = 14
    valueText.Font = Enum.Font.GothamBold
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Parent = sliderFrame
    
    -- 副标题
    if sliderConfig.subtitle ~= "" then
        local subtitleText = Instance.new("TextLabel")
        subtitleText.Size = UDim2.new(0.6, 0, 0, 16)
        subtitleText.Position = UDim2.new(0, sliderConfig.icon and 65 or 20, 0, 38)
        subtitleText.BackgroundTransparency = 1
        subtitleText.Text = sliderConfig.subtitle
        subtitleText.TextColor3 = Color3.fromRGB(150, 150, 150)
        subtitleText.TextSize = 11
        subtitleText.Font = Enum.Font.Gotham
        subtitleText.TextXAlignment = Enum.TextXAlignment.Left
        subtitleText.TextTruncate = Enum.TextTruncate.AtEnd
        subtitleText.Parent = sliderFrame
    end
    
    -- 滑块轨道
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -40, 0, 4)
    sliderTrack.Position = UDim2.new(0, 20, 0, 65)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    sliderTrack.BorderSizePixel = 0
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = sliderTrack
    
    -- 滑块填充
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = self.config.accentColor
    sliderFill.BorderSizePixel = 0
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    sliderFill.Parent = sliderTrack
    
    -- 滑块滑块
    local sliderThumb = Instance.new("TextButton")
    sliderThumb.Size = UDim2.new(0, 20, 0, 20)
    sliderThumb.Position = UDim2.new(0, -10, 0.5, -10)
    sliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderThumb.Text = ""
    sliderThumb.BorderSizePixel = 0
    sliderThumb.AutoButtonColor = false
    
    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = sliderThumb
    
    -- 滑块阴影
    local thumbShadow = Instance.new("ImageLabel")
    thumbShadow.Size = UDim2.new(1, 10, 1, 10)
    thumbShadow.Position = UDim2.new(0, -5, 0, -3)
    thumbShadow.BackgroundTransparency = 1
    thumbShadow.Image = "rbxassetid://5554236805"
    thumbShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    thumbShadow.ImageTransparency = 0.7
    thumbShadow.ScaleType = Enum.ScaleType.Slice
    thumbShadow.SliceCenter = Rect.new(23, 23, 277, 277)
    thumbShadow.ZIndex = -1
    thumbShadow.Parent = sliderThumb
    
    sliderThumb.Parent = sliderFill
    
    sliderTrack.Parent = sliderFrame
    
    local currentValue = sliderConfig.default
    local dragging = false
    
    -- 更新滑块值
    local function updateSlider(value)
        local percentage = math.clamp((value - sliderConfig.min) / (sliderConfig.max - sliderConfig.min), 0, 1)
        currentValue = math.floor(sliderConfig.min + (sliderConfig.max - sliderConfig.min) * percentage)
        
        game:GetService("TweenService"):Create(sliderFill, TweenInfo.new(0.1), {
            Size = UDim2.new(percentage, 0, 1, 0)
        }):Play()
        
        valueText.Text = tostring(currentValue)
        sliderConfig.callback(currentValue)
    end
    
    -- 鼠标拖动
    sliderThumb.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            local trackPos = sliderTrack.AbsolutePosition
            local trackSize = sliderTrack.AbsoluteSize
            
            local percentage = math.clamp((mousePos.X - trackPos.X) / trackSize.X, 0, 1)
            local value = sliderConfig.min + (sliderConfig.max - sliderConfig.min) * percentage
            
            updateSlider(value)
        end
    end)
    
    -- 初始化
    updateSlider(sliderConfig.default)
    
    sliderFrame.Parent = page.frame
    table.insert(page.elements, sliderFrame)
    return sliderFrame
end

-- 创建MIUI风格按钮
function MIUIUI:createButton(page, config)
    local buttonConfig = {
        text = config.text or "Button",
        icon = config.icon or nil,
        style = config.style or "primary", -- primary/secondary/danger
        callback = config.callback or function() end
    }
    
    local button = Instance.new("TextButton")
    button.Name = buttonConfig.text.."Button"
    button.Size = UDim2.new(1, 0, 0, 50)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    
    -- 根据样式设置颜色
    local bgColor, textColor
    if buttonConfig.style == "primary" then
        bgColor = self.config.accentColor
        textColor = Color3.fromRGB(255, 255, 255)
    elseif buttonConfig.style == "secondary" then
        bgColor = Color3.fromRGB(240, 240, 240)
        textColor = Color3.fromRGB(50, 50, 50)
    else -- danger
        bgColor = Color3.fromRGB(255, 59, 48)
        textColor = Color3.fromRGB(255, 255, 255)
    end
    
    button.BackgroundColor3 = bgColor
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    
    -- 图标
    if buttonConfig.icon then
        local iconText = Instance.new("TextLabel")
        iconText.Size = UDim2.new(0, 20, 0, 20)
        iconText.Position = UDim2.new(0, 20, 0.5, -10)
        iconText.BackgroundTransparency = 1
        iconText.Text = buttonConfig.icon
        iconText.TextColor3 = textColor
        iconText.TextSize = 16
        iconText.Font = Enum.Font.GothamBold
        iconText.Parent = button
    end
    
    -- 按钮文本
    local buttonText = Instance.new("TextLabel")
    buttonText.Size = UDim2.new(1, buttonConfig.icon and -60 or -40, 1, 0)
    buttonText.Position = UDim2.new(0, buttonConfig.icon and 50 or 20, 0, 0)
    buttonText.BackgroundTransparency = 1
    buttonText.Text = buttonConfig.text
    buttonText.TextColor3 = textColor
    buttonText.TextSize = 14
    buttonText.Font = Enum.Font.GothamMedium
    buttonText.TextXAlignment = Enum.TextXAlignment.Left
    buttonText.Parent = button
    
    -- 点击效果
    button.MouseButton1Click:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        }):Play()
        
        wait(0.1)
        
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = bgColor
        }):Play()
        
        buttonConfig.callback()
    end)
    
    button.Parent = page.frame
    table.insert(page.elements, button)
    return button
end

-- 返回MIUI风格UI库实例
return MIUIUI
-- Roblox UI Library v1.0 - Neon Glass Style
-- 基于OOP模式的现代UI库

local UILibrary = {}
UILibrary.__index = UILibrary

-- 创建UI库实例
function UILibrary.new(config)
    local self = setmetatable({}, UILibrary)
    
    -- 默认配置
    self.config = config or {}
    self.config.title = self.config.title or "UI Library"
    self.config.size = self.config.size or {500, 330}
    self.config.toggleKey = self.config.toggleKey or Enum.KeyCode.RightShift
    
    -- 核心组件
    self.elements = {}
    self.pages = {}
    self.currentPage = nil
    self.window = nil
    self.toggleButton = nil
    
    -- 初始化
    self:init()
    
    return self
end

-- 初始化UI
function UILibrary:init()
    -- 创建主ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "UILibrary"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- 优先挂载到CoreGui，降级到PlayerGui
    local success, err = pcall(function()
        self.screenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        self.screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- 创建悬浮按钮
    self:createToggleButton()
    
    -- 创建主窗口
    self:createMainWindow()
    
    -- 设置键盘监听
    self:setupKeybinds()
end

-- 创建悬浮按钮
function UILibrary:createToggleButton()
    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.Size = UDim2.new(0, 46, 0, 46)
    button.Position = UDim2.new(0.5, -23, 0, 10)
    button.BackgroundColor3 = Color3.fromRGB(254, 74, 161)
    button.Text = "★"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 24
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button
    
    -- 添加霓虹光晕效果
    local glow = Instance.new("UIStroke")
    glow.Color = Color3.fromRGB(254, 74, 161)
    glow.Thickness = 2
    glow.Transparency = 0.5
    glow.Parent = button
    
    -- 设置父级
    button.Parent = self.screenGui
    
    -- 添加拖拽功能
    self:addDrag(button)
    
    -- 点击事件
    button.MouseButton1Click:Connect(function()
        self:toggleWindow()
    end)
    
    -- 悬浮效果
    button.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 50, 0, 50),
            Position = UDim2.new(0.5, -25, 0, 8)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 46, 0, 46),
            Position = UDim2.new(0.5, -23, 0, 10)
        }):Play()
    end)
    
    self.toggleButton = button
end

-- 创建主窗口
function UILibrary:createMainWindow()
    local window = Instance.new("Frame")
    window.Name = "MainWindow"
    window.Size = UDim2.new(0, self.config.size[1], 0, self.config.size[2])
    window.Position = UDim2.new(0.5, -self.config.size[1]/2, 0.5, -self.config.size[2]/2)
    window.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    window.BackgroundTransparency = 0.3
    window.BorderSizePixel = 0
    window.Visible = false
    
    -- 添加玻璃效果
    local glassEffect = Instance.new("Frame")
    glassEffect.Name = "GlassEffect"
    glassEffect.Size = UDim2.new(1, 0, 1, 0)
    glassEffect.BackgroundColor3 = Color3.fromRGB(254, 74, 161)
    glassEffect.BackgroundTransparency = 0.95
    glassEffect.BorderSizePixel = 0
    glassEffect.Parent = window
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = window
    
    -- 添加边框
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(254, 74, 161)
    border.Thickness = 1
    border.Transparency = 0.7
    border.Parent = window
    
    -- 创建标题栏
    self:createTitleBar(window)
    
    -- 创建内容区域
    self:createContentArea(window)
    
    -- 设置父级
    window.Parent = self.screenGui
    
    -- 添加拖拽功能
    self:addDrag(window)
    
    self.window = window
end

-- 创建标题栏
function UILibrary:createTitleBar(parent)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    titleBar.BackgroundTransparency = 0.5
    titleBar.BorderSizePixel = 0
    
    -- 标题文本
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(0.8, 0, 1, 0)
    titleText.Position = UDim2.new(0.1, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = self.config.title
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:toggleWindow()
    end)
    
    closeBtn.Parent = titleBar
    
    titleBar.Parent = parent
end

-- 创建内容区域
function UILibrary:createContentArea(parent)
    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    
    -- 添加滚动框架
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(254, 74, 161)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Name = "ListLayout"
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    scrollFrame.Parent = content
    content.Parent = parent
end

-- 切换窗口显示
function UILibrary:toggleWindow()
    if self.window.Visible then
        -- 关闭动画
        game:GetService("TweenService"):Create(self.window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        wait(0.3)
        self.window.Visible = false
        self.window.Size = UDim2.new(0, self.config.size[1], 0, self.config.size[2])
        self.window.Position = UDim2.new(0.5, -self.config.size[1]/2, 0.5, -self.config.size[2]/2)
    else
        -- 打开动画
        self.window.Visible = true
        self.window.Size = UDim2.new(0, 0, 0, 0)
        self.window.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        game:GetService("TweenService"):Create(self.window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, self.config.size[1], 0, self.config.size[2]),
            Position = UDim2.new(0.5, -self.config.size[1]/2, 0.5, -self.config.size[2]/2)
        }):Play()
    end
end

-- 添加拖拽功能
function UILibrary:addDrag(element)
    local dragging = false
    local dragInput, dragStart, startPos
    
    element.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = element.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    element.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            element.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 设置键盘监听
function UILibrary:setupKeybinds()
    game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.config.toggleKey then
            self:toggleWindow()
        end
    end)
end

-- 创建页面
function UILibrary:createPage(pageName)
    local page = {}
    page.name = pageName
    page.elements = {}
    
    -- 创建页面框架
    local pageFrame = Instance.new("Frame")
    pageFrame.Name = pageName.."Page"
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Visible = false
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = pageFrame
    
    pageFrame.Parent = self.window.ContentArea.ScrollFrame
    page.frame = pageFrame
    
    -- 创建标签页按钮
    local tabButton = Instance.new("TextButton")
    tabButton.Name = pageName.."Tab"
    tabButton.Size = UDim2.new(0, 100, 0, 30)
    tabButton.BackgroundColor3 = Color3.fromRGB(254, 74, 161)
    tabButton.BackgroundTransparency = 0.7
    tabButton.Text = pageName
    tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.TextSize = 14
    tabButton.Font = Enum.Font.GothamMedium
    tabButton.BorderSizePixel = 0
    tabButton.AutoButtonColor = false
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 5)
    tabCorner.Parent = tabButton
    
    tabButton.MouseButton1Click:Connect(function()
        self:switchPage(page)
    end)
    
    tabButton.Parent = self.window.ContentArea.ScrollFrame
    
    page.tabButton = tabButton
    
    table.insert(self.pages, page)
    
    -- 如果是第一个页面，自动显示
    if #self.pages == 1 then
        self:switchPage(page)
    end
    
    return page
end

-- 切换页面
function UILibrary:switchPage(page)
    -- 隐藏所有页面
    for _, p in ipairs(self.pages) do
        p.frame.Visible = false
        p.tabButton.BackgroundTransparency = 0.7
    end
    
    -- 显示选中页面
    page.frame.Visible = true
    page.tabButton.BackgroundTransparency = 0.3
    self.currentPage = page
end

-- 创建按钮组件
function UILibrary:createButton(page, config)
    local buttonConfig = {
        text = config.text or "Button",
        callback = config.callback or function() end,
        size = config.size or {1, 0, 0, 35}
    }
    
    local button = Instance.new("TextButton")
    button.Name = buttonConfig.text.."Button"
    button.Size = UDim2.new(buttonConfig.size[1], buttonConfig.size[2], 0, buttonConfig.size[3])
    button.BackgroundColor3 = Color3.fromRGB(254, 74, 161)
    button.BackgroundTransparency = 0.5
    button.Text = buttonConfig.text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.GothamMedium
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    -- 点击效果
    button.MouseButton1Click:Connect(function()
        -- 按下动画
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.1), {
            BackgroundTransparency = 0.3
        }):Play()
        
        wait(0.1)
        
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.1), {
            BackgroundTransparency = 0.5
        }):Play()
        
        buttonConfig.callback()
    end)
    
    button.Parent = page.frame
    
    table.insert(page.elements, button)
    return button
end

-- 创建开关组件
function UILibrary:createToggle(page, config)
    local toggleConfig = {
        text = config.text or "Toggle",
        default = config.default or false,
        callback = config.callback or function() end
    }
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = toggleConfig.text.."Toggle"
    toggleFrame.Size = UDim2.new(1, 0, 0, 35)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    toggleFrame.BackgroundTransparency = 0.5
    toggleFrame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggleFrame
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, 10, 1, 0)
    labelText.Position = UDim2.new(0, 10, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = toggleConfig.text
    labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
    labelText.TextSize = 14
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = toggleFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 40, 0, 20)
    toggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggleButton.Text = ""
    toggleButton.BorderSizePixel = 0
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.BorderSizePixel = 0
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    
    toggleCircle.Parent = toggleButton
    
    local isToggled = toggleConfig.default
    
    -- 更新开关状态
    local function updateToggle()
        if isToggled then
            game:GetService("TweenService"):Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(254, 74, 161)
            }):Play()
            
            game:GetService("TweenService"):Create(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -18, 0.5, -8)
            }):Play()
        else
            game:GetService("TweenService"):Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            }):Play()
            
            game:GetService("TweenService"):Create(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 2, 0.5, -8)
            }):Play()
        end
        
        toggleConfig.callback(isToggled)
    end
    
    toggleButton.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        updateToggle()
    end)
    
    toggleButton.Parent = toggleFrame
    toggleFrame.Parent = page.frame
    
    table.insert(page.elements, toggleFrame)
    return toggleFrame
end

-- 创建滑块组件
function UILibrary:createSlider(page, config)
    local sliderConfig = {
        text = config.text or "Slider",
        min = config.min or 0,
        max = config.max or 100,
        default = config.default or 50,
        callback = config.callback or function() end
    }
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = sliderConfig.text.."Slider"
    sliderFrame.Size = UDim2.new(1, 0, 0, 44)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    sliderFrame.BackgroundTransparency = 0.5
    sliderFrame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = sliderFrame
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, 10, 0, 20)
    labelText.Position = UDim2.new(0, 10, 0, 5)
    labelText.BackgroundTransparency = 1
    labelText.Text = sliderConfig.text
    labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
    labelText.TextSize = 14
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = sliderFrame
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0.3, -10, 0, 20)
    valueText.Position = UDim2.new(0.7, 0, 0, 5)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(sliderConfig.default)
    valueText.TextColor3 = Color3.fromRGB(254, 74, 161)
    valueText.TextSize = 14
    valueText.Font = Enum.Font.GothamBold
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Parent = sliderFrame
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -20, 0, 8)
    sliderTrack.Position = UDim2.new(0, 10, 0, 30)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    sliderTrack.BorderSizePixel = 0
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = sliderTrack
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(254, 74, 161)
    sliderFill.BorderSizePixel = 0
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    sliderFill.Parent = sliderTrack
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 16, 0, 16)
    sliderButton.Position = UDim2.new(0, -8, 0.5, -8)
    sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderButton.Text = ""
    sliderButton.BorderSizePixel = 0
    sliderButton.AutoButtonColor = false
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = sliderButton
    
    sliderButton.Parent = sliderFill
    
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
    sliderButton.MouseButton1Down:Connect(function()
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

-- 创建下拉菜单组件
function UILibrary:createDropdown(page, config)
    local dropdownConfig = {
        text = config.text or "Dropdown",
        options = config.options or {"Option 1", "Option 2", "Option 3"},
        default = config.default or nil,
        callback = config.callback or function() end
    }
    
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = dropdownConfig.text.."Dropdown"
    dropdownFrame.Size = UDim2.new(1, 0, 0, 35)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    dropdownFrame.BackgroundTransparency = 0.5
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.ClipsDescendants = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = dropdownFrame
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, 10, 0, 35)
    labelText.Position = UDim2.new(0, 10, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = dropdownConfig.text
    labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
    labelText.TextSize = 14
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = dropdownFrame
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Size = UDim2.new(0.3, -10, 0, 25)
    dropdownButton.Position = UDim2.new(0.7, 0, 0, 5)
    dropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    dropdownButton.Text = dropdownConfig.default or dropdownConfig.options[1]
    dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownButton.TextSize = 12
    dropdownButton.Font = Enum.Font.GothamMedium
    dropdownButton.BorderSizePixel = 0
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = dropdownButton
    
    dropdownButton.Parent = dropdownFrame
    
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(1, 0, 0, #dropdownConfig.options * 25)
    optionsFrame.Position = UDim2.new(0, 0, 0, 35)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    optionsFrame.BackgroundTransparency = 0.3
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    
    local optionsCorner = Instance.new("UICorner")
    optionsCorner.CornerRadius = UDim.new(0, 4)
    optionsCorner.Parent = optionsFrame
    
    local optionsList = Instance.new("UIListLayout")
    optionsList.Padding = UDim.new(0, 2)
    optionsList.SortOrder = Enum.SortOrder.LayoutOrder
    optionsList.Parent = optionsFrame
    
    for i, option in ipairs(dropdownConfig.options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 25)
        optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        optionButton.BackgroundTransparency = 0.5
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.TextSize = 12
        optionButton.Font = Enum.Font.GothamMedium
        optionButton.BorderSizePixel = 0
        
        local optCorner = Instance.new("UICorner")
        optCorner.CornerRadius = UDim.new(0, 3)
        optCorner.Parent = optionButton
        
        optionButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = option
            optionsFrame.Visible = false
            dropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            dropdownConfig.callback(option)
        end)
        
        optionButton.Parent = optionsFrame
    end
    
    optionsFrame.Parent = dropdownFrame
    
    dropdownButton.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
        if optionsFrame.Visible then
            dropdownFrame.Size = UDim2.new(1, 0, 0, 35 + #dropdownConfig.options * 25 + 5)
        else
            dropdownFrame.Size = UDim2.new(1, 0, 0, 35)
        end
    end)
    
    dropdownFrame.Parent = page.frame
    table.insert(page.elements, dropdownFrame)
    return dropdownFrame
end

-- 创建输入框组件
function UILibrary:createInput(page, config)
    local inputConfig = {
        text = config.text or "Input",
        placeholder = config.placeholder or "Enter text...",
        callback = config.callback or function() end
    }
    
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = inputConfig.text.."Input"
    inputFrame.Size = UDim2.new(1, 0, 0, 35)
    inputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    inputFrame.BackgroundTransparency = 0.5
    inputFrame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = inputFrame
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.3, 10, 0, 35)
    labelText.Position = UDim2.new(0, 10, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = inputConfig.text
    labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
    labelText.TextSize = 14
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = inputFrame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.65, -10, 0, 25)
    textBox.Position = UDim2.new(0.3, 0, 0.5, -12.5)
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    textBox.Text = ""
    textBox.PlaceholderText = inputConfig.placeholder
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 12
    textBox.Font = Enum.Font.GothamMedium
    textBox.ClearTextOnFocus = false
    textBox.BorderSizePixel = 0
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = textBox
    
    textBox.FocusLost:Connect(function(enterPressed)
        inputConfig.callback(textBox.Text)
    end)
    
    textBox.Parent = inputFrame
    inputFrame.Parent = page.frame
    
    table.insert(page.elements, inputFrame)
    return inputFrame
end

-- 返回UI库实例
return UILibrary
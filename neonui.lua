-- [[ Neon Eclipse Premium Roblox UI Library ]] --
local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 获取最佳 GUI 容器
local function GetGuiParent()
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success and coreGui then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- 物理缓动封装 (更丝滑的动画曲线)
local function Animate(obj, duration, style, dir, properties)
    local info = TweenInfo.new(duration, style, dir)
    local tween = TweenService:Create(obj, info, properties)
    tween:Play()
    return tween
end

-- 拖拽机制封装 (支持惯性拖拽)
local function MakeDraggable(dragFrame, targetFrame)
    local dragging, dragInput, dragStart, startPos
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Animate(targetFrame, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
        end
    end)
end

function Library:CreateWindow(titleText, accentColor)
    titleText = titleText or "NEON ECLIPSE"
    accentColor = accentColor or Color3.fromRGB(0, 190, 255) -- 极光蓝
    local accentPurple = Color3.fromRGB(150, 80, 255) -- 电光紫 (用于双色渐变)

    -- 1. 创建顶层 ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NeonEclipse_" .. math.random(1000, 9999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetGuiParent()

    -- 销毁旧 UI
    for _, old in ipairs(GetGuiParent():GetChildren()) do
        if old.Name:match("^NeonEclipse_") and old ~= ScreenGui then
            old:Destroy()
        end
    end

    -- 黄金比例尺寸 (Medium Size)
    local originalSize = UDim2.new(0, 550, 0, 360)
    local lastWindowPosition = UDim2.new(0.5, -275, 0.5, -180) -- 记录最大化时的位置

    -- 2. 创建极光悬浮球 (Floating Switch Toggle)
    local FloatingToggle = Instance.new("Frame")
    FloatingToggle.Name = "FloatingToggle"
    FloatingToggle.Size = UDim2.new(0, 50, 0, 50)
    FloatingToggle.Position = UDim2.new(0.9, 0, 0.15, 0)
    FloatingToggle.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    FloatingToggle.BorderSizePixel = 0
    FloatingToggle.ZIndex = 10
    FloatingToggle.Parent = ScreenGui

    local FloatCorner = Instance.new("UICorner")
    FloatCorner.CornerRadius = UDim.new(1, 0)
    FloatCorner.Parent = FloatingToggle

    local FloatStroke = Instance.new("UIStroke")
    FloatStroke.Thickness = 2
    FloatStroke.Color = accentColor
    FloatStroke.Parent = FloatingToggle

    -- 悬浮球内的炫酷 Icon 装饰
    local FloatIcon = Instance.new("TextLabel")
    FloatIcon.Size = UDim2.new(1, 0, 1, 0)
    FloatIcon.BackgroundTransparency = 1
    FloatIcon.Text = "⚡"
    FloatIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    FloatIcon.TextSize = 20
    FloatIcon.Font = Enum.Font.GothamBold
    FloatIcon.Parent = FloatingToggle

    -- 悬浮球拖拽及点击事件
    MakeDraggable(FloatingToggle, FloatingToggle)

    -- 3. 主窗口容器 (CanvasGroup 用于完美的全局淡入淡出和缩放)
    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = originalSize
    MainFrame.Position = lastWindowPosition
    MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    MainFrame.BorderSizePixel = 0
    MainFrame.GroupTransparency = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame

    -- 霓虹发光双色边框
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = accentColor
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    -- 【吸入/弹出核心动画控制】
    local isMinimized = false
    local animating = false

    local function ToggleUI()
        if animating then return end
        animating = true
        isMinimized = not isMinimized

        if isMinimized then
            -- 记录当前窗口位置，以便原样弹回
            lastWindowPosition = MainFrame.Position
            -- 悬浮球闪烁反馈
            Animate(FloatStroke, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentPurple})
            
            -- 窗口缩小并向悬浮球吸入
            local shrinkTween = Animate(MainFrame, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(FloatingToggle.Position.X.Scale, FloatingToggle.Position.X.Offset + 25, FloatingToggle.Position.Y.Scale, FloatingToggle.Position.Y.Offset + 25),
                GroupTransparency = 1
            })
            
            shrinkTween.Completed:Connect(function()
                MainFrame.Visible = false
                animating = false
            end)
            Animate(FloatingToggle, 0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, {Size = UDim2.new(0, 56, 0, 56)})
        else
            MainFrame.Visible = true
            Animate(FloatStroke, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
            
            -- 从悬浮球当前位置“弹出”并恢复
            MainFrame.Position = UDim2.new(FloatingToggle.Position.X.Scale, FloatingToggle.Position.X.Offset + 25, FloatingToggle.Position.Y.Scale, FloatingToggle.Position.Y.Offset + 25)
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.GroupTransparency = 1

            local expandTween = Animate(MainFrame, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                Size = originalSize,
                Position = lastWindowPosition,
                GroupTransparency = 0
            })
            
            expandTween.Completed:Connect(function()
                animating = false
            end)
            Animate(FloatingToggle, 0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, {Size = UDim2.new(0, 50, 0, 50)})
        end
    end

    -- 悬浮球点击 (仅当不是在剧烈拖拽时触发)
    local dragThreshold = 5
    local clickStartPos
    FloatingToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickStartPos = input.Position
        end
    end)
    FloatingToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if clickStartPos then
                local dist = (input.Position - clickStartPos).Magnitude
                if dist < dragThreshold then
                    ToggleUI()
                end
            end
        end
    end)

    -- 4. 窗口顶部栏 (TopBar)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12)
    TopBarCorner.Parent = TopBar

    -- 标题 (支持霓虹渐变感)
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 18, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText:upper()
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.MontserratBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    -- 最小化按钮 (点击也会触发吸入动画)
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -75, 0.5, -15)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Text = "—"
    MinimizeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    MinimizeBtn.TextSize = 14
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Parent = TopBar

    MinimizeBtn.MouseEnter:Connect(function() Animate(MinimizeBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = accentColor}) end)
    MinimizeBtn.MouseLeave:Connect(function() Animate(MinimizeBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(150, 150, 150)}) end)
    MinimizeBtn.MouseButton1Click:Connect(ToggleUI)

    -- 关闭按钮
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    CloseBtn.TextSize = 20
    CloseBtn.Font = Enum.Font.GothamMedium
    CloseBtn.Parent = TopBar

    CloseBtn.MouseEnter:Connect(function() Animate(CloseBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(255, 75, 75)}) end)
    CloseBtn.MouseLeave:Connect(function() Animate(CloseBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(150, 150, 150)}) end)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    MakeDraggable(TopBar, MainFrame)

    -- 5. 侧边导航栏 (Tab List)
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Size = UDim2.new(0, 140, 1, -42)
    SideBar.Position = UDim2.new(0, 0, 0, 42)
    SideBar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    SideBar.BorderSizePixel = 0
    SideBar.Parent = MainFrame

    local SideBarLine = Instance.new("Frame")
    SideBarLine.Size = UDim2.new(0, 1, 1, 0)
    SideBarLine.Position = UDim2.new(1, -1, 0, 0)
    SideBarLine.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    SideBarLine.BorderSizePixel = 0
    SideBarLine.Parent = SideBar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -10, 1, -20)
    TabContainer.Position = UDim2.new(0, 5, 0, 10)
    TabContainer.BackgroundTransparency = 1
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = SideBar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.Parent = TabContainer

    -- 6. 右侧主内容区 (Pages)
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -155, 1, -55)
    ContentFrame.Position = UDim2.new(0, 150, 0, 50)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    local Pages = {}
    local CurrentTab = nil

    function Pages:CreateTab(tabName)
        tabName = tabName or "Tab"
        
        -- 创建 Page 容器
        local Page = Instance.new("ScrollingFrame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Color3.fromRGB(45, 45, 50)
        Page.Visible = false
        Page.Parent = ContentFrame

        local PageList = Instance.new("UIListLayout")
        PageList.Padding = UDim.new(0, 8)
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Parent = Page
        
        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 15)
        end)

        -- 侧边栏按钮 (高级悬停动画)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 34)
        TabBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "   " .. tabName
        TabBtn.TextColor3 = Color3.fromRGB(130, 130, 140)
        TabBtn.TextSize = 12
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabContainer

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 6)
        TabBtnCorner.Parent = TabBtn

        -- 霓虹小滑块，高亮当前的 Tab
        local Indicator = Instance.new("Frame")
        Indicator.Size = UDim2.new(0, 3, 0.5, 0)
        Indicator.Position = UDim2.new(0, 0, 0.25, 0)
        Indicator.BackgroundColor3 = accentColor
        Indicator.BorderSizePixel = 0
        Indicator.BackgroundTransparency = 1
        Indicator.Parent = TabBtn

        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(1, 0)
        IndicatorCorner.Parent = Indicator

        local function Select()
            for _, child in ipairs(ContentFrame:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            for _, btn in ipairs(TabContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    Animate(btn, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(130, 130, 140), BackgroundTransparency = 1})
                    Animate(btn.Indicator, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
                end
            end
            
            -- 淡入显示当前 Page
            Page.Visible = true
            Animate(TabBtn, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(24, 24, 28)})
            Animate(Indicator, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {BackgroundTransparency = 0})
        end

        TabBtn.MouseButton1Click:Connect(Select)

        if CurrentTab == nil then
            CurrentTab = tabName
            Select()
        end

        local TabElements = {}

        -- [[ 1. Premium Label ]]
        function TabElements:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, -10, 0, 24)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = Page

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(170, 170, 180)
            Label.TextSize = 12
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = LabelFrame
            
            local Elements = {}
            function Elements:Update(newText)
                Label.Text = newText
            end
            return Elements
        end

        -- [[ 2. Premium Button ]]
        function TabElements:CreateButton(btnText, callback)
            callback = callback or function() end
            
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, -10, 0, 36)
            Button.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            Button.Text = ""
            Button.AutoButtonColor = false
            Button.Parent = Page

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 6)
            BtnCorner.Parent = Button

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Color = Color3.fromRGB(34, 34, 40)
            BtnStroke.Thickness = 1
            BtnStroke.Parent = Button

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = btnText
            Label.TextColor3 = Color3.fromRGB(220, 220, 230)
            Label.TextSize = 12
            Label.Font = Enum.Font.GothamBold
            Label.Parent = Button

            -- 触觉动力学特效
            Button.MouseEnter:Connect(function()
                Animate(Button, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(28, 28, 34)})
                Animate(BtnStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
            end)
            Button.MouseLeave:Connect(function()
                Animate(Button, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(22, 22, 26)})
                Animate(BtnStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(34, 34, 40)})
            end)
            Button.MouseButton1Down:Connect(function()
                -- 轻轻捏紧的物理反馈
                Animate(Button, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -15, 0, 34)})
            end)
            Button.MouseButton1Up:Connect(function()
                Animate(Button, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, -10, 0, 36)})
                pcall(callback)
            end)
        end

        -- [[ 3. Premium Toggle ]]
        function TabElements:CreateToggle(toggleText, default, callback)
            local state = default or false
            callback = callback or function() end

            local Toggle = Instance.new("TextButton")
            Toggle.Size = UDim2.new(1, -10, 0, 36)
            Toggle.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            Toggle.Text = ""
            Toggle.AutoButtonColor = false
            Toggle.Parent = Page

            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 6)
            ToggleCorner.Parent = Toggle

            local ToggleStroke = Instance.new("UIStroke")
            ToggleStroke.Color = Color3.fromRGB(34, 34, 40)
            ToggleStroke.Parent = Toggle

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = toggleText
            Label.TextColor3 = Color3.fromRGB(200, 200, 210)
            Label.TextSize = 12
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Toggle

            -- 精巧胶囊开关
            local SwitchBg = Instance.new("Frame")
            SwitchBg.Size = UDim2.new(0, 36, 0, 18)
            SwitchBg.Position = UDim2.new(1, -48, 0.5, -9)
            SwitchBg.BackgroundColor3 = state and accentColor or Color3.fromRGB(40, 40, 48)
            SwitchBg.Parent = Toggle

            local SwitchCorner = Instance.new("UICorner")
            SwitchCorner.CornerRadius = UDim.new(1, 0)
            SwitchCorner.Parent = SwitchBg

            local SwitchStroke = Instance.new("UIStroke")
            SwitchStroke.Color = Color3.fromRGB(60, 60, 70)
            SwitchStroke.Thickness = 1
            SwitchStroke.Parent = SwitchBg

            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 12, 0, 12)
            Dot.Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
            Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Dot.Parent = SwitchBg

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = Dot

            local function UpdateToggle()
                local targetColor = state and accentColor or Color3.fromRGB(40, 40, 48)
                local targetPos = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
                
                Animate(SwitchBg, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = targetColor})
                Animate(Dot, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Position = targetPos})
                pcall(callback, state)
            end

            Toggle.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggle()
            end)

            Toggle.MouseEnter:Connect(function() Animate(ToggleStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor}) end)
            Toggle.MouseLeave:Connect(function() Animate(ToggleStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(34, 34, 40)}) end)
            
            local Elements = {}
            function Elements:Set(val)
                state = val
                UpdateToggle()
            end
            return Elements
        end

        -- [[ 4. Premium Slider ]]
        function TabElements:CreateSlider(sliderText, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end

            local Slider = Instance.new("Frame")
            Slider.Size = UDim2.new(1, -10, 0, 48)
            Slider.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            Slider.Parent = Page

            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 6)
            SliderCorner.Parent = Slider

            local SliderStroke = Instance.new("UIStroke")
            SliderStroke.Color = Color3.fromRGB(34, 34, 40)
            SliderStroke.Parent = Slider

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -80, 0, 22)
            Label.Position = UDim2.new(0, 12, 0, 4)
            Label.BackgroundTransparency = 1
            Label.Text = sliderText
            Label.TextColor3 = Color3.fromRGB(200, 200, 210)
            Label.TextSize = 12
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Slider

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 60, 0, 22)
            ValLabel.Position = UDim2.new(1, -72, 0, 4)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = accentColor
            ValLabel.TextSize = 12
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = Slider

            -- 滑动条轨道
            local SliderBar = Instance.new("TextButton")
            SliderBar.Size = UDim2.new(1, -24, 0, 6)
            SliderBar.Position = UDim2.new(0, 12, 0, 32)
            SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
            SliderBar.Text = ""
            SliderBar.AutoButtonColor = false
            SliderBar.Parent = Slider

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = SliderBar

            -- 高亮填充
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
            Fill.BackgroundColor3 = accentColor
            Fill.BorderSizePixel = 0
            Fill.Parent = SliderBar

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            -- 微型发光滑块
            local SliderDot = Instance.new("Frame")
            SliderDot.Size = UDim2.new(0, 12, 0, 12)
            SliderDot.AnchorPoint = Vector2.new(0.5, 0.5)
            SliderDot.Position = UDim2.new((default - min)/(max - min), 0, 0.5, 0)
            SliderDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderDot.Parent = SliderBar

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = SliderDot

            local dragging = false
            local function UpdateValue(input)
                local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * percentage)
                
                Animate(Fill, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(percentage, 0, 1, 0)})
                Animate(SliderDot, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = UDim2.new(percentage, 0, 0.5, 0)})
                
                ValLabel.Text = tostring(value)
                pcall(callback, value)
            end

            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateValue(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateValue(input)
                end
            end)

            local Elements = {}
            function Elements:Set(val)
                val = math.clamp(val, min, max)
                local percentage = (val - min)/(max - min)
                Animate(Fill, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(percentage, 0, 1, 0)})
                Animate(SliderDot, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = UDim2.new(percentage, 0, 0.5, 0)})
                ValLabel.Text = tostring(val)
                pcall(callback, val)
            end
            return Elements
        end

        -- [[ 5. Premium Dropdown ]]
        function TabElements:CreateDropdown(dropdownText, options, callback)
            options = options or {}
            callback = callback or function() end

            local Dropdown = Instance.new("Frame")
            Dropdown.Size = UDim2.new(1, -10, 0, 36)
            Dropdown.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            Dropdown.ClipsDescendants = true
            Dropdown.Parent = Page

            local DropCorner = Instance.new("UICorner")
            DropCorner.CornerRadius = UDim.new(0, 6)
            DropCorner.Parent = Dropdown

            local DropStroke = Instance.new("UIStroke")
            DropStroke.Color = Color3.fromRGB(34, 34, 40)
            DropStroke.Parent = Dropdown

            local ClickBtn = Instance.new("TextButton")
            ClickBtn.Size = UDim2.new(1, 0, 0, 36)
            ClickBtn.BackgroundTransparency = 1
            ClickBtn.Text = ""
            ClickBtn.Parent = Dropdown

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -40, 0, 36)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = dropdownText
            Label.TextColor3 = Color3.fromRGB(200, 200, 210)
            Label.TextSize = 12
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ClickBtn

            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 30, 0, 36)
            Arrow.Position = UDim2.new(1, -36, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Color3.fromRGB(150, 150, 160)
            Arrow.TextSize = 11
            Arrow.Font = Enum.Font.GothamMedium
            Arrow.Parent = ClickBtn

            local OptionContainer = Instance.new("Frame")
            OptionContainer.Size = UDim2.new(1, -10, 0, 0)
            OptionContainer.Position = UDim2.new(0, 5, 0, 38)
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.Parent = Dropdown

            local OptionList = Instance.new("UIListLayout")
            OptionList.Padding = UDim.new(0, 4)
            OptionList.Parent = OptionContainer

            local open = false
            local function ToggleDropdown()
                open = not open
                local targetHeight = open and (42 + OptionList.AbsoluteContentSize.Y) or 36
                Animate(Dropdown, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, -10, 0, targetHeight)})
                Animate(Arrow, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Rotation = open and 180 or 0})
            end

            ClickBtn.MouseButton1Click:Connect(ToggleDropdown)

            local function RefreshOptions()
                for _, child in ipairs(OptionContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for _, optName in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 28)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
                    OptBtn.Text = "  " .. optName
                    OptBtn.TextColor3 = Color3.fromRGB(170, 170, 180)
                    OptBtn.TextSize = 11
                    OptBtn.Font = Enum.Font.GothamMedium
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.Parent = OptionContainer

                    local OptCorner = Instance.new("UICorner")
                    OptCorner.CornerRadius = UDim.new(0, 5)
                    OptCorner.Parent = OptBtn

                    OptBtn.MouseButton1Click:Connect(function()
                        Label.Text = dropdownText .. ": " .. optName
                        ToggleDropdown()
                        pcall(callback, optName)
                    end)
                end
            end

            RefreshOptions()

            local Elements = {}
            function Elements:Refresh(newOptions)
                options = newOptions or {}
                RefreshOptions()
                if open then
                    Animate(Dropdown, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -10, 0, 42 + OptionList.AbsoluteContentSize.Y)})
                end
            end
            return Elements
        end

        return TabElements
    end

    return Pages
end

return Library
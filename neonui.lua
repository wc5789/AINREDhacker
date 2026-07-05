-- [[ Operit Modern Premium UI Library ]] --
local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 获取最佳 GUI 父级
local function GetGuiParent()
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success and coreGui then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- 高级物理弹性动画
local function Animate(obj, duration, style, dir, properties)
    local info = TweenInfo.new(duration, style, dir)
    local tween = TweenService:Create(obj, info, properties)
    tween:Play()
    return tween
end

-- 拖拽机制封装
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
            Animate(targetFrame, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
        end
    end)
end

function Library:CreateWindow(titleText, accentColor)
    titleText = titleText or "OPERIT HUB"
    accentColor = accentColor or Color3.fromRGB(0, 162, 255) -- 极光蓝
    
    -- 1. 创建顶层 ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OperitPrime_" .. math.random(1000, 9999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetGuiParent()

    -- 自动销毁老版本
    for _, old in ipairs(GetGuiParent():GetChildren()) do
        if old.Name:match("^OperitPrime_") and old ~= ScreenGui then
            old:Destroy()
        end
    end

    -- 中间大小的黄金比例尺寸 (刚刚好)
    local originalSize = UDim2.new(0, 560, 0, 360)
    local lastWindowPosition = UDim2.new(0.5, -280, 0.5, -180)

    -- 2. 炫酷的外挂悬浮球开关
    local FloatingToggle = Instance.new("Frame")
    FloatingToggle.Name = "FloatingToggle"
    FloatingToggle.Size = UDim2.new(0, 48, 0, 48)
    FloatingToggle.Position = UDim2.new(0.9, -10, 0.2, 0)
    FloatingToggle.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
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

    local FloatIcon = Instance.new("TextLabel")
    FloatIcon.Size = UDim2.new(1, 0, 1, 0)
    FloatIcon.BackgroundTransparency = 1
    FloatIcon.Text = "O"
    FloatIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    FloatIcon.TextSize = 18
    FloatIcon.Font = Enum.Font.GothamBold
    FloatIcon.Parent = FloatingToggle

    MakeDraggable(FloatingToggle, FloatingToggle)

    -- 3. 主界面 CanvasGroup 渲染层
    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = originalSize
    MainFrame.Position = lastWindowPosition
    MainFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
    MainFrame.BorderSizePixel = 0
    MainFrame.GroupTransparency = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(28, 28, 33)
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- 【吸入与释放核心逻辑】
    local isMinimized = false
    local animating = false

    local function ToggleUI()
        if animating then return end
        animating = true
        isMinimized = not isMinimized

        if isMinimized then
            lastWindowPosition = MainFrame.Position
            -- 吸入悬浮球动画 (Size + Position 双重渐变，顺滑果冻收缩)
            local shrink = Animate(MainFrame, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(FloatingToggle.Position.X.Scale, FloatingToggle.Position.X.Offset + 24, FloatingToggle.Position.Y.Scale, FloatingToggle.Position.Y.Offset + 24),
                GroupTransparency = 1
            })
            shrink.Completed:Connect(function()
                MainFrame.Visible = false
                animating = false
            end)
            Animate(FloatingToggle, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(0, 54, 0, 54)})
        else
            MainFrame.Visible = true
            MainFrame.Position = UDim2.new(FloatingToggle.Position.X.Scale, FloatingToggle.Position.X.Offset + 24, FloatingToggle.Position.Y.Scale, FloatingToggle.Position.Y.Offset + 24)
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.GroupTransparency = 1

            local expand = Animate(MainFrame, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                Size = originalSize,
                Position = lastWindowPosition,
                GroupTransparency = 0
            })
            expand.Completed:Connect(function()
                animating = false
            end)
            Animate(FloatingToggle, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(0, 48, 0, 48)})
        end
    end

    -- 悬浮球轻点检测（防拖拽误触）
    local dragThreshold = 6
    local clickStart
    FloatingToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickStart = input.Position
        end
    end)
    FloatingToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if clickStart then
                local dist = (input.Position - clickStart).Magnitude
                if dist < dragThreshold then ToggleUI() end
            end
        end
    end)

    -- 4. 顶部标题栏
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = TopBar

    -- 防止下面露出
    local Cover = Instance.new("Frame")
    Cover.Size = UDim2.new(1, 0, 0, 10)
    Cover.Position = UDim2.new(0, 0, 1, -10)
    Cover.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    Cover.BorderSizePixel = 0
    Cover.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Color3.fromRGB(240, 240, 245)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    -- 最小化按钮
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -65, 0.5, -15)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Text = "—"
    MinimizeBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
    MinimizeBtn.TextSize = 12
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Parent = TopBar
    MinimizeBtn.MouseButton1Click:Connect(ToggleUI)

    -- 彻底关闭按钮
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamMedium
    CloseBtn.Parent = TopBar
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    MakeDraggable(TopBar, MainFrame)

    -- 5. 左侧垂直导航栏 (包含底部分类看板)
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Size = UDim2.new(0, 130, 1, -38)
    SideBar.Position = UDim2.new(0, 0, 0, 38)
    SideBar.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
    SideBar.BorderSizePixel = 0
    SideBar.Parent = MainFrame

    local SideLine = Instance.new("Frame")
    SideLine.Size = UDim2.new(0, 1, 1, 0)
    SideLine.Position = UDim2.new(1, -1, 0, 0)
    SideLine.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    SideLine.BorderSizePixel = 0
    SideLine.Parent = SideBar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -6, 1, -85) -- 留出底部信息位置
    TabContainer.Position = UDim2.new(0, 3, 0, 10)
    TabContainer.BackgroundTransparency = 1
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = SideBar

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 4)
    TabList.Parent = TabContainer

    -- ==================== 📊 独家：底部状态看板 (图上完美复刻) ====================
    local InfoPanel = Instance.new("Frame")
    InfoPanel.Name = "InfoPanel"
    InfoPanel.Size = UDim2.new(1, -10, 0, 65)
    InfoPanel.Position = UDim2.new(0, 5, 1, -70)
    InfoPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    InfoPanel.Parent = SideBar

    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 6)
    InfoCorner.Parent = InfoPanel

    local InfoStroke = Instance.new("UIStroke")
    InfoStroke.Color = Color3.fromRGB(24, 24, 28)
    InfoStroke.Parent = InfoPanel

    -- 帧数标签
    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Size = UDim2.new(1, -10, 0, 20)
    FpsLabel.Position = UDim2.new(0, 8, 0, 6)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Text = "游戏帧数: 计算中..."
    FpsLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    FpsLabel.TextSize = 10
    FpsLabel.Font = Enum.Font.GothamBold
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.Parent = InfoPanel

    -- 音量标签
    local VolLabel = Instance.new("TextLabel")
    VolLabel.Size = UDim2.new(1, -10, 0, 20)
    VolLabel.Position = UDim2.new(0, 8, 0, 24)
    VolLabel.BackgroundTransparency = 1
    VolLabel.Text = "游戏音量: 100%"
    VolLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    VolLabel.TextSize = 10
    VolLabel.Font = Enum.Font.GothamBold
    VolLabel.TextXAlignment = Enum.TextXAlignment.Left
    VolLabel.Parent = InfoPanel

    -- 状态标签
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 0, 20)
    StatusLabel.Position = UDim2.new(0, 8, 0, 42)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "系统状态: 稳定运行"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
    StatusLabel.TextSize = 9
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = InfoPanel

    -- 动态获取并计算 FPS
    local frameCount = 0
    local lastTime = os.clock()
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = os.clock()
        if currentTime - lastTime >= 1 then
            FpsLabel.Text = "游戏帧数: " .. frameCount .. " 帧"
            frameCount = 0
            lastTime = currentTime
        end
    end)

    -- 动态获取音量
    task.spawn(function()
        while task.wait(2) do
            local success, vol = pcall(function()
                return math.floor(UserSettings():GetService("UserGameSettings").MasterVolume * 100)
            end)
            if success then
                VolLabel.Text = "游戏音量: " .. vol .. "%"
            end
        end
    end)

    -- 6. 右侧内容面板
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -145, 1, -50)
    ContentFrame.Position = UDim2.new(0, 140, 0, 45)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    local Pages = {}
    local CurrentTab = nil

    function Pages:CreateTab(tabName)
        tabName = tabName or "分类"

        -- 创建 Page Scrolling Frame
        local Page = Instance.new("ScrollingFrame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Color3.fromRGB(30, 30, 35)
        Page.Visible = false
        Page.Parent = ContentFrame

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 6)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        -- 侧边栏精美按钮
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 28)
        TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "   " .. tabName
        TabBtn.TextColor3 = Color3.fromRGB(130, 130, 140)
        TabBtn.TextSize = 11
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabContainer

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = TabBtn

        local BorderMarker = Instance.new("Frame")
        BorderMarker.Size = UDim2.new(0, 3, 0.4, 0)
        BorderMarker.Position = UDim2.new(0, 0, 0.3, 0)
        BorderMarker.BackgroundColor3 = accentColor
        BorderMarker.BackgroundTransparency = 1
        BorderMarker.Parent = TabBtn

        local MarkerCorner = Instance.new("UICorner")
        MarkerCorner.CornerRadius = UDim.new(1, 0)
        MarkerCorner.Parent = BorderMarker

        local function Select()
            for _, child in ipairs(ContentFrame:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            for _, btn in ipairs(TabContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    Animate(btn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(130, 130, 140), BackgroundTransparency = 1})
                    Animate(btn.BorderMarker, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
                end
            end
            Page.Visible = true
            Animate(TabBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(20, 20, 25)})
            Animate(BorderMarker, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {BackgroundTransparency = 0})
        end

        TabBtn.MouseButton1Click:Connect(Select)

        if CurrentTab == nil then
            CurrentTab = tabName
            Select()
        end

        local Elements = {}

        -- [[ 1. Label ]]
        function Elements:CreateLabel(labelText)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -10, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = labelText
            Label.TextColor3 = Color3.fromRGB(140, 140, 150)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Page
            return Label
        end

        -- [[ 2. Premium Button ]]
        function Elements:CreateButton(btnText, callback)
            callback = callback or function() end

            local Card = Instance.new("TextButton")
            Card.Size = UDim2.new(1, -10, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
            Card.Text = ""
            Card.AutoButtonColor = false
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(24, 24, 28)
            CardStroke.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = btnText
            Label.TextColor3 = Color3.fromRGB(210, 210, 220)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamBold
            Label.Parent = Card

            -- 鼠标物理交互反馈
            Card.MouseEnter:Connect(function()
                Animate(Card, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(20, 20, 25)})
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
            end)
            Card.MouseLeave:Connect(function()
                Animate(Card, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(16, 16, 20)})
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(24, 24, 28)})
            end)
            Card.MouseButton1Down:Connect(function()
                Animate(Card, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -14, 0, 30)})
            end)
            Card.MouseButton1Up:Connect(function()
                Animate(Card, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, -10, 0, 32)})
                pcall(callback)
            end)
        end

        -- [[ 3. Premium Toggle ]]
        function Elements:CreateToggle(toggleText, default, callback)
            local state = default or false
            callback = callback or function() end

            local Card = Instance.new("TextButton")
            Card.Size = UDim2.new(1, -10, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
            Card.Text = ""
            Card.AutoButtonColor = false
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(24, 24, 28)
            CardStroke.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -50, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = toggleText
            Label.TextColor3 = Color3.fromRGB(190, 190, 200)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Card

            local Switch = Instance.new("Frame")
            Switch.Size = UDim2.new(0, 32, 0, 16)
            Switch.Position = UDim2.new(1, -42, 0.5, -8)
            Switch.BackgroundColor3 = state and accentColor or Color3.fromRGB(35, 35, 40)
            Switch.Parent = Card

            local SwitchCorner = Instance.new("UICorner")
            SwitchCorner.CornerRadius = UDim.new(1, 0)
            SwitchCorner.Parent = Switch

            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 10, 0, 10)
            Dot.Position = state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
            Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Dot.Parent = Switch

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = Dot

            local function Update()
                local targetColor = state and accentColor or Color3.fromRGB(35, 35, 40)
                local targetPos = state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
                Animate(Switch, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = targetColor})
                Animate(Dot, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Position = targetPos})
                pcall(callback, state)
            end

            Card.MouseButton1Click:Connect(function()
                state = not state
                Update()
            end)

            Card.MouseEnter:Connect(function() Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor}) end)
            Card.MouseLeave:Connect(function() Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(24, 24, 28)}) end)

            return {Set = function(_, v) state = v Update() end}
        end

        -- [[ 4. Premium Slider ]]
        function Elements:CreateSlider(sliderText, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, -10, 0, 42)
            Card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(24, 24, 28)
            CardStroke.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -80, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 2)
            Label.BackgroundTransparency = 1
            Label.Text = sliderText
            Label.TextColor3 = Color3.fromRGB(190, 190, 200)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Card

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 60, 0, 20)
            ValLabel.Position = UDim2.new(1, -70, 0, 2)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = accentColor
            ValLabel.TextSize = 11
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = Card

            local SliderBar = Instance.new("TextButton")
            SliderBar.Size = UDim2.new(1, -20, 0, 5)
            SliderBar.Position = UDim2.new(0, 10, 0, 26)
            SliderBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            SliderBar.Text = ""
            SliderBar.AutoButtonColor = false
            SliderBar.Parent = Card

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = SliderBar

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
            Fill.BackgroundColor3 = accentColor
            Fill.BorderSizePixel = 0
            Fill.Parent = SliderBar

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            local dragging = false
            local function Update(input)
                local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * percentage)
                Animate(Fill, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(percentage, 0, 1, 0)})
                ValLabel.Text = tostring(value)
                pcall(callback, value)
            end

            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)

            return {Set = function(_, v)
                local percentage = (math.clamp(v, min, max) - min)/(max - min)
                Animate(Fill, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(percentage, 0, 1, 0)})
                ValLabel.Text = tostring(v)
                pcall(callback, v)
            end}
        end

        -- [[ 5. Premium Dropdown ]]
        function Elements:CreateDropdown(dropdownText, options, callback)
            options = options or {}
            callback = callback or function() end

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, -10, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
            Card.ClipsDescendants = true
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(24, 24, 28)
            CardStroke.Parent = Card

            local ClickBtn = Instance.new("TextButton")
            ClickBtn.Size = UDim2.new(1, 0, 0, 32)
            ClickBtn.BackgroundTransparency = 1
            ClickBtn.Text = ""
            ClickBtn.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -40, 0, 32)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = dropdownText
            Label.TextColor3 = Color3.fromRGB(190, 190, 200)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ClickBtn

            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 30, 0, 32)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Color3.fromRGB(140, 140, 150)
            Arrow.TextSize = 10
            Arrow.Font = Enum.Font.GothamMedium
            Arrow.Parent = ClickBtn

            local OptionContainer = Instance.new("Frame")
            OptionContainer.Size = UDim2.new(1, -10, 0, 0)
            OptionContainer.Position = UDim2.new(0, 5, 0, 34)
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.Parent = Card

            local OptionList = Instance.new("UIListLayout")
            OptionList.Padding = UDim.new(0, 3)
            OptionList.Parent = OptionContainer

            local open = false
            local function Toggle()
                open = not open
                local targetHeight = open and (38 + OptionList.AbsoluteContentSize.Y) or 32
                Animate(Card, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, -10, 0, targetHeight)})
                Animate(Arrow, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Rotation = open and 180 or 0})
            end

            ClickBtn.MouseButton1Click:Connect(Toggle)

            local function Build()
                for _, child in ipairs(OptionContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, name in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 24)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
                    OptBtn.Text = "  " .. name
                    OptBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
                    OptBtn.TextSize = 10
                    OptBtn.Font = Enum.Font.GothamMedium
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.Parent = OptionContainer

                    local OptCorner = Instance.new("UICorner")
                    OptCorner.CornerRadius = UDim.new(0, 4)
                    OptCorner.Parent = OptBtn

                    OptBtn.MouseButton1Click:Connect(function()
                        Label.Text = dropdownText .. ": " .. name
                        Toggle()
                        pcall(callback, name)
                    end)
                end
            end

            Build()
            return {Refresh = function(_, newOpts) options = newOpts Build() end}
        end

        return Elements
    end

    return Pages
end

return Library
-- [[ Operit Neon Pink Morphing Fluid Glass UI Library ]] --
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
    titleText = titleText or "OPERIT V3"
    accentColor = accentColor or Color3.fromRGB(254, 74, 161) -- 魅影霓虹粉
    
    -- 1. 创建顶层 ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OperitMorph_" .. math.random(1000, 9999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetGuiParent()

    -- 自动销毁旧版
    for _, old in ipairs(GetGuiParent():GetChildren()) do
        if old.Name:match("^OperitMorph_") and old ~= ScreenGui then
            old:Destroy()
        end
    end

    -- 📐 黄金中置尺寸 (490 x 320)
    local windowSize = UDim2.new(0, 490, 0, 320)
    local windowCenterPos = UDim2.new(0.5, -245, 0.5, -160)
    
    -- 🔴 悬浮状态初始设定
    local floatSize = UDim2.new(0, 46, 0, 46)
    local lastFloatPosition = UDim2.new(0.9, -10, 0.2, 0)

    -- 2. 变形主基座 (MainFrame) - Morphing Engine
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = floatSize 
    MainFrame.Position = lastFloatPosition
    MainFrame.BackgroundColor3 = Color3.fromRGB(12, 8, 12)
    MainFrame.BackgroundTransparency = 0.25 -- 高光25%玻璃透感
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 23) -- 完美的圆形起步
    MainCorner.Parent = MainFrame

    -- 粉边高亮
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = accentColor
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 12, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 6, 10))
    })
    MainGradient.Rotation = 45
    MainGradient.Parent = MainFrame

    -- 悬浮状态小樱花图标
    local FloatIcon = Instance.new("TextLabel")
    FloatIcon.Name = "FloatIcon"
    FloatIcon.Size = UDim2.new(1, 0, 1, 0)
    FloatIcon.BackgroundTransparency = 1
    FloatIcon.Text = "🌸"
    FloatIcon.TextSize = 16
    FloatIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    FloatIcon.Font = Enum.Font.GothamBold
    FloatIcon.Visible = true
    FloatIcon.Parent = MainFrame

    -- 内容独立容器
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Visible = false 
    ContentContainer.Parent = MainFrame

    local isMinimized = true
    local animating = false

    -- 3. 终极一键圆滑变形动画 (Morph)
    local function ToggleUI()
        if animating then return end
        animating = true
        isMinimized = not isMinimized

        if isMinimized then
            -- 【长方形 ➔ 圆球】 收缩
            ContentContainer.Visible = false
            
            Animate(MainCorner, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In, {CornerRadius = UDim.new(0, 23)})
            local morphBack = Animate(MainFrame, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
                Size = floatSize,
                Position = lastFloatPosition,
                BackgroundTransparency = 0.25
            })

            morphBack.Completed:Connect(function()
                FloatIcon.Visible = true
                FloatIcon.TextTransparency = 1
                Animate(FloatIcon, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
                animating = false
            end)
        else
            -- 【圆球 ➔ 长方形】 展开
            lastFloatPosition = MainFrame.Position
            
            Animate(FloatIcon, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
            task.wait(0.1)
            FloatIcon.Visible = false

            Animate(MainCorner, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {CornerRadius = UDim.new(0, 10)})
            local morphForward = Animate(MainFrame, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                Size = windowSize,
                Position = windowCenterPos,
                BackgroundTransparency = 0.18 -- 展现质感磨砂
            })

            morphForward.Completed:Connect(function()
                ContentContainer.Visible = true 
                animating = false
            end)
        end
    end

    -- 悬浮球点击检测
    local dragThreshold = 6
    local clickStart
    MainFrame.InputBegan:Connect(function(input)
        if isMinimized then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                clickStart = input.Position
            end
        end
    end)
    MainFrame.InputEnded:Connect(function(input)
        if isMinimized then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if clickStart then
                    local dist = (input.Position - clickStart).Magnitude
                    if dist < dragThreshold then ToggleUI() end
                end
            end
        end
    end)
    MakeDraggable(MainFrame, MainFrame)

    -- 4. 顶部标题栏
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundColor3 = Color3.fromRGB(18, 12, 18)
    TopBar.BackgroundTransparency = 0.2
    TopBar.BorderSizePixel = 0
    TopBar.Parent = ContentContainer

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = TopBar

    local Cover = Instance.new("Frame")
    Cover.Name = "Cover"
    Cover.Size = UDim2.new(1, 0, 0, 10)
    Cover.Position = UDim2.new(0, 0, 1, -10)
    Cover.BackgroundColor3 = Color3.fromRGB(18, 12, 18)
    Cover.BorderSizePixel = 0
    Cover.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText:upper()
    Title.TextColor3 = Color3.fromRGB(255, 235, 245)
    Title.TextSize = 12
    Title.Font = Enum.Font.MontserratBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    -- 最小化与关闭
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -65, 0.5, -15)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Text = "—"
    MinimizeBtn.TextColor3 = Color3.fromRGB(160, 140, 150)
    MinimizeBtn.TextSize = 11
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Parent = TopBar
    MinimizeBtn.MouseButton1Click:Connect(ToggleUI)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(160, 140, 150)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamMedium
    CloseBtn.Parent = TopBar
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    MakeDraggable(TopBar, MainFrame)

    -- 5. 左侧垂直导航栏 SideBar (完美包裹，圆角无缝覆盖)
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Size = UDim2.new(0, 125, 1, -38)
    SideBar.Position = UDim2.new(0, 0, 0, 38)
    SideBar.BackgroundTransparency = 1 -- 🔴 透明防穿帮
    SideBar.BorderSizePixel = 0
    SideBar.Parent = ContentContainer

    local SideLine = Instance.new("Frame")
    SideLine.Name = "SideLine"
    SideLine.Size = UDim2.new(0, 1.5, 1, 0)
    SideLine.Position = UDim2.new(1, -1.5, 0, 0)
    SideLine.BackgroundColor3 = Color3.fromRGB(85, 38, 62) -- 明显的分层线条
    SideLine.BorderSizePixel = 0
    SideLine.Parent = SideBar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -6, 1, -85)
    TabContainer.Position = UDim2.new(0, 3, 0, 10)
    TabContainer.BackgroundTransparency = 1
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = SideBar

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 4)
    TabList.Parent = TabContainer

    -- ==================== 📊 底部状态看板 ====================
    local InfoPanel = Instance.new("Frame")
    InfoPanel.Name = "InfoPanel"
    InfoPanel.Size = UDim2.new(1, -10, 0, 65)
    InfoPanel.Position = UDim2.new(0, 5, 1, -70)
    InfoPanel.BackgroundColor3 = Color3.fromRGB(24, 15, 23)
    InfoPanel.BackgroundTransparency = 0.4
    InfoPanel.Parent = SideBar

    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 6)
    InfoCorner.Parent = InfoPanel

    local InfoStroke = Instance.new("UIStroke")
    InfoStroke.Color = Color3.fromRGB(55, 30, 45)
    InfoStroke.Parent = InfoPanel

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Size = UDim2.new(1, -10, 0, 18)
    FpsLabel.Position = UDim2.new(0, 8, 0, 6)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Text = "游戏帧数: 0 帧"
    FpsLabel.TextColor3 = Color3.fromRGB(200, 175, 190)
    FpsLabel.TextSize = 10
    FpsLabel.Font = Enum.Font.GothamBold
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.Parent = InfoPanel

    local VolLabel = Instance.new("TextLabel")
    VolLabel.Size = UDim2.new(1, -10, 0, 18)
    VolLabel.Position = UDim2.new(0, 8, 0, 24)
    VolLabel.BackgroundTransparency = 1
    VolLabel.Text = "游戏音量: 100%"
    VolLabel.TextColor3 = Color3.fromRGB(200, 175, 190)
    VolLabel.TextSize = 10
    VolLabel.Font = Enum.Font.GothamBold
    VolLabel.TextXAlignment = Enum.TextXAlignment.Left
    VolLabel.Parent = InfoPanel

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 0, 18)
    StatusLabel.Position = UDim2.new(0, 8, 0, 42)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "系统状态: 稳定运行"
    StatusLabel.TextColor3 = Color3.fromRGB(254, 74, 161)
    StatusLabel.TextSize = 9
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = InfoPanel

    -- FPS 渲染
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

    -- 音量侦测
    task.spawn(function()
        while task.wait(2) do
            local success, vol = pcall(function()
                return math.floor(UserSettings():GetService("UserGameSettings").MasterVolume * 100)
            end)
            if success then VolLabel.Text = "游戏音量: " .. vol .. "%" end
        end
    end)

    -- 6. 右侧内容面板 ContentFrame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -135, 1, -48)
    ContentFrame.Position = UDim2.new(0, 130, 0, 43)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = ContentContainer

    local Pages = {}
    local CurrentTab = nil

    function Pages:CreateTab(tabName)
        tabName = tabName or "分类"

        -- 页面容器
        local Page = Instance.new("ScrollingFrame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Color3.fromRGB(80, 40, 60)
        Page.Visible = false
        Page.Parent = ContentFrame

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 6)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        -- 侧边栏按钮 TabBtn
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -4, 0, 28)
        TabBtn.BackgroundColor3 = Color3.fromRGB(36, 20, 30)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "   " .. tabName
        TabBtn.TextColor3 = Color3.fromRGB(150, 135, 145)
        TabBtn.TextSize = 11
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabContainer

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 5)
        TabCorner.Parent = TabBtn

        local BorderMarker = Instance.new("Frame")
        BorderMarker.Name = "BorderMarker"
        BorderMarker.Size = UDim2.new(0, 3, 0.4, 0)
        BorderMarker.Position = UDim2.new(0, 0, 0.3, 0)
        BorderMarker.BackgroundColor3 = accentColor
        BorderMarker.BackgroundTransparency = 1
        BorderMarker.Parent = TabBtn

        local MarkerCorner = Instance.new("UICorner")
        MarkerCorner.CornerRadius = UDim.new(1, 0)
        MarkerCorner.Parent = BorderMarker

        -- 🌟 极致高光 Tab 切换滑入过渡
        local function Select()
            for _, child in ipairs(ContentFrame:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            for _, btn in ipairs(TabContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    Animate(btn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(150, 135, 145), BackgroundTransparency = 1})
                    local marker = btn:FindFirstChild("BorderMarker")
                    if marker then
                        Animate(marker, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
                    end
                end
            end
            
            -- ⭐ 灵魂滑入动画：由下至上+淡入
            Page.Visible = true
            Page.Position = UDim2.new(0, 0, 0, 15) -- 初始下偏
            Animate(Page, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = UDim2.new(0, 0, 0, 0)})
            
            Animate(TabBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(36, 20, 30)})
            Animate(BorderMarker, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {BackgroundTransparency = 0})
        end

        TabBtn.MouseButton1Click:Connect(Select)

        if CurrentTab == nil then
            CurrentTab = tabName
            Select()
        end

        local Elements = {}

        -- [[ 1. Premium Label ]]
        function Elements:CreateLabel(labelText)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -10, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = labelText
            Label.TextColor3 = Color3.fromRGB(175, 155, 168)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Page
            return Label
        end

        -- [[ 2. Premium Button (微物理震动反馈) ]]
        function Elements:CreateButton(btnText, callback)
            callback = callback or function() end

            local Card = Instance.new("TextButton")
            Card.Size = UDim2.new(1, -10, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35 
            Card.Text = ""
            Card.AutoButtonColor = false
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(55, 30, 48)
            CardStroke.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = btnText
            Label.TextColor3 = Color3.fromRGB(245, 220, 235)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamBold
            Label.Parent = Card

            Card.MouseEnter:Connect(function()
                Animate(Card, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.15})
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
            end)
            Card.MouseLeave:Connect(function()
                Animate(Card, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.35})
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(55, 30, 48)})
            end)
            Card.MouseButton1Down:Connect(function()
                Animate(Card, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -14, 0, 30)})
            end)
            Card.MouseButton1Up:Connect(function()
                Animate(Card, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, -10, 0, 32)})
                pcall(callback)
            end)
        end

        -- [[ 3. Premium Toggle (⭐ 果冻果冻弹性开关与粉色晕染) ]]
        function Elements:CreateToggle(toggleText, default, callback)
            local state = default or false
            callback = callback or function() end

            local Card = Instance.new("TextButton")
            Card.Size = UDim2.new(1, -10, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35
            Card.Text = ""
            Card.AutoButtonColor = false
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(55, 30, 48)
            CardStroke.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -50, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = toggleText
            Label.TextColor3 = Color3.fromRGB(220, 200, 212)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Card

            local Switch = Instance.new("Frame")
            Switch.Size = UDim2.new(0, 32, 0, 16)
            Switch.Position = UDim2.new(1, -42, 0.5, -8)
            Switch.BackgroundColor3 = state and accentColor or Color3.fromRGB(60, 40, 52)
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
                local targetColor = state and accentColor or Color3.fromRGB(60, 40, 52)
                local targetPos = state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
                
                -- ⭐ 果冻拉伸弹性（在滑行过程中产生形变）
                Animate(Dot, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(0, 14, 0, 10)})
                task.delay(0.1, function()
                    Animate(Dot, 0.18, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, {Size = UDim2.new(0, 10, 0, 10)})
                end)

                Animate(Switch, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = targetColor})
                Animate(Dot, 0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, {Position = targetPos})
                
                if state then
                    Animate(CardStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
                    Animate(Card, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.2})
                else
                    Animate(CardStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(55, 30, 48)})
                    Animate(Card, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.35})
                end
                
                pcall(callback, state)
            end

            Card.MouseButton1Click:Connect(function()
                state = not state
                Update()
            end)

            Card.MouseEnter:Connect(function() 
                if not state then Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(120, 60, 95)}) end
            end)
            Card.MouseLeave:Connect(function() 
                if not state then Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(55, 30, 48)}) end
            end)

            return {Set = function(_, v) state = v Update() end}
        end

        -- [[ 4. Premium Slider (⭐ 精致液态变形滑块设计) ]]
        function Elements:CreateSlider(sliderText, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, -10, 0, 42)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(55, 30, 48)
            CardStroke.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -80, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 2)
            Label.BackgroundTransparency = 1
            Label.Text = sliderText
            Label.TextColor3 = Color3.fromRGB(220, 200, 212)
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

            -- 隐形/极简滑槽
            local SliderBar = Instance.new("TextButton")
            SliderBar.Size = UDim2.new(1, -20, 0, 4) -- 默认极细，凸显科技感
            SliderBar.Position = UDim2.new(0, 10, 0, 26)
            SliderBar.BackgroundColor3 = Color3.fromRGB(60, 40, 52)
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

            -- 浮动发光白色指示钮
            local Thumb = Instance.new("Frame")
            Thumb.Size = UDim2.new(0, 8, 0, 8) -- 极小
            Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            Thumb.Position = UDim2.new((default - min)/(max - min), 0, 0.5, 0)
            Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Thumb.Parent = SliderBar

            local ThumbCorner = Instance.new("UICorner")
            ThumbCorner.CornerRadius = UDim.new(1, 0)
            ThumbCorner.Parent = Thumb

            local ThumbStroke = Instance.new("UIStroke")
            ThumbStroke.Color = accentColor
            ThumbStroke.Thickness = 1.5
            ThumbStroke.Parent = Thumb

            -- ⭐ 液体式交互膨胀特效
            Card.MouseEnter:Connect(function()
                Animate(SliderBar, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -20, 0, 6)}) -- 滑槽变粗
                Animate(Thumb, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(0, 12, 0, 12)}) -- 指示钮膨胀
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(120, 60, 95)})
            end)
            Card.MouseLeave:Connect(function()
                Animate(SliderBar, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -20, 0, 4)})
                Animate(Thumb, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(0, 8, 0, 8)})
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(55, 30, 48)})
            end)

            local dragging = false
            local function Update(input)
                local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * percentage)
                
                -- 顺滑液态跟随
                Animate(Fill, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(percentage, 0, 1, 0)})
                Animate(Thumb, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = UDim2.new(percentage, 0, 0.5, 0)})
                
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
                Animate(Thumb, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = UDim2.new(percentage, 0, 0.5, 0)})
                ValLabel.Text = tostring(v)
                pcall(callback, v)
            end}
        end

        -- [[ 5. Premium TextBox (⭐ 纯净化输入框 - 极简极高大上) ]]
        function Elements:CreateInput(placeholder, callback)
            placeholder = placeholder or "请输入并点击回车..."
            callback = callback or function() end

            -- 纯净化输入框卡片 (无标，TextBox 直接占据全容器，超大气)
            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, -10, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(55, 30, 48)
            CardStroke.Parent = Card

            -- 全屏包裹 TextBox
            local TextBox = Instance.new("TextBox")
            TextBox.Size = UDim2.new(1, -20, 1, 0)
            TextBox.Position = UDim2.new(0, 10, 0, 0)
            TextBox.BackgroundTransparency = 1
            TextBox.PlaceholderText = placeholder
            TextBox.PlaceholderColor3 = Color3.fromRGB(120, 95, 110)
            TextBox.Text = ""
            TextBox.TextColor3 = Color3.fromRGB(255, 235, 245)
            TextBox.TextSize = 11
            TextBox.Font = Enum.Font.GothamMedium
            TextBox.Parent = Card

            -- ⭐ 聚焦缩进拟真呼吸效果
            TextBox.Focused:Connect(function()
                Animate(Card, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -14, 0, 30), BackgroundTransparency = 0.2})
                Animate(CardStroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
            end)
            TextBox.FocusLost:Connect(function()
                Animate(Card, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, -10, 0, 32), BackgroundTransparency = 0.35})
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(55, 30, 48)})
                pcall(callback, TextBox.Text)
            end)

            return {
                GetText = function() return TextBox.Text end,
                SetText = function(_, newText) TextBox.Text = newText pcall(callback, newText) end
            }
        end

        -- [[ 6. Premium Dropdown (下拉选择条) ]]
        function Elements:CreateDropdown(dropdownText, options, callback)
            options = options or {}
            callback = callback or function() end

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, -10, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35
            Card.ClipsDescendants = true
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(55, 30, 48)
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
            Label.TextColor3 = Color3.fromRGB(220, 200, 212)
            Label.TextSize = 11
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ClickBtn

            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 30, 0, 32)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Color3.fromRGB(160, 140, 150)
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
                Animate(Card, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, -10, 0, targetHeight)})
                Animate(Arrow, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Rotation = open and 180 or 0})
            end

            ClickBtn.MouseButton1Click:Connect(Toggle)

            local function Build()
                for _, child in ipairs(OptionContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, name in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 24)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(42, 22, 34)
                    OptBtn.Text = "  " .. name
                    OptBtn.TextColor3 = Color3.fromRGB(190, 170, 182)
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
-- [[ Operit Neon Star & Custom Font Glassmorphism UI Library ]] --
local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 默认字体配置：Builder Sans (Roblox 最新高档中英文适配字体)
Library.CurrentFont = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

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

-- 统一字体更新引擎 (安全应用字体)
local function ApplyFont(textLabel, weight)
    weight = weight or Enum.FontWeight.Bold
    pcall(function()
        textLabel.FontFace = Font.new(Library.CurrentFont.Family, weight, Enum.FontStyle.Normal)
    end)
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

-- ==================== 📊 独家：毛玻璃侧滑弹窗通知系统 (Compact Toasts) ====================
local NotificationGui = nil
local function CreateNotificationContainer()
    if NotificationGui then return NotificationGui end
    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "OperitNotifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = GetGuiParent()

    local FrameList = Instance.new("Frame")
    FrameList.Name = "FrameList"
    FrameList.Size = UDim2.new(0, 200, 1, -40) -- 精致窄版容器
    FrameList.Position = UDim2.new(1, -210, 0, 20)
    FrameList.BackgroundTransparency = 1
    FrameList.Parent = NotificationGui

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 6)
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = FrameList

    return NotificationGui
end

function Library:Notify(titleText, descText, duration)
    titleText = titleText or "SYSTEM"
    descText = descText or "操作成功"
    duration = duration or 3

    local container = CreateNotificationContainer()
    local listFrame = container.FrameList

    -- 采用 CanvasGroup，方便做完美的渐渐显示淡入动画
    local Toast = Instance.new("CanvasGroup")
    Toast.Name = "Toast"
    Toast.Size = UDim2.new(1, 0, 0, 42) -- 极其精致小巧的尺寸，不挡屏幕
    Toast.BackgroundColor3 = Color3.fromRGB(15, 10, 15)
    Toast.GroupTransparency = 1 -- 初始完全透明
    Toast.BorderSizePixel = 0
    Toast.Parent = listFrame

    local ToastCorner = Instance.new("UICorner")
    ToastCorner.CornerRadius = UDim.new(0, 5)
    ToastCorner.Parent = Toast

    local ToastStroke = Instance.new("UIStroke")
    ToastStroke.Color = Color3.fromRGB(254, 74, 161) -- 霓虹魅影粉
    ToastStroke.Thickness = 1.2
    ToastStroke.Parent = Toast

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -16, 0, 18)
    Title.Position = UDim2.new(0, 8, 0, 3)
    Title.BackgroundTransparency = 1
    Title.Text = titleText:upper()
    Title.TextColor3 = Color3.fromRGB(254, 74, 161)
    Title.TextSize = 10
    ApplyFont(Title, Enum.FontWeight.Bold)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Toast

    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -16, 0, 18)
    Desc.Position = UDim2.new(0, 8, 0, 19)
    Desc.BackgroundTransparency = 1
    Desc.Text = descText
    Desc.TextColor3 = Color3.fromRGB(235, 220, 230)
    Desc.TextSize = 9
    ApplyFont(Desc, Enum.FontWeight.Medium)
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Toast

    -- 进度条
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, 0, 0, 1.5)
    ProgressBar.Position = UDim2.new(0, 0, 1, -1.5)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(254, 74, 161)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = Toast

    -- 🌟 1. 【渐渐显示】淡入动画
    Toast.Position = UDim2.new(0, 0, 0, 0) -- 原位不动
    Animate(Toast, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {GroupTransparency = 0}) -- 渐渐显示出来
    Animate(ProgressBar, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {Size = UDim2.new(0, 0, 0, 1.5)})

    -- 🌟 2. 【左右往回拉】收回关闭动画
    task.delay(duration, function()
        -- 弹性向右侧往回拉并滑走
        local slideOut = Animate(Toast, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
            Position = UDim2.new(1.3, 0, 0, 0), -- 往回拉
            GroupTransparency = 1
        })
        slideOut.Completed:Connect(function()
            Toast:Destroy()
        end)
    end)
end

-- ==================== 🌸 自定义云端字体配置 ====================
function Library:SetCustomFont(fontAssetId)
    local success, customFont = pcall(function()
        if typeof(fontAssetId) == "number" then
            return Font.fromId(fontAssetId)
        else
            return Font.new(fontAssetId, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        end
    end)
    if success and customFont then
        Library.CurrentFont = customFont
        -- 全局刷新当前存在的UI字体
        for _, gui in ipairs(GetGuiParent():GetChildren()) do
            if gui.Name:match("^OperitMorph_") or gui.Name == "OperitNotifications" then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                        ApplyFont(desc, desc.Font == Enum.Font.GothamBold and Enum.FontWeight.Bold or Enum.FontWeight.Medium)
                    end
                end
            end
        end
    else
        warn("字体加载失败，已应用默认高档字体。")
    end
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
    
    local floatSize = UDim2.new(0, 46, 0, 46)
    local lastFloatPosition = UDim2.new(0.9, -10, 0.2, 0)

    -- 2. 变形主基座 (MainFrame) - Morphing Engine
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = floatSize 
    MainFrame.Position = lastFloatPosition
    MainFrame.BackgroundColor3 = Color3.fromRGB(12, 8, 12)
    MainFrame.BackgroundTransparency = 1 -- 悬浮球状态时容器完全透明，只露出星体
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 23) -- 完美的圆形起步
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = accentColor
    MainStroke.Thickness = 0 -- 悬浮时描边隐藏，只显示星星的描边
    MainStroke.Parent = MainFrame

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 12, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 6, 10))
    })
    MainGradient.Rotation = 45
    MainGradient.Parent = MainFrame

    -- ⭐ 旋转星核 (FloatIcon) - 真正无限自转的璀璨五角星
    local FloatIcon = Instance.new("TextLabel")
    FloatIcon.Name = "FloatIcon"
    FloatIcon.Size = UDim2.new(1, 0, 1, 0)
    FloatIcon.BackgroundTransparency = 1
    FloatIcon.Text = "★" -- 奢华五角星形状
    FloatIcon.TextSize = 36
    FloatIcon.TextColor3 = accentColor
    FloatIcon.Font = Enum.Font.GothamBold
    FloatIcon.Visible = true
    FloatIcon.Parent = MainFrame

    local IconStroke = Instance.new("UIStroke")
    IconStroke.Color = Color3.fromRGB(255, 255, 255)
    IconStroke.Thickness = 1.2
    IconStroke.Parent = FloatIcon

    -- 自转物理线程
    local rotationConnection
    local function StartRotation()
        if rotationConnection then rotationConnection:Disconnect() end
        rotationConnection = RunService.RenderStepped:Connect(function(delta)
            FloatIcon.Rotation = (FloatIcon.Rotation + 140 * delta) % 360 -- 每秒旋转 140 度
        end)
    end
    StartRotation()

    -- 内容独立容器
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Visible = false 
    ContentContainer.Parent = MainFrame

    local isMinimized = true
    local animating = false

    -- 3. 终极一键自转星体 ➔ 长方形主窗口 变形动画
    local function ToggleUI()
        if animating then return end
        animating = true
        isMinimized = not isMinimized

        if isMinimized then
            -- 【长方形 ➔ 自转星体】
            ContentContainer.Visible = false
            MainStroke.Thickness = 0
            
            Animate(MainCorner, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In, {CornerRadius = UDim.new(0, 23)})
            local morphBack = Animate(MainFrame, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
                Size = floatSize,
                Position = lastFloatPosition,
                BackgroundTransparency = 1
            })

            morphBack.Completed:Connect(function()
                FloatIcon.Visible = true
                FloatIcon.TextTransparency = 1
                Animate(FloatIcon, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
                StartRotation() -- 开启无限自转
                animating = false
            end)
        else
            -- 【自转星体 ➔ 长方形】
            lastFloatPosition = MainFrame.Position
            if rotationConnection then rotationConnection:Disconnect() end -- 解除自转
            
            -- 星体爆发动画
            Animate(FloatIcon, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In, {TextTransparency = 1, Rotation = FloatIcon.Rotation + 90})
            task.wait(0.1)
            FloatIcon.Visible = false

            MainStroke.Thickness = 1.5
            Animate(MainCorner, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {CornerRadius = UDim.new(0, 10)})
            local morphForward = Animate(MainFrame, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                Size = windowSize,
                Position = windowCenterPos,
                BackgroundTransparency = 0.2 -- 20% 通透度
            })

            morphForward.Completed:Connect(function()
                ContentContainer.Visible = true 
                animating = false
            end)
        end
    end

    -- 星星点击检测
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
    ApplyFont(Title, Enum.FontWeight.Bold)
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
    ApplyFont(MinimizeBtn, Enum.FontWeight.Bold)
    MinimizeBtn.Parent = TopBar
    MinimizeBtn.MouseButton1Click:Connect(ToggleUI)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(160, 140, 150)
    CloseBtn.TextSize = 18
    ApplyFont(CloseBtn, Enum.FontWeight.Medium)
    CloseBtn.Parent = TopBar
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    MakeDraggable(TopBar, MainFrame)

    -- 5. 左侧垂直导航栏 SideBar
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Size = UDim2.new(0, 125, 1, -38)
    SideBar.Position = UDim2.new(0, 0, 0, 38)
    SideBar.BackgroundTransparency = 1 
    SideBar.BorderSizePixel = 0
    SideBar.Parent = ContentContainer

    local SideLine = Instance.new("Frame")
    SideLine.Name = "SideLine"
    SideLine.Size = UDim2.new(0, 2, 1, 0)
    SideLine.Position = UDim2.new(1, -2, 0, 0)
    SideLine.BackgroundColor3 = Color3.fromRGB(110, 42, 75) 
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

    -- ==================== 📊 底部状态栏 ====================
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
    InfoStroke.Color = Color3.fromRGB(65, 30, 50)
    InfoStroke.Parent = InfoPanel

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Size = UDim2.new(1, -10, 0, 18)
    FpsLabel.Position = UDim2.new(0, 8, 0, 6)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Text = "游戏帧数: 0 帧"
    FpsLabel.TextColor3 = Color3.fromRGB(200, 175, 190)
    FpsLabel.TextSize = 10
    ApplyFont(FpsLabel, Enum.FontWeight.Bold)
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.Parent = InfoPanel

    local VolLabel = Instance.new("TextLabel")
    VolLabel.Size = UDim2.new(1, -10, 0, 18)
    VolLabel.Position = UDim2.new(0, 8, 0, 24)
    VolLabel.BackgroundTransparency = 1
    VolLabel.Text = "游戏音量: 100%"
    VolLabel.TextColor3 = Color3.fromRGB(200, 175, 190)
    VolLabel.TextSize = 10
    ApplyFont(VolLabel, Enum.FontWeight.Bold)
    VolLabel.TextXAlignment = Enum.TextXAlignment.Left
    VolLabel.Parent = InfoPanel

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 0, 18)
    StatusLabel.Position = UDim2.new(0, 8, 0, 42)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "系统状态: 稳定运行"
    StatusLabel.TextColor3 = Color3.fromRGB(254, 74, 161)
    StatusLabel.TextSize = 9
    ApplyFont(StatusLabel, Enum.FontWeight.Bold)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = InfoPanel

    -- 计算 FPS
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

    -- 计算音量
    task.spawn(function()
        while task.wait(2) do
            local success, vol = pcall(function()
                return math.floor(UserSettings():GetService("UserGameSettings").MasterVolume * 100)
            end)
            if success then VolLabel.Text = "游戏音量: " .. vol .. "%" end
        end
    end)

    -- 6. 右侧内容面板
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

        -- 页面容器 (高精防溢出 UIPadding)
        local Page = Instance.new("ScrollingFrame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Color3.fromRGB(110, 45, 75)
        Page.Visible = false
        Page.Parent = ContentFrame

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingLeft = UDim.new(0, 6)
        PagePadding.PaddingRight = UDim.new(0, 10)
        PagePadding.PaddingTop = UDim.new(0, 6)
        PagePadding.PaddingBottom = UDim.new(0, 6)
        PagePadding.Parent = Page

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 6)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 15)
        end)

        -- 侧边栏切换按钮
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -4, 0, 28)
        TabBtn.BackgroundColor3 = Color3.fromRGB(36, 20, 30)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "   " .. tabName
        TabBtn.TextColor3 = Color3.fromRGB(150, 135, 145)
        TabBtn.TextSize = 11
        ApplyFont(TabBtn, Enum.FontWeight.Bold)
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
            
            -- 平滑滑入+淡入
            Page.Visible = true
            Page.Position = UDim2.new(0, 0, 0, 15)
            Animate(Page, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = UDim2.new(0, 0, 0, 0)})
            
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
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = labelText
            Label.TextColor3 = Color3.fromRGB(175, 155, 168)
            Label.TextSize = 11
            ApplyFont(Label, Enum.FontWeight.Medium)
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Page
            return Label
        end

        -- [[ 2. Premium Button ]]
        function Elements:CreateButton(btnText, callback)
            callback = callback or function() end

            local Card = Instance.new("TextButton")
            Card.Size = UDim2.new(1, 0, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35 
            Card.Text = ""
            Card.AutoButtonColor = false
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
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
            ApplyFont(Label, Enum.FontWeight.Bold)
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
                Animate(Card, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -4, 0, 30)})
            end)
            Card.MouseButton1Up:Connect(function()
                Animate(Card, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 32)})
                pcall(callback)
            end)
        end

        -- [[ 3. Premium Toggle ]]
        function Elements:CreateToggle(toggleText, default, callback)
            local state = default or false
            callback = callback or function() end

            local Card = Instance.new("TextButton")
            Card.Size = UDim2.new(1, 0, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35
            Card.Text = ""
            Card.AutoButtonColor = false
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
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
            ApplyFont(Label, Enum.FontWeight.Bold)
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
                
                -- 果冻在滑行中产生拉伸再回弹
                Animate(Dot, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(0, 14, 0, 9)})
                task.delay(0.08, function()
                    Animate(Dot, 0.18, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, {Size = UDim2.new(0, 10, 0, 10)})
                end)

                Animate(Switch, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = targetColor})
                Animate(Dot, 0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, {Position = targetPos})
                
                if state then
                    Animate(CardStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
                    Animate(Card, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(42, 18, 32), BackgroundTransparency = 0.2})
                else
                    Animate(CardStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(55, 30, 48)})
                    Animate(Card, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(30, 18, 26), BackgroundTransparency = 0.35})
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

        -- [[ 4. Premium Thick Slider (⭐ iOS / macOS 拟真音量粗拉条卡片) ]]
        function Elements:CreateSlider(sliderText, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end

            -- 28px 深度的一体化粗卡片
            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 28) 
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(55, 30, 48)
            CardStroke.Parent = Card

            -- 液态填充进度条
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
            Fill.BackgroundColor3 = accentColor
            Fill.BackgroundTransparency = 0.65 -- 透亮液态填充
            Fill.BorderSizePixel = 0
            Fill.Parent = Card

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(0, 6)
            FillCorner.Parent = Fill

            -- 边缘亮条
            local FillEdge = Instance.new("Frame")
            FillEdge.Size = UDim2.new(0, 2, 1, 0)
            FillEdge.Position = UDim2.new(1, -2, 0, 0)
            FillEdge.BackgroundColor3 = accentColor
            FillEdge.BorderSizePixel = 0
            FillEdge.Parent = Fill

            -- 数值和文本嵌入在拉条内部
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -80, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.ZIndex = 3
            Label.Text = sliderText:upper()
            Label.TextColor3 = Color3.fromRGB(255, 240, 248)
            Label.TextSize = 10
            ApplyFont(Label, Enum.FontWeight.Bold)
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Card

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 60, 1, 0)
            ValLabel.Position = UDim2.new(1, -12, 0, 0)
            ValLabel.BackgroundTransparency = 1
            ValLabel.ZIndex = 3
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ValLabel.TextSize = 10
            ApplyFont(ValLabel, Enum.FontWeight.Bold)
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = Card

            Card.MouseEnter:Connect(function()
                Animate(Card, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 31)}) -- 稍微膨胀变粗
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
                Animate(Fill, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.5}) -- 液体高亮
            end)
            Card.MouseLeave:Connect(function()
                Animate(Card, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 28)})
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(55, 30, 48)})
                Animate(Fill, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.65})
            end)

            -- 拖动
            local dragging = false
            local function Update(input)
                local percentage = math.clamp((input.Position.X - Card.AbsolutePosition.X) / Card.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * percentage)
                
                Animate(Fill, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(percentage, 0, 1, 0)})
                ValLabel.Text = tostring(value)
                pcall(callback, value)
            end

            Card.InputBegan:Connect(function(input)
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

        -- [[ 5. Premium TextBox (⭐ 极简无标输入框 - 支持内陷呼吸) ]]
        function Elements:CreateInput(placeholder, callback)
            placeholder = placeholder or "请输入参数并点击回车..."
            callback = callback or function() end

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Color3.fromRGB(55, 30, 48)
            CardStroke.Parent = Card

            local TextBox = Instance.new("TextBox")
            TextBox.Size = UDim2.new(1, -20, 1, 0)
            TextBox.Position = UDim2.new(0, 10, 0, 0)
            TextBox.BackgroundTransparency = 1
            TextBox.PlaceholderText = placeholder
            TextBox.PlaceholderColor3 = Color3.fromRGB(120, 95, 110)
            TextBox.Text = ""
            TextBox.TextColor3 = Color3.fromRGB(255, 235, 245)
            TextBox.TextSize = 11
            ApplyFont(TextBox, Enum.FontWeight.Medium)
            TextBox.Parent = Card

            -- 聚焦呼吸
            TextBox.Focused:Connect(function()
                Animate(Card, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, -6, 0, 30), BackgroundTransparency = 0.2})
                Animate(CardStroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accentColor})
            end)
            TextBox.FocusLost:Connect(function()
                Animate(Card, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 0.35})
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Color3.fromRGB(55, 30, 48)})
                pcall(callback, TextBox.Text)
            end)

            return {
                GetText = function() return TextBox.Text end,
                SetText = function(_, newText) TextBox.Text = newText pcall(callback, newText) end
            }
        end

        -- [[ 6. Premium Dropdown ]]
        function Elements:CreateDropdown(dropdownText, options, callback)
            options = options or {}
            callback = callback or function() end

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 32)
            Card.BackgroundColor3 = Color3.fromRGB(30, 18, 26)
            Card.BackgroundTransparency = 0.35
            Card.ClipsDescendants = true
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
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
            ApplyFont(Label, Enum.FontWeight.Bold)
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ClickBtn

            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 30, 0, 32)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Color3.fromRGB(160, 140, 150)
            Arrow.TextSize = 10
            ApplyFont(Arrow, Enum.FontWeight.Medium)
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
                Animate(Card, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, targetHeight)})
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
                    ApplyFont(OptBtn, Enum.FontWeight.Medium)
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
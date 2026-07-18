-- =============================================================================
--  高级自适应 Roblox UI 库 (支持PC & 移动端)
-- =============================================================================

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 清理旧 UI
if PlayerGui:FindFirstChild("OperitUILib") then
    PlayerGui:FindFirstChild("OperitUILib"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OperitUILib"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- === 颜色主题定义 ===
local Theme = {
    MainBg = Color3.fromRGB(255, 255, 255),
    SidebarBg = Color3.fromRGB(245, 247, 248),
    Accent = Color3.fromRGB(46, 204, 113), -- 活力绿
    AccentDark = Color3.fromRGB(39, 174, 96),
    TextDark = Color3.fromRGB(44, 62, 80),
    TextMuted = Color3.fromRGB(127, 140, 141),
    Border = Color3.fromRGB(230, 234, 237),
    ToggleOff = Color3.fromRGB(220, 224, 227),
    ToggleOn = Color3.fromRGB(231, 76, 60), -- 红色开关 (按原图)
    ComponentBg = Color3.fromRGB(248, 249, 250),
}

-- === 辅助工具函数 ===
local function AddCorner(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = obj
    return corner
end

local function AddStroke(obj, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = obj
    return stroke
end

-- === 拖动实现 (完美兼容PC/手机) ===
local function MakeDraggable(dragFrame, dragHandle)
    local dragging, dragInput, dragStart, startPos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragFrame.Position
            
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
            local delta = input.Position - dragStart
            -- 限制防止拖出屏幕外
            dragFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- === 通知系统 ===
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Size = UDim2.new(0, 300, 1, -40)
NotificationContainer.Position = UDim2.new(1, -320, 0, 20)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Padding = UDim.new(0, 10)
NotifLayout.Parent = NotificationContainer

local function CreateNotification(title, text, duration)
    duration = duration or 4
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 70)
    NotifFrame.BackgroundColor3 = Theme.MainBg
    NotifFrame.Position = UDim2.new(1.2, 0, 0, 0) -- 初始在屏幕右侧外
    NotifFrame.Parent = NotificationContainer
    AddCorner(NotifFrame, 8)
    local stroke = AddStroke(NotifFrame, Theme.Border, 1)

    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 5, 1, 0)
    AccentBar.BackgroundColor3 = Theme.Accent
    AccentBar.Parent = NotifFrame
    AddCorner(AccentBar, 8) -- 靠左的小绿条

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 25)
    TitleLabel.Position = UDim2.new(0, 15, 0, 8)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Theme.TextDark
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = NotifFrame

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, -20, 1, -35)
    TextLabel.Position = UDim2.new(0, 15, 0, 30)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = text
    TextLabel.TextColor3 = Theme.TextMuted
    TextLabel.Font = Enum.Font.Gotham
    TextLabel.TextSize = 12
    TextLabel.TextWrapped = true
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.TextYAlignment = Enum.TextYAlignment.Top
    TextLabel.Parent = NotifFrame

    -- 滑入动画
    TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    -- 延时自动消失
    task.delay(duration, function()
        local tween = TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1.2, 0, 0, 0)
        })
        tween:Play()
        tween.Completed:Wait()
        NotifFrame:Destroy()
    end)
end


-- === UI 库主类 ===
local Lib = {}

function Lib:CreateWindow(windowTitle)
    local Window = {
        CurrentTab = nil,
        Tabs = {}
    }

    -- 限制主窗口最大大小以适配移动端
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local frameWidth = isMobile and 380 or 480
    local frameHeight = isMobile and 280 or 340

    -- 主容器
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Theme.MainBg
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    AddCorner(MainFrame, 12)
    local MainStroke = AddStroke(MainFrame, Theme.Accent, 2) -- 活力绿描边

    -- 侧边栏 (导航栏)
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 130, 1, 0)
    Sidebar.BackgroundColor3 = Theme.SidebarBg
    Sidebar.Parent = MainFrame
    AddCorner(Sidebar, 12)

    -- 侧边栏滚动容器（防止Tab过多超出）
    local SidebarScroll = Instance.new("ScrollingFrame")
    SidebarScroll.Size = UDim2.new(1, 0, 1, -70)
    SidebarScroll.Position = UDim2.new(0, 0, 0, 70)
    SidebarScroll.BackgroundTransparency = 1
    SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SidebarScroll.ScrollBarThickness = 0
    SidebarScroll.Parent = Sidebar

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Padding = UDim.new(0, 6)
    SidebarLayout.Parent = SidebarScroll

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingLeft = UDim.new(0, 10)
    SidebarPadding.PaddingRight = UDim.new(0, 10)
    SidebarPadding.Parent = SidebarScroll

    -- 侧边栏顶部Logo占位 (小圆圈)
    local LogoContainer = Instance.new("Frame")
    LogoContainer.Size = UDim2.new(1, 0, 0, 60)
    LogoContainer.BackgroundTransparency = 1
    LogoContainer.Parent = Sidebar

    local LogoDot = Instance.new("Frame")
    LogoDot.Size = UDim2.new(0, 42, 0, 42)
    LogoDot.Position = UDim2.new(0.5, -21, 0.5, -21)
    LogoDot.BackgroundColor3 = Theme.Accent
    LogoDot.Parent = LogoContainer
    AddCorner(LogoDot, 100)

    local LogoText = Instance.new("TextLabel")
    LogoText.Size = UDim2.new(1, 0, 1, 0)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "UI"
    LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogoText.Font = Enum.Font.GothamBold
    LogoText.TextSize = 16
    LogoText.Parent = LogoDot

    -- 头部拖动区域 (右侧内容区的顶部)
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, -130, 0, 50)
    Header.Position = UDim2.new(0, 130, 0, 0)
    Header.BackgroundTransparency = 1
    Header.Parent = MainFrame

    -- 标题
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = windowTitle or "Operit UI Library"
    TitleLabel.TextColor3 = Theme.Accent
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    -- 关闭按钮
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundColor3 = Theme.ComponentBg
    CloseBtn.Text = "X" -- 使用普通可靠的 X 字母
    CloseBtn.TextColor3 = Theme.TextMuted
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = Header
    AddCorner(CloseBtn, 6)

    -- 右侧内容面板主容器
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -130, 1, -50)
    Container.Position = UDim2.new(0, 130, 0, 50)
    Container.BackgroundTransparency = 1
    Container.Parent = MainFrame

    -- 启用拖拽
    MakeDraggable(MainFrame, Header)
    MakeDraggable(MainFrame, Sidebar) -- 侧边栏也能拖

    -- === 悬浮球 (最小化切换开关) ===
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 50, 0, 50)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.1, 0)
    ToggleButton.BackgroundColor3 = Theme.Accent
    ToggleButton.Text = "UI"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 16
    ToggleButton.Visible = false -- 默认隐藏，主界面打开
    ToggleButton.Parent = ScreenGui
    AddCorner(ToggleButton, 100)
    AddStroke(ToggleButton, Color3.fromRGB(255,255,255), 2)
    MakeDraggable(ToggleButton, ToggleButton)

    -- 关闭逻辑
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true, function()
            MainFrame.Visible = false
            ToggleButton.Visible = true
        end)
    end)

    -- 悬浮按钮点击逻辑
    ToggleButton.MouseButton1Click:Connect(function()
        ToggleButton.Visible = false
        MainFrame.Visible = true
        MainFrame:TweenSize(UDim2.new(0, frameWidth, 0, frameHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.4, true)
    end)

    -- 自动调整 Sidebar 滚动条
    SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y)
    end)


    -- === TAB 创建方法 ===
    function Window:CreateTab(tabName)
        local Tab = {
            Active = false,
            PageFrame = nil,
            Button = nil
        }

        -- 创建页面滚动容器（保证移动端适配，内容多时可往下滑动）
        local PageScroll = Instance.new("ScrollingFrame")
        PageScroll.Size = UDim2.new(1, 0, 1, 0)
        PageScroll.BackgroundTransparency = 1
        PageScroll.Visible = false
        PageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        PageScroll.ScrollBarThickness = 2
        PageScroll.ScrollBarImageColor3 = Theme.Accent
        PageScroll.Parent = Container

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = PageScroll

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 10)
        PagePadding.PaddingLeft = UDim.new(0, 15)
        PagePadding.PaddingRight = UDim.new(0, 15)
        PagePadding.PaddingBottom = UDim.new(0, 15)
        PagePadding.Parent = PageScroll

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PageScroll.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 30)
        end)

        -- 侧边栏按钮
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = Theme.SidebarBg
        TabBtn.Text = tabName
        TabBtn.TextColor3 = Theme.TextMuted
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 13
        TabBtn.Parent = SidebarScroll
        AddCorner(TabBtn, 6)

        Tab.PageFrame = PageScroll
        Tab.Button = TabBtn

        -- 切换 Tab 的高亮激活逻辑
        local function Activate()
            for _, t in ipairs(Window.Tabs) do
                t.PageFrame.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Theme.SidebarBg,
                    TextColor3 = Theme.TextMuted
                }):Play()
            end
            PageScroll.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Theme.Accent,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            Window.CurrentTab = Tab
        end

        TabBtn.MouseButton1Click:Connect(Activate)

        if #Window.Tabs == 0 then
            Activate() -- 默认激活第一个Tab
        end

        table.insert(Window.Tabs, Tab)

        -- =====================================================================
        -- 组件生成：BUTTON (点击按钮)
        -- =====================================================================
        function Tab:CreateButton(text, callback)
            callback = callback or function() end
            
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 40)
            Btn.BackgroundColor3 = Theme.Accent
            Btn.Text = text
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 14
            Btn.Parent = PageScroll
            AddCorner(Btn, 8)

            -- 点击微缩放反馈动画
            Btn.MouseButton1Down:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(0.97, 0, 0, 38)}):Play()
            end)
            Btn.MouseButton1Up:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                callback()
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)}):Play()
            end)
        end

        -- =====================================================================
        -- 组件生成：TOGGLE (开关)
        -- =====================================================================
        function Tab:CreateToggle(text, default, callback)
            local state = default or false
            callback = callback or function() end

            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 45)
            ToggleFrame.BackgroundColor3 = Theme.ComponentBg
            ToggleFrame.Parent = PageScroll
            AddCorner(ToggleFrame, 8)
            AddStroke(ToggleFrame, Theme.Border, 1)

            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -80, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = Theme.TextDark
            ToggleLabel.Font = Enum.Font.GothamMedium
            ToggleLabel.TextSize = 14
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame

            -- 开关轨道
            local Track = Instance.new("TextButton")
            Track.Size = UDim2.new(0, 46, 0, 24)
            Track.Position = UDim2.new(1, -58, 0.5, -12)
            Track.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
            Track.Text = ""
            Track.Parent = ToggleFrame
            AddCorner(Track, 100)

            -- 开关摇杆
            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 18, 0, 18)
            Knob.Position = state and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 4, 0.5, -9)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.Parent = Track
            AddCorner(Knob, 100)

            local function updateToggle()
                local targetColor = state and Theme.ToggleOn or Theme.ToggleOff
                local targetPos = state and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 4, 0.5, -9)
                
                TweenService:Create(Track, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
                TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
                callback(state)
            end

            Track.MouseButton1Click:Connect(function()
                state = not state
                updateToggle()
            end)
        end

        -- =====================================================================
        -- 组件生成：SLIDER (拉条，兼容PC与手机触屏)
        -- =====================================================================
        function Tab:CreateSlider(text, min, max, default, callback)
            callback = callback or function() end
            local value = math.clamp(default or min, min, max)

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 55)
            SliderFrame.BackgroundColor3 = Theme.ComponentBg
            SliderFrame.Parent = PageScroll
            AddCorner(SliderFrame, 8)
            AddStroke(SliderFrame, Theme.Border, 1)

            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Size = UDim2.new(0.6, 0, 0, 25)
            SliderLabel.Position = UDim2.new(0, 12, 0, 4)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = text
            SliderLabel.TextColor3 = Theme.TextDark
            SliderLabel.Font = Enum.Font.GothamMedium
            SliderLabel.TextSize = 13
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = SliderFrame

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Size = UDim2.new(0.3, 0, 0, 25)
            ValueLabel.Position = UDim2.new(0.7, -12, 0, 4)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(value)
            ValueLabel.TextColor3 = Theme.Accent
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame

            -- 轨道
            local Track = Instance.new("TextButton")
            Track.Size = UDim2.new(1, -24, 0, 6)
            Track.Position = UDim2.new(0, 12, 0.7, -3)
            Track.BackgroundColor3 = Theme.ToggleOff
            Track.Text = ""
            Track.Parent = SliderFrame
            AddCorner(Track, 100)

            -- 进度填充
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.Parent = Track
            AddCorner(Fill, 100)

            -- 拖动逻辑
            local function updateSlider(input)
                local percentage = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * percentage)
                ValueLabel.Text = tostring(value)
                Fill.Size = UDim2.new(percentage, 0, 1, 0)
                callback(value)
            end

            local dragging = false
            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
        end

        -- =====================================================================
        -- 组件生成：DROPDOWN (下拉菜单)
        -- =====================================================================
        function Tab:CreateDropdown(text, list, callback)
            list = list or {}
            callback = callback or function() end
            local expanded = false

            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.BackgroundColor3 = Theme.ComponentBg
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = PageScroll
            AddCorner(DropdownFrame, 8)
            AddStroke(DropdownFrame, Theme.Border, 1)

            local HeaderBtn = Instance.new("TextButton")
            HeaderBtn.Size = UDim2.new(1, 0, 0, 40)
            HeaderBtn.BackgroundTransparency = 1
            HeaderBtn.Text = ""
            HeaderBtn.Parent = DropdownFrame

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.8, 0, 1, 0)
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = text
            Title.TextColor3 = Theme.TextDark
            Title.Font = Enum.Font.GothamMedium
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = HeaderBtn

            local Indicator = Instance.new("TextLabel")
            Indicator.Size = UDim2.new(0, 30, 0, 30)
            Indicator.Position = UDim2.new(1, -40, 0.5, -15)
            Indicator.BackgroundTransparency = 1
            Indicator.Text = "▼"
            Indicator.TextColor3 = Theme.TextMuted
            Indicator.Font = Enum.Font.GothamMedium
            Indicator.TextSize = 10
            Indicator.Parent = HeaderBtn

            -- 下拉列表项容器
            local OptionContainer = Instance.new("Frame")
            OptionContainer.Size = UDim2.new(1, 0, 0, #list * 35)
            OptionContainer.Position = UDim2.new(0, 0, 0, 40)
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.Parent = DropdownFrame

            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionLayout.Parent = OptionContainer

            -- 生成选项
            for i, val in ipairs(list) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 35)
                OptBtn.BackgroundTransparency = 1
                OptBtn.Text = "   " .. tostring(val)
                OptBtn.TextColor3 = Theme.TextMuted
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.TextSize = 12
                OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptBtn.LayoutOrder = i
                OptBtn.Parent = OptionContainer

                OptBtn.MouseEnter:Connect(function()
                    TweenService:Create(OptBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Accent}):Play()
                end)
                OptBtn.MouseLeave:Connect(function()
                    TweenService:Create(OptBtn, TweenInfo.new(0.15), {TextColor3 = Theme.TextMuted}):Play()
                end)

                OptBtn.MouseButton1Click:Connect(function()
                    Title.Text = text .. ": " .. tostring(val)
                    expanded = false
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                    TweenService:Create(Indicator, TweenInfo.new(0.3), {Rotation = 0}):Play()
                    callback(val)
                end)
            end

            -- 打开/关闭切换
            HeaderBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                local targetHeight = expanded and (40 + #list * 35) or 40
                local targetRotation = expanded and 180 or 0
                TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                TweenService:Create(Indicator, TweenInfo.new(0.3), {Rotation = targetRotation}):Play()
            end)
        end

        -- =====================================================================
        -- 组件生成：TEXTBOX (文本框输入)
        -- =====================================================================
        function Tab:CreateTextBox(text, placeholder, callback)
            callback = callback or function() end

            local BoxFrame = Instance.new("Frame")
            BoxFrame.Size = UDim2.new(1, 0, 0, 45)
            BoxFrame.BackgroundColor3 = Theme.ComponentBg
            BoxFrame.Parent = PageScroll
            AddCorner(BoxFrame, 8)
            local stroke = AddStroke(BoxFrame, Theme.Border, 1)

            local BoxLabel = Instance.new("TextLabel")
            BoxLabel.Size = UDim2.new(0.5, 0, 1, 0)
            BoxLabel.Position = UDim2.new(0, 12, 0, 0)
            BoxLabel.BackgroundTransparency = 1
            BoxLabel.Text = text
            BoxLabel.TextColor3 = Theme.TextDark
            BoxLabel.Font = Enum.Font.GothamMedium
            BoxLabel.TextSize = 13
            BoxLabel.TextXAlignment = Enum.TextXAlignment.Left
            BoxLabel.Parent = BoxFrame

            local RealInput = Instance.new("TextBox")
            RealInput.Size = UDim2.new(0.4, 0, 0, 26)
            RealInput.Position = UDim2.new(0.6, -12, 0.5, -13)
            RealInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            RealInput.Text = ""
            RealInput.PlaceholderText = placeholder or "输入..."
            RealInput.TextColor3 = Theme.TextDark
            RealInput.Font = Enum.Font.Gotham
            RealInput.TextSize = 12
            RealInput.ClipsDescendants = true
            RealInput.Parent = BoxFrame
            AddCorner(RealInput, 6)
            AddStroke(RealInput, Theme.Border, 1)

            -- 动画效果：输入时边框变绿色
            RealInput.Focused:Connect(function()
                TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
            end)
            RealInput.FocusLost:Connect(function(enterPressed)
                TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Theme.Border}):Play()
                callback(RealInput.Text)
            end)
        end

        -- =====================================================================
        -- 组件生成：COLOR PICKER (RGB 调色板)
        -- =====================================================================
        function Tab:CreateColorPicker(text, default, callback)
            default = default or Color3.fromRGB(255, 255, 255)
            callback = callback or function() end
            local expanded = false

            local PickerFrame = Instance.new("Frame")
            PickerFrame.Size = UDim2.new(1, 0, 0, 45)
            PickerFrame.BackgroundColor3 = Theme.ComponentBg
            PickerFrame.ClipsDescendants = true
            PickerFrame.Parent = PageScroll
            AddCorner(PickerFrame, 8)
            AddStroke(PickerFrame, Theme.Border, 1)

            local HeaderBtn = Instance.new("TextButton")
            HeaderBtn.Size = UDim2.new(1, 0, 0, 45)
            HeaderBtn.BackgroundTransparency = 1
            HeaderBtn.Text = ""
            HeaderBtn.Parent = PickerFrame

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.6, 0, 1, 0)
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = text
            Title.TextColor3 = Theme.TextDark
            Title.Font = Enum.Font.GothamMedium
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = HeaderBtn

            -- 颜色预览框
            local ColorPreview = Instance.new("Frame")
            ColorPreview.Size = UDim2.new(0, 30, 0, 20)
            ColorPreview.Position = UDim2.new(1, -45, 0.5, -10)
            ColorPreview.BackgroundColor3 = default
            ColorPreview.Parent = HeaderBtn
            AddCorner(ColorPreview, 4)
            AddStroke(ColorPreview, Theme.Border, 1)

            -- 内置滑块调整区
            local AdjustArea = Instance.new("Frame")
            AdjustArea.Size = UDim2.new(1, -24, 0, 100)
            AdjustArea.Position = UDim2.new(0, 12, 0, 45)
            AdjustArea.BackgroundTransparency = 1
            AdjustArea.Parent = PickerFrame

            local currentR, currentG, currentB = math.floor(default.R*255), math.floor(default.G*255), math.floor(default.B*255)

            local function createRGBSlider(colorName, layoutOrder, initVal, onChange)
                local SFrame = Instance.new("Frame")
                SFrame.Size = UDim2.new(1, 0, 0, 30)
                SFrame.BackgroundTransparency = 1
                SFrame.LayoutOrder = layoutOrder
                SFrame.Parent = AdjustArea

                local SLabel = Instance.new("TextLabel")
                SLabel.Size = UDim2.new(0.1, 0, 1, 0)
                SLabel.BackgroundTransparency = 1
                SLabel.Text = colorName
                SLabel.TextColor3 = Theme.TextDark
                SLabel.Font = Enum.Font.GothamBold
                SLabel.TextSize = 11
                SLabel.Parent = SFrame

                local STrack = Instance.new("TextButton")
                STrack.Size = UDim2.new(0.85, -10, 0, 4)
                STrack.Position = UDim2.new(0.12, 0, 0.5, -2)
                STrack.BackgroundColor3 = Theme.ToggleOff
                STrack.Text = ""
                STrack.Parent = SFrame
                AddCorner(STrack, 100)

                local SFill = Instance.new("Frame")
                SFill.Size = UDim2.new(initVal/255, 0, 1, 0)
                SFill.BackgroundColor3 = colorName == "R" and Color3.fromRGB(231, 76, 60) or (colorName == "G" and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(52, 152, 219))
                SFill.Parent = STrack
                AddCorner(SFill, 100)

                local function updateColorVal(input)
                    local percentage = math.clamp((input.Position.X - STrack.AbsolutePosition.X) / STrack.AbsoluteSize.X, 0, 1)
                    SFill.Size = UDim2.new(percentage, 0, 1, 0)
                    onChange(math.floor(percentage * 255))
                end

                local drag = false
                STrack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        drag = true
                        updateColorVal(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateColorVal(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        drag = false
                    end
                end)
            end

            local function fireCallback()
                local newColor = Color3.fromRGB(currentR, currentG, currentB)
                ColorPreview.BackgroundColor3 = newColor
                callback(newColor)
            end

            local AdjustLayout = Instance.new("UIListLayout")
            AdjustLayout.Padding = UDim.new(0, 2)
            AdjustLayout.Parent = AdjustArea

            createRGBSlider("R", 1, currentR, function(val) currentR = val fireCallback() end)
            createRGBSlider("G", 2, currentG, function(val) currentG = val fireCallback() end)
            createRGBSlider("B", 3, currentB, function(val) currentB = val fireCallback() end)

            HeaderBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                local targetHeight = expanded and 150 or 45
                TweenService:Create(PickerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
            end)
        end

        -- =====================================================================
        -- 组件生成：LABEL (标签)
        -- =====================================================================
        function Tab:CreateLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Theme.TextMuted
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = PageScroll
        end

        return Tab
    end

    return Window
end

-- 导出通知 API
function Lib:Notify(title, text, duration)
    CreateNotification(title, text, duration)
end

return Lib
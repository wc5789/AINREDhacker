-- =============================================================================
--  Operit UI Library (Modern Dark Theme)
--  支持拖拽、流畅动画、完整交互组件
-- =============================================================================

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- 自动获取渲染容器（优先使用 CoreGui，防止被游戏内其他 UI 遮挡；若在 Studio 无权限则使用 PlayerGui）
local TargetGui;
local success, err = pcall(function()
    TargetGui = CoreGui
end)
if not success or not TargetGui then
    TargetGui = LocalPlayer:WaitForChild("PlayerGui")
end

-- 创建主库对象
local Library = {}

-- 简易拖拽函数
local function MakeDraggable(gui, dragArea)
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragArea.InputChanged:Connect(function(input)
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

-- 创建窗口方法
function Library:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "Operit UI Library"
    
    -- 1. ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Operit_UILib"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = TargetGui
    
    -- 2. Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, 360)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(45, 45, 55)
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- 3. Top Bar (Header)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = TopBar
    
    -- 遮挡下半部分圆角
    local CornerCover = Instance.new("Frame")
    CornerCover.Size = UDim2.new(1, 0, 0, 10)
    CornerCover.Position = UDim2.new(0, 0, 1, -10)
    CornerCover.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    CornerCover.BorderSizePixel = 0
    CornerCover.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = TitleText
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- 关闭按钮
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    CloseBtn.TextSize = 24
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.Parent = TopBar
    
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 75, 75)}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    MakeDraggable(MainFrame, TopBar)

    -- 4. Sidebar (Tabs Area)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 140, 1, -40)
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    
    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Padding = UDim.new(0, 5)
    SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Parent = Sidebar
    
    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingTop = UDim.new(0, 10)
    SidebarPadding.Parent = Sidebar

    -- 5. Container (Content Area)
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, -140, 1, -40)
    Container.Position = UDim2.new(0, 140, 0, 40)
    Container.BackgroundTransparency = 1
    Container.Parent = MainFrame

    -- 多 Tab 管理系统
    local Tabs = {}
    local CurrentTab = nil

    function Tabs:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local TabName = tabConfig.Name or "Tab"
        
        -- 创建 Tab 按钮
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(0.9, 0, 0, 35)
        TabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "  " .. TabName
        TabBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
        TabBtn.TextSize = 13
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = Sidebar
        
        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 6)
        TabBtnCorner.Parent = TabBtn
        
        -- 创建 Tab 滚动面板
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
        TabPage.Visible = false
        TabPage.Parent = Container
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = TabPage
        
        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 12)
        PagePadding.PaddingBottom = UDim.new(0, 12)
        PagePadding.Parent = TabPage

        -- 自动调整滚动范围
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 25)
        end)

        -- 切换 Tab 激活逻辑
        local function Select()
            for _, t in pairs(Container:GetChildren()) do
                if t:IsA("ScrollingFrame") then t.Visible = false end
            end
            for _, b in pairs(Sidebar:GetChildren()) do
                if b:IsA("TextButton") then
                    TweenService:Create(b, TweenInfo.new(0.2), {
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.fromRGB(160, 160, 170)
                    }):Play()
                end
            end
            
            TabPage.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {
                BackgroundTransparency = 0,
                BackgroundColor3 = Color3.fromRGB(30, 30, 45),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        end

        TabBtn.MouseButton1Click:Connect(Select)
        
        -- 默认选择第一个 Tab
        if CurrentTab == nil then
            CurrentTab = TabName
            Select()
        end

        -- Component Creator inside Tab
        local Components = {}

        -- [1. Button 组件]
        function Components:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local Name = btnConfig.Name or "Button"
            local Callback = btnConfig.Callback or function() end
            
            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Size = UDim2.new(0.92, 0, 0, 38)
            BtnFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
            BtnFrame.AutoButtonColor = false
            BtnFrame.Text = ""
            BtnFrame.Parent = TabPage
            
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 6)
            Corner.Parent = BtnFrame
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = Color3.fromRGB(40, 40, 50)
            Stroke.Thickness = 1
            Stroke.Parent = BtnFrame

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -20, 1, 0)
            Text.Position = UDim2.new(0, 10, 0, 0)
            Text.BackgroundTransparency = 1
            Text.Text = Name
            Text.TextColor3 = Color3.fromRGB(230, 230, 240)
            Text.TextSize = 13
            Text.Font = Enum.Font.GothamMedium
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.Parent = BtnFrame

            local Icon = Instance.new("ImageLabel")
            Icon.Size = UDim2.new(0, 16, 0, 16)
            Icon.Position = UDim2.new(1, -26, 0.5, -8)
            Icon.BackgroundTransparency = 1
            Icon.Image = "rbxassetid://6031094678" -- 类似箭头的图标
            Icon.ImageColor3 = Color3.fromRGB(150, 150, 160)
            Icon.Parent = BtnFrame

            -- 动画反馈
            BtnFrame.MouseEnter:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(34, 34, 48)}):Play()
                TweenService:Create(Stroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(60, 60, 80)}):Play()
            end)
            BtnFrame.MouseLeave:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(26, 26, 36)}):Play()
                TweenService:Create(Stroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 40, 50)}):Play()
            end)
            BtnFrame.MouseButton1Down:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(40, 40, 60)}):Play()
            end)
            BtnFrame.MouseButton1Up:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(34, 34, 48)}):Play()
                task.spawn(Callback)
            end)
        end

        -- [2. Toggle 组件]
        function Components:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local Name = toggleConfig.Name or "Toggle"
            local Default = toggleConfig.Default or false
            local Callback = toggleConfig.Callback or function() end
            
            local Toggled = Default

            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Size = UDim2.new(0.92, 0, 0, 38)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
            ToggleFrame.AutoButtonColor = false
            ToggleFrame.Text = ""
            ToggleFrame.Parent = TabPage
            
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 6)
            Corner.Parent = ToggleFrame
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = Color3.fromRGB(40, 40, 50)
            Stroke.Thickness = 1
            Stroke.Parent = ToggleFrame

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -60, 1, 0)
            Text.Position = UDim2.new(0, 10, 0, 0)
            Text.BackgroundTransparency = 1
            Text.Text = Name
            Text.TextColor3 = Color3.fromRGB(230, 230, 240)
            Text.TextSize = 13
            Text.Font = Enum.Font.GothamMedium
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.Parent = ToggleFrame

            -- 开关背景框
            local SwitchBg = Instance.new("Frame")
            SwitchBg.Size = UDim2.new(0, 34, 0, 18)
            SwitchBg.Position = UDim2.new(1, -44, 0.5, -9)
            SwitchBg.BackgroundColor3 = Toggled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(45, 45, 55)
            SwitchBg.BorderSizePixel = 0
            SwitchBg.Parent = ToggleFrame
            
            local SwitchBgCorner = Instance.new("UICorner")
            SwitchBgCorner.CornerRadius = UDim.new(1, 0)
            SwitchBgCorner.Parent = SwitchBg

            -- 开关摇杆圆点
            local SwitchDot = Instance.new("Frame")
            SwitchDot.Size = UDim2.new(0, 14, 0, 14)
            SwitchDot.Position = Toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            SwitchDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SwitchDot.BorderSizePixel = 0
            SwitchDot.Parent = SwitchBg
            
            local SwitchDotCorner = Instance.new("UICorner")
            SwitchDotCorner.CornerRadius = UDim.new(1, 0)
            SwitchDotCorner.Parent = SwitchDot

            local function UpdateToggle()
                local targetPos = Toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                local targetColor = Toggled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(45, 45, 55)
                
                TweenService:Create(SwitchDot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
                TweenService:Create(SwitchBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
                
                task.spawn(Callback, Toggled)
            end

            ToggleFrame.MouseButton1Up:Connect(function()
                Toggled = not Toggled
                UpdateToggle()
            end)
            
            -- 悬停效果
            ToggleFrame.MouseEnter:Connect(function()
                TweenService:Create(ToggleFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(34, 34, 48)}):Play()
            end)
            ToggleFrame.MouseLeave:Connect(function()
                TweenService:Create(ToggleFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(26, 26, 36)}):Play()
            end)
        end

        -- [3. Slider 组件]
        function Components:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local Name = sliderConfig.Name or "Slider"
            local Min = sliderConfig.Min or 0
            local Max = sliderConfig.Max or 100
            local Default = sliderConfig.Default or Min
            local Callback = sliderConfig.Callback or function() end
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(0.92, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
            SliderFrame.Parent = TabPage
            
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 6)
            Corner.Parent = SliderFrame
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = Color3.fromRGB(40, 40, 50)
            Stroke.Thickness = 1
            Stroke.Parent = SliderFrame

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(0.7, 0, 0, 25)
            Text.Position = UDim2.new(0, 10, 0, 3)
            Text.BackgroundTransparency = 1
            Text.Text = Name
            Text.TextColor3 = Color3.fromRGB(230, 230, 240)
            Text.TextSize = 13
            Text.Font = Enum.Font.GothamMedium
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.Parent = SliderFrame

            local ValueText = Instance.new("TextLabel")
            ValueText.Size = UDim2.new(0.25, 0, 0, 25)
            ValueText.Position = UDim2.new(1, -135, 0, 3)
            ValueText.BackgroundTransparency = 1
            ValueText.Text = tostring(Default)
            ValueText.TextColor3 = Color3.fromRGB(0, 150, 255)
            ValueText.TextSize = 13
            ValueText.Font = Enum.Font.GothamBold
            ValueText.TextXAlignment = Enum.TextXAlignment.Right
            ValueText.Parent = SliderFrame

            -- 滑动轨道背景
            local SliderTrack = Instance.new("TextButton")
            SliderTrack.Size = UDim2.new(1, -20, 0, 6)
            SliderTrack.Position = UDim2.new(0, 10, 1, -14)
            SliderTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            SliderTrack.Text = ""
            SliderTrack.AutoButtonColor = false
            SliderTrack.BorderSizePixel = 0
            SliderTrack.Parent = SliderFrame
            
            local SliderTrackCorner = Instance.new("UICorner")
            SliderTrackCorner.CornerRadius = UDim.new(1, 0)
            SliderTrackCorner.Parent = SliderTrack

            -- 已填充的滑动轨道
            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new(math.clamp((Default - Min) / (Max - Min), 0, 1), 0, 1, 0)
            SliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            SliderFill.BorderSizePixel = 0
            SliderFill.Parent = SliderTrack
            
            local SliderFillCorner = Instance.new("UICorner")
            SliderFillCorner.CornerRadius = UDim.new(1, 0)
            SliderFillCorner.Parent = SliderFill

            -- 拖动逻辑
            local function UpdateSliderValue(input)
                local percentage = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                local value = math.floor(Min + (Max - Min) * percentage)
                
                SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                ValueText.Text = tostring(value)
                task.spawn(Callback, value)
            end

            local isDragging = false
            SliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    UpdateSliderValue(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSliderValue(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)
        end

        -- [4. Dropdown 组件]
        function Components:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local Name = dropdownConfig.Name or "Dropdown"
            local Options = dropdownConfig.Options or {}
            local Default = dropdownConfig.Default or Options[1]
            local Callback = dropdownConfig.Callback or function() end
            
            local DropdownOpen = false

            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(0.92, 0, 0, 38)
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = TabPage
            
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 6)
            Corner.Parent = DropdownFrame
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = Color3.fromRGB(40, 40, 50)
            Stroke.Thickness = 1
            Stroke.Parent = DropdownFrame

            -- 头部按钮（点击展开）
            local DropdownHeader = Instance.new("TextButton")
            DropdownHeader.Size = UDim2.new(1, 0, 0, 38)
            DropdownHeader.BackgroundTransparency = 1
            DropdownHeader.Text = ""
            DropdownHeader.Parent = DropdownFrame

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(0.6, 0, 1, 0)
            Text.Position = UDim2.new(0, 10, 0, 0)
            Text.BackgroundTransparency = 1
            Text.Text = Name .. ": " .. tostring(Default)
            Text.TextColor3 = Color3.fromRGB(230, 230, 240)
            Text.TextSize = 13
            Text.Font = Enum.Font.GothamMedium
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.Parent = DropdownHeader

            local Arrow = Instance.new("ImageLabel")
            Arrow.Size = UDim2.new(0, 16, 0, 16)
            Arrow.Position = UDim2.new(1, -26, 0.5, -8)
            Arrow.BackgroundTransparency = 1
            Arrow.Image = "rbxassetid://6034818372" -- 向下箭头
            Arrow.ImageColor3 = Color3.fromRGB(150, 150, 160)
            Arrow.Parent = DropdownHeader

            -- 下拉选项列表容器
            local OptionList = Instance.new("Frame")
            OptionList.Size = UDim2.new(1, -10, 0, #Options * 30)
            OptionList.Position = UDim2.new(0, 5, 0, 38)
            OptionList.BackgroundTransparency = 1
            OptionList.Parent = DropdownFrame
            
            local ListLayout = Instance.new("UIListLayout")
            ListLayout.Padding = UDim.new(0, 2)
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Parent = OptionList

            -- 生成选项列表
            for i, option in ipairs(Options) do
                local OptionBtn = Instance.new("TextButton")
                OptionBtn.Size = UDim2.new(1, 0, 0, 28)
                OptionBtn.BackgroundColor3 = Color3.fromRGB(33, 33, 46)
                OptionBtn.AutoButtonColor = false
                OptionBtn.Text = "  " .. tostring(option)
                OptionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
                OptionBtn.TextSize = 12
                OptionBtn.Font = Enum.Font.Gotham
                OptionBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptionBtn.Parent = OptionList
                
                local OptionCorner = Instance.new("UICorner")
                OptionCorner.CornerRadius = UDim.new(0, 4)
                OptionCorner.Parent = OptionBtn

                OptionBtn.MouseEnter:Connect(function()
                    TweenService:Create(OptionBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 45, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                end)
                OptionBtn.MouseLeave:Connect(function()
                    TweenService:Create(OptionBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(33, 33, 46), TextColor3 = Color3.fromRGB(180, 180, 190)}):Play()
                end)

                OptionBtn.MouseButton1Click:Connect(function()
                    Text.Text = Name .. ": " .. tostring(option)
                    DropdownOpen = false
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0.92, 0, 0, 38)}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                    task.spawn(Callback, option)
                end)
            end

            -- 打开/折叠动画
            DropdownHeader.MouseButton1Click:Connect(function()
                DropdownOpen = not DropdownOpen
                if DropdownOpen then
                    local targetHeight = 38 + (#Options * 30) + 10
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0.92, 0, 0, targetHeight)}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 180}):Play()
                else
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0.92, 0, 0, 38)}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                end
                
                -- 更新滑动页面整体大小
                task.wait(0.25)
                TabPage.CanvasSize = UDim2.new(0, 0, 0, TabPage.UIListLayout.AbsoluteContentSize.Y + 25)
            end)
        end

        -- [5. TextBox 输入框组件]
        function Components:CreateTextBox(textBoxConfig)
            textBoxConfig = textBoxConfig or {}
            local Name = textBoxConfig.Name or "Input"
            local Placeholder = textBoxConfig.Placeholder or "Enter text..."
            local Callback = textBoxConfig.Callback or function() end

            local BoxFrame = Instance.new("Frame")
            BoxFrame.Size = UDim2.new(0.92, 0, 0, 38)
            BoxFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
            BoxFrame.Parent = TabPage
            
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 6)
            Corner.Parent = BoxFrame
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = Color3.fromRGB(40, 40, 50)
            Stroke.Thickness = 1
            Stroke.Parent = BoxFrame

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(0.5, 0, 1, 0)
            Text.Position = UDim2.new(0, 10, 0, 0)
            Text.BackgroundTransparency = 1
            Text.Text = Name
            Text.TextColor3 = Color3.fromRGB(230, 230, 240)
            Text.TextSize = 13
            Text.Font = Enum.Font.GothamMedium
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.Parent = BoxFrame

            -- 文本输入框
            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(0.45, 0, 0, 24)
            Box.Position = UDim2.new(1, -Box.Size.X.Offset - 230, 0.5, -12) -- 计算自右边距对齐
            Box.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
            Box.Text = ""
            Box.PlaceholderText = Placeholder
            Box.TextColor3 = Color3.fromRGB(255, 255, 255)
            Box.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
            Box.TextSize = 12
            Box.Font = Enum.Font.Gotham
            Box.TextXAlignment = Enum.TextXAlignment.Center
            Box.ClearTextOnFocus = false
            Box.Parent = BoxFrame
            
            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UDim.new(0, 4)
            BoxCorner.Parent = Box

            local BoxStroke = Instance.new("UIStroke")
            BoxStroke.Color = Color3.fromRGB(35, 35, 45)
            BoxStroke.Thickness = 1
            BoxStroke.Parent = Box

            Box.FocusLost:Connect(function(enterPressed)
                task.spawn(Callback, Box.Text)
            end)
        end

        -- [6. Label 标签组件]
        function Components:CreateLabel(labelConfig)
            labelConfig = labelConfig or {}
            local Content = labelConfig.Text or "This is a label"
            
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(0.92, 0, 0, 28)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = TabPage

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -10, 1, 0)
            Text.Position = UDim2.new(0, 10, 0, 0)
            Text.BackgroundTransparency = 1
            Text.Text = Content
            Text.TextColor3 = Color3.fromRGB(180, 180, 190)
            Text.TextSize = 12
            Text.Font = Enum.Font.GothamSemibold
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.Parent = LabelFrame
        end

        return Components
    end

    return Tabs
end

return Library
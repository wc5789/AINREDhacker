-- [[ Modern Roblox UI Library ]] --
local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 自动获取最佳的 UI 父级 (优先 CoreGui，其次 PlayerGui)
local function GetGuiParent()
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success and coreGui then
        return coreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- 拖拽功能实现
local function MakeDraggable(topBar, mainFrame)
    local dragging, dragInput, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 快捷动画
local function Tween(obj, time, properties)
    local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, info, properties)
    tween:Play()
    return tween
end

-- 创建主窗口
function Library:CreateWindow(titleText)
    titleText = titleText or "Roblox UI Lib"
    
    -- 1. 基础容器
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OperitUiLib_" .. math.random(1000, 9999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetGuiParent()
    
    -- 销毁旧的同名 UI 防止重复
    for _, old in ipairs(GetGuiParent():GetChildren()) do
        if old.Name:match("^OperitUiLib_") and old ~= ScreenGui then
            old:Destroy()
        end
    end

    -- 2. 主框架
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, 340)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(35, 35, 35)
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- 3. 顶部栏 (TopBar)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 8)
    TopBarCorner.Parent = TopBar
    
    -- 遮挡底部的圆角以使顶部栏只有上方有圆角
    local TopBarCover = Instance.new("Frame")
    TopBarCover.Size = UDim2.new(1, 0, 0, 10)
    TopBarCover.Position = UDim2.new(0, 0, 1, -10)
    TopBarCover.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    TopBarCover.BorderSizePixel = 0
    TopBarCover.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    -- 关闭按钮
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    CloseBtn.TextSize = 22
    CloseBtn.Font = Enum.Font.GothamMedium
    CloseBtn.Parent = TopBar

    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, 0.2, {TextColor3 = Color3.fromRGB(255, 75, 75)}) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, 0.2, {TextColor3 = Color3.fromRGB(150, 150, 150)}) end)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    MakeDraggable(TopBar, MainFrame)

    -- 4. 侧边栏 (Tab 导航栏)
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Size = UDim2.new(0, 130, 1, -35)
    SideBar.Position = UDim2.new(0, 0, 0, 35)
    SideBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    SideBar.BorderSizePixel = 0
    SideBar.Parent = MainFrame

    local SideBarLine = Instance.new("Frame")
    SideBarLine.Size = UDim2.new(0, 1, 1, 0)
    SideBarLine.Position = UDim2.new(1, -1, 0, 0)
    SideBarLine.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    SideBarLine.BorderSizePixel = 0
    SideBarLine.Parent = SideBar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -5, 1, -10)
    TabContainer.Position = UDim2.new(0, 5, 0, 5)
    TabContainer.BackgroundTransparency = 1
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.ScrollBarThickness = 2
    TabContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    TabContainer.Parent = SideBar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabContainer

    -- 5. 内容展示区 (Pages 容器)
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -135, 1, -40)
    ContentFrame.Position = UDim2.new(0, 135, 0, 38)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    local Pages = {}
    local CurrentTab = nil

    -- Tab 创建函数
    function Pages:CreateTab(tabName)
        tabName = tabName or "Tab"
        
        -- 创建对应的 Page (内容页)
        local Page = Instance.new("ScrollingFrame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.ScrollBarThickness = 4
        Page.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
        Page.Visible = false
        Page.Parent = ContentFrame

        local PageList = Instance.new("UIListLayout")
        PageList.Padding = UDim.new(0, 6)
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Parent = Page
        
        -- 动态自适应 Content 高度
        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 10)
        end)

        -- 创建导航 Tab 按钮
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -5, 0, 30)
        TabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "  " .. tabName
        TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        TabBtn.TextSize = 13
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabContainer

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 4)
        TabBtnCorner.Parent = TabBtn

        -- 切换激活状态的逻辑
        local function Select()
            for _, child in ipairs(ContentFrame:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            for _, child in ipairs(TabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    Tween(child, 0.2, {TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1})
                end
            end
            Page.Visible = true
            Tween(TabBtn, 0.2, {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(30, 30, 30)})
        end

        TabBtn.MouseButton1Click:Connect(Select)

        -- 默认选中第一个创建的 Tab
        if CurrentTab == nil then
            CurrentTab = tabName
            Select()
        end

        local TabElements = {}

        -- [[ 1. Label 标签控件 ]]
        function TabElements:CreateLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -10, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(180, 180, 180)
            Label.TextSize = 12
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Page
            
            local Elements = {}
            function Elements:Update(newText)
                Label.Text = newText
            end
            return Elements
        end

        -- [[ 2. Button 按钮控件 ]]
        function TabElements:CreateButton(btnText, callback)
            callback = callback or function() end
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, -10, 0, 32)
            Button.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
            Button.Text = ""
            Button.AutoButtonColor = false
            Button.Parent = Page

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 5)
            BtnCorner.Parent = Button

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Color = Color3.fromRGB(40, 40, 40)
            BtnStroke.Parent = Button

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = btnText
            Label.TextColor3 = Color3.fromRGB(220, 220, 220)
            Label.TextSize = 13
            Label.Font = Enum.Font.GothamMedium
            Label.Parent = Button

            -- Hover & Click FX
            Button.MouseEnter:Connect(function()
                Tween(Button, 0.2, {BackgroundColor3 = Color3.fromRGB(32, 32, 32)})
                Tween(BtnStroke, 0.2, {Color = Color3.fromRGB(0, 162, 255)})
            end)
            Button.MouseLeave:Connect(function()
                Tween(Button, 0.2, {BackgroundColor3 = Color3.fromRGB(26, 26, 26)})
                Tween(BtnStroke, 0.2, {Color = Color3.fromRGB(40, 40, 40)})
            end)
            Button.MouseButton1Down:Connect(function()
                Tween(Button, 0.05, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)})
            end)
            Button.MouseButton1Up:Connect(function()
                Tween(Button, 0.05, {BackgroundColor3 = Color3.fromRGB(32, 32, 32)})
                pcall(callback)
            end)
        end

        -- [[ 3. Toggle 开关控件 ]]
        function TabElements:CreateToggle(toggleText, default, callback)
            local state = default or false
            callback = callback or function() end

            local Toggle = Instance.new("TextButton")
            Toggle.Size = UDim2.new(1, -10, 0, 32)
            Toggle.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
            Toggle.Text = ""
            Toggle.AutoButtonColor = false
            Toggle.Parent = Page

            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 5)
            ToggleCorner.Parent = Toggle

            local ToggleStroke = Instance.new("UIStroke")
            ToggleStroke.Color = Color3.fromRGB(40, 40, 40)
            ToggleStroke.Parent = Toggle

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -50, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = toggleText
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.TextSize = 13
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Toggle

            -- 开关背景滑槽
            local FrameSwitch = Instance.new("Frame")
            FrameSwitch.Size = UDim2.new(0, 34, 0, 18)
            FrameSwitch.Position = UDim2.new(1, -44, 0.5, -9)
            FrameSwitch.BackgroundColor3 = state and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(50, 50, 50)
            FrameSwitch.Parent = Toggle

            local FrameCorner = Instance.new("UICorner")
            FrameCorner.CornerRadius = UDim.new(1, 0)
            FrameCorner.Parent = FrameSwitch

            -- 开关小圆点
            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 14, 0, 14)
            Dot.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Dot.Parent = FrameSwitch

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = Dot

            local function UpdateToggle()
                local targetBg = state and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(50, 50, 50)
                local targetPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                Tween(FrameSwitch, 0.2, {BackgroundColor3 = targetBg})
                Tween(Dot, 0.2, {Position = targetPos})
                pcall(callback, state)
            end

            Toggle.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggle()
            end)

            Toggle.MouseEnter:Connect(function() Tween(ToggleStroke, 0.2, {Color = Color3.fromRGB(80, 80, 80)}) end)
            Toggle.MouseLeave:Connect(function() Tween(ToggleStroke, 0.2, {Color = Color3.fromRGB(40, 40, 40)}) end)
            
            local Elements = {}
            function Elements:Set(val)
                state = val
                UpdateToggle()
            end
            return Elements
        end

        -- [[ 4. Slider 滑动条控件 ]]
        function TabElements:CreateSlider(sliderText, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end

            local Slider = Instance.new("Frame")
            Slider.Size = UDim2.new(1, -10, 0, 45)
            Slider.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
            Slider.Parent = Page

            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 5)
            SliderCorner.Parent = Slider

            local SliderStroke = Instance.new("UIStroke")
            SliderStroke.Color = Color3.fromRGB(40, 40, 40)
            SliderStroke.Parent = Slider

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -80, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 4)
            Label.BackgroundTransparency = 1
            Label.Text = sliderText
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.TextSize = 13
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Slider

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 60, 0, 20)
            ValLabel.Position = UDim2.new(1, -70, 0, 4)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
            ValLabel.TextSize = 13
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = Slider

            -- 滑槽
            local SliderBar = Instance.new("TextButton")
            SliderBar.Size = UDim2.new(1, -20, 0, 6)
            SliderBar.Position = UDim2.new(0, 10, 0, 28)
            SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            SliderBar.Text = ""
            SliderBar.AutoButtonColor = false
            SliderBar.Parent = Slider

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = SliderBar

            -- 填充区
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
            Fill.BorderSizePixel = 0
            Fill.Parent = SliderBar

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            -- 拖动逻辑
            local dragging = false
            local function UpdateValue(input)
                local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * percentage)
                Fill.Size = UDim2.new(percentage, 0, 1, 0)
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
                Fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
                ValLabel.Text = tostring(val)
                pcall(callback, val)
            end
            return Elements
        end

        -- [[ 5. Dropdown 下拉框控件 ]]
        function TabElements:CreateDropdown(dropdownText, options, callback)
            options = options or {}
            callback = callback or function() end

            local Dropdown = Instance.new("Frame")
            Dropdown.Size = UDim2.new(1, -10, 0, 32)
            Dropdown.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
            Dropdown.ClipsDescendants = true
            Dropdown.Parent = Page

            local DropCorner = Instance.new("UICorner")
            DropCorner.CornerRadius = UDim.new(0, 5)
            DropCorner.Parent = Dropdown

            local DropStroke = Instance.new("UIStroke")
            DropStroke.Color = Color3.fromRGB(40, 40, 40)
            DropStroke.Parent = Dropdown

            local ClickBtn = Instance.new("TextButton")
            ClickBtn.Size = UDim2.new(1, 0, 0, 32)
            ClickBtn.BackgroundTransparency = 1
            ClickBtn.Text = ""
            ClickBtn.Parent = Dropdown

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -40, 0, 32)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = dropdownText
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.TextSize = 13
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ClickBtn

            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 30, 0, 32)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Color3.fromRGB(150, 150, 150)
            Arrow.TextSize = 11
            Arrow.Font = Enum.Font.GothamMedium
            Arrow.Parent = ClickBtn

            local OptionContainer = Instance.new("Frame")
            OptionContainer.Size = UDim2.new(1, -10, 0, 0)
            OptionContainer.Position = UDim2.new(0, 5, 0, 34)
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.Parent = Dropdown

            local OptionList = Instance.new("UIListLayout")
            OptionList.Padding = UDim.new(0, 4)
            OptionList.Parent = OptionContainer

            local open = false
            local function ToggleDropdown()
                open = not open
                local targetHeight = open and (36 + OptionList.AbsoluteContentSize.Y) or 32
                Tween(Dropdown, 0.2, {Size = UDim2.new(1, -10, 0, targetHeight)})
                Arrow.Text = open and "▲" or "▼"
            end

            ClickBtn.MouseButton1Click:Connect(ToggleDropdown)

            local function RefreshOptions()
                for _, child in ipairs(OptionContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for _, optName in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 26)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
                    OptBtn.Text = "  " .. optName
                    OptBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
                    OptBtn.TextSize = 12
                    OptBtn.Font = Enum.Font.GothamMedium
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.Parent = OptionContainer

                    local OptCorner = Instance.new("UICorner")
                    OptCorner.CornerRadius = UDim.new(0, 4)
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
                    Tween(Dropdown, 0.2, {Size = UDim2.new(1, -10, 0, 36 + OptionList.AbsoluteContentSize.Y)})
                end
            end
            return Elements
        end

        return TabElements
    end

    return Pages
end

return Library
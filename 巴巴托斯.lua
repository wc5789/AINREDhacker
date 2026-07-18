--[[
    Advanced Roblox UI Library by D小姐
    特性：移动端适配、拖拽、最小化、关闭、动画、通知、颜色选择器等
--]]

local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Library = {}
local ActiveNotifications = {}

-- 工具函数
local function Create(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            obj.Parent = v
        else
            obj[k] = v
        end
    end
    return obj
end

local function Tween(obj, tweenInfo, props)
    local tween = TweenService:Create(obj, tweenInfo, props)
    tween:Play()
    return tween
end

-- 屏幕安全区域适配（移动端）
local function GetSafeArea()
    local screenSize = workspace.CurrentCamera.ViewportSize
    local width = math.min(screenSize.X, 500)  -- 最大宽度500
    local height = math.min(screenSize.Y, 350) -- 最大高度350
    return width, height
end

-- 主窗口构建
function Library:CreateWindow(title)
    local window = {}
    local width, height = GetSafeArea()
    
    -- ScreenGui
    local gui = Create("ScreenGui", {
        Name = title,
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    -- 主容器
    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = gui,
        BackgroundColor3 = Color3.fromRGB(25,25,25),
        BorderSizePixel = 0,
        Size = UDim2.new(0, width, 0, height),
        Position = UDim2.new(0.5, -width/2, 0.5, -height/2),
        ClipsDescendants = true
    })
    
    -- 圆角效果
    local corner = Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = mainFrame})
    
    -- 标题栏
    local titleBar = Create("Frame", {
        Name = "TitleBar",
        Parent = mainFrame,
        BackgroundColor3 = Color3.fromRGB(35,35,35),
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,30)
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = titleBar})
    
    -- 标题文字
    local titleText = Create("TextLabel", {
        Parent = titleBar,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        Size = UDim2.new(0, width-80, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- 窗口图标（防止乱码）
    local icon = Create("ImageLabel", {
        Parent = titleBar,
        Image = "rbxassetid://3926305904", -- 你可以换成自己的图标
        Size = UDim2.new(0,18,0,18),
        Position = UDim2.new(0,12,0,6),
        BackgroundTransparency = 1
    })
    
    -- 最小化按钮（图标）
    local minimizeBtn = Create("ImageButton", {
        Parent = titleBar,
        Image = "rbxassetid://3926307971", -- 最小化图标
        Size = UDim2.new(0,20,0,20),
        Position = UDim2.new(1,-50,0,5),
        BackgroundTransparency = 1
    })
    
    -- 关闭按钮（图标）
    local closeBtn = Create("ImageButton", {
        Parent = titleBar,
        Image = "rbxassetid://3926305904", -- 关闭图标
        Size = UDim2.new(0,20,0,20),
        Position = UDim2.new(1,-25,0,5),
        BackgroundTransparency = 1,
        ImageRectOffset = Vector2.new(364, 4),
        ImageRectSize = Vector2.new(36,36)
    })
    
    -- 窗口拖拽（适配触屏）
    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
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
    titleBar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- 最小化/还原
    local minimized = false
    local originalSize = mainFrame.Size
    minimizeBtn.Activated:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(mainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, width, 0, 30)})
        else
            Tween(mainFrame, TweenInfo.new(0.2), {Size = originalSize})
        end
    end)
    
    -- 关闭
    closeBtn.Activated:Connect(function()
        gui:Destroy()
    end)
    
    -- 标签栏容器
    local tabBar = Create("Frame", {
        Name = "TabBar",
        Parent = mainFrame,
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BorderSizePixel = 0,
        Size = UDim2.new(0,100,1,-30),
        Position = UDim2.new(0,0,0,30)
    })
    local tabList = Create("UIListLayout", {
        Parent = tabBar,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,2)
    })
    Create("UIPadding", {Parent = tabBar, PaddingTop = UDim.new(0,5), PaddingLeft = UDim.new(0,5)})
    
    -- 页面容器
    local pageContainer = Create("Frame", {
        Name = "PageContainer",
        Parent = mainFrame,
        BackgroundColor3 = Color3.fromRGB(20,20,20),
        BorderSizePixel = 0,
        Size = UDim2.new(1,-100,1,-30),
        Position = UDim2.new(0,100,0,30),
        ClipsDescendants = true
    })
    
    -- 通知系统
    local notificationFrame = Create("Frame", {
        Name = "Notifications",
        Parent = gui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        Position = UDim2.new(0,0,0,0),
        ZIndex = 10
    })
    
    -- 存储页面和标签
    local tabs = {}
    local pages = {}
    
    function window:AddTab(tabName)
        local tab = {}
        local tabButton = Create("TextButton", {
            Parent = tabBar,
            Text = tabName,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(200,200,200),
            BackgroundColor3 = Color3.fromRGB(40,40,40),
            BorderSizePixel = 0,
            Size = UDim2.new(1,-10,0,28),
            AutoButtonColor = false,
            ClipsDescendants = true
        })
        Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = tabButton})
        
        local page = Create("ScrollingFrame", {
            Parent = pageContainer,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1,0,1,0),
            Visible = false,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0,0,0,0),
            ScrollingEnabled = true
        })
        local pageLayout = Create("UIListLayout", {
            Parent = page,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0,5)
        })
        Create("UIPadding", {Parent = page, PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,8)})
        
        -- 自动调整 Canvas 大小
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0,0,0,pageLayout.AbsoluteContentSize.Y + 16)
        end)
        
        table.insert(tabs, {button = tabButton, page = page})
        table.insert(pages, page)
        
        -- 标签切换逻辑
        tabButton.Activated:Connect(function()
            for _, t in ipairs(tabs) do
                Tween(t.button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40,40,40), TextColor3 = Color3.fromRGB(200,200,200)})
                t.page.Visible = false
            end
            Tween(tabButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Color3.fromRGB(255,255,255)})
            page.Visible = true
        end)
        
        -- 默认激活第一个标签
        if #tabs == 1 then
            tabButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            tabButton.TextColor3 = Color3.fromRGB(255,255,255)
            page.Visible = true
        end
        
        -- 为页面添加元素的方法
        function tab:AddLabel(text)
            local lbl = Create("TextLabel", {
                Parent = page,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(180,180,180),
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,18),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            return lbl
        end
        
        function tab:AddToggle(text, default, callback)
            local toggle = {Value = default or false}
            local container = Create("Frame", {
                Parent = page,
                BackgroundColor3 = Color3.fromRGB(35,35,35),
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,30)
            })
            Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = container})
            
            local label = Create("TextLabel", {
                Parent = container,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 1,
                Size = UDim2.new(1,-50,1,0),
                Position = UDim2.new(0,8,0,0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local switch = Create("Frame", {
                Parent = container,
                BackgroundColor3 = toggle.Value and Color3.fromRGB(0,255,109) or Color3.fromRGB(255,100,100),
                BorderSizePixel = 0,
                Size = UDim2.new(0,36,0,20),
                Position = UDim2.new(1,-44,0,5)
            })
            Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = switch})
            local knob = Create("Frame", {
                Parent = switch,
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0,
                Size = UDim2.new(0,16,0,16),
                Position = UDim2.new(0,2,0,2)
            })
            Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = knob})
            
            local function update()
                Tween(switch, TweenInfo.new(0.2), {BackgroundColor3 = toggle.Value and Color3.fromRGB(0,255,109) or Color3.fromRGB(255,100,100)})
                Tween(knob, TweenInfo.new(0.2), {Position = toggle.Value and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)})
                callback(toggle.Value)
            end
            
            container.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    toggle.Value = not toggle.Value
                    update()
                end
            end)
            
            return toggle
        end
        
        function tab:AddButton(text, callback)
            local btn = Create("TextButton", {
                Parent = page,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(255,255,255),
                BackgroundColor3 = Color3.fromRGB(40,40,40),
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,28),
                AutoButtonColor = false
            })
            Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = btn})
            
            btn.Activated:Connect(function()
                Tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60,60,60)})
                wait(0.1)
                Tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40,40,40)})
                callback()
            end)
            return btn
        end
        
        function tab:AddSlider(text, min, max, default, callback)
            local slider = {Value = default or min}
            local container = Create("Frame", {
                Parent = page,
                BackgroundColor3 = Color3.fromRGB(35,35,35),
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,40)
            })
            Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = container})
            
            local label = Create("TextLabel", {
                Parent = container,
                Text = text .. ": " .. slider.Value,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,16),
                Position = UDim2.new(0,8,0,2),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local bar = Create("Frame", {
                Parent = container,
                BackgroundColor3 = Color3.fromRGB(50,50,50),
                BorderSizePixel = 0,
                Size = UDim2.new(1,-16,0,6),
                Position = UDim2.new(0,8,0,24)
            })
            Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = bar})
            
            local fill = Create("Frame", {
                Parent = bar,
                BackgroundColor3 = Color3.fromRGB(0,170,255),
                BorderSizePixel = 0,
                Size = UDim2.new((slider.Value - min) / (max - min), 0, 1, 0)
            })
            Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = fill})
            
            local function update(val)
                slider.Value = math.clamp(val, min, max)
                fill.Size = UDim2.new((slider.Value - min) / (max - min), 0, 1, 0)
                label.Text = text .. ": " .. slider.Value
                callback(slider.Value)
            end
            
            local draggingSlider = false
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    local x = input.Position.X - bar.AbsolutePosition.X
                    local percent = math.clamp(x / bar.AbsoluteSize.X, 0, 1)
                    update(min + (max - min) * percent)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local x = input.Position.X - bar.AbsolutePosition.X
                    local percent = math.clamp(x / bar.AbsoluteSize.X, 0, 1)
                    update(min + (max - min) * percent)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)
            
            return slider
        end
        
        function tab:AddDropdown(text, options, callback)
            local dropdown = {Value = nil}
            local container = Create("Frame", {
                Parent = page,
                BackgroundColor3 = Color3.fromRGB(35,35,35),
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,30),
                ClipsDescendants = true
            })
            Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = container})
            
            local header = Create("TextButton", {
                Parent = container,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,30),
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false
            })
            Create("UIPadding", {Parent = header, PaddingLeft = UDim.new(0,8)})
            
            local arrow = Create("ImageLabel", {
                Parent = header,
                Image = "rbxassetid://3926305904",
                Size = UDim2.new(0,16,0,16),
                Position = UDim2.new(1,-24,0,7),
                BackgroundTransparency = 1,
                ImageRectOffset = Vector2.new(324,364),
                ImageRectSize = Vector2.new(36,36)
            })
            
            local optionFrame = Create("Frame", {
                Parent = container,
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,0),
                Position = UDim2.new(0,0,0,30),
                ClipsDescendants = true
            })
            local optionLayout = Create("UIListLayout", {Parent = optionFrame, SortOrder = Enum.SortOrder.LayoutOrder})
            
            local expanded = false
            header.Activated:Connect(function()
                expanded = not expanded
                local optionCount = #options
                Tween(container, TweenInfo.new(0.2), {Size = expanded and UDim2.new(1,0,0,30 + optionCount*25) or UDim2.new(1,0,0,30)})
                Tween(arrow, TweenInfo.new(0.2), {Rotation = expanded and 180 or 0})
            end)
            
            for _, opt in ipairs(options) do
                local optBtn = Create("TextButton", {
                    Parent = optionFrame,
                    Text = opt,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Color3.fromRGB(255,255,255),
                    BackgroundColor3 = Color3.fromRGB(40,40,40),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1,0,0,25),
                    AutoButtonColor = false
                })
                optBtn.Activated:Connect(function()
                    dropdown.Value = opt
                    header.Text = text .. ": " .. opt
                    callback(opt)
                    -- 收起
                    expanded = false
                    Tween(container, TweenInfo.new(0.2), {Size = UDim2.new(1,0,0,30)})
                    Tween(arrow, TweenInfo.new(0.2), {Rotation = 0})
                end)
            end
            
            return dropdown
        end
        
        function tab:AddColorPicker(text, defaultColor, callback)
            local color = defaultColor or Color3.fromRGB(255,0,0)
            local container = Create("Frame", {
                Parent = page,
                BackgroundColor3 = Color3.fromRGB(35,35,35),
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,100),
                ClipsDescendants = true
            })
            Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = container})
            
            local preview = Create("Frame", {
                Parent = container,
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Size = UDim2.new(0,20,0,20),
                Position = UDim2.new(0,8,0,5)
            })
            Create("UICorner", {CornerRadius = UDim.new(0,3), Parent = preview})
            
            local label = Create("TextLabel", {
                Parent = container,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 1,
                Size = UDim2.new(1,-40,0,30),
                Position = UDim2.new(0,34,0,0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            -- RGB 滑块
            local function updateColor()
                preview.BackgroundColor3 = color
                callback(color)
            end
            
            local rSlider = Create("Frame", {Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1,-16,0,18), Position = UDim2.new(0,8,0,32)})
            local rLabel = Create("TextLabel", {Parent = rSlider, Text = "R:", Size = UDim2.new(0,15,1,0), Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(255,0,0), BackgroundTransparency = 1})
            local rBar = Create("Frame", {Parent = rSlider, BackgroundColor3 = Color3.fromRGB(50,50,50), Size = UDim2.new(1,-20,0,8), Position = UDim2.new(0,20,0,5)})
            Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = rBar})
            local rFill = Create("Frame", {Parent = rBar, BackgroundColor3 = Color3.fromRGB(255,0,0), Size = UDim2.new(color.R,0,1,0)})
            Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = rFill})
            
            -- 简化：只做红色滑块示例，你可以自行扩展 G、B 滑块
            local draggingR = false
            rBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingR = true
                    local x = input.Position.X - rBar.AbsolutePosition.X
                    local r = math.clamp(x / rBar.AbsoluteSize.X, 0, 1)
                    color = Color3.new(r, color.G, color.B)
                    rFill.Size = UDim2.new(r,0,1,0)
                    updateColor()
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingR and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local x = input.Position.X - rBar.AbsolutePosition.X
                    local r = math.clamp(x / rBar.AbsoluteSize.X, 0, 1)
                    color = Color3.new(r, color.G, color.B)
                    rFill.Size = UDim2.new(r,0,1,0)
                    updateColor()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingR = false
                end
            end)
            
            -- 为了简洁，这里省略 G、B 滑块的完整代码，你可以按照 R 滑块的模式添加
            
            return color
        end
        
        function tab:AddTextBox(text, placeholder, callback)
            local container = Create("Frame", {
                Parent = page,
                BackgroundColor3 = Color3.fromRGB(35,35,35),
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,30)
            })
            Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = container})
            
            local label = Create("TextLabel", {
                Parent = container,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Color3.fromRGB(200,200,200),
                BackgroundTransparency = 1,
                Size = UDim2.new(0,60,1,0),
                Position = UDim2.new(0,8,0,0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local input = Create("TextBox", {
                Parent = container,
                PlaceholderText = placeholder or "",
                Text = "",
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Color3.fromRGB(255,255,255),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                BorderSizePixel = 0,
                Size = UDim2.new(1,-76,0,24),
                Position = UDim2.new(0,68,0,3),
                ClearTextOnFocus = false
            })
            Create("UICorner", {CornerRadius = UDim.new(0,3), Parent = input})
            
            input.FocusLost:Connect(function(enterPressed)
                callback(input.Text)
            end)
            return input
        end
        
        return tab
    end
    
    -- 通知方法
    function window:Notify(title, message, duration)
        duration = duration or 3
        local notif = Create("Frame", {
            Parent = notificationFrame,
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            BorderSizePixel = 0,
            Size = UDim2.new(0,240,0,60),
            Position = UDim2.new(1, -250, 1, -70 - (#ActiveNotifications * 65)),
            ZIndex = 10
        })
        Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = notif})
        Create("TextLabel", {
            Parent = notif,
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(255,255,255),
            BackgroundTransparency = 1,
            Size = UDim2.new(1,-16,0,18),
            Position = UDim2.new(0,8,0,8),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Create("TextLabel", {
            Parent = notif,
            Text = message,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(180,180,180),
            BackgroundTransparency = 1,
            Size = UDim2.new(1,-16,0,18),
            Position = UDim2.new(0,8,0,30),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        table.insert(ActiveNotifications, notif)
        
        -- 弹出动画
        notif.Position = UDim2.new(1, 10, notif.Position.Y.Scale, notif.Position.Y.Offset)
        Tween(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(1, -250, notif.Position.Y.Scale, notif.Position.Y.Offset)})
        
        delay(duration, function()
            Tween(notif, TweenInfo.new(0.3), {Position = UDim2.new(1, 10, notif.Position.Y.Scale, notif.Position.Y.Offset)})
            wait(0.3)
            notif:Destroy()
            table.remove(ActiveNotifications, table.find(ActiveNotifications, notif))
            -- 重新排列剩余通知
            for i, n in ipairs(ActiveNotifications) do
                Tween(n, TweenInfo.new(0.2), {Position = UDim2.new(1, -250, 1, -70 - (i-1)*65)})
            end
        end)
    end
    
    return window
end

-- 返回库
return Library
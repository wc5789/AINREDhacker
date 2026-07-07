--!strict
-- QQUILibrary - Roblox 仿QQ风格 UI Library
-- 设计要点：蓝色渐变头部、圆角卡片、轻拟物阴影、流畅补间动画、移动端触控拖动
-- API:
--   local ui = Library:CreateWindow(opts) -- {title, size=UDim2, draggable=true, blur=true}
--   local tab = ui:Tab("首页")
--   tab:Button("开始", function() end)
--   tab:Toggle("自动开关", false, function(v) end)
--   tab:Textbox("输入昵称", "在此输入...", function(text) end)
--   tab:Dropdown("选择模式", {"轻度","标准","进阶"}, 2, function(idx, val) end)
--   tab:Slider("音量", 0, 100, 30, function(val) end)
--   ui:Notify("已连接", "你的账号已登录", 3)
--   ui:Destroy()

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local function safeParent()
    local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pgui then
        pgui = Instance.new("PlayerGui")
        pgui.ResetOnSpawn = false
        pgui.Parent = LocalPlayer
    end
    return pgui
end

local function create(instance, props, children)
    local obj = Instance.new(instance)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = obj
    end
    return obj
end

local function roundify(gui, radius)
    local corner = create("UICorner", {CornerRadius = UDim.new(0, radius or 12)})
    corner.Parent = gui
    return corner
end

local function shadow(parent, transparency)
    local s = create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageTransparency = transparency or 0.35,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24,24,276,276),
        Size = UDim2.fromScale(1,1),
        Position = UDim2.fromScale(0,0),
        ZIndex = (parent.ZIndex or 1) - 1
    })
    s.Parent = parent
    return s
end

local function gradientBlue(parent)
    local g = create("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(64,140,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0,102,255))
        })
    })
    g.Parent = parent
    return g
end

local function stroke(parent, thickness, transparency)
    local st = create("UIStroke", {
        Thickness = thickness or 1,
        Transparency = transparency or 0.2,
        Color = Color3.fromRGB(220, 230, 255),
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    st.Parent = parent
    return st
end

local function ripple(button)
    button.ClipsDescendants = true
    return function()
        local circle = create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            BackgroundTransparency = 0.8,
            AnchorPoint = Vector2.new(0.5,0.5),
            Size = UDim2.fromOffset(0,0),
            Position = UDim2.fromScale(0.5,0.5),
            ZIndex = button.ZIndex + 1
        }, {roundify(create("Frame",{}), 999)}) -- dummy, we only want round shape
        circle.Parent = button
        roundify(circle, 999)
        TweenService:Create(circle, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(1.8,1.8),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.4, function() circle:Destroy() end)
    end
end

local function makeDraggable(handle: GuiObject, dragRoot: GuiObject)
    local dragging = false
    local dragStart, startPos
    local function inputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragRoot.Position
            input.Changed:Connect(function(i)
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end
    local function inputChanged(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            dragRoot.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
    handle.InputBegan:Connect(inputBegan)
    UserInputService.InputChanged:Connect(inputChanged)
end

local Library = {}
Library.__index = Library

export type Window = {
    ScreenGui: ScreenGui,
    Main: Frame,
    TabBar: Frame,
    Content: Frame,
    _tabs: {[string]: Frame},
    _buttons: {},
    Tab: (self: Window, name: string) -> any,
    Notify: (self: Window, title: string, msg: string, duration: number?) -> (),
    Destroy: (self: Window) -> ()
}

function Library:CreateWindow(opts): Window
    opts = opts or {}
    local title = opts.title or "QQ UI"
    local size = opts.size or UDim2.fromOffset(540, 360)
    local draggable = (opts.draggable ~= false)
    local blur = (opts.blur ~= false)

    local pgui = safeParent()
    local gui = create("ScreenGui", {
        Name = "QQUILibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = pgui
    })

    -- 全局自适应缩放（移动端）
    local scale = create("UIScale", {})
    scale.Parent = gui
    local function autoScale()
        local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
        local minSide = math.min(v.X, v.Y)
        scale.Scale = math.clamp(minSide/1080, 0.7, 1.1)
    end
    autoScale()
    RunService.RenderStepped:Connect(autoScale)

    -- 背景毛玻璃（可选）
    local blurEffect
    if blur then
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Size = 12
        blurEffect.Parent = workspace.CurrentCamera
    end

    local main = create("Frame", {
        Name = "Main",
        Size = size,
        Position = UDim2.fromScale(0.5,0.5),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = Color3.fromRGB(245, 248, 255),
        BackgroundTransparency = 0,
        Parent = gui
    })
    roundify(main, 20)
    shadow(main, 0.45)
    stroke(main, 1, 0.6)

    -- 顶部蓝色渐变标题栏（仿QQ）
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Color3.fromRGB(64,140,255),
        Parent = main
    })
    gradientBlue(header)
    roundify(header, 20)
    stroke(header, 1, 0.2)

    local titleLabel = create("TextLabel", {
        Text = title,
        Font = Enum.Font.GothamSemibold,
        TextSize = 20,
        TextColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0,0.5),
        Position = UDim2.new(0, 20, 0.5, 0),
        Size = UDim2.new(1, -120, 1, 0),
        Parent = header
    })

    local closeBtn = create("TextButton", {
        Text = "×",
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(40,40),
        AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Parent = header,
        ZIndex = 10
    })
    local doRipple = ripple(closeBtn)
    closeBtn.MouseButton1Click:Connect(function()
        doRipple()
        TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(main.AbsoluteSize.X, 0),
            Position = UDim2.new(0.5,0, 0.5, 0)
        }):Play()
        task.delay(0.18, function()
            gui:Destroy()
            if blurEffect then blurEffect:Destroy() end
        end)
    end)

    if draggable then
        makeDraggable(header, main)
    end

    -- Tab 栏（左侧）
    local tabbar = create("Frame", {
        Name = "TabBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 140, 1, -64),
        Position = UDim2.new(0, 0, 0, 64),
        Parent = main
    })
    local tablist = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0,8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    tablist.Parent = tabbar

    -- 内容区域（右侧卡片）
    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -140, 1, -64),
        Position = UDim2.new(0, 140, 0, 64),
        BackgroundTransparency = 1,
        Parent = main
    })

    local pages = create("Frame", {
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Parent = content
    })
    local pagePadding = create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) })
    pagePadding.Parent = pages

    local notifHolder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1,0),
        Position = UDim2.new(1, -12, 0, 76),
        Size = UDim2.new(0, 260, 1, -88),
        BackgroundTransparency = 1,
        Parent = main
    })
    local notifList = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0,8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    notifList.Parent = notifHolder

    local window: Window = setmetatable({
        ScreenGui = gui,
        Main = main,
        TabBar = tabbar,
        Content = pages,
        _tabs = {},
        _buttons = {}
    }, Library)

    function window:Notify(ntitle: string, msg: string, duration: number?)
        local card = create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            Size = UDim2.new(1, 0, 0, 68),
            Parent = notifHolder
        })
        roundify(card, 16)
        shadow(card, 0.4)
        stroke(card, 1, 0.6)
        local t = create("TextLabel", {
            Text = ntitle or "通知",
            Font = Enum.Font.GothamSemibold,
            TextSize = 16,
            TextColor3 = Color3.fromRGB(32, 40, 64),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(1, -24, 0, 20),
            Parent = card
        })
        local m = create("TextLabel", {
            Text = msg or "",
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            TextColor3 = Color3.fromRGB(70, 85, 120),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 30),
            Size = UDim2.new(1, -24, 0, 28),
            Parent = card
        })
        card.BackgroundTransparency = 1
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        task.delay(duration or 2.5, function()
            TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            task.delay(0.2, function() card:Destroy() end)
        end)
    end

    function window:Destroy()
        self.ScreenGui:Destroy()
    end

    local function showTab(name)
        for tName, page in pairs(window._tabs) do
            page.Visible = (tName == name)
        end
    end

    function window:Tab(name: string)
        name = name or "Tab"
        local btn = create("TextButton", {
            Text = "  "..name,
            Font = Enum.Font.GothamMedium,
            TextSize = 16,
            TextColor3 = Color3.fromRGB(40,70,120),
            AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            Size = UDim2.new(1, -24, 0, 40),
            Parent = tabbar
        })
        roundify(btn, 12)
        stroke(btn, 1, 0.65)
        local bRipple = ripple(btn)

        local page = create("Frame", {
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = pages
        })
        window._tabs[name] = page

        local list = create("UIListLayout", {
            Padding = UDim.new(0, 10),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        list.Parent = page
        local pad = create("UIPadding", {PaddingTop = UDim.new(0,2)})
        pad.Parent = page

        local tabApi = {}

        local function cardBase(height)
            local card = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                Size = UDim2.new(1, 0, 0, height),
                Parent = page
            })
            roundify(card, 16)
            shadow(card, 0.4)
            stroke(card, 1, 0.6)
            local innerPad = create("UIPadding", {PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,14), PaddingTop = UDim.new(0,12), PaddingBottom = UDim.new(0,12)})
            innerPad.Parent = card
            return card
        end

        function tabApi:Button(text, callback)
            local card = cardBase(52)
            local btn = create("TextButton", {
                Text = text or "按钮",
                Font = Enum.Font.GothamMedium,
                TextSize = 16,
                TextColor3 = Color3.fromRGB(40,70,120),
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1),
                Parent = card
            })
            local doR = ripple(card)
            btn.MouseButton1Click:Connect(function()
                doR()
                if callback then task.spawn(callback) end
            end)
            return btn
        end

        function tabApi:Toggle(text, default, callback)
            local card = cardBase(56)
            local lbl = create("TextLabel", {
                Text = text or "开关",
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextColor3 = Color3.fromRGB(40,70,120),
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -80, 1, 0),
                Parent = card
            })
            local track = create("Frame", {
                AnchorPoint = Vector2.new(1,0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(56, 28),
                BackgroundColor3 = Color3.fromRGB(230, 235, 250),
                Parent = card
            })
            roundify(track, 14)
            stroke(track, 1, 0.6)

            local knob = create("Frame", {
                Size = UDim2.fromOffset(24,24),
                Position = UDim2.new(0, 2, 0.5, 0),
                AnchorPoint = Vector2.new(0,0.5),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                Parent = track
            })
            roundify(knob, 12)
            shadow(knob, 0.4)
            stroke(knob, 1, 0.6)

            local state = default and true or false
            local function render()
                local targetX = state and (track.AbsoluteSize.X - 26) or 2
                TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, targetX, 0.5, 0)}):Play()
                TweenService:Create(track, TweenInfo.new(0.15), {
                    BackgroundColor3 = state and Color3.fromRGB(64,140,255) or Color3.fromRGB(230,235,250)
                }):Play()
            end
            render()

            local function set(v)
                state = not not v
                render()
                if callback then task.spawn(callback, state) end
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    set(not state)
                end
            end)

            return {
                Set = set,
                Get = function() return state end
            }
        end

        function tabApi:Textbox(placeholder, default, callback)
            local card = cardBase(64)
            local box = create("TextBox", {
                PlaceholderText = placeholder or "请输入...",
                Text = default or "",
                ClearTextOnFocus = false,
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextColor3 = Color3.fromRGB(40,70,120),
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = card
            })
            box.FocusLost:Connect(function(enter)
                if (enter or true) and callback then
                    task.spawn(callback, box.Text)
                end
            end)
            return box
        end

        function tabApi:Slider(text, min, max, default, callback)
            min, max = min or 0, max or 100
            local value = math.clamp(default or min, min, max)
            local card = cardBase(72)
            local lbl = create("TextLabel", {
                Text = string.format("%s  %d", text or "滑块", value),
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextColor3 = Color3.fromRGB(40,70,120),
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Parent = card
            })
            local bar = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(230,235,250),
                Size = UDim2.new(1, 0, 0, 10),
                Position = UDim2.new(0, 0, 0, 38),
                Parent = card
            })
            roundify(bar, 5)
            stroke(bar, 1, 0.6)
            local fill = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(64,140,255),
                Size = UDim2.new((value-min)/(max-min), 0, 1, 0),
                Parent = bar
            })
            roundify(fill, 5)
            local knob = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                Size = UDim2.fromOffset(16,16),
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0),
                Parent = bar
            })
            roundify(knob, 8)
            shadow(knob, 0.4)
            stroke(knob, 1, 0.6)

            local dragging = false
            local function setFromX(x)
                local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
                value = math.floor(min + rel*(max-min) + 0.5)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, 0, 0.5, 0)
                lbl.Text = string.format("%s  %d", text or "滑块", value)
                if callback then task.spawn(callback, value) end
            end
            bar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromX(i.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(i.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                    dragging = false
                end
            end)

            return {
                Set = function(v) setFromX(bar.AbsolutePosition.X + (math.clamp((v-min)/(max-min),0,1))*bar.AbsoluteSize.X) end,
                Get = function() return value end
            }
        end

        function tabApi:Dropdown(text, items, defaultIndex, callback)
            items = items or {}
            local open = false
            local selectedIndex = defaultIndex or 1

            local card = cardBase(56)
            local lbl = create("TextLabel", {
                Text = (text or "下拉").."："..(items[selectedIndex] or ""),
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextColor3 = Color3.fromRGB(40,70,120),
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                Parent = card
            })
            local caret = create("TextButton", {
                Text = "▾",
                Font = Enum.Font.GothamBold,
                TextSize = 18,
                TextColor3 = Color3.fromRGB(40,70,120),
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1,0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(30,30),
                Parent = card
            })
            local panel = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 8),
                Parent = card,
                ClipsDescendants = true
            })
            roundify(panel, 12)
            shadow(panel, 0.45)
            stroke(panel, 1, 0.6)
            local vlist = create("UIListLayout", {
                Padding = UDim.new(0,6),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            vlist.Parent = panel
            local function rebuild()
                for _, c in ipairs(panel:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for i, it in ipairs(items) do
                    local opt = create("TextButton", {
                        Text = tostring(it),
                        Font = Enum.Font.Gotham,
                        TextSize = 15,
                        TextColor3 = i==selectedIndex and Color3.fromRGB(64,140,255) or Color3.fromRGB(40,70,120),
                        BackgroundColor3 = Color3.fromRGB(247,249,255),
                        AutoButtonColor = true,
                        Size = UDim2.new(1, -12, 0, 32),
                        Parent = panel
                    })
                    roundify(opt, 10); stroke(opt, 1, 0.6)
                    opt.MouseButton1Click:Connect(function()
                        selectedIndex = i
                        lbl.Text = (text or "下拉").."："..tostring(it)
                        if callback then task.spawn(callback, selectedIndex, it) end
                        open = false
                        TweenService:Create(panel, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                        rebuild()
                    end)
                end
            end
            rebuild()

            local function toggleOpen()
                open = not open
                local targetH = open and math.min(#items*38+12, 200) or 0
                TweenService:Create(panel, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetH)}):Play()
            end
            caret.MouseButton1Click:Connect(toggleOpen)

            return {
                Set = function(idx)
                    if items[idx] then
                        selectedIndex = idx; lbl.Text = (text or "下拉").."："..tostring(items[idx]); rebuild()
                    end
                end,
                Get = function() return selectedIndex, items[selectedIndex] end,
                Refresh = function(newItems)
                    items = newItems or {}; selectedIndex = 1; lbl.Text = (text or "下拉").."："..(items[1] or ""); rebuild()
                end
            }
        end

        btn.MouseButton1Click:Connect(function()
            bRipple()
            showTab(name)
            -- 轻动画
            page.Visible = true
            page.BackgroundTransparency = 1
            TweenService:Create(page, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
        end)

        -- 默认选中第一个
        if #tabbar:GetChildren() <= 2 then
            showTab(name)
            page.Visible = true
        end

        return tabApi
    end

    return window
end

return setmetatable({}, {__index = Library})
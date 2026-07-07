--[[
Roblox风格 UI 单文件库
作者: ChatGPT
说明:
* 纯原生 Instance 创建与 Tween 动画，无需外部依赖，移动端友好。
* 仿 Roblox 深色 UI 风格（圆角、描边、阴影、蓝色强调）。
* 支持：窗口拖动 / 侧边 Tab / 分页 / 按钮 / Toggle / Slider / Textbox / 分组。
* 自带悬浮开关按钮与打开/关闭动画。

使用：把本文件整段复制到执行环境运行，或 require 后调用。
local UI = loadstring(<此脚本字符串>)()
local win = UI:CreateWindow({ title = "我的工具", keybind = Enum.KeyCode.RightControl })
local tab = win:AddTab("主页面")
tab:AddButton("点我", function() print("clicked") end)
local t = tab:AddToggle("自动开火", false, function(v) print("toggle:", v) end)
tab:AddSlider("灵敏度", 0, 100, 50, function(v) print(v) end)
tab:AddTextbox("搜索...", function(txt) print(txt) end)
提示：若你在 Exploit 环境，库会优先挂载到 gethui() / CoreGui；否则挂在 PlayerGui。
]]

local RobloxUI = { _version = "1.0.0" }

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// Mount target
local function getMount()
    local ok, ui = pcall(function()
        return gethui and gethui() or game:GetService("CoreGui")
    end)
    if ok and ui then
        return ui
    end
    local pg = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    return pg or Instance.new("ScreenGui")
end

--// Theme
local Theme = {
    Bg = Color3.fromRGB(22, 22, 22),
    Panel = Color3.fromRGB(30, 30, 30),
    Hover = Color3.fromRGB(40, 40, 40),
    Stroke = Color3.fromRGB(60, 60, 60),
    Text = Color3.fromRGB(235, 235, 235),
    SubText = Color3.fromRGB(170, 170, 170),
    Accent = Color3.fromRGB(0, 162, 255), -- Roblox 蓝
    Shadow = Color3.fromRGB(10, 10, 10)
}

--// Utility
local function new(inst, props, children)
    local obj = Instance.new(inst)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = obj
    end
    return obj
end

local function tween(o, info, props)
    return TweenService:Create(o, info, props)
end

local function uiStroke(parent, thickness)
    return new("UIStroke", {
        Color = Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, {}),
           new("UICorner", { CornerRadius = UDim.new(0, 10) }),
           new("UIStroke")
end

local function makeShadow(parent)
    local shadow = new("ImageLabel", {
        Name = "_shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Theme.Shadow,
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.fromOffset(-15, -15),
        ZIndex = 0
    })
    shadow.Parent = parent
end

local function makeDraggable(handle, dragTarget)
    local dragging = false
    local startPos, startInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = dragTarget.Position
            startInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            startInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == startInput then
            local delta = input.Delta
            dragTarget.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--// Core ScreenGui
local function makeScreenGui()
    local mount = getMount()
    local gui = new("ScreenGui", {
        Name = "RobloxStyleUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 10
    })
    gui.Parent = mount
    return gui
end

--// Floating Toggle Button
local function makeFloatingButton(parent, onClick)
    local btn = new("ImageButton", {
        Name = "FloatingButton",
        Parent = parent,
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.fromOffset(46, 46),
        Position = UDim2.new(1, -60, 1, -60),
        ZIndex = 100
    }, {
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1 }),
        new("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    new("ImageLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Image = "rbxassetid://10723422294", -- 触发器图标
        Size = UDim2.fromScale(0.6, 0.6),
        Position = UDim2.fromScale(0.2, 0.2),
        ZIndex = 101
    })

    btn.MouseButton1Click:Connect(onClick)
    -- 呼吸动画
    task.spawn(function()
        while btn.Parent do
            tween(btn, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.fromOffset(50, 50) }):Play()
            task.wait(1.1)
            tween(btn, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.fromOffset(46, 46) }):Play()
            task.wait(1.1)
        end
    end)

    makeDraggable(btn, btn)
    return btn
end

--// Window Factory
local Window = {}
Window.__index = Window

function RobloxUI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.title or "Roblox Style UI"

    local gui = makeScreenGui()
    local main = new("Frame", {
        Name = "Main",
        Parent = gui,
        BackgroundColor3 = Theme.Bg,
        Size = UDim2.fromOffset(720, 420),
        Position = UDim2.new(0.5, -360, 0.5, -210),
        Visible = false
    }, {
        new("UICorner", { CornerRadius = UDim.new(0, 14) }),
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
    })

    makeShadow(main)

    local topbar = new("Frame", {
        Name = "Topbar",
        Parent = main,
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, 0, 0, 46)
    }, {
        new("UICorner", { CornerRadius = UDim.new(0, 14) }),
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
    })

    local titleLabel = new("TextLabel", {
        Parent = topbar,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 18,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -110, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local closeBtn = new("TextButton", {
        Parent = topbar,
        Text = "✕",
        Font = Enum.Font.Gotham,
        TextSize = 18,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Hover,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(34, 30),
        Position = UDim2.new(1, -44, 0.5, -15)
    }, {
        new("UICorner", { CornerRadius = UDim.new(0, 8) }),
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
    })

    local left = new("Frame", {
        Parent = main,
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(0, 180, 1, -46),
        Position = UDim2.new(0, 0, 0, 46)
    }, {
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
    })

    local right = new("Frame", {
        Parent = main,
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, -190, 1, -56),
        Position = UDim2.new(0, 190, 0, 56)
    }, {
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
    })

    local tabList = new("ScrollingFrame", {
        Parent = left,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 4
    }, {
        new("UIListLayout", {
            Padding = UDim.new(0, 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        new("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 10)
        })
    })

    local pageContainer = new("Frame", {
        Parent = right,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1)
    })

    makeDraggable(topbar, main)

    local floatBtn
    floatBtn = makeFloatingButton(gui, function()
        if main.Visible then
            tween(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(720, 0),
                Position = UDim2.new(0.5, -360, 0.5, 0)
            }):Play()
            task.delay(0.18, function()
                main.Visible = false
            end)
        else
            main.Size = UDim2.fromOffset(720, 0)
            main.Position = UDim2.new(0.5, -360, 0.5, 0)
            main.Visible = true
            tween(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(720, 420),
                Position = UDim2.new(0.5, -360, 0.5, -210)
            }):Play()
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    local window = setmetatable({
        _gui = gui,
        _main = main,
        _tabList = tabList,
        _pageContainer = pageContainer,
        _tabs = {},
        Theme = Theme,
        Toggle = function(self)
            floatBtn:Activate()
        end,
        Destroy = function(self)
            if gui then
                gui:Destroy()
            end
        end
    }, Window)

    -- 可选：键位打开/关闭
    if opts.keybind then
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == opts.keybind then
                floatBtn:Activate()
            end
        end)
    end

    return window
end

--// Tab & Controls
function Window:AddTab(name)
    name = name or "Tab"

    local btn = new("TextButton", {
        Parent = self._tabList,
        AutoButtonColor = false,
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Bg,
        Size = UDim2.new(1, -8, 0, 38)
    }, {
        new("UICorner", { CornerRadius = UDim.new(0, 10) }),
        new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
    })

    local page = new("ScrollingFrame", {
        Parent = self._pageContainer,
        BackgroundTransparency = 1,
        Visible = false,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 6
    }, {
        new("UIListLayout", {
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        new("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12)
        })
    })

    local function select()
        for _, t in pairs(self._tabs) do
            t._btn.BackgroundColor3 = Theme.Bg
            t._btn.TextColor3 = Theme.Text
            t._page.Visible = false
        end
        btn.BackgroundColor3 = Theme.Accent
        btn.TextColor3 = Color3.new(1, 1, 1)
        page.Visible = true
    end

    btn.MouseEnter:Connect(function()
        if page.Visible then return end
        tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
    end)

    btn.MouseLeave:Connect(function()
        if page.Visible then return end
        tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Bg }):Play()
    end)

    btn.MouseButton1Click:Connect(select)

    local tab = {
        _btn = btn,
        _page = page,
        AddSection = function(_, title)
            local section = new("TextLabel", {
                Parent = page,
                BackgroundTransparency = 1,
                Text = title or "SECTION",
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.SubText,
                TextSize = 14,
                Size = UDim2.new(1, -4, 0, 20)
            })
            return section
        end,
        AddButton = function(_, text, callback)
            local b = new("TextButton", {
                Parent = page,
                AutoButtonColor = false,
                Text = text or "Button",
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextColor3 = Theme.Text,
                BackgroundColor3 = Theme.Bg,
                Size = UDim2.new(1, -4, 0, 40)
            }, {
                new("UICorner", { CornerRadius = UDim.new(0, 10) }),
                new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
            })

            b.MouseEnter:Connect(function()
                tween(b, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
            end)

            b.MouseLeave:Connect(function()
                tween(b, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Bg }):Play()
            end)

            b.MouseButton1Click:Connect(function()
                if typeof(callback) == "function" then
                    task.spawn(callback)
                end
            end)

            return b
        end,
        AddToggle = function(_, text, default, callback)
            local holder = new("Frame", {
                Parent = page,
                BackgroundColor3 = Theme.Bg,
                Size = UDim2.new(1, -4, 0, 40)
            }, {
                new("UICorner", { CornerRadius = UDim.new(0, 10) }),
                new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
            })

            local lbl = new("TextLabel", {
                Parent = holder,
                BackgroundTransparency = 1,
                Text = text or "Toggle",
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.fromOffset(12, 0)
            })

            local sw = new("TextButton", {
                Parent = holder,
                AutoButtonColor = false,
                Text = "",
                BackgroundColor3 = Theme.Stroke,
                Size = UDim2.fromOffset(52, 24),
                Position = UDim2.new(1, -64, 0.5, -12)
            }, {
                new("UICorner", { CornerRadius = UDim.new(1, 0) }),
                new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
            })

            local dot = new("Frame", {
                Parent = sw,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.fromOffset(2, 2)
            }, {
                new("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local state = default and true or false

            local function render(v)
                state = v
                tween(sw, TweenInfo.new(0.15), { BackgroundColor3 = v and Theme.Accent or Theme.Stroke }):Play()
                tween(dot, TweenInfo.new(0.15), { Position = v and UDim2.fromOffset(30, 2) or UDim2.fromOffset(2, 2) }):Play()
            end

            render(state)

            local function toggle()
                render(not state)
                if typeof(callback) == "function" then
                    task.spawn(callback, state)
                end
            end

            sw.MouseButton1Click:Connect(toggle)

            holder.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    toggle()
                end
            end)

            return setmetatable({
                Set = function(_, v)
                    render(v)
                end,
                Get = function(_)
                    return state
                end
            }, {
                __tostring = function()
                    return "Toggle"
                end
            })
        end,
        AddSlider = function(_, text, min, max, default, callback)
            min, max = tonumber(min) or 0, tonumber(max) or 100
            local value = math.clamp(tonumber(default) or min, min, max)

            local holder = new("Frame", {
                Parent = page,
                BackgroundColor3 = Theme.Bg,
                Size = UDim2.new(1, -4, 0, 56)
            }, {
                new("UICorner", { CornerRadius = UDim.new(0, 10) }),
                new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
            })

            local lbl = new("TextLabel", {
                Parent = holder,
                BackgroundTransparency = 1,
                Text = string.format("%s [%d]", text or "Slider", value),
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -12, 0, 24),
                Position = UDim2.fromOffset(12, 6)
            })

            local bar = new("Frame", {
                Parent = holder,
                BackgroundColor3 = Theme.Stroke,
                Size = UDim2.new(1, -24, 0, 6),
                Position = UDim2.fromOffset(12, 36)
            }, {
                new("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local fill = new("Frame", {
                Parent = bar,
                BackgroundColor3 = Theme.Accent,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            }, {
                new("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local dragging = false

            local function setFromX(x)
                local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * rel + 0.5)
                tween(fill, TweenInfo.new(0.08), { Size = UDim2.new((value - min) / (max - min), 0, 1, 0) }):Play()
                lbl.Text = string.format("%s [%d]", text or "Slider", value)
                if typeof(callback) == "function" then
                    task.spawn(callback, value)
                end
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
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            return setmetatable({
                Set = function(_, v)
                    v = math.clamp(tonumber(v) or value, min, max)
                    value = v
                    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    lbl.Text = string.format("%s [%d]", text or "Slider", value)
                end,
                Get = function(_)
                    return value
                end
            }, {
                __tostring = function()
                    return "Slider"
                end
            })
        end,
        AddTextbox = function(_, placeholder, callback)
            local box = new("TextBox", {
                Parent = page,
                PlaceholderText = placeholder or "输入...",
                Text = "",
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextColor3 = Theme.Text,
                ClearTextOnFocus = false,
                BackgroundColor3 = Theme.Bg,
                Size = UDim2.new(1, -4, 0, 40)
            }, {
                new("UICorner", { CornerRadius = UDim.new(0, 10) }),
                new("UIStroke", { Color = Theme.Stroke, Thickness = 1 })
            })

            box.Focused:Connect(function()
                tween(box, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
            end)

            box.FocusLost:Connect(function(enter)
                tween(box, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Bg }):Play()
                if enter and typeof(callback) == "function" then
                    task.spawn(callback, box.Text)
                end
            end)

            return box
        end
    }

    table.insert(self._tabs, tab)

    if #self._tabs == 1 then
        -- 自动选中第一个
        task.defer(function()
            btn:Activate()
        end)
        task.defer(function()
            for _, t in pairs(self._tabs) do
                t._page.Visible = false
            end
            btn.BackgroundColor3 = Theme.Accent
            btn.TextColor3 = Color3.new(1, 1, 1)
            tab._page.Visible = true
        end)
    end

    return tab
end

return RobloxUI
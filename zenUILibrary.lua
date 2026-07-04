-- =====================================================================
-- OperitUILibrary.lua - v2.0 "Cyber Zen" Professional Neo-Minimalism UI Library
-- Designed for Roblox CoreGui/PlayerGui compatibility across desktop & mobile
-- Author: Operit AI
-- Date: 2024-07-04
-- =====================================================================

-- Core Globals & Configuration
local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration for UI aesthetics and behavior
local CONFIG = {
    PRIMARY_COLOR = Color3.fromRGB(10, 10, 12), -- Deep Obsidian Black
    SECONDARY_COLOR = Color3.fromRGB(13, 13, 16), -- Matte Charcoal Grey
    ACCENT_COLOR = Color3.fromRGB(0, 255, 204), -- Aurora Cyan (Neon Green-Blue)
    TEXT_COLOR = Color3.fromRGB(240, 240, 240),
    FONT = Enum.Font.SourceSans, -- Preferred modern font
    FONT_SIZE = 14,
    CORNER_RADIUS = UDim.new(0, 8), -- Slightly rounded corners
    BORDER_SIZE = 1,
    BORDER_COLOR = Color3.fromRGB(30, 30, 35),
    DRAG_SENSITIVITY = 0.5, -- Adjust for touch/mouse drag feel
    SNAP_DISTANCE = 0.15, -- Percentage of screen width/height for magnetic snap
    ANIM_DURATION = 0.2, -- Standard animation duration
    EASING_STYLE_WINDOW = Enum.EasingStyle.Sine,
    EASING_DIRECTION_WINDOW = Enum.EasingDirection.Out,
    EASING_STYLE_NODE = Enum.EasingStyle.Back, -- For Cyber Node elastic snap
    EASING_DIRECTION_NODE = Enum.EasingDirection.Out,
    NODE_SIZE = UDim2.new(0, 60, 0, 28), -- Size of the Cyber Node (pill-shaped)
    NODE_ZINDEX = 100, -- Highest ZIndex for the node
    WINDOW_ZINDEX = 99, -- Window slightly below node
    KASUMI_IDLE_TIMEOUT = 2.5 -- seconds before Kasumi resets to idle
}

-- Utility Functions
-- getSafeParent: Intelligently determine the best ScreenGui parent
-- Tries CoreGui first for executor environments, falls back to PlayerGui for Studio/sandbox
local function getSafeParent()
    local coreGui = game:GetService("CoreGui")
    local playerGui = Players.LocalPlayer and Players.LocalPlayer:WaitForChild("PlayerGui")

    if coreGui then
        -- Attempt to create a test ScreenGui in CoreGui
        local testGui = Instance.new("ScreenGui")
        local success, err = pcall(function()
            testGui.Name = "OperitCoreGuiTest"
            testGui.Parent = coreGui
        end)
        if success then
            testGui:Destroy() -- Clean up test GUI
            return coreGui
        else
            warn("CoreGui access denied or failed:", err, "Falling back to PlayerGui.")
            testGui:Destroy()
        end
    end

    if playerGui then
        return playerGui
    else
        error("Neither CoreGui nor PlayerGui available for UI parent.")
    end
end

-- getScreenSize: Robustly get screen dimensions, handling potential NaN/zero initial states
local function getScreenSize()
    local viewportSize = UserInputService.ViewportSize
    local safeWidth = viewportSize.X > 100 and viewportSize.X or 1920 -- Default to common desktop width
    local safeHeight = viewportSize.Y > 100 and viewportSize.Y or 1080 -- Default to common desktop height
    return safeWidth, safeHeight
end

-- clamp: Clamps a value between a min and max
local function clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(value, maxVal))
end

-- Create ScreenGui base
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OperitCyberZenUI"
ScreenGui.ResetOnSpawn = false -- Crucial for persistent UI across respawns
ScreenGui.Parent = getSafeParent() -- Use safe parent detection

-- Cyber Node (Floating Pill Button)
local CyberNode = Instance.new("Frame")
CyberNode.Name = "CyberNode"
CyberNode.Size = CONFIG.NODE_SIZE
CyberNode.BackgroundTransparency = 0.95 -- Mostly transparent
CyberNode.BackgroundColor3 = CONFIG.PRIMARY_COLOR
CyberNode.BorderSizePixel = 0
CyberNode.ZIndex = CONFIG.NODE_ZINDEX
CyberNode.Active = true
CyberNode.Draggable = true -- Allows direct dragging

local NodeCorner = Instance.new("UICorner")
NodeCorner.CornerRadius = UDim.new(0.5, 0) -- Pill shape
NodeCorner.Parent = CyberNode

local NodeOutline = Instance.new("UIStroke")
NodeOutline.Name = "NodeOutline"
NodeOutline.ApplyStrokeMode = Enum.UIStrokeApplyMode.Border
NodeOutline.Color = CONFIG.ACCENT_COLOR
NodeOutline.Thickness = 1
NodeOutline.Transparency = 0.5
NodeOutline.Parent = CyberNode

local NodeLabel = Instance.new("TextLabel")
NodeLabel.Name = "NodeLabel"
NodeLabel.Text = "CYBER // ZEN"
NodeLabel.Font = CONFIG.FONT
NodeLabel.TextSize = CONFIG.FONT_SIZE - 2
NodeLabel.TextColor3 = CONFIG.ACCENT_COLOR
NodeLabel.TextScaled = false
NodeLabel.BackgroundTransparency = 1
NodeLabel.Size = UDim2.new(1, 0, 1, 0)
NodeLabel.Parent = CyberNode

CyberNode.Parent = ScreenGui

-- Window Management
local currentWindow = nil
local nodeOriginalSize = CyberNode.Size
local nodeOriginalLabelText = NodeLabel.Text

-- Function to handle CyberNode dragging and snapping
local isDraggingNode = false
local dragStartPos = nil
local dragStartTime = 0

CyberNode.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingNode = true
        dragStartPos = UserInputService:GetMouseLocation() -- For mouse
        if input.UserInputType == Enum.UserInputType.Touch and #UserInputService:GetTouchEnabled() > 0 then
            dragStartPos = input.Position -- For touch
        end
        dragStartTime = os.clock()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingNode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mousePos = UserInputService:GetMouseLocation()
        if input.UserInputType == Enum.UserInputType.Touch and #UserInputService:GetTouchEnabled() > 0 then
            mousePos = input.Position
        end

        local deltaX = (mousePos.X - dragStartPos.X) * CONFIG.DRAG_SENSITIVITY
        local deltaY = (mousePos.Y - dragStartPos.Y) * CONFIG.DRAG_SENSITIVITY

        -- Update node position
        local newX = CyberNode.AbsolutePosition.X + deltaX
        local newY = CyberNode.AbsolutePosition.Y + deltaY

        local screenW, screenH = getScreenSize()
        local nodeW, nodeH = CyberNode.AbsoluteSize.X, CyberNode.AbsoluteSize.Y

        newX = clamp(newX, 0, screenW - nodeW)
        newY = clamp(newY, 0, screenH - nodeH)

        CyberNode.Position = UDim2.new(0, newX, 0, newY)
        dragStartPos = mousePos
    end
end)

CyberNode.InputEnded:Connect(function(input)
    if isDraggingNode and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isDraggingNode = false
        local dragEndTime = os.clock()
        -- Only snap if it wasn't a quick tap (indicating a click to open/close)
        if (dragEndTime - dragStartTime) > 0.1 then -- A small threshold to differentiate drag from tap
            local screenW, screenH = getScreenSize()
            local nodeW, nodeH = CyberNode.AbsoluteSize.X, CyberNode.AbsoluteSize.Y
            local nodeCenterX = CyberNode.AbsolutePosition.X + nodeW / 2
            local nodeCenterY = CyberNode.AbsolutePosition.Y + nodeH / 2

            local snapThresholdX = screenW * CONFIG.SNAP_DISTANCE
            local snapThresholdY = screenH * CONFIG.SNAP_DISTANCE

            local targetX = CyberNode.Position.X.Offset
            local targetY = CyberNode.Position.Y.Offset

            -- Snap to horizontal edges
            if nodeCenterX < snapThresholdX then -- Left edge
                targetX = 0
            elseif nodeCenterX > screenW - snapThresholdX then -- Right edge
                targetX = screenW - nodeW
            end

            -- Snap to vertical edges (less aggressive, just for bounce)
            if nodeCenterY < snapThresholdY then
                targetY = 0
            elseif nodeCenterY > screenH - snapThresholdY then
                targetY = screenH - nodeH
            end

            local newPosition = UDim2.new(0, targetX, 0, targetY)
            local tweenInfo = TweenInfo.new(CONFIG.ANIM_DURATION, CONFIG.EASING_STYLE_NODE, CONFIG.EASING_DIRECTION_NODE)
            TweenService:Create(CyberNode, tweenInfo, {Position = newPosition}):Play()
        end
    end
end)


-- Main UI Window
local Window = {}
Window.__index = Window

function Library:CreateWindow(title, version)
    local self = setmetatable({}, Window)
    self.IsOpen = false
    self.Tabs = {}
    self.CurrentTab = nil
    self.KasumiMessages = {
        Idle = "Operit AI is online. How may I assist?",
        Active = "Processing command...",
        Typing = "...",
        Error = "Error: System anomaly detected.",
        Success = "Task complete. Awaiting new directive."
    }
    self.KasumiCurrentState = "Idle"
    self.KasumiTypingTween = nil
    self.KasumiIdleCoroutine = nil

    self.Frame = Instance.new("Frame")
    self.Frame.Name = "OperitWindow"
    self.Frame.Size = UDim2.new(0.3, 0, 0.7, 0) -- Responsive width, fixed height for better mobile scaling
    self.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Frame.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    self.Frame.BorderSizePixel = 0
    self.Frame.ZIndex = CONFIG.WINDOW_ZINDEX
    self.Frame.Visible = false -- Start hidden
    self.Frame.Parent = ScreenGui

    -- Add a UIScale for smooth scaling animations instead of CanvasGroup
    self.UIScale = Instance.new("UIScale")
    self.UIScale.Scale = 0.8 -- Start slightly smaller
    self.UIScale.Parent = self.Frame

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = CONFIG.CORNER_RADIUS
    WindowCorner.Parent = self.Frame

    local WindowStroke = Instance.new("UIStroke")
    WindowStroke.ApplyStrokeMode = Enum.UIStrokeApplyMode.Border
    WindowStroke.Color = CONFIG.BORDER_COLOR
    WindowStroke.Thickness = CONFIG.BORDER_SIZE
    WindowStroke.Parent = self.Frame

    -- Top Bar (Draggable)
    self.TopBar = Instance.new("Frame")
    self.TopBar.Name = "TopBar"
    self.TopBar.Size = UDim2.new(1, 0, 0, 30)
    self.TopBar.Position = UDim2.new(0, 0, 0, 0)
    self.TopBar.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    self.TopBar.BorderSizePixel = 0
    self.TopBar.Parent = self.Frame
    self.TopBar.Active = true

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 8)
    TopBarCorner.Parent = self.TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Text = title .. " <font color='" .. CONFIG.ACCENT_COLOR:ToHex() .. "'>" .. version .. "</font>"
    TitleLabel.RichText = true
    TitleLabel.Font = CONFIG.FONT
    TitleLabel.TextSize = CONFIG.FONT_SIZE + 2
    TitleLabel.TextColor3 = CONFIG.TEXT_COLOR
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1, -60, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = self.TopBar

    -- Close Button (X)
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 1, 0)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    CloseButton.Text = "✕"
    CloseButton.Font = CONFIG.FONT
    CloseButton.TextSize = CONFIG.FONT_SIZE + 4
    CloseButton.TextColor3 = CONFIG.TEXT_COLOR
    CloseButton.BorderSizePixel = 0
    CloseButton.Parent = self.TopBar

    CloseButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Draggable functionality for TopBar
    local dragging = false
    local dragStart = Vector2.new(0, 0)
    local startPos = UDim2.new(0, 0, 0, 0)

    self.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = UserInputService:GetMouseLocation()
            startPos = self.Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = UserInputService:GetMouseLocation() - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y

            -- Clamp to screen bounds
            local screenW, screenH = getScreenSize()
            local frameW, frameH = self.Frame.AbsoluteSize.X, self.Frame.AbsoluteSize.Y

            newX = clamp(newX, -self.Frame.AnchorPoint.X * frameW, screenW - (1 - self.Frame.AnchorPoint.X) * frameW)
            newY = clamp(newY, -self.Frame.AnchorPoint.Y * frameH, screenH - (1 - self.Frame.AnchorPoint.Y) * frameH)

            self.Frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    -- Tab Container (Left Sidebar)
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.Size = UDim2.new(0, 100, 1, -30) -- Fixed width, fills height below TopBar
    self.TabContainer.Position = UDim2.new(0, 0, 0, 30)
    self.TabContainer.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    self.TabContainer.BorderSizePixel = 0
    self.TabContainer.Parent = self.Frame

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.FillDirection = Enum.FillDirection.Vertical
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = self.TabContainer

    -- Content Container (Right Side)
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Name = "ContentContainer"
    self.ContentContainer.Size = UDim2.new(1, -100, 1, -30)
    self.ContentContainer.Position = UDim2.new(0, 100, 0, 30)
    self.ContentContainer.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    self.ContentContainer.BorderSizePixel = 0
    self.ContentContainer.Parent = self.Frame

    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = CONFIG.CORNER_RADIUS
    ContentCorner.Parent = self.ContentContainer

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.Parent = self.ContentContainer

    local ContentListLayout = Instance.new("UIListLayout")
    ContentListLayout.FillDirection = Enum.FillDirection.Vertical
    ContentListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ContentListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    ContentListLayout.Padding = UDim.new(0, 8)
    ContentListLayout.Parent = self.ContentContainer

    -- Kasumi Core (ASCII Sidekick)
    self.KasumiFrame = Instance.new("Frame")
    self.KasumiFrame.Name = "KasumiCore"
    self.KasumiFrame.Size = UDim2.new(1, 0, 0.3, 0) -- Takes bottom 30% of tab container
    self.KasumiFrame.Position = UDim2.new(0, 0, 0.7, 0)
    self.KasumiFrame.BackgroundTransparency = 1
    self.KasumiFrame.Parent = self.TabContainer

    self.KasumiDisplay = Instance.new("TextLabel")
    self.KasumiDisplay.Name = "KasumiDisplay"
    self.KasumiDisplay.Size = UDim2.new(1, 0, 1, -20)
    self.KasumiDisplay.Position = UDim2.new(0, 0, 0, 0)
    self.KasumiDisplay.BackgroundTransparency = 1
    self.KasumiDisplay.Font = Enum.Font.Code
    self.KasumiDisplay.TextSize = CONFIG.FONT_SIZE - 2
    self.KasumiDisplay.TextColor3 = CONFIG.ACCENT_COLOR
    self.KasumiDisplay.TextXAlignment = Enum.TextXAlignment.Center
    self.KasumiDisplay.TextYAlignment = Enum.TextYAlignment.Top
    self.KasumiDisplay.RichText = true
    self.KasumiDisplay.TextWrapped = true
    self.KasumiDisplay.Parent = self.KasumiFrame

    self.KasumiMessageLabel = Instance.new("TextLabel")
    self.KasumiMessageLabel.Name = "KasumiMessage"
    self.KasumiMessageLabel.Size = UDim2.new(1, 0, 0, 20)
    self.KasumiMessageLabel.Position = UDim2.new(0, 0, 1, -20)
    self.KasumiMessageLabel.BackgroundTransparency = 1
    self.KasumiMessageLabel.Font = CONFIG.FONT
    self.KasumiMessageLabel.TextSize = CONFIG.FONT_SIZE - 4
    self.KasumiMessageLabel.TextColor3 = CONFIG.TEXT_COLOR
    self.KasumiMessageLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.KasumiMessageLabel.TextWrapped = true
    self.KasumiMessageLabel.Parent = self.KasumiFrame

    self:SetKasumiState("Idle") -- Initial Kasumi state

    -- CyberNode click handler
    CyberNode.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    return self
end

function Window:SetKasumiState(state, message)
    if self.KasumiIdleCoroutine then
        coroutine.yield(self.KasumiIdleCoroutine) -- Stop any existing idle timer
        self.KasumiIdleCoroutine = nil
    end
    if self.KasumiTypingTween then
        self.KasumiTypingTween:Cancel()
        self.KasumiTypingTween = nil
    end

    self.KasumiCurrentState = state
    local displayArt
    local msg = message or self.KasumiMessages[state] or "..."

    if state == "Idle" then
        displayArt = [[
        /\_/\  < CYBER//ZEN
       ( o.o )  
        > ^ <   v2.0 PRO
        ]]
        self.KasumiIdleCoroutine = coroutine.wrap(function()
            task.wait(CONFIG.KASUMI_IDLE_TIMEOUT)
            self:SetKasumiState("Idle") -- Reset to idle after timeout
        end)()
    elseif state == "Active" then
        displayArt = [[
        ( *.* )  
        / \_ / \  < Processing...
        | | | |
        ]]
    elseif state == "Typing" then
        displayArt = [[
        ( ._.)  
        / V V \   < Typing...
        `---'
        ]]
        -- Add a subtle blinking cursor effect for typing
        local alpha = 1
        self.KasumiTypingTween = TweenService:Create(self.KasumiMessageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0), {TextTransparency = 0.5})
        self.KasumiTypingTween:Play()
    elseif state == "Error" then
        displayArt = [[
        ( X.X )  
        / / \ \   < ERROR!
        ^ ~ ^
        ]]
        msg = "<font color='#FF0000'>" .. msg .. "</font>"
    elseif state == "Success" then
        displayArt = [[
        ( ^.^ )  
        / --- \   < Success!
        `-----'
        ]]
    end

    self.KasumiDisplay.Text = displayArt
    self.KasumiMessageLabel.Text = msg
    self.KasumiMessageLabel.TextTransparency = 0 -- Reset transparency
end

function Window:Toggle()
    self.IsOpen = not self.IsOpen

    local targetScale = self.IsOpen and 1 or 0.8
    local targetTransparency = self.IsOpen and 0 or 1
    local targetPosition = self.IsOpen and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0) -- Position remains centered

    -- Animate UIScale for visual opening/closing
    local scaleTweenInfo = TweenInfo.new(CONFIG.ANIM_DURATION, CONFIG.EASING_STYLE_WINDOW, CONFIG.EASING_DIRECTION_WINDOW)
    TweenService:Create(self.UIScale, scaleTweenInfo, {Scale = targetScale}):Play()

    -- For visibility, we toggle after a short delay for opening, and before for closing
    if self.IsOpen then
        self.Frame.Visible = true
        self:SetKasumiState("Active", "Window opened.")
    else
        self:SetKasumiState("Idle", "Window closed.")
        -- For closing, wait for tween to finish before making invisible
        task.delay(CONFIG.ANIM_DURATION, function()
            self.Frame.Visible = false
        end)
    end
end

function Window:CreateTab(name)
    local Tab = {}
    Tab.__index = Tab
    local selfTab = setmetatable({}, Tab)
    selfTab.Name = name
    selfTab.Elements = {}
    selfTab.ParentWindow = self

    selfTab.Button = Instance.new("TextButton")
    selfTab.Button.Name = name .. "TabButton"
    selfTab.Button.Size = UDim2.new(1, -10, 0, 25) -- Slightly smaller to show padding
    selfTab.Button.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    selfTab.Button.BorderSizePixel = 0
    selfTab.Button.Text = name
    selfTab.Button.Font = CONFIG.FONT
    selfTab.Button.TextSize = CONFIG.FONT_SIZE
    selfTab.Button.TextColor3 = CONFIG.TEXT_COLOR
    selfTab.Button.Parent = self.TabContainer

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = CONFIG.CORNER_RADIUS
    TabCorner.Parent = selfTab.Button

    selfTab.ContentFrame = Instance.new("Frame")
    selfTab.ContentFrame.Name = name .. "Content"
    selfTab.ContentFrame.Size = UDim2.new(1, 0, 1, 0)
    selfTab.ContentFrame.BackgroundTransparency = 1
    selfTab.ContentFrame.BorderSizePixel = 0
    selfTab.ContentFrame.Visible = false -- Hidden by default
    selfTab.ContentFrame.Parent = self.ContentContainer

    local ContentListLayout = Instance.new("UIListLayout")
    ContentListLayout.FillDirection = Enum.FillDirection.Vertical
    ContentListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ContentListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    ContentListLayout.Padding = UDim.new(0, 8)
    ContentListLayout.Parent = selfTab.ContentFrame

    selfTab.Button.MouseButton1Click:Connect(function()
        selfTab.ParentWindow:SwitchTab(selfTab)
        selfTab.ParentWindow:SetKasumiState("Active", "Switched to " .. name .. " tab.")
    end)

    table.insert(self.Tabs, selfTab)

    if not self.CurrentTab then
        self:SwitchTab(selfTab)
    end

    return selfTab
end

function Window:SwitchTab(tab)
    if self.CurrentTab then
        self.CurrentTab.Button.BackgroundColor3 = CONFIG.SECONDARY_COLOR
        self.CurrentTab.Button.TextColor3 = CONFIG.TEXT_COLOR
        self.CurrentTab.ContentFrame.Visible = false
    end

    self.CurrentTab = tab
    self.CurrentTab.Button.BackgroundColor3 = CONFIG.ACCENT_COLOR * 0.5 -- Highlight active tab
    self.CurrentTab.Button.TextColor3 = CONFIG.PRIMARY_COLOR -- Dark text on bright background
    self.CurrentTab.ContentFrame.Visible = true
end

-- UI Element Creators (for Tabs)
function Window.CreateButton(selfTab, text, callback)
    local Button = Instance.new("TextButton")
    Button.Name = text:gsub("%s+", "") .. "Button"
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.Font = CONFIG.FONT
    Button.TextSize = CONFIG.FONT_SIZE
    Button.TextColor3 = CONFIG.TEXT_COLOR
    Button.Parent = selfTab.ContentFrame

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = CONFIG.CORNER_RADIUS
    ButtonCorner.Parent = Button

    Button.MouseButton1Click:Connect(function()
        if callback then
            pcall(callback)
            selfTab.ParentWindow:SetKasumiState("Success", "'" .. text .. "' triggered.")
        end
    end)
    table.insert(selfTab.Elements, Button)
    return Button
end

function Window.CreateToggle(selfTab, text, initialState, callback)
    local isToggled = initialState
    local Frame = Instance.new("Frame")
    Frame.Name = text:gsub("%s+", "") .. "ToggleFrame"
    Frame.Size = UDim2.new(1, 0, 0, 30)
    Frame.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    Frame.BorderSizePixel = 0
    Frame.Parent = selfTab.ContentFrame

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = CONFIG.CORNER_RADIUS
    FrameCorner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.Text = text
    Label.Font = CONFIG.FONT
    Label.TextSize = CONFIG.FONT_SIZE
    Label.TextColor3 = CONFIG.TEXT_COLOR
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 40, 0, 20)
    ToggleButton.Position = UDim2.new(1, -45, 0.5, -10)
    ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
    ToggleButton.BackgroundColor3 = isToggled and CONFIG.ACCENT_COLOR or CONFIG.BORDER_COLOR
    ToggleButton.Text = isToggled and "ON" or "OFF"
    ToggleButton.Font = CONFIG.FONT
    ToggleButton.TextSize = CONFIG.FONT_SIZE - 2
    ToggleButton.TextColor3 = CONFIG.TEXT_COLOR
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = Frame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 5)
    ToggleCorner.Parent = ToggleButton

    ToggleButton.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        ToggleButton.BackgroundColor3 = isToggled and CONFIG.ACCENT_COLOR or CONFIG.BORDER_COLOR
        ToggleButton.Text = isToggled and "ON" or "OFF"
        if callback then
            pcall(callback, isToggled)
            selfTab.ParentWindow:SetKasumiState("Active", text .. ": " .. (isToggled and "ON" or "OFF"))
        end
    end)
    table.insert(selfTab.Elements, Frame)
    return Frame
end

function Window.CreateSlider(selfTab, text, min, max, initialValue, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = text:gsub("%s+", "") .. "SliderFrame"
    SliderFrame.Size = UDim2.new(1, 0, 0, 45)
    SliderFrame.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = selfTab.ContentFrame

    local SliderFrameCorner = Instance.new("UICorner")
    SliderFrameCorner.CornerRadius = CONFIG.CORNER_RADIUS
    SliderFrameCorner.Parent = SliderFrame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -60, 0, 20)
    Label.Position = UDim2.new(0, 5, 0, 5)
    Label.Text = text .. ": " .. initialValue
    Label.Font = CONFIG.FONT
    Label.TextSize = CONFIG.FONT_SIZE
    Label.TextColor3 = CONFIG.TEXT_COLOR
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = SliderFrame

    local Slider = Instance.new("Slider")
    Slider.Name = "Slider"
    Slider.Size = UDim2.new(1, -10, 0, 10)
    Slider.Position = UDim2.new(0, 5, 0, 28)
    Slider.Minimum = min
    Slider.Maximum = max
    Slider.Value = initialValue
    Slider.FillColor = CONFIG.ACCENT_COLOR
    Slider.BorderColor = CONFIG.BORDER_COLOR
    Slider.BackgroundTransparency = 0.8
    Slider.Parent = SliderFrame

    Slider.Changed:Connect(function()
        Label.Text = text .. ": " .. math.floor(Slider.Value) -- Round for display
        if callback then
            pcall(callback, Slider.Value)
            selfTab.ParentWindow:SetKasumiState("Active", text .. " set to " .. math.floor(Slider.Value))
        end
    end)
    table.insert(selfTab.Elements, SliderFrame)
    return SliderFrame
end

function Window.CreateDropdown(selfTab, text, options, callback)
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = text:gsub("%s+", "") .. "DropdownFrame"
    DropdownFrame.Size = UDim2.new(1, 0, 0, 30)
    DropdownFrame.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.Parent = selfTab.ContentFrame

    local DropdownFrameCorner = Instance.new("UICorner")
    DropdownFrameCorner.CornerRadius = CONFIG.CORNER_RADIUS
    DropdownFrameCorner.Parent = DropdownFrame

    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Name = "DropdownButton"
    DropdownButton.Size = UDim2.new(1, 0, 1, 0)
    DropdownButton.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    DropdownButton.BorderSizePixel = 0
    DropdownButton.Text = text .. " ▼"
    DropdownButton.Font = CONFIG.FONT
    DropdownButton.TextSize = CONFIG.FONT_SIZE
    DropdownButton.TextColor3 = CONFIG.TEXT_COLOR
    DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    DropdownButton.TextWrapped = true
    DropdownButton.Parent = DropdownFrame

    local DropdownList = Instance.new("Frame")
    DropdownList.Name = "DropdownList"
    DropdownList.Size = UDim2.new(1, 0, 0, 0) -- Height will expand
    DropdownList.Position = UDim2.new(0, 0, 1, 0)
    DropdownList.BackgroundColor3 = CONFIG.SECONDARY_COLOR * 0.8
    DropdownList.BorderSizePixel = 0
    DropdownList.Visible = false
    DropdownList.ZIndex = CONFIG.WINDOW_ZINDEX + 1 -- Above other elements
    DropdownList.Parent = DropdownFrame

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.FillDirection = Enum.FillDirection.Vertical
    ListLayout.Padding = UDim.new(0, 2)
    ListLayout.Parent = DropdownList

    local dropdownOpen = false

    local function updateDropdownHeight()
        DropdownList.Size = UDim2.new(1, 0, 0, #options * (CONFIG.FONT_SIZE + 10))
    end

    for i, optionText in ipairs(options) do
        local OptionButton = Instance.new("TextButton")
        OptionButton.Name = optionText:gsub("%s+", "") .. "Option"
        OptionButton.Size = UDim2.new(1, 0, 0, CONFIG.FONT_SIZE + 10)
        OptionButton.BackgroundColor3 = CONFIG.SECONDARY_COLOR * 0.9
        OptionButton.BorderSizePixel = 0
        OptionButton.Text = optionText
        OptionButton.Font = CONFIG.FONT
        OptionButton.TextSize = CONFIG.FONT_SIZE
        OptionButton.TextColor3 = CONFIG.TEXT_COLOR
        OptionButton.TextXAlignment = Enum.TextXAlignment.Left
        OptionButton.TextWrapped = true
        OptionButton.Parent = DropdownList

        OptionButton.MouseButton1Click:Connect(function()
            DropdownButton.Text = optionText .. " ▼"
            DropdownList.Visible = false
            dropdownOpen = false
            if callback then
                pcall(callback, optionText)
                selfTab.ParentWindow:SetKasumiState("Active", text .. " selected: " .. optionText)
            end
        end)
    end

    updateDropdownHeight()

    DropdownButton.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        DropdownList.Visible = dropdownOpen
        selfTab.ParentWindow:SetKasumiState("Active", "Dropdown " .. (dropdownOpen and "opened" or "closed"))
    end)
    table.insert(selfTab.Elements, DropdownFrame)
    return DropdownFrame
end

function Window.CreateTextBox(selfTab, text, callback)
    local TextBoxFrame = Instance.new("Frame")
    TextBoxFrame.Name = text:gsub("%s+", "") .. "TextBoxFrame"
    TextBoxFrame.Size = UDim2.new(1, 0, 0, 50)
    TextBoxFrame.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    TextBoxFrame.BorderSizePixel = 0
    TextBoxFrame.Parent = selfTab.ContentFrame

    local TextBoxFrameCorner = Instance.new("UICorner")
    TextBoxFrameCorner.CornerRadius = CONFIG.CORNER_RADIUS
    TextBoxFrameCorner.Parent = TextBoxFrame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -10, 0, 20)
    Label.Position = UDim2.new(0, 5, 0, 5)
    Label.Text = text
    Label.Font = CONFIG.FONT
    Label.TextSize = CONFIG.FONT_SIZE
    Label.TextColor3 = CONFIG.TEXT_COLOR
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = TextBoxFrame

    local InputBox = Instance.new("TextBox")
    InputBox.Name = "InputBox"
    InputBox.Size = UDim2.new(1, -10, 0, 20)
    InputBox.Position = UDim2.new(0, 5, 0, 25)
    InputBox.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    InputBox.BorderSizePixel = 0
    InputBox.Font = CONFIG.FONT
    InputBox.TextSize = CONFIG.FONT_SIZE
    InputBox.TextColor3 = CONFIG.TEXT_COLOR
    InputBox.PlaceholderText = "Type here..."
    InputBox.PlaceholderColor3 = CONFIG.TEXT_COLOR * 0.5
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.Parent = TextBoxFrame

    local InputBoxCorner = Instance.new("UICorner")
    InputBoxCorner.CornerRadius = UDim.new(0, 5)
    InputBoxCorner.Parent = InputBox

    InputBox.FocusBegan:Connect(function()
        selfTab.ParentWindow:SetKasumiState("Typing", "Awaiting input...")
    end)

    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and callback then
            pcall(callback, InputBox.Text)
            selfTab.ParentWindow:SetKasumiState("Success", "Input received: '" .. InputBox.Text .. "'")
            InputBox.Text = "" -- Clear after submission
        else
            selfTab.ParentWindow:SetKasumiState("Idle", "Input field unfocused.")
        end
    end)
    table.insert(selfTab.Elements, TextBoxFrame)
    return TextBoxFrame
end

return Library
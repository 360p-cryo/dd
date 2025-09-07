-- Overseer UI Library
-- Built from scratch by WaveAI.
-- Contains a window and a fully-featured color picker.

local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')

-- Main Library Table
local Overseer = {}

-- Theme Configuration
local Theme = {
    Primary = Color3.fromRGB(40, 255, 110),
    Secondary = Color3.fromRGB(20, 200, 90),
    
    WindowHeader = Color3.fromRGB(20, 22, 21),
    WindowBody = Color3.fromRGB(15, 16, 15),
    
    Element = Color3.fromRGB(35, 37, 36),
    ElementHover = Color3.fromRGB(45, 47, 46),
    ElementActive = Color3.fromRGB(55, 57, 56),

    Stroke = Color3.fromRGB(50, 52, 51),
    StrokeHover = Color3.fromRGB(70, 72, 71),
    
    TextPrimary = Color3.fromRGB(230, 230, 230),
    TextDim = Color3.fromRGB(150, 150, 150),
}

-- Utility Functions
local function tween(object, properties, duration)
    local info = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(object, info, properties):Play()
end

local function polarToCart(r, theta) 
    return r * math.cos(theta), r * math.sin(theta)
end

local function cartToPolar(x, y) 
    return math.sqrt((x^2) + (y^2)), math.atan2(y, x)
end

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui", gethui())
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn = false

-- Base Class for UI Elements
local BaseElement = {}
BaseElement.__index = BaseElement
function BaseElement:new()
    local self = setmetatable({}, BaseElement)
    self.Events = {}
    return self
end
function BaseElement:On(event, callback)
    self.Events[event] = self.Events[event] or {}
    table.insert(self.Events[event], callback)
end
function BaseElement:Fire(event, ...)
    if self.Events[event] then
        for _, callback in ipairs(self.Events[event]) do
            task.spawn(callback, ...)
        end
    end
end

-- Color Picker Popup Window Class (Extracted and Adapted)
local ColorPickerWindow = {}
ColorPickerWindow.__index = ColorPickerWindow
setmetatable(ColorPickerWindow, BaseElement)

function ColorPickerWindow:new(parentPicker)
    local self = setmetatable(BaseElement:new(), ColorPickerWindow)

    self.Picker = parentPicker
    self.Hue, self.Sat, self.Val = parentPicker.Color:ToHSV()
    self.ChromaEnabled = false
    
    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.fromOffset(250, 280)
    Frame.BackgroundColor3 = Theme.WindowBody
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 500
    Frame.Parent = ScreenGui
    self.Frame = Frame
    
    Instance.new("UIStroke", Frame).Color = Theme.Stroke

    -- Title Bar
    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1, 0, 0, 25)
    TitleBar.BackgroundColor3 = Theme.WindowHeader
    TitleBar.BorderSizePixel = 0
    
    Instance.new("UIStroke", TitleBar).Color = Theme.Stroke
    
    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -30, 1, 0)
    Title.Position = UDim2.fromOffset(5, 0)
    Title.Text = parentPicker.Title
    Title.Font = "SourceSans"
    Title.TextColor3 = Theme.TextPrimary
    Title.TextSize = 14
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = "Left"

    local CloseButton = Instance.new("TextButton", TitleBar)
    CloseButton.Size = UDim2.fromOffset(18, 18)
    CloseButton.Position = UDim2.new(1, -22, 0.5, -9)
    CloseButton.Text = "X"
    CloseButton.Font = "SourceSansBold"
    CloseButton.TextSize = 14
    CloseButton.TextColor3 = Theme.TextDim
    CloseButton.BackgroundColor3 = Theme.Element
    CloseButton.MouseButton1Click:Connect(function() self:Destroy() end)

    -- Color Wheel
    local Wheel = Instance.new("ImageLabel", Frame)
    Wheel.Size = UDim2.fromOffset(150, 150)
    Wheel.Position = UDim2.new(0.5, -75, 0, 35)
    Wheel.Image = "rbxassetid://9801454501"
    Wheel.BackgroundTransparency = 1
    
    local Cursor = Instance.new("Frame", Wheel)
    Cursor.Size = UDim2.fromOffset(8, 8)
    Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
    Cursor.BackgroundColor3 = Color3.new(1,1,1)
    Cursor.BorderSizePixel = 0
    Instance.new("UICorner", Cursor).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke", Cursor).Color = Color3.new(0,0,0)
    
    -- Value Slider
    local ValTrack = Instance.new("Frame", Frame)
    ValTrack.Size = UDim2.new(1, -20, 0, 12)
    ValTrack.Position = UDim2.new(0.5, -((Frame.AbsoluteSize.X - 20)/2), 0, 195)
    ValTrack.BackgroundColor3 = Theme.Element
    Instance.new("UIStroke", ValTrack).Color = Theme.Stroke

    local ValFill = Instance.new("UIGradient", ValTrack)
    ValFill.Rotation = 180
    
    local ValHandle = Instance.new("Frame", ValTrack)
    ValHandle.Size = UDim2.new(0, 4, 1, 2)
    ValHandle.Position = UDim2.fromScale(1, -0.5)
    ValHandle.BackgroundColor3 = Color3.new(1,1,1)
    ValHandle.BorderSizePixel = 0
    Instance.new("UIStroke", ValHandle).Color = Color3.new(0,0,0)

    -- Chroma Button
    local ChromaButton = Instance.new("TextButton", Frame)
    ChromaButton.Size = UDim2.fromOffset(20, 20)
    ChromaButton.Position = UDim2.new(0, 10, 0, 220)
    ChromaButton.BackgroundColor3 = Theme.Element
    ChromaButton.Text = ""
    Instance.new("UIStroke", ChromaButton).Color = Theme.Stroke
    
    local ChromaIcon = Instance.new("ImageLabel", ChromaButton)
    ChromaIcon.Size = UDim2.new(1,-4,1,-4)
    ChromaIcon.Position = UDim2.fromScale(0.5,0.5)
    ChromaIcon.AnchorPoint = Vector2.new(0.5,0.5)
    ChromaIcon.BackgroundTransparency = 1
    ChromaIcon.Image = "rbxassetid://9841673199"
    
    -- Logic
    function self:UpdateColor(from)
        local color = Color3.fromHSV(self.Hue, self.Sat, self.Val)
        self.Picker:SetColor(color)

        if from ~= "wheel" then
            local radius = self.Sat / 2
            local theta = self.Hue * (math.pi * 2) - math.pi
            local x, y = polarToCart(radius, theta)
            Cursor.Position = UDim2.fromScale(x + 0.5, y + 0.5)
        end

        if from ~= "value" then
            ValHandle.Position = UDim2.fromScale(self.Val, -0.5)
        end
        
        ValFill.Color = ColorSequence.new(Color3.fromHSV(self.Hue, self.Sat, 0), Color3.fromHSV(self.Hue, self.Sat, 1))
    end
    
    local wheelDragging = false
    Wheel.InputBegan:Connect(function() wheelDragging = true end)
    Wheel.InputEnded:Connect(function() wheelDragging = false end)
    
    local valDragging = false
    ValTrack.InputBegan:Connect(function() valDragging = true end)
    ValTrack.InputEnded:Connect(function() valDragging = false end)
    
    RunService.Heartbeat:Connect(function()
        if wheelDragging then
            local mousePos = UserInputService:GetMouseLocation()
            local wheelPos = Wheel.AbsolutePosition
            local wheelSize = Wheel.AbsoluteSize
            local x = (mousePos.X - wheelPos.X) / wheelSize.X - 0.5
            local y = (mousePos.Y - wheelPos.Y) / wheelSize.Y - 0.5
            
            local radius, theta = cartToPolar(x, y)
            self.Sat = math.clamp(radius * 2, 0, 1)
            self.Hue = (theta / math.pi + 1) / 2
            
            self:UpdateColor("wheel")
        end
        if valDragging then
            local mouseX = UserInputService:GetMouseLocation().X
            local trackX = ValTrack.AbsolutePosition.X
            local trackWidth = ValTrack.AbsoluteSize.X
            self.Val = math.clamp((mouseX - trackX) / trackWidth, 0, 1)
            self:UpdateColor("value")
        end
        if self.ChromaEnabled and self.ChromaConnection.Connected then
            self.Hue = (self.Hue + 0.005) % 1
            self:UpdateColor()
        end
    end)
    
    ChromaButton.MouseButton1Click:Connect(function()
        self.ChromaEnabled = not self.ChromaEnabled
        if self.ChromaEnabled then
            tween(ChromaIcon, {Rotation = 360}, 0.5)
            ChromaIcon.ImageColor3 = Theme.Primary
            self.ChromaConnection = RunService.Heartbeat:Connect(function() end) -- dummy connection
        else
            tween(ChromaIcon, {Rotation = 0}, 0.5)
            ChromaIcon.ImageColor3 = Color3.new(1,1,1)
            if self.ChromaConnection then self.ChromaConnection:Disconnect() end
        end
    end)
    
    self:UpdateColor()
    return self
end

function ColorPickerWindow:Destroy()
    if self.ChromaConnection and self.ChromaConnection.Connected then self.ChromaConnection:Disconnect() end
    self.Frame:Destroy()
    self.Picker.PickerWindow = nil
    self:Fire("Close")
end

-- Color Picker Element Class
local ColorPicker = {}
ColorPicker.__index = ColorPicker
setmetatable(ColorPicker, BaseElement)

function ColorPicker:new(options)
    local self = setmetatable(BaseElement:new(), ColorPicker)
    
    self.Title = options.Title or "Color Picker"
    self.Color = options.Default or Color3.new(1,1,1)
    self.PickerWindow = nil

    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 20)
    Frame.BackgroundTransparency = 1
    self.Frame = Frame
    
    -- Label
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -25, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Font = "SourceSans"
    Label.Text = self.Title
    Label.TextColor3 = Theme.TextPrimary
    Label.TextSize = 14
    Label.TextXAlignment = "Left"
    
    -- Color Display Button
    local Button = Instance.new("TextButton", Frame)
    Button.Size = UDim2.fromOffset(16, 16)
    Button.Position = UDim2.new(1, -16, 0.5, -8)
    Button.BackgroundColor3 = Theme.Element
    Button.Text = ""
    
    local ButtonStroke = Instance.new("UIStroke", Button)
    ButtonStroke.Color = Theme.Stroke
    
    local Display = Instance.new("Frame", Button)
    Display.Size = UDim2.new(1, -4, 1, -4)
    Display.Position = UDim2.fromScale(0.5,0.5)
    Display.AnchorPoint = Vector2.new(0.5,0.5)
    Display.BackgroundColor3 = self.Color
    Display.BorderSizePixel = 0
    Instance.new("UICorner", Display).CornerRadius = UDim.new(0, 2)
    self.Display = Display

    Button.MouseEnter:Connect(function() tween(ButtonStroke, {Color = Theme.StrokeHover}) end)
    Button.MouseLeave:Connect(function() tween(ButtonStroke, {Color = Theme.Stroke}) end)
    Button.MouseButton1Click:Connect(function() self:Open() end)
    
    self:On("ColorChanged", options.Callback or function() end)
    
    return self
end

function ColorPicker:SetColor(color)
    self.Color = color
    self.Display.BackgroundColor3 = color
    self:Fire("ColorChanged", color)
end

function ColorPicker:Open()
    if self.PickerWindow then return end
    self.PickerWindow = ColorPickerWindow:new(self)
    
    local mousePos = UserInputService:GetMouseLocation()
    self.PickerWindow.Frame.Position = UDim2.fromOffset(mousePos.X + 10, mousePos.Y)
end

-- Window Class
local Window = {}
Window.__index = Window
setmetatable(Window, BaseElement)

function Window:new(options)
    local self = setmetatable(BaseElement:new(), Window)

    self.Frame = Instance.new("Frame")
    self.Frame.Size = options.Size or UDim2.fromOffset(300, 400)
    self.Frame.Position = UDim2.new(0.5, -self.Frame.AbsoluteSize.X / 2, 0.5, -self.Frame.AbsoluteSize.Y / 2)
    self.Frame.BackgroundColor3 = Theme.WindowBody
    self.Frame.BorderSizePixel = 0
    self.Frame.Parent = ScreenGui
    
    Instance.new("UIStroke", self.Frame).Color = Theme.Stroke
    
    local TitleBar = Instance.new("Frame", self.Frame)
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Theme.WindowHeader
    
    local Accent = Instance.new("Frame", TitleBar)
    Accent.Size = UDim2.new(1, 0, 0, 1)
    Accent.Position = UDim2.new(0, 0, 1, -1)
    Accent.BackgroundColor3 = Theme.Primary
    Accent.BorderSizePixel = 0
    
    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.Position = UDim2.fromOffset(10, 0)
    Title.Text = options.Title or "Overseer"
    Title.Font = "SourceSansBold"
    Title.TextSize = 16
    Title.TextColor3 = Theme.TextPrimary
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = "Left"
    
    self.Content = Instance.new("ScrollingFrame", self.Frame)
    self.Content.Size = UDim2.new(1, -10, 1, -35)
    self.Content.Position = UDim2.fromOffset(5, 30)
    self.Content.BackgroundTransparency = 1
    self.Content.BorderSizePixel = 0
    self.Content.ScrollBarThickness = 3
    
    local layout = Instance.new("UIListLayout", self.Content)
    layout.Padding = UDim.new(0, 5)

    -- Dragging
    local dragging = false
    local dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return self
end

function Window:AddColorPicker(options)
    local picker = ColorPicker:new(options)
    picker.Frame.Parent = self.Content
    return picker
end

-- Main API
function Overseer:CreateWindow(options)
    return Window:new(options)
end

return Overseer

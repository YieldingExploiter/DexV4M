-- Gui to Lua
-- Version: 3.2
-- Instances:
local LoadingUI = Instance.new('ScreenGui')
local MainUI = Instance.new('Frame')
local UICorner = Instance.new('UICorner')
local Title = Instance.new('TextLabel')
local Version = Instance.new('TextLabel')
local Subtitle = Instance.new('TextLabel')
local Changelog = Instance.new('Frame')
local UICorner_2 = Instance.new('UICorner')
local Subtitle_2 = Instance.new('TextLabel')
local Changes = Instance.new('TextLabel')
local UICorner_3 = Instance.new('UICorner')
local StatusInformation = Instance.new('ScrollingFrame')
local UICorner_4 = Instance.new('UICorner')
local Text = Instance.new('TextLabel')

-- Properties:
LoadingUI.Name = 'LoadingUI'

MainUI.Name = 'MainUI'
MainUI.Parent = LoadingUI
MainUI.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainUI.Position = UDim2.new(0.290322572, 0, 0.250309795, 0)
MainUI.Size = UDim2.new(0, 519, 0, 403)

UICorner.Parent = MainUI

Title.Name = 'Title'
Title.Parent = MainUI
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.Position = UDim2.new(0.294797659, 0, 0.0471464023, 0)
Title.Size = UDim2.new(0.385356456, 0, 0.0818858594, 0)
Title.Font = Enum.Font.SourceSans
Title.Text = 'Rex V5'
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextSize = 14.000
Title.TextWrapped = true

Version.Name = 'Version'
Version.Parent = MainUI
Version.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Version.BackgroundTransparency = 1.000
Version.Position = UDim2.new(0.196531788, 0, 0.957816362, 0)
Version.Size = UDim2.new(0.606936395, 0, 0.0421836227, 0)
Version.Font = Enum.Font.SourceSans
Version.Text = 'Loader v%s | Loading Rex v%s'
Version.TextColor3 = Color3.fromRGB(99, 99, 99)
Version.TextScaled = true
Version.TextSize = 14.000
Version.TextWrapped = true

Subtitle.Name = 'Subtitle'
Subtitle.Parent = MainUI
Subtitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Subtitle.BackgroundTransparency = 1.000
Subtitle.Position = UDim2.new(0.294797689, 0, 0.129032254, 0)
Subtitle.Size = UDim2.new(0.385356456, 0, 0.0521091819, 0)
Subtitle.Font = Enum.Font.SourceSans
Subtitle.Text = 'Dex, Reimagined'
Subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
Subtitle.TextScaled = true
Subtitle.TextSize = 14.000
Subtitle.TextWrapped = true

Changelog.Name = 'Changelog'
Changelog.Parent = MainUI
Changelog.AnchorPoint = Vector2.new(1, 0.5)
Changelog.BackgroundColor3 = Color3.fromRGB(20, 21, 24)
Changelog.Position = UDim2.new(1.33526015, 0, 0.5, 0)
Changelog.Size = UDim2.new(0.296724468, 0, 1, 0)

UICorner_2.Parent = Changelog

Subtitle_2.Name = 'Subtitle'
Subtitle_2.Parent = Changelog
Subtitle_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Subtitle_2.BackgroundTransparency = 1.000
Subtitle_2.Position = UDim2.new(0.157996237, 0, 0.0471464023, 0)
Subtitle_2.Size = UDim2.new(0.703538239, 0, 0.0521091819, 0)
Subtitle_2.Font = Enum.Font.SourceSans
Subtitle_2.Text = 'Changelog'
Subtitle_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Subtitle_2.TextScaled = true
Subtitle_2.TextSize = 14.000
Subtitle_2.TextWrapped = true

Changes.Name = 'Changes'
Changes.Parent = Changelog
Changes.AnchorPoint = Vector2.new(0.5, 0.5)
Changes.BackgroundColor3 = Color3.fromRGB(20, 21, 24)
Changes.BorderColor3 = Color3.fromRGB(255, 255, 255)
Changes.BorderSizePixel = 2
Changes.Position = UDim2.new(0.5, 0, 0.549404919, 0)
Changes.Size = UDim2.new(0.835510135, 0, 0.84074533, 0)
Changes.Font = Enum.Font.SourceSans
Changes.Text = '<br/>Did some stuff'
Changes.TextColor3 = Color3.fromRGB(255, 255, 255)
Changes.TextSize = 14.000
Changes.TextWrapped = true
Changes.TextYAlignment = Enum.TextYAlignment.Top

UICorner_3.Parent = Changes

StatusInformation.Name = 'StatusInformation'
StatusInformation.Parent = MainUI
StatusInformation.BackgroundColor3 = Color3.fromRGB(20, 21, 24)
StatusInformation.BorderSizePixel = 0
StatusInformation.Position = UDim2.new(0.240847781, 0, 0.225806445, 0)
StatusInformation.Selectable = false
StatusInformation.Size = UDim2.new(0.518304408, 0, 0.694789112, 0)
StatusInformation.BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png'
StatusInformation.TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png'
StatusInformation.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar

UICorner_4.Parent = StatusInformation

Text.Name = 'Text'
Text.Parent = StatusInformation
Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Text.BackgroundTransparency = 1.000
Text.Position = UDim2.new(0, 16, 0, 16)
Text.Size = UDim2.new(1, -32, 1, -32)
Text.Font = Enum.Font.SourceSans
Text.TextColor3 = Color3.fromRGB(255, 255, 255)
Text.TextSize = 14.000
Text.TextXAlignment = Enum.TextXAlignment.Left
Text.TextYAlignment = Enum.TextYAlignment.Top

return LoadingUI

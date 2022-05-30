--[[
	DEX Main Script
	
	Created by: Moon and Courtney
	
	RASPBERRY PI IS A SKIDDY SKID AF
--]] -- Metas
local Services = setmetatable({}, {
  __index = function(self, ind)
    if pcall(function() game:GetService(ind) end) then
      return game:GetService(ind)
    else
      return nil
    end
  end;
})

function CreateInstance(cls, props)
  local inst = Instance.new(cls)
  for i, v in pairs(props) do inst[i] = v end
  return inst
end

local createDexGui = require('func/createDexGui')

-- Main Gui References
local gui = createDexGui()
gui.Parent = Services.CoreGui
local contentL = gui:WaitForChild('ContentFrameL')
local contentR = gui:WaitForChild('ContentFrameR')
local resources = gui:WaitForChild('Resources')

-- Welcome Gui References
local welcomeFrame = gui:WaitForChild('WelcomeFrame')
local welcomeOutline = welcomeFrame:WaitForChild('Outline')
local welcomeContents = welcomeFrame:WaitForChild('Content')
local welcomeMain = welcomeContents:WaitForChild('Main')
local welcomeChangelog = welcomeContents:WaitForChild('Changelog')
local welcomeBottom = welcomeContents:WaitForChild('Bottom')
local welcomeProgress = welcomeMain:WaitForChild('Progress')

-- Explorer Stuff
local explorerTree = nil
local updateDebounce = false
local rightClickContext = nil
local rightEntry = nil
local clipboard = {}
local lastSearch = 0
local nodeWidth = 0

-- Properties Stuff
local propertiesTree = nil
local propWidth = 0

-- Settings
local explorerSettings = {LPaneWidth = 300; RPaneWidth = 300}

-- JSON Stuff
local API
local RMD

-- Main Variables
local mouse = Services.Players.LocalPlayer:GetMouse()
local mouseWindow = nil
local LPaneItems = {}
local RPaneItems = {}
local setPane = 'None'
local activeWindows = {}
local f = {}
local API = {}
local RMD = {}

-- ScrollBar
function f.buttonArrows(size, num, dir)
  local max = num
  local arrowFrame =
      CreateInstance('Frame', {BackgroundTransparency = 1; Name = 'Arrow'; Size = UDim2.new(0, size, 0, size)})
  if dir == 'up' then
    for i = 1, num do
      local newLine = CreateInstance('Frame', {
        BackgroundColor3 = Color3.new(220 / 255, 220 / 255, 220 / 255);
        BorderSizePixel = 0;
        Position = UDim2.new(0, math.floor(size / 2) - (i - 1), 0, math.floor(size / 2) + i - math.floor(max / 2) - 1);
        Size = UDim2.new(0, i + (i - 1), 0, 1);
        Parent = arrowFrame;
      })
    end
    return arrowFrame
  elseif dir == 'down' then
    for i = 1, num do
      local newLine = CreateInstance('Frame', {
        BackgroundColor3 = Color3.new(220 / 255, 220 / 255, 220 / 255);
        BorderSizePixel = 0;
        Position = UDim2.new(0, math.floor(size / 2) - (i - 1), 0, math.floor(size / 2) - i + math.floor(max / 2) + 1);
        Size = UDim2.new(0, i + (i - 1), 0, 1);
        Parent = arrowFrame;
      })
    end
    return arrowFrame
  elseif dir == 'left' then
    for i = 1, num do
      local newLine = CreateInstance('Frame', {
        BackgroundColor3 = Color3.new(220 / 255, 220 / 255, 220 / 255);
        BorderSizePixel = 0;
        Position = UDim2.new(0, math.floor(size / 2) + i - math.floor(max / 2) - 1, 0, math.floor(size / 2) - (i - 1));
        Size = UDim2.new(0, 1, 0, i + (i - 1));
        Parent = arrowFrame;
      })
    end
    return arrowFrame
  elseif dir == 'right' then
    for i = 1, num do
      local newLine = CreateInstance('Frame', {
        BackgroundColor3 = Color3.new(220 / 255, 220 / 255, 220 / 255);
        BorderSizePixel = 0;
        Position = UDim2.new(0, math.floor(size / 2) - i + math.floor(max / 2) + 1, 0, math.floor(size / 2) - (i - 1));
        Size = UDim2.new(0, 1, 0, i + (i - 1));
        Parent = arrowFrame;
      })
    end
    return arrowFrame
  end
  error('r u ok')
end

local ScrollBar
do
  ScrollBar = {}

  local user = game:GetService('UserInputService')
  local mouse = game:GetService('Players').LocalPlayer:GetMouse()

  ScrollMt = {
    __index = {
      AddMarker = function(self, ind, color) self.Markers[ind] = color or Color3.new(0, 0, 0) end;
      ScrollTo = function(self, ind)
        self.Index = ind
        self:Update()
      end;
      ScrollUp = function(self)
        self.Index = self.Index - self.Increment
        self:Update()
      end;
      ScrollDown = function(self)
        self.Index = self.Index + self.Increment
        self:Update()
      end;
      CanScrollUp = function(self) return self.Index > 0 end;
      CanScrollDown = function(self) return self.Index + self.VisibleSpace < self.TotalSpace end;
      GetScrollPercent = function(self) return self.Index / (self.TotalSpace - self.VisibleSpace) end;
      SetScrollPercent = function(self, perc)
        self.Index = math.floor(perc * (self.TotalSpace - self.VisibleSpace))
        self:Update()
      end;
    };
  }

  function ScrollBar.new(hor)
    local newFrame = CreateInstance('Frame', {
      Style = 0;
      Active = false;
      AnchorPoint = Vector2.new(0, 0);
      BackgroundColor3 = Color3.new(0.35294118523598, 0.35294118523598, 0.35294118523598);
      BackgroundTransparency = 0;
      BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
      BorderSizePixel = 0;
      ClipsDescendants = false;
      Draggable = false;
      Position = UDim2.new(1, -16, 0, 0);
      Rotation = 0;
      Selectable = false;
      Size = UDim2.new(0, 16, 1, 0);
      SizeConstraint = 0;
      Visible = true;
      ZIndex = 1;
      Name = 'ScrollBar';
    })
    local button1 = nil
    local button2 = nil

    local lastTotalSpace = 0

    if hor then
      newFrame.Size = UDim2.new(1, 0, 0, 16)
      button1 = CreateInstance('ImageButton', {
        Parent = newFrame;
        Name = 'Left';
        Size = UDim2.new(0, 16, 0, 16);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        AutoButtonColor = false;
      })
      f.buttonArrows(16, 4, 'left').Parent = button1
      button2 = CreateInstance('ImageButton', {
        Parent = newFrame;
        Name = 'Right';
        Position = UDim2.new(1, -16, 0, 0);
        Size = UDim2.new(0, 16, 0, 16);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        AutoButtonColor = false;
      })
      f.buttonArrows(16, 4, 'right').Parent = button2
    else
      newFrame.Size = UDim2.new(0, 16, 1, 0)
      button1 = CreateInstance('ImageButton', {
        Parent = newFrame;
        Name = 'Up';
        Size = UDim2.new(0, 16, 0, 16);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        AutoButtonColor = false;
      })
      f.buttonArrows(16, 4, 'up').Parent = button1
      button2 = CreateInstance('ImageButton', {
        Parent = newFrame;
        Name = 'Down';
        Position = UDim2.new(0, 0, 1, -16);
        Size = UDim2.new(0, 16, 0, 16);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        AutoButtonColor = false;
      })
      f.buttonArrows(16, 4, 'down').Parent = button2
    end

    local scrollThumbFrame = CreateInstance('Frame', {BackgroundTransparency = 1; Parent = newFrame})
    if hor then
      scrollThumbFrame.Position = UDim2.new(0, 16, 0, 0)
      scrollThumbFrame.Size = UDim2.new(1, -32, 1, 0)
    else
      scrollThumbFrame.Position = UDim2.new(0, 0, 0, 16)
      scrollThumbFrame.Size = UDim2.new(1, 0, 1, -32)
    end

    local scrollThumb = CreateInstance('Frame', {
      BackgroundColor3 = Color3.new(120 / 255, 120 / 255, 120 / 255);
      BorderSizePixel = 0;
      Parent = scrollThumbFrame;
    })

    local markerFrame = CreateInstance('Frame', {
      BackgroundTransparency = 1;
      Name = 'Markers';
      Size = UDim2.new(1, 0, 1, 0);
      Parent = scrollThumbFrame;
    })

    local newMt = setmetatable({Gui = newFrame; Index = 0; VisibleSpace = 0; TotalSpace = 0; Increment = 1; Markers = {}},
                               ScrollMt)

    local function drawThumb()
      local total = newMt.TotalSpace
      local visible = newMt.VisibleSpace
      local index = newMt.Index

      if not (newMt:CanScrollUp() or newMt:CanScrollDown()) then
        scrollThumb.Visible = false
      else
        scrollThumb.Visible = true
      end

      if hor then
        scrollThumb.Size = UDim2.new(visible / total, 0, 1, 0)
        if scrollThumb.AbsoluteSize.X < 16 then scrollThumb.Size = UDim2.new(0, 16, 1, 0) end
        local fs = scrollThumbFrame.AbsoluteSize.X
        local bs = scrollThumb.AbsoluteSize.X
        scrollThumb.Position = UDim2.new(newMt:GetScrollPercent() * (fs - bs) / fs, 0, 0, 0)
      else
        scrollThumb.Size = UDim2.new(1, 0, visible / total, 0)
        if scrollThumb.AbsoluteSize.Y < 16 then scrollThumb.Size = UDim2.new(1, 0, 0, 16) end
        local fs = scrollThumbFrame.AbsoluteSize.Y
        local bs = scrollThumb.AbsoluteSize.Y
        scrollThumb.Position = UDim2.new(0, 0, newMt:GetScrollPercent() * (fs - bs) / fs, 0)
      end
    end

    local function updateMarkers()
      markerFrame:ClearAllChildren()

      for i, v in pairs(newMt.Markers) do
        if i < newMt.TotalSpace then
          CreateInstance('Frame', {
            BackgroundTransparency = 0;
            BackgroundColor3 = v;
            BorderSizePixel = 0;
            Position = hor and UDim2.new(i / newMt.TotalSpace, 0, 1, -6) or UDim2.new(1, -6, i / newMt.TotalSpace, 0);
            Size = hor and UDim2.new(0, 1, 0, 6) or UDim2.new(0, 6, 0, 1);
            Name = 'Marker' .. tostring(i);
            Parent = markerFrame;
          })
        end
      end
    end
    newMt.UpdateMarkers = updateMarkers

    local function update()
      local total = newMt.TotalSpace
      local visible = newMt.VisibleSpace
      local index = newMt.Index

      if visible <= total then
        if index > 0 then
          if index + visible > total then newMt.Index = total - visible end
        else
          newMt.Index = 0
        end
      else
        newMt.Index = 0
      end

      if lastTotalSpace ~= newMt.TotalSpace then
        lastTotalSpace = newMt.TotalSpace
        updateMarkers()
      end

      if newMt.OnUpdate then newMt:OnUpdate() end

      if newMt:CanScrollUp() then
        for i, v in pairs(button1.Arrow:GetChildren()) do v.BackgroundTransparency = 0 end
      else
        button1.BackgroundTransparency = 1
        for i, v in pairs(button1.Arrow:GetChildren()) do v.BackgroundTransparency = 0.5 end
      end
      if newMt:CanScrollDown() then
        for i, v in pairs(button2.Arrow:GetChildren()) do v.BackgroundTransparency = 0 end
      else
        button2.BackgroundTransparency = 1
        for i, v in pairs(button2.Arrow:GetChildren()) do v.BackgroundTransparency = 0.5 end
      end

      drawThumb()
    end

    local buttonPress = false
    local thumbPress = false
    local thumbFramePress = false

    local thumbColor = Color3.new(120 / 255, 120 / 255, 120 / 255)
    local thumbSelectColor = Color3.new(140 / 255, 140 / 255, 140 / 255)
    button1.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement and not buttonPress and newMt:CanScrollUp() then
        button1.BackgroundTransparency = 0.8
      end
      if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not newMt:CanScrollUp() then return end
      buttonPress = true
      button1.BackgroundTransparency = 0.5
      if newMt:CanScrollUp() then newMt:ScrollUp() end
      local buttonTick = tick()
      local releaseEvent
      releaseEvent = user.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        releaseEvent:Disconnect()
        if f.checkMouseInGui(button1) and newMt:CanScrollUp() then
          button1.BackgroundTransparency = 0.8
        else
          button1.BackgroundTransparency = 1
        end
        buttonPress = false
      end)
      while buttonPress do
        if tick() - buttonTick >= 0.3 and newMt:CanScrollUp() then newMt:ScrollUp() end
        wait()
      end
    end)
    button1.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement and not buttonPress then
        button1.BackgroundTransparency = 1
      end
    end)
    button2.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement and not buttonPress and newMt:CanScrollDown() then
        button2.BackgroundTransparency = 0.8
      end
      if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not newMt:CanScrollDown() then return end
      buttonPress = true
      button2.BackgroundTransparency = 0.5
      if newMt:CanScrollDown() then newMt:ScrollDown() end
      local buttonTick = tick()
      local releaseEvent
      releaseEvent = user.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        releaseEvent:Disconnect()
        if f.checkMouseInGui(button2) and newMt:CanScrollDown() then
          button2.BackgroundTransparency = 0.8
        else
          button2.BackgroundTransparency = 1
        end
        buttonPress = false
      end)
      while buttonPress do
        if tick() - buttonTick >= 0.3 and newMt:CanScrollDown() then newMt:ScrollDown() end
        wait()
      end
    end)
    button2.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement and not buttonPress then
        button2.BackgroundTransparency = 1
      end
    end)

    scrollThumb.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement and not thumbPress then
        scrollThumb.BackgroundTransparency = 0.2
        scrollThumb.BackgroundColor3 = thumbSelectColor
      end
      if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

      local dir = hor and 'X' or 'Y'
      local lastThumbPos = nil

      buttonPress = false
      thumbFramePress = false
      thumbPress = true
      scrollThumb.BackgroundTransparency = 0
      local mouseOffset = mouse[dir] - scrollThumb.AbsolutePosition[dir]
      local mouseStart = mouse[dir]
      local releaseEvent
      local mouseEvent
      releaseEvent = user.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        releaseEvent:Disconnect()
        if mouseEvent then mouseEvent:Disconnect() end
        if f.checkMouseInGui(scrollThumb) then
          scrollThumb.BackgroundTransparency = 0.2
        else
          scrollThumb.BackgroundTransparency = 0
          scrollThumb.BackgroundColor3 = thumbColor
        end
        thumbPress = false
      end)
      newMt:Update()
      -- while math.abs(mouse[dir] - mouseStart) == 0 do wait() end
      mouseEvent = user.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and thumbPress and releaseEvent.Connected then
          local thumbFrameSize = scrollThumbFrame.AbsoluteSize[dir] - scrollThumb.AbsoluteSize[dir]
          local pos = mouse[dir] - scrollThumbFrame.AbsolutePosition[dir] - mouseOffset
          if pos > thumbFrameSize then
            pos = thumbFrameSize
          elseif pos < 0 then
            pos = 0
          end
          if lastThumbPos ~= pos then
            lastThumbPos = pos
            newMt:ScrollTo(math.floor(pos / thumbFrameSize * (newMt.TotalSpace - newMt.VisibleSpace)))
          end
          wait()
        end
      end)
    end)
    scrollThumb.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement and not thumbPress then
        scrollThumb.BackgroundTransparency = 0
        scrollThumb.BackgroundColor3 = thumbColor
      end
    end)
    scrollThumbFrame.InputBegan:Connect(function(input)
      if input.UserInputType ~= Enum.UserInputType.MouseButton1 or f.checkMouseInGui(scrollThumb) then return end

      local dir = hor and 'X' or 'Y'

      local function doTick()
        local thumbFrameSize = scrollThumbFrame.AbsoluteSize[dir] - scrollThumb.AbsoluteSize[dir]
        local thumbFrameDist = scrollThumb.AbsolutePosition[dir] - scrollThumbFrame.AbsolutePosition[dir]
        local pos = thumbFrameDist +
                        (mouse[dir] < scrollThumb.AbsolutePosition[dir] + math.floor(scrollThumb.AbsoluteSize[dir] / 2) and
                            -50 or 50)
        if pos > thumbFrameSize then
          pos = thumbFrameSize
        elseif pos < 0 then
          pos = 0
        end
        if pos < thumbFrameDist and scrollThumbFrame.AbsolutePosition[dir] + pos +
            math.floor(scrollThumb.AbsoluteSize[dir] / 2) <= mouse[dir] then
          pos = mouse[dir] - scrollThumbFrame.AbsolutePosition[dir] - math.floor(scrollThumb.AbsoluteSize[dir] / 2)
        elseif pos > thumbFrameDist and scrollThumbFrame.AbsolutePosition[dir] + pos +
            math.floor(scrollThumb.AbsoluteSize[dir] / 2) >= mouse[dir] then
          pos = mouse[dir] - scrollThumbFrame.AbsolutePosition[dir] - math.floor(scrollThumb.AbsoluteSize[dir] / 2)
        end
        newMt:ScrollTo(math.floor(pos / thumbFrameSize * (newMt.TotalSpace - newMt.VisibleSpace)))
      end

      thumbPress = false
      thumbFramePress = true
      doTick()
      local thumbFrameTick = tick()
      local releaseEvent
      releaseEvent = user.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        releaseEvent:Disconnect()
        thumbFramePress = false
      end)
      while thumbFramePress and not f.checkMouseInGui(scrollThumb) do
        if tick() - thumbFrameTick >= 0.3 then doTick() end
        wait()
      end
    end)

    local function texture(self, data)
      thumbColor = data.ThumbColor or Color3.new(0, 0, 0)
      thumbSelectColor = data.ThumbSelectColor or Color3.new(0, 0, 0)
      scrollThumb.BackgroundColor3 = data.ThumbColor or Color3.new(0, 0, 0)
      newFrame.BackgroundColor3 = data.FrameColor or Color3.new(0, 0, 0)
      button1.BackgroundColor3 = data.ButtonColor or Color3.new(0, 0, 0)
      button2.BackgroundColor3 = data.ButtonColor or Color3.new(0, 0, 0)
      for i, v in pairs(button1.Arrow:GetChildren()) do v.BackgroundColor3 = data.ArrowColor or Color3.new(0, 0, 0) end
      for i, v in pairs(button2.Arrow:GetChildren()) do v.BackgroundColor3 = data.ArrowColor or Color3.new(0, 0, 0) end
    end
    newMt.Texture = texture

    local wheelIncrement = 1
    local scrollOverlay = Instance.new('ScrollingFrame')
    scrollOverlay.BackgroundTransparency = 1
    scrollOverlay.Size = UDim2.new(1, 0, 1, 0)
    scrollOverlay.ScrollBarThickness = 0
    scrollOverlay.CanvasSize = UDim2.new(0, 0, 0, 0)
    local scrollOverlayFrame = Instance.new('Frame', scrollOverlay)
    scrollOverlayFrame.BackgroundTransparency = 1
    scrollOverlayFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollOverlayFrame.MouseWheelForward:Connect(function() newMt:ScrollTo(newMt.Index - wheelIncrement) end)
    scrollOverlayFrame.MouseWheelBackward:Connect(function() newMt:ScrollTo(newMt.Index + wheelIncrement) end)

    local scrollUpEvent, scrollDownEvent

    local function setScrollFrame(self, frame, inc)
      wheelIncrement = inc or self.Increment
      if scrollUpEvent then
        scrollUpEvent:Disconnect()
        scrollUpEvent = nil
      end
      if scrollDownEvent then
        scrollDownEvent:Disconnect()
        scrollDownEvent = nil
      end
      scrollUpEvent = frame.MouseWheelForward:Connect(function() newMt:ScrollTo(newMt.Index - wheelIncrement) end)
      scrollDownEvent = frame.MouseWheelBackward:Connect(function() newMt:ScrollTo(newMt.Index + wheelIncrement) end)
      -- scrollOverlay.Parent = frame
    end
    newMt.SetScrollFrame = setScrollFrame

    newMt.Update = update

    update()
    return newMt
  end
end

local TreeView
do
  TreeView = {}

  local treeMt = {__index = {Length = function(self) return #self.Tree end}}

  function TreeView.new()
    local function createDNodeTemplate()
      local DNodeTemplate = CreateInstance('TextButton', {
        Font = 3;
        FontSize = 5;
        Text = '';
        TextColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
        TextScaled = false;
        TextSize = 14;
        TextStrokeColor3 = Color3.new(0, 0, 0);
        TextStrokeTransparency = 1;
        TextTransparency = 0;
        TextWrapped = false;
        TextXAlignment = 2;
        TextYAlignment = 1;
        AutoButtonColor = false;
        Modal = false;
        Selected = false;
        Style = 0;
        Active = true;
        AnchorPoint = Vector2.new(0, 0);
        BackgroundColor3 = Color3.new(0.37647062540054, 0.54901963472366, 0.82745105028152);
        BackgroundTransparency = 1;
        BorderColor3 = Color3.new(0.33725491166115, 0.49019610881805, 0.73725491762161);
        BorderSizePixel = 1;
        ClipsDescendants = false;
        Draggable = false;
        Position = UDim2.new(0, 1, 0, 2);
        Rotation = 0;
        Selectable = true;
        Size = UDim2.new(1, -18, 0, 18);
        SizeConstraint = 0;
        Visible = true;
        ZIndex = 1;
        Name = 'Entry';
      })
      local DNodeTemplate2 = CreateInstance('Frame', {
        Style = 0;
        Active = false;
        AnchorPoint = Vector2.new(0, 0);
        BackgroundColor3 = Color3.new(0, 0, 0);
        BackgroundTransparency = 1;
        BorderColor3 = Color3.new(0.14509804546833, 0.20784315466881, 0.21176472306252);
        BorderSizePixel = 1;
        ClipsDescendants = false;
        Draggable = false;
        Position = UDim2.new(0, 18, 0, 0);
        Rotation = 0;
        Selectable = false;
        Size = UDim2.new(1, -18, 1, 0);
        SizeConstraint = 0;
        Visible = true;
        ZIndex = 1;
        Name = 'Indent';
        Parent = DNodeTemplate;
      })
      local DNodeTemplate3 = CreateInstance('TextLabel', {
        Font = 3;
        FontSize = 5;
        Text = 'Item';
        TextColor3 = Color3.new(0.86274516582489, 0.86274516582489, 0.86274516582489);
        TextScaled = false;
        TextSize = 14;
        TextStrokeColor3 = Color3.new(0, 0, 0);
        TextStrokeTransparency = 1;
        TextTransparency = 0;
        TextWrapped = false;
        TextXAlignment = 0;
        TextYAlignment = 1;
        Active = false;
        AnchorPoint = Vector2.new(0, 0);
        BackgroundColor3 = Color3.new(1, 1, 1);
        BackgroundTransparency = 1;
        BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
        BorderSizePixel = 1;
        ClipsDescendants = false;
        Draggable = false;
        Position = UDim2.new(0, 22, 0, 0);
        Rotation = 0;
        Selectable = false;
        Size = UDim2.new(1, -22, 0, 18);
        SizeConstraint = 0;
        Visible = true;
        ZIndex = 1;
        Name = 'EntryName';
        Parent = DNodeTemplate2;
      })
      local DNodeTemplate4 = CreateInstance('Frame', {
        Style = 0;
        Active = false;
        AnchorPoint = Vector2.new(0, 0);
        BackgroundColor3 = Color3.new(1, 1, 1);
        BackgroundTransparency = 1;
        BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
        BorderSizePixel = 1;
        ClipsDescendants = true;
        Draggable = false;
        Position = UDim2.new(0, 2, 0.5, -8);
        Rotation = 0;
        Selectable = false;
        Size = UDim2.new(0, 16, 0, 16);
        SizeConstraint = 0;
        Visible = true;
        ZIndex = 1;
        Name = 'IconFrame';
        Parent = DNodeTemplate2;
      })
      local DNodeTemplate5 = CreateInstance('ImageLabel', {
        Image = 'rbxassetid://529659138';
        ImageColor3 = Color3.new(1, 1, 1);
        ImageRectOffset = Vector2.new(0, 0);
        ImageRectSize = Vector2.new(0, 0);
        ImageTransparency = 0;
        ScaleType = 0;
        SliceCenter = Rect.new(0, 0, 0, 0);
        Active = false;
        AnchorPoint = Vector2.new(0, 0);
        BackgroundColor3 = Color3.new(1, 1, 1);
        BackgroundTransparency = 1;
        BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
        BorderSizePixel = 1;
        ClipsDescendants = false;
        Draggable = false;
        Position = UDim2.new(-5.811999797821, 0, -1.3120000362396, 0);
        Rotation = 0;
        Selectable = false;
        Size = UDim2.new(16, 0, 16, 0);
        SizeConstraint = 0;
        Visible = true;
        ZIndex = 1;
        Name = 'Icon';
        Parent = DNodeTemplate4;
      })
      local DNodeTemplate6 = CreateInstance('TextButton', {
        Font = 3;
        FontSize = 5;
        Text = '';
        TextColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
        TextScaled = false;
        TextSize = 14;
        TextStrokeColor3 = Color3.new(0, 0, 0);
        TextStrokeTransparency = 1;
        TextTransparency = 0;
        TextWrapped = false;
        TextXAlignment = 2;
        TextYAlignment = 1;
        AutoButtonColor = true;
        Modal = false;
        Selected = false;
        Style = 0;
        Active = true;
        AnchorPoint = Vector2.new(0, 0);
        BackgroundColor3 = Color3.new(1, 1, 1);
        BackgroundTransparency = 1;
        BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
        BorderSizePixel = 1;
        ClipsDescendants = true;
        Draggable = false;
        Position = UDim2.new(0, -16, 0.5, -8);
        Rotation = 0;
        Selectable = true;
        Size = UDim2.new(0, 16, 0, 16);
        SizeConstraint = 0;
        Visible = true;
        ZIndex = 1;
        Name = 'Expand';
        Parent = DNodeTemplate2;
      })
      local DNodeTemplate7 = CreateInstance('ImageLabel', {
        Image = 'rbxassetid://529659138';
        ImageColor3 = Color3.new(1, 1, 1);
        ImageRectOffset = Vector2.new(0, 0);
        ImageRectSize = Vector2.new(0, 0);
        ImageTransparency = 0;
        ScaleType = 0;
        SliceCenter = Rect.new(0, 0, 0, 0);
        Active = false;
        AnchorPoint = Vector2.new(0, 0);
        BackgroundColor3 = Color3.new(1, 1, 1);
        BackgroundTransparency = 1;
        BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
        BorderSizePixel = 1;
        ClipsDescendants = false;
        Draggable = false;
        Position = UDim2.new(-12.562000274658, 0, -12.562000274658, 0);
        Rotation = 0;
        Selectable = false;
        Size = UDim2.new(16, 0, 16, 0);
        SizeConstraint = 0;
        Visible = true;
        ZIndex = 1;
        Name = 'Icon';
        Parent = DNodeTemplate6;
      })
      return DNodeTemplate
    end
    local dNodeTemplate = createDNodeTemplate()

    local newMt = setmetatable({
      Index = 0;
      Tree = {};
      Expanded = {};
      NodeTemplate = dNodeTemplate;
      DisplayFrame = nil;
      Entries = {};
      Height = 18;
      OffX = 1;
      OffY = 1;
    }, treeMt)

    local function refresh(self)
      if not self.DisplayFrame then
        warn('Tree: No Display Frame')
        return
      end

      if self.PreUpdate then self:PreUpdate() end

      local displayFrame = self.DisplayFrame
      local entrySpace = math.ceil(displayFrame.AbsoluteSize.Y / (self.Height + 1))

      for i = 1, entrySpace do
        local node = self.Tree[i + self.Index]
        if node then
          local entry = self.Entries[i]
          if not entry then
            entry = self.NodeTemplate:Clone()
            entry.Position = UDim2.new(0, self.OffX, 0, self.OffY + (self.Height + 1) * #displayFrame:GetChildren())
            entry.Parent = displayFrame
            self.Entries[i] = entry
            if self.NodeCreate then self:NodeCreate(entry, i) end
          end
          entry.Visible = true
          if self.NodeDraw then self:NodeDraw(entry, node) end
        else
          local entry = self.Entries[i]
          if entry then entry.Visible = false end
        end
      end

      for i = entrySpace + 1, #self.Entries do
        if self.Entries[i] then
          self.Entries[i]:Destroy()
          self.Entries[i] = nil
        end
      end

      if self.OnUpdate then self:OnUpdate() end
      if self.RefreshNeeded then
        self.RefreshNeeded = false
        self:Refresh()
      end
    end
    newMt.Refresh = refresh

    local function expand(self, item)
      self.Expanded[item] = not self.Expanded[item]
      if self.TreeUpdate then self:TreeUpdate() end
      self:Refresh()
    end
    newMt.Expand = expand

    local Selection
    do
      Selection = {List = {}; Selected = {}}

      function Selection:Add(obj)
        if Selection.Selected[obj] then return end

        Selection.Selected[obj] = true
        table.insert(Selection.List, obj)
      end

      function Selection:Set(objs)
        for i, v in pairs(Selection.List) do Selection.Selected[v] = nil end
        Selection.List = {}

        for i, v in pairs(objs) do
          if not Selection.Selected[v] then
            Selection.Selected[v] = true
            table.insert(Selection.List, v)
          end
        end
      end

      function Selection:Remove(obj)
        if not Selection.Selected[obj] then return end

        Selection.Selected[obj] = false
        for i, v in pairs(Selection.List) do
          if v == obj then
            table.remove(Selection.List, i)
            break
          end
        end
      end
    end
    newMt.Selection = Selection

    return newMt
  end
end

local ContextMenu
do
  ContextMenu = {}

  local function createContextEntry()
    local ContextEntry = CreateInstance('TextButton', {
      Font = 3;
      FontSize = 5;
      Text = '';
      TextColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
      TextScaled = false;
      TextSize = 14;
      TextStrokeColor3 = Color3.new(0, 0, 0);
      TextStrokeTransparency = 1;
      TextTransparency = 0;
      TextWrapped = false;
      TextXAlignment = 2;
      TextYAlignment = 1;
      AutoButtonColor = false;
      Modal = false;
      Selected = false;
      Style = 0;
      Active = true;
      AnchorPoint = Vector2.new(0, 0);
      BackgroundColor3 = Color3.new(0.37647062540054, 0.54901963472366, 0.82745105028152);
      BackgroundTransparency = 1;
      BorderColor3 = Color3.new(0.33725491166115, 0.49019610881805, 0.73725491762161);
      BorderSizePixel = 0;
      ClipsDescendants = false;
      Draggable = false;
      Position = UDim2.new(0, 0, 0, 2);
      Rotation = 0;
      Selectable = true;
      Size = UDim2.new(1, 0, 0, 20);
      SizeConstraint = 0;
      Visible = true;
      ZIndex = 1;
      Name = 'Entry';
    })
    local ContextEntry2 = CreateInstance('Frame', {
      Style = 0;
      Active = false;
      AnchorPoint = Vector2.new(0, 0);
      BackgroundColor3 = Color3.new(1, 1, 1);
      BackgroundTransparency = 1;
      BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
      BorderSizePixel = 1;
      ClipsDescendants = true;
      Draggable = false;
      Position = UDim2.new(0, 2, 0.5, -8);
      Rotation = 0;
      Selectable = false;
      Size = UDim2.new(0, 16, 0, 16);
      SizeConstraint = 0;
      Visible = true;
      ZIndex = 1;
      Name = 'IconFrame';
      Parent = ContextEntry;
    })
    local ContextEntry3 = CreateInstance('ImageLabel', {
      Image = 'rbxassetid://529659138';
      ImageColor3 = Color3.new(1, 1, 1);
      ImageRectOffset = Vector2.new(0, 0);
      ImageRectSize = Vector2.new(0, 0);
      ImageTransparency = 0;
      ScaleType = 0;
      SliceCenter = Rect.new(0, 0, 0, 0);
      Active = false;
      AnchorPoint = Vector2.new(0, 0);
      BackgroundColor3 = Color3.new(1, 1, 1);
      BackgroundTransparency = 1;
      BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
      BorderSizePixel = 1;
      ClipsDescendants = false;
      Draggable = false;
      Position = UDim2.new(0, 0, 0, 0);
      Rotation = 0;
      Selectable = false;
      Size = UDim2.new(0, 16, 0, 16);
      SizeConstraint = 0;
      Visible = true;
      ZIndex = 1;
      Name = 'Icon';
      Parent = ContextEntry2;
    })
    local ContextEntry4 = CreateInstance('TextLabel', {
      Font = 3;
      FontSize = 5;
      Text = 'Item';
      TextColor3 = Color3.new(0.86274516582489, 0.86274516582489, 0.86274516582489);
      TextScaled = false;
      TextSize = 14;
      TextStrokeColor3 = Color3.new(0, 0, 0);
      TextStrokeTransparency = 1;
      TextTransparency = 0;
      TextWrapped = false;
      TextXAlignment = 0;
      TextYAlignment = 1;
      Active = false;
      AnchorPoint = Vector2.new(0, 0);
      BackgroundColor3 = Color3.new(1, 1, 1);
      BackgroundTransparency = 1;
      BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
      BorderSizePixel = 1;
      ClipsDescendants = false;
      Draggable = false;
      Position = UDim2.new(0, 24, 0, 0);
      Rotation = 0;
      Selectable = false;
      Size = UDim2.new(1, -24, 0, 20);
      SizeConstraint = 0;
      Visible = true;
      ZIndex = 1;
      Name = 'EntryName';
      Parent = ContextEntry;
    })
    local ContextEntry5 = CreateInstance('TextLabel', {
      Font = 3;
      FontSize = 5;
      Text = 'Ctrl+C';
      TextColor3 = Color3.new(0.86274516582489, 0.86274516582489, 0.86274516582489);
      TextScaled = false;
      TextSize = 14;
      TextStrokeColor3 = Color3.new(0, 0, 0);
      TextStrokeTransparency = 1;
      TextTransparency = 0;
      TextWrapped = false;
      TextXAlignment = 1;
      TextYAlignment = 1;
      Active = false;
      AnchorPoint = Vector2.new(0, 0);
      BackgroundColor3 = Color3.new(1, 1, 1);
      BackgroundTransparency = 1;
      BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
      BorderSizePixel = 1;
      ClipsDescendants = false;
      Draggable = false;
      Position = UDim2.new(0, 24, 0, 0);
      Rotation = 0;
      Selectable = false;
      Size = UDim2.new(1, -30, 0, 20);
      SizeConstraint = 0;
      Visible = true;
      ZIndex = 1;
      Name = 'Shortcut';
      Parent = ContextEntry;
    })
    return ContextEntry
  end

  local function createContextDivider()
    local ContextDivider = CreateInstance('Frame', {
      Style = 0;
      Active = false;
      AnchorPoint = Vector2.new(0, 0);
      BackgroundColor3 = Color3.new(0.18823531270027, 0.18823531270027, 0.18823531270027);
      BackgroundTransparency = 1;
      BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
      BorderSizePixel = 0;
      ClipsDescendants = false;
      Draggable = false;
      Position = UDim2.new(0, 0, 0, 20);
      Rotation = 0;
      Selectable = false;
      Size = UDim2.new(1, 0, 0, 12);
      SizeConstraint = 0;
      Visible = true;
      ZIndex = 1;
      Name = 'Divider';
    })
    local ContextDivider2 = CreateInstance('Frame', {
      Style = 0;
      Active = false;
      AnchorPoint = Vector2.new(0, 0);
      BackgroundColor3 = Color3.new(0.43921571969986, 0.43921571969986, 0.43921571969986);
      BackgroundTransparency = 0;
      BorderColor3 = Color3.new(0.10588236153126, 0.16470588743687, 0.20784315466881);
      BorderSizePixel = 0;
      ClipsDescendants = false;
      Draggable = false;
      Position = UDim2.new(0, 2, 0, 5);
      Rotation = 0;
      Selectable = false;
      Size = UDim2.new(1, -4, 0, 1);
      SizeConstraint = 0;
      Visible = true;
      ZIndex = 1;
      Name = 'Line';
      Parent = ContextDivider;
    })
    return ContextDivider
  end

  local contextFrame = CreateInstance('ScrollingFrame', {
    BottomImage = 'rbxasset://textures/ui/Scroll/scroll-bottom.png';
    CanvasPosition = Vector2.new(0, 0);
    CanvasSize = UDim2.new(0, 0, 2, 0);
    MidImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
    ScrollBarThickness = 0;
    ScrollingEnabled = true;
    TopImage = 'rbxasset://textures/ui/Scroll/scroll-top.png';
    Active = false;
    AnchorPoint = Vector2.new(0, 0);
    BackgroundColor3 = Color3.new(0.3137255012989, 0.3137255012989, 0.3137255012989);
    BackgroundTransparency = 0;
    BorderColor3 = Color3.new(0.43921571969986, 0.43921571969986, 0.43921571969986);
    BorderSizePixel = 1;
    ClipsDescendants = true;
    Draggable = false;
    Position = UDim2.new(0, 0, 0, 0);
    Rotation = 0;
    Selectable = true;
    Size = UDim2.new(0, 200, 0, 100);
    SizeConstraint = 0;
    Visible = true;
    ZIndex = 1;
    Name = 'ContextFrame';
  })
  local contextEntry = createContextEntry()
  local contextDivider = createContextDivider()

  function ContextMenu.new()
    local newMt = setmetatable({Width = 200; Height = 20; Items = {}; Frame = contextFrame:Clone()}, {})

    local mainFrame = newMt.Frame
    local entryFrame = contextEntry:Clone()
    local dividerFrame = contextDivider:Clone()

    mainFrame.ScrollingEnabled = false

    local function add(self, item)
      local newItem = {
        Name = item.Name or 'Item';
        Icon = item.Icon or '';
        Shortcut = item.Shortcut or '';
        OnClick = item.OnClick;
        OnHover = item.OnHover;
        Disabled = item.Disabled or false;
        DisabledIcon = item.DisabledIcon or '';
      }
      table.insert(self.Items, newItem)
    end
    newMt.Add = add

    local function addDivider(self) table.insert(self.Items, 'Divider') end
    newMt.AddDivider = addDivider

    local function clear(self) self.Items = {} end
    newMt.Clear = clear

    local function refresh(self)
      mainFrame:ClearAllChildren()

      local currentPos = 2
      for _, item in pairs(self.Items) do
        if item == 'Divider' then
          local newDivider = dividerFrame:Clone()
          newDivider.Position = UDim2.new(0, 0, 0, currentPos)
          newDivider.Parent = mainFrame
          currentPos = currentPos + 12
        else
          local newEntry = entryFrame:Clone()
          newEntry.Position = UDim2.new(0, 0, 0, currentPos)
          newEntry.EntryName.Text = item.Name
          newEntry.Shortcut.Text = item.Shortcut
          if item.Disabled then
            newEntry.EntryName.TextColor3 = Color3.new(150 / 255, 150 / 255, 150 / 255)
            newEntry.Shortcut.TextColor3 = Color3.new(150 / 255, 150 / 255, 150 / 255)
          end

          local useIcon = item.Disabled and item.DisabledIcon or item.Icon
          if type(useIcon) == 'string' then
            newEntry.IconFrame.Icon.Image = useIcon
          else
            newEntry.IconFrame:Destroy()
            local newIcon = useIcon:Clone()
            newIcon.Position = UDim2.new(0, 2, 0.5, -8)
            newIcon.Parent = newEntry
          end

          if item.OnClick and not item.Disabled then newEntry.MouseButton1Click:Connect(item.OnClick) end

          newEntry.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then newEntry.BackgroundTransparency = 0.5 end
          end)

          newEntry.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then newEntry.BackgroundTransparency = 1 end
          end)

          newEntry.Parent = mainFrame
          currentPos = currentPos + self.Height
        end
      end

      mainFrame.Size = UDim2.new(0, self.Width, 0, currentPos + 2)
    end
    newMt.Refresh = refresh

    local function show(self, displayFrame, x, y)
      local toSize = mainFrame.Size.Y.Offset
      local reverseY = false

      local maxX, maxY = gui.AbsoluteSize.X, gui.AbsoluteSize.Y

      if x + self.Width > maxX then x = x - self.Width end
      if y + toSize > maxY then reverseY = true end

      mainFrame.Position = UDim2.new(0, x, 0, y)
      mainFrame.Size = UDim2.new(0, self.Width, 0, 0)
      mainFrame.Parent = displayFrame

      local closeEvent = Services.UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        if not f.checkMouseInGui(mainFrame) then self:Hide() end
      end)

      if reverseY then
        if y - toSize < 0 then y = toSize end
        mainFrame:TweenSizeAndPosition(UDim2.new(0, self.Width, 0, toSize), UDim2.new(0, x, 0, y - toSize),
                                       Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
      else
        mainFrame:TweenSize(UDim2.new(0, self.Width, 0, toSize), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
      end
    end
    newMt.Show = show

    local function hide(self) mainFrame.Parent = nil end
    newMt.Hide = hide

    return newMt
  end
end

-- Explorer
local workspaces = {['Default'] = {Data = {'Default'}; IsDefault = true}}
local nodes = {}

local explorerPanel
local propertiesPanel

local entryTemplate = resources:WaitForChild('Entry')

local iconMap = 'rbxassetid://765660635'
local iconIndex = {
  -- Core
  NodeCollapsed = 165;
  NodeExpanded = 166;
  NodeCollapsedOver = 179;
  NodeExpandedOver = 180;

  -- Buttons
  CUT_ICON = 174;
  COPY_ICON = 175;
  PASTE_ICON = 176;
  DELETE_ICON = 177;
  GROUP_ICON = 150;
  UNGROUP_ICON = 151;
  SELECTCHILDREN_ICON = 152;

  CUT_D_ICON = 160;
  COPY_D_ICON = 161;
  PASTE_D_ICON = 162;
  DELETE_D_ICON = 163;
  GROUP_D_ICON = 136;
  UNGROUP_D_ICON = 137;
  SELECTCHILDREN_D_ICON = 138;

  -- Classes
  ['Accessory'] = 32;
  ['Accoutrement'] = 32;
  ['AdvancedDragger'] = 41;
  ['AdService'] = 73;
  ['AlignOrientation'] = 110;
  ['AlignPosition'] = 111;
  ['Animation'] = 60;
  ['AnimationController'] = 60;
  ['AnimationTrack'] = 60;
  ['Animator'] = 60;
  ['ArcHandles'] = 56;
  ['AssetService'] = 72;
  ['Attachment'] = 92;
  ['Backpack'] = 20;
  ['BadgeService'] = 75;
  ['BallSocketConstraint'] = 97;
  ['BillboardGui'] = 64;
  ['BinaryStringValue'] = 4;
  ['BindableEvent'] = 67;
  ['BindableFunction'] = 66;
  ['BlockMesh'] = 8;
  ['BloomEffect'] = 90;
  ['BlurEffect'] = 90;
  ['BodyAngularVelocity'] = 14;
  ['BodyForce'] = 14;
  ['BodyGyro'] = 14;
  ['BodyPosition'] = 14;
  ['BodyThrust'] = 14;
  ['BodyVelocity'] = 14;
  ['BoolValue'] = 4;
  ['BoxHandleAdornment'] = 54;
  ['BrickColorValue'] = 4;
  ['Camera'] = 5;
  ['CFrameValue'] = 4;
  ['ChangeHistoryService'] = 118;
  ['CharacterMesh'] = 60;
  ['Chat'] = 33;
  ['ClickDetector'] = 41;
  ['CollectionService'] = 30;
  ['Color3Value'] = 4;
  ['ColorCorrectionEffect'] = 90;
  ['ConeHandleAdornment'] = 54;
  ['Configuration'] = 58;
  ['ContentProvider'] = 72;
  ['ContextActionService'] = 41;
  ['ControllerService'] = 84;
  ['CookiesService'] = 119;
  ['CoreGui'] = 46;
  ['CoreScript'] = 91;
  ['CornerWedgePart'] = 1;
  ['CustomEvent'] = 4;
  ['CustomEventReceiver'] = 4;
  ['CylinderHandleAdornment'] = 54;
  ['CylinderMesh'] = 8;
  ['CylindricalConstraint'] = 89;
  ['Debris'] = 30;
  ['Decal'] = 7;
  ['Dialog'] = 62;
  ['DialogChoice'] = 63;
  ['DoubleConstrainedValue'] = 4;
  ['Explosion'] = 36;
  ['FileMesh'] = 8;
  ['Fire'] = 61;
  ['Flag'] = 38;
  ['FlagStand'] = 39;
  ['FloorWire'] = 4;
  ['Folder'] = 70;
  ['ForceField'] = 37;
  ['Frame'] = 48;
  ['FriendService'] = 121;
  ['GamepadService'] = 84;
  ['GamePassService'] = 19;
  ['Geometry'] = 120;
  ['Glue'] = 34;
  ['GuiButton'] = 52;
  ['GuiMain'] = 47;
  ['GuiService'] = 47;
  ['Handles'] = 53;
  ['HapticService'] = 84;
  ['Hat'] = 45;
  ['HingeConstraint'] = 89;
  ['Hint'] = 33;
  ['HopperBin'] = 22;
  ['HttpRbxApiService'] = 76;
  ['HttpService'] = 76;
  ['Humanoid'] = 9;
  ['HumanoidController'] = 9;
  ['ImageButton'] = 52;
  ['ImageLabel'] = 49;
  ['InsertService'] = 72;
  ['IntConstrainedValue'] = 4;
  ['IntValue'] = 4;
  ['JointInstance'] = 34;
  ['JointsService'] = 34;
  ['Keyframe'] = 60;
  ['KeyframeSequence'] = 60;
  ['KeyframeSequenceProvider'] = 60;
  ['Lighting'] = 13;
  ['LineForce'] = 112;
  ['LineHandleAdornment'] = 54;
  ['LocalScript'] = 18;
  ['LogService'] = 87;
  ['LuaWebService'] = 91;
  ['MarketplaceService'] = 106;
  ['MeshContentProvider'] = 8;
  ['MeshPart'] = 77;
  ['Message'] = 33;
  ['Model'] = 2;
  ['ModuleScript'] = 71;
  ['Motor'] = 34;
  ['Motor6D'] = 34;
  ['MoveToConstraint'] = 89;
  ['NegateOperation'] = 78;
  ['NetworkClient'] = 16;
  ['NetworkReplicator'] = 29;
  ['NetworkServer'] = 15;
  ['NotificationService'] = 117;
  ['NumberValue'] = 4;
  ['ObjectValue'] = 4;
  ['Pants'] = 44;
  ['ParallelRampPart'] = 1;
  ['Part'] = 1;
  ['ParticleEmitter'] = 69;
  ['PartPairLasso'] = 57;
  ['PathfindingService'] = 37;
  ['PersonalServerService'] = 121;
  ['PhysicsService'] = 30;
  ['Platform'] = 35;
  ['Player'] = 12;
  ['PlayerGui'] = 46;
  ['Players'] = 21;
  ['PlayerScripts'] = 82;
  ['PointLight'] = 13;
  ['PointsService'] = 83;
  ['Pose'] = 60;
  ['PrismaticConstraint'] = 89;
  ['PrismPart'] = 1;
  ['PyramidPart'] = 1;
  ['RayValue'] = 4;
  ['ReflectionMetadata'] = 86;
  ['ReflectionMetadataCallbacks'] = 86;
  ['ReflectionMetadataClass'] = 86;
  ['ReflectionMetadataClasses'] = 86;
  ['ReflectionMetadataEnum'] = 86;
  ['ReflectionMetadataEnumItem'] = 86;
  ['ReflectionMetadataEnums'] = 86;
  ['ReflectionMetadataEvents'] = 86;
  ['ReflectionMetadataFunctions'] = 86;
  ['ReflectionMetadataMember'] = 86;
  ['ReflectionMetadataProperties'] = 86;
  ['ReflectionMetadataYieldFunctions'] = 86;
  ['RemoteEvent'] = 80;
  ['RemoteFunction'] = 79;
  ['RenderHooksService'] = 122;
  ['ReplicatedFirst'] = 72;
  ['ReplicatedStorage'] = 72;
  ['RightAngleRampPart'] = 1;
  ['RocketPropulsion'] = 14;
  ['RodConstraint'] = 89;
  ['RopeConstraint'] = 89;
  ['Rotate'] = 34;
  ['RotateP'] = 34;
  ['RotateV'] = 34;
  ['RunService'] = 124;
  ['RuntimeScriptService'] = 91;
  ['ScreenGui'] = 47;
  ['Script'] = 6;
  ['ScriptContext'] = 82;
  ['ScriptService'] = 91;
  ['ScrollingFrame'] = 48;
  ['Seat'] = 35;
  ['Selection'] = 55;
  ['SelectionBox'] = 54;
  ['SelectionPartLasso'] = 57;
  ['SelectionPointLasso'] = 57;
  ['SelectionSphere'] = 54;
  ['ServerScriptService'] = 115;
  ['ServerStorage'] = 74;
  ['Shirt'] = 43;
  ['ShirtGraphic'] = 40;
  ['SkateboardPlatform'] = 35;
  ['Sky'] = 28;
  ['SlidingBallConstraint'] = 89;
  ['Smoke'] = 59;
  ['Snap'] = 34;
  ['SolidModelContentProvider'] = 77;
  ['Sound'] = 11;
  ['SoundGroup'] = 93;
  ['SoundService'] = 31;
  ['Sparkles'] = 42;
  ['SpawnLocation'] = 25;
  ['SpecialMesh'] = 8;
  ['SphereHandleAdornment'] = 54;
  ['SpotLight'] = 13;
  ['SpringConstraint'] = 89;
  ['StarterCharacterScripts'] = 82;
  ['StarterGear'] = 20;
  ['StarterGui'] = 46;
  ['StarterPack'] = 20;
  ['StarterPlayer'] = 88;
  ['StarterPlayerScripts'] = 82;
  ['Status'] = 2;
  ['StringValue'] = 4;
  ['SunRaysEffect'] = 90;
  ['SurfaceGui'] = 64;
  ['SurfaceLight'] = 13;
  ['SurfaceSelection'] = 55;
  ['Team'] = 24;
  ['Teams'] = 23;
  ['TeleportService'] = 81;
  ['Terrain'] = 65;
  ['TerrainRegion'] = 65;
  ['TestService'] = 68;
  ['TextBox'] = 51;
  ['TextButton'] = 51;
  ['TextLabel'] = 50;
  ['TextService'] = 50;
  ['Texture'] = 10;
  ['TextureTrail'] = 4;
  ['TimerService'] = 118;
  ['Tool'] = 17;
  ['Torque'] = 113;
  ['TouchInputService'] = 84;
  ['TouchTransmitter'] = 37;
  ['TrussPart'] = 1;
  ['TweenService'] = 109;
  ['UnionOperation'] = 77;
  ['UserInputService'] = 84;
  ['Vector3Value'] = 4;
  ['VehicleSeat'] = 35;
  ['VelocityMotor'] = 34;
  ['Visit'] = 123;
  ['VRService'] = 95;
  ['WedgePart'] = 1;
  ['Weld'] = 34;
  ['Workspace'] = 19;
  [''] = 116;
}

entryTemplate.Indent.IconFrame.Icon.Image = iconMap

-- Properties
local propCategories = {
  ['Instance'] = {
    ['Archivable'] = 'Behavior';
    ['ClassName'] = 'Data';
    ['DataCost'] = 'Data';
    ['Name'] = 'Data';
    ['Parent'] = 'Data';
    ['RobloxLocked'] = 'Data';
  };
  ['BasePart'] = {
    ['Anchored'] = 'Behavior';
    ['BackParamA'] = 'Surface Inputs';
    ['BackParamB'] = 'Surface Inputs';
    ['BackSurface'] = 'Surface';
    ['BackSurfaceInput'] = 'Surface Inputs';
    ['BottomParamA'] = 'Surface Inputs';
    ['BottomParamB'] = 'Surface Inputs';
    ['BottomSurface'] = 'Surface';
    ['BottomSurfaceInput'] = 'Surface Inputs';
    ['BrickColor'] = 'Appearance';
    ['CFrame'] = 'Data';
    ['CanCollide'] = 'Behavior';
    ['CollisionGroupId'] = 'Data';
    ['CustomPhysicalProperties'] = 'Part';
    ['DraggingV1'] = 'Behavior';
    ['Elasticity'] = 'Part';
    ['Friction'] = 'Part';
    ['FrontParamA'] = 'Surface Inputs';
    ['FrontParamB'] = 'Surface Inputs';
    ['FrontSurface'] = 'Surface';
    ['FrontSurfaceInput'] = 'Surface Inputs';
    ['LeftParamA'] = 'Surface Inputs';
    ['LeftParamB'] = 'Surface Inputs';
    ['LeftSurface'] = 'Surface';
    ['LeftSurfaceInput'] = 'Surface Inputs';
    ['LocalTransparencyModifier'] = 'Data';
    ['Locked'] = 'Behavior';
    ['Material'] = 'Appearance';
    ['NetworkIsSleeping'] = 'Data';
    ['NetworkOwnerV3'] = 'Data';
    ['NetworkOwnershipRule'] = 'Behavior';
    ['NetworkOwnershipRuleBool'] = 'Behavior';
    ['Position'] = 'Data';
    ['ReceiveAge'] = 'Part';
    ['Reflectance'] = 'Appearance';
    ['ResizeIncrement'] = 'Behavior';
    ['ResizeableFaces'] = 'Behavior';
    ['RightParamA'] = 'Surface Inputs';
    ['RightParamB'] = 'Surface Inputs';
    ['RightSurface'] = 'Surface';
    ['RightSurfaceInput'] = 'Surface Inputs';
    ['RotVelocity'] = 'Data';
    ['Rotation'] = 'Data';
    ['Size'] = 'Part';
    ['TopParamA'] = 'Surface Inputs';
    ['TopParamB'] = 'Surface Inputs';
    ['TopSurface'] = 'Surface';
    ['TopSurfaceInput'] = 'Surface Inputs';
    ['Transparency'] = 'Appearance';
    ['Velocity'] = 'Data';
  };
  ['Part'] = {['Shape'] = 'Part'};
  ['Message'] = {['Text'] = 'Appearance'};
  ['Camera'] = {
    ['CFrame'] = 'Data';
    ['CameraSubject'] = 'Camera';
    ['CameraType'] = 'Camera';
    ['FieldOfView'] = 'Data';
    ['Focus'] = 'Data';
    ['HeadLocked'] = 'Data';
    ['HeadScale'] = 'Data';
    ['ViewportSize'] = 'Data';
  };
  ['Animation'] = {['AnimationId'] = 'Data'; ['Loop'] = 'Data'; ['Priority'] = 'Data'};
  ['PVAdornment'] = {['Adornee'] = 'Data'};
  ['PartAdornment'] = {['Adornee'] = 'Data'};
  ['Decal'] = {
    ['Color3'] = 'Appearance';
    ['LocalTransparencyModifier'] = 'Appearance';
    ['Shiny'] = 'Appearance';
    ['Specular'] = 'Appearance';
    ['Texture'] = 'Appearance';
    ['Transparency'] = 'Appearance';
  };
  ['Texture'] = {['StudsPerTileU'] = 'Appearance'; ['StudsPerTileV'] = 'Appearance'};
  ['Feature'] = {['FaceId'] = 'Data'; ['InOut'] = 'Data'; ['LeftRight'] = 'Data'; ['TopBottom'] = 'Data'};
  ['VelocityMotor'] = {['CurrentAngle'] = 'Data'; ['DesiredAngle'] = 'Data'; ['Hole'] = 'Data'; ['MaxVelocity'] = 'Data'};
  ['JointInstance'] = {['C0'] = 'Data'; ['C1'] = 'Data'; ['Part0'] = 'Data'; ['Part1'] = 'Data'};
  ['DynamicRotate'] = {['BaseAngle'] = 'Data'};
  ['Motor'] = {['CurrentAngle'] = 'Data'; ['DesiredAngle'] = 'Data'; ['MaxVelocity'] = 'Data'};
  ['Glue'] = {['F0'] = 'Data'; ['F1'] = 'Data'; ['F2'] = 'Data'; ['F3'] = 'Data'};
  ['ManualSurfaceJointInstance'] = {['Surface0'] = 'Data'; ['Surface1'] = 'Data'};
  ['Explosion'] = {
    ['BlastPressure'] = 'Data';
    ['BlastRadius'] = 'Data';
    ['DestroyJointRadiusPercent'] = 'Data';
    ['ExplosionType'] = 'Data';
    ['Position'] = 'Data';
    ['Visible'] = 'Data';
  };
  ['Sparkles'] = {['Enabled'] = 'Data'; ['SparkleColor'] = 'Data'};
  ['Fire'] = {['Color'] = 'Data'; ['Enabled'] = 'Data'; ['Heat'] = 'Data'; ['SecondaryColor'] = 'Data'; ['Size'] = 'Data'};
  ['Smoke'] = {['Color'] = 'Data'; ['Enabled'] = 'Data'; ['Opacity'] = 'Data'; ['RiseVelocity'] = 'Data'; ['Size'] = 'Data'};
  ['ParticleEmitter'] = {
    ['Acceleration'] = 'Motion';
    ['Color'] = 'Appearance';
    ['Drag'] = 'Particles';
    ['EmissionDirection'] = 'Emission';
    ['Enabled'] = 'Emission';
    ['Lifetime'] = 'Emission';
    ['LightEmission'] = 'Appearance';
    ['LockedToPart'] = 'Particles';
    ['Rate'] = 'Emission';
    ['RotSpeed'] = 'Emission';
    ['Rotation'] = 'Emission';
    ['Size'] = 'Appearance';
    ['Speed'] = 'Emission';
    ['Texture'] = 'Appearance';
    ['Transparency'] = 'Appearance';
    ['VelocityInheritance'] = 'Particles';
    ['VelocitySpread'] = 'Emission';
    ['ZOffset'] = 'Appearance';
  };
  ['Sky'] = {
    ['CelestialBodiesShown'] = 'Appearance';
    ['SkyboxBk'] = 'Appearance';
    ['SkyboxDn'] = 'Appearance';
    ['SkyboxFt'] = 'Appearance';
    ['SkyboxLf'] = 'Appearance';
    ['SkyboxRt'] = 'Appearance';
    ['SkyboxUp'] = 'Appearance';
    ['StarCount'] = 'Appearance';
  };
  ['Stats'] = {['MinReportInterval'] = 'Reporting'; ['ReporterType'] = 'Reporting'};
  ['StarterPlayer'] = {
    ['AutoJumpEnabled'] = 'Mobile';
    ['CameraMaxZoomDistance'] = 'Camera';
    ['CameraMinZoomDistance'] = 'Camera';
    ['CameraMode'] = 'Camera';
    ['DevCameraOcclusionMode'] = 'Camera';
    ['DevComputerCameraMovementMode'] = 'Camera';
    ['DevComputerMovementMode'] = 'Controls';
    ['DevTouchCameraMovementMode'] = 'Camera';
    ['DevTouchMovementMode'] = 'Controls';
    ['EnableMouseLockOption'] = 'Controls';
    ['HealthDisplayDistance'] = 'Data';
    ['LoadCharacterAppearance'] = 'Character';
    ['NameDisplayDistance'] = 'Data';
    ['ScreenOrientation'] = 'Mobile';
  };
  ['Lighting'] = {
    ['Ambient'] = 'Appearance';
    ['Brightness'] = 'Appearance';
    ['ColorShift_Bottom'] = 'Appearance';
    ['ColorShift_Top'] = 'Appearance';
    ['FogColor'] = 'Fog';
    ['FogEnd'] = 'Fog';
    ['FogStart'] = 'Fog';
    ['GeographicLatitude'] = 'Data';
    ['GlobalShadows'] = 'Appearance';
    ['OutdoorAmbient'] = 'Appearance';
    ['Outlines'] = 'Appearance';
    ['TimeOfDay'] = 'Data';
  };
  ['LocalizationService'] = {['LocaleId'] = 'Behavior'; ['PreferredLanguage'] = 'Behavior'};
  ['Light'] = {
    ['Brightness'] = 'Appearance';
    ['Color'] = 'Appearance';
    ['Enabled'] = 'Appearance';
    ['Shadows'] = 'Appearance';
  };
  ['PointLight'] = {['Range'] = 'Appearance'};
  ['SpotLight'] = {['Angle'] = 'Appearance'; ['Face'] = 'Appearance'; ['Range'] = 'Appearance'};
  ['SurfaceLight'] = {['Angle'] = 'Appearance'; ['Face'] = 'Appearance'; ['Range'] = 'Appearance'};
  ['TrussPart'] = {['Style'] = 'Part'};
  ['Attachment'] = {
    ['Axis'] = 'Derived Data';
    ['CFrame'] = 'Data';
    ['Position'] = 'Data';
    ['Rotation'] = 'Data';
    ['SecondaryAxis'] = 'Derived Data';
    ['Visible'] = 'Appearance';
    ['WorldAxis'] = 'Derived Data';
    ['WorldPosition'] = 'Derived Data';
    ['WorldRotation'] = 'Derived Data';
    ['WorldSecondaryAxis'] = 'Derived Data';
  };
  ['Humanoid'] = {
    ['AutoJumpEnabled'] = 'Control';
    ['AutoRotate'] = 'Control';
    ['CameraMaxDistance'] = 'Data';
    ['CameraMinDistance'] = 'Data';
    ['CameraMode'] = 'Data';
    ['CameraOffset'] = 'Data';
    ['DisplayDistanceType'] = 'Data';
    ['Health'] = 'Game';
    ['HealthDisplayDistance'] = 'Data';
    ['Health_XML'] = 'Game';
    ['HipHeight'] = 'Game';
    ['Jump'] = 'Control';
    ['JumpPower'] = 'Game';
    ['JumpReplicate'] = 'Control';
    ['LeftLeg'] = 'Data';
    ['MaxHealth'] = 'Game';
    ['MaxSlopeAngle'] = 'Game';
    ['MoveDirection'] = 'Control';
    ['MoveDirectionInternal'] = 'Control';
    ['NameDisplayDistance'] = 'Data';
    ['NameOcclusion'] = 'Data';
    ['PlatformStand'] = 'Control';
    ['RigType'] = 'Data';
    ['RightLeg'] = 'Data';
    ['SeatPart'] = 'Control';
    ['Sit'] = 'Control';
    ['Strafe'] = 'Control';
    ['TargetPoint'] = 'Control';
    ['Torso'] = 'Data';
    ['WalkAngleError'] = 'Control';
    ['WalkDirection'] = 'Control';
    ['WalkSpeed'] = 'Game';
    ['WalkToPart'] = 'Control';
    ['WalkToPoint'] = 'Control';
  };
}

local categoryOrder = {
  ['Appearance'] = 1;
  ['Data'] = 2;
  ['Goals'] = 3;
  ['Thrust'] = 4;
  ['Turn'] = 5;
  ['Camera'] = 6;
  ['Behavior'] = 7;
  ['Compliance'] = 8;
  ['AlignOrientation'] = 9;
  ['AlignPosition'] = 10;
  ['Derived'] = 11;
  ['LineForce'] = 12;
  ['Rod'] = 13;
  ['Constraint'] = 14;
  ['Spring'] = 15;
  ['Torque'] = 16;
  ['VectorForce'] = 17;
  ['Attachments'] = 18;
  ['Axes'] = 19;
  ['Image'] = 20;
  ['Text'] = 21;
  ['Scrolling'] = 22;
  ['State'] = 23;
  ['Control'] = 24;
  ['Game'] = 25;
  ['Fog'] = 26;
  ['Settings'] = 27;
  ['Physics'] = 28;
  ['Teams'] = 29;
  ['Forcefield'] = 30;
  ['Part'] = 31;
  ['Surface Inputs'] = 32;
  ['Surface'] = 33;
  ['Motion'] = 34;
  ['Particles'] = 35;
  ['Emission'] = 36;
  ['Reflection'] = 37;
  ['Mobile'] = 38;
  ['Controls'] = 39;
  ['Character'] = 40;
  ['Results'] = 41;
  ['Other'] = 42;
}

-- Gui Functions
local function getResource(name) return resources:WaitForChild(name):Clone() end

function f.prevProportions(t, ind)
  local count = 0
  for i = ind, 1, -1 do count = count + t[i].Proportion end
  return count
end

function f.buildPanes()
  -- print("\n-----\n")
  -- for i,v in pairs(RPaneItems) do print(v.Window) end
  -- print("\n-----")

  for i, v in pairs(RPaneItems) do
    v.Window:TweenSizeAndPosition(UDim2.new(0, explorerSettings.RPaneWidth, v.Proportion, 0),
                                  UDim2.new(0, 0, f.prevProportions(RPaneItems, i - 1), 0), Enum.EasingDirection.Out,
                                  Enum.EasingStyle.Quart, 0.5, true)
    -- v.Window.Position = UDim2.new(0,0,prevProportions(RPaneItems,i-1),0)
    -- v.Window.Size = UDim2.new(0,explorerSettings.RPaneWidth,v.Proportion,0)
  end
end

function f.distance(x1, y1, x2, y2) return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) end

function f.checkMouseInGui(gui)
  if gui == nil then return false end
  local guiPosition = gui.AbsolutePosition
  local guiSize = gui.AbsoluteSize

  if mouse.X >= guiPosition.x and mouse.X <= guiPosition.x + guiSize.x and mouse.Y >= guiPosition.y and mouse.Y <=
      guiPosition.y + guiSize.y then
    return true
  else
    return false
  end
end

function f.addToPane(window, pane)
  if pane == 'Right' then
    for i, v in pairs(RPaneItems) do if v.Window == window then return end end
    for i, v in pairs(RPaneItems) do RPaneItems[i].Proportion = v.Proportion / 100 * 80 end
    window.Parent = contentR
    if #RPaneItems == 0 then
      table.insert(RPaneItems, {Window = window; Proportion = 1})
    else
      table.insert(RPaneItems, {Window = window; Proportion = 0.2})
    end
  end
  f.buildPanes()
end

function f.removeFromPane(window)
  local pane
  local windowIndex

  for i, v in pairs(LPaneItems) do
    if v.Window == window then
      pane = LPaneItems
      windowIndex = i
    end
  end
  for i, v in pairs(RPaneItems) do
    if v.Window == window then
      pane = RPaneItems
      windowIndex = i
    end
  end

  if pane and #pane > 0 then
    local weightTop, weightBottom, weightTopN, weightBottomN = 0, 0

    for i = windowIndex - 1, 1, -1 do weightTop = weightTop + RPaneItems[i].Proportion end
    for i = windowIndex + 1, #RPaneItems do weightBottom = weightBottom + RPaneItems[i].Proportion end

    if weightTop > 0 and weightBottom == 0 then
      weightTopN = weightTop + RPaneItems[windowIndex].Proportion
    elseif weightTop == 0 and weightBottom > 0 then
      weightBottomN = weightBottom + RPaneItems[windowIndex].Proportion
    else
      weightTopN = weightTop + RPaneItems[windowIndex].Proportion / 2
      weightBottomN = weightBottom + RPaneItems[windowIndex].Proportion / 2
    end

    for i = 1, windowIndex - 1 do RPaneItems[i].Proportion = RPaneItems[i].Proportion / weightTop * weightTopN end
    for i = windowIndex + 1, #RPaneItems do
      RPaneItems[i].Proportion = RPaneItems[i].Proportion / weightBottom * weightBottomN
    end

    table.remove(RPaneItems, windowIndex)
    f.buildPanes()
  end
end

function f.resizePaneItem(window, pane, size)
  local windowIndex = 0
  local sizeWeight = 0
  size = math.max(0.2, size)
  if pane == 'Right' then
    for i, v in pairs(RPaneItems) do
      if v.Window == window then
        windowIndex = i
        break
      end
    end

    for i = windowIndex + 1, #RPaneItems do sizeWeight = sizeWeight + RPaneItems[i].Proportion end

    local oldSize = 1 - (sizeWeight + RPaneItems[windowIndex].Proportion)

    RPaneItems[windowIndex].Proportion = size

    for i = 1, windowIndex - 1 do
      RPaneItems[i].Proportion = RPaneItems[i].Proportion / oldSize * (1 - (sizeWeight + size))
    end

    for i, v in pairs(RPaneItems) do print(v.Window, v.Proportion) end
  end
  f.buildPanes()
end

f.fetchAPI = function()
  local classes, enums, rawAPI = {}, {}, nil
  if script and script:FindFirstChild('API') then
    rawAPI = require(script.API)
  else
    rawAPI = require('data/rawAPI')
  end
  rawAPI = Services.HttpService:JSONDecode(rawAPI)

  for _, entry in pairs(rawAPI) do
    local eType = entry.type
    if eType == 'Class' then
      classes[entry.Name] = entry
      entry.Properties = {}
      entry.Functions = {}
      entry.YieldFunctions = {}
      entry.Events = {}
      entry.Callbacks = {}
    elseif eType == 'Property' then
      table.insert(classes[entry.Class].Properties, entry)
      entry.Category = (propCategories[entry.Class] and propCategories[entry.Class][entry.Name] or 'Other')
      entry.Tags = {}
      for i, tag in pairs(entry.tags) do entry.Tags[tag] = true end
      entry.tags = nil
    elseif eType == 'Enum' then
      enums[entry.Name] = entry
      entry.EnumItems = {}
    elseif eType == 'EnumItem' then
      table.insert(enums[entry.Enum].EnumItems, entry)
    end
  end

  local function getMember(class, mType)
    if not classes[class] or not classes[class][mType] then return end
    local result = {}

    local currentClass = classes[class]
    while currentClass do
      for _, entry in pairs(currentClass[mType]) do table.insert(result, entry) end
      currentClass = classes[currentClass.Superclass]
    end

    table.sort(result, function(a, b) return a.Name < b.Name end)
    return result
  end

  local API = {Classes = classes; Enums = enums; GetMember = getMember}

  return API
end

f.fetchRMD = function()
  local rawRMD = nil
  if script and script:FindFirstChild('RMD') then
    rawRMD = require(script.RMD)
  else
    rawRMD = require('data/rawRMD')
    -- TODO: Show critical error
  end
  rawRMD = Services.HttpService:JSONDecode(rawRMD)

  local RMD = {}
  for _, v in pairs(rawRMD) do RMD[v.Name] = v end

  return RMD
end

function f.checkInPane(window)
  local inPane = false
  for i, v in pairs(LPaneItems) do if v.Window == window then inPane = true end end
  for i, v in pairs(RPaneItems) do if v.Window == window then inPane = true end end
  return inPane
end

function f.transGui(gui, num)
  if gui:IsA('GuiObject') then gui.BackgroundTransparency = num end
  if gui:IsA('TextBox') or gui:IsA('TextLabel') then
    gui.TextTransparency = num
  elseif gui:IsA('ImageButton') or gui:IsA('ImageLabel') then
    gui.ImageTransparency = num
  end
  for i, v in pairs(gui:GetChildren()) do f.transGui(v, num) end
end

function f.hookWindowListener(window)
  local selected = false
  local user = Services.UserInputService

  window.TopBar.InputBegan:connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
      selected = true
      local selectedInit = false
      local initPos = {mouse.X; mouse.Y}
      local dragOffX, dragOffY = mouse.X - window.TopBar.AbsolutePosition.X, mouse.Y - window.TopBar.AbsolutePosition.Y
      local inPane = false
      local releaseEvent
      local mouseEvent

      for i, v in pairs(LPaneItems) do if v.Window == window then inPane = true end end
      for i, v in pairs(RPaneItems) do if v.Window == window then inPane = true end end

      releaseEvent = user.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        releaseEvent:Disconnect()
        if mouseEvent then mouseEvent:Disconnect() end
        selected = false
        if setPane ~= 'None' then
          window.Position = window.Position - UDim2.new(0, gui.AbsoluteSize.X - 300, 0, 0)
          f.addToPane(window, setPane)
        end
        mouseWindow = nil
      end)

      mouseEvent = user.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and
            (selectedInit or f.distance(initPos[1], initPos[2], mouse.X, mouse.Y) >= (inPane and 20 or 5)) then
          if not selectedInit then
            selectedInit = true
            window.Position = UDim2.new(0, mouse.X - dragOffX, 0, mouse.Y - dragOffY)
            window.Parent = nil
          end
          for i, v in pairs(LPaneItems) do
            if v.Window == window then
              f.removeFromPane(window, 'Left')
              break
            end
          end
          for i, v in pairs(RPaneItems) do
            if v.Window == window then
              f.removeFromPane(window, 'Right')
              break
            end
          end

          mouseWindow = window

          window.Parent = gui
          window.Position = UDim2.new(0, mouse.X - dragOffX, 0, mouse.Y - dragOffY)
          window.Size = UDim2.new(0, window.Size.X.Offset, 0, 300)
        end
      end)
    end
  end)

  -- window.TopBar.InputEnded:connect(function(input)
  --	if input.UserInputType == Enum.UserInputType.MouseButton1 then
  --		print("OH")
  --	end
  -- end)

  window.InputBegan:connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
      local inPane = f.checkInPane(window)

      if inPane then return end

      for i, v in pairs(activeWindows) do
        if v ~= window then if f.checkMouseInGui(v) and not f.checkInPane(v) then return end end
      end

      window.Parent = nil
      window.Parent = gui
    end
  end)

  window.TopBar.Close.MouseEnter:connect(function() window.TopBar.Close.BackgroundTransparency = 0.5 end)

  window.TopBar.Close.MouseLeave:connect(function() window.TopBar.Close.BackgroundTransparency = 1 end)

  window.TopBar.Close.MouseButton1Click:connect(function()
    if f.checkInPane(window) then
      f.removeFromPane(window)
      window.Visible = false
      return
    end
    window.Content:TweenSize(UDim2.new(1, -4, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4, true)
    wait(0.4)
    window.Visible = false
  end)
end

-- Explorer Functions

function f.tabIsA(tab, class)
  for i, v in pairs(tab) do if v:IsA(class) then return true end end
  return false
end

function f.hasChildren(tab)
  for i, v in pairs(tab) do if #v:GetChildren() > 0 then return true end end
  return false
end

function f.tabHasChar(tab)
  local players = Services.Players
  for i, v in pairs(tab) do if players:GetPlayerFromCharacter(v) then return true end end
  return false
end

function f.expandAll(obj)
  local node = nodes[obj]
  while node do
    explorerTree.Expanded[node] = true
    node = node.Parent
  end
end

function f.rightClick()
  rightClickContext:Clear()

  local selection = explorerTree.Selection

  -- Cut
  rightClickContext:Add({
    Name = 'Cut';
    Icon = f.icon(nil, iconIndex.CUT_ICON);
    DisabledIcon = f.icon(nil, iconIndex.CUT_D_ICON);
    Shortcut = 'Ctrl+X';
    Disabled = #selection.List == 0;
    OnClick = function()
      print('CUT')
      pcall(function()
        clipboard = {}
        for i, v in pairs(selection.List) do
          table.insert(clipboard, v:Clone())
          v:Destroy()
        end
      end)
      rightClickContext:Hide()
    end;
  })

  rightClickContext:Add({
    Name = 'Copy';
    Icon = f.icon(nil, iconIndex.COPY_ICON);
    DisabledIcon = f.icon(nil, iconIndex.COPY_D_ICON);
    Shortcut = 'Ctrl+C';
    Disabled = #selection.List == 0;
    OnClick = function()
      print('COPY')
      pcall(function()
        clipboard = {}
        for i, v in pairs(selection.List) do table.insert(clipboard, v:Clone()) end
      end)
      rightClickContext:Hide()
    end;
  })

  rightClickContext:Add({
    Name = 'Paste Into';
    Icon = f.icon(nil, iconIndex.PASTE_ICON);
    DisabledIcon = f.icon(nil, iconIndex.PASTE_D_ICON);
    Shortcut = 'Ctrl+B';
    Disabled = #clipboard == 0;
    OnClick = function()
      print('PASTE')
      pcall(function()
        for i, v in pairs(selection.List) do for _, copy in pairs(clipboard) do copy:Clone().Parent = v end end
      end)
      rightClickContext:Hide()
    end;
  })

  rightClickContext:Add({
    Name = 'Duplicate';
    Icon = f.icon(nil, iconIndex.COPY_ICON);
    DisabledIcon = f.icon(nil, iconIndex.COPY_D_ICON);
    Shortcut = 'Ctrl+D';
    Disabled = #selection.List == 0;
    OnClick = function()
      print('DUPLICATE')
      pcall(function() for i, v in pairs(selection.List) do v:Clone().Parent = v.Parent end end)
      rightClickContext:Hide()
    end;
  })

  rightClickContext:Add({
    Name = 'Delete';
    Icon = f.icon(nil, iconIndex.DELETE_ICON);
    DisabledIcon = f.icon(nil, iconIndex.DELETE_D_ICON);
    Shortcut = 'Del';
    Disabled = #selection.List == 0;
    OnClick = function()
      print('DELETE')
      pcall(function() for i, v in pairs(selection.List) do v:Destroy() end end)
      rightClickContext:Hide()
    end;
  })

  rightClickContext:Add({
    Name = 'Rename';
    Icon = '';
    DisabledIcon = '';
    Shortcut = 'Ctrl+R';
    Disabled = #selection.List == 0;
    OnClick = function() print('RENAME') end;
  })

  rightClickContext:AddDivider()

  rightClickContext:Add({
    Name = 'Group';
    Icon = f.icon(nil, iconIndex.GROUP_ICON);
    DisabledIcon = f.icon(nil, iconIndex.GROUP_D_ICON);
    Shortcut = 'Ctrl+G';
    Disabled = #selection.List == 0;
    OnClick = function()
      print('GROUP')
      local base = selection.List[1]
      local model = Instance.new('Model', base.Parent)
      for i, v in pairs(selection.List) do v.Parent = model end
      rightClickContext:Hide()
    end;
  })

  rightClickContext:Add({
    Name = 'Ungroup';
    Icon = f.icon(nil, iconIndex.UNGROUP_ICON);
    DisabledIcon = f.icon(nil, iconIndex.UNGROUP_D_ICON);
    Shortcut = 'Ctrl+U';
    Disabled = not f.tabIsA(selection.List, 'Model');
    OnClick = function()
      print('UNGROUP')
      for i, v in pairs(selection.List) do
        if v:IsA('Model') then
          for _, child in pairs(v:GetChildren()) do child.Parent = v.Parent end
          v:Destroy()
        end
      end
      rightClickContext:Hide()
    end;
  })

  rightClickContext:Add({
    Name = 'Select Children';
    Icon = f.icon(nil, iconIndex.SELECTCHILDREN_ICON);
    DisabledIcon = f.icon(nil, iconIndex.SELECTCHILDREN_D_ICON);
    Shortcut = '';
    Disabled = not f.hasChildren(selection.List);
    OnClick = function()
      print('SELECT CHILDREN')
      local oldSel = selection.List
      selection.List = {}
      selection.Selected = {}
      for i, v in pairs(oldSel) do
        for _, child in pairs(v:GetChildren()) do
          explorerTree.Selection:Add(child)
          f.expandAll(child.Parent)
        end
      end
      explorerTree:TreeUpdate()
      explorerTree:Refresh()
      rightClickContext:Hide()
    end;
  })

  rightClickContext:Add({
    Name = 'Jump To Parent';
    Icon = '';
    DisabledIcon = '';
    Shortcut = '';
    Disabled = #selection.List == 0;
    OnClick = function()
      print('JUMP TO PARENT')
      local oldSel = selection.List
      selection.List = {}
      selection.Selected = {}
      for i, v in pairs(oldSel) do if v.Parent ~= nil then selection:Add(v.Parent) end end
      explorerTree:Refresh()
      rightClickContext:Hide()
    end;
  })

  -- Parts
  if f.tabIsA(selection.List, 'BasePart') or f.tabIsA(selection.List, 'Model') then
    rightClickContext:AddDivider()

    rightClickContext:Add({
      Name = 'Teleport To';
      Icon = '';
      DisabledIcon = '';
      Shortcut = '';
      Disabled = #selection.List == 0;
      OnClick = function()
        print('TELEPORT TO')
        for i, v in pairs(selection.List) do
          if v:IsA('BasePart') then
            Services.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame
            break
          end
        end
        rightClickContext:Hide()
      end;
    })

    rightClickContext:Add({
      Name = 'Teleport Here';
      Icon = '';
      DisabledIcon = '';
      Shortcut = '';
      Disabled = #selection.List == 0;
      OnClick = function()
        print('TELEPORT HERE')
        rightClickContext:Hide()
      end;
    })
  end

  -- Player
  local hasPlayer = false

  if f.tabIsA(selection.List, 'Player') then
    hasPlayer = true
    rightClickContext:AddDivider()

    rightClickContext:Add({
      Name = 'Jump To Character';
      Icon = '';
      DisabledIcon = '';
      Shortcut = '';
      Disabled = #selection.List == 0;
      OnClick = function()
        print('JUMP TO CHARACTER')
        rightClickContext:Hide()
      end;
    })
  end

  if f.tabHasChar(selection.List) then
    if not hasPlayer then rightClickContext:AddDivider() end

    rightClickContext:Add({
      Name = 'Jump To Player';
      Icon = '';
      DisabledIcon = '';
      Shortcut = '';
      Disabled = #selection.List == 0;
      OnClick = function()
        print('JUMP TO PLAYER')
        rightClickContext:Hide()
      end;
    })
  end

  rightClickContext:Refresh()
  rightClickContext:Show(gui, mouse.X, mouse.Y)
end

function f.newExplorer()
  local newgui = getResource('ExplorerPanel')
  local explorerScroll = ScrollBar.new()
  local explorerScrollH = ScrollBar.new(true)
  local newTree = TreeView.new()
  newTree.Scroll = explorerScroll
  newTree.DisplayFrame = newgui.Content.List
  newTree.TreeUpdate = f.updateTree
  newTree.SearchText = ''
  newTree.SearchExpanded = {}

  local nameEvents = {}

  newTree.PreUpdate = function(self)
    for i, v in pairs(nameEvents) do
      v:Disconnect()
      nameEvents[i] = nil
    end
  end

  newTree.NodeCreate = function(self, entry, i)
    entry.Indent.IconFrame.Icon.Image = iconMap

    entry.MouseEnter:Connect(function()
      local node = self.Tree[i + self.Index]
      if node then
        if self.Selection.Selected[node.Obj] then return end
        if rightClickContext.Frame.Parent ~= nil and f.checkMouseInGui(rightClickContext.Frame) then return end
        entry.BackgroundTransparency = 0.7
      end
    end)
    entry.MouseLeave:Connect(function()
      local node = self.Tree[i + self.Index]
      if node then
        if self.Selection.Selected[node.Obj] then return end
        entry.BackgroundTransparency = 1
      end
    end)
    entry.MouseButton1Down:Connect(function()
      local node = self.Tree[i + self.Index]
      if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        self.Selection:Add(node.Obj)
      else
        self.Selection:Set({node.Obj})
      end
      self:Refresh()
      propertiesTree:TreeUpdate()
      propertiesTree:Refresh()
    end)
    entry.MouseButton2Down:Connect(function()
      local node = self.Tree[i + self.Index]
      rightEntry = entry
      rightClickContext.Frame.Parent = nil
      if not self.Selection.Selected[node.Obj] then self.Selection:Set({node.Obj}) end
      self:Refresh()
    end)
    entry.MouseButton2Up:Connect(function() if rightEntry and f.checkMouseInGui(rightEntry) then f.rightClick() end end)

    entry.Indent.Expand.MouseEnter:Connect(function()
      local node = self.Tree[i + self.Index]
      if node then
        if (not self.SearchResults and self.Expanded[node]) or (self.SearchResults and self.SearchExpanded[node.Obj]) then
          f.icon(entry.Indent.Expand, iconIndex.NodeExpandedOver)
        else
          f.icon(entry.Indent.Expand, iconIndex.NodeCollapsedOver)
        end
      end
    end)
    entry.Indent.Expand.MouseLeave:Connect(function()
      local node = self.Tree[i + self.Index]
      if node then
        if (not self.SearchResults and self.Expanded[node]) or (self.SearchResults and self.SearchExpanded[node.Obj]) then
          f.icon(entry.Indent.Expand, iconIndex.NodeExpanded)
        else
          f.icon(entry.Indent.Expand, iconIndex.NodeCollapsed)
        end
      end
    end)
    entry.Indent.Expand.MouseButton1Down:Connect(function()
      local node = self.Tree[i + self.Index]
      if node and not self.SearchResults then
        self:Expand(node)
      else
        if self.SearchExpanded[node.Obj] then
          self.SearchExpanded[node.Obj] = nil
        else
          self.SearchExpanded[node.Obj] = 2
        end
        if self.TreeUpdate then self:TreeUpdate() end
        self:Refresh()
      end
    end)
  end

  newTree.NodeDraw = function(self, entry, node)
    f.icon(entry.Indent.IconFrame, iconIndex[node.Obj.ClassName] or 0)
    entry.Indent.EntryName.Text = node.Obj.Name
    if #node > 0 then
      entry.Indent.Expand.Visible = true
      if (not self.SearchResults and self.Expanded[node]) or (self.SearchResults and self.SearchExpanded[node.Obj] == 2) then
        f.icon(entry.Indent.Expand, iconIndex.NodeExpanded)
      else
        f.icon(entry.Indent.Expand, iconIndex.NodeCollapsed)
      end
      if self.SearchExpanded[node.Obj] == 1 then entry.Indent.Expand.Visible = false end
    else
      entry.Indent.Expand.Visible = false
    end

    if node.Obj.Parent ~= node.Parent.Obj then spawn(function() f.moveObject(node.Obj, node.Obj.Parent) end) end

    if self.Selection.Selected[node.Obj] then
      entry.Indent.EntryName.TextColor3 = Color3.new(1, 1, 1)
      entry.BackgroundTransparency = 0
    else
      entry.Indent.EntryName.TextColor3 = Color3.new(220 / 255, 220 / 255, 220 / 255)
      entry.BackgroundTransparency = 1
    end

    nameEvents[node.Obj] = node.Obj:GetPropertyChangedSignal('Name'):Connect(function()
      entry.Indent.EntryName.Text = node.Obj.Name
    end)

    entry.Indent.Position = UDim2.new(0, 18 * node.Depth, 0, 0)
    entry.Size = UDim2.new(0, nodeWidth + 10, 0, 18)
  end

  explorerScroll.Gui.Parent = newgui.Content
  explorerScroll:Texture({
    FrameColor = Color3.new(80 / 255, 80 / 255, 80 / 255);
    ThumbColor = Color3.new(120 / 255, 120 / 255, 120 / 255);
    ThumbSelectColor = Color3.new(140 / 255, 140 / 255, 140 / 255);
    ButtonColor = Color3.new(163 / 255, 162 / 255, 165 / 255);
    ArrowColor = Color3.new(220 / 255, 220 / 255, 220 / 255);
  })
  explorerScroll:SetScrollFrame(newgui.Content, 3)

  explorerScrollH.Gui.Visible = false
  explorerScrollH.Gui.Parent = newgui.Content
  explorerScrollH:Texture({
    FrameColor = Color3.new(80 / 255, 80 / 255, 80 / 255);
    ThumbColor = Color3.new(120 / 255, 120 / 255, 120 / 255);
    ThumbSelectColor = Color3.new(140 / 255, 140 / 255, 140 / 255);
    ButtonColor = Color3.new(163 / 255, 162 / 255, 165 / 255);
    ArrowColor = Color3.new(220 / 255, 220 / 255, 220 / 255);
  })
  explorerScrollH.Gui.Position = UDim2.new(0, 0, 1, -16)
  explorerScrollH.Gui.Size = UDim2.new(1, -16, 0, 16)

  newTree.OnUpdate = function(self)
    local guiX = explorerPanel.Content.AbsoluteSize.X - 16
    explorerScrollH.VisibleSpace = guiX
    explorerScrollH.TotalSpace = nodeWidth + 10
    if nodeWidth > guiX then
      explorerScrollH.Gui.Visible = true
      explorerScroll.Gui.Size = UDim2.new(0, 16, 1, -16)
      self.DisplayFrame.Size = UDim2.new(1, -16, 1, -16)
    else
      explorerScrollH.Gui.Visible = false
      explorerScroll.Gui.Size = UDim2.new(0, 16, 1, 0)
      self.DisplayFrame.Size = UDim2.new(1, -16, 1, 0)
    end
    explorerScroll.TotalSpace = #self.Tree + 1
    explorerScroll.VisibleSpace = math.ceil(self.DisplayFrame.AbsoluteSize.Y / 19)
    explorerScrollH:Update()
    explorerScroll:Update()
  end
  explorerScroll.OnUpdate = function(self)
    if newTree.Index == self.Index then return end
    newTree.Index = self.Index
    newTree:Refresh()
  end
  explorerScrollH.OnUpdate = function(self)
    for i, v in pairs(explorerTree.Entries) do v.Position = UDim2.new(0, 1 - self.Index, 0, v.Position.Y.Offset) end
  end
  -- explorerData = {Window = newgui, NodeData = {}, Scroll = explorerScroll, Entries = {}}

  explorerTree = newTree

  table.insert(activeWindows, newgui)
  f.hookWindowListener(newgui)
  newgui.Changed:connect(
      function(prop) if prop == 'AbsoluteSize' or prop == 'AbsolutePosition' then newTree:Refresh() end end)

  local searchBox = newgui.TopBar.SearchFrame.Search
  local searchAnim = searchBox.Parent.Entering
  searchBox:GetPropertyChangedSignal('Text'):Connect(function()
    local searchTime = tick()
    lastSearch = searchTime
    wait()
    if lastSearch ~= searchTime then return end
    newTree.SearchText = searchBox.Text
    f.updateSearch(newTree)
    explorerTree:TreeUpdate()
    explorerTree:Refresh()
  end)

  searchBox.Focused:Connect(function()
    searchBox.Empty.Visible = false
    searchAnim:TweenSizeAndPosition(UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out,
                                    Enum.EasingStyle.Quart, 0.5, true)
  end)

  searchBox.FocusLost:Connect(function()
    if searchBox.Text == '' then
      searchBox.Empty.Visible = true
    else
      searchBox.Empty.Visible = false
    end
    searchAnim:TweenSizeAndPosition(UDim2.new(0, 0, 0, 2), UDim2.new(0.5, 0, 0, 0), Enum.EasingDirection.Out,
                                    Enum.EasingStyle.Quart, 0.5, true)
  end)

  return newgui
end

function f.refreshExplorer()
  -- if updateDebounce then return end
  -- updateDebounce = true
  -- Services.RunService.RenderStepped:wait()
  -- updateDebounce = false
  explorerTree:Refresh()
end

function f.makeWindow(name)
  local newWindow = getResource(name)

  table.insert(activeWindows, newWindow)
  f.hookWindowListener(newWindow)

  return newWindow
end

function f.getRMDOrder(class)
  local currentClass = API.Classes[class]
  while currentClass do
    if RMD[currentClass.Name] and RMD[currentClass.Name].ExplorerOrder then return RMD[currentClass.Name].ExplorerOrder end
    currentClass = API.Classes[currentClass.Superclass]
  end
  return 999
end

function f.reDepth(node, depth)
  for i, v in ipairs(node) do
    v.Depth = depth + 1
    f.reDepth(node[i], depth + 1)
  end
end

function f.moveObject(obj, par)
  ypcall(function()
    if obj.Parent == nil then return end
    local node = nodes[obj]
    local newNode = nodes[par]
    if node and newNode then
      local parNode = node.Parent
      for i, v in ipairs(parNode) do
        if v == node then
          table.remove(parNode, i)
          break
        end
      end

      node.Depth = f.depth(par) + 1
      f.reDepth(node, node.Depth)

      node.Parent = newNode
      newNode.Sorted = nil
      table.insert(newNode, node)

      if not updateDebounce then
        updateDebounce = true
        wait()
        updateDebounce = false
        explorerTree:TreeUpdate()
        f.refreshExplorer()
      end
    end
  end)
end

function f.addObject(obj, noupdate, recurse)
  ypcall(function()
    local access = obj.Changed
    if not nodes[obj.Parent] then return end
    local newNode = {
      Obj = obj;
      Parent = nodes[obj.Parent];
      -- Ind = #nodes[obj.Parent] + 1,
      ExplorerOrder = f.getRMDOrder(obj.ClassName);
      Depth = f.depth(obj);
      UID = tick(); -- RMD[v.ClassName] and (RMD[v.ClassName].ExplorerOrder or 999) or 999
    }
    if newNode.ExplorerOrder <= 0 and not obj:IsA('Workspace') and obj.Parent == game then newNode.ExplorerOrder = 999 end
    nodes[obj] = newNode
    newNode.Parent.Sorted = nil
    table.insert(newNode.Parent, newNode)

    newNode.AncestryEvent = obj.AncestryChanged:Connect(function(child, par)
      spawn(function() if child == obj then f.moveObject(obj, par) end end)
    end)

    newNode.AddedEvent = obj.ChildAdded:Connect(function(child) f.addObject(child, false, true) end)

    newNode.RemovedEvent = obj.ChildRemoved:Connect(function(child) f.removeObject(child, false, true) end)

    if recurse then for i, v in pairs(obj:GetDescendants()) do f.addObject(v, true) end end

    if not noupdate then
      if explorerTree.SearchChecks and explorerTree.SearchResults then
        for i, v in pairs(explorerTree.SearchChecks) do
          local success, found = pcall(v, obj)
          if found then
            explorerTree.SearchResults[obj] = true
            explorerTree.SearchExpanded[obj] = math.max(explorerTree.SearchExpanded[v] or 0, 1)
            local par = obj.Parent
            while par and not explorerTree.SearchResults[par] or explorerTree.SearchExpanded[par] == 1 do
              explorerTree.SearchResults[par] = true
              explorerTree.SearchExpanded[par] = 2
              par = par.Parent
            end
          end
        end
      end

      if not updateDebounce then
        updateDebounce = true
        wait()
        updateDebounce = false
        explorerTree:TreeUpdate()
        f.refreshExplorer()
      end
    end
    -- TODO: Maybe ypcall?
  end)
end

function f.nodeDescendants(node, descendants)
  for i, v in ipairs(node) do
    table.insert(descendants, v.Obj)
    f.nodeDescendants(v, descendants)
  end
end

function f.removeObject(obj, noupdate, recurse)
  ypcall(function()
    local node = nodes[obj]
    if node then
      local par = node.Parent
      for i, v in ipairs(par) do
        if v == node then
          table.remove(par, i)
          break
        end
      end

      node.AncestryEvent:Disconnect()
      node.AncestryEvent = nil

      node.AddedEvent:Disconnect()
      node.AddedEvent = nil

      node.RemovedEvent:Disconnect()
      node.RemovedEvent = nil

      if recurse then
        local descendants = {}
        f.nodeDescendants(node, descendants)
        for i, v in ipairs(descendants) do f.removeObject(v, true) end
      end

      nodes[obj] = nil

      if not updateDebounce and not noupdate then
        updateDebounce = true
        wait()
        updateDebounce = false
        explorerTree:TreeUpdate()
        f.refreshExplorer()
      end
    end
  end)
end

function f.indexNodes(obj)
  if not nodes[game] then nodes[game] = {Obj = game; Parent = nil} end

  local addObject = f.addObject
  local removeObject = f.removeObject

  -- game.DescendantAdded:Connect(function(obj) spawn(function() addObject(obj) end) end)
  -- game.DescendantRemoving:Connect(function(obj) spawn(function() removeObject(obj) end) end)

  for i, v in pairs(game:GetChildren()) do addObject(v, true, true) end
end

function f.gExpanded(obj)
  if explorerData.NodeData and explorerData.NodeData[obj] and explorerData.NodeData[obj].Expanded then return true end
  return false
end

local searchFunctions = {
  ['class:'] = function(token, results)
    local class = string.match(token, '%S+:%s*(%S*)')
    if class == '' then return end
    local foundClass = ''
    for i, v in pairs(API.Classes) do
      if i:lower() == class:lower() then
        foundClass = i
        break
      elseif i:lower():find(class:lower(), 1, true) then
        foundClass = i
      end
    end

    if foundClass == '' then return end

    return function(obj) return obj.ClassName == foundClass end
  end;
  ['isa:'] = function(token, results)
    local class = string.match(token, '%S+:%s*(%S*)')
    if class == '' then return end
    local foundClass = ''
    for i, v in pairs(API.Classes) do
      if i:lower() == class:lower() then
        foundClass = i
        break
      elseif i:lower():find(class:lower(), 1, true) then
        foundClass = i
      end
    end

    if foundClass == '' then return end

    return function(obj) return obj:IsA(foundClass) end
  end;
  ['regex:'] = function(token, results)
    local pattern = string.match(token, '%S+:%s*(%S*)')
    if pattern == '' then return end

    return function(obj) return obj.Name:find(pattern) end
  end;
}

local searchCache = {}

function f.updateSearch(self)
  local searchText = self.SearchText
  if searchText == '' then
    self.SearchResults = nil
    return
  end
  local results = {}
  local tokens = {}
  local checks = {}
  local tokenMap = {}

  self.SearchExpanded = {}

  -- Splits search text into multiple tokens for multiple searching
  for w in string.gmatch(searchText, '[^|]+') do table.insert(tokens, w) end

  -- Create checks based on search text
  for _, token in pairs(tokens) do
    token = token:match('%s*(.+)')
    tokenMap[token] = true
    local keyword = string.match(token, '%S+:')
    if searchFunctions[keyword] then
      local res = searchFunctions[keyword](token, results)
      if res then checks[token] = res end
    else
      checks[token] = function(obj) return obj.Name:lower():find(token:lower(), 1, true) end
    end
  end

  -- Remove uneeded items from cache
  for i, v in pairs(searchCache) do if not tokenMap[i] then searchCache[i] = nil end end

  -- Perform the searches
  local searchExpanded = self.SearchExpanded

  for token, check in pairs(checks) do
    local newResults = {}
    if searchCache[token] then
      for obj, v in pairs(searchCache[token]) do
        results[obj] = true
        searchExpanded[obj] = math.max(searchExpanded[obj] or 0, 1)
        local par = obj.Parent
        while par and not results[par] or searchExpanded[par] == 1 do
          results[par] = true
          searchExpanded[par] = 2
          par = par.Parent
        end
      end
    else
      for i, v in pairs(game:GetDescendants()) do
        local success, found = pcall(check, v)
        if found and nodes[v] then
          results[v] = true
          newResults[v] = true
          searchExpanded[v] = math.max(searchExpanded[v] or 0, 1)
          local par = v.Parent
          while par and not results[par] or searchExpanded[par] == 1 do
            results[par] = true
            newResults[par] = true
            searchExpanded[par] = 2
            par = par.Parent
          end
        end
      end
      searchCache[token] = newResults
    end
  end

  --[[
	for i,v in pairs(game:GetDescendants()) do
		searchCache[token] = {}
		for token,check in pairs(checks) do
			if searchCache[token] then for obj,_ in pairs(searchCache[token]) do results[obj] = true end break end
			local success,found = pcall(check,v)
			if found and nodes[v] then
				results[v] = true
				local par = v.Parent
				while par and not results[par] do
					results[par] = true
					par = par.Parent
				end
				break
			end
		end
	end
	--]]
  self.SearchChecks = checks
  self.SearchResults = results
end

local textWidthRuler = Instance.new('TextLabel', gui)
textWidthRuler.Font = Enum.Font.SourceSans
textWidthRuler.TextSize = 14
textWidthRuler.Visible = false

function f.textWidth(text)
  textWidthRuler.Text = text
  return textWidthRuler.TextBounds.X
end

function f.updateTree(self)
  local isSearching = self.SearchResults
  local searchExpanded = self.SearchExpanded

  nodeWidth = 0

  local function fillTree(node, tree)
    if not node.Sorted then
      table.sort(node, function(a, b)
        local o1 = a.ExplorerOrder
        local o2 = b.ExplorerOrder
        if o1 ~= o2 then
          return o1 < o2
        elseif a.Obj.Name ~= b.Obj.Name then
          return a.Obj.Name < b.Obj.Name
        elseif a.Obj.ClassName ~= b.Obj.ClassName then
          return a.Obj.ClassName < b.Obj.ClassName
        else
          return a.UID < b.UID
        end
      end)
      node.Sorted = true
    end

    for i = 1, #node do
      -- node[i].Ind = i
      if not isSearching or (isSearching and isSearching[node[i].Obj]) then
        local textWidth = node[i].Depth * 18 + f.textWidth(node[i].Obj.Name) + 22
        nodeWidth = textWidth > nodeWidth and textWidth or nodeWidth
        table.insert(tree, node[i])
        if (not isSearching and explorerTree.Expanded[node[i]]) or (isSearching and searchExpanded[node[i].Obj] == 2) then
          fillTree(node[i], tree)
        end
      end
    end
  end

  self.Tree = {}
  fillTree(nodes[game], self.Tree)
  -- self.Scroll:Update()
end

function f.icon(frame, index)
  local row, col = math.floor(index / 14 % 14), math.floor(index % 14)
  local pad, border = 2, 1
  if not frame then
    frame = Instance.new('Frame')
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(0, 16, 0, 16)
    frame.ClipsDescendants = true
    local newMap = Instance.new('ImageLabel', frame)
    newMap.Name = 'Icon'
    newMap.BackgroundTransparency = 1
    newMap.Size = UDim2.new(16, 0, 16, 0)
    newMap.Image = iconMap
  end
  local icon = frame.Icon
  icon.Position = UDim2.new(-col - (pad * (col + 1) + border) / 16, 0, -row - (pad * (row + 1) + border) / 16, 0)
  return frame
end

function f.depth(obj)
  local depth = 0
  local curPar = obj.Parent
  while curPar ~= nil do
    curPar = curPar.Parent
    depth = depth + 1
  end
  return depth
end

local Selection
do
  Selection = {List = {}; Selected = {}}

  function Selection:Add(obj)
    if Selection.Selected[obj] then return end

    Selection.Selected[obj] = true
    table.insert(Selection.List, obj)
  end

  function Selection:Set(objs)
    for i, v in pairs(Selection.List) do Selection.Selected[v] = nil end
    Selection.List = {}

    for i, v in pairs(objs) do
      if not Selection.Selected[v] then
        Selection.Selected[v] = true
        table.insert(Selection.List, v)
      end
    end
  end

  function Selection:Remove(obj)
    if not Selection.Selected[obj] then return end

    Selection.Selected[obj] = false
    for i, v in pairs(Selection.List) do
      if v == obj then
        table.remove(Selection.List, i)
        break
      end
    end
  end
end

function f.refreshExplorers(id)
  -- wait()
  local e = explorerData
  local window = e.Window
  local scroll = e.Scroll
  local entrySpace = math.floor(window.Content.List.AbsoluteSize.Y / 19) + 1

  scroll.TotalSpace = #e.Tree
  scroll.VisibleSpace = entrySpace - 1

  for i = 1, entrySpace do
    local node = e.Tree[i + scroll.Index]
    if node then
      local nodeData = e.NodeData[node.Obj]
      local cEntry = e.Entries[i]
      if not cEntry then
        cEntry = entryTemplate:Clone()
        cEntry.Position = UDim2.new(0, 1, 0, 2 + 19 * #window.Content.List:GetChildren())
        cEntry.Parent = window.Content.List
        e.Entries[i] = cEntry

        cEntry.MouseEnter:connect(function()
          local node = e.Tree[i + scroll.Index]
          if node then
            if Selection.Selected[node.Obj] then return end
            cEntry.BackgroundTransparency = 0.7
          end
        end)
        cEntry.MouseLeave:connect(function()
          local node = e.Tree[i + scroll.Index]
          if node then
            if Selection.Selected[node.Obj] then return end
            cEntry.BackgroundTransparency = 1
          end
        end)
        cEntry.MouseButton1Down:connect(function()
          local node = e.Tree[i + scroll.Index]
          if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            Selection:Add(node.Obj)
          else
            Selection:Set({node.Obj})
          end
          f.refreshExplorer()
        end)

        cEntry.Indent.Expand.MouseEnter:connect(function()
          local node = e.Tree[i + scroll.Index]
          if node then
            if not e.NodeData[node.Obj] then e.NodeData[node.Obj] = {} end
            if e.NodeData[node.Obj].Expanded then
              f.icon(cEntry.Indent.Expand, iconIndex.NodeExpandedOver)
            else
              f.icon(cEntry.Indent.Expand, iconIndex.NodeCollapsedOver)
            end
          end
        end)
        cEntry.Indent.Expand.MouseLeave:connect(function()
          local node = e.Tree[i + scroll.Index]
          if node then
            if not e.NodeData[node.Obj] then e.NodeData[node.Obj] = {} end
            if e.NodeData[node.Obj].Expanded then
              f.icon(cEntry.Indent.Expand, iconIndex.NodeExpanded)
            else
              f.icon(cEntry.Indent.Expand, iconIndex.NodeCollapsed)
            end
          end
        end)
        cEntry.Indent.Expand.MouseButton1Down:connect(function()
          local node = e.Tree[i + scroll.Index]
          if node then
            if not e.NodeData[node.Obj] then e.NodeData[node.Obj] = {} end
            if e.NodeData[node.Obj].Expanded then
              e.NodeData[node.Obj].Expanded = false
            else
              e.NodeData[node.Obj].Expanded = true
            end
            f.updateTree()
            f.refreshExplorer()
          end
        end)
      end

      cEntry.Visible = true
      f.icon(cEntry.Indent.IconFrame, iconIndex[node.Obj.ClassName] or 0)
      cEntry.Indent.EntryName.Text = node.Obj.Name
      if #node.Obj:GetChildren() > 0 then
        cEntry.Indent.Expand.Visible = true
        if nodeData and nodeData.Expanded then
          f.icon(cEntry.Indent.Expand, iconIndex.NodeExpanded)
        else
          f.icon(cEntry.Indent.Expand, iconIndex.NodeCollapsed)
        end
      else
        cEntry.Indent.Expand.Visible = false
      end

      if Selection.Selected[node.Obj] then
        cEntry.Indent.EntryName.TextColor3 = Color3.new(1, 1, 1)
        cEntry.BackgroundTransparency = 0
      else
        cEntry.Indent.EntryName.TextColor3 = Color3.new(220 / 255, 220 / 255, 220 / 255)
        cEntry.BackgroundTransparency = 1
      end

      cEntry.Indent.Position = UDim2.new(0, 18 * node.Depth, 0, 0)
    else
      local cEntry = e.Entries[i]
      if cEntry then cEntry.Visible = false end
    end
  end

  -- Outliers
  for i = entrySpace + 1, #e.Entries do
    if e.Entries[i] then
      e.Entries[i]:Destroy()
      e.Entries[i] = nil
    end
  end
end

-- Properties Functions

function f.toValue(str, valueType)
  if valueType == 'int' or valueType == 'float' or valueType == 'double' then return tonumber(str) end
end

function f.childValue(prop, value, obj)
  local propName = prop.Name
  local parentPropName = prop.ParentProp.Name
  local parentPropType = prop.ParentProp.ValueType
  local objProp = obj[parentPropName]

  if parentPropType == 'Vector3' then
    return Vector3.new(propName == 'X' and value or objProp.X, propName == 'Y' and value or objProp.Y,
                       propName == 'Z' and value or objProp.Z)
  elseif parentPropType == 'Rect2D' then
    return Rect.new(propName == 'X0' and value or objProp.Min.X, propName == 'Y0' and value or objProp.Min.Y,
                    propName == 'X1' and value or objProp.Max.X, propName == 'Y1' and value or objProp.Max.Y)
  end
end

function f.setProp(prop, str, child)
  local value = f.toValue(str, prop.ValueType)
  if value then
    for i, v in pairs(explorerTree.Selection.List) do
      pcall(function()
        if v:IsA(prop.Class) then
          if #child == 0 then
            v[prop.Name] = value
          else
            v[prop.ParentProp.Name] = f.childValue(prop, value, v)
          end
        end
      end)
    end
  end
end

local propControls = {
  ['Default'] = function(prop, child)
    local newMt = setmetatable({}, {})

    local controlGui, readOnlyText, lastValue

    local function setup(self, frame)
      controlGui = resources.PropControls.String:Clone()
      readOnlyText = controlGui.ReadOnly

      if prop.Tags['readonly'] then
        if lastValue then readOnlyText.Text = tostring(lastValue) end
        readOnlyText.Visible = true
        readOnlyText.Parent = frame
      else
        if lastValue then controlGui.Text = tostring(lastValue) end
        controlGui.FocusLost:Connect(function() f.setProp(prop, controlGui.Text, child or {}) end)
        controlGui.Parent = frame
      end
    end
    newMt.Setup = setup

    local function update(self, value)
      lastValue = value
      if not controlGui then return end
      if not prop.Tags['readonly'] then
        controlGui.Text = tostring(value)
      else
        readOnlyText.Text = tostring(value)
      end
    end
    newMt.Update = update

    local function focus(self) controlGui:CaptureFocus() end
    newMt.Focus = focus
    return newMt
  end;
  ['Vector3'] = function(prop, child)
    local newMt = setmetatable({}, {})

    local controlGui, readOnlyText

    local function setup(self, frame)
      controlGui = resources.PropControls.String:Clone()
      readOnlyText = controlGui.ReadOnly

      if prop.Tags['readonly'] then
        readOnlyText.Visible = true
        readOnlyText.Parent = frame
      else
        controlGui.FocusLost:Connect(function() f.setProp(prop, controlGui.Text, child or {}) end)
        controlGui.Parent = frame
      end
    end
    newMt.Setup = setup

    local function update(self, value)
      if not prop.Tags['readonly'] then
        controlGui.Text = tostring(value)
        self.Children[1].Control:Update(value.X)
        self.Children[2].Control:Update(value.Y)
        self.Children[3].Control:Update(value.Z)
      else
        readOnlyText.Text = tostring(value)
        self.Children[1].Control:Update(value.X)
        self.Children[2].Control:Update(value.Y)
        self.Children[3].Control:Update(value.Z)
      end
    end
    newMt.Update = update

    local function focus(self) controlGui:CaptureFocus() end
    newMt.Focus = focus

    newMt.Children = {
      f.getChildProp(prop, {Name = 'X'; ValueType = 'double'; Depth = 2});
      f.getChildProp(prop, {Name = 'Y'; ValueType = 'double'; Depth = 2});
      f.getChildProp(prop, {Name = 'Z'; ValueType = 'double'; Depth = 2});
    }

    return newMt
  end;
  ['Rect2D'] = function(prop, child)
    local newMt = setmetatable({}, {})

    local controlGui, readOnlyText

    local function setup(self, frame)
      controlGui = resources.PropControls.String:Clone()
      readOnlyText = controlGui.ReadOnly

      if prop.Tags['readonly'] then
        readOnlyText.Visible = true
        readOnlyText.Parent = frame
      else
        controlGui.FocusLost:Connect(function() f.setProp(prop, controlGui.Text, child or {}) end)
        controlGui.Parent = frame
      end
    end
    newMt.Setup = setup

    local function update(self, value)
      if not prop.Tags['readonly'] then
        controlGui.Text = tostring(value)
        self.Children[1].Control:Update(value.Min.X)
        self.Children[2].Control:Update(value.Min.Y)
        self.Children[3].Control:Update(value.Max.X)
        self.Children[4].Control:Update(value.Max.Y)
      else
        readOnlyText.Text = tostring(value)
        self.Children[1].Control:Update(value.Min.X)
        self.Children[2].Control:Update(value.Min.Y)
        self.Children[3].Control:Update(value.Max.X)
        self.Children[4].Control:Update(value.Max.Y)
      end
    end
    newMt.Update = update

    local function focus(self) controlGui:CaptureFocus() end
    newMt.Focus = focus

    newMt.Children = {
      f.getChildProp(prop, {Name = 'X0'; ValueType = 'double'; Depth = 2});
      f.getChildProp(prop, {Name = 'Y0'; ValueType = 'double'; Depth = 2});
      f.getChildProp(prop, {Name = 'X1'; ValueType = 'double'; Depth = 2});
      f.getChildProp(prop, {Name = 'Y1'; ValueType = 'double'; Depth = 2});
    }

    return newMt
  end;
}

function f.getPropControl(prop, child)
  local control = propControls[prop.ValueType] or propControls['Default']
  return control(prop, child)
end

--[[
local propExpandable = {
	["Vector3"] = true
}
--]]

--[[
function f.getChildrenControls(obj,prop)
	local children = {}
	if prop.ValueType == "Vector3" then
		local newProp = {}
		for i,v in pairs(prop) do newProp[i] = v end
		newProp.ValueType = "double"
		newProp.Name = "X"
		newProp.ParentName = prop.Name
		newProp.ParentType = prop.ValueType
		local newNode = {
			Prop = newProp,
			RefName = prop.Class.."|"..prop.Name.."|X",
			Control = f.getPropControl(newProp,{"X"}),
			Depth = 2,
			Obj = obj,
			Children = {}
		}
		table.insert(children,newNode)
	end
	return children
end
--]]

function f.getChildProp(prop, data)
  local newProp = {Name = data.Name; ValueType = data.ValueType; ParentProp = prop; Tags = prop.Tags; Class = prop.Class}
  local childNode = {
    Prop = newProp;
    RefName = prop.Class .. '|' .. prop.Name .. '|' .. data.Name;
    Control = f.getPropControl(newProp, {data.Name});
    Depth = data.Depth;
    Children = {};
  }
  return childNode
end

function f.updatePropTree(self)
  self.Tree = {}

  propWidth = 0
  local gotProps = {}
  local props = {}
  local newTree = {}

  for i, v in pairs(explorerTree.Selection.List) do
    local class = API.Classes[v.ClassName]
    while class ~= nil and not gotProps[class.Name] do
      for _, prop in pairs(class.Properties) do
        pcall(function()
          local check = v[prop.Name]
          local categoryList = propCategories[class.Name] or {}
          local newNode = {
            Prop = prop;
            RefName = class.Name .. '|' .. prop.Name;
            Obj = v;
            Control = f.getPropControl(prop);
            Depth = 1;
            -- Children = f.getChildrenControls(v,prop)
          }
          -- f.setupControls(newNode)
          -- newNode.Control.Children = newNode.Children
          local textWidth = f.textWidth(prop.Name) + newNode.Depth * 18 + 5
          propWidth = textWidth > propWidth and textWidth or propWidth
          table.insert(props, newNode)
        end)
      end
      gotProps[class.Name] = true
      class = API.Classes[class.Superclass]
    end
  end

  table.sort(props, function(a, b)
    local o1 = categoryOrder[a.Prop.Category] or 0
    local o2 = categoryOrder[b.Prop.Category] or 0
    if o1 ~= o2 then
      return o1 < o2
    else
      return a.Prop.Name < b.Prop.Name
    end
  end)

  local nextCategory = ''
  local categoryNode
  for i, v in pairs(props) do
    if nextCategory ~= v.Prop.Category then
      nextCategory = v.Prop.Category
      categoryNode = {Category = true; RefName = 'CAT:' .. nextCategory; Prop = {Name = nextCategory}; Depth = 1}
      table.insert(newTree, categoryNode)
    end
    if self.Expanded['CAT:' .. nextCategory] then
      table.insert(newTree, v)
      if v.Control.Children and self.Expanded[v.RefName] then
        for _, child in pairs(v.Control.Children) do table.insert(newTree, child) end
      end
    end
  end

  self.Tree = newTree
end

function f.newProperties()
  local newgui = getResource('PropertiesPanel')
  local propertiesScroll = ScrollBar.new()
  local propertiesScrollH = ScrollBar.new(true)
  local newTree = TreeView.new()
  newTree.NodeTemplate = getResource('PEntry')
  newTree.Height = 22
  newTree.OffY = 0
  newTree.Scroll = propertiesScroll
  newTree.DisplayFrame = newgui.Content.List
  newTree.TreeUpdate = f.updatePropTree
  newTree.SearchText = ''

  local changeEvents = {}
  local drawOrder = 0

  newTree.PreUpdate = function(self)
    drawOrder = 0
    for i, v in pairs(changeEvents) do
      v:Disconnect()
      changeEvents[i] = nil
    end
  end

  newTree.NodeCreate = function(self, entry, i)
    entry.MouseEnter:Connect(function()
      local node = self.Tree[i + self.Index]
      if node then
        if self.Selection.Selected[node.RefName] then return end
        entry.Indent.BackgroundTransparency = 0.7
      end
    end)
    entry.MouseLeave:Connect(function()
      local node = self.Tree[i + self.Index]
      if node then
        if self.Selection.Selected[node.RefName] then return end
        entry.Indent.BackgroundTransparency = 1
      end
    end)
    entry.MouseButton1Down:Connect(function()
      local node = self.Tree[i + self.Index]
      -- node.Control:Focus()
    end)
    entry.MouseButton2Down:Connect(function()
      local node = self.Tree[i + self.Index]
      -- node.Control:Focus()
    end)

    entry.Indent.Expand.MouseEnter:Connect(function()
      local node = self.Tree[i + self.Index]
      if node then
        if (not self.SearchResults and self.Expanded[node]) or (self.SearchResults and self.SearchExpanded[node.Obj]) then
          f.icon(entry.Indent.Expand, iconIndex.NodeExpandedOver)
        else
          f.icon(entry.Indent.Expand, iconIndex.NodeCollapsedOver)
        end
      end
    end)
    entry.Indent.Expand.MouseLeave:Connect(function()
      local node = self.Tree[i + self.Index]
      if node then
        if (not self.SearchResults and self.Expanded[node]) or (self.SearchResults and self.SearchExpanded[node.Obj]) then
          f.icon(entry.Indent.Expand, iconIndex.NodeExpanded)
        else
          f.icon(entry.Indent.Expand, iconIndex.NodeCollapsed)
        end
      end
    end)
    entry.Indent.Expand.MouseButton1Down:Connect(function()
      local node = self.Tree[i + self.Index]
      self:Expand(node.RefName)
    end)
  end

  newTree.NodeDraw = function(self, entry, node)
    entry.Indent.EntryName.Text = node.Prop.Name
    entry.Indent.Control:ClearAllChildren()

    if not node.Category then
      -- Update property controls
      node.Control:Setup(entry.Indent.Control)
      if node.Depth > 1 then
        -- node.Control:Update(node.Obj[node.Prop.ParentName][node.Prop.Name])
      else
        node.Control:Update(node.Obj[node.Prop.Name])
      end

      -- Color switching
      -- if drawOrder % 2 == 0 and not node.Category then
      --	entry.BackgroundColor3 = Color3.new(96/255,96/255,96/255)
      -- else
      entry.BackgroundColor3 = Color3.new(80 / 255, 80 / 255, 80 / 255)
      -- end
    else
      entry.BackgroundColor3 = Color3.new(64 / 255, 64 / 255, 64 / 255)
    end
    drawOrder = drawOrder + 1

    -- Fonts for category nodes and property nodes
    if node.Category then
      entry.Indent.Sep.Visible = false
      entry.Indent.EntryName.Font = Enum.Font.SourceSansBold
      entry.Indent.EntryName.TextColor3 = Color3.new(220 / 255, 220 / 255, 220 / 255)
    else
      entry.Indent.Sep.Visible = true
      entry.Indent.EntryName.Font = Enum.Font.SourceSans
      if node.Prop.Tags['readonly'] then
        entry.Indent.EntryName.TextColor3 = Color3.new(144 / 255, 144 / 255, 144 / 255)
      else
        entry.Indent.EntryName.TextColor3 = Color3.new(220 / 255, 220 / 255, 220 / 255)
      end
    end

    if node.Category or node.Control.Children then
      entry.Indent.Expand.Visible = true
      if self.Expanded[node.RefName] then
        f.icon(entry.Indent.Expand, iconIndex.NodeExpanded)
      else
        f.icon(entry.Indent.Expand, iconIndex.NodeCollapsed)
      end
    else
      entry.Indent.Expand.Visible = false
    end

    if self.Selection.Selected[node.Obj] then
      entry.Indent.EntryName.TextColor3 = Color3.new(1, 1, 1)
      entry.Indent.BackgroundTransparency = 0
    else
      -- entry.Indent.EntryName.TextColor3 = Color3.new(220/255, 220/255, 220/255)
      entry.Indent.BackgroundTransparency = 1
    end

    if not node.Category and node.Depth == 1 then
      changeEvents[node.Obj] = node.Obj:GetPropertyChangedSignal(node.Prop.Name):Connect(function()
        node.Control:Update(node.Obj[node.Prop.Name])
      end)
    end

    entry.Indent.Position = UDim2.new(0, 18 * node.Depth, 0, 0)

    local newPropWidth = propWidth - node.Depth * 18
    entry.Indent.EntryName.Size = UDim2.new(0, newPropWidth, 0, 22)
    entry.Indent.Control.Position = UDim2.new(0, newPropWidth + 2, 0, 0)
    entry.Indent.Control.Size = UDim2.new(1, -newPropWidth - 2, 0, 22)
    entry.Indent.Sep.Position = UDim2.new(0, newPropWidth + 1, 0, 0)
    entry.Size = UDim2.new(0, 281, 0, 22)
  end

  propertiesScroll.Gui.Parent = newgui.Content
  propertiesScroll:Texture({
    FrameColor = Color3.new(80 / 255, 80 / 255, 80 / 255);
    ThumbColor = Color3.new(120 / 255, 120 / 255, 120 / 255);
    ThumbSelectColor = Color3.new(140 / 255, 140 / 255, 140 / 255);
    ButtonColor = Color3.new(163 / 255, 162 / 255, 165 / 255);
    ArrowColor = Color3.new(220 / 255, 220 / 255, 220 / 255);
  })
  propertiesScroll:SetScrollFrame(newgui.Content, 3)

  propertiesScrollH.Gui.Visible = false
  propertiesScrollH.Gui.Parent = newgui.Content
  propertiesScrollH:Texture({
    FrameColor = Color3.new(80 / 255, 80 / 255, 80 / 255);
    ThumbColor = Color3.new(120 / 255, 120 / 255, 120 / 255);
    ThumbSelectColor = Color3.new(140 / 255, 140 / 255, 140 / 255);
    ButtonColor = Color3.new(163 / 255, 162 / 255, 165 / 255);
    ArrowColor = Color3.new(220 / 255, 220 / 255, 220 / 255);
  })
  propertiesScrollH.Gui.Position = UDim2.new(0, 0, 1, -16)
  propertiesScrollH.Gui.Size = UDim2.new(1, -16, 0, 16)

  newTree.OnUpdate = function(self)
    local guiX = propertiesPanel.Content.AbsoluteSize.X - 16
    --[[
		propertiesScrollH.VisibleSpace = guiX
		propertiesScrollH.TotalSpace = nodeWidth+10
		if nodeWidth > guiX then
			explorerScrollH.Gui.Visible = true
			explorerScroll.Gui.Size = UDim2.new(0,16,1,-16)
			self.DisplayFrame.Size = UDim2.new(1,-16,1,-16)
		else
			explorerScrollH.Gui.Visible = false
			explorerScroll.Gui.Size = UDim2.new(0,16,1,0)
			self.DisplayFrame.Size = UDim2.new(1,-16,1,0)
		end
		--]]
    propertiesScroll.TotalSpace = #self.Tree + 1
    propertiesScroll.VisibleSpace = math.ceil(self.DisplayFrame.AbsoluteSize.Y / 23)
    propertiesScrollH:Update()
    propertiesScroll:Update()
  end
  propertiesScroll.OnUpdate = function(self)
    if newTree.Index == self.Index then return end
    newTree.Index = self.Index
    newTree:Refresh()
  end
  propertiesScrollH.OnUpdate = function(self)
    for i, v in pairs(propertiesTree.Entries) do v.Position = UDim2.new(0, -self.Index, 0, v.Position.Y.Offset) end
  end
  -- explorerData = {Window = newgui, NodeData = {}, Scroll = explorerScroll, Entries = {}}

  propertiesTree = newTree

  table.insert(activeWindows, newgui)
  f.hookWindowListener(newgui)
  newgui.Changed:connect(
      function(prop) if prop == 'AbsoluteSize' or prop == 'AbsolutePosition' then newTree:Refresh() end end)

  local searchBox = newgui.TopBar.SearchFrame.Search
  local searchAnim = searchBox.Parent.Entering
  searchBox:GetPropertyChangedSignal('Text'):Connect(function()
    --[[
		local searchTime = tick()
		lastSearch = searchTime
		wait()
		if lastSearch ~= searchTime then return end
		newTree.SearchText = searchBox.Text
		f.updateSearch(newTree)
		explorerTree:TreeUpdate()
		explorerTree:Refresh()
		--]]
  end)

  searchBox.Focused:Connect(function()
    searchBox.Empty.Visible = false
    searchAnim:TweenSizeAndPosition(UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out,
                                    Enum.EasingStyle.Quart, 0.5, true)
  end)

  searchBox.FocusLost:Connect(function()
    if searchBox.Text == '' then
      searchBox.Empty.Visible = true
    else
      searchBox.Empty.Visible = false
    end
    searchAnim:TweenSizeAndPosition(UDim2.new(0, 0, 0, 2), UDim2.new(0.5, 0, 0, 0), Enum.EasingDirection.Out,
                                    Enum.EasingStyle.Quart, 0.5, true)
  end)

  return newgui
end

local function welcomePlayer()
  welcomeFrame.Visible = true
  welcomeMain.Position = UDim2.new(-0.6, 0, 0, 0)
  welcomeChangelog.Position = UDim2.new(1, 5, 0, 20)
  welcomeBottom.Position = UDim2.new(0.6, 0, 1, 0)

  welcomeFrame.BackgroundTransparency = 1
  welcomeOutline.ImageTransparency = 1

  wait(2)

  for i = 1, 0, -0.1 do
    welcomeFrame.BackgroundTransparency = i
    welcomeOutline.ImageTransparency = i
    wait()
  end

  welcomeMain:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)
  welcomeChangelog:TweenPosition(UDim2.new(0.6, 5, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)
  welcomeBottom:TweenPosition(UDim2.new(0.6, 0, 1, -50), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)

  wait(0.5)

  welcomeProgress:WaitForChild('Progress1').TextColor3 = Color3.new(1, 1, 1)
  API = f.fetchAPI()
  welcomeProgress:WaitForChild('Progress2').TextColor3 = Color3.new(1, 1, 1)
  RMD = f.fetchRMD()
  welcomeProgress:WaitForChild('Progress3').TextColor3 = Color3.new(1, 1, 1)
  wait(0.25)
  welcomeProgress:WaitForChild('Progress4').TextColor3 = Color3.new(1, 1, 1)
  rightClickContext = ContextMenu.new()
  f.indexNodes()
  explorerTree:TreeUpdate()
  wait(0.25)
  welcomeProgress:WaitForChild('Progress5').TextColor3 = Color3.new(1, 1, 1)

  -- Attach explorer and properties to right content pane then launch
  explorerTree:Refresh()
  f.addToPane(explorerPanel, 'Right')
  f.addToPane(propertiesPanel, 'Right')
  f.resizePaneItem(propertiesPanel, 'Right', 0.5)

  contentL:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)
  contentR:TweenPosition(UDim2.new(1, -explorerSettings.RPaneWidth, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart,
                         0.5, true)

  wait(2)

  welcomeFrame:TweenPosition(UDim2.new(0.5, -250, 0, -350), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)
end

mouse.Move:connect(function()
  -- if mouseWindow == nil then return end
  local x, y = mouse.X, mouse.Y

  if x <= 50 then
    setPane = 'Left'
  elseif x >= gui.AbsoluteSize.X - 50 then
    setPane = 'Right'
  else
    setPane = 'None'
  end
end)

explorerPanel = f.newExplorer()
propertiesPanel = f.newProperties()

for category, _ in pairs(categoryOrder) do propertiesTree.Expanded['CAT:' .. category] = true end

propertiesTree.Expanded['CAT:Surface Inputs'] = false
propertiesTree.Expanded['CAT:Surface'] = false

welcomePlayer()

for i, v in pairs(nodes[workspace]) do print(type(i)) end

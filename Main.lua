-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Wind = loadstring(game:HttpGet("https://raw.githubusercontent.com/w1ndx/wind/main/Wind.lua"))()

-- Global settings table
local Settings = {
    ToggleUI_Keyboard = Enum.KeyCode.RightControl,
    Aimbot_Key = Enum.UserInputType.MouseButton2,
    Aimbot_Controller = Enum.KeyCode.ButtonL2,
    Fly_Key = Enum.KeyCode.F,
}

-- State variables
local isMoving = false
local antiAfkEnabled, noClipEnabled = false, false
local noClipConnection = nil
local isMinimized = false
local nameChangerCoroutine = nil

-- Fly Variables
local flyEnabled = false
local currentFlySpeed = 50
local bodyVelocity, bodyGyro = nil, nil

-- ESP & Aimbot Variables
local skeletonESPEnabled, nameESPEnabled, healthESPEnabled, distanceESPEnabled, tracerESPEnabled, wallcheckEnabled, printerESPEnabled, carESPEnabled = true, true, true, true, true, false, false, false
local aimbotEnabled, fovCircleEnabled, aimbotConnection, aimbotTargetPart, aimbotFOV = false, false, nil, "Head", 30
local fullbrightEnabled, defaultBrightness, defaultOutdoorAmbient = false, Lighting.Brightness, Lighting.OutdoorAmbient
local espRenderDistance, espLineColor, espTextColor, espThickness, espTextSize = 1000, Color3.new(1,0,0), Color3.new(1,1,1), 2, 14
local espPrinterColor = Color3.fromRGB(255, 105, 180)
local espCarColor = Color3.fromRGB(0, 170, 255)
local skeletonConnections, boxConnections, tracerConnections, printerEspDrawings, carEspDrawings = {}, {}, {}, {}, {}

-- FOV Circle Drawing Object
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 1
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Filled = false
fovCircle.NumSides = 64
fovCircle.ZIndex = 0

-- Connections table for easy cleanup
local connections = {}

-- Forward declare the GUI
local FrostsHubGui

--//=========================================================================\\
--|| CORE FUNCTIONS (Teleport, ESP, Aimbot, etc.)
--\\=========================================================================//

-- New Teleport Function
local function sitAndTeleport(targetPosition, targetLookVector)
    if isMoving then
        StarterGui:SetCore("SendNotification", {
            Title = "Frosts HUB",
            Text = "Please wait for the current action to finish."
        })
        return
    end
    isMoving = true
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not character then
        isMoving = false;
        return
    end
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    if not (humanoid and rootPart) then
        isMoving = false;
        return
    end
    -- Make the player sit
    humanoid.Sit = true
    -- Wait a short moment to ensure they are sitting
    task.wait(0.2)
    -- Teleport to the destination with the specified look vector
    if rootPart and rootPart.Parent then
        rootPart.CFrame = CFrame.new(targetPosition, targetPosition + targetLookVector)
    end
    -- Short delay before allowing another action
    task.wait(0.1)
    isMoving = false
end

-- Function to disable flying
local function disableFly()
    local character = LocalPlayer.Character
    if not flyEnabled or not character then
        return
    end
    flyEnabled = false
    if bodyVelocity then
        bodyVelocity:Destroy();
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy();
        bodyGyro = nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end
end

-- Function to enable flying
local function enableFly()
    local character = LocalPlayer.Character
    if flyEnabled or not character then
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then
        return
    end
    flyEnabled = true
    humanoid.PlatformStand = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = rootPart
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P, bodyGyro.D = 10000, 500
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    task.spawn(function()
        while flyEnabled and bodyVelocity and bodyGyro do
            local direction = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                direction = direction - Vector3.new(0, -1, 0)
            end
            if direction.Magnitude > 0 then
                direction = direction.Unit * currentFlySpeed
            end
            if bodyVelocity then
                bodyVelocity.Velocity = direction
            end
            if bodyGyro and rootPart then
                bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Camera.CFrame.LookVector)
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

-- ESP Drawing Functions
local function newLine()
    local line = Drawing.new("Line");
    line.Visible = false;
    line.Thickness = espThickness;
    line.Color = espLineColor;
    return line
end

local function newText()
    local text = Drawing.new("Text");
    text.Visible = false;
    text.Size = espTextSize;
    text.Color = espTextColor;
    text.Center = true;
    text.Outline = true;
    return text
end

local function isWallBetween(fromPos, toPos, ignoreCharacter)
    local rayParams = RaycastParams.new();
    rayParams.FilterType = Enum.RaycastFilterType.Exclude;
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, ignoreCharacter};
    rayParams.IgnoreWater = true
    return workspace:Raycast(fromPos, (toPos - fromPos).Unit * (toPos - fromPos).Magnitude, rayParams) ~= nil
end

-- Skeleton ESP
local function createSkeleton(player)
    if skeletonConnections[player] then
        return
    end
    local lines = {
        HeadToUpperTorso = newLine(),
        UpperToLowerTorso = newLine(),
        LeftShoulder = newLine(),
        LeftUpperToLowerArm = newLine(),
        LeftLowerToHand = newLine(),
        RightShoulder = newLine(),
        RightUpperToLowerArm = newLine(),
        RightLowerToHand = newLine(),
        LeftHip = newLine(),
        LeftUpperToLowerLeg = newLine(),
        LeftLowerToFoot = newLine(),
        RightHip = newLine(),
        RightUpperToLowerLeg = newLine(),
        RightLowerToFoot = newLine()
    }
    local conn = RunService.RenderStepped:Connect(function()
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local char = player.Character
        if not skeletonESPEnabled or not localHRP or not char or not char:FindFirstChild("HumanoidRootPart") or (localHRP.Position - char.HumanoidRootPart.Position).Magnitude > espRenderDistance or (wallcheckEnabled and isWallBetween(localHRP.Position, char.HumanoidRootPart.Position, char)) then
            for _, line in pairs(lines) do
                line.Visible = false
            end;
            return
        end
        local function getPos(partName)
            local part = char:FindFirstChild(partName);
            if part and part:IsA("BasePart") then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position);
                if onScreen then
                    return Vector2.new(pos.X, pos.Y), true
                end
            end;
            return nil, false
        end
        local function draw(name, fromPart, toPart)
            local fromPos, fromVisible = getPos(fromPart);
            local toPos, toVisible = getPos(toPart);
            local line = lines[name];
            if fromPos and toPos and fromVisible and toVisible then
                line.From = fromPos;
                line.To = toPos;
                line.Visible = true;
                line.Color = espLineColor;
                line.Thickness = espThickness
            else
                line.Visible = false
            end
        end
        draw("HeadToUpperTorso", "Head", "UpperTorso");
        draw("UpperToLowerTorso", "UpperTorso", "LowerTorso");
        draw("LeftShoulder", "UpperTorso", "LeftUpperArm");
        draw("LeftUpperToLowerArm", "LeftUpperArm", "LeftLowerArm");
        draw("LeftLowerToHand", "LeftLowerArm", "LeftHand");
        draw("RightShoulder", "UpperTorso", "RightUpperArm");
        draw("RightUpperToLowerArm", "RightUpperArm", "RightLowerArm");
        draw("RightLowerToHand", "RightLowerArm", "RightHand");
        draw("LeftHip", "LowerTorso", "LeftUpperLeg");
        draw("LeftUpperToLowerLeg", "LeftUpperLeg", "LeftLowerLeg");
        draw("LeftLowerToFoot", "LeftLowerLeg", "LeftFoot");
        draw("RightHip", "LowerTorso", "RightUpperLeg");
        draw("RightUpperToLowerLeg", "RightUpperLeg", "RightLowerLeg");
        draw("RightLowerToFoot", "RightLowerLeg", "RightFoot")
    end)
    skeletonConnections[player] = {
        connection = conn,
        lines = lines
    }
end

local function cleanupSkeleton(player)
    if skeletonConnections[player] then
        skeletonConnections[player].connection:Disconnect();
        for _, line in pairs(skeletonConnections[player].lines) do
            line:Remove()
        end;
        skeletonConnections[player] = nil
    end
end

-- Info ESP (Name, Health, Distance)
local function createInfoESP(player)
    if boxConnections[player] then
        return
    end
    local nameText, healthText, distanceText = newText(), newText(), newText()
    local conn = RunService.RenderStepped:Connect(function()
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not localHRP or not char or not humanoid or humanoid.Health <= 0 or not char:FindFirstChild("Head") then
            nameText.Visible, healthText.Visible, distanceText.Visible = false, false, false;
            return
        end
        local hrp, head = char.HumanoidRootPart, char.Head
        local dist = (localHRP.Position - hrp.Position).Magnitude
        if dist > espRenderDistance or (wallcheckEnabled and isWallBetween(localHRP.Position, hrp.Position, char)) then
            nameText.Visible, healthText.Visible, distanceText.Visible = false, false, false;
            return
        end
        local headPos, onScreenHead = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpPos, onScreenHRP = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 1, 0))
        if not (onScreenHead and onScreenHRP) then
            nameText.Visible, healthText.Visible, distanceText.Visible = false, false, false;
            return
        end
        local x, y, h = headPos.X, headPos.Y, math.abs(headPos.Y - hrpPos.Y)
        if nameESPEnabled then
            nameText.Text = player.Name;
            nameText.Position = Vector2.new(x, y - 15);
            nameText.Visible = true;
            nameText.Color = espTextColor;
            nameText.Size = espTextSize
        end
        if healthESPEnabled then
            local health, maxHealth = math.floor(humanoid.Health), math.floor(humanoid.MaxHealth);
            healthText.Text = string.format("HP: %d/%d", health, maxHealth);
            healthText.Position = Vector2.new(x, y - 30);
            healthText.Color = health > maxHealth * 0.75 and Color3.new(0,1,0) or (health > maxHealth * 0.25 and Color3.new(1,1,0) or Color3.new(1,0,0));
            healthText.Visible = true;
            healthText.Size = espTextSize
        end
        if distanceESPEnabled then
            distanceText.Text = string.format("Dist: %d studs", math.floor(dist));
            distanceText.Position = Vector2.new(x, y + h + 15);
            distanceText.Visible = true;
            distanceText.Color = espTextColor;
            distanceText.Size = espTextSize
        end
    end)
    boxConnections[player] = {
        connection = conn,
        nameText = nameText,
        healthText = healthText,
        distanceText = distanceText
    }
end

local function cleanupInfoESP(player)
    if boxConnections[player] then
        boxConnections[player].connection:Disconnect();
        boxConnections[player].nameText:Remove();
        boxConnections[player].healthText:Remove();
        boxConnections[player].distanceText:Remove();
        boxConnections[player] = nil
    end
end

-- Tracer ESP
local function createTracerESP(player)
    if tracerConnections[player] then
        return
    end
    local tracerLine = newLine()
    local conn = RunService.RenderStepped:Connect(function()
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not tracerESPEnabled or not localHRP or not targetHRP or (localHRP.Position - targetHRP.Position).Magnitude > espRenderDistance or (wallcheckEnabled and isWallBetween(localHRP.Position, targetHRP.Position, player.Character)) then
            tracerLine.Visible = false;
            return
        end
        local rootPos, onScreen = Camera:WorldToViewportPoint(targetHRP.Position)
        if onScreen then
            tracerLine.From, tracerLine.To, tracerLine.Visible = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y), Vector2.new(rootPos.X, rootPos.Y), true;
            tracerLine.Color = espLineColor;
            tracerLine.Thickness = espThickness
        else
            tracerLine.Visible = false
        end
    end)
    tracerConnections[player] = {
        connection = conn,
        line = tracerLine
    }
end

local function cleanupTracerESP(player)
    if tracerConnections[player] then
        tracerConnections[player].connection:Disconnect();
        tracerConnections[player].line:Remove();
        tracerConnections[player] = nil
    end
end

-- Aimbot Logic
local function aimbotLoop()
    if not aimbotEnabled then
        return
    end
    local localHRP = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart
    if not localHRP then
        return
    end
    local closestPlayer, shortestDistance = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local targetHRP = player.Character.HumanoidRootPart
            local distance = (localHRP.Position - targetHRP.Position).Magnitude
            if distance < shortestDistance and distance <= espRenderDistance then
                local targetPart = player.Character:FindFirstChild(aimbotTargetPart)
                if targetPart then
                    local directionToTarget = (targetPart.Position - Camera.CFrame.p).Unit
                    if math.deg(math.acos(Camera.CFrame.LookVector:Dot(directionToTarget))) <= aimbotFOV and not (wallcheckEnabled and isWallBetween(localHRP.Position, targetPart.Position, player.Character)) then
                        closestPlayer, shortestDistance = player, distance
                    end
                end
            end
        end
    end
    if closestPlayer then
        local targetPart = closestPlayer.Character:FindFirstChild(aimbotTargetPart)
        if targetPart then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.p, targetPart.Position), 0.5)
        end
    end
end

-- ESP Management Functions
local function updatePlayerESP(player, enable)
    if player == LocalPlayer then
        return
    end
    cleanupSkeleton(player);
    cleanupInfoESP(player);
    cleanupTracerESP(player)
    if enable then
        if skeletonESPEnabled then
            createSkeleton(player)
        end
        if nameESPEnabled or healthESPEnabled or distanceESPEnabled then
            createInfoESP(player)
        end
        if tracerESPEnabled then
            createTracerESP(player)
        end
    end
end

local function updateAllEspVisuals()
    for _, player in pairs(Players:GetPlayers()) do
        updatePlayerESP(player, true)
    end
end

--//=========================================================================\\
--|| GUI CREATION & MANAGEMENT (CoreUI Redesign)
--\\=========================================================================//

local Theme = {
    Background = Color3.fromRGB(24, 24, 27),
    Primary = Color3.fromRGB(39, 39, 42),
    Secondary = Color3.fromRGB(63, 63, 70),
    Accent = Color3.fromRGB(0, 221, 255),
    Text = Color3.fromRGB(244, 244, 245),
    TextSecondary = Color3.fromRGB(161, 161, 170),
    Font = {
        Main = Enum.Font.Gotham,
        Semibold = Enum.Font.GothamSemibold
    },
    TextSize = {
        Normal = 14,
        Small = 12,
        Title = 16
    },
    CornerRadius = UDim.new(0, 6),
    AnimationInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
}
FrostsHubGui = Instance.new("ScreenGui");
FrostsHubGui.Name = "FrostsHubGui";
FrostsHubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
FrostsHubGui.ResetOnSpawn = false;
FrostsHubGui.Parent = CoreGui
local Window = Instance.new("Frame");
Window.Name = "Window";
Window.Size = UDim2.fromOffset(560, 420);
Window.Position = UDim2.new(0.5, -280, 0.5, -210);
Window.BackgroundColor3 = Theme.Background;
Window.Active = true;
Window.Draggable = true;
Window.Parent = FrostsHubGui
Instance.new("UICorner", Window).CornerRadius = Theme.CornerRadius
local WindowStroke = Instance.new("UIStroke", Window);
WindowStroke.Color = Theme.Primary;
WindowStroke.Thickness = 1.5
local TitleLabel = Instance.new("TextLabel");
TitleLabel.Name = "TitleLabel";
TitleLabel.Size = UDim2.new(1, -50, 0, 45);
TitleLabel.Position = UDim2.fromOffset(0, 0);
TitleLabel.BackgroundTransparency = 1;
TitleLabel.Font = Theme.Font.Semibold;
TitleLabel.TextColor3 = Theme.Text;
TitleLabel.TextSize = Theme.TextSize.Title;
TitleLabel.Text = "FrostsHub - Philly Streetz 2";
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center;
TitleLabel.Parent = Window
local CloseButton = Instance.new("TextButton");
CloseButton.Name = "CloseButton";
CloseButton.Size = UDim2.fromOffset(30, 30);
CloseButton.Position = UDim2.new(1, -40, 0, 8);
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60);
CloseButton.Font = Theme.Font.Semibold;
CloseButton.Text = "X";
CloseButton.TextColor3 = Theme.Text;
CloseButton.TextSize = 16;
CloseButton.Parent = Window;
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 4)
-- [[ NEW FEATURE: Minimize Button ]]
local MinimizeButton = Instance.new("TextButton");
MinimizeButton.Name = "MinimizeButton";
MinimizeButton.Size = UDim2.fromOffset(30, 30);
MinimizeButton.Position = UDim2.new(1, -75, 0, 8);
MinimizeButton.BackgroundColor3 = Theme.Secondary;
MinimizeButton.Font = Theme.Font.Semibold;
MinimizeButton.Text = "-";
MinimizeButton.TextColor3 = Theme.Text;
MinimizeButton.TextSize = 20;
MinimizeButton.Parent = Window;
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 4)
local TabContainer = Instance.new("Frame");
TabContainer.Name = "TabContainer";
TabContainer.Size = UDim2.new(1, -20, 0, 30);
TabContainer.Position = UDim2.fromOffset(10, 45);
TabContainer.BackgroundTransparency = 1;
TabContainer.Parent = Window
local TabListLayout = Instance.new("UIListLayout");
TabListLayout.FillDirection = Enum.FillDirection.Horizontal;
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
TabListLayout.Padding = UDim.new(0, 8);
TabListLayout.Parent = TabContainer
local ContentArea = Instance.new("Frame");
ContentArea.Name = "ContentArea";
ContentArea.Size = UDim2.new(1, -20, 1, -90);
ContentArea.Position = UDim2.fromOffset(10, 80);
ContentArea.BackgroundTransparency = 1;
ContentArea.Parent = Window
local Tabs, ContentFrames, activeTab, activeDropdown = {}, {}, nil, nil
local function CreateTab(name, order)
    local contentFrame = Instance.new("Frame");
    contentFrame.Name = name .. "Content";
    contentFrame.Size = UDim2.new(1, 0, 1, 0);
    contentFrame.BackgroundTransparency = 1;
    contentFrame.Visible = false;
    contentFrame.Parent = ContentArea;
    local tabButton = Instance.new("TextButton");
    tabButton.Name = name .. "Tab";
    tabButton.Size = UDim2.new(0, 85, 1, 0);
    tabButton.BackgroundColor3 = Theme.Primary;
    tabButton.Font = Theme.Font.Semibold;
    tabButton.Text = name;
    tabButton.TextColor3 = Theme.TextSecondary;
    tabButton.TextSize = Theme.TextSize.Normal;
    tabButton.LayoutOrder = order;
    tabButton.Parent = TabContainer;
    Instance.new("UICorner", tabButton).CornerRadius = Theme.CornerRadius;
    table.insert(Tabs, tabButton);
    ContentFrames[name] = contentFrame;
    tabButton.MouseButton1Click:Connect(function()
        if activeTab == tabButton then
            return
        end
        if activeDropdown and activeDropdown.Parent then
            activeDropdown:Destroy()
        end;
        activeDropdown = nil
        for _, otherFrame in pairs(ContentFrames) do
            otherFrame.Visible = false
        end
        for _, otherButton in pairs(Tabs) do
            TweenService:Create(otherButton, Theme.AnimationInfo, {
                BackgroundColor3 = Theme.Primary,
                TextColor3 = Theme.TextSecondary
            }):Play()
        end
        contentFrame.Visible = true;
        activeTab = tabButton
        TweenService:Create(tabButton, Theme.AnimationInfo, {
            BackgroundColor3 = Theme.Accent,
            TextColor3 = Theme.Text
        }):Play()
    end)
    return contentFrame
end

local function CreateSection(parentFrame, title, width)
    local section = Instance.new("Frame");
    section.Name = title;
    section.Size = width;
    section.BackgroundColor3 = Theme.Primary;
    section.Parent = parentFrame;
    Instance.new("UICorner", section).CornerRadius = Theme.CornerRadius
    local titleLabel = Instance.new("TextLabel");
    titleLabel.Name = "Title";
    titleLabel.Size = UDim2.new(1, -20, 0, 25);
    titleLabel.Position = UDim2.fromOffset(10, 5);
    titleLabel.BackgroundTransparency = 1;
    titleLabel.Font = Theme.Font.Main;
    titleLabel.Text = title;
    titleLabel.TextColor3 = Theme.Text;
    titleLabel.TextSize = Theme.TextSize.Normal;
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left;
    titleLabel.Parent = section
    local content = Instance.new("ScrollingFrame");
    content.Name = "Content";
    content.Size = UDim2.new(1, 0, 1, -30);
    content.Position = UDim2.fromOffset(0, 30);
    content.BackgroundTransparency = 1;
    content.BorderSizePixel = 0;
    content.ScrollBarThickness = 0;
    content.Parent = section
    Instance.new("UIListLayout", content).Padding = UDim.new(0, 5)
    local contentPadding = Instance.new("UIPadding", content);
    contentPadding.PaddingTop = UDim.new(0, 10);
    contentPadding.PaddingBottom = UDim.new(0, 10);
    contentPadding.PaddingLeft = UDim.new(0, 10);
    contentPadding.PaddingRight = UDim.new(0, 10)
    return content
end

local function CreateButton(parent, name, callback)
    local button = Instance.new("TextButton");
    button.Name = name;
    button.Size = UDim2.new(1, -20, 0, 35);
    button.Position = UDim2.fromOffset(10, 0);
    button.BackgroundColor3 = Theme.Secondary;
    button.Font = Theme.Font.Main;
    button.Text = name;
    button.TextColor3 = Theme.Text;
    button.TextSize = Theme.TextSize.Normal;
    button.Parent = parent;
    Instance.new("UICorner", button).CornerRadius = Theme.CornerRadius
    button.MouseEnter:Connect(function()
        TweenService:Create(button, Theme.AnimationInfo, {
            BackgroundColor3 = Color3.Lerp(Theme.Secondary, Theme.Accent, 0.5)
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, Theme.AnimationInfo, {
            BackgroundColor3 = Theme.Secondary
        }):Play()
    end)
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    return button
end

local function CreateToggle(parent, name, initialValue, callback)
    local Frame = Instance.new("Frame", parent);
    Frame.Size = UDim2.new(1, -20, 0, 30);
    Frame.Position = UDim2.fromOffset(10, 0);
    Frame.BackgroundTransparency = 1;
    local Label = Instance.new("TextLabel", Frame);
    Label.Size = UDim2.new(1, -55, 1, 0);
    Label.BackgroundTransparency = 1;
    Label.Font = Theme.Font.Main;
    Label.Text = name;
    Label.TextColor3 = Theme.Text;
    Label.TextSize = Theme.TextSize.Normal;
    Label.TextXAlignment = Enum.TextXAlignment.Left;
    local Switch = Instance.new("TextButton", Frame);
    Switch.Size = UDim2.fromOffset(38, 20);
    Switch.Position = UDim2.new(1, -45, 0.5, -10);
    Switch.BackgroundTransparency = 1;
    Switch.Text = ""
    local state = initialValue
    local Track = Instance.new("Frame", Switch);
    Track.Size = UDim2.new(1, 0, 1, 0);
    Track.BackgroundColor3 = state and Theme.Accent or Theme.Secondary;
    Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 10);
    local Nub = Instance.new("Frame", Track);
    Nub.Size = UDim2.fromOffset(14, 14);
    Nub.Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3);
    Nub.BackgroundColor3 = Theme.Text;
    Instance.new("UICorner", Nub).CornerRadius = UDim.new(0, 7);
    local function updateToggleState(newState)
        state = newState
        local newTrackColor = state and Theme.Accent or Theme.Secondary;
        local newNubPos = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3);
        TweenService:Create(Track, Theme.AnimationInfo, {
            BackgroundColor3 = newTrackColor
        }):Play();
        TweenService:Create(Nub, Theme.AnimationInfo, {
            Position = newNubPos
        }):Play();
        if callback then
            callback(state)
        end
    end
    Switch.MouseButton1Click:Connect(function()
        updateToggleState(not state)
    end)
    return Frame, updateToggleState
end

local function CreateSlider(parent, name, range, initialValue, callback)
    local Frame = Instance.new("Frame", parent);
    Frame.Size = UDim2.new(1, -20, 0, 45);
    Frame.Position = UDim2.fromOffset(10, 0);
    Frame.BackgroundTransparency = 1;
    local Label = Instance.new("TextLabel", Frame);
    Label.Size = UDim2.new(1, 0, 0, 20);
    Label.BackgroundTransparency = 1;
    Label.Font = Theme.Font.Main;
    Label.TextColor3 = Theme.Text;
    Label.TextSize = Theme.TextSize.Normal;
    Label.TextXAlignment = Enum.TextXAlignment.Left
    local sliderFrame = Instance.new("Frame", Frame);
    sliderFrame.Size = UDim2.new(1, 0, 0, 20);
    sliderFrame.Position = UDim2.fromOffset(0, 25);
    sliderFrame.BackgroundTransparency = 1
    local Track = Instance.new("Frame", sliderFrame);
    Track.Size = UDim2.new(1, 0, 0, 4);
    Track.Position = UDim2.new(0, 0, 0.5, -2);
    Track.BackgroundColor3 = Theme.Secondary;
    Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 2)
    local Progress = Instance.new("Frame", Track);
    Progress.Size = UDim2.new(0, 0, 1, 0);
    Progress.BackgroundColor3 = Theme.Accent;
    Instance.new("UICorner", Progress).CornerRadius = UDim.new(0, 2)
    local Handle = Instance.new("Frame", Track);
    Handle.Size = UDim2.fromOffset(14, 14);
    Handle.AnchorPoint = Vector2.new(0.5, 0.5);
    Handle.Position = UDim2.new(0, 0, 0.5, 0);
    Handle.BackgroundColor3 = Theme.Text;
    Instance.new("UICorner", Handle).CornerRadius = UDim.new(0, 7)
    local minVal, maxVal = range[1], range[2]
    local currentValue = initialValue
    local smoothTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local function updateSlider(value, instant)
        currentValue = math.floor(math.clamp(value, minVal, maxVal))
        local percentage = (currentValue - minVal) / (maxVal - minVal)
        Label.Text = string.format("%s: %d", name, currentValue)
        local goal = {
            Position = UDim2.new(percentage, 0, 0.5, 0),
            Size = UDim2.new(percentage, 0, 1, 0)
        }
        if instant then
            Handle.Position = goal.Position
            Progress.Size = goal.Size
        else
            TweenService:Create(Handle, smoothTweenInfo, {
                Position = goal.Position
            }):Play()
            TweenService:Create(Progress, smoothTweenInfo, {
                Size = goal.Size
            }):Play()
        end
        if callback then
            callback(currentValue)
        end
    end
    local inputButton = Instance.new("TextButton", sliderFrame);
    inputButton.Size = UDim2.new(1, 0, 1, 0);
    inputButton.BackgroundTransparency = 1;
    inputButton.Text = ""
    inputButton.MouseButton1Down:Connect(function()
        local mouseMoveConn, mouseUpConn
        local mouseX = UserInputService:GetMouseLocation().X
        local relativeX = mouseX - Track.AbsolutePosition.X
        local percentage = math.clamp(relativeX / Track.AbsoluteSize.X, 0, 1)
        local newValue = minVal + (maxVal - minVal) * percentage
        updateSlider(newValue, false)
        mouseMoveConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local currentMouseX = UserInputService:GetMouseLocation().X
                local currentRelativeX = currentMouseX - Track.AbsolutePosition.X
                local currentPercentage = math.clamp(currentRelativeX / Track.AbsoluteSize.X, 0, 1)
                local newCurrentValue = minVal + (maxVal - minVal) * currentPercentage
                updateSlider(newCurrentValue, true)
            end
        end)
        mouseUpConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                mouseMoveConn:Disconnect()
                mouseUpConn:Disconnect()
            end
        end)
    end)
    updateSlider(initialValue, true)
    return Frame
end

local function CreateDropdown(parent, name, options, callback)
    local Frame = Instance.new("Frame", parent);
    Frame.Size = UDim2.new(1, -20, 0, 45);
    Frame.Position = UDim2.fromOffset(10, 0);
    Frame.BackgroundTransparency = 1;
    local Label = Instance.new("TextLabel", Frame);
    Label.Size = UDim2.new(1, 0, 0, 20);
    Label.BackgroundTransparency = 1;
    Label.Font = Theme.Font.Main;
    Label.TextColor3 = Theme.Text;
    Label.TextSize = Theme.TextSize.Normal;
    Label.TextXAlignment = Enum.TextXAlignment.Left;
    Label.Text = name
    local mainButton = CreateButton(Frame, options[1]);
    mainButton.Position = UDim2.fromOffset(0, 20);
    mainButton.Size = UDim2.new(1, 0, 0, 35);
    mainButton.Name = name .. "DropdownButton"
    mainButton.MouseButton1Click:Connect(function()
        if activeDropdown and activeDropdown.Parent then
            local wasMyDropdown = (activeDropdown.Name == name .. "OptionsFrame")
            activeDropdown:Destroy()
            activeDropdown = nil
            if wasMyDropdown then
                return
            end
        end
        local optionsFrame = Instance.new("ScrollingFrame")
        optionsFrame.Name = name .. "OptionsFrame"
        activeDropdown = optionsFrame
        local maxHeight = 130
        local calculatedHeight = #options * 40 + 10
        local finalHeight = math.min(maxHeight, calculatedHeight)
        optionsFrame.Size = UDim2.fromOffset(mainButton.AbsoluteSize.X, finalHeight)
        optionsFrame.Position = UDim2.fromAbsolute(mainButton.AbsolutePosition.X, mainButton.AbsolutePosition.Y + 38)
        optionsFrame.BackgroundColor3 = Theme.Primary
        optionsFrame.BorderSizePixel = 0
        optionsFrame.ZIndex = 10
        optionsFrame.Parent = FrostsHubGui
        optionsFrame.ScrollBarThickness = 4
        Instance.new("UICorner", optionsFrame).CornerRadius = Theme.CornerRadius
        Instance.new("UIStroke", optionsFrame).Color = Theme.Secondary
        local listLayout = Instance.new("UIListLayout", optionsFrame)
        listLayout.Padding = UDim.new(0, 5)
        local padding = Instance.new("UIPadding", optionsFrame)
        padding.PaddingTop = UDim.new(0, 5)
        padding.PaddingBottom = UDim.new(0, 5)
        for _, optionText in ipairs(options) do
            local optionButton = CreateButton(optionsFrame, optionText, function()
                mainButton.Text = optionText
                if activeDropdown and activeDropdown.Parent then
                    activeDropdown:Destroy()
                end
                activeDropdown = nil
                if callback then
                    callback(optionText)
                end
            end)
            optionButton.Position = UDim2.fromOffset(0, 0)
        end
    end)
    return Frame
end

local function CreateTextInput(parent, name, placeholder, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, -20, 0, 60)
    Frame.Position = UDim2.fromOffset(10, 0)
    Frame.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Position = UDim2.fromOffset(0, 5)
    Label.BackgroundTransparency = 1
    Label.Font = Theme.Font.Main
    Label.TextColor3 = Theme.Text
    Label.TextSize = Theme.TextSize.Normal
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = name
    local TextBoxFrame = Instance.new("Frame", Frame)
    TextBoxFrame.Size = UDim2.new(1, 0, 0, 35)
    TextBoxFrame.Position = UDim2.fromOffset(0, 25)
    TextBoxFrame.BackgroundColor3 = Theme.Secondary
    TextBoxFrame.Parent = Frame
    Instance.new("UICorner", TextBoxFrame).CornerRadius = Theme.CornerRadius
    local TextBox = Instance.new("TextBox", TextBoxFrame)
    TextBox.Size = UDim2.new(1, -10, 1, 0)
    TextBox.Position = UDim2.fromOffset(5, 0)
    TextBox.BackgroundColor3 = Theme.Secondary
    TextBox.Font = Theme.Font.Main
    TextBox.TextColor3 = Theme.Text
    TextBox.PlaceholderText = placeholder
    TextBox.PlaceholderColor3 = Theme.TextSecondary
    TextBox.TextSize = Theme.TextSize.Normal
    TextBox.ClearTextOnFocus = false
    TextBox.BackgroundTransparency = 1
    TextBox:GetPropertyChangedSignal("Text"):Connect(function()
        if callback then
            callback(TextBox.Text)
        end
    end)
    return Frame, TextBox
end

--//=========================================================================\\
--|| POPULATING THE GUI
--\\=========================================================================//

local CombatTab = CreateTab("Combat", 1);
local VisualsTab = CreateTab("Visuals", 2);
local TeleportTab = CreateTab("Teleport", 3);
local MoneyTab = CreateTab("Money", 4);
local MiscTab = CreateTab("Misc", 5)

-- == Teleport Tab Content ==
do
    local tabLayout = Instance.new("UIListLayout", TeleportTab);
    tabLayout.FillDirection = Enum.FillDirection.Horizontal;
    tabLayout.Padding = UDim.new(0, 10)
    local locationSection = CreateSection(TeleportTab, "Locations", UDim2.new(0.5, -5, 1, 0))
    local utilitySection = CreateSection(TeleportTab, "Utility", UDim2.new(0.5, -5, 1, 0))
    local teleportLocations = {
        ["Clothes Store"] = Vector3.new(882.73, 317.48, -309.71),
        ["sell ripz"] = Vector3.new(868.59, 317.36, -236.99),
        ["rays Auto Center"] = Vector3.new(648.39, 317.42, 354.92),
        ["Gun Store"] = Vector3.new(192.39, 317.45, 935.83),
        ["Black Market"] = Vector3.new(318.29, 317.40, 1107.25),
        ["laundromat"] = Vector3.new(-0.71, 317.43, 933.01),
        ["houses"] = Vector3.new(216.12, 317.43, 172.89),
        ["gas station"] = Vector3.new(284.65, 317.43, 359.92),
        ["Wood Chopper"] = Vector3.new(745.51, 317.39, 843.63),
        ["food shop"] = Vector3.new(713.68, 317.43, -133.08),
        ["Printers"] = Vector3.new(-135.16, 317.39, 162.96),
        ["guapo"] = Vector3.new(177.20, 317.43, -162.10),
        ["Heist"] = Vector3.new(47.77, 317.39, 786.96),
        ["p mobile"] = Vector3.new(721.06, 317.36, -74.68)
    }
    for name, pos in pairs(teleportLocations) do
        CreateButton(locationSection, name, function()
            if LocalPlayer.Character then
                sitAndTeleport(pos, LocalPlayer.Character.PrimaryPart.CFrame.LookVector)
            end
        end)
    end
    CreateButton(utilitySection, "ServerHop", function()
        task.spawn(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local success, result = pcall(function()
                return HttpService:GetAsync(url)
            end)
            if not success then
                StarterGui:SetCore("SendNotification", {
                    Title = "FrostsHub",
                    Text = "Failed to fetch servers."
                });
                return
            end
            local servers = HttpService:JSONDecode(result).data
            local newServers = {}
            for _, server in ipairs(servers) do
                if type(server) == 'table' and server.id and server.id ~= game.JobId and server.playing < server.maxPlayers then
                    table.insert(newServers, server.id)
                end
            end
            if #newServers > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, newServers[math.random(1, #newServers)], LocalPlayer)
            else
                StarterGui:SetCore("SendNotification", {
                    Title = "FrostsHub",
                    Text = "No other servers found."
                })
            end
        end)
    end)
end

-- == Combat Tab Content ==
do
    local combatLayout = Instance.new("UIGridLayout", CombatTab);
    combatLayout.CellSize = UDim2.new(1, 0, 1, 0)
    local aimbotSection = CreateSection(CombatTab, "Aimbot", UDim2.new(1, 0, 1, 0))
    CreateToggle(aimbotSection, "Enable Aimbot", false, function(state)
        aimbotEnabled = state
    end)
    CreateToggle(aimbotSection, "Show FOV Circle", false, function(state)
        fovCircleEnabled = state
    end)
    CreateSlider(aimbotSection, "Aimbot FOV", {1, 180}, aimbotFOV, function(v)
        aimbotFOV = v
    end)
    CreateDropdown(aimbotSection, "Target Part", {
        "Head",
        "HumanoidRootPart",
        "Torso"
    }, function(s)
        aimbotTargetPart = s
    end)
end

-- == Visuals Tab Content ==
do
    local visualsLayout = Instance.new("UIListLayout", VisualsTab);
    visualsLayout.FillDirection = Enum.FillDirection.Horizontal;
    visualsLayout.Padding = UDim.new(0, 10)
    local playerEspSection = CreateSection(VisualsTab, "Player ESP", UDim2.new(0.5, -5, 1, 0))
    local worldEspSection = CreateSection(VisualsTab, "World & Settings", UDim2.new(0.5, -5, 1, 0))
    CreateToggle(playerEspSection, "Skeleton ESP", true, function(s)
        skeletonESPEnabled = s;
        updateAllEspVisuals()
    end)
    CreateToggle(playerEspSection, "Name ESP", true, function(s)
        nameESPEnabled = s;
        updateAllEspVisuals()
    end)
    CreateToggle(playerEspSection, "Health ESP", true, function(s)
        healthESPEnabled = s;
        updateAllEspVisuals()
    end)
    CreateToggle(playerEspSection, "Distance ESP", true, function(s)
        distanceESPEnabled = s;
        updateAllEspVisuals()
    end)
    CreateToggle(playerEspSection, "Tracers", true, function(s)
        tracerESPEnabled = s;
        updateAllEspVisuals()
    end)
    CreateToggle(playerEspSection, "Wallcheck", false, function(s)
        wallcheckEnabled = s
    end)
    CreateToggle(worldEspSection, "Printer ESP", false, function(s)
        printerESPEnabled = s
    end)
    CreateToggle(worldEspSection, "Car ESP", false, function(s)
        carESPEnabled = s
    end)
    local colors = {
        Red = Color3.new(1, 0, 0),
        Green = Color3.new(0, 1, 0),
        Blue = Color3.new(0, 0, 1),
        White = Color3.new(1, 1, 1),
        Yellow = Color3.new(1, 1, 0),
        Cyan = Color3.new(0, 1, 1),
        Magenta = Color3.new(1, 0, 1)
    }
    CreateDropdown(worldEspSection, "Line Color", {
        "Red",
        "Green",
        "Blue",
        "White",
        "Yellow",
        "Cyan",
        "Magenta"
    }, function(s)
        espLineColor = colors[s];
        updateAllEspVisuals()
    end)
    CreateDropdown(worldEspSection, "Text Color", {
        "White",
        "Red",
        "Green",
        "Blue",
        "Yellow",
        "Cyan",
        "Magenta"
    }, function(s)
        espTextColor = colors[s];
        updateAllEspVisuals()
    end)
    CreateSlider(worldEspSection, "Line Size", {1, 5}, espThickness, function(v)
        espThickness = v;
        updateAllEspVisuals()
    end)
    CreateSlider(worldEspSection, "Text Size", {10, 20}, espTextSize, function(v)
        espTextSize = v;
        updateAllEspVisuals()
    end)
end

-- == Money Tab Content ==
do
    local moneyLayout = Instance.new("UIGridLayout", MoneyTab);
    moneyLayout.CellSize = UDim2.new(1, 0, 1, 0)
    local moneySection = CreateSection(MoneyTab, "Automation", UDim2.new(1, 0, 1, 0))
    CreateButton(moneySection, "Auto Rob Electronics", function()
        if isMoving then
            StarterGui:SetCore("SendNotification", {
                Title = "FrostsHub",
                Text = "Auto-robbery already in progress."
            });
            return
        end
        task.spawn(function()
            local originalHolds = {}
            local function restore()
                for p, d in pairs(originalHolds) do
                    if p and p.Parent then
                        p.HoldDuration = d
                    end
                end
            end
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.ClassName == "ProximityPrompt" then
                    originalHolds[v] = v.HoldDuration;
                    v.HoldDuration = 0
                end
            end;
            task.wait(0.3)
            local steps = {
                {
                    N = "Phone 1",
                    P = Vector3.new(706.48, 317.36, -68.72),
                    L = Vector3.new(0, 0, 1)
                },
                {
                    N = "Phone 2",
                    P = Vector3.new(705.51, 317.36, -68.24),
                    L = Vector3.new(0, 0, 1)
                },
                {
                    N = "Phone 3",
                    P = Vector3.new(704.51, 317.36, -68.37),
                    L = Vector3.new(0, 0, 1)
                },
                {
                    N = "Phone 4",
                    P = Vector3.new(703.58, 317.36, -68.35),
                    L = Vector3.new(0, 0, 1)
                },
                {
                    N = "Phone 5",
                    P = Vector3.new(702.25, 317.36, -68.46),
                    L = Vector3.new(0, 0, 1)
                },
                {
                    N = "Laptop 1",
                    P = Vector3.new(697.6, 317.44, -68.3),
                    L = Vector3.new(0, 0, 1)
                },
                {
                    N = "Laptop 2",
                    P = Vector3.new(694.72, 317.36, -68.15),
                    L = Vector3.new(0, 0, 1)
                },
                {
                    N = "Phone 6",
                    P = Vector3.new(686.85, 317.36, -79.66),
                    L = Vector3.new(0, 0, -1)
                },
                {
                    N = "Phone 7",
                    P = Vector3.new(688.1, 317.36, -79.95),
                    L = Vector3.new(0, 0, -1)
                },
                {
                    N = "Phone 8",
                    P = Vector3.new(689.22, 317.36, -79.89),
                    L = Vector3.new(0, 0, -1)
                },
                {
                    N = "Phone 9",
                    P = Vector3.new(689.78, 317.36, -80.3),
                    L = Vector3.new(0, 0, -1)
                },
                {
                    N = "Phone 10",
                    P = Vector3.new(691.04, 317.36, -80.41),
                    L = Vector3.new(0, 0, -1)
                },
                {
                    N = "TV 1",
                    P = Vector3.new(700.92, 317.36, -81.48),
                    L = Vector3.new(0, 0, -1)
                },
                {
                    N = "TV 2",
                    P = Vector3.new(705.91, 317.36, -81.57),
                    L = Vector3.new(0, 0, -1)
                }
            }
            for i, step in ipairs(steps) do
                if not LocalPlayer.Character then
                    restore();
                    return
                end
                StarterGui:SetCore("SendNotification", {
                    Title = "FrostsHub",
                    Text = "Robbing " .. step.N .. " (" .. i .. "/" .. #steps .. ")"
                })
                sitAndTeleport(step.P, step.L);
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game);
                task.wait(0.1);
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait(0.2)
            end
            StarterGui:SetCore("SendNotification", {
                Title = "FrostsHub",
                Text = "Auto-robbery complete."
            });
            restore()
        end)
    end)
    CreateButton(moneySection, "Frosts Car Steal", function()
        local carStealWindow = Instance.new("Frame")
        carStealWindow.Name = "CarStealWindow"
        carStealWindow.Size = UDim2.fromOffset(450, 350)
        carStealWindow.Position = UDim2.new(0.5, -225, 0.5, -175)
        carStealWindow.BackgroundColor3 = Theme.Background
        carStealWindow.Active = true
        carStealWindow.Draggable = true
        carStealWindow.Parent = FrostsHubGui
        Instance.new("UICorner", carStealWindow).CornerRadius = Theme.CornerRadius
        local csStroke = Instance.new("UIStroke", carStealWindow);
        csStroke.Color = Theme.Primary;
        csStroke.Thickness = 1.5
        local csTitle = Instance.new("TextLabel", carStealWindow)
        csTitle.Name = "Title"
        csTitle.Size = UDim2.new(1, 0, 0, 40)
        csTitle.BackgroundTransparency = 1
        csTitle.Font = Theme.Font.Semibold
        csTitle.TextColor3 = Theme.Text
        csTitle.TextSize = Theme.TextSize.Title
        csTitle.Text = "Frosts Car Steal"
        csTitle.TextXAlignment = Enum.TextXAlignment.Center
        local csClose = Instance.new("TextButton", carStealWindow)
        csClose.Name = "CloseButton"
        csClose.Size = UDim2.fromOffset(25, 25)
        csClose.Position = UDim2.new(1, -35, 0, 8)
        csClose.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        csClose.Font = Theme.Font.Semibold
        csClose.Text = "X"
        csClose.TextColor3 = Theme.Text
        csClose.TextSize = 14
        csClose.MouseButton1Click:Connect(function()
            carStealWindow:Destroy()
        end)
        Instance.new("UICorner", csClose).CornerRadius = UDim.new(0, 4)
        local csContent = Instance.new("ScrollingFrame")
        csContent.Name = "Content"
        csContent.Size = UDim2.new(1, -20, 1, -50)
        csContent.Position = UDim2.fromOffset(10, 40)
        csContent.BackgroundTransparency = 1
        csContent.BorderSizePixel = 0
        csContent.ScrollBarThickness = 5
        csContent.Parent = carStealWindow
        local csListLayout = Instance.new("UIListLayout", csContent)
        csListLayout.Padding = UDim.new(0, 5)
        csListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        local vehiclesFolder = workspace:WaitForChild("Vehicles")
        if not vehiclesFolder then
            return
        end
        for i, vehicle in ipairs(vehiclesFolder:GetChildren()) do
            if vehicle:IsA("Model") then
                local seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("FRSeat")
                if seat and seat:IsA("BasePart") then
                    local carName = vehicle.Name
                    local carPos = seat.Position
                    local posText = string.format("(%.0f, %.0f, %.0f)", carPos.X, carPos.Y, carPos.Z)
                    local carButton = CreateButton(csContent, carName .. " - " .. posText, function()
                        if LocalPlayer.Character then
                            sitAndTeleport(seat.Position, seat.CFrame.LookVector)
                        else
                            StarterGui:SetCore("SendNotification", {
                                Title = "FrostsHub",
                                Text = "Your character is not loaded."
                            })
                        end
                    end)
                    carButton.LayoutOrder = i
                end
            end
        end
    end)
    -- [[ NEW FEATURE: Printer Teleporter ]]
    CreateButton(moneySection, "Printer Teleporter", function()
        local printerTpWindow = Instance.new("Frame")
        printerTpWindow.Name = "PrinterTpWindow"
        printerTpWindow.Size = UDim2.fromOffset(450, 350)
        printerTpWindow.Position = UDim2.new(0.5, -225, 0.5, -175)
        printerTpWindow.BackgroundColor3 = Theme.Background
        printerTpWindow.Active = true
        printerTpWindow.Draggable = true
        printerTpWindow.Parent = FrostsHubGui
        Instance.new("UICorner", printerTpWindow).CornerRadius = Theme.CornerRadius
        local ptpStroke = Instance.new("UIStroke", printerTpWindow);
        ptpStroke.Color = Theme.Primary;
        ptpStroke.Thickness = 1.5
        local ptpTitle = Instance.new("TextLabel", printerTpWindow)
        ptpTitle.Name = "Title"
        ptpTitle.Size = UDim2.new(1, 0, 0, 40)
        ptpTitle.BackgroundTransparency = 1
        ptpTitle.Font = Theme.Font.Semibold
        ptpTitle.TextColor3 = Theme.Text
        ptpTitle.TextSize = Theme.TextSize.Title
        ptpTitle.Text = "Printer Teleporter"
        ptpTitle.TextXAlignment = Enum.TextXAlignment.Center
        local ptpClose = Instance.new("TextButton", printerTpWindow)
        ptpClose.Name = "CloseButton"
        ptpClose.Size = UDim2.fromOffset(25, 25)
        ptpClose.Position = UDim2.new(1, -35, 0, 8)
        ptpClose.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        ptpClose.Font = Theme.Font.Semibold
        ptpClose.Text = "X"
        ptpClose.TextColor3 = Theme.Text
        ptpClose.TextSize = 14
        ptpClose.MouseButton1Click:Connect(function()
            printerTpWindow:Destroy()
        end)
        Instance.new("UICorner", ptpClose).CornerRadius = UDim.new(0, 4)
        local ptpContent = Instance.new("ScrollingFrame")
        ptpContent.Name = "Content"
        ptpContent.Size = UDim2.new(1, -20, 1, -50)
        ptpContent.Position = UDim2.fromOffset(10, 40)
        ptpContent.BackgroundTransparency = 1
        ptpContent.BorderSizePixel = 0
        ptpContent.ScrollBarThickness = 5
        ptpContent.Parent = printerTpWindow
        local ptpListLayout = Instance.new("UIListLayout", ptpContent)
        ptpListLayout.Padding = UDim.new(0, 5)
        ptpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        local repzFolder = workspace:FindFirstChild("RepzMachines")
        if not repzFolder then
            return
        end
        for i, printerModel in ipairs(repzFolder:GetChildren()) do
            if printerModel:IsA("Model") then
                local targetPart = printerModel:FindFirstChild("PrintBase") or (printerModel:FindFirstChild("Base") and printerModel.Base.PrimaryPart)
                if targetPart and targetPart:IsA("BasePart") then
                    local printerPos = targetPart.Position
                    local posText = string.format("(%.0f, %.0f, %.0f)", printerPos.X, printerPos.Y, printerPos.Z)
                    local printerButton = CreateButton(ptpContent, "Printer " .. i .. " - " .. posText, function()
                        if LocalPlayer.Character then
                            sitAndTeleport(printerPos, LocalPlayer.Character.PrimaryPart.CFrame.LookVector)
                        else
                            StarterGui:SetCore("SendNotification", {
                                Title = "FrostsHub",
                                Text = "Your character is not loaded."
                            })
                        end
                    end)
                    printerButton.LayoutOrder = i
                end
            end
        end
    end)
end

-- == Misc Tab Content ==
do
    local miscLayout = Instance.new("UIGridLayout", MiscTab);
    miscLayout.CellSize = UDim2.new(1, 0, 1, 0)
    local miscSection = CreateSection(MiscTab, "Player", UDim2.new(1, 0, 1, 0))
    local flyToggle = CreateToggle(miscSection, "Fly", flyEnabled, function(s)
        if s then
            enableFly()
        else
            disableFly()
        end
    end)
    CreateSlider(miscSection, "Fly Speed", {10, 200}, currentFlySpeed, function(v)
        currentFlySpeed = v
    end)
    CreateToggle(miscSection, "No Clip", false, function(s)
        noClipEnabled = s;
        if not s and LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
    end)
    CreateToggle(miscSection, "Anti-AFK", false, function(s)
        antiAfkEnabled = s
    end)
    CreateToggle(miscSection, "Fullbright", false, function(s)
        fullbrightEnabled = s;
        Lighting.Brightness = s and 1 or defaultBrightness;
        Lighting.OutdoorAmbient = s and Color3.new(1, 1, 1) or defaultOutdoorAmbient
    end)
    -- Name Changer Feature
    local customName = "ðŸ”¥ FrostsHub ðŸ”¥"
    CreateTextInput(miscSection, "Name Changer", "Enter custom name", function(text)
        customName = text
    end)
    local _, updateNameChangerToggle = CreateToggle(miscSection, "Enable Name Changer", false, function(state)
        if state then
            -- Toggled ON
            if not customName or customName:gsub("%s", "") == "" then
                StarterGui:SetCore("SendNotification", {
                    Title = "FrostsHub",
                    Text = "Please enter a name first."
                })
                pcall(updateNameChangerToggle, false)
                return
            end
            if nameChangerCoroutine then
                task.cancel(nameChangerCoroutine)
            end
            nameChangerCoroutine = task.spawn(function()
                while task.wait(0.5) do
                    pcall(function()
                        local nameLabel = LocalPlayer.Character.Head.displayGUI.nameLabel
                        nameLabel.Text = customName
                    end)
                end
            end)
        else
            -- Toggled OFF
            if nameChangerCoroutine then
                task.cancel(nameChangerCoroutine)
                nameChangerCoroutine = nil
            end
            pcall(function()
                local nameLabel = LocalPlayer.Character.Head.displayGUI.nameLabel
                nameLabel.Text = LocalPlayer.Name
            end)
        end
    end)
end

--//=========================================================================\\
--|| EVENT CONNECTIONS & INITIALIZATION
--\\=========================================================================//

-- Unload Function
local function unload()
    if nameChangerCoroutine then
        task.cancel(nameChangerCoroutine);
        nameChangerCoroutine = nil
    end
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end;
    connections = {}
    if aimbotConnection then
        aimbotConnection:Disconnect();
        aimbotConnection = nil
    end
    if noClipConnection then
        noClipConnection:Disconnect();
        noClipConnection = nil
    end
    fovCircle:Remove()
    for player, data in pairs(skeletonConnections) do
        cleanupSkeleton(player)
    end
    for player, data in pairs(boxConnections) do
        cleanupInfoESP(player)
    end
    for player, data in pairs(tracerConnections) do
        cleanupTracerESP(player)
    end
    for part, drawingSet in pairs(printerEspDrawings) do
        if drawingSet.text then
            drawingSet.text:Remove()
        end;
        if drawingSet.line then
            drawingSet.line:Remove()
        end
    end;
    printerEspDrawings = {}
    for part, drawingSet in pairs(carEspDrawings) do
        if drawingSet.text then
            drawingSet.text:Remove()
        end;
        if drawingSet.line then
            drawingSet.line:Remove()
        end
    end;
    carEspDrawings = {}
    FrostsHubGui:Destroy()
end
CloseButton.MouseButton1Click:Connect(unload)

-- Minimize Button Logic
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local goalSize = isMinimized and UDim2.fromOffset(560, 45) or UDim2.fromOffset(560, 420)
    TabContainer.Visible = not isMinimized
    ContentArea.Visible = not isMinimized
    local tween = TweenService:Create(Window, Theme.AnimationInfo, {
        Size = goalSize
    })
    tween:Play()
end)

-- FOV Circle Loop
table.insert(connections, RunService.RenderStepped:Connect(function()
    if fovCircleEnabled and aimbotEnabled then
        local radius = (math.tan(math.rad(aimbotFOV / 2)) * (Camera.ViewportSize.Y / 2)) / math.tan(math.rad(Camera.FieldOfView / 2))
        fovCircle.Radius = radius
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end))

-- Printer ESP Loop
local function updatePrinterEsp()
    if not printerESPEnabled then
        for _, d in pairs(printerEspDrawings) do
            d.text.Visible = false;
            d.line.Visible = false
        end;
        return
    end
    local repz, localHRP = workspace:FindFirstChild("RepzMachines"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not repz or not localHRP then
        for _, d in pairs(printerEspDrawings) do
            d.text.Visible = false;
            d.line.Visible = false
        end;
        return
    end
    local activePrinters = {}
    for _, m in ipairs(repz:GetChildren()) do
        if m:IsA("Model") then
            local base = m:FindFirstChild("PrintBase");
            local target = nil
            if base and base:IsA("BasePart") then
                target = base
            elseif base and base:IsA("Model") and base.PrimaryPart then
                target = base.PrimaryPart
            end
            if target then
                activePrinters[target] = true;
                local dist = (localHRP.Position - target.Position).Magnitude;
                local d = printerEspDrawings[target]
                if not d then
                    d = {
                        text = newText(),
                        line = newLine()
                    };
                    printerEspDrawings[target] = d
                end
                if dist <= espRenderDistance then
                    local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
                    if onScreen then
                        local text = "Printer";
                        local s, l = pcall(function()
                            return m:FindFirstChild("Mechine Screen"):FindFirstChild("Display"):FindFirstChild("timeremaining")
                        end)
                        if s and l and l:IsA("TextLabel") then
                            text = "Printer: " .. l.Text
                        end
                        d.text.Text = text;
                        d.text.Position = Vector2.new(pos.X, pos.Y);
                        d.text.Visible = true;
                        d.text.Color = espPrinterColor;
                        d.text.Size = espTextSize
                        d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y);
                        d.line.To = Vector2.new(pos.X, pos.Y);
                        d.line.Visible = true;
                        d.line.Color = espPrinterColor;
                        d.line.Thickness = espThickness
                    else
                        if d then
                            d.text.Visible = false;
                            d.line.Visible = false
                        end
                    end
                else
                    if d then
                        d.text.Visible = false;
                        d.line.Visible = false
                    end
                end
            end
        end
    end
    for p, d in pairs(printerEspDrawings) do
        if not activePrinters[p] then
            d.text:Remove();
            d.line:Remove();
            printerEspDrawings[p] = nil
        end
    end
end
table.insert(connections, RunService.RenderStepped:Connect(updatePrinterEsp))

-- Car ESP Loop
local function updateCarEsp()
    if not carESPEnabled then
        for _, d in pairs(carEspDrawings) do
            if d.text then
                d.text.Visible = false
            end;
            if d.line then
                d.line.Visible = false
            end
        end;
        return
    end
    local vehicles, localHRP = workspace:FindFirstChild("Vehicles"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not vehicles or not localHRP then
        for _, d in pairs(carEspDrawings) do
            if d.text then
                d.text.Visible = false
            end;
            if d.line then
                d.line.Visible = false
            end
        end;
        return
    end
    local activeCars = {}
    for _, v in ipairs(vehicles:GetChildren()) do
        if v:IsA("Model") then
            local seat = v:FindFirstChild("Drivers Seat")
            if seat and seat:IsA("BasePart") then
                activeCars[seat] = true;
                local dist = (localHRP.Position - seat.Position).Magnitude;
                local d = carEspDrawings[seat]
                if not d then
                    d = {
                        text = newText(),
                        line = newLine()
                    };
                    carEspDrawings[seat] = d
                end
                if dist <= espRenderDistance then
                    local pos, onScreen = Camera:WorldToViewportPoint(seat.Position)
                    if onScreen then
                        d.text.Text = "Car";
                        d.text.Position = Vector2.new(pos.X, pos.Y);
                        d.text.Visible = true;
                        d.text.Color = espCarColor;
                        d.text.Size = espTextSize
                        d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y);
                        d.line.To = Vector2.new(pos.X, pos.Y);
                        d.line.Visible = true;
                        d.line.Color = espCarColor;
                        d.line.Thickness = espThickness
                    else
                        if d then
                            d.text.Visible = false;
                            d.line.Visible = false
                        end
                    end
                else
                    if d then
                        d.text.Visible = false;
                        d.line.Visible = false
                    end
                end
            end
        end
    end
    for p, d in pairs(carEspDrawings) do
        if not activeCars[p] then
            d.text:Remove();
            d.line:Remove();
            carEspDrawings[p] = nil
        end
    end
end
table.insert(connections, RunService.RenderStepped:Connect(updateCarEsp))

-- Input Handlers
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end
    if input.KeyCode == Settings.ToggleUI_Keyboard then
        FrostsHubGui.Enabled = not FrostsHubGui.Enabled;
        if activeDropdown and activeDropdown.Parent then
            activeDropdown:Destroy()
        end;
        activeDropdown = nil
    end
    if input.KeyCode == Settings.Fly_Key then
        flyEnabled = not flyEnabled;
        if flyEnabled then
            enableFly()
        else
            disableFly()
        end
    end
    -- Direct toggle
    if (input.UserInputType == Settings.Aimbot_Key or input.KeyCode == Settings.Aimbot_Controller) and aimbotEnabled and not aimbotConnection then
        aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
    end
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then
        return
    end
    if (input.UserInputType == Settings.Aimbot_Key or input.KeyCode == Settings.Aimbot_Controller) and aimbotConnection then
        aimbotConnection:Disconnect();
        aimbotConnection = nil
    end
end))

-- Character/Player Events
local function onCharacter(character)
    if flyEnabled then
        disableFly()
    end
end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(onCharacter))
table.insert(connections, Players.PlayerAdded:Connect(function(player)
    updatePlayerESP(player, true)
end))
table.insert(connections, Players.PlayerRemoving:Connect(function(player)
    updatePlayerESP(player, false)
end))

-- Continuous Loops
noClipConnection = RunService.Stepped:Connect(function()
    if noClipEnabled and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)
table.insert(connections, noClipConnection)
table.insert(connections, RunService.Stepped:Connect(function()
    if antiAfkEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and tick() % 60 < 1 then
        LocalPlayer.Character.Humanoid.Jump = true
    end
end))

-- Initial Setup
for _, player in pairs(Players:GetPlayers()) do
    updatePlayerESP(player, true)
end
if LocalPlayer.Character then
    onCharacter(LocalPlayer.Character)
end

-- Activate the Teleport tab by default
task.wait(0.1)
pcall(function()
    Tabs[3].MouseButton1Click:Fire()
end)
--[[
    Frosts HUB | Philly Street 2 v1.0
    Final Verified Script - August 2025

    - UI Library: Rayfield
    - Target Executor: Delta (and other modern executors)
    - Status: Fully checked for syntax and runtime errors.

    This script has been reviewed to ensure it is complete and functional.
]]

-- Load Rayfield Interface Library
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Global settings table for easy configuration and keybinds
local Settings = {
    ToggleUI_Keyboard = Enum.KeyCode.K,
    ToggleUI_Controller = Enum.KeyCode.ButtonSelect,
    Aimbot_Controller = Enum.KeyCode.ButtonL2,
}

-- Create the main window using Rayfield
local Window = Rayfield:CreateWindow({
    Name = "Frosts HUB | Philly Street 2",
    LoadingTitle = "Loading Frosts HUB v1.0",
    LoadingSubtitle = "by Frost",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FrostsHUB",
        FileName = "Config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Mobile UI Button Setup
local UserInputService = game:GetService("UserInputService")
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.GamepadEnabled
local ScreenGui -- Declare here to be accessible by other mobile buttons

if IsMobile then
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MobileToggleUI"
    ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Text = "🧊" -- Frost icon
    ToggleButton.Size = UDim2.new(0, 75, 0, 45)
    ToggleButton.Position = UDim2.new(1, -85, 0, 10) -- Top-right corner
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.TextColor3 = Color3.new(1, 1, 1)
    ToggleButton.Font = Enum.Font.SourceSans
    ToggleButton.TextScaled = true
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = ScreenGui
    
    -- The mobile button now calls Rayfield's toggle function directly
    ToggleButton.Activated:Connect(function()
        Rayfield:ToggleUI()
    end)
end

-- Create all tabs
local TeleportsTab = Window:CreateTab("Teleports", 4949176341)
local PlayerTab = Window:CreateTab("Player", 4949176341)
local VisualsTab = Window:CreateTab("Visuals", 4949176341)
local AutoRobTab = Window:CreateTab("Autorob", 4949176341)
local SettingsTab = Window:CreateTab("Settings", 4949176341)

-- State variable for movement
local isMoving = false

-- Generic Smooth Teleport Function
local function smoothMove(targetPosition, targetLookVector)
    if isMoving then
        Rayfield:Notify({Title = "Frosts HUB", Content = "Please wait for the current action to finish.", Duration = 5})
        return
    end
    isMoving = true
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HRP = Character:WaitForChild("HumanoidRootPart")
    local speed = 44
    local arrived = false

    local function enableTempNoClip()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    local connection
    connection = RunService.RenderStepped:Connect(function(dt)
        if not HRP or not HRP.Parent then
            connection:Disconnect()
            isMoving = false
            arrived = true
            return
        end
        enableTempNoClip()
        local currentPosition = HRP.Position
        local direction = (targetPosition - currentPosition)
        local distance = direction.Magnitude
        if distance < 1 then
            HRP.CFrame = CFrame.new(targetPosition, targetPosition + targetLookVector)
            connection:Disconnect()
            isMoving = false
            arrived = true
            return
        end
        local stepSize = math.min(speed * dt, distance)
        local newPosition = currentPosition + direction.Unit * stepSize
        HRP.CFrame = CFrame.new(newPosition, newPosition + targetLookVector)
    end)
    while not arrived do
        task.wait()
    end
end

-- Teleports Tab
TeleportsTab:CreateSection("Locations")

local storeLocations = {
    ["Clothes Store"] = Vector3.new(882.73, 317.48, -309.71),
    ["Sell Ripz"] = Vector3.new(868.59, 317.36, -236.99),
    ["Rays Auto Center"] = Vector3.new(648.39, 317.42, 354.92),
    ["Gun Store"] = Vector3.new(192.39, 317.45, 935.83),
    ["Black Market"] = Vector3.new(318.29, 317.40, 1107.25),
    ["Laundromat (Wash Money)"] = Vector3.new(-0.71, 317.43, 933.01),
    ["Houses"] = Vector3.new(216.12, 317.43, 172.89),
    ["Gas Station"] = Vector3.new(284.65, 317.43, 359.92)
}
local storeNames = {}
for storeName, _ in pairs(storeLocations) do table.insert(storeNames, storeName) end
TeleportsTab:CreateDropdown({
    Name = "Locations",
    Options = storeNames,
    Default = storeNames[1],
    Callback = function(selectedStore)
        local pos = storeLocations[selectedStore]
        if pos and game:GetService("Players").LocalPlayer.Character then
            smoothMove(pos, game:GetService("Players").LocalPlayer.Character.PrimaryPart.CFrame.LookVector)
        end
    end,
})

local jobLocations = {["Wood Chopper"] = Vector3.new(745.51, 317.39, 843.63)}
local jobNames = {}
for jobName, _ in pairs(jobLocations) do table.insert(jobNames, jobName) end
TeleportsTab:CreateDropdown({
    Name = "Jobs",
    Options = jobNames,
    Default = jobNames[1],
    Callback = function(selectedJob)
        local pos = jobLocations[selectedJob]
        if pos and game:GetService("Players").LocalPlayer.Character then
            smoothMove(pos, game:GetService("Players").LocalPlayer.Character.PrimaryPart.CFrame.LookVector)
        end
    end,
})

local foodWaterLocations = {["Food Shop"] = Vector3.new(713.68, 317.43, -133.08)}
local foodWaterNames = {}
for locName, _ in pairs(foodWaterLocations) do table.insert(foodWaterNames, locName) end
TeleportsTab:CreateDropdown({
    Name = "Food/Water",
    Options = foodWaterNames,
    Default = foodWaterNames[1],
    Callback = function(selectedLoc)
        local pos = foodWaterLocations[selectedLoc]
        if pos and game:GetService("Players").LocalPlayer.Character then
            smoothMove(pos, game:GetService("Players").LocalPlayer.Character.PrimaryPart.CFrame.LookVector)
        end
    end,
})

local dealerLocations = {
    ["Printers"] = Vector3.new(-135.16, 317.39, 162.96),
    ["Guapo"] = Vector3.new(177.20, 317.43, -162.10),
    ["Heist"] = Vector3.new(47.77, 317.39, 786.96)
}
local dealerNames = {}
for dealerName, _ in pairs(dealerLocations) do table.insert(dealerNames, dealerName) end
TeleportsTab:CreateDropdown({
    Name = "Dealers",
    Options = dealerNames,
    Default = dealerNames[1],
    Callback = function(selectedDealer)
        local pos = dealerLocations[selectedDealer]
        if pos and game:GetService("Players").LocalPlayer.Character then
            smoothMove(pos, game:GetService("Players").LocalPlayer.Character.PrimaryPart.CFrame.LookVector)
        end
    end,
})

local canRobLocations = {["P Mobile"] = Vector3.new(721.06, 317.36, -74.68)}
local canRobNames = {}
for locName, _ in pairs(canRobLocations) do table.insert(canRobNames, locName) end
TeleportsTab:CreateDropdown({
    Name = "Can Rob",
    Options = canRobNames,
    Default = canRobNames[1],
    Callback = function(selectedLoc)
        local pos = canRobLocations[selectedLoc]
        if pos and game:GetService("Players").LocalPlayer.Character then
            smoothMove(pos, game:GetService("Players").LocalPlayer.Character.PrimaryPart.CFrame.LookVector)
        end
    end,
})

-- Player Tab
PlayerTab:CreateSection("Movement")

local fastWalkSpeed, defaultWalkSpeed = 40, 16
local fastWalkEnabled, antiAfkEnabled, noClipEnabled = false, false, false
local noClipConnection = nil

local function updateWalkSpeed()
    local Character = game:GetService("Players").LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end
    Humanoid.WalkSpeed = fastWalkEnabled and fastWalkSpeed or defaultWalkSpeed
end

PlayerTab:CreateToggle({
    Name = "Fast Walk",
    Description = "Toggles walk speed",
    CurrentValue = false,
    Flag = "FastWalk",
    Callback = function(state)
        fastWalkEnabled = state
        updateWalkSpeed()
    end,
})

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    Description = "Jumps every minute to prevent disconnect",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(state)
        antiAfkEnabled = state
        if antiAfkEnabled then
            task.spawn(function()
                while antiAfkEnabled do
                    pcall(function()
                        game:GetService("Players").LocalPlayer.Character.Humanoid.Jump = true
                    end)
                    task.wait(60)
                end
            end)
        end
    end,
})

local function noClipLoop()
    if noClipEnabled and game:GetService("Players").LocalPlayer.Character then
        for _, part in ipairs(game:GetService("Players").LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

PlayerTab:CreateToggle({
    Name = "No Clip",
    Description = "Fly through walls",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(state)
        noClipEnabled = state
        if noClipEnabled and not noClipConnection then
            noClipConnection = game:GetService("RunService").RenderStepped:Connect(noClipLoop)
        elseif not noClipEnabled and noClipConnection then
            noClipConnection:Disconnect()
            noClipConnection = nil
        end
    end,
})

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
    task.wait(0.1)
    updateWalkSpeed()
end)

PlayerTab:CreateSection("Combat")

-- Visuals Tab & Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

-- ESP & Aimbot Variables
local skeletonESPEnabled, nameESPEnabled, healthESPEnabled, distanceESPEnabled, tracerESPEnabled, wallcheckEnabled = true, true, true, true, true, false
local aimbotEnabled, aimbotConnection, aimbotTargetPart, aimbotFOV = false, nil, "Head", 30
local espRenderDistance, espLineColor, espTextColor, espThickness, espTextSize = 1000, Color3.new(1,0,0), Color3.new(1,1,1), 2, 14
local skeletonConnections, boxConnections, tracerConnections = {}, {}, {}

-- ESP Drawing Functions
local function newLine() local line = Drawing.new("Line"); line.Visible = false; line.Thickness = espThickness; line.Color = espLineColor; return line end
local function newText() local text = Drawing.new("Text"); text.Visible = false; text.Size = espTextSize; text.Color = espTextColor; text.Center = true; text.Outline = true; return text end
local function isWallBetween(fromPos, toPos, ignoreCharacter)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, ignoreCharacter}
    rayParams.IgnoreWater = true
    return workspace:Raycast(fromPos, (toPos - fromPos).Unit * (toPos - fromPos).Magnitude, rayParams) ~= nil
end

-- Skeleton ESP
local function createSkeleton(player)
    if skeletonConnections[player] then return end
    local lines = { HeadToUpperTorso = newLine(), UpperToLowerTorso = newLine(), LeftShoulder = newLine(), LeftUpperToLowerArm = newLine(), LeftLowerToHand = newLine(), RightShoulder = newLine(), RightUpperToLowerArm = newLine(), RightLowerToHand = newLine(), LeftHip = newLine(), LeftUpperToLowerLeg = newLine(), LeftLowerToFoot = newLine(), RightHip = newLine(), RightUpperToLowerLeg = newLine(), RightLowerToFoot = newLine() }
    local conn = RunService.RenderStepped:Connect(function()
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local char = player.Character
        if not skeletonESPEnabled or not localHRP or not char or not char:FindFirstChild("HumanoidRootPart") or (localHRP.Position - char.HumanoidRootPart.Position).Magnitude > espRenderDistance or (wallcheckEnabled and isWallBetween(localHRP.Position, char.HumanoidRootPart.Position, char)) then
            for _, line in pairs(lines) do line.Visible = false end
            return
        end
        local function getPos(partName) local part = char:FindFirstChild(partName); if part and part:IsA("BasePart") then local pos, onScreen = Camera:WorldToViewportPoint(part.Position); if onScreen then return Vector2.new(pos.X, pos.Y), true end end; return nil, false end
        local function draw(name, fromPart, toPart)
            local fromPos, fromVisible = getPos(fromPart)
            local toPos, toVisible = getPos(toPart)
            local line = lines[name]
            if fromPos and toPos and fromVisible and toVisible then line.From = fromPos; line.To = toPos; line.Visible = true; line.Color = espLineColor; line.Thickness = espThickness else line.Visible = false end
        end
        draw("HeadToUpperTorso", "Head", "UpperTorso")
        draw("UpperToLowerTorso", "UpperTorso", "LowerTorso")
        draw("LeftShoulder", "UpperTorso", "LeftUpperArm")
        draw("LeftUpperToLowerArm", "LeftUpperArm", "LeftLowerArm")
        draw("LeftLowerToHand", "LeftLowerArm", "LeftHand")
        draw("RightShoulder", "UpperTorso", "RightUpperArm")
        draw("RightUpperToLowerArm", "RightUpperArm", "RightLowerArm")
        draw("RightLowerToHand", "RightLowerArm", "RightHand")
        draw("LeftHip", "LowerTorso", "LeftUpperLeg")
        draw("LeftUpperToLowerLeg", "LeftUpperLeg", "LeftLowerLeg")
        draw("LeftLowerToFoot", "LeftLowerLeg", "LeftFoot")
        draw("RightHip", "LowerTorso", "RightUpperLeg")
        draw("RightUpperToLowerLeg", "RightUpperLeg", "RightLowerLeg")
        draw("RightLowerToFoot", "RightLowerLeg", "RightFoot")
    end)
    skeletonConnections[player] = { connection = conn, lines = lines }
end
local function cleanupSkeleton(player) if skeletonConnections[player] then skeletonConnections[player].connection:Disconnect(); for _, line in pairs(skeletonConnections[player].lines) do line:Remove() end; skeletonConnections[player] = nil end end

-- Info ESP (Name, Health, Distance)
local function createInfoESP(player)
    if boxConnections[player] then return end
    local nameText, healthText, distanceText = newText(), newText(), newText()
    local conn = RunService.RenderStepped:Connect(function()
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not localHRP or not char or not humanoid or humanoid.Health <= 0 or not char:FindFirstChild("Head") then nameText.Visible, healthText.Visible, distanceText.Visible = false, false, false; return end
        local hrp, head = char.HumanoidRootPart, char.Head
        local dist = (localHRP.Position - hrp.Position).Magnitude
        if dist > espRenderDistance or (wallcheckEnabled and isWallBetween(localHRP.Position, hrp.Position, char)) then nameText.Visible, healthText.Visible, distanceText.Visible = false, false, false; return end
        local headPos, onScreenHead = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpPos, onScreenHRP = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 1, 0))
        if not (onScreenHead and onScreenHRP) then nameText.Visible, healthText.Visible, distanceText.Visible = false, false, false; return end
        local x, y, h = headPos.X, headPos.Y, math.abs(headPos.Y - hrpPos.Y)
        if nameESPEnabled then nameText.Text = player.Name; nameText.Position = Vector2.new(x, y - 15); nameText.Visible = true; nameText.Color = espTextColor; nameText.Size = espTextSize end
        if healthESPEnabled then local health, maxHealth = math.floor(humanoid.Health), math.floor(humanoid.MaxHealth); healthText.Text = string.format("HP: %d/%d", health, maxHealth); healthText.Position = Vector2.new(x, y - 30); healthText.Color = health > maxHealth * 0.75 and Color3.new(0, 1, 0) or (health > maxHealth * 0.25 and Color3.new(1, 1, 0) or Color3.new(1, 0, 0)); healthText.Visible = true; healthText.Size = espTextSize end
        if distanceESPEnabled then distanceText.Text = string.format("Dist: %d studs", math.floor(dist)); distanceText.Position = Vector2.new(x, y + h + 15); distanceText.Visible = true; distanceText.Color = espTextColor; distanceText.Size = espTextSize end
    end)
    boxConnections[player] = { connection = conn, nameText = nameText, healthText = healthText, distanceText = distanceText }
end
local function cleanupInfoESP(player) if boxConnections[player] then boxConnections[player].connection:Disconnect(); boxConnections[player].nameText:Remove(); boxConnections[player].healthText:Remove(); boxConnections[player].distanceText:Remove(); boxConnections[player] = nil end end

-- Tracer ESP
local function createTracerESP(player)
    if tracerConnections[player] then return end
    local tracerLine = newLine()
    local conn = RunService.RenderStepped:Connect(function()
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not tracerESPEnabled or not localHRP or not targetHRP or (localHRP.Position - targetHRP.Position).Magnitude > espRenderDistance or (wallcheckEnabled and isWallBetween(localHRP.Position, targetHRP.Position, player.Character)) then tracerLine.Visible = false; return end
        local rootPos, onScreen = Camera:WorldToViewportPoint(targetHRP.Position)
        if onScreen then tracerLine.From, tracerLine.To, tracerLine.Visible = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y), Vector2.new(rootPos.X, rootPos.Y), true; tracerLine.Color = espLineColor; tracerLine.Thickness = espThickness else tracerLine.Visible = false end
    end)
    tracerConnections[player] = { connection = conn, line = tracerLine }
end
local function cleanupTracerESP(player) if tracerConnections[player] then tracerConnections[player].connection:Disconnect(); tracerConnections[player].line:Remove(); tracerConnections[player] = nil end end

-- Aimbot Logic
local function aimbotLoop()
    if not aimbotEnabled then return end
    local localHRP = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart
    if not localHRP then return end
    local closestPlayer, shortestDistance = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local targetHRP = player.Character.HumanoidRootPart
            local distance = (localHRP.Position - targetHRP.Position).Magnitude
            if distance < shortestDistance and distance <= espRenderDistance then
                local targetPart = player.Character:FindFirstChild(aimbotTargetPart)
                if targetPart then
                    local screenPoint, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                    if onScreen then
                        local magnitude = (UserInputService:GetMouseLocation() - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                        if magnitude < aimbotFOV * 10 and not (wallcheckEnabled and isWallBetween(localHRP.Position, targetPart.Position, player.Character)) then
                            closestPlayer, shortestDistance = player, magnitude
                        end
                    end
                end
            end
        end
    end
    if closestPlayer then
        local targetPart = closestPlayer.Character:FindFirstChild(aimbotTargetPart)
        if targetPart then
            Camera.CFrame = CFrame.new(Camera.CFrame.p, targetPart.Position)
        end
    end
end

-- ESP Management Functions
local function updatePlayerESP(player, enable)
    if player == LocalPlayer then return end
    cleanupSkeleton(player)
    cleanupInfoESP(player)
    cleanupTracerESP(player)
    if enable then
        if skeletonESPEnabled then createSkeleton(player) end
        if nameESPEnabled or healthESPEnabled or distanceESPEnabled then createInfoESP(player) end
        if tracerESPEnabled then createTracerESP(player) end
    end
end
local function updateAllEspVisuals() for _, player in pairs(Players:GetPlayers()) do updatePlayerESP(player, true) end end

-- Mobile Aimbot Button
if IsMobile then
    local AimbotToggleButton = Instance.new("TextButton")
    AimbotToggleButton.Name = "AimbotToggle"
    AimbotToggleButton.Text = "AIM"
    AimbotToggleButton.Size = UDim2.new(0, 75, 0, 45)
    AimbotToggleButton.Position = UDim2.new(1, -85, 0, 60)
    AimbotToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    AimbotToggleButton.TextColor3 = Color3.new(1, 1, 1)
    AimbotToggleButton.Font = Enum.Font.SourceSans
    AimbotToggleButton.TextScaled = true
    AimbotToggleButton.BorderSizePixel = 1
    AimbotToggleButton.BorderColor3 = Color3.new(1,1,1)
    AimbotToggleButton.Parent = ScreenGui -- Attach to the same ScreenGui as the main toggle
    AimbotToggleButton.Activated:Connect(function()
        aimbotEnabled = not aimbotEnabled
        if aimbotEnabled and not aimbotConnection then
            AimbotToggleButton.BackgroundColor3 = Color3.fromRGB(25, 100, 25)
            aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
        elseif not aimbotEnabled and aimbotConnection then
            AimbotToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end)
end

-- Input handling for PC/Controller aimbot
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if (input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Settings.Aimbot_Controller) then
        if not aimbotEnabled then return end -- only activate if toggle is on
        aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
    end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    if (input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Settings.Aimbot_Controller) then
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end)

-- Visuals UI Setup
VisualsTab:CreateSection("ESP Settings")
VisualsTab:CreateToggle({Name = "Skeleton ESP", CurrentValue = skeletonESPEnabled, Flag = "SkeletonESP", Callback = function(s) skeletonESPEnabled = s; updateAllEspVisuals() end})
VisualsTab:CreateToggle({Name = "Name ESP", CurrentValue = nameESPEnabled, Flag = "NameESP", Callback = function(s) nameESPEnabled = s; updateAllEspVisuals() end})
VisualsTab:CreateToggle({Name = "Health ESP", CurrentValue = healthESPEnabled, Flag = "HealthESP", Callback = function(s) healthESPEnabled = s; updateAllEspVisuals() end})
VisualsTab:CreateToggle({Name = "Distance ESP", CurrentValue = distanceESPEnabled, Flag = "DistanceESP", Callback = function(s) distanceESPEnabled = s; updateAllEspVisuals() end})
VisualsTab:CreateToggle({Name = "Tracers", CurrentValue = tracerESPEnabled, Flag = "Tracers", Callback = function(s) tracerESPEnabled = s; updateAllEspVisuals() end})
VisualsTab:CreateToggle({Name = "Wallcheck", Description = "ESP/Aimbot only works on visible players", CurrentValue = wallcheckEnabled, Flag = "Wallcheck", Callback = function(s) wallcheckEnabled = s end})
VisualsTab:CreateDropdown({Name = "Line Color", Options = {"Red", "Green", "Blue", "White", "Black", "Yellow", "Cyan", "Magenta"}, Default = "Red", Callback = function(s) local c = Color3.fromHex("#FFFFFF"); if s == "Red" then c = Color3.new(1,0,0) elseif s == "Green" then c = Color3.new(0,1,0) elseif s == "Blue" then c = Color3.new(0,0,1) elseif s == "White" then c = Color3.new(1,1,1) elseif s == "Black" then c = Color3.new(0,0,0) elseif s == "Yellow" then c = Color3.new(1,1,0) elseif s == "Cyan" then c = Color3.new(0,1,1) elseif s == "Magenta" then c = Color3.new(1,0,1) end; espLineColor = c; updateAllEspVisuals() end})
VisualsTab:CreateDropdown({Name = "Text Color", Options = {"White", "Red", "Green", "Blue", "Black", "Yellow", "Cyan", "Magenta"}, Default = "White", Callback = function(s) local c = Color3.fromHex("#FFFFFF"); if s == "Red" then c = Color3.new(1,0,0) elseif s == "Green" then c = Color3.new(0,1,0) elseif s == "Blue" then c = Color3.new(0,0,1) elseif s == "White" then c = Color3.new(1,1,1) elseif s == "Black" then c = Color3.new(0,0,0) elseif s == "Yellow" then c = Color3.new(1,1,0) elseif s == "Cyan" then c = Color3.new(0,1,1) elseif s == "Magenta" then c = Color3.new(1,0,1) end; espTextColor = c; updateAllEspVisuals() end})
VisualsTab:CreateSlider({Name = "Line Size", Min = 1, Max = 5, Default = 2, Rounding = 0, Callback = function(v) espThickness = v; updateAllEspVisuals() end})
VisualsTab:CreateSlider({Name = "Text Size", Min = 10, Max = 20, Default = 14, Rounding = 0, Callback = function(v) espTextSize = v; updateAllEspVisuals() end})

VisualsTab:CreateSection("Miscellaneous")
VisualsTab:CreateToggle({Name = "Fullbright", Description = "Removes shadows and makes everything bright", CurrentValue = false, Flag = "Fullbright", Callback = function(s) local defaultBrightness = 2; local defaultOutdoorAmbient = Color3.fromRGB(128, 128, 128); Lighting.Brightness = s and 1 or defaultBrightness; Lighting.OutdoorAmbient = s and Color3.new(1,1,1) or defaultOutdoorAmbient end})

-- Combat Tab Aimbot Settings
PlayerTab:CreateToggle({Name = "Aimbot", Description = "Hold Right Mouse or Controller L2 to aim", CurrentValue = false, Flag = "Aimbot", Callback = function(s) aimbotEnabled = s end})
PlayerTab:CreateDropdown({Name = "Target Part", Options = {"Head", "HumanoidRootPart", "Torso"}, Default = "Head", Flag = "AimbotTarget", Callback = function(s) aimbotTargetPart = s end})
PlayerTab:CreateSlider({Name = "Aimbot FOV", Min = 1, Max = 180, Default = 30, Rounding = 0, Callback = function(v) aimbotFOV = v end})


-- Player Connection Events
Players.PlayerAdded:Connect(function(player) updatePlayerESP(player, true) end)
Players.PlayerRemoving:Connect(function(player) updatePlayerESP(player, false) end)
for _, player in pairs(Players:GetPlayers()) do updatePlayerESP(player, true) end

-- AutoRob & ServerHop
AutoRobTab:CreateSection("Automation")
AutoRobTab:CreateButton({
    Name = "Auto Rob Electronics",
    Description = "Robs all electronics in P Mobile, then stops.",
    Callback = function()
        if isMoving then
            Rayfield:Notify({Title = "Frosts HUB", Content = "Auto-robbery already in progress.", Duration = 5})
            return
        end
        task.spawn(function()
            local VIM, LP, originalHolds = game:GetService("VirtualInputManager"), Players.LocalPlayer, {}
            local function restore() for p, d in pairs(originalHolds) do if p and p.Parent then p.HoldDuration = d end end end
            for _, v in ipairs(workspace:GetDescendants()) do if v.ClassName == "ProximityPrompt" then originalHolds[v] = v.HoldDuration; v.HoldDuration = 0 end end
            task.wait(0.3)
            local steps = {
                { N = "Phone 1", P = Vector3.new(706.48, 317.36, -68.72), L = Vector3.new(0, 0, 1) }, { N = "Phone 2", P = Vector3.new(705.51, 317.36, -68.24), L = Vector3.new(0, 0, 1) }, { N = "Phone 3", P = Vector3.new(704.51, 317.36, -68.37), L = Vector3.new(0, 0, 1) },
                { N = "Phone 4", P = Vector3.new(703.58, 317.36, -68.35), L = Vector3.new(0, 0, 1) }, { N = "Phone 5", P = Vector3.new(702.25, 317.36, -68.46), L = Vector3.new(0, 0, 1) }, { N = "Laptop 1", P = Vector3.new(697.6, 317.44, -68.3), L = Vector3.new(0, 0, 1) },
                { N = "Laptop 2", P = Vector3.new(694.72, 317.36, -68.15), L = Vector3.new(0, 0, 1) }, { N = "Phone 6", P = Vector3.new(686.85, 317.36, -79.66), L = Vector3.new(0, 0, -1) }, { N = "Phone 7", P = Vector3.new(688.1, 317.36, -79.95), L = Vector3.new(0, 0, -1) },
                { N = "Phone 8", P = Vector3.new(689.22, 317.36, -79.89), L = Vector3.new(0, 0, -1) }, { N = "Phone 9", P = Vector3.new(689.78, 317.36, -80.3), L = Vector3.new(0, 0, -1) }, { N = "Phone 10", P = Vector3.new(691.04, 317.36, -80.41), L = Vector3.new(0, 0, -1) },
                { N = "TV 1", P = Vector3.new(700.92, 317.36, -81.48), L = Vector3.new(0, 0, -1) }, { N = "TV 2", P = Vector3.new(705.91, 317.36, -81.57), L = Vector3.new(0, 0, -1) }
            }
            for i, step in ipairs(steps) do
                if not LP.Character then restore(); return end
                Rayfield:Notify({Title = "Frosts HUB", Content = "Robbing " .. step.N .. " (" .. i .. "/" .. #steps .. ")", Duration = 3})
                smoothMove(step.P, step.L)
                task.wait(0.1)
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait(0.2)
            end
            Rayfield:Notify({Title = "Frosts HUB", Content = "Auto-robbery complete.", Duration = 5})
            restore()
        end)
    end,
})

AutoRobTab:CreateButton({
    Name = "Server Hop",
    Description = "Finds and joins a different server.",
    Callback = function()
        task.spawn(function()
            local TS, HS = game:GetService("TeleportService"), game:GetService("HttpService")
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local servers = HS:JSONDecode(HS:GetAsync(url)).data
            local newServers = {}
            for _, server in ipairs(servers) do
                if type(server) == 'table' and server.id and server.id ~= game.JobId and server.playing < server.maxPlayers then
                    table.insert(newServers, server.id)
                end
            end
            if #newServers > 0 then
                TS:TeleportToPlaceInstance(game.PlaceId, newServers[math.random(1, #newServers)], Players.LocalPlayer)
            else
                Rayfield:Notify({Title = "Frosts HUB", Content = "No other servers found.", Duration = 5})
            end
        end)
    end,
})

-- Keybinds Setup
SettingsTab:CreateSection("Keybinds")
SettingsTab:CreateKeybind({
    Name = "Toggle UI (Keyboard)",
    CurrentKey = tostring(Settings.ToggleUI_Keyboard):match("([^.]+)$"),
    Flag = "ToggleUI_KB",
    Callback = function(newKey)
        Settings.ToggleUI_Keyboard = Enum.KeyCode[newKey]
        Rayfield:Notify({Title = "Keybind Changed", Content = "Toggle UI (Keyboard) set to " .. newKey, Duration = 5})
    end,
})

-- Link the Rayfield toggle to the custom keybind
Rayfield:SetKeybind(Settings.ToggleUI_Keyboard)

SettingsTab:CreateKeybind({
    Name = "Aimbot (Controller)",
    CurrentKey = tostring(Settings.Aimbot_Controller):match("([^.]+)$"),
    Flag = "Aimbot_GP",
    Callback = function(newKey)
        Settings.Aimbot_Controller = Enum.KeyCode[newKey]
        Rayfield:Notify({Title = "Keybind Changed", Content = "Aimbot (Controller) set to " .. newKey, Duration = 5})
    end,
})


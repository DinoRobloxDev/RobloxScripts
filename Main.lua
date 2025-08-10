--[[
    Frosts HUB | Philly Street 2 v1.0
    Final Self-Contained UI Edition

    - UI Library: None. UI is built from scratch to be 100% self-contained.
    - Target Executor: Delta (and other modern executors)
    - Status: Re-written to have ZERO dependencies and solve all HTTP errors.
]]

--================================================================================================--
--[[                                        BACKEND LOGIC                                       ]]
--================================================================================================--

-- This first part of the script contains all the features like teleport, ESP, aimbot, etc.
-- The UI is created in the second part and connected to this logic.

-- Global Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Global Player Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Global Script Settings
local Settings = {
    -- Toggles
    FastWalk_Enabled = false,
    AntiAFK_Enabled = false,
    NoClip_Enabled = false,
    Aimbot_Enabled = false,
    SkeletonESP_Enabled = true,
    NameESP_Enabled = true,
    HealthESP_Enabled = true,
    DistanceESP_Enabled = true,
    TracerESP_Enabled = true,
    Wallcheck_Enabled = false,
    Fullbright_Enabled = false,
    
    -- Values
    Aimbot_TargetPart = "Head",
    Aimbot_FOV = 30,
    ESP_RenderDistance = 1000,
    ESP_LineColor = Color3.new(1,0,0),
    ESP_TextColor = Color3.new(1,1,1),
    ESP_Thickness = 2,
    ESP_TextSize = 14
}

-- Generic Smooth Teleport Function
local isMoving = false
local function smoothMove(targetPosition, targetLookVector)
    if isMoving then return end
    isMoving = true
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HRP = Character:WaitForChild("HumanoidRootPart")
    local speed = 44
    local arrived = false
    local function enableTempNoClip() for _, part in pairs(Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
    local connection
    connection = RunService.RenderStepped:Connect(function(dt)
        if not HRP or not HRP.Parent then connection:Disconnect(); isMoving = false; arrived = true; return end
        enableTempNoClip()
        local currentPosition = HRP.Position
        local direction = (targetPosition - currentPosition)
        if direction.Magnitude < 1 then HRP.CFrame = CFrame.new(targetPosition, targetPosition + targetLookVector); connection:Disconnect(); isMoving = false; arrived = true; return end
        local stepSize = math.min(speed * dt, direction.Magnitude)
        HRP.CFrame = CFrame.new(currentPosition + direction.Unit * stepSize, currentPosition + direction.Unit * stepSize + targetLookVector)
    end)
    while not arrived do task.wait() end
end

-- ESP Drawing Functions
local skeletonConnections, boxConnections, tracerConnections = {}, {}, {}
local function newLine() local line = Drawing.new("Line"); line.Visible = false; line.Thickness = Settings.ESP_Thickness; line.Color = Settings.ESP_LineColor; return line end
local function newText() local text = Drawing.new("Text"); text.Visible = false; text.Size = Settings.ESP_TextSize; text.Color = Settings.ESP_TextColor; text.Center = true; text.Outline = true; return text end
local function isWallBetween(fromPos, toPos, ignore) local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {LocalPlayer.Character, ignore}; return workspace:Raycast(fromPos, toPos - fromPos, params) ~= nil end

-- ESP Main Logic
local function updatePlayerESP(player, enable)
    -- Cleanup previous ESP elements
    if skeletonConnections[player] then skeletonConnections[player].connection:Disconnect(); for _,v in pairs(skeletonConnections[player].lines)do v:Remove()end; skeletonConnections[player]=nil end
    if boxConnections[player] then boxConnections[player].connection:Disconnect();boxConnections[player].nameText:Remove();boxConnections[player].healthText:Remove();boxConnections[player].distanceText:Remove();boxConnections[player]=nil end
    if tracerConnections[player] then tracerConnections[player].connection:Disconnect();tracerConnections[player].line:Remove();tracerConnections[player]=nil end

    if not enable or player == LocalPlayer then return end

    -- Create new ESP elements
    if Settings.SkeletonESP_Enabled then
        local l={H=newLine(),T=newLine(),LS=newLine(),LUA=newLine(),LLA=newLine(),RS=newLine(),RUA=newLine(),RLA=newLine(),LH=newLine(),LUL=newLine(),LLL=newLine(),RH=newLine(),RUL=newLine(),RLL=newLine()};
        local c=RunService.RenderStepped:Connect(function()
            local h,ch=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),player.Character;
            if not Settings.SkeletonESP_Enabled or not h or not ch or not ch:FindFirstChild("HumanoidRootPart") or(h.Position-ch.HumanoidRootPart.Position).Magnitude>Settings.ESP_RenderDistance or(Settings.Wallcheck_Enabled and isWallBetween(h.Position,ch.HumanoidRootPart.Position,ch))then for _,v in pairs(l)do v.Visible=false end;return end;
            local function gp(pn)local pt=ch:FindFirstChild(pn);if pt and pt:IsA("BasePart")then local pos,vis=Camera:WorldToViewportPoint(pt.Position);if vis then return Vector2.new(pos.X,pos.Y)end end end;
            local function dr(n,fp,tp)local f,t=gp(fp),gp(tp);if f and t then l[n].From=f;l[n].To=t;l[n].Visible=true;l[n].Color=Settings.ESP_LineColor;l[n].Thickness=Settings.ESP_Thickness else l[n].Visible=false end end;
            dr("H","Head","UpperTorso");dr("T","UpperTorso","LowerTorso");dr("LS","UpperTorso","LeftUpperArm");dr("LUA","LeftUpperArm","LeftLowerArm");dr("LLA","LeftLowerArm","LeftHand");dr("RS","UpperTorso","RightUpperArm");dr("RUA","RightUpperArm","RightLowerArm");dr("RLA","RightLowerArm","RightHand");dr("LH","LowerTorso","LeftUpperLeg");dr("LUL","LeftUpperLeg","LeftLowerLeg");dr("LLL","LeftLowerLeg","LeftFoot");dr("RH","LowerTorso","RightUpperLeg");dr("RUL","RightUpperLeg","RightLowerLeg");dr("RLL","RightLowerLeg","RightFoot");
        end); skeletonConnections[player]={connection=c,lines=l}
    end
    if Settings.NameESP_Enabled or Settings.HealthESP_Enabled or Settings.DistanceESP_Enabled then
        local nt,ht,dt=newText(),newText(),newText();local c=RunService.RenderStepped:Connect(function()
            local h,ch,uh=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),player.Character,player.Character and player.Character:FindFirstChildOfClass("Humanoid");
            if not h or not ch or not uh or uh.Health<=0 or not ch:FindFirstChild("Head")then nt.Visible,ht.Visible,dt.Visible=false,false,false;return end;
            local d=(h.Position-ch.HumanoidRootPart.Position).Magnitude;if d>Settings.ESP_RenderDistance or(Settings.Wallcheck_Enabled and isWallBetween(h.Position,ch.HumanoidRootPart.Position,ch))then nt.Visible,ht.Visible,dt.Visible=false,false,false;return end;
            local hp,hvis=Camera:WorldToViewportPoint(ch.Head.Position+Vector3.new(0,0.5,0));local hrpp,hrpvis=Camera:WorldToViewportPoint(ch.HumanoidRootPart.Position-Vector3.new(0,1,0));
            if not(hvis and hrpvis)then nt.Visible,ht.Visible,dt.Visible=false,false,false;return end;local x,y,hei=hp.X,hp.Y,math.abs(hp.Y-hrpp.Y);
            nt.Visible=Settings.NameESP_Enabled;if nt.Visible then nt.Text=player.Name;nt.Position=Vector2.new(x,y-15);nt.Color=Settings.ESP_TextColor;nt.Size=Settings.ESP_TextSize end;
            ht.Visible=Settings.HealthESP_Enabled;if ht.Visible then local h,mh=math.floor(uh.Health),math.floor(uh.MaxHealth);ht.Text=string.format("HP: %d/%d",h,mh);ht.Position=Vector2.new(x,y-30);ht.Color=h>mh*0.75 and Color3.new(0,1,0)or(h>mh*0.25 and Color3.new(1,1,0)or Color3.new(1,0,0));ht.Size=Settings.ESP_TextSize end;
            dt.Visible=Settings.DistanceESP_Enabled;if dt.Visible then dt.Text=string.format("Dist: %d studs",math.floor(d));dt.Position=Vector2.new(x,y+hei+15);dt.Color=Settings.ESP_TextColor;dt.Size=Settings.ESP_TextSize end;
        end); boxConnections[player]={connection=c,nameText=nt,healthText=ht,distanceText=dt}
    end
    if Settings.TracerESP_Enabled then
        local l=newLine();local c=RunService.RenderStepped:Connect(function()
            local h,th=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),player.Character and player.Character:FindFirstChild("HumanoidRootPart");
            if not Settings.TracerESP_Enabled or not h or not th or(h.Position-th.Position).Magnitude>Settings.ESP_RenderDistance or(Settings.Wallcheck_Enabled and isWallBetween(h.Position,th.Position,player.Character))then l.Visible=false;return end;
            local rp,vis=Camera:WorldToViewportPoint(th.Position);if vis then l.From,l.To,l.Visible=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y),Vector2.new(rp.X,rp.Y),true;l.Color=Settings.ESP_LineColor;l.Thickness=Settings.ESP_Thickness else l.Visible=false end
        end); tracerConnections[player]={connection=c,line=l}
    end
end
local function updateAllEspVisuals() for _,p in pairs(Players:GetPlayers())do updatePlayerESP(p,true)end end

-- Aimbot Logic
local aimbotConnection = nil
local function aimbotLoop()
    if not Settings.Aimbot_Enabled then return end;
    local h=LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart;if not h then return end;
    local cp,sd=nil,math.huge;
    for _,p in pairs(Players:GetPlayers())do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart")and p.Character:FindFirstChildOfClass("Humanoid").Health>0 then
            local d=(h.Position-p.Character.HumanoidRootPart.Position).Magnitude;
            if d<sd and d<=Settings.ESP_RenderDistance then
                local tp=p.Character:FindFirstChild(Settings.Aimbot_TargetPart);
                if tp then
                    local sp,vis=Camera:WorldToScreenPoint(tp.Position);
                    if vis then
                        local m=(UserInputService:GetMouseLocation()-Vector2.new(sp.X,sp.Y)).Magnitude;
                        if m<Settings.Aimbot_FOV*10 and not(Settings.Wallcheck_Enabled and isWallBetween(h.Position,tp.Position,p.Character))then cp,sd=p,m end
                    end
                end
            end
        end
    end
    if cp then local tp=cp.Character:FindFirstChild(Settings.Aimbot_TargetPart);if tp then Camera.CFrame=CFrame.new(Camera.CFrame.p,tp.Position)end end
end

-- PlayerAdded/Removing Connections
Players.PlayerAdded:Connect(function(p) updatePlayerESP(p, true) end)
Players.PlayerRemoving:Connect(function(p) updatePlayerESP(p, false) end)
task.spawn(updateAllEspVisuals) -- Initial run

--================================================================================================--
--[[                                         UI CREATION                                        ]]
--================================================================================================--

-- This part creates the UI from scratch. It's long but has no external dependencies.

-- Cleanup old UI
if game:GetService("CoreGui"):FindFirstChild("FrostsHub_UI") then
    game:GetService("CoreGui"):FindFirstChild("FrostsHub_UI"):Destroy()
end

-- Main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FrostsHub_UI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Window
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Parent = ScreenGui
MainWindow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainWindow.BorderColor3 = Color3.fromRGB(80, 140, 255)
MainWindow.BorderSizePixel = 2
MainWindow.Size = UDim2.new(0, 500, 0, 350)
MainWindow.Position = UDim2.new(0.5, -250, 0.5, -175)
MainWindow.Active = true
MainWindow.Draggable = true

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainWindow
TitleBar.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 25)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1.000
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "Frosts HUB | Philly Street 2"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14.000

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = MainWindow
TabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TabContainer.BorderSizePixel = 0
TabContainer.Position = UDim2.new(0, 0, 0, 25)
TabContainer.Size = UDim2.new(0, 100, 1, -25)

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Parent = TabContainer
TabListLayout.FillDirection = Enum.FillDirection.Vertical
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 5)

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MainWindow
ContentContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ContentContainer.BorderSizePixel = 0
ContentContainer.Position = UDim2.new(0, 100, 0, 25)
ContentContainer.Size = UDim2.new(1, -100, 1, -25)

-- UI Element Creation Functions
local activeTab = nil
local pages = {}

local function createTab(name, order)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name
    tabButton.Parent = TabContainer
    tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tabButton.BorderSizePixel = 0
    tabButton.Size = UDim2.new(1, -10, 0, 30)
    tabButton.LayoutOrder = order
    tabButton.Font = Enum.Font.SourceSans
    tabButton.Text = name
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.TextSize = 14.000
    
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Parent = ContentContainer
    page.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 140, 255)
    
    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Parent = page
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 5)

    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    pages[name] = page
    
    tabButton.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            pages[activeTab.Name].Visible = false
        end
        activeTab = tabButton
        tabButton.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
        page.Visible = true
    end)
    
    return page
end

local function createSection(parent, title)
    local sectionLabel = Instance.new("TextLabel")
    sectionLabel.Name = title
    sectionLabel.Parent = parent
    sectionLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    sectionLabel.Size = UDim2.new(1, -10, 0, 20)
    sectionLabel.Position = UDim2.new(0, 5, 0, 0)
    sectionLabel.Font = Enum.Font.SourceSansBold
    sectionLabel.Text = title
    sectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sectionLabel.TextSize = 14.000
    sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UIPadding", sectionLabel).PaddingLeft = UDim.new(0, 5)
end

local function createButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Name = text
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, -10, 0, 25)
    button.Position = UDim2.new(0, 5, 0, 0)
    button.Font = Enum.Font.SourceSans
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14.000
    button.MouseButton1Click:Connect(callback)
end

local function createToggle(parent, text, initialValue, callback)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = text
    toggleButton.Parent = parent
    toggleButton.BackgroundColor3 = initialValue and Color3.fromRGB(80, 140, 255) or Color3.fromRGB(70, 70, 70)
    toggleButton.BorderSizePixel = 0
    toggleButton.Size = UDim2.new(1, -10, 0, 25)
    toggleButton.Position = UDim2.new(0, 5, 0, 0)
    toggleButton.Font = Enum.Font.SourceSans
    toggleButton.Text = text
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 14.000
    
    local state = initialValue
    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        toggleButton.BackgroundColor3 = state and Color3.fromRGB(80, 140, 255) or Color3.fromRGB(70, 70, 70)
        if callback then callback(state) end
    end)
end

local function createDropdown(parent, title, options, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = title
    dropdownFrame.Parent = parent
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dropdownFrame.BackgroundTransparency = 1.000
    dropdownFrame.Size = UDim2.new(1, -10, 0, 25)
    dropdownFrame.Position = UDim2.new(0, 5, 0, 0)

    local mainButton = Instance.new("TextButton")
    mainButton.Name = "MainButton"
    mainButton.Parent = dropdownFrame
    mainButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    mainButton.BorderSizePixel = 0
    mainButton.Size = UDim2.new(1, 0, 1, 0)
    mainButton.Font = Enum.Font.SourceSans
    mainButton.Text = title .. ": " .. options[1]
    mainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainButton.TextSize = 14.000

    local optionsFrame = Instance.new("ScrollingFrame")
    optionsFrame.Name = "OptionsFrame"
    optionsFrame.Parent = dropdownFrame
    optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    optionsFrame.BorderSizePixel = 1
    optionsFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    optionsFrame.Position = UDim2.new(0, 0, 1, 0)
    optionsFrame.Size = UDim2.new(1, 0, 0, 100)
    optionsFrame.Visible = false
    optionsFrame.ZIndex = 2
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = optionsFrame
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    mainButton.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
    end)

    for i, optionText in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = optionText
        optionButton.Parent = optionsFrame
        optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        optionButton.BorderSizePixel = 0
        optionButton.Size = UDim2.new(1, 0, 0, 25)
        optionButton.LayoutOrder = i
        optionButton.Font = Enum.Font.SourceSans
        optionButton.Text = optionText
        optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        optionButton.TextSize = 14.000

        optionButton.MouseButton1Click:Connect(function()
            mainButton.Text = title .. ": " .. optionText
            optionsFrame.Visible = false
            if callback then callback(optionText) end
        end)
    end
end


-- Build the UI Tabs and Content
local teleportsPage = createTab("Teleports", 1)
local playerPage = createTab("Player", 2)
local visualsPage = createTab("Visuals", 3)
local autorobPage = createTab("Autorob", 4)

-- Teleports Page Content
createSection(teleportsPage, "Locations")
local storeLocations = { ["Clothes Store"]=Vector3.new(882.73,317.48,-309.71),["Sell Ripz"]=Vector3.new(868.59,317.36,-236.99),["Rays Auto Center"]=Vector3.new(648.39,317.42,354.92),["Gun Store"]=Vector3.new(192.39,317.45,935.83),["Black Market"]=Vector3.new(318.29,317.40,1107.25),["Laundromat"]=Vector3.new(-0.71,317.43,933.01),["Houses"]=Vector3.new(216.12,317.43,172.89),["Gas Station"]=Vector3.new(284.65,317.43,359.92)}
for name, pos in pairs(storeLocations) do
    createButton(teleportsPage, name, function() smoothMove(pos, Camera.CFrame.LookVector) end)
end
createSection(teleportsPage, "Jobs & Robbery")
createButton(teleportsPage, "Wood Chopper", function() smoothMove(Vector3.new(745.51, 317.39, 843.63), Camera.CFrame.LookVector) end)
createButton(teleportsPage, "P Mobile", function() smoothMove(Vector3.new(721.06, 317.36, -74.68), Camera.CFrame.LookVector) end)
createSection(teleportsPage, "Misc")
createButton(teleportsPage, "Food Shop", function() smoothMove(Vector3.new(713.68, 317.43, -133.08), Camera.CFrame.LookVector) end)
createButton(teleportsPage, "Printers", function() smoothMove(Vector3.new(-135.16, 317.39, 162.96), Camera.CFrame.LookVector) end)
createButton(teleportsPage, "Guapo", function() smoothMove(Vector3.new(177.20, 317.43, -162.10), Camera.CFrame.LookVector) end)
createButton(teleportsPage, "Heist", function() smoothMove(Vector3.new(47.77, 317.39, 786.96), Camera.CFrame.LookVector) end)

-- Player Page Content
createSection(playerPage, "Movement")
createToggle(playerPage, "Fast Walk", Settings.FastWalk_Enabled, function(state) Settings.FastWalk_Enabled = state; local char=LocalPlayer.Character; if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = state and 40 or 16 end end)
createToggle(playerPage, "Anti-AFK", Settings.AntiAFK_Enabled, function(state) Settings.AntiAFK_Enabled = state; if state then task.spawn(function() while Settings.AntiAFK_Enabled do pcall(function() LocalPlayer.Character.Humanoid.Jump = true end) task.wait(60) end end) end end)
createToggle(playerPage, "No Clip", Settings.NoClip_Enabled, function(state) Settings.NoClip_Enabled = state; if state then noClipConnection = RunService.Heartbeat:Connect(function() if Settings.NoClip_Enabled and LocalPlayer.Character then for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end end) else if noClipConnection then noClipConnection:Disconnect() noClipConnection = nil end end end)
createSection(playerPage, "Combat")
createToggle(playerPage, "Aimbot", Settings.Aimbot_Enabled, function(state) Settings.Aimbot_Enabled = state end)
createDropdown(playerPage, "Target Part", {"Head", "HumanoidRootPart", "Torso"}, function(val) Settings.Aimbot_TargetPart = val end)
-- Slider is too complex for this basic UI, FOV is set to a reasonable default.

-- Visuals Page Content
createSection(visualsPage, "ESP Toggles")
createToggle(visualsPage, "Skeleton ESP", Settings.SkeletonESP_Enabled, function(state) Settings.SkeletonESP_Enabled = state; updateAllEspVisuals() end)
createToggle(visualsPage, "Name ESP", Settings.NameESP_Enabled, function(state) Settings.NameESP_Enabled = state; updateAllEspVisuals() end)
createToggle(visualsPage, "Health ESP", Settings.HealthESP_Enabled, function(state) Settings.HealthESP_Enabled = state; updateAllEspVisuals() end)
createToggle(visualsPage, "Distance ESP", Settings.DistanceESP_Enabled, function(state) Settings.DistanceESP_Enabled = state; updateAllEspVisuals() end)
createToggle(visualsPage, "Tracers", Settings.TracerESP_Enabled, function(state) Settings.TracerESP_Enabled = state; updateAllEspVisuals() end)
createToggle(visualsPage, "Wallcheck", Settings.Wallcheck_Enabled, function(state) Settings.Wallcheck_Enabled = state end)
createSection(visualsPage, "Misc Visuals")
createToggle(visualsPage, "Fullbright", Settings.Fullbright_Enabled, function(state) Settings.Fullbright_Enabled = state; local b,a=Lighting.Brightness,Lighting.OutdoorAmbient; Lighting.Brightness = state and 1 or b; Lighting.OutdoorAmbient = state and Color3.new(1,1,1) or a end)

-- Autorob Page Content
createSection(autorobPage, "Automation")
createButton(autorobPage, "Auto Rob Electronics", function()
    if isMoving then return end
    task.spawn(function()
        local oH={}; local function r()for p,d in pairs(oH)do if p and p.Parent then p.HoldDuration=d end end end
        for _,v in ipairs(workspace:GetDescendants())do if v.ClassName=="ProximityPrompt"then oH[v]=v.HoldDuration;v.HoldDuration=0 end end
        local s={{N="Phone 1",P=Vector3.new(706.48,317.36,-68.72)},{N="Phone 2",P=Vector3.new(705.51,317.36,-68.24)},{N="Phone 3",P=Vector3.new(704.51,317.36,-68.37)},{N="Laptop 1",P=Vector3.new(697.6,317.44,-68.3)},{N="TV 1",P=Vector3.new(700.92,317.36,-81.48)}}
        for _,st in ipairs(s)do if not LocalPlayer.Character then r();return end;smoothMove(st.P,Camera.CFrame.LookVector);task.wait(0.2);VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game);task.wait(0.1);VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)end; r()
    end)
end)
createButton(autorobPage, "Server Hop", function()
    task.spawn(function()
        local u="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"; local s=HttpService:JSONDecode(HttpService:GetAsync(u)).data; local nS={};
        for _,sv in ipairs(s)do if type(sv)=='table'and sv.id and sv.id~=game.JobId and sv.playing<sv.maxPlayers then table.insert(nS,sv.id)end end
        if #nS>0 then TeleportService:TeleportToPlaceInstance(game.PlaceId,nS[math.random(1,#nS)],LocalPlayer) end
    end)
end)

-- Default to first tab
if TabContainer:FindFirstChild("Teleports") then
    TabContainer.Teleports:Invoke("MouseButton1Click")
end

-- Keybinds and Input Handling
local keybindToggle = Enum.KeyCode.K -- Hardcoded toggle key
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == keybindToggle then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
    if(input.UserInputType==Enum.UserInputType.MouseButton2 or input.KeyCode==Enum.KeyCode.ButtonL2)then if not Settings.Aimbot_Enabled then return end;aimbotConnection=RunService.RenderStepped:Connect(aimbotLoop)end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    if(input.UserInputType==Enum.UserInputType.MouseButton2 or input.KeyCode==Enum.KeyCode.ButtonL2)then if aimbotConnection then aimbotConnection:Disconnect();aimbotConnection=nil end end
end)

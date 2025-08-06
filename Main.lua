local P=game:GetService("Players")
local RS=game:GetService("RunService")
local C=workspace.CurrentCamera
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local LP=P.LocalPlayer
local a=false
local t="Head"
local md=math.huge
local SG=Instance.new("ScreenGui")
SG.Name="ScriptGUI"
SG.Parent=LP:WaitForChild("PlayerGui")
local AF=Instance.new("Frame")
AF.Visible=true
AF.Size=UDim2.new(0,500,0,100)
AF.Position=UDim2.new(0.5,-250,0.5,-50)
AF.BackgroundColor3=Color3.new(0.08,0.08,0.08)
AF.BorderSizePixel=0
AF.Parent=SG
local FC=Instance.new("UICorner")
FC.CornerRadius=UDim.new(0,12)
FC.Parent=AF
local FS=Instance.new("UIStroke")
FS.Color=Color3.new(0,0.635294,1)
FS.Thickness=2
FS.Transparency=0.8
FS.Parent=AF
local TB=Instance.new("Frame")
TB.Size=UDim2.new(1,0,0,35)
TB.BackgroundColor3=Color3.new(0.12,0.12,0.12)
TB.Parent=AF
local TBC=Instance.new("UICorner")
TBC.CornerRadius=UDim.new(0,12)
TBC.Parent=TB
local TBG=Instance.new("UIGradient")
TBG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,0.635294,1)),ColorSequenceKeypoint.new(1,Color3.new(0.08,0.08,0.08))})
TBG.Parent=TB
local T=Instance.new("TextLabel")
T.Size=UDim2.new(1,0,1,0)
T.Text="Dino's Universal Aimbot"
T.Font=Enum.Font.RobotoMono
T.TextColor3=Color3.new(1,1,1)
T.BackgroundTransparency=1
T.TextXAlignment=Enum.TextXAlignment.Center
T.Parent=TB
local D=false
local dS,iP
TB.InputBegan:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
D=true
dS=i.Position
iP=AF.Position
end
end)
TB.InputEnded:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
D=false
end
end)
UIS.InputChanged:Connect(function(i)
if D and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then
local d=i.Position-dS
AF.Position=UDim2.new(iP.X.Scale,iP.X.Offset+d.X,iP.Y.Scale,iP.Y.Offset+d.Y)
end
end)
local CF=Instance.new("Frame")
CF.Size=UDim2.new(1,-20,1,-45)
CF.Position=UDim2.new(0,10,0,35)
CF.BackgroundTransparency=1
CF.Parent=AF
local CL=Instance.new("UIListLayout")
CL.FillDirection=Enum.FillDirection.Horizontal
CL.Padding=UDim.new(0,15)
CL.HorizontalAlignment=Enum.HorizontalAlignment.Center
CL.Parent=CF
local TB=Instance.new("TextButton")
TB.Name="AimbotToggle"
TB.Size=UDim2.new(0,100,0.8,0)
TB.Text="Aimbot: OFF"
TB.Font=Enum.Font.RobotoMono
TB.TextColor3=Color3.new(1,1,1)
TB.BackgroundColor3=Color3.new(0.2,0.2,0.2)
TB.Parent=CF
local TC=Instance.new("UICorner")
TC.CornerRadius=UDim.new(0,8)
TC.Parent=TB
local TS=Instance.new("UIStroke")
TS.Color=Color3.new(0.4,0.4,0.4)
TS.Thickness=1
TS.Parent=TB
TB.MouseButton1Click:Connect(function()
a=not a
if a then
TB.Text="Aimbot: ON"
TB.BackgroundColor3=Color3.new(0.121569,0.482353,0.129412)
TS.Color=Color3.new(0.121569,0.8,0.129412)
else
TB.Text="Aimbot: OFF"
TB.BackgroundColor3=Color3.new(0.482353,0.121569,0.121569)
TS.Color=Color3.new(0.8,0.121569,0.121569)
end
end)
local DB=Instance.new("TextButton")
DB.Size=UDim2.new(0,100,0.8,0)
DB.Text=t
DB.Font=Enum.Font.RobotoMono
DB.TextColor3=Color3.new(1,1,1)
DB.BackgroundColor3=Color3.new(0.12,0.12,0.12)
DB.Parent=CF
local DC=Instance.new("UICorner")
DC.CornerRadius=UDim.new(0,8)
DC.Parent=DB
local DS=Instance.new("UIStroke")
DS.Color=Color3.new(0.4,0.4,0.4)
DS.Thickness=1
DS.Parent=DB
local DM=Instance.new("Frame")
DM.Visible=false
DM.Size=UDim2.new(0,100,0,100)
DM.BackgroundColor3=Color3.new(0.12,0.12,0.12)
DM.Position=UDim2.new(0.05,0,0.05,100)
DM.Parent=AF
local MC=Instance.new("UICorner")
MC.CornerRadius=UDim.new(0,8)
MC.Parent=DM
local ML=Instance.new("UIListLayout")
ML.FillDirection=Enum.FillDirection.Vertical
ML.Padding=UDim.new(0,2)
ML.Parent=DM
local to={"Head","Neck","Torso","Feet"}
for _,pn in pairs(to)do
local OB=Instance.new("TextButton")
OB.Size=UDim2.new(1,0,0,25)
OB.Text=pn
OB.Font=Enum.Font.RobotoMono
OB.TextColor3=Color3.new(1,1,1)
OB.BackgroundColor3=Color3.new(0.2,0.2,0.2)
OB.Parent=DM
OB.MouseButton1Click:Connect(function()
t=pn
DB.Text=pn
DM.Visible=false
print("Aimbot target set to: "..t)
end)
end
DB.MouseButton1Click:Connect(function()
DM.Visible=not DM.Visible
end)
local UB=Instance.new("TextButton")
UB.Name="UninjectButton"
UB.Size=UDim2.new(0,100,0.8,0)
UB.Text="Uninject"
UB.Font=Enum.Font.RobotoMono
UB.TextColor3=Color3.new(1,1,1)
UB.BackgroundColor3=Color3.new(0.68,0.1,0.1)
UB.Parent=CF
local UC=Instance.new("UICorner")
UC.CornerRadius=UDim.new(0,8)
UC.Parent=UB
local US=Instance.new("UIStroke")
US.Color=Color3.new(0.8,0.1,0.1)
US.Thickness=1
US.Parent=UB
UB.MouseButton1Click:Connect(function()
SG:Destroy()
script:Destroy()
end)
RS.Stepped:Connect(function()
if a then
local cT=nil
local cD=math.huge
local pTA=nil
for _,p in pairs(P:GetPlayers())do
if p~=LP and p.Character and p.Character:FindFirstChild("Humanoid")and p.Character.Humanoid.Health>0 then
local tHRP=p.Character:FindFirstChild("HumanoidRootPart")
if tHRP then
local d=(LP.Character.HumanoidRootPart.Position-tHRP.Position).Magnitude
if d<md and d<cD then
cD=d
cT=tHRP
pTA=p
end
end
end
end
if cT then
local tP=pTA.Character:FindFirstChild(t)
if tP then
local nC=CFrame.new(C.CFrame.Position,tP.Position)
C.CFrame=C.CFrame:Lerp(nC,0.5)
end
end
end
end)

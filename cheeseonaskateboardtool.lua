local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local espOn = false
local aimbotEnabled = false
local aiming = false
local ignoreFriends = false
local target = nil

local espObjects = {}
local SWAP_RADIUS = 500

-- Movement
local flyEnabled = false
local flySpeed = 50
local walkSpeed = 16
local flying = false
local flyConnection = nil
local flyBodies = {}

-- ESP Color
local espColor = Color3.fromRGB(255,0,0)

--------------------------------------------------
-- ESP SYSTEM
--------------------------------------------------

local function createESP(character)
	if espObjects[character] then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	if not humanoid or not head then return end
	
	local highlight = Instance.new("Highlight")
	highlight.FillColor = espColor
	highlight.FillTransparency = 0.5
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
	
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0,200,0,50)
	billboard.StudsOffset = Vector3.new(0,2.5,0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1,0,1,0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1,1,1)
	text.TextStrokeTransparency = 0
	text.Font = Enum.Font.SourceSansBold
	text.TextScaled = true
	text.Parent = billboard
	
	task.spawn(function()
		while humanoid.Parent and espOn do
			text.Text = character.Name .. "\nHP: " .. math.floor(humanoid.Health)
			if highlight.Parent then
				highlight.FillColor = espColor
			end
			task.wait(0.1)
		end
	end)
	
	espObjects[character] = {
		highlight = highlight,
		gui = billboard
	}
end

local function clearESP()
	for _, obj in pairs(espObjects) do
		if obj.highlight then obj.highlight:Destroy() end
		if obj.gui then obj.gui:Destroy() end
	end
	espObjects = {}
end

--------------------------------------------------
-- FRIEND CHECK
--------------------------------------------------

local function isFriend(plr)
	return localPlayer:IsFriendsWith(plr.UserId)
end

--------------------------------------------------
-- TARGETING
--------------------------------------------------

local function getClosestTarget()
	local closest = nil
	local shortest = math.huge
	
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= localPlayer and plr.Character then
			
			if ignoreFriends and isFriend(plr) then
				continue
			end
			
			local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
			local head = plr.Character:FindFirstChild("Head")
			
			if humanoid and head and humanoid.Health > 0 then
				
				local pos,onScreen = camera:WorldToViewportPoint(head.Position)
				
				if onScreen then
					local center = Vector2.new(
						camera.ViewportSize.X/2,
						camera.ViewportSize.Y/2
					)
					
					local dist = (Vector2.new(pos.X,pos.Y)-center).Magnitude
					
					if dist < shortest then
						shortest = dist
						closest = plr.Character
					end
				end
			end
		end
	end
	
	return closest
end

--------------------------------------------------
-- FLY SYSTEM
--------------------------------------------------

local function startFlying()
	if flying then return end
	flying = true
	
	local char = localPlayer.Character
	if not char then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
	bv.Velocity = Vector3.zero
	bv.Parent = root
	
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
	bg.P = 10000
	bg.Parent = root
	
	flyBodies = {bv= bv, bg= bg, root=root}
	
	flyConnection = RunService.RenderStepped:Connect(function()
		if not flyEnabled then return end
		
		bg.CFrame = camera.CFrame
		
		local dir = Vector3.zero
		
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
		
		if dir.Magnitude > 0 then
			dir = dir.Unit
		end
		
		bv.Velocity = dir * flySpeed
	end)
end

local function stopFlying()
	flying = false
	
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	
	local char = localPlayer.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		
		if root then
			root.Velocity = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		
		if hum then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end
	
	for _,v in pairs(flyBodies) do
		if typeof(v) == "Instance" then
			v:Destroy()
		end
	end
	
	flyBodies = {}
end

--------------------------------------------------
-- WALK SPEED
--------------------------------------------------

local function updateWalkSpeed()
	local char = localPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = walkSpeed
		end
	end
end

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.1)
	updateWalkSpeed()
end)

--------------------------------------------------
-- AIMBOT
--------------------------------------------------

UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = true
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = false
	end
end)

RunService.RenderStepped:Connect(function()
	if not aimbotEnabled or not aiming then return end
	
	target = getClosestTarget()
	if not target then return end
	
	local head = target:FindFirstChild("Head")
	if head then
		camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
	end
end)

--------------------------------------------------
-- PLAYER HOOK
--------------------------------------------------

local function onPlayer(plr)
	plr.CharacterAdded:Connect(function(char)
		if espOn and plr ~= localPlayer then
			task.wait(0.5)
			createESP(char)
		end
	end)
end

for _,p in pairs(Players:GetPlayers()) do onPlayer(p) end
Players.PlayerAdded:Connect(onPlayer)

--------------------------------------------------
-- UI
--------------------------------------------------

task.spawn(function()

local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local Window = Library:CreateWindow({
	Title = "Cheeseyonaskateboard",
	SubTitle = "Universal Cheat Script",
	TabWidth = 120,
	Size = UDim2.fromOffset(700,560),
	Theme = "Darker",
	MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
	Combat = Window:CreateTab({Title="Combat"}),
	Visuals = Window:CreateTab({Title="Visuals"}),
	Tools = Window:CreateTab({Title="Tools"})
}

--------------------------------------------------
-- COMBAT
--------------------------------------------------

Tabs.Combat:CreateToggle("Aimbot",{
	Title="Aimbot",
	Default=false,
	Callback=function(v)
		aimbotEnabled=v
	end
})

--------------------------------------------------
-- VISUALS
--------------------------------------------------

Tabs.Visuals:CreateToggle("ESP",{
	Title="ESP",
	Default=false,
	Callback=function(v)
		espOn=v
		if v then
			for _,p in pairs(Players:GetPlayers()) do
				if p~=localPlayer and p.Character then
					createESP(p.Character)
				end
			end
		else
			clearESP()
		end
	end
})

Tabs.Visuals:CreateColorPicker("ESPColor",{
	Title="ESP Color",
	Default=espColor,
	Callback=function(v)
		espColor=v
	end
})

--------------------------------------------------
-- TOOLS
--------------------------------------------------

Tabs.Tools:CreateToggle("Fly",{
	Title="Fly",
	Default=false,
	Callback=function(v)
		flyEnabled=v
		if v then startFlying() else stopFlying() end
	end
})

Tabs.Tools:CreateSlider("FlySpeed",{
	Title="Fly Speed",
	Min=10,
	Max=200,
	Default=50,
	Callback=function(v)
		flySpeed=v
	end
})

Tabs.Tools:CreateSlider("WalkSpeed",{
	Title="Walk Speed",
	Min=5,
	Max=100,
	Default=16,
	Callback=function(v)
		walkSpeed=v
		updateWalkSpeed()
	end
})

end)

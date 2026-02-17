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

-- Tools settings
local flyEnabled = false
local flySpeed = 50
local walkSpeed = 16
local flying = false
local flyConnection = nil

-- ESP color settings
local espColor = Color3.fromRGB(255, 0, 0)

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
			text.Text =
				character.Name ..
				"\nHP: " ..
				math.floor(humanoid.Health)
			-- Update highlight color dynamically
			if highlight and highlight.Parent then
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
-- TARGET FUNCTIONS
--------------------------------------------------

local function getTargetsInRadius()
	local list = {}
	
	local myChar = localPlayer.Character
	if not myChar then return list end
	
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return list end
	
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= localPlayer and plr.Character then
			
			if ignoreFriends and isFriend(plr) then
				continue
			end
			
			local humanoid =
				plr.Character:FindFirstChildOfClass("Humanoid")
			local root =
				plr.Character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and root and humanoid.Health > 0 then
				
				local dist =
					(root.Position - myRoot.Position).Magnitude
				
				if dist <= SWAP_RADIUS then
					table.insert(list,{
						char = plr.Character,
						dist = dist
					})
				end
			end
		end
	end
	
	table.sort(list,function(a,b)
		return a.dist < b.dist
	end)
	
	return list
end

local function getClosestTarget()
	local closest = nil
	local shortest = math.huge
	
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= localPlayer and plr.Character then
			
			if ignoreFriends and isFriend(plr) then
				continue
			end
			
			local humanoid =
				plr.Character:FindFirstChildOfClass("Humanoid")
			local head =
				plr.Character:FindFirstChild("Head")
			
			if humanoid and head and humanoid.Health > 0 then
				
				local pos,onScreen =
					camera:WorldToViewportPoint(head.Position)
				
				if onScreen then
					local center = Vector2.new(
						camera.ViewportSize.X/2,
						camera.ViewportSize.Y/2
					)
					
					local dist =
						(Vector2.new(pos.X,pos.Y)-center).Magnitude
					
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
	
	local myChar = localPlayer.Character
	if not myChar then return end
	
	local rootPart = myChar:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Create BodyVelocity for flying
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Parent = rootPart
	
	-- Create BodyGyro for rotation
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 10000
	bodyGyro.Parent = rootPart
	
	flyConnection = RunService.RenderStepped:Connect(function()
		if not flyEnabled or not flying or not rootPart.Parent then
			if flyConnection then
				flyConnection:Disconnect()
				flyConnection = nil
			end
			if bodyVelocity then bodyVelocity:Destroy() end
			if bodyGyro then bodyGyro:Destroy() end
			flying = false
			return
		end
		
		bodyGyro.CFrame = camera.CFrame
		
		local moveDirection = Vector3.new(0, 0, 0)
		if UIS:IsKeyDown(Enum.KeyCode.W) then
			moveDirection = moveDirection + (camera.CFrame.LookVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then
			moveDirection = moveDirection - (camera.CFrame.LookVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then
			moveDirection = moveDirection - (camera.CFrame.RightVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) then
			moveDirection = moveDirection + (camera.CFrame.RightVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			moveDirection = moveDirection + Vector3.new(0, 1, 0)
		end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			moveDirection = moveDirection - Vector3.new(0, 1, 0)
		end
		
		if moveDirection.Magnitude > 0 then
			moveDirection = moveDirection.Unit
		end
		
		bodyVelocity.Velocity = moveDirection * flySpeed
	end)
end

local function stopFlying()
	flying = false
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
end

--------------------------------------------------
-- WALK SPEED SYSTEM
--------------------------------------------------

local function updateWalkSpeed()
	local myChar = localPlayer.Character
	if myChar then
		local humanoid = myChar:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = walkSpeed
		end
	end
end

-- Update walk speed when character spawns
localPlayer.CharacterAdded:Connect(function()
	task.wait(0.1)
	updateWalkSpeed()
end)

--------------------------------------------------
-- INPUT (KEYBOARD SHORTCUTS)
--------------------------------------------------

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = true
	end
end)

UIS.InputEnded:Connect(function(input,gp)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = false
	end
end)

--------------------------------------------------
-- AIMBOT LOOP (RMB HOLD)
--------------------------------------------------

RunService.RenderStepped:Connect(function()
	if not aimbotEnabled or not aiming then return end
	
	target = getClosestTarget()
	
	if not target then return end
	
	local head = target:FindFirstChild("Head")
	
	if head then
		camera.CFrame =
			CFrame.new(
				camera.CFrame.Position,
				head.Position
			)
	end
end)

--------------------------------------------------
-- RESPAWN ESP
--------------------------------------------------

local function onPlayer(plr)
	plr.CharacterAdded:Connect(function(char)
		if espOn and plr ~= localPlayer then
			task.wait(0.5)
			createESP(char)
		end
	end)
end

for _,plr in pairs(Players:GetPlayers()) do
	onPlayer(plr)
end

Players.PlayerAdded:Connect(onPlayer)

--------------------------------------------------
-- FLUENT UI (LOADED IN BACKGROUND)
--------------------------------------------------

task.spawn(function()
	local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
	local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
	local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()
	
	local Window = Library:CreateWindow({
		Title = "Aimbot & ESP",
		SubTitle = "Universal FPS Script",
		TabWidth = 120,
		Size = UDim2.fromOffset(700, 560),
		Acrylic = true,
		Theme = "Darker",
		MinSize = Vector2.new(600, 450),
		MinimizeKey = Enum.KeyCode.RightControl
	})
	
	local Tabs = {
		Combat = Window:CreateTab({
			Title = "Combat",
			Icon = "crosshair"
		}),
		Visuals = Window:CreateTab({
			Title = "Visuals",
			Icon = "eye"
		}),
		Tools = Window:CreateTab({
			Title = "Tools",
			Icon = "wrench"
		}),
		Settings = Window:CreateTab({
			Title = "Settings",
			Icon = "settings"
		}),
		Info = Window:CreateTab({
			Title = "Info",
			Icon = "info"
		})
	}
	
	-- COMBAT TAB
	Tabs.Combat:CreateParagraph("Aimbot", {
		Title = "Aimbot Controls",
		Content = "Hold right mouse button to aim. Auto-targets closest player."
	})
	
	local aimbotToggle = Tabs.Combat:CreateToggle("AimbotToggle", {
		Title = "Aimbot",
		Default = false,
		Callback = function(Value)
			aimbotEnabled = Value
			target = nil
		end
	})
	
	-- VISUALS TAB
	Tabs.Visuals:CreateParagraph("ESP", {
		Title = "Enemy Highlighting",
		Content = "Shows all players with health indicators."
	})
	
	local espToggle = Tabs.Visuals:CreateToggle("ESPToggle", {
		Title = "ESP",
		Default = false,
		Callback = function(Value)
			espOn = Value
			if espOn then
				for _,plr in pairs(Players:GetPlayers()) do
					if plr ~= localPlayer and plr.Character then
						createESP(plr.Character)
					end
				end
			else
				clearESP()
			end
		end
	})
	
	-- TOOLS TAB
	Tabs.Tools:CreateParagraph("Movement", {
		Title = "Movement Tools",
		Content = "Enhance your movement capabilities."
	})
	
	local flyToggle = Tabs.Tools:CreateToggle("FlyToggle", {
		Title = "Fly",
		Default = false,
		Callback = function(Value)
			flyEnabled = Value
			if flyEnabled then
				startFlying()
			else
				stopFlying()
			end
		end
	})
	
	local flySpeedSlider = Tabs.Tools:CreateSlider("FlySpeedSlider", {
		Title = "Fly Speed",
		Description = "Control your flying speed",
		Min = 10,
		Max = 200,
		Default = 50,
		Step = 5,
		Suffix = " speed",
		Callback = function(Value)
			flySpeed = Value
		end
	})
	
	local walkSpeedSlider = Tabs.Tools:CreateSlider("WalkSpeedSlider", {
		Title = "Walk Speed",
		Description = "Control your walking speed",
		Min = 5,
		Max = 100,
		Default = 16,
		Step = 1,
		Suffix = " speed",
		Callback = function(Value)
			walkSpeed = Value
			updateWalkSpeed()
		end
	})
	
	-- SETTINGS TAB
	Tabs.Settings:CreateParagraph("Filters", {
		Title = "Target Filters",
		Content = "Configure who can be targeted."
	})
	
	local friendCheckToggle = Tabs.Settings:CreateToggle("FriendCheck", {
		Title = "Ignore Friends",
		Default = false,
		Callback = function(Value)
			ignoreFriends = Value
		end
	})
	
	local radiusSlider = Tabs.Settings:CreateSlider("RadiusSlider", {
		Title = "Target Radius",
		Description = "Maximum distance to target players",
		Min = 100,
		Max = 2000,
		Default = 500,
		Step = 50,
		Suffix = " studs",
		Callback = function(Value)
			SWAP_RADIUS = Value
		end
	})
	
	-- INFO TAB
	Tabs.Info:CreateParagraph("How to Use", {
		Title = "Getting Started",
		Content = "1. Enable Aimbot in Combat tab\n2. Enable ESP in Visuals tab\n3. Hold right mouse button to aim\n4. Configure settings as needed"
	})
	
	Tabs.Info:CreateParagraph("Controls", {
		Title = "Keyboard Shortcuts",
		Content = "Right Mouse Button - Hold to aim\nRightCtrl - Toggle UI visibility"
	})
	
	Tabs.Info:CreateButton({
		Title = "Load Infinite Yield",
		Description = "Load infinite yield commands",
		Callback = function()
			loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'),true))()
		end
	})
	
	-- Save Manager
	SaveManager:SetLibrary(Library)
	InterfaceManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({})
	InterfaceManager:SetStyle("Dark")
	SaveManager:SetFolder("FluentScriptSettings/AimbotESP")
	InterfaceManager:BuildInterfaceSection(Tabs.Settings)
	SaveManager:BuildConfigSection(Tabs.Settings)
	SaveManager:LoadAutoloadConfig()
end)

--// COMBAT TESTING & DEBUG TOOL
--// LocalScript - StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local LOCK_TOGGLE_KEY = Enum.KeyCode.Q
local LOCK_RADIUS = 150
local LOCK_SMOOTHNESS = 0.15

local ESP_ENABLED = true

--------------------------------------------------
-- STATE
--------------------------------------------------

local lockSystemEnabled = false
local rightClickHeld = false
local currentTarget = nil

--------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------

local function getCharacter(player)
	if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		return player.Character
	end
end

local function isAlive(character)
	local hum = character and character:FindFirstChild("Humanoid")
	return hum and hum.Health > 0
end

--------------------------------------------------
-- TARGET SCAN FUNCTION
--------------------------------------------------

local function getClosestTarget()
	local closest = nil
	local closestAngle = math.huge

	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = getCharacter(player)

			if char and isAlive(char) then
				local hrp = char.HumanoidRootPart
				local distance = (hrp.Position - camPos).Magnitude

				if distance <= LOCK_RADIUS then
					local direction = (hrp.Position - camPos).Unit
					local angle = math.acos(camLook:Dot(direction))

					if angle < closestAngle then
						closestAngle = angle
						closest = char
					end
				end
			end
		end
	end

	return closest
end

--------------------------------------------------
-- CAMERA LOCK FUNCTION
--------------------------------------------------

local function updateLock()
	if not lockSystemEnabled then return end
	if not rightClickHeld then return end

	-- Recalculate target every hold
	currentTarget = getClosestTarget()

	if not currentTarget then return end

	local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local camCF = Camera.CFrame
	local targetCF = CFrame.new(camCF.Position, hrp.Position)

	Camera.CFrame = camCF:Lerp(targetCF, LOCK_SMOOTHNESS)
end

RunService.RenderStepped:Connect(function()
	if currentTarget and not isAlive(currentTarget) then
		currentTarget = nil
	end

	updateLock()
end)

--------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	-- Toggle system
	if input.KeyCode == LOCK_TOGGLE_KEY then
		lockSystemEnabled = not lockSystemEnabled
		print("Lock System:", lockSystemEnabled and "ENABLED" or "DISABLED")
	end

	-- Right click hold
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = false
		currentTarget = nil
	end
end)

--------------------------------------------------
-- ESP SYSTEM
--------------------------------------------------

local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_FOLDER"
espFolder.Parent = workspace

local function createESP(player)
	if player == LocalPlayer then return end

	local function attach(char)
		local head = char:WaitForChild("Head", 5)
		local hum = char:WaitForChild("Humanoid", 5)

		if not head or not hum then return end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ESP"
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 80, 80)
		label.TextStrokeTransparency = 0
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.Parent = billboard

		-- Update text
		local function update()
			label.Text =
				player.Name ..
				" | HP: " ..
				math.floor(hum.Health)
		end

		update()

		hum.HealthChanged:Connect(update)
	end

	-- Handle respawns
	if player.Character then
		attach(player.Character)
	end

	player.CharacterAdded:Connect(attach)
end

--------------------------------------------------
-- INITIALIZE ESP
--------------------------------------------------

if ESP_ENABLED then
	for _, plr in pairs(Players:GetPlayers()) do
		createESP(plr)
	end

	Players.PlayerAdded:Connect(createESP)
end

--------------------------------------------------
-- DEBUG UI PRINT
--------------------------------------------------

print("Combat Testing Tool Loaded")
print("Press Q to toggle Lock-On")
print("Hold Right Click to aim-lock")

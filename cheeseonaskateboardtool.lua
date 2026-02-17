local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

--------------------------------------------------
-- GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "CmdConsole"
gui.ResetOnSpawn = false
gui.Parent = lp.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,300,0,150)
frame.Position = UDim2.new(1,-310,1,-160)
frame.BackgroundTransparency = 0.2
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.Visible = false
frame.Parent = gui

local box = Instance.new("TextBox")
box.Size = UDim2.new(1,-10,0,30)
box.Position = UDim2.new(0,5,1,-35)
box.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
box.TextColor3 = Color3.new(1,1,1)
box.ClearTextOnFocus = false
box.Text = ""
box.Parent = frame

local suggestions = Instance.new("TextLabel")
suggestions.Size = UDim2.new(1,-10,1,-40)
suggestions.Position = UDim2.new(0,5,0,5)
suggestions.BackgroundTransparency = 1
suggestions.TextColor3 = Color3.new(1,1,1)
suggestions.TextXAlignment = Enum.TextXAlignment.Left
suggestions.TextYAlignment = Enum.TextYAlignment.Top
suggestions.Font = Enum.Font.Code
suggestions.TextSize = 14
suggestions.Text = ""
suggestions.Parent = frame

--------------------------------------------------
-- NOTIFICATIONS (FIXED)
--------------------------------------------------

local function notify(msg)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0,260,0,30)
	label.Position = UDim2.new(1,-270,1,-200)
	label.BackgroundColor3 = Color3.new(0,0,0)
	label.BackgroundTransparency = 0.3
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 18
	label.Text = msg
	label.Parent = gui

	task.delay(2,function()
		label:Destroy()
	end)
end

--------------------------------------------------
-- COMMANDS
--------------------------------------------------

local commands = {"fly","speed","goto","swp","wp","noclip"}
local waypoints = {}

--------------------------------------------------
-- AUTOCOMPLETE
--------------------------------------------------

local function updateSuggestions(text)
	text = text:lower()
	local list = {}

	for _,cmd in pairs(commands) do
		if cmd:sub(1,#text) == text then
			table.insert(list,cmd)
		end
	end

	suggestions.Text = table.concat(list,"\n")
end

box:GetPropertyChangedSignal("Text"):Connect(function()
	updateSuggestions(box.Text)
end)

--------------------------------------------------
-- PLAYER FIND
--------------------------------------------------

local function findPlayer(str)
	str = (str or ""):lower()

	for _,plr in pairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Name:lower():find(str) then
			return plr
		end
	end
end

--------------------------------------------------
-- FLY (ACTUALLY FIXED)
--------------------------------------------------

local flying = false
local flySpeed = 50
local bodyVel, bodyGyro

local function toggleFly(speed)
	flying = not flying

	if flying then
		flySpeed = tonumber(speed) or 50

		bodyVel = Instance.new("BodyVelocity")
		bodyVel.MaxForce = Vector3.new(9e9,9e9,9e9)
		bodyVel.Velocity = Vector3.zero
		bodyVel.Parent = root

		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
		bodyGyro.P = 9e4
		bodyGyro.CFrame = cam.CFrame
		bodyGyro.Parent = root

		hum.PlatformStand = true

		notify("Fly Enabled ("..flySpeed..")")

	else
		if bodyVel then bodyVel:Destroy() end
		if bodyGyro then bodyGyro:Destroy() end

		hum.PlatformStand = false

		notify("Fly Disabled")
	end
end

RunService.RenderStepped:Connect(function()
	if not flying or not bodyVel then return end

	bodyGyro.CFrame = cam.CFrame

	local move = hum.MoveDirection
	local worldMove = cam.CFrame:VectorToWorldSpace(move)

	bodyVel.Velocity = worldMove * flySpeed
end)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local noclip = false

RunService.Stepped:Connect(function()
	if not noclip then return end

	for _,v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
end)

local function toggleNoclip()
	noclip = not noclip

	if noclip then
		notify("Noclip Enabled")
	else
		notify("Noclip Disabled")
	end
end

--------------------------------------------------
-- SPEED
--------------------------------------------------

local defaultSpeed = 16

local function toggleSpeed(val)
	if hum.WalkSpeed ~= defaultSpeed then
		hum.WalkSpeed = defaultSpeed
		notify("Speed Reset")
	else
		hum.WalkSpeed = tonumber(val) or 50
		notify("Speed "..hum.WalkSpeed)
	end
end

--------------------------------------------------
-- WAYPOINTS
--------------------------------------------------

local function setWaypoint(name)
	if not name then return end
	waypoints[name] = root.Position
	notify("Waypoint '"..name.."' Set")
end

local function gotoWaypoint(name)
	if waypoints[name] then
		root.CFrame = CFrame.new(waypoints[name])
		notify("Teleported to '"..name.."'")
	end
end

--------------------------------------------------
-- RUN COMMAND
--------------------------------------------------

local function runCommand(text)
	local args = text:split(" ")
	local cmd = (args[1] or ""):lower()

	if cmd == "fly" then
		toggleFly(args[2])
	elseif cmd == "speed" then
		toggleSpeed(args[2])
	elseif cmd == "goto" then
		local plr = findPlayer(args[2])
		if plr and plr.Character then
			root.CFrame = plr.Character.HumanoidRootPart.CFrame
			notify("Teleported to "..plr.Name)
		end
	elseif cmd == "swp" then
		setWaypoint(args[2])
	elseif cmd == "wp" then
		gotoWaypoint(args[2])
	elseif cmd == "noclip" then
		toggleNoclip()
	end
end

--------------------------------------------------
-- INPUT (FULLY FIXED)
--------------------------------------------------

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end

	-- TOGGLE CONSOLE
	if input.KeyCode == Enum.KeyCode.Semicolon then

		frame.Visible = not frame.Visible

		if frame.Visible then
			box.Text = ""          -- stops ";" appearing
			task.wait()            -- ensures focus next frame
			box:CaptureFocus()
		else
			box:ReleaseFocus()
		end

		return -- prevents typing ";"
	end

	-- SUBMIT COMMAND (INSTANT)
	if input.KeyCode == Enum.KeyCode.Return then
		if frame.Visible then
			runCommand(box.Text)
			box.Text = ""
			return
		end
	end
end)

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
-- CONFIRMATION POPUP
--------------------------------------------------

local function notify(msg)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0,250,0,30)
	label.Position = UDim2.new(1,-260,1,-200)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.new(0,0,0)
	label.TextColor3 = Color3.new(1,1,1)
	label.Text = msg
	label.Parent = gui
	
	task.delay(2,function()
		label:Destroy()
	end)
end

--------------------------------------------------
-- COMMAND DATA
--------------------------------------------------

local commands = {
	"fly",
	"speed",
	"goto",
	"swp",
	"wp",
	"noclip"
}

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
		if plr ~= lp then
			if plr.Name:lower():find(str) then
				return plr
			end
		end
	end
end

--------------------------------------------------
-- FLY (FIXED)
--------------------------------------------------

local flying = false
local flySpeed = 50
local bv, bg

local function toggleFly(speed)
	flying = not flying
	
	if flying then
		flySpeed = tonumber(speed) or 50
		
		bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e6,1e6,1e6)
		bv.Velocity = Vector3.zero
		bv.Parent = root
		
		bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1e6,1e6,1e6)
		bg.CFrame = root.CFrame
		bg.Parent = root
		
		notify("Fly Enabled ("..flySpeed..")")
	else
		if bv then bv:Destroy() end
		if bg then bg:Destroy() end
		
		notify("Fly Disabled")
	end
end

RunService.RenderStepped:Connect(function()
	if not flying or not bv then return end
	
	bg.CFrame = cam.CFrame
	
	local moveDir = hum.MoveDirection
	local camDir = cam.CFrame:VectorToWorldSpace(moveDir)
	
	bv.Velocity = camDir * flySpeed
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
-- COMMAND RUNNER
--------------------------------------------------

local function runCommand(text)
	local args = text:split(" ")
	local cmd = (args[1] or ""):lower()
	
	if cmd == "fly" then
		toggleFly(args[2])
	end
	
	if cmd == "speed" then
		toggleSpeed(args[2])
	end
	
	if cmd == "goto" then
		local plr = findPlayer(args[2])
		if plr and plr.Character then
			root.CFrame =
				plr.Character.HumanoidRootPart.CFrame
			notify("Teleported to "..plr.Name)
		end
	end
	
	if cmd == "swp" then
		setWaypoint(args[2])
	end
	
	if cmd == "wp" then
		gotoWaypoint(args[2])
	end
	
	if cmd == "noclip" then
		toggleNoclip()
	end
end

--------------------------------------------------
-- OPEN / CLOSE (;)
--------------------------------------------------

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	
	if input.KeyCode == Enum.KeyCode.Semicolon then
		
		frame.Visible = not frame.Visible
		
		if frame.Visible then
			box.Text = "" -- prevents ; appearing
			box:CaptureFocus()
		else
			box:ReleaseFocus()
		end
	end
	
	if input.KeyCode == Enum.KeyCode.Return then
		if frame.Visible then
			runCommand(box.Text)
			box.Text = ""
		end
	end
end)

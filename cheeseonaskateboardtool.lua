local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

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
-- TOGGLES
--------------------------------------------------

local flying = false
local noclip = false
local flySpeed = 50

local bv, bg

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
-- PLAYER FIND (PARTIAL)
--------------------------------------------------

local function findPlayer(str)
	str = str:lower()
	
	for _,plr in pairs(Players:GetPlayers()) do
		if plr ~= lp then
			if plr.Name:lower():find(str) then
				return plr
			end
		end
	end
end

--------------------------------------------------
-- FLY
--------------------------------------------------

local function toggleFly(speed)
	flying = not flying
	
	if flying then
		flySpeed = tonumber(speed) or 50
		
		bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e5,1e5,1e5)
		bv.Parent = root
		
		bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
		bg.Parent = root
		
	else
		if bv then bv:Destroy() end
		if bg then bg:Destroy() end
	end
end

RunService.RenderStepped:Connect(function()
	if flying and bv and bg then
		bg.CFrame = workspace.CurrentCamera.CFrame
		
		local move = hum.MoveDirection
		bv.Velocity = workspace.CurrentCamera.CFrame:VectorToWorldSpace(move) * flySpeed
	end
end)

--------------------------------------------------
-- NOCLIP (SMART FLOOR KEEP)
--------------------------------------------------

RunService.Stepped:Connect(function()
	if not noclip then return end
	
	for _,v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			
			-- Keep floor collision if grounded
			if hum.FloorMaterial ~= Enum.Material.Air and not flying then
				if v.Position.Y < root.Position.Y - 2 then
					v.CanCollide = true
				else
					v.CanCollide = false
				end
			else
				v.CanCollide = false
			end
			
		end
	end
end)

local function toggleNoclip()
	noclip = not noclip
end

--------------------------------------------------
-- SPEED
--------------------------------------------------

local defaultSpeed = 16

local function toggleSpeed(val)
	if hum.WalkSpeed ~= defaultSpeed then
		hum.WalkSpeed = defaultSpeed
	else
		hum.WalkSpeed = tonumber(val) or 50
	end
end

--------------------------------------------------
-- WAYPOINTS
--------------------------------------------------

local function setWaypoint(name)
	waypoints[name] = root.Position
end

local function gotoWaypoint(name)
	if waypoints[name] then
		root.CFrame = CFrame.new(waypoints[name])
	end
end

--------------------------------------------------
-- COMMAND RUNNER
--------------------------------------------------

local function runCommand(text)
	local args = text:split(" ")
	local cmd = args[1]:lower()
	
	if cmd == "fly" then
		toggleFly(args[2])
	end
	
	if cmd == "speed" then
		toggleSpeed(args[2])
	end
	
	if cmd == "goto" then
		local plr = findPlayer(args[2] or "")
		if plr and plr.Character then
			root.CFrame =
				plr.Character.HumanoidRootPart.CFrame
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

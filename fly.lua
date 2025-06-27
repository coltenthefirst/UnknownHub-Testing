local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local gui = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
gui.Name = "fly_ui"
gui.ResetOnSpawn = false

local flying = false
local move = {x=0, y=0, z=0}
local speed = 50
local vel, gyro
local controls = {}

local function btn(id, pos, label, color)
	local b = Instance.new("TextButton", gui)
	b.Name = id
	b.Size = UDim2.new(0, 50, 0, 50)
	b.Position = pos
	b.Text = label
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1,1,1)
	b.TextScaled = true
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	return b
end

controls.W = btn("W", UDim2.new(0, 60, 0.5, -110), "W", Color3.fromRGB(0, 200, 0))
controls.A = btn("A", UDim2.new(0, 10, 0.5, -55),  "A", Color3.fromRGB(0, 200, 0))
controls.S = btn("S", UDim2.new(0, 60, 0.5, -55),  "S", Color3.fromRGB(0, 200, 0))
controls.D = btn("D", UDim2.new(0,110, 0.5, -55),  "D", Color3.fromRGB(0, 200, 0))
controls.E = btn("E", UDim2.new(0,260, 0.5,-110),  "E", Color3.fromRGB(0, 120, 255))
controls.Q = btn("Q", UDim2.new(0,260, 0.5, -55),  "Q", Color3.fromRGB(255, 60, 60))
controls.T = btn("Toggle", UDim2.new(0,60, 0.5, 10), "fucking toggle fly", Color3.fromRGB(130, 0, 200))
controls.T.Size = UDim2.new(0, 150, 0, 40)

local function startFly()
	if flying then return end
	flying = true
	vel = Instance.new("BodyVelocity")
	gyro = Instance.new("BodyGyro")
	vel.MaxForce = Vector3.new(9e9,9e9,9e9)
	gyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
	vel.Velocity = Vector3.zero
	gyro.CFrame = root.CFrame
	vel.Parent = root
	gyro.Parent = root

	game:GetService("RunService").RenderStepped:Connect(function()
		if not flying then return end
		local cam = workspace.CurrentCamera
		local dir = cam.CFrame.LookVector * move.z + cam.CFrame.RightVector * move.x + Vector3.new(0, move.y, 0)
		vel.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
		gyro.CFrame = cam.CFrame
	end)
end

local function stopFly()
	flying = false
	if vel then vel:Destroy() end
	if gyro then gyro:Destroy() end
end

controls.T.MouseButton1Click:Connect(function()
	if flying then stopFly() else startFly() end
end)

local function hold(btn, axis, val)
	btn.MouseButton1Down:Connect(function() move[axis] = val end)
	btn.MouseButton1Up:Connect(function() move[axis] = 0 end)
end

hold(controls.W, "z", 1)
hold(controls.S, "z", -1)
hold(controls.A, "x", -1)
hold(controls.D, "x", 1)
hold(controls.E, "y", 1)
hold(controls.Q, "y", -1)

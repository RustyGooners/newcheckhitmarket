-- FULL WORKING SCRIPT
-- // SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- // SETTINGS
local settings = {
	FOVRadius = 120,
	ShowFOV = true,
	RainbowInner = true,
	SpinHitmarker = true,
	DebugBind = Enum.KeyCode.B
}

-- // HITMARKER DEFAULTS (can be changed in menu)
local hitmarkerID = "966597671"
local hitSoundID = "5043539486"

-- // VARIABLES
local outerCircle, innerFrame, innerGradient, targetLabel, hitmarker, hitSound
local hueOffset = 0
local lastHP = {}
local menuOpen = true
local menu

-- // SCREEN GUI
local screenGui = Instance.new("ScreenGui")
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- // GUI SETUP
local function setupGUI()
	-- destroy previous menu if present
	if menu then menu:Destroy() end

	-- Outer DrawCircle (Drawing)
	if not outerCircle then
		outerCircle = Drawing.new("Circle")
		outerCircle.Radius = settings.FOVRadius
		outerCircle.Thickness = 2
		outerCircle.Filled = false
		outerCircle.Color = Color3.fromRGB(255,255,255)
		outerCircle.Visible = settings.ShowFOV
	end

	-- Inner Frame (centered)
	if not innerFrame then
		innerFrame = Instance.new("Frame")
		innerFrame.AnchorPoint = Vector2.new(0.5,0.5)
		innerFrame.BackgroundColor3 = Color3.fromRGB(255,255,255)
		innerFrame.BackgroundTransparency = 0.5
		innerFrame.Size = UDim2.new(0, settings.FOVRadius*2, 0, settings.FOVRadius*2)
		innerFrame.Parent = screenGui

		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(1,0)
		innerCorner.Parent = innerFrame

		innerGradient = Instance.new("UIGradient")
		innerGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,0.2),
			NumberSequenceKeypoint.new(0.5,0),
			NumberSequenceKeypoint.new(1,0.5)
		})
		innerGradient.Rotation = 0
		innerGradient.Parent = innerFrame
	end

	-- Ensure targetLabel exists (prevents nil indexing)
	if not targetLabel then
		targetLabel = Instance.new("TextLabel")
		targetLabel.Size = UDim2.new(0,200,0,30)
		targetLabel.AnchorPoint = Vector2.new(0.5,0)
		targetLabel.Position = UDim2.new(0.5,0,0.5,settings.FOVRadius + 10)
		targetLabel.BackgroundTransparency = 1
		targetLabel.TextColor3 = Color3.fromRGB(255,255,255)
		targetLabel.TextStrokeTransparency = 0.5
		targetLabel.Font = Enum.Font.GothamBold
		targetLabel.TextSize = 16
		targetLabel.Text = ""
		targetLabel.Parent = screenGui
	end

	-- Hitmarker (ImageLabel + Sound)
	if not hitmarker then
		hitmarker = Instance.new("ImageLabel")
		hitmarker.Size = UDim2.new(0,50,0,50)
		hitmarker.AnchorPoint = Vector2.new(0.5,0.5)
		hitmarker.Position = UDim2.new(0.5,0,0.5,0)
		hitmarker.BackgroundTransparency = 1
		hitmarker.Image = "rbxassetid://"..hitmarkerID
		hitmarker.ImageTransparency = 1
		hitmarker.Visible = false
		hitmarker.Parent = screenGui

		hitSound = Instance.new("Sound")
		hitSound.SoundId = "rbxassetid://"..hitSoundID
		hitSound.Volume = 1
		hitSound.Parent = hitmarker
	end

	-- Build menu
	menu = Instance.new("Frame")
	menu.Size = UDim2.new(0,380,0,320)
	menu.Position = UDim2.new(0.5,-190,0.5,-160)
	menu.BackgroundColor3 = Color3.fromRGB(40,40,40)
	menu.BorderSizePixel = 0
	menu.Visible = menuOpen
	menu.Parent = screenGui

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0,10)
	menuCorner.Parent = menu

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,30)
	title.BackgroundTransparency = 1
	title.Text = "Hitmarker & FOV Menu"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.new(1,1,1)
	title.Parent = menu

	-- Dragging
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = menu.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	title.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- helper to create buttons
	local function createButton(text, posY, parent)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0,160,0,30)
		btn.Position = UDim2.new(0,12,0,posY)
		btn.Text = text
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		btn.TextColor3 = Color3.fromRGB(255,255,255)
		btn.Parent = parent or menu
		local c = Instance.new("UICorner", btn)
		c.CornerRadius = UDim.new(0,6)
		btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(80,80,80) end)
		btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(60,60,60) end)
		return btn
	end

	-- Buttons & inputs
	local btnToggleFOV = createButton("Toggle FOV", 40)
	btnToggleFOV.MouseButton1Click:Connect(function()
		settings.ShowFOV = not settings.ShowFOV
	end)

	local btnToggleRainbow = createButton("Toggle Rainbow Inner", 80)
	btnToggleRainbow.MouseButton1Click:Connect(function()
		settings.RainbowInner = not settings.RainbowInner
	end)

	-- Hitmarker texture input
	local labelImg = Instance.new("TextLabel", menu)
	labelImg.Size = UDim2.new(0,120,0,20)
	labelImg.Position = UDim2.new(0,12,0,130)
	labelImg.BackgroundTransparency = 1
	labelImg.Text = "Hitmarker Image ID"
	labelImg.TextColor3 = Color3.new(1,1,1)
	labelImg.Font = Enum.Font.Gotham
	labelImg.TextSize = 12

	local imageBox = Instance.new("TextBox", menu)
	imageBox.Size = UDim2.new(0,200,0,30)
	imageBox.Position = UDim2.new(0,12,0,150)
	imageBox.ClearTextOnFocus = false
	imageBox.Text = hitmarkerID
	imageBox.PlaceholderText = "Enter image id"
	imageBox.Font = Enum.Font.Gotham
	imageBox.TextSize = 14

	local applyImg = createButton("Apply Image", 150, menu)
	applyImg.Position = UDim2.new(0,220,0,150)
	applyImg.MouseButton1Click:Connect(function()
		if imageBox.Text ~= "" then
			hitmarkerID = imageBox.Text
			if hitmarker then hitmarker.Image = "rbxassetid://"..hitmarkerID end
		end
	end)

	-- Hitmarker sound input
	local labelSnd = Instance.new("TextLabel", menu)
	labelSnd.Size = UDim2.new(0,120,0,20)
	labelSnd.Position = UDim2.new(0,12,0,195)
	labelSnd.BackgroundTransparency = 1
	labelSnd.Text = "Hitmarker Sound ID"
	labelSnd.TextColor3 = Color3.new(1,1,1)
	labelSnd.Font = Enum.Font.Gotham
	labelSnd.TextSize = 12

	local soundBox = Instance.new("TextBox", menu)
	soundBox.Size = UDim2.new(0,200,0,30)
	soundBox.Position = UDim2.new(0,12,0,215)
	soundBox.ClearTextOnFocus = false
	soundBox.Text = hitSoundID
	soundBox.PlaceholderText = "Enter sound id"
	soundBox.Font = Enum.Font.Gotham
	soundBox.TextSize = 14

	local applySnd = createButton("Apply Sound", 215, menu)
	applySnd.Position = UDim2.new(0,220,0,215)
	applySnd.MouseButton1Click:Connect(function()
		if soundBox.Text ~= "" then
			hitSoundID = soundBox.Text
			if hitSound then hitSound.SoundId = "rbxassetid://"..hitSoundID end
		end
	end)

	-- Debug bind setter
	local btnBind = createButton("Set Debug Bind (B)", 260, menu)
	btnBind.MouseButton1Click:Connect(function()
		btnBind.Text = "Press a key..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				settings.DebugBind = input.KeyCode
				btnBind.Text = "Debug Bind: "..tostring(input.KeyCode):gsub("Enum.KeyCode.","")
				conn:Disconnect()
			end
		end)
	end)
end

-- initial GUI
setupGUI()
player.CharacterAdded:Connect(function()
	task.wait(0.35)
	setupGUI()
end)

-- // GRADIENT ANIMATION
local function updateInnerGradient(dt)
	hueOffset = (hueOffset + dt*0.18) % 1
	local positions = {0, 0.17, 0.33, 0.5, 0.67, 0.83, 1}
	local keypoints = {}
	for i, pos in ipairs(positions) do
		local h = (pos + hueOffset) % 1
		-- low saturation for a shiny near-white look
		keypoints[i] = ColorSequenceKeypoint.new((i-1)/(#positions-1), Color3.fromHSV(h, 0.28, 1))
	end
	if innerGradient then
		innerGradient.Color = ColorSequence.new(keypoints)
		innerGradient.Rotation = (innerGradient.Rotation + 40*dt) % 360
	end
end

-- // HELPER: closest player inside FOV (CENTRED using mouse.X/Y)
local function getClosestPlayerToCursor()
	local closestPlayer = nil
	local shortestDist = math.huge
	local mousePos = Vector2.new(mouse.X, mouse.Y)
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
			local root = plr.Character.HumanoidRootPart
			local distance3D = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - root.Position).Magnitude) or 0
			if distance3D > 750 then continue end
			local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
			if not onScreen then continue end
			local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
			if dist <= settings.FOVRadius and dist < shortestDist then
				closestPlayer = plr
				shortestDist = dist
			end
		end
	end
	return closestPlayer
end

-- // HITMARKER TRIGGER (used by debug, click-check and automatic immediate detection)
local function spawnHitmarkerVisual()
	if not hitmarker then return end
	hitmarker.Visible = true
	hitmarker.ImageTransparency = 0
	-- play sound
	if hitSound and hitSound.SoundId ~= "" then
		pcall(function() hitSound:Play() end)
	end
	-- spin + fade
	local tw = TweenService:Create(hitmarker, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Rotation = 360, ImageTransparency = 1})
	tw:Play()
	tw.Completed:Connect(function()
		if hitmarker then
			hitmarker.Visible = false
			hitmarker.ImageTransparency = 0
			hitmarker.Rotation = 0
		end
	end)
end

-- Called when we want to watch a humanoid for 2 seconds (click or bind)
local function watchHumanoidForHit(humanoid)
	coroutine.wrap(function()
		if not humanoid then return end
		local initialHP = humanoid.Health
		local start = tick()
		while tick() - start <= 2 do
			if humanoid.Health < initialHP then
				spawnHitmarkerVisual()
				return
			end
			task.wait(0.05)
		end
		print("HP didn't change")
	end)()
end

-- // INPUT: Debug bind (key) & classic click
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- Debug bind (key)
	if input.KeyCode == settings.DebugBind then
		local target = getClosestPlayerToCursor()
		if target and target.Character and target.Character:FindFirstChild("Humanoid") then
			watchHumanoidForHit(target.Character.Humanoid)
		end
	end

	-- Left click (classic): same behaviour
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local target = getClosestPlayerToCursor()
		if target and target.Character and target.Character:FindFirstChild("Humanoid") then
			watchHumanoidForHit(target.Character.Humanoid)
		end
	end
end)

-- // AUTOMATIC immediate hit detection (HP drop)
RunService.RenderStepped:Connect(function(dt)
	-- update outer circle position and visibility
	local mousePos = Vector2.new(mouse.X, mouse.Y)
	if outerCircle then
		outerCircle.Position = mousePos
		outerCircle.Visible = settings.ShowFOV
		outerCircle.Radius = settings.FOVRadius
	end

	-- update inner frame center
	if innerFrame then
		innerFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
		innerFrame.Visible = settings.ShowFOV
	end

	-- animate gradient
	if settings.RainbowInner and innerGradient then
		updateInnerGradient(dt)
	end

	-- update target label under the circle
	local closest = getClosestPlayerToCursor()
	if targetLabel then
		if closest then
			targetLabel.Text = closest.Name
			targetLabel.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y + settings.FOVRadius + 10)
		else
			targetLabel.Text = ""
		end
	end

	-- automatic HP drop detection: instant hitmarker
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") then
			local humanoid = plr.Character.Humanoid
			if not lastHP[plr] then lastHP[plr] = humanoid.Health end
			if humanoid.Health < lastHP[plr] then
				-- check distance & on-screen & inside FOV
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
					if onScreen then
						local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
						local distance3D = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - root.Position).Magnitude) or 0
						if dist2D <= settings.FOVRadius and distance3D <= 750 then
							spawnHitmarkerVisual()
						end
					end
				end
			end
			lastHP[plr] = humanoid.Health
		end
	end
end)

-- // MENU TOGGLE
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		menuOpen = not menuOpen
		if menu then menu.Visible = menuOpen end
	end
end)

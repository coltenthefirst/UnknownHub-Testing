local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local defaultShadows = Lighting.GlobalShadows
local defaultBrightness = Lighting.Brightness
local defaultClockTime = Lighting.ClockTime

local plr = Players.LocalPlayer
local guiRoot = plr:WaitForChild("PlayerGui")
local char = plr.Character or plr.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local rootPart
local cam = Workspace.CurrentCamera

local settings = {
    espEnabled = false,
    showSelfESP = true,
    showFriendsESP = true,
    showInfo = true,
    forceSpeed = false,
    desiredSpeed = math.ceil(humanoid.WalkSpeed),
    forceJump = false,
    desiredJump = math.ceil(humanoid.UseJumpPower and humanoid.JumpPower or humanoid.JumpHeight),
    noclip = false,
    fullBright = false,
    fly = false,
}

local trackers = {}

local theme = {
    mode = "dark",
    dark = { bg = Color3.fromRGB(20,20,20), sec = Color3.fromRGB(15,15,15), btn = Color3.fromRGB(35,35,35) },
    purple = { bg = Color3.fromRGB(25,0,50), sec = Color3.fromRGB(40,0,60), btn = Color3.fromRGB(60,0,90) },
}

local function tweenColor(obj, prop, to)
    TweenService:Create(obj, TweenInfo.new(0.2), {[prop] = to}):Play()
end

local function getColor(key)
    return theme[theme.mode][key or "bg"]
end

local function styleGui(obj, key)
    tweenColor(obj, "BackgroundColor3", getColor(key))
    obj.BorderSizePixel = 0
    local u = obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", obj)
    u.CornerRadius = UDim.new(0,6)
    local s = obj:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", obj)
    s.Color = Color3.fromRGB(70,70,70)
end

local function findRootPart(c)
    return c.PrimaryPart
        or c:FindFirstChild("HumanoidRootPart")
        or c:FindFirstChild("Head")
        or c:FindFirstChild("UpperTorso")
        or c:FindFirstChild("Torso")
end

local function setupLocal(c)
    char = c
    humanoid = char:WaitForChild("Humanoid")
    rootPart = findRootPart(char)
    settings.desiredSpeed = math.ceil(humanoid.WalkSpeed)
    settings.desiredJump = math.ceil(humanoid.UseJumpPower and humanoid.JumpPower or humanoid.JumpHeight)
    print("ready, speed "..settings.desiredSpeed)
    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if settings.forceSpeed and humanoid.WalkSpeed ~= settings.desiredSpeed then
            humanoid.WalkSpeed = settings.desiredSpeed
            print("speed "..settings.desiredSpeed)
        end
    end)
    humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if settings.forceJump and humanoid.JumpPower ~= settings.desiredJump then
            humanoid.JumpPower = settings.desiredJump
            print("jump "..settings.desiredJump)
        end
    end)
    humanoid:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if settings.forceJump and humanoid.JumpHeight ~= settings.desiredJump then
            humanoid.JumpHeight = settings.desiredJump
            print("jump "..settings.desiredJump)
        end
    end)
end

setupLocal(char)
plr.CharacterAdded:Connect(setupLocal)

local function cleanupESP(player)
    local t = trackers[player]
    if t then
        t.Highlight:Destroy()
        t.Billboard:Destroy()
        trackers[player] = nil
        print("removed esp "..player.Name)
    end
end

local function refreshOne(player)
    local t = trackers[player]
    if not t then return end
    local isSelf = player == plr
    local isFriend = player:IsFriendsWith(plr.UserId)
    local keep = settings.espEnabled and ((isSelf and settings.showSelfESP) or (isFriend and settings.showFriendsESP) or (not isSelf and not isFriend))
    t.Highlight.Enabled = keep
    t.Billboard.Enabled = keep and settings.showInfo
    print(player.Name.." esp "..(keep and "on" or "off"))
end

local function refreshAll()
    for p in pairs(trackers) do
        refreshOne(p)
    end
    print("esp updated")
end

local function onCharAdded(player, c)
    cleanupESP(player)
    local hl = Instance.new("Highlight", Workspace)
    hl.Adornee = c
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = Color3.new(1,0,1)
    hl.OutlineColor = Color3.new(1,1,1)

    local root = findRootPart(c) or c
    local bb = Instance.new("BillboardGui", guiRoot)
    bb.Adornee = root
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,120,0,80)
    bb.StudsOffset = Vector3.new(0,2.5,0)

    local thumb = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    local img = Instance.new("ImageLabel", bb)
    img.Size = UDim2.new(0,48,0,48)
    img.Position = UDim2.new(0.5,-24,0,0)
    img.BackgroundTransparency = 1
    img.Image = thumb

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(0,120,0,20)
    lbl.Position = UDim2.new(0.5,-60,0,52)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.Text = player.Name.." ("..player.DisplayName..")"

    trackers[player] = { Highlight = hl, Billboard = bb }
    refreshOne(player)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c) onCharAdded(p, c) end)
end)
Players.PlayerRemoving:Connect(cleanupESP)
for _,p in ipairs(Players:GetPlayers()) do
    if p.Character then onCharAdded(p, p.Character) end
    p.CharacterAdded:Connect(function(c) onCharAdded(p, c) end)
end

local screen = Instance.new("ScreenGui", guiRoot)
screen.Name = "UnknownHub"
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.ResetOnSpawn = false

local main = Instance.new("Frame", screen)
main.Size = UDim2.new(0,600,0,400)
main.Position = UDim2.new(0.5,-300,0.5,-200)
main.AnchorPoint = Vector2.new(0.5,0.5)
main.Active = true
main.Draggable = true
styleGui(main)

local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0,140,1,-10)
sidebar.Position = UDim2.new(0,5,0,5)
styleGui(sidebar, "sec")

local layout = Instance.new("UIListLayout", sidebar)
layout.Padding = UDim.new(0,8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top

local header = Instance.new("TextLabel", sidebar)
header.Size = UDim2.new(1,-20,0,40)
header.Text = "Unknown Hub"
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.TextColor3 = Color3.new(1,1,1)
header.BackgroundTransparency = 1

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,-160,1,-20)
content.Position = UDim2.new(0,150,0,10)
styleGui(content, "sec")

local contentLayout = Instance.new("UIListLayout", content)
contentLayout.Padding = UDim.new(0,8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

local desc = Instance.new("TextLabel", content)
desc.Name = "Description"
desc.Size = UDim2.new(1,-20,0,40)
desc.Position = UDim2.new(0,10,1,-50)
desc.BackgroundTransparency = 1
desc.Font = Enum.Font.Gotham
desc.TextSize = 12
desc.TextColor3 = Color3.new(1,1,1)
desc.TextWrapped = true

local function clear()
    for _,v in pairs(content:GetChildren()) do
        if not v:IsA("UIListLayout") and v ~= desc then
            v:Destroy()
        end
    end
end

local function makeButton(text, fn, tip)
    local b = Instance.new("TextButton", content)
    b.Size = UDim2.new(1,-20,0,34)
    b.Text = text
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.TextColor3 = Color3.new(1,1,1)
    styleGui(b, "btn")
    b.MouseEnter:Connect(function() desc.Text = tip or "" end)
    b.MouseLeave:Connect(function() desc.Text = "" end)
    b.MouseButton1Click:Connect(function() fn(b) end)
    return b
end

local function makeSlider(label, min, max, def, cb)
    local f = Instance.new("Frame", content)
    f.Size = UDim2.new(1,-20,0,40)
    styleGui(f, "btn")
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(0,100,1,0)
    l.Text = label
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextColor3 = Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0,10,0,0)
    local box = Instance.new("TextBox", f)
    box.Size = UDim2.new(0,50,0,24)
    box.Position = UDim2.new(1,-60,0.5,-12)
    styleGui(box, "btn")
    box.Text = tostring(def)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextColor3 = Color3.new(1,1,1)
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(1,-180,0,6)
    bar.Position = UDim2.new(0,110,0.5,-3)
    bar.BackgroundColor3 = Color3.fromRGB(60,60,60)
    bar.BorderSizePixel = 0
    local bc = Instance.new("UICorner", bar)
    bc.CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.new(0,10,1.5,0)
    knob.Position = UDim2.new((def-min)/(max-min),0,-0.25,0)
    knob.BackgroundColor3 = Color3.fromRGB(150,150,150)
    local kc = Instance.new("UICorner", knob)
    kc.CornerRadius = UDim.new(1,0)
    local dragging = false
    local function update(v)
        v = math.clamp(math.ceil(v), min, max)
        knob.Position = UDim2.new((v-min)/(max-min),0,-0.25,0)
        box.Text = tostring(v)
        cb(v)
        print(label.." now "..v)
    end
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local rel = UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X
            local pct = math.clamp(rel / bar.AbsoluteSize.X, 0, 1)
            update(min + (max-min)*pct)
        end
    end)
    box.FocusLost:Connect(function()
        local v2 = tonumber(box.Text)
        if v2 then update(v2) end
    end)
    return { set = update }
end

local tabs = {}
local function makeTab(name, fn)
    tabs[name] = fn
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,-20,0,34)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1,1,1)
    styleGui(btn, "btn")
    btn.MouseButton1Click:Connect(function() clear() fn() end)
end

makeTab("Player", function()
    local speedSlider = makeSlider("Speed", 0, 200, settings.desiredSpeed, function(v)
        humanoid.WalkSpeed = v
        settings.desiredSpeed = v
    end)
    local jumpSlider = makeSlider("Jump", 0, 200, settings.desiredJump, function(v)
        if humanoid.UseJumpPower then
            humanoid.JumpPower = v
        else
            humanoid.JumpHeight = v
        end
        settings.desiredJump = v
    end)
    makeButton("Reset Stats", function()
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        humanoid.JumpHeight = 7.2
        speedSlider.set(16)
        jumpSlider.set(settings.desiredJump)
    end, "reset defaults")
    makeButton("Force Speed: Off (client)", function(b)
        settings.forceSpeed = not settings.forceSpeed
        b.Text = "Force Speed: "..(settings.forceSpeed and "On" or "Off").." (client)"
    end, "lock speed")
    makeButton("Force Jump: Off (client)", function(b)
        settings.forceJump = not settings.forceJump
        b.Text = "Force Jump: "..(settings.forceJump and "On" or "Off").." (client)"
    end, "lock jump")
    makeButton("Noclip: Off (client)", function(b)
        settings.noclip = not settings.noclip
        b.Text = "Noclip: "..(settings.noclip and "On" or "Off").." (client)"
    end, "noclip")
    makeButton("Fly: Off (client)", function(b)
        settings.fly = not settings.fly
        b.Text = "Fly: "..(settings.fly and "On" or "Off").." (client)"
        if settings.fly then
            local bv = Instance.new("BodyVelocity", rootPart)
            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
            settings._flyBV = bv
        else
            if settings._flyBV then
                settings._flyBV:Destroy()
                settings._flyBV = nil
            end
        end
    end, "fly client")
end)

makeTab("Visuals", function()
    local fovSlider = makeSlider("FOV", 30, 120, cam.FieldOfView, function(v)
        cam.FieldOfView = v
    end)
    makeButton("Reset FOV", function()
        cam.FieldOfView = 70
        fovSlider.set(70)
    end, "default fov")
end)

makeTab("World", function()
    makeButton("Full Bright: Off (client)", function(b)
        settings.fullBright = not settings.fullBright
        b.Text = "Full Bright: "..(settings.fullBright and "On" or "Off").." (client)"
        if settings.fullBright then
            Lighting.GlobalShadows = false
            Lighting.Brightness = 5
            Lighting.ClockTime = 12
        else
            Lighting.GlobalShadows = defaultShadows
            Lighting.Brightness = defaultBrightness
            Lighting.ClockTime = defaultClockTime
        end
    end, "bright client")
    makeSlider("Brightness", 0, 10, Lighting.Brightness, function(v)
        Lighting.Brightness = v
    end)
    makeButton("Toggle Shadows", function()
        Lighting.GlobalShadows = not Lighting.GlobalShadows
    end, "shadows")
    makeButton("Toggle Textures", function()
        for _,d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = (d.Transparency == 1) and 0 or 1
            end
        end
    end, "textures")
end)

makeTab("ESP", function()
    makeButton("ESP: Off (client)", function(b)
        settings.espEnabled = not settings.espEnabled
        b.Text = "ESP: "..(settings.espEnabled and "On" or "Off").." (client)"
        refreshAll()
    end, "toggle esp")
    makeButton("Self ESP: On (client)", function(b)
        settings.showSelfESP = not settings.showSelfESP
        b.Text = "Self ESP: "..(settings.showSelfESP and "On" or "Off").." (client)"
        refreshAll()
    end, "include you")
    makeButton("Friends ESP: On (client)", function(b)
        settings.showFriendsESP = not settings.showFriendsESP
        b.Text = "Friends ESP: "..(settings.showFriendsESP and "On" or "Off").." (client)"
        refreshAll()
    end, "friends")
    makeButton("Info: On (client)", function(b)
        settings.showInfo = not settings.showInfo
        b.Text = "Info: "..(settings.showInfo and "On" or "Off").." (client)"
        refreshAll()
    end, "info")
    makeButton("Clear ESP", function()
        for _,t in pairs(trackers) do
            t.Highlight.Enabled = false
            t.Billboard.Enabled = false
        end
    end, "clear all")
end)

makeTab("Other", function()
    makeButton("Rejoin", function()
        TeleportService:Teleport(game.PlaceId, plr)
    end, "back in")
end)

local closeBtn = Instance.new("TextButton", main)
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.new(1,1,1)
styleGui(closeBtn, "btn")
closeBtn.ZIndex = 50
closeBtn.MouseButton1Click:Connect(function()
    screen:Destroy()
end)

local miniBtn = Instance.new("TextButton", main)
miniBtn.Size = UDim2.new(0,30,0,30)
miniBtn.Position = UDim2.new(1,-70,0,5)
miniBtn.Text = "-"
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 18
miniBtn.TextColor3 = Color3.new(1,1,1)
styleGui(miniBtn, "btn")
miniBtn.ZIndex = 50
miniBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    local icon = Instance.new("TextButton", screen)
    icon.Size = UDim2.new(0,40,0,40)
    icon.Position = UDim2.new(0,20,0,20)
    icon.Text = "🌀"
    icon.Font = Enum.Font.Gotham
    icon.TextSize = 24
    icon.TextColor3 = Color3.new(1,1,1)
    styleGui(icon, "btn")
    icon.MouseButton1Click:Connect(function()
        main.Visible = true
        icon:Destroy()
    end)
end)

RunService.RenderStepped:Connect(function()
    if settings.noclip and char then
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
    if settings.fly and rootPart and settings._flyBV then
        local x = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 50) or (UserInputService:IsKeyDown(Enum.KeyCode.A) and -50) or 0
        local y = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 50) or (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and -50) or 0
        local z = (UserInputService:IsKeyDown(Enum.KeyCode.S) and 50) or (UserInputService:IsKeyDown(Enum.KeyCode.W) and -50) or 0
        settings._flyBV.Velocity = Vector3.new(x, y, z)
    end
end)

print("hub loaded")

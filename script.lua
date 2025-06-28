local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local FLY_URL = "https://raw.githubusercontent.com/coltenthefirst/UnknownHub-Testing/refs/heads/main/fly.lua"

local plr = Players.LocalPlayer
local guiRoot = plr:WaitForChild("PlayerGui")
local char = plr.Character or plr.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local rootPart
local cam = Workspace.CurrentCamera

local defShadows, defBright, defTime =
  Lighting.GlobalShadows, Lighting.Brightness, Lighting.ClockTime

local settings = {
  esp = false, selfESP = true, friendESP = true, info = true,
  forceSpeed = false, desiredSpeed = humanoid.WalkSpeed,
  forceJump = false, desiredJump = humanoid.UseJumpPower and humanoid.JumpPower or humanoid.JumpHeight,
  noclip = false, fullBright = false,
  flyEnabled = false, flyUIEnabled = true,
}

local trackers = {}

-- theme / util
local theme = { mode = "dark",
  dark = { bg = Color3.fromRGB(20,20,20), sec = Color3.fromRGB(15,15,15), btn = Color3.fromRGB(35,35,35) }
}

local function tween(o,p,v)
  TweenService:Create(o, TweenInfo.new(0.2), {[p]=v}):Play()
end

local function col(k)
  return theme[theme.mode][k or "bg"]
end

local function style(o,k)
  tween(o,"BackgroundColor3",col(k))
  o.BorderSizePixel = 0
  local u = o:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", o)
  u.CornerRadius = UDim.new(0,6)
  local s = o:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", o)
  s.Color = Color3.fromRGB(70,70,70)
end

local function findRoot(c)
  return c.PrimaryPart
    or c:FindFirstChild("HumanoidRootPart")
    or c:FindFirstChild("Head")
    or c:FindFirstChild("UpperTorso")
    or c:FindFirstChild("Torso")
end

-- character setup
local function setupChar(c)
  char = c
  humanoid = char:WaitForChild("Humanoid")
  rootPart = findRoot(char)
  settings.desiredSpeed = humanoid.WalkSpeed
  settings.desiredJump = humanoid.UseJumpPower and humanoid.JumpPower or humanoid.JumpHeight
  print("ready, speed set to", settings.desiredSpeed)
  humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
    if settings.forceSpeed and humanoid.WalkSpeed ~= settings.desiredSpeed then
      humanoid.WalkSpeed = settings.desiredSpeed
      print("forced speed to", settings.desiredSpeed)
    end
  end)
  humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
    if settings.forceJump and humanoid.JumpPower ~= settings.desiredJump then
      humanoid.JumpPower = settings.desiredJump
      print("forced jump to", settings.desiredJump)
    end
  end)
  humanoid:GetPropertyChangedSignal("JumpHeight"):Connect(function()
    if settings.forceJump and humanoid.JumpHeight ~= settings.desiredJump then
      humanoid.JumpHeight = settings.desiredJump
      print("forced jump to", settings.desiredJump)
    end
  end)
end

setupChar(char)
plr.CharacterAdded:Connect(setupChar)

-- ESP
local function cleanupESP(p)
  local t = trackers[p]
  if t then
    t.hl:Destroy()
    t.bb:Destroy()
    trackers[p] = nil
    print("cleaned up ESP for", p.Name)
  end
end

local function refreshOne(p)
  local t = trackers[p]
  if not t then return end
  local isSelf = p == plr
  local isFriend = p:IsFriendsWith(plr.UserId)
  local keep = settings.esp
    and ((isSelf and settings.selfESP)
      or (isFriend and settings.friendESP)
      or (not isSelf and not isFriend))
  t.hl.Enabled = keep
  t.bb.Enabled = keep and settings.info
end

local function refreshAll()
  for p in pairs(trackers) do
    refreshOne(p)
  end
  print("ESP refreshed")
end

local function onCharAdded(p, c)
  cleanupESP(p)
  local hl = Instance.new("Highlight", Workspace)
  hl.Adornee = c
  hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
  hl.FillColor = Color3.new(1,0,1)
  hl.OutlineColor = Color3.new(1,1,1)

  local root = findRoot(c) or c
  local bb = Instance.new("BillboardGui", guiRoot)
  bb.Adornee = root
  bb.AlwaysOnTop = true
  bb.Size = UDim2.new(0,120,0,80)
  bb.StudsOffset = Vector3.new(0,2.5,0)

  local thumb = Players:GetUserThumbnailAsync(
    p.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size48x48
  )
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
  lbl.Text = p.Name.." ("..p.DisplayName..")"

  trackers[p] = { hl = hl, bb = bb }
  refreshOne(p)
  print("ESP set up for", p.Name)
end

Players.PlayerAdded:Connect(function(p)
  p.CharacterAdded:Connect(function(c) onCharAdded(p, c) end)
end)
Players.PlayerRemoving:Connect(cleanupESP)
for _,p in ipairs(Players:GetPlayers()) do
  if p.Character then onCharAdded(p, p.Character) end
  p.CharacterAdded:Connect(function(c) onCharAdded(p, c) end)
end

-- UI hub
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
style(main)

local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0,140,1,-10)
sidebar.Position = UDim2.new(0,5,0,5)
style(sidebar, "sec")

local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0,8)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.VerticalAlignment = Enum.VerticalAlignment.Top

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
style(content, "sec")

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

local function clearContent()
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
  style(b, "btn")
  b.MouseEnter:Connect(function() desc.Text = tip or "" end)
  b.MouseLeave:Connect(function() desc.Text = "" end)
  b.MouseButton1Click:Connect(function() fn(b) end)
  return b
end

local function makeSlider(label, min, max, default, cb)
  local f = Instance.new("Frame", content)
  f.Size = UDim2.new(1,-20,0,40)
  style(f, "btn")
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
  style(box, "btn")
  box.Text = tostring(default)
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
  knob.Position = UDim2.new((default-min)/(max-min),0,-0.25,0)
  knob.BackgroundColor3 = Color3.fromRGB(150,150,150)
  local kc = Instance.new("UICorner", knob)
  kc.CornerRadius = UDim.new(1,0)
  local dragging = false
  local function update(v)
    v = math.clamp(math.ceil(v), min, max)
    knob.Position = UDim2.new((v-min)/(max-min),0,-0.25,0)
    box.Text = tostring(v)
    cb(v)
  end
  knob.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
      dragging = true
    end
  end)
  UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
      dragging = false
    end
  end)
  RunService.RenderStepped:Connect(function()
    if dragging then
      local rel = UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X
      local pct = math.clamp(rel/bar.AbsoluteSize.X, 0, 1)
      update(min + (max-min)*pct)
    end
  end)
  box.FocusLost:Connect(function()
    local v2 = tonumber(box.Text)
    if v2 then update(v2) end
  end)
  return { set = update }
end

local function makeTab(name, fn)
  local btn = Instance.new("TextButton", sidebar)
  btn.Size = UDim2.new(1,-20,0,34)
  btn.Text = name
  btn.Font = Enum.Font.Gotham
  btn.TextSize = 13
  btn.TextColor3 = Color3.new(1,1,1)
  style(btn, "btn")
  btn.MouseButton1Click:Connect(function()
    clearContent()
    fn()
  end)
end

-- Player tab
makeTab("Player", function()
  local speedSlider = makeSlider("Speed", 0, 200,
    settings.desiredSpeed,
    function(v)
      humanoid.WalkSpeed = v
      settings.desiredSpeed = v
    end
  )
  local jumpSlider = makeSlider("Jump", 0, 200,
    settings.desiredJump,
    function(v)
      if humanoid.UseJumpPower then
        humanoid.JumpPower = v
      else
        humanoid.JumpHeight = v
      end
      settings.desiredJump = v
    end
  )
  makeButton("Reset Stats", function()
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    humanoid.JumpHeight = 7.2
    speedSlider.set(16)
    jumpSlider.set(settings.desiredJump)
    print("stats reset")
  end, "reset defaults")

  makeButton("Force Speed: Off", function(b)
    settings.forceSpeed = not settings.forceSpeed
    b.Text = "Force Speed: " .. (settings.forceSpeed and "On" or "Off")
    print("forceSpeed", settings.forceSpeed)
  end, "lock speed")

  makeButton("Force Jump: Off", function(b)
    settings.forceJump = not settings.forceJump
    b.Text = "Force Jump: " .. (settings.forceJump and "On" or "Off")
    print("forceJump", settings.forceJump)
  end, "lock jump")

  makeButton("Noclip: Off", function(b)
    settings.noclip = not settings.noclip
    b.Text = "Noclip: " .. (settings.noclip and "On" or "Off")
    print("noclip", settings.noclip)
  end, "noclip")

  makeButton("Toggle Fly: Off", function(b)
    settings.flyEnabled = not settings.flyEnabled
    b.Text = "Toggle Fly: " .. (settings.flyEnabled and "On" or "Off")
    if settings.flyEnabled then
      loadstring(game:HttpGet(FLY_URL))()
      wait(0.1)
      local gui = guiRoot:FindFirstChild("fly_ui")
      if gui then
        local tb = gui:FindFirstChild("Toggle")
        if tb then tb:Activate() end
        gui.Enabled = settings.flyUIEnabled
      end
    else
      local gui = guiRoot:FindFirstChild("fly_ui")
      if gui then
        local tb = gui:FindFirstChild("Toggle")
        if tb then tb:Activate() end
        gui.Enabled = settings.flyUIEnabled
      end
    end
    print("flyEnabled", settings.flyEnabled)
  end, "fly")

  makeButton("Toggle Fly UI: On", function(b)
    settings.flyUIEnabled = not settings.flyUIEnabled
    b.Text = "Toggle Fly UI: " .. (settings.flyUIEnabled and "On" or "Off")
    local gui = guiRoot:FindFirstChild("fly_ui")
    if gui then gui.Enabled = settings.flyUIEnabled end
    print("flyUIEnabled", settings.flyUIEnabled)
  end, "fly ui")
end)

-- Visuals tab
makeTab("Visuals", function()
  local fovSlider = makeSlider("FOV", 30, 120, cam.FieldOfView,
    function(v) cam.FieldOfView = v end
  )
  makeButton("Reset FOV", function()
    cam.FieldOfView = 70
    fovSlider.set(70)
    print("fov reset")
  end, "default fov")
end)

-- World tab
makeTab("World", function()
  makeButton("Full Bright: Off", function(b)
    settings.fullBright = not settings.fullBright
    b.Text = "Full Bright: " .. (settings.fullBright and "On" or "Off")
    if settings.fullBright then
      Lighting.GlobalShadows = false
      Lighting.Brightness = 5
      Lighting.ClockTime = 12
    else
      Lighting.GlobalShadows = defShadows
      Lighting.Brightness = defBright
      Lighting.ClockTime = defTime
    end
    print("fullBright", settings.fullBright)
  end, "bright")

  makeSlider("Brightness", 0, 10, Lighting.Brightness,
    function(v) Lighting.Brightness = v end
  )

  makeButton("Toggle Shadows", function()
    Lighting.GlobalShadows = not Lighting.GlobalShadows
    print("shadows", Lighting.GlobalShadows)
  end, "shadows")

  makeButton("Toggle Textures", function()
    for _,d in ipairs(Workspace:GetDescendants()) do
      if d:IsA("Decal") or d:IsA("Texture") then
        d.Transparency = (d.Transparency == 1) and 0 or 1
      end
    end
    print("textures toggled")
  end, "textures")

  makeButton("Reset Textures", function()
    for _,d in ipairs(Workspace:GetDescendants()) do
      if d:IsA("Decal") or d:IsA("Texture") then
        d.Transparency = 0
      end
    end
    print("textures reset")
  end, "reset textures")
end)

-- ESP tab
makeTab("ESP", function()
  makeButton("ESP: Off", function(b)
    settings.esp = not settings.esp
    b.Text = "ESP: " .. (settings.esp and "On" or "Off")
    refreshAll()
    print("esp", settings.esp)
  end, "toggle esp")

  makeButton("Self ESP: On", function(b)
    settings.selfESP = not settings.selfESP
    b.Text = "Self ESP: " .. (settings.selfESP and "On" or "Off")
    refreshAll()
    print("selfESP", settings.selfESP)
  end, "self")

  makeButton("Friend ESP: On", function(b)
    settings.friendESP = not settings.friendESP
    b.Text = "Friend ESP: " .. (settings.friendESP and "On" or "Off")
    refreshAll()
    print("friendESP", settings.friendESP)
  end, "friend")

  makeButton("Info: On", function(b)
    settings.info = not settings.info
    b.Text = "Info: " .. (settings.info and "On" or "Off")
    refreshAll()
    print("info", settings.info)
  end, "info")

  makeButton("Clear ESP", function()
    for _,t in pairs(trackers) do
      t.hl.Enabled = false
      t.bb.Enabled = false
    end
    print("ESP cleared")
  end, "clear")
end)

-- Other tab
makeTab("Other", function()
  makeButton("Rejoin", function()
    TeleportService:Teleport(game.PlaceId, plr)
  end, "rejoin")
end)

-- close/minimize
local closeBtn = Instance.new("TextButton", main)
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
style(closeBtn, "btn")
closeBtn.MouseButton1Click:Connect(function()
  screen:Destroy()
end)

local miniBtn = Instance.new("TextButton", main)
miniBtn.Size = UDim2.new(0,30,0,30)
miniBtn.Position = UDim2.new(1,-70,0,5)
miniBtn.Text = "-"
style(miniBtn, "btn")
miniBtn.MouseButton1Click:Connect(function()
  main.Visible = false
  local icon = Instance.new("TextButton", screen)
  icon.Size = UDim2.new(0,40,0,40)
  icon.Position = UDim2.new(0,20,0,20)
  icon.Text = "🌀"
  style(icon, "btn")
  icon.MouseButton1Click:Connect(function()
    main.Visible = true
    icon:Destroy()
  end)
end)

-- noclip
RunService.RenderStepped:Connect(function()
  if settings.noclip and char then
    for _,p in ipairs(char:GetDescendants()) do
      if p:IsA("BasePart") then
        p.CanCollide = false
      end
    end
  end
end)

print("UnknownHub loaded")

--// Kosx Hub - Session Time Edition
--// Features: ESP, Camera Fly, Cframe Speed, Noclip + Binds, Touch Fling
--// Keybind: J

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Cleanup
if pg:FindFirstChild("KosxHubV2") then pg.KosxHubV2:Destroy() end
if Lighting:FindFirstChild("KosxHubBlur") then Lighting.KosxHubBlur:Destroy() end

-- Unbind previous
ContextActionService:UnbindAction("KosxHubFlyScroll")

--========================
-- CONFIG SYSTEM
--========================
local FileName = "KosxHub_Config.json"
local Config = { Theme = 1, Binds = {} }

local function SaveConfig()
    if writefile then
        pcall(function() writefile(FileName, HttpService:JSONEncode(Config)) end)
    end
end

local function LoadConfig()
    if isfile and isfile(FileName) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if success and result then
            if result.Theme then Config.Theme = result.Theme end
            if result.Binds then for k,v in pairs(result.Binds) do Config.Binds[k] = v end end
        end
    end
end
LoadConfig()

--========================
-- SOUND SYSTEM
--========================
local function playClick(pitch)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://6351629524"
    s.Volume = 0.5
    s.Pitch = pitch or 1
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local function playToggleSound()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://87437544236708"
    s.Volume = 1
    s.Pitch = 1
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

--========================
-- THEME SYSTEM
--========================
local PRESETS = {
    {Name = "Orange", Accent = Color3.fromRGB(255, 140, 40), Bg = Color3.fromRGB(25, 25, 28)},
    {Name = "Purple", Accent = Color3.fromRGB(160, 100, 255), Bg = Color3.fromRGB(25, 20, 35)},
    {Name = "Red",    Accent = Color3.fromRGB(255, 60, 60),   Bg = Color3.fromRGB(30, 20, 20)},
    {Name = "Green",  Accent = Color3.fromRGB(60, 255, 120),  Bg = Color3.fromRGB(20, 30, 25)},
    {Name = "Blue",   Accent = Color3.fromRGB(60, 150, 255),  Bg = Color3.fromRGB(20, 25, 35)},
    {Name = "White",  Accent = Color3.fromRGB(220, 220, 220), Bg = Color3.fromRGB(35, 35, 35)},
}

local CURRENT = {Accent = PRESETS[Config.Theme].Accent, Bg = PRESETS[Config.Theme].Bg}
local ThemeObjects = {Accents = {}, Backgrounds = {}, Texts = {}}

local function tween(obj, props, time)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play() return t
end

local function mk(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function SetTheme(themeIndex)
    local theme = PRESETS[themeIndex]
    CURRENT.Accent = theme.Accent
    CURRENT.Bg = theme.Bg
    Config.Theme = themeIndex
    SaveConfig()
    
    for _, obj in pairs(ThemeObjects.Backgrounds) do tween(obj, {BackgroundColor3 = theme.Bg}) end
    for _, obj in pairs(ThemeObjects.Accents) do
        if not obj:GetAttribute("ArrayItem") then
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then tween(obj, {TextColor3 = theme.Accent})
            elseif obj:IsA("UIStroke") then tween(obj, {Color = theme.Accent})
            else tween(obj, {BackgroundColor3 = theme.Accent}) end
        end
    end
end

--========================
-- Logic Variables
--========================
local espEnabled = false
local espSettings = {Box = true, Name = true, Health = true, Dist = true}
local espConnection = nil

local noclipEnabled, noclipConnection = false, nil
local flyEnabled, flySpeed = false, 50
local flyBodyV, flyBodyG

-- Cframe Speed Variables
local cframeSpeedEnabled = false
local cframeSpeedMultiplier = 0.2
local cframeSpeedConnection = nil

-- Touch Fling Variables
local hiddenfling = false

--========================
-- GUI Base
--========================
local gui = mk("ScreenGui", {
    Name = "KosxHubV2", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = pg, ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

--========================
-- VISUALS: PARTICLES
--========================
local function createParticles(parent, count)
    local amount = count or 40 
    local container = mk("Frame", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Parent=parent, ZIndex=1})
    
    for i = 1, amount do 
        local size = math.random(2, 4)
        if count then size = math.random(1, 2) end 
        local dot = mk("Frame", {
            BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.fromOffset(size, size),
            Position = UDim2.fromScale(math.random(), math.random()),
            BackgroundTransparency = math.random(7, 9)/10, BorderSizePixel = 0, Parent = container
        })
        mk("UICorner", {Parent=dot, CornerRadius=UDim.new(1,0)})
        task.spawn(function()
            while dot.Parent do
                local targetPos = UDim2.fromScale(math.random(), math.random())
                local speed = math.random(10, 25)
                local t1 = TweenService:Create(dot, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = targetPos})
                task.spawn(function()
                    while dot.Parent do
                        TweenService:Create(dot, TweenInfo.new(2), {BackgroundTransparency = math.random(5,9)/10}):Play()
                        task.wait(math.random(2,5))
                    end
                end)
                t1:Play() t1.Completed:Wait()
            end
        end)
    end
end

--========================
-- ARRAY LIST
--========================
local arrayList = mk("Frame", {
    Name = "ArrayList", Position = UDim2.new(1, -10, 0, 10), Size = UDim2.new(0, 300, 1, 0),
    AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Parent = gui
})
mk("UIListLayout", {Parent=arrayList, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Top, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2)})

local function updateArray(name, state)
    local existing = arrayList:FindFirstChild(name)
    if state then
        if not existing then
            playToggleSound()
            local card = mk("Frame", {
                Name = name, BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.1,
                Size = UDim2.new(0, 0, 0, 24), BorderSizePixel = 0, ClipsDescendants = true, Parent = arrayList
            })
            mk("UICorner", {Parent=card, CornerRadius=UDim.new(0,4)})
            createParticles(card, 10)
            
            local txt = mk("TextLabel", {
                Text = name, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1),
                BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
                Position = UDim2.new(0, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2, Parent = card
            })
            txt:SetAttribute("ArrayItem", true)
            local grad = Instance.new("UIGradient", txt) grad.Name = "Shimmer"
            mk("UIPadding", {Parent=card, PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5)})
            
            local targetWidth = txt.TextBounds.X + 10
            card.Size = UDim2.new(0, 0, 0, 24)
            tween(card, {Size = UDim2.new(0, targetWidth, 0, 24)}, 0.3)
        end
    else
        if existing then
            local t = tween(existing, {Size = UDim2.new(0, 0, 0, 24)}, 0.25)
            t.Completed:Connect(function() existing:Destroy() end)
        end
    end
end

RunService.RenderStepped:Connect(function()
    local children = {}
    for _, child in pairs(arrayList:GetChildren()) do if child:IsA("Frame") then table.insert(children, child) end end
    table.sort(children, function(a, b)
        local tA = a:FindFirstChild("TextLabel") local tB = b:FindFirstChild("TextLabel")
        if tA and tB then return tA.TextBounds.X > tB.TextBounds.X end return false
    end)
    
    local mainColor = CURRENT.Accent
    local h, s, v = mainColor:ToHSV()
    local lightColor = Color3.fromHSV(h, math.max(0, s - 0.6), 1) 
    local shimmerSeq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, mainColor), ColorSequenceKeypoint.new(0.5, lightColor), ColorSequenceKeypoint.new(1, mainColor)
    })
    local offset = (tick() * 0.8) % 1
    
    for i, card in ipairs(children) do
        card.LayoutOrder = i
        local txt = card:FindFirstChild("TextLabel")
        if txt then
            local grad = txt:FindFirstChild("Shimmer")
            if grad then grad.Color = shimmerSeq grad.Offset = Vector2.new(-1 + (offset * 2.5), 0) end
        end
    end
end)

--========================
-- ADVANCED ESP LOGIC
--========================
local espContainer = mk("Folder", {Name = "ESP_Container", Parent = gui})

local function DrawESP(plr)
    local success, err = pcall(function()
        if not espEnabled then return end
        if plr == lp then return end
        
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        local tag = espContainer:FindFirstChild(plr.Name)
        
        if not char or not root or not hum or hum.Health <= 0 then 
            if tag then tag.Visible = false end
            return 
        end
        
        local espColor = CURRENT.Accent
        if lp.Team and plr.Team and lp.Team == plr.Team then espColor = Color3.fromRGB(40, 255, 60) end
        
        if not tag then
            tag = mk("Frame", {Name=plr.Name, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Parent=espContainer, Visible=false})
            local box = mk("Frame", {Name="Box", BackgroundTransparency=1, BorderSizePixel=0, Parent=tag, Visible=false}) mk("UIStroke", {Parent=box, Color=espColor, Thickness=1})
            local hpBarBg = mk("Frame", {Name="HealthBg", BackgroundColor3=Color3.new(0,0,0), BorderSizePixel=0, Parent=tag, Visible=false, ZIndex=2})
            local hpBar = mk("Frame", {Name="Bar", BackgroundColor3=Color3.new(0,1,0), BorderSizePixel=0, Parent=hpBarBg, ZIndex=3})
            local name = mk("TextLabel", {Name="Name", Text=plr.DisplayName, TextSize=11, Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1), BackgroundTransparency=1, Parent=tag, Visible=false, ZIndex=4}) mk("UIStroke", {Parent=name, Thickness=1, TextStrokeTransparency=0})
        end
        
        tag.Visible = true
        local box = tag:FindFirstChild("Box") local hpBg = tag:FindFirstChild("HealthBg") local hpBar = hpBg and hpBg:FindFirstChild("Bar") local name = tag:FindFirstChild("Name")
        
        if not box or not hpBg or not name then return end
        if box then box.UIStroke.Color = espColor end
        
        local cam = workspace.CurrentCamera
        local pos, onScreen = cam:WorldToViewportPoint(root.Position)
        
        if onScreen then
            local dist = (cam.CFrame.Position - root.Position).Magnitude
            local fov = math.tan(math.rad(cam.FieldOfView * 0.5))
            local scale = 1000 / ((dist * fov) + 0.01) 
            local h = scale * 2.5
            local w = h * 0.7
            
            if espSettings.Box then box.Visible = true box.Size = UDim2.fromOffset(w, h) box.Position = UDim2.fromOffset(pos.X - (w/2), pos.Y - (h/2)) else box.Visible = false end
            
            if espSettings.Health then
                hpBg.Visible = true
                local maxHp = hum.MaxHealth if maxHp <= 0 then maxHp = 100 end 
                local healthPct = math.clamp(hum.Health / maxHp, 0, 1)
                local barH = h * healthPct
                hpBg.Size = UDim2.fromOffset(2, h) hpBg.Position = UDim2.fromOffset(pos.X - (w/2) - 5, pos.Y - (h/2))
                hpBar.Size = UDim2.fromOffset(2, barH) hpBar.Position = UDim2.fromScale(0, 1 - healthPct) hpBar.BackgroundColor3 = Color3.fromHSV(healthPct * 0.3, 1, 1) 
            else hpBg.Visible = false end

            if espSettings.Name or espSettings.Dist then
                name.Visible = true
                local str = "" if espSettings.Name then str = plr.DisplayName end
                if espSettings.Dist then if espSettings.Name then str = str .. " " end str = str .. string.format("[%dm]", math.floor(dist)) end
                name.Text = str name.Position = UDim2.fromOffset(pos.X - (name.TextBounds.X/2), pos.Y - (h/2) - 16)
            else name.Visible = false end
        else
            box.Visible = false; hpBg.Visible = false; name.Visible = false
        end
    end)
    if not success then warn("ESP Fail:", err) end
end

local function toggleESP(state)
    espEnabled = state
    if state then
        if espConnection then espConnection:Disconnect() end
        espContainer:ClearAllChildren()
        espConnection = RunService.RenderStepped:Connect(function() for _, p in pairs(Players:GetPlayers()) do DrawESP(p) end end)
    else
        if espConnection then espConnection:Disconnect() end
        espContainer:ClearAllChildren()
    end
end

--========================
-- Other Logic
--========================
local function toggleNoclip(state)
    noclipEnabled = state
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if lp.Character then for _, part in pairs(lp.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end end
        end)
    else if noclipConnection then noclipConnection:Disconnect() end end
end

local function toggleFly(state)
    flyEnabled = state
    local char = lp.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if state and root and hum then
        flyBodyV = Instance.new("BodyVelocity", root) flyBodyV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyG = Instance.new("BodyGyro", root) flyBodyG.MaxTorque = Vector3.new(9e9, 9e9, 9e9) flyBodyG.P = 9e4
        hum.PlatformStand = true
        task.spawn(function()
            while flyEnabled and char.Parent do
                local cam = workspace.CurrentCamera
                local move = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
                flyBodyV.Velocity = move * flySpeed
                flyBodyG.CFrame = cam.CFrame
                RunService.RenderStepped:Wait()
            end
        end)
    else
        if flyBodyV then flyBodyV:Destroy() end if flyBodyG then flyBodyG:Destroy() end if hum then hum.PlatformStand = false end
    end
end

-- Cframe Speed Logic
local function toggleCframeSpeed(state)
    cframeSpeedEnabled = state
    if state then
        if cframeSpeedConnection then cframeSpeedConnection:Disconnect() end
        cframeSpeedConnection = RunService.RenderStepped:Connect(function()
            local character = lp.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                
                if rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                    rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * cframeSpeedMultiplier)
                end
            end
        end)
    else
        if cframeSpeedConnection then
            cframeSpeedConnection:Disconnect()
            cframeSpeedConnection = nil
        end
    end
end

-- Touch Fling Loop Logic
local function startFlingLoop()
    local movel = 0.1
    while hiddenfling do
        RunService.Heartbeat:Wait()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")

        if hrp then
            local vel = hrp.Velocity
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

local function toggleTouchFling(state)
    hiddenfling = state
    if hiddenfling then
        task.spawn(startFlingLoop)
    end
end

-- SCROLL FLY SPEED HANDLER
local function handleFlyScroll(actionName, inputState, inputObject)
    if flyEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if inputObject.Position.Z ~= 0 then
            local change = (inputObject.Position.Z > 0) and 3 or -3
            flySpeed = math.clamp(flySpeed + change, 10, 1000)
        end
        return Enum.ContextActionResult.Sink 
    end
    return Enum.ContextActionResult.Pass
end
ContextActionService:BindActionAtPriority("KosxHubFlyScroll", handleFlyScroll, false, 3000, Enum.UserInputType.MouseWheel)

lp.CharacterAdded:Connect(function()
    flyEnabled = false
    cframeSpeedEnabled = false
    hiddenfling = false
    if cframeSpeedConnection then
        cframeSpeedConnection:Disconnect()
        cframeSpeedConnection = nil
    end
end)

--========================
-- MAIN GUI
--========================
local notifyContainer = mk("Frame", {Name = "Notify", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -50), Size = UDim2.new(0, 250, 0, 400), BackgroundTransparency = 1, Parent = gui, ZIndex=10})
mk("UIListLayout", {Parent=notifyContainer, VerticalAlignment=Enum.VerticalAlignment.Bottom, Padding=UDim.new(0,10)})

local function sendNotify(title, msg)
    local f = mk("Frame", {BackgroundColor3 = Color3.fromRGB(20,20,23), Size = UDim2.new(1,0,0,0), ClipsDescendants = true, Parent = notifyContainer})
    mk("UICorner", {Parent=f, CornerRadius=UDim.new(0,8)})
    local str = mk("UIStroke", {Parent=f, Color=CURRENT.Accent, Thickness=1, Transparency=0.5})
    table.insert(ThemeObjects.Accents, str) 
    mk("TextLabel", {Text=title, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=CURRENT.Accent, BackgroundTransparency=1, Position=UDim2.new(0,12,0,8), Size=UDim2.new(1,-24,0,16), TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
    mk("TextLabel", {Text=msg, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,12,0,24), Size=UDim2.new(1,-24,0,20), TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
    tween(f, {Size = UDim2.new(1,0,0,55)}, 0.3)
    task.delay(3, function() if f then local out = tween(f, {Size = UDim2.new(1,0,0,0), BackgroundTransparency=1}, 0.3) out.Completed:Connect(function() f:Destroy() end) end end)
end

-- Window
local window = mk("Frame", {
    Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(500, 340),
    BackgroundColor3 = CURRENT.Bg, BackgroundTransparency = 0.02,
    Active = true, ClipsDescendants = true, Parent = gui
})
mk("UICorner", {Parent=window, CornerRadius=UDim.new(0,10)})
local wStroke = mk("UIStroke", {Parent=window, Color=Color3.fromRGB(60,60,65), Thickness=1, Transparency=0.4})
table.insert(ThemeObjects.Backgrounds, window)

-- START PARTICLES
createParticles(window)

-- Topbar
local top = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = window})

mk("TextLabel", {Text = "Kosx Hub", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0, 50, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = top})

local profileContainer = mk("Frame", {Name = "Profile", BackgroundColor3 = Color3.fromRGB(25,25,28), BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 75, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), ClipsDescendants = true, Parent = top})
local iconId = "rbxassetid://0" pcall(function() iconId = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
local userAvatar = mk("ImageLabel", {Name = "Avatar", Image = iconId, BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = profileContainer})
mk("UICorner", {Parent = userAvatar, CornerRadius = UDim.new(0, 6)})
local avaStroke = mk("UIStroke", {Parent = userAvatar, Thickness = 1.5, Color = CURRENT.Accent, Transparency = 0})
table.insert(ThemeObjects.Accents, avaStroke)
local userName = mk("TextLabel", {Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(220,220,220), BackgroundTransparency = 1, Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(0, 100, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Parent = profileContainer})

profileContainer.MouseEnter:Connect(function() tween(profileContainer, {Size = UDim2.fromOffset(34 + userName.TextBounds.X + 10, 30)}, 0.3) tween(userName, {TextTransparency = 0}, 0.3) end)
profileContainer.MouseLeave:Connect(function() tween(profileContainer, {Size = UDim2.fromOffset(30, 30)}, 0.3) tween(userName, {TextTransparency = 1}, 0.2) end)

local minBtn = mk("TextButton", {Text = "-", Font=Enum.Font.GothamBold, TextSize=22, TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Size=UDim2.fromOffset(30,30), Parent=top})
local headerStatus = mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 200, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -50, 0, 0), Font = Enum.Font.Code, TextSize = 11, TextColor3 = Color3.fromRGB(150,150,150), TextXAlignment = Enum.TextXAlignment.Right, Visible = false, Text = "...", Parent = top})
local topSep = mk("Frame", {BackgroundColor3 = Color3.fromRGB(60,60,65), BorderSizePixel=0, Position=UDim2.new(0,0,0,40), Size=UDim2.new(1,0,0,1), Parent=window})

-- Footer
local footer = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -25), Size = UDim2.new(1, 0, 0, 25), Parent = window})
mk("Frame", {BackgroundColor3 = Color3.fromRGB(60,60,65), BorderSizePixel=0, Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,1), Parent=footer})
local footerStatus = mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Code, TextSize = 11, TextColor3 = Color3.fromRGB(150,150,150), TextXAlignment = Enum.TextXAlignment.Right, Text = "Loading...", Parent = footer})

local startTime = os.time()
task.spawn(function()
    while window.Parent do
        local fps = math.floor(workspace:GetRealPhysicsFPS())
        local ping = 0 pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():match("%d+")) end)
        
        local currentTime = os.time()
        local elapsed = currentTime - startTime
        local minutes = math.floor(elapsed / 60)
        
        local text = string.format("FPS: %d  |  Ping: %dms  |  Session: %dm", fps, ping, minutes)
        footerStatus.Text = text headerStatus.Text = text
        task.wait(1)
    end
end)

-- Layout Structure
local content = mk("Frame", {BackgroundTransparency = 1, Position=UDim2.new(0,0,0,41), Size=UDim2.new(1,0,1,-66), Parent=window, ZIndex=2})
local sidebar = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(0,140,1,0), Parent=content})
local pagesHost = mk("Frame", {BackgroundTransparency=1, Position=UDim2.new(0,140,0,0), Size=UDim2.new(1,-140,1,0), Parent=content})
local tabContainer = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,-45), Parent=sidebar})
mk("UIListLayout", {Parent=tabContainer, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
mk("UIPadding", {Parent=tabContainer, PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10)})
local setContainer = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,45), Position=UDim2.new(0,0,1,-45), Parent=sidebar})
mk("Frame", {BackgroundColor3=Color3.fromRGB(60,60,65), BorderSizePixel=0, Size=UDim2.new(1,0,0,1), Parent=setContainer}) 

--========================
-- Components
--========================
local tabs = {}
local function createTab(name, parent)
    local btn = mk("TextButton", {
        Text = name, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(150,150,150),
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,32), TextXAlignment=Enum.TextXAlignment.Left, Parent=parent or tabContainer
    })
    mk("UIPadding", {Parent=btn, PaddingLeft=UDim.new(0, 15)})
    local indicator = mk("Frame", {BackgroundColor3 = CURRENT.Accent, Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, -10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, BackgroundTransparency = 1, Parent = btn})
    mk("UICorner", {Parent=indicator, CornerRadius=UDim.new(1,0)}) table.insert(ThemeObjects.Accents, indicator) 
    local page = mk("ScrollingFrame", {Visible=false, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=Color3.fromRGB(150,150,150), BorderSizePixel=0, Parent=pagesHost})
    mk("UIListLayout", {Parent=page, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,10)})
    mk("UIPadding", {Parent=page, PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,5)})
    btn.MouseButton1Click:Connect(function()
        playClick(1) for _,t in pairs(tabs) do tween(t.Btn, {TextColor3=Color3.fromRGB(150,150,150)}) tween(t.Ind, {Size=UDim2.new(0,3,0,0), BackgroundTransparency=1}) t.Page.Visible = false end
        tween(btn, {TextColor3=CURRENT.Accent}) tween(indicator, {Size=UDim2.new(0,3,0,20), BackgroundTransparency=0}) page.Visible = true
    end)
    table.insert(tabs, {Btn=btn, Page=page, Ind=indicator}) return page
end

-- Функция создания переключателя с биндом
local function createSwitch(parent, text, callback)
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(35,35,38), Size=UDim2.new(1,-10,0,44), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text = text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,15,0,0), Size=UDim2.new(0.6,0,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    
    -- Кнопка для бинда (маленькое окошко)
    local savedKey = Config.Binds[text] 
    local displayKey = savedKey and "["..savedKey.."]" or "[...]"
    local bindBtn = mk("TextButton", {
        Text = displayKey, 
        Font=Enum.Font.GothamBold, 
        TextSize=11, 
        TextColor3=Color3.fromRGB(150,150,150),
        BackgroundColor3 = Color3.fromRGB(25,25,28),
        Size=UDim2.new(0,45,0,24), 
        AnchorPoint=Vector2.new(1,0.5), 
        Position=UDim2.new(1,-65,0.5,0),
        AutoButtonColor=false,
        Parent=c
    })
    mk("UICorner", {Parent=bindBtn, CornerRadius=UDim.new(0,6)})
    mk("UIStroke", {Parent=bindBtn, Color=Color3.fromRGB(60,60,65), Thickness=1, Transparency=0.5})
    
    -- Переключатель
    local sw = mk("TextButton", {Text = "", AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(50,50,55), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-15,0.5,0), Size=UDim2.fromOffset(40, 20), Parent=c})
    mk("UICorner", {Parent=sw, CornerRadius=UDim.new(1,0)})
    local circ = mk("Frame", {BackgroundColor3 = Color3.new(1,1,1), Size=UDim2.fromOffset(14,14), AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,3,0.5,0), Parent=sw})
    mk("UICorner", {Parent=circ, CornerRadius=UDim.new(1,0)})
    
    local on = false 
    local bind = savedKey and Enum.KeyCode[savedKey] or nil
    
    local function doToggle()
        on = not on
        if on then 
            playClick(1.1) 
            tween(sw, {BackgroundColor3 = CURRENT.Accent}) 
            tween(circ, {Position = UDim2.new(1, -17, 0.5, 0)}) 
            sendNotify("Enabled", text)
        else 
            playClick(0.9) 
            tween(sw, {BackgroundColor3 = Color3.fromRGB(50,50,55)}) 
            tween(circ, {Position = UDim2.new(0, 3, 0, 3)}) 
            sendNotify("Disabled", text) 
        end
        updateArray(text, on) 
        if callback then callback(on) end
    end
    
    sw.MouseButton1Click:Connect(doToggle)
    
    -- Система бинда (нажатие на маленькое окошко)
    bindBtn.MouseButton1Click:Connect(function()
        bindBtn.Text = "[...]"
        bindBtn.TextColor3 = CURRENT.Accent
        local conn
        conn = UserInputService.InputBegan:Connect(function(key)
            if key.UserInputType == Enum.UserInputType.Keyboard then
                if key.KeyCode == Enum.KeyCode.Backspace then
                    bind = nil
                    bindBtn.Text = "[...]"
                    Config.Binds[text] = nil
                else
                    bind = key.KeyCode
                    bindBtn.Text = "["..key.KeyCode.Name.."]"
                    Config.Binds[text] = key.KeyCode.Name
                end
                SaveConfig()
                bindBtn.TextColor3 = Color3.fromRGB(150,150,150)
                conn:Disconnect()
            elseif key.UserInputType == Enum.UserInputType.MouseButton1 then
                bindBtn.Text = bind and ("["..bind.Name.."]") or "[...]"
                bindBtn.TextColor3 = Color3.fromRGB(150,150,150)
                conn:Disconnect()
            end
        end)
    end)
    
    -- Глобальный обработчик для бинда
    UserInputService.InputBegan:Connect(function(input, gp) 
        if not gp and bind and input.KeyCode == bind then 
            doToggle() 
        end 
    end)
end

-- Функция создания ОДНОРАЗОВОЙ КНОПКИ (для скриптов)
local function createButton(parent, text, callback)
    local btn = mk("TextButton", {
        Text = text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240),
        BackgroundColor3 = Color3.fromRGB(35,35,38), Size = UDim2.new(1, -10, 0, 35), AutoButtonColor = false, Parent = parent
    })
    mk("UICorner", {Parent=btn, CornerRadius=UDim.new(0,8)})
    mk("UIStroke", {Parent=btn, Color=Color3.fromRGB(60,60,65), Thickness=1, Transparency=0.5})

    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Color3.fromRGB(45,45,48)}) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Color3.fromRGB(35,35,38)}) end)
    
    btn.MouseButton1Click:Connect(function()
        playClick(1.1)
        tween(btn, {Size = UDim2.new(1, -14, 0, 31)}, 0.1).Completed:Connect(function()
            tween(btn, {Size = UDim2.new(1, -10, 0, 35)}, 0.1)
        end)
        if callback then callback() end
        sendNotify("Script Executed", text .. " loaded!")
    end)
end

-- ESP Control с биндом
local function createEspControl(parent, callback)
    local text = "Player ESP" 
    local c = mk("Frame", {BackgroundColor3 = Color3.fromRGB(35,35,38), Size = UDim2.new(1, -10, 0, 44), ClipsDescendants = true, Parent = parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text = text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,15,0,0), Size=UDim2.new(0.6,0,0,44), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    
    -- Кнопка для бинда
    local savedKey = Config.Binds[text] 
    local displayKey = savedKey and "["..savedKey.."]" or "[...]"
    local bindBtn = mk("TextButton", {
        Text = displayKey, 
        Font=Enum.Font.GothamBold, 
        TextSize=11, 
        TextColor3=Color3.fromRGB(150,150,150),
        BackgroundColor3 = Color3.fromRGB(25,25,28),
        Size=UDim2.new(0,45,0,24), 
        AnchorPoint=Vector2.new(1,0.5), 
        Position=UDim2.new(1,-65,0.5,0),
        AutoButtonColor=false,
        Parent=c
    })
    mk("UICorner", {Parent=bindBtn, CornerRadius=UDim.new(0,6)})
    mk("UIStroke", {Parent=bindBtn, Color=Color3.fromRGB(60,60,65), Thickness=1, Transparency=0.5})

    -- Переключатель
    local sw = mk("TextButton", {Text = "", AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(50,50,55), AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-15,0,12), Size=UDim2.fromOffset(40, 20), Parent=c})
    mk("UICorner", {Parent=sw, CornerRadius=UDim.new(1,0)})
    local circ = mk("Frame", {BackgroundColor3 = Color3.new(1,1,1), Size=UDim2.fromOffset(14,14), AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,3,0.5,0), Parent=sw})
    mk("UICorner", {Parent=circ, CornerRadius=UDim.new(1,0)})

    -- Подменю для настроек ESP
    local subRow = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 30), Parent = c})
    mk("UIListLayout", {Parent = subRow, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8)})

    local function createChip(t, settingKey)
        local btn = mk("TextButton", {Text = t, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = espSettings[settingKey] and Color3.new(1,1,1) or Color3.fromRGB(120,120,120), BackgroundColor3 = espSettings[settingKey] and CURRENT.Accent or Color3.fromRGB(45,45,48), Size = UDim2.fromOffset(55, 24), AutoButtonColor = false, Parent = subRow})
        mk("UICorner", {Parent=btn, CornerRadius=UDim.new(0, 6)}) if espSettings[settingKey] then table.insert(ThemeObjects.Accents, btn) end
        btn.MouseButton1Click:Connect(function()
            playClick(1) espSettings[settingKey] = not espSettings[settingKey]
            if espSettings[settingKey] then tween(btn, {BackgroundColor3 = CURRENT.Accent, TextColor3 = Color3.new(1,1,1)}) table.insert(ThemeObjects.Accents, btn) else tween(btn, {BackgroundColor3 = Color3.fromRGB(45,45,48), TextColor3 = Color3.fromRGB(120,120,120)}) end
        end)
    end
    createChip("Box", "Box") createChip("Name", "Name") createChip("Health", "Health") createChip("Dist", "Dist")

    local on = false 
    local bind = savedKey and Enum.KeyCode[savedKey] or nil
    
    local function doToggle()
        on = not on
        if on then 
            playClick(1.1) 
            tween(sw, {BackgroundColor3 = CURRENT.Accent}) 
            tween(circ, {Position = UDim2.new(1, -17, 0.5, 0)}) 
            tween(c, {Size = UDim2.new(1, -10, 0, 84)}, 0.4) 
            sendNotify("Enabled", text)
        else 
            playClick(0.9) 
            tween(sw, {BackgroundColor3 = Color3.fromRGB(50,50,55)}) 
            tween(circ, {Position = UDim2.new(0, 3, 0.5, 0)}) 
            tween(c, {Size = UDim2.new(1, -10, 0, 44)}, 0.4) 
            sendNotify("Disabled", text) 
        end
        updateArray(text, on) 
        callback(on)
    end
    
    sw.MouseButton1Click:Connect(doToggle)
    
    -- Система бинда для ESP
    bindBtn.MouseButton1Click:Connect(function()
        bindBtn.Text = "[...]"
        bindBtn.TextColor3 = CURRENT.Accent
        local conn
        conn = UserInputService.InputBegan:Connect(function(key)
            if key.UserInputType == Enum.UserInputType.Keyboard then
                if key.KeyCode == Enum.KeyCode.Backspace then
                    bind = nil
                    bindBtn.Text = "[...]"
                    Config.Binds[text] = nil
                else
                    bind = key.KeyCode
                    bindBtn.Text = "["..key.KeyCode.Name.."]"
                    Config.Binds[text] = key.KeyCode.Name
                end
                SaveConfig()
                bindBtn.TextColor3 = Color3.fromRGB(150,150,150)
                conn:Disconnect()
            elseif key.UserInputType == Enum.UserInputType.MouseButton1 then
                bindBtn.Text = bind and ("["..bind.Name.."]") or "[...]"
                bindBtn.TextColor3 = Color3.fromRGB(150,150,150)
                conn:Disconnect()
            end
        end)
    end)
    
    UserInputService.InputBegan:Connect(function(input, gp) 
        if not gp and bind and input.KeyCode == bind then 
            doToggle() 
        end 
    end)
end

local function createDragValue(parent, text, min, max, def, callback)
    local c = mk("Frame", {BackgroundColor3=Color3.fromRGB(35,35,38), Size=UDim2.new(1,-10,0,44), Parent=parent})
    mk("UICorner", {Parent=c, CornerRadius=UDim.new(0,8)})
    mk("TextLabel", {Text=text, Font=Enum.Font.GothamMedium, TextSize=13, TextColor3=Color3.fromRGB(240,240,240), BackgroundTransparency=1, Position=UDim2.new(0,15,0,0), Size=UDim2.new(0.6,0,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=c})
    local btn = mk("TextButton", {Text=tostring(def), Font=Enum.Font.GothamBold, TextSize=14, TextColor3=CURRENT.Accent, BackgroundColor3=Color3.fromRGB(25,25,28), Size=UDim2.new(0,60,0,24), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-15,0.5,0), AutoButtonColor=false, Parent=c})
    mk("UICorner", {Parent=btn, CornerRadius=UDim.new(0,6)})
    mk("UIStroke", {Parent=btn, Color=Color3.fromRGB(60,60,65), Thickness=1, Transparency=0.5}) table.insert(ThemeObjects.Accents, btn) 
    
    local val = def 
    local dragging = false 
    local dragStart = Vector2.new() 
    local startVal = val
    
    btn.InputBegan:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true 
            dragStart = i.Position 
            startVal = val 
        end 
    end)
    
    UserInputService.InputChanged:Connect(function(i) 
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then 
            local deltaX = i.Position.X - dragStart.X 
            local change = math.floor(deltaX / 2) 
            val = math.clamp(startVal + change, min, max) 
            btn.Text = tostring(val) 
            callback(val) 
        end 
    end)
    
    UserInputService.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = false 
            if (i.Position - dragStart).Magnitude < 3 then 
                local box = mk("TextBox", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", PlaceholderText="#", TextColor3=CURRENT.Accent, Font=Enum.Font.GothamBold, TextSize=14, Parent=btn}) 
                box:CaptureFocus() 
                box.FocusLost:Connect(function(e) 
                    if e and tonumber(box.Text) then 
                        val = math.clamp(tonumber(box.Text), min, max) 
                        btn.Text = tostring(val) 
                        callback(val) 
                    end 
                    box:Destroy() 
                end) 
            end 
        end 
    end)
end

--========================
-- Build Content
--========================
local pCombat = createTab("Combat")
local pScripts = createTab("Scripts") -- Твоя новая вкладка для скриптов
local pSettings = createTab("Settings", setContainer)
local setBtn = tabs[#tabs].Btn
setBtn.Size = UDim2.new(1,0,1,0) setBtn.Position = UDim2.new(0,0,0,0)

-- > COMBAT TAB 
createEspControl(pCombat, function(v) toggleESP(v) end)
createSwitch(pCombat, "Touch Fling", function(v) toggleTouchFling(v) end)
createSwitch(pCombat, "Cframe Speed", function(v) toggleCframeSpeed(v) end)
createDragValue(pCombat, "Cframe Speed Multiplier", 0.01, 2, 0.2, function(v) 
    cframeSpeedMultiplier = v 
end)
createSwitch(pCombat, "Cframe Fly", function(v) toggleFly(v) end)
createSwitch(pCombat, "Noclip", function(v) toggleNoclip(v) end)
createDragValue(pCombat, "Fly Speed", 10, 1000, 50, function(v) flySpeed = v end)

-- > SCRIPTS TAB (Твои скрипты)
createButton(pScripts, "Infinite Yield", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)
createButton(pScripts, "Bring Parts", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/GELATENOZE/bringallpartsgela/refs/heads/main/partsbring.lua"))()
end)
createButton(pScripts, "Camlock-Q", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/GELATENOZE/camlock/e1de1d2ca33d78ba650daaa8350da0180efe0316/lock.lua"))()
end)
createButton(pScripts, "f3x tool", function()
	loadstring(game:GetObjects("rbxassetid://6695644299")[1].Source)()
end)

-- > SETTINGS TAB
mk("TextLabel", {Text = "Theme Presets", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(150,150,150), BackgroundTransparency = 1, Size = UDim2.new(1,0,0,20), TextXAlignment=Enum.TextXAlignment.Left, Parent = pSettings})
mk("UIPadding", {Parent=pSettings, PaddingLeft=UDim.new(0,10)})
local palette = mk("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,-10,0,40), Parent=pSettings})
mk("UIListLayout", {Parent=palette, FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,10)})
for i, theme in ipairs(PRESETS) do
    local colorBtn = mk("TextButton", {
        Text = "", BackgroundColor3 = theme.Accent, Size = UDim2.new(0, 30, 0, 30), AutoButtonColor = false, Parent = palette
    })
    mk("UICorner", {Parent=colorBtn, CornerRadius=UDim.new(1,0)})
    
    colorBtn.MouseButton1Click:Connect(function()
        SetTheme(i)
        for _, t in pairs(tabs) do
            if t.Page.Visible then
                tween(t.Btn, {TextColor3 = theme.Accent})
            else
                t.Btn.TextColor3 = Color3.fromRGB(150,150,150)
            end
        end
    end)
end

-- Init
task.delay(0.1, function()
    tabs[1].Btn.TextColor3 = CURRENT.Accent
    tabs[1].Page.Visible = true
    tabs[1].Ind.Size = UDim2.new(0,3,0,20)
    tabs[1].Ind.BackgroundTransparency = 0
end)

-- Minimize & Drag
local minimized, normalSize, miniSize, centerPos, topPos = false, UDim2.fromOffset(500, 340), UDim2.fromOffset(500, 40), UDim2.fromScale(0.5, 0.5), UDim2.new(0.5, 0, 0, 30)
minBtn.MouseButton1Click:Connect(function()
    playClick(1)
    minimized = not minimized
    if minimized then
        tween(window, {Size = miniSize, Position = topPos}, 0.5) tween(wStroke, {Transparency = 1}, 0.3)
        topSep.BackgroundTransparency = 1 footer.Visible = false content.Visible = false headerStatus.Visible = true minBtn.Text = "+" minBtn.TextColor3 = CURRENT.Accent
    else
        tween(window, {Size = normalSize, Position = centerPos}, 0.5) tween(wStroke, {Transparency = 0.4}, 0.3)
        headerStatus.Visible = false task.delay(0.3, function() topSep.BackgroundTransparency = 0 footer.Visible = true content.Visible = true end) minBtn.Text = "-" minBtn.TextColor3 = Color3.fromRGB(150,150,150)
    end
end)

local dragging, dragStart, startPos
window.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true dragStart=i.Position startPos=window.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local d=i.Position-dragStart window.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)

local vis = true
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.J then vis = not vis window.Visible = vis end end)

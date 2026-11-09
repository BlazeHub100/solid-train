-- โหลด Rayfield UI Library แบบปลอดภัย
local successRay, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not successRay or not Rayfield then
    warn("⚠️ โหลด Rayfield UI ไม่สำเร็จ")
    return
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- สร้าง หน้าต่าง Rayfield UI หลัก
local Window = Rayfield:CreateWindow({
   Name = "BlazeHub - MM2 God Tier Homing Hub",
   LoadingTitle = "กำลังโหลดระบบล็อกเป้าอัจฉริยะ...",
   LoadingSubtitle = "โดย BlazeHub",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("🎯 ระบบล็อกเป้ายิง", 4483362458)
local KillerTab = Window:CreateTab("🔪 ฆาตกร", 4483362458)
local SheriffTab = Window:CreateTab("🛡️ นายอำเภอ", 4483362458)
local EspTab = Window:CreateTab("👁️ esp", 4483362458)

-- =========================================================================
-- ส่วนที่ 1: สร้างปุ่มวงกลมลอยบนจอ (ย้ายตำแหน่งได้อิสระ)
-- =========================================================================
pcall(function()
    if CoreGui:FindFirstChild("BlazeHubFloatButton") then
        CoreGui.BlazeHubFloatButton:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BlazeHubFloatButton"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local FloatButton = Instance.new("TextButton")
FloatButton.Name = "ShootCircleButton"
FloatButton.Size = UDim2.new(0, 75, 0, 75)
FloatButton.Position = UDim2.new(0.8, 0, 0.5, 0)
FloatButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
FloatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatButton.TextSize = 16
FloatButton.Font = Enum.Font.GothamBold
FloatButton.Text = "🎯 ยิง"
FloatButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FloatButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 50, 50)
UIStroke.Thickness = 3.5
UIStroke.Parent = FloatButton

-- ระบบลากปุ่มวงกลมบนมือถือ
local dragging, dragInput, dragStart, startPos
FloatButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = FloatButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

FloatButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        FloatButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- =========================================================================
-- ส่วนที่ 2: ระบบตรวจสอบบทบาทและรีโมตยิง "ดักหน้าคนกระโดด" (Prediction Homing)
-- =========================================================================

local function GetNil(Name, DebugId)
	for _, Object in getnilinstances() do
		if Object.Name == Name and Object:GetDebugId() == DebugId then
			return Object
		end
	end
end

local function GetShootEvent()
    local event = GetNil("Shoot", "1_9585014")
    if not event then
        pcall(function()
            event = LocalPlayer.Backpack.Gun.Shoot
        end)
    end
    if not event then
        pcall(function()
            event = LocalPlayer.Character.Gun.Shoot
        end)
    end
    return event
end

-- ฟังก์ชันตรวจสอบบทบาท (โค้ดดั้งเดิมมึงเป๊ะๆ)
local function getPlayerRole(player)
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    
    if not character then return "Innocent" end
    
    local hasGun = character:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))
    local hasKnife = character:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))
    
    if hasKnife then
        return "Murderer"
    elseif hasGun then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- ค้นหาหัวฆาตกร + คำนวณความเร็วดักหน้าตอนกระโดด
local function GetPredictedKillerCFrame()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if rootPart and head and getPlayerRole(player) == "Murderer" then
                -- คำนวณความเร็ว (Velocity) เพื่อดักทางตอนมันกระโดดหรือวิ่งหนี
                local velocity = rootPart.Velocity
                local predictedPos = head.Position + (velocity * 0.12) -- คำนวณพิกัดล่วงหน้าเสี้ยววินาที
                local predictedCFrame = CFrame.new(predictedPos)
                
                return predictedCFrame, player.Name
            end
        end
    end
    return nil, nil
end

-- ฟังก์ชันยิงถล่มดักจังหวะกระโดด (รัว 4 นัดติดด้วยพิกัดทำนายล่วงหน้า)
local function FireHomingBullet()
    local shootEvent = GetShootEvent()
    local targetCF, killerName = GetPredictedKillerCFrame()
    
    if shootEvent and targetCF then
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        if myRoot then
            local originCF = myRoot.CFrame
            -- รัวยิง 4 นัดติดเพื่อล้างบางไอ้ตัวที่ชอบกระโดดหลบ
            task.spawn(function()
                for i = 1, 4 do
                    local liveCF, _ = GetPredictedKillerCFrame()
                    if liveCF then
                        shootEvent:FireServer(originCF, liveCF)
                    else
                        shootEvent:FireServer(originCF, targetCF)
                    end
                    task.wait(0.01)
                end
            end)
            return true, killerName
        end
    end
    return false, nil
end

-- =========================================================================
-- ส่วนที่ 3: ฟังก์ชันเพิ่มเติม (วาร์ปเก็บปืน, ดึงคน, ทะลุคน)
-- =========================================================================

local function TeleportToDroppedGun()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") or not myChar:FindFirstChild("Humanoid") then
        Rayfield:Notify({Title = "ผิดพลาด", Content = "ตัวละครของคุณยังไม่พร้อม", Duration = 2})
        return
    end
    
    local originalCFrame = myChar.HumanoidRootPart.CFrame
    local foundGunDrop = nil
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "GunDrop" or (obj:IsA("BasePart") and obj.Name:lower():find("gun")) then
            if not obj.Parent:FindFirstChild("Humanoid") then
                foundGunDrop = obj
                break
            end
        end
    end
    
    if foundGunDrop then
        pcall(function()
            myChar.Humanoid.PlatformStand = false
            myChar.HumanoidRootPart.CFrame = foundGunDrop.CFrame + Vector3.new(0, 1.5, 0)
            
            if foundGunDrop:IsA("BasePart") then
                firetouchinterest(myChar.HumanoidRootPart, foundGunDrop, 0)
                task.wait(0.05)
                firetouchinterest(myChar.HumanoidRootPart, foundGunDrop, 1)
            end
            
            task.wait(0.2)
            myChar.HumanoidRootPart.CFrame = originalCFrame
            Rayfield:Notify({Title = "สำเร็จ!", Content = "เก็บปืนและวาร์ปกลับจุดเดิมเรียบร้อย!", Duration = 2})
        end)
    else
        Rayfield:Notify({Title = "ไม่พบปืน", Content = "ยังไม่มีปืนตกอยู่บนพื้น", Duration = 2})
    end
end

local function TeleportAllToMe()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myPos = myChar.HumanoidRootPart.CFrame + (myChar.HumanoidRootPart.CFrame.LookVector * 5)
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                player.Character.HumanoidRootPart.CFrame = myPos
                count = count + 1
            end)
        end
    end
    Rayfield:Notify({Title = "สำเร็จ!", Content = "ดึงผู้เล่นจำนวน " .. count .. " คนมาข้างหน้าคุณแล้ว", Duration = 2})
end

local AntiPushEnabled = false
RunService.Stepped:Connect(function()
    if AntiPushEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- ส่วนที่ 4: ระบบ ESP ของมึง (ใส่ไว้ในหมวดหมู่ esp)
-- =========================================================================

local EspEnabled = false

local function applyESP(player)
    if player == LocalPlayer then return end
    
    local function updateHighlight()
        local character = player.Character
        if not character then return end
        
        local highlight = character:FindFirstChild("BlazeESP")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "BlazeESP"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = character
        end
        
        local role = getPlayerRole(player)
        if role == "Murderer" then
            highlight.FillColor = Color3.fromRGB(255, 0, 0) -- สีแดง
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        elseif role == "Sheriff" then
            highlight.FillColor = Color3.fromRGB(0, 100, 255) -- สีน้ำเงิน
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        else
            highlight.FillColor = Color3.fromRGB(0, 255, 0) -- สีเขียว
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        end
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        updateHighlight()
    end)
    
    if player.Character then
        updateHighlight()
    end
end

RunService.Heartbeat:Connect(function()
    if EspEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                applyESP(player)
            end
        end
    end
end)

-- =========================================================================
-- ส่วนที่ 5: ปุ่มกดและเมนู UI แยกตามหมวดหมู่
-- =========================================================================

FloatButton.MouseButton1Click:Connect(function()
    local success, killerName = FireHomingBullet()
    if success then
        FloatButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(0.15)
        FloatButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    else
        FloatButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        task.wait(0.15)
        FloatButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
end)

MainTab:CreateButton({
   Name = "⚡ ยิงดักหัวฆาตกร (Prediction Homing)",
   Callback = function()
      local success, killerName = FireHomingBullet()
      if success then
         Rayfield:Notify({Title = "สำเร็จ!", Content = "ยิงดักวิถีเป้าหมายของ: " .. tostring(killerName), Duration = 2})
      else
         Rayfield:Notify({Title = "ไม่พบเป้าหมาย", Content = "ยังไม่เจอฆาตกร หรือยังไม่ได้ถือปืน", Duration = 2})
      end
   end,
})

local AutoHomingEnabled = false
MainTab:CreateToggle({
   Name = "🔄 ออโต้กระสุนดักหน้าฆาตกร (Auto Prediction)",
   CurrentValue = false,
   Flag = "AutoHomingToggle",
   Callback = function(Value)
      AutoHomingEnabled = Value
      if AutoHomingEnabled then
         task.spawn(function()
            while AutoHomingEnabled do
               FireHomingBullet()
               task.wait(0.15)
            end
         end)
      end
   end,
})

KillerTab:CreateButton({
   Name = "🧲 ดึงทุกคนมาข้างหน้า (Teleport All to Me)",
   Callback = function()
      TeleportAllToMe()
   end,
})

KillerTab:CreateToggle({
   Name = "👻 เดินทะลุผู้คน (กันคนชน / Anti-Push)",
   CurrentValue = false,
   Flag = "AntiPushToggle",
   Callback = function(Value)
      AntiPushEnabled = Value
   end,
})

SheriffTab:CreateButton({
   Name = "🔫 วาร์ปเก็บปืนที่ตกพื้นอัตโนมัติ (Auto Grab Gun)",
   Callback = function()
      TeleportToDroppedGun()
   end,
})

EspTab:CreateToggle({
   Name = "👁️ เปิดใช้งาน ESP มองทะลุกำแพง",
   CurrentValue = false,
   Flag = "EspToggle",
   Callback = function(Value)
      EspEnabled = Value
      if not EspEnabled then
          for _, player in ipairs(Players:GetPlayers()) do
              if player.Character and player.Character:FindFirstChild("BlazeESP") then
                  player.Character.BlazeESP:Destroy()
              end
          end
      end
   end,
})

Rayfield:Notify({Title = "พร้อมลุย", Content = "อัปเกรดระบบยิงดักหน้าคนกระโดดเรียบร้อย!", Duration = 3})
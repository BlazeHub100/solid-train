-- โหลด Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- สร้าง หน้าต่างหลัก (Window) สำหรับแมพเบอร์เกอร์
local Window = Rayfield:CreateWindow({
   Name = "Burger Shop Hub - Map 2 (Safe Fixed)",
   LoadingTitle = "กำลังโหลดระบบร้านเบอร์เกอร์...",
   LoadingSubtitle = "โดย AI Assistant",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- อ้างอิง Network ตามโครงสร้างของแมพเบอร์เกอร์
local NetworkFolder = ReplicatedStorage:WaitForChild("Network")
local NetEvent1 = NetworkFolder:GetChildren()[69]  
local NetEvent2 = NetworkFolder:GetChildren()[259] 

-- ตัวแปรควบคุมสถานะและพิกัดล็อกถาวร
local AutoOrderEnabled = false
local AutoDishEnabled = false
local AutoRegisterEnabled = false
local AutoStoveEnabled = false
local fixedSafeCFrame = nil

-- สร้าง Tab หลักสำหรับแมพเบอร์เกอร์
local BurgerTab = Window:CreateTab("🍔 ระบบร้านเบอร์เกอร์ (ปลอดภัย)", 4483362458)

-- ฟังก์ชันตรวจสอบและดึงตัวกลับพิกัดปลอดภัย
local function CheckAndSnap(rootPart)
    if rootPart and fixedSafeCFrame then
        rootPart.CFrame = fixedSafeCFrame
        rootPart.Anchored = false
    end
end

-- ==========================================
-- 1. ออโต้รับออร์เดอร์ (OrderReceive)
-- ==========================================
BurgerTab:CreateToggle({
   Name = "📋 ออโต้รับออร์เดอร์ลูกค้า (OrderReceive)",
   CurrentValue = false,
   Flag = "AutoOrderToggle",
   Callback = function(Value)
      AutoOrderEnabled = Value
      if AutoOrderEnabled then
         local char = LocalPlayer.Character
         local rootPart = char and char:FindFirstChild("HumanoidRootPart")
         fixedSafeCFrame = rootPart and rootPart.CFrame or nil

         task.spawn(function()
            while AutoOrderEnabled do
               pcall(function()
                  if NetEvent1 then
                     NetEvent1:InvokeServer("108fedf8-5249-4d51-afbc-d9c839a85ced", "OrderReceive")
                  end
               end)
               
               local currentRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
               CheckAndSnap(currentRoot)
               
               task.wait(1)
            end
         end)
      else
         fixedSafeCFrame = nil
      end
   end,
})

-- ==========================================
-- 2. ออโต้จัดการจานสกปรก & เก็บจาน (เพิ่มโค้ดใหม่ครบทุกจุดโดยไม่มีการตัดออก)
-- ==========================================
BurgerTab:CreateToggle({
   Name = "🍽️ ออโต้เก็บและเคลียร์จานสกปรก (DirtyDish & Deposit - เพิ่มครบถ้วน)",
   CurrentValue = false,
   Flag = "AutoDishToggle",
   Callback = function(Value)
      AutoDishEnabled = Value
      if AutoDishEnabled then
         local char = LocalPlayer.Character
         local rootPart = char and char:FindFirstChild("HumanoidRootPart")
         fixedSafeCFrame = rootPart and rootPart.CFrame or nil

         task.spawn(function()
            while AutoDishEnabled do
               pcall(function()
                  if NetEvent1 then
                     -- โค้ดเดิมและโค้ดใหม่ทั้งหมดที่เพิ่มเข้ามาตามที่คุณสั่ง
                     NetEvent1:InvokeServer("250b0143-1b82-4074-9103-ad17a7ebfcf8", "DirtyDishTake")
                     task.wait(0.1)
                     NetEvent1:InvokeServer("a2bddabe-1dbc-4e00-8980-23ef42209562", "DirtyDishTake")
                     task.wait(0.1)
                     NetEvent1:InvokeServer("d6e8de77-2dd9-4bf1-8c6b-f08fac96664f", "DirtyDishTake")
                     task.wait(0.1)
                     NetEvent1:InvokeServer("619fc58d-6a50-484b-ae1c-c3c523561159", "DirtyDishTake")
                     task.wait(0.1)
                     NetEvent1:InvokeServer("619fc58d-6a50-484b-ae1c-c3c523561159", "DirtyDishTake")
                     task.wait(0.1)
                     
                     -- นำจานไปเก็บ/ล้าง
                     NetEvent1:InvokeServer("694353e5-4d20-4807-84c7-854dfc473b7d", "DishDeposit")
                  end
               end)
               
               local currentRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
               CheckAndSnap(currentRoot)
               
               task.wait(1.5)
            end
         end)
      else
         fixedSafeCFrame = nil
      end
   end,
})

-- ==========================================
-- 3. ออโต้เก็บเงินจากแคชเชียร์ (RegisterCollect)
-- ==========================================
BurgerTab:CreateToggle({
   Name = "💵 ออโต้เก็บเงินแคชเชียร์ (RegisterCollect)",
   CurrentValue = false,
   Flag = "AutoRegisterToggle",
   Callback = function(Value)
      AutoRegisterEnabled = Value
      if AutoRegisterEnabled then
         local char = LocalPlayer.Character
         local rootPart = char and char:FindFirstChild("HumanoidRootPart")
         fixedSafeCFrame = rootPart and rootPart.CFrame or nil

         task.spawn(function()
            while AutoRegisterEnabled do
               pcall(function()
                  if NetEvent1 then
                     NetEvent1:InvokeServer("4cca728d-b753-4c44-9d3b-9d054fb94250", "RegisterCollect")
                  end
               end)
               
               local currentRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
               CheckAndSnap(currentRoot)
               
               task.wait(2)
            end
         end)
      else
         fixedSafeCFrame = nil
      end
   end,
})

-- ==========================================
-- 4. ออโต้เปิดเตาทำเบอร์เกอร์ (StoveActivate)
-- ==========================================
BurgerTab:CreateToggle({
   Name = "🔥 ออโต้เปิดเตาย่างเนื้อ/เบอร์เกอร์ (StoveActivate)",
   CurrentValue = false,
   Flag = "AutoStoveToggle",
   Callback = function(Value)
      AutoStoveEnabled = Value
      if AutoStoveEnabled then
         local char = LocalPlayer.Character
         local rootPart = char and char:FindFirstChild("HumanoidRootPart")
         fixedSafeCFrame = rootPart and rootPart.CFrame or nil

         task.spawn(function()
            while AutoStoveEnabled do
               pcall(function()
                  if NetEvent1 then
                     NetEvent1:InvokeServer("d89498f2-b970-49e0-bfe3-9c3161b85007", "StoveActivate")
                     task.wait(0.1)
                     NetEvent1:InvokeServer("73de6aa8-3db2-4371-a38b-067755188fbc", "StoveActivate")
                  end
               end)
               
               local currentRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
               CheckAndSnap(currentRoot)
               
               task.wait(1.5)
            end
         end)
      else
         fixedSafeCFrame = nil
         local char = LocalPlayer.Character
         if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
            if char:FindFirstChild("HumanoidRootPart") then
               char.HumanoidRootPart.Anchored = false
            end
         end
      end
   end,
})
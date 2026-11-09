-- โหลด Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- สร้าง หน้าต่างหลัก (Window)
local Window = Rayfield:CreateWindow({
   Name = "Restaurant Tycoon 3 - Multi-Tycoon Hub (Fixed)",
   LoadingTitle = "กำลังโหลดระบบออโต้เก็บเงิน...",
   LoadingSubtitle = "โดย AI Assistant",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันหา Instance ที่อยู่ใน Nil
local function GetNil(Name, DebugId)
	for _, Object in getnilinstances() do
		if Object.Name == Name and Object:GetDebugId() == DebugId then
			return Object
		end
	end
end

-- ฟังก์ชันดึง Tycoon ของตัวเอง (ร้านหลัก)
local function GetMyTycoon()
    for _, tycoon in ipairs(workspace.Tycoons:GetChildren()) do
        if tycoon:FindFirstChild("Owner") and tycoon.Owner.Value == LocalPlayer then
            return tycoon
        end
    end
    return workspace.Tycoons:GetChildren()[2]
end

-- =========================================================================
-- TAB 1: ร้านที่ 1 (ของตัวเอง / ร้านหลัก)
-- =========================================================================
local MainTab = Window:CreateTab("🍳 ร้านที่ 1 (หลัก)", 4483362458)

local AutoCookEnabled = false
local AutoGrabEnabled = false
local AutoCollectEnabled = false
local fixedSafeCFrame = nil

MainTab:CreateButton({
   Name = "⚡ ทำอาหารเฉพาะเตาใกล้ตัว (ไม่ปลิว)",
   Callback = function()
      local myTycoon = GetMyTycoon()
      if not myTycoon or not myTycoon:FindFirstChild("Items") then return end

      local char = LocalPlayer.Character
      local rootPart = char and char:FindFirstChild("HumanoidRootPart")
      if not rootPart then return end

      local originalCFrame = rootPart.CFrame
      local CookEvent = ReplicatedStorage.Events.Cook.CookInputRequested
      
      for _, item in ipairs(myTycoon.Items.Surface:GetChildren()) do
         pcall(function()
            if item and item:IsA("Model") then
               local itemPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
               if itemPart then
                  local distance = (rootPart.Position - itemPart.Position).Magnitude
                  if distance <= 15 then
                     CookEvent:FireServer("Interact", item, "Kitchen")
                     task.wait(0.01)
                     CookEvent:FireServer("CompleteTask", item, "Kitchen", nil)
                     
                     CookEvent:FireServer("Interact", item, "Oven")
                     task.wait(0.01)
                     CookEvent:FireServer("CompleteTask", item, "Oven", false)
                  end
               end
            end
         end)
      end
      
      task.wait(0.05)
      if rootPart and originalCFrame then
         rootPart.CFrame = originalCFrame
         rootPart.Anchored = false
      end
      
      Rayfield:Notify({Title = "สำเร็จ", Content = "ทำอาหารเสร็จและดึงตัวกลับที่เดิมแล้ว!", Duration = 1.5})
   end,
})

MainTab:CreateToggle({
   Name = "🔄 ออโต้ทำอาหารเฉพาะเตาใกล้ตัว (Fixed Safe Cook)",
   CurrentValue = false,
   Flag = "AutoCookToggle1",
   Callback = function(Value)
      AutoCookEnabled = Value
      if AutoCookEnabled then
         local char = LocalPlayer.Character
         local rootPart = char and char:FindFirstChild("HumanoidRootPart")
         if rootPart then
            fixedSafeCFrame = rootPart.CFrame
         else
            fixedSafeCFrame = nil
         end

         task.spawn(function()
            local CookEvent = ReplicatedStorage.Events.Cook.CookInputRequested
            while AutoCookEnabled do
               local currentChars = LocalPlayer.Character
               local currentRoot = currentChars and currentChars:FindFirstChild("HumanoidRootPart")
               
               local myTycoon = GetMyTycoon()
               if myTycoon and myTycoon:FindFirstChild("Items") then
                  for _, item in ipairs(myTycoon.Items.Surface:GetChildren()) do
                     if not AutoCookEnabled then break end
                     pcall(function()
                        if item and item:IsA("Model") then
                           local itemPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                           if itemPart and currentRoot then
                              local distance = (currentRoot.Position - itemPart.Position).Magnitude
                              if distance <= 15 then
                                 CookEvent:FireServer("Interact", item, "Kitchen")
                                 task.wait(0.01)
                                 CookEvent:FireServer("CompleteTask", item, "Kitchen", nil)
                                 
                                 CookEvent:FireServer("Interact", item, "Oven")
                                 task.wait(0.01)
                                 CookEvent:FireServer("CompleteTask", item, "Oven", false)
                              end
                           end
                        end
                     end)
                  end
               end
               
               if currentRoot and fixedSafeCFrame then
                  currentRoot.CFrame = fixedSafeCFrame
                  currentRoot.Anchored = false
               end
               
               task.wait(1)
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

MainTab:CreateToggle({
   Name = "🤲 ออโต้หยิบอาหารและเสิร์ฟ",
   CurrentValue = false,
   Flag = "AutoGrabToggle1",
   Callback = function(Value)
      AutoGrabEnabled = Value
      if AutoGrabEnabled then
         task.spawn(function()
            local GrabEvent = ReplicatedStorage.Events.Restaurant.GrabFood
            local InteractEvent = ReplicatedStorage.Events.Restaurant.Interactions.Interacted
            
            while AutoGrabEnabled do
               local myTycoon = GetMyTycoon()
               if myTycoon and myTycoon:FindFirstChild("Items") then
                  for _, item in ipairs(myTycoon.Items.Surface:GetChildren()) do
                     if item:FindFirstChild("Trash") then
                        for _, food in ipairs(item.Trash:GetChildren()) do
                           pcall(function()
                              GrabEvent:InvokeServer(food)
                           end)
                        end
                     end
                  end
                  
                  pcall(function()
                     InteractEvent:FireServer(
                         myTycoon,
                         {
                             WorldPosition = Vector3.new(1149.050048828125, 0.26629018783569336, -227.231201171875),
                             GamepadKeyCode = Enum.KeyCode.ButtonY,
                             ActionText = "Serve",
                             ProximityPromptStyle = Enum.ProximityPromptStyle.Custom,
                             TemporaryPart = GetNil("Part", "0_394806"),
                             Range = 9,
                             Id = "86",
                             KeyboardKeyCode = Enum.KeyCode.F,
                             IsCustomerPrompt = true,
                             Key = "Serve",
                             Model = myTycoon.Items.Surface:GetChildren()[9],
                             InteractionType = "OrderCounter",
                             Prompt = GetNil("86", "0_394805"),
                             Part = GetNil("Part", "0_394806"),
                             HoldDuration = 0.25
                         }
                     )
                  end)
               end
               task.wait(0.5)
            end
         end)
      end
   end,
})

MainTab:CreateToggle({
   Name = "💵 ออโต้เก็บเงินจากโต๊ะลูกค้า",
   CurrentValue = false,
   Flag = "AutoCollectToggle1",
   Callback = function(Value)
      AutoCollectEnabled = Value
      if AutoCollectEnabled then
         task.spawn(function()
            local InteractEvent = ReplicatedStorage.Events.Restaurant.Interactions.Interacted
            local TaskCompletedEvent = ReplicatedStorage.Events.Restaurant.TaskCompleted
            
            while AutoCollectEnabled do
               local myTycoon = GetMyTycoon()
               if myTycoon and myTycoon:FindFirstChild("Items") then
                  for _, item in ipairs(myTycoon.Items.Surface:GetChildren()) do
                     if not AutoCollectEnabled then break end
                     pcall(function()
                        if item.Name:match("T") or item:FindFirstChild("Trash") or item:FindFirstChild("Bill") then
                           local pos = item.PrimaryPart and item.PrimaryPart.Position or Vector3.new(0,0,0)
                           
                           InteractEvent:FireServer(myTycoon, {
                               WorldPosition = pos,
                               GamepadKeyCode = Enum.KeyCode.ButtonX,
                               ActionText = "",
                               Id = "83",
                               Range = 10,
                               KeyboardKeyCode = Enum.KeyCode.E,
                               IsCustomerPrompt = true,
                               Key = "CollectBill",
                               Model = item,
                               InteractionType = "CollectBill",
                               HoldDuration = 0
                           })
                           
                           TaskCompletedEvent:FireServer({
                               Tycoon = myTycoon,
                               Name = "CollectBill",
                               FurnitureModel = item
                           })
                        end
                     end)
                  end
               end
               task.wait(1)
            end
         end)
      end
   end,
})


-- =========================================================================
-- TAB 2: ร้านที่ 2 (Tycoon 7)
-- =========================================================================
local Shop2Tab = Window:CreateTab("🏢 ร้านที่ 2", 4483362458)

local AutoCook2Enabled = false
local AutoCollect2Enabled = false
local fixedSafeCFrame2 = nil

-- 1. ปุ่มทำอาหารร้านที่ 2
Shop2Tab:CreateButton({
   Name = "⚡ ทำอาหารร้านที่ 2 (พร้อมล็อกพิกัดกันปลิว)",
   Callback = function()
      local tycoon7 = workspace.Tycoons:GetChildren()[7]
      if not tycoon7 then
         Rayfield:Notify({Title = "แจ้งเตือน", Content = "ไม่พบ Tycoons ลำดับที่ 7", Duration = 2})
         return
      end

      local char = LocalPlayer.Character
      local rootPart = char and char:FindFirstChild("HumanoidRootPart")
      if not rootPart then return end

      local originalCFrame = rootPart.CFrame
      local InteractEvent = ReplicatedStorage.Events.Restaurant.Interactions.Interacted
      local CookEvent = ReplicatedStorage.Events.Cook.CookInputRequested

      pcall(function()
         InteractEvent:FireServer(tycoon7, {
             WorldPosition = Vector3.new(940.143798828125, -1.2337098121643066, -376.231201171875),
             GamepadKeyCode = Enum.KeyCode.ButtonX,
             HoldDuration = 0.25,
             ProximityPromptStyle = Enum.ProximityPromptStyle.Custom,
             TemporaryPart = GetNil("Part", "0_405236"),
             Range = 9,
             KeyboardKeyCode = Enum.KeyCode.E,
             InteractionType = "OrderCounter",
             Key = "Cook",
             Model = tycoon7.Items.Surface.K16,
             Id = "0",
             Prompt = GetNil("0", "0_405235"),
             Part = GetNil("Part", "0_405236"),
             ActionText = "Cook"
         })

         InteractEvent:FireServer(tycoon7, {
             WorldPosition = Vector3.new(940.143798828125, -1.2337098121643066, -372.231201171875),
             GamepadKeyCode = Enum.KeyCode.ButtonX,
             HoldDuration = 0.25,
             ProximityPromptStyle = Enum.ProximityPromptStyle.Custom,
             TemporaryPart = GetNil("Part", "0_405283"),
             Range = 9,
             KeyboardKeyCode = Enum.KeyCode.E,
             InteractionType = "OrderCounter",
             Key = "Cook",
             Model = tycoon7.Items.Surface:GetChildren()[3],
             Id = "1",
             Prompt = GetNil("1", "0_405282"),
             Part = GetNil("Part", "0_405283"),
             ActionText = "Cook"
         })

         CookEvent:FireServer("Interact", tycoon7.Items.Surface.K3, "Kitchen")
         CookEvent:FireServer("CompleteTask", tycoon7.Items.Surface.K3, "Kitchen", nil)

         CookEvent:FireServer("Interact", tycoon7.Items.Surface.K28, "Oven")
         CookEvent:FireServer("CompleteTask", tycoon7.Items.Surface.K28, "Oven", false)

         CookEvent:FireServer("Interact", tycoon7.Items.Surface:GetChildren()[5], "Oven")
         CookEvent:FireServer("CompleteTask", tycoon7.Items.Surface:GetChildren()[5], "Oven", false)
      end)

      task.wait(0.05)
      if rootPart and originalCFrame then
         rootPart.CFrame = originalCFrame
         rootPart.Anchored = false
      end

      Rayfield:Notify({Title = "สำเร็จ", Content = "สั่งทำอาหารร้านที่ 2 เรียบร้อย!", Duration = 1.5})
   end,
})

-- 2. สวิตช์ออโต้ทำอาหารร้านที่ 2
Shop2Tab:CreateToggle({
   Name = "🔄 ออโต้ทำอาหารร้านที่ 2 (Safe Loop)",
   CurrentValue = false,
   Flag = "AutoCook2Toggle",
   Callback = function(Value)
      AutoCook2Enabled = Value
      if AutoCook2Enabled then
         local char = LocalPlayer.Character
         local rootPart = char and char:FindFirstChild("HumanoidRootPart")
         if rootPart then
            fixedSafeCFrame2 = rootPart.CFrame
         else
            fixedSafeCFrame2 = nil
         end

         task.spawn(function()
            local InteractEvent = ReplicatedStorage.Events.Restaurant.Interactions.Interacted
            local CookEvent = ReplicatedStorage.Events.Cook.CookInputRequested

            while AutoCook2Enabled do
               local tycoon7 = workspace.Tycoons:GetChildren()[7]
               if tycoon7 then
                  pcall(function()
                     InteractEvent:FireServer(tycoon7, {
                         WorldPosition = Vector3.new(940.143798828125, -1.2337098121643066, -376.231201171875),
                         GamepadKeyCode = Enum.KeyCode.ButtonX,
                         HoldDuration = 0.25,
                         ProximityPromptStyle = Enum.ProximityPromptStyle.Custom,
                         TemporaryPart = GetNil("Part", "0_405236"),
                         Range = 9,
                         KeyboardKeyCode = Enum.KeyCode.E,
                         InteractionType = "OrderCounter",
                         Key = "Cook",
                         Model = tycoon7.Items.Surface.K16,
                         Id = "0",
                         Prompt = GetNil("0", "0_405235"),
                         Part = GetNil("Part", "0_405236"),
                         ActionText = "Cook"
                     })

                     InteractEvent:FireServer(tycoon7, {
                         WorldPosition = Vector3.new(940.143798828125, -1.2337098121643066, -372.231201171875),
                         GamepadKeyCode = Enum.KeyCode.ButtonX,
                         HoldDuration = 0.25,
                         ProximityPromptStyle = Enum.ProximityPromptStyle.Custom,
                         TemporaryPart = GetNil("Part", "0_405283"),
                         Range = 9,
                         KeyboardKeyCode = Enum.KeyCode.E,
                         InteractionType = "OrderCounter",
                         Key = "Cook",
                         Model = tycoon7.Items.Surface:GetChildren()[3],
                         Id = "1",
                         Prompt = GetNil("1", "0_405282"),
                         Part = GetNil("Part", "0_405283"),
                         ActionText = "Cook"
                     })

                     CookEvent:FireServer("Interact", tycoon7.Items.Surface.K3, "Kitchen")
                     CookEvent:FireServer("CompleteTask", tycoon7.Items.Surface.K3, "Kitchen", nil)

                     CookEvent:FireServer("Interact", tycoon7.Items.Surface.K28, "Oven")
                     CookEvent:FireServer("CompleteTask", tycoon7.Items.Surface.K28, "Oven", false)

                     CookEvent:FireServer("Interact", tycoon7.Items.Surface:GetChildren()[5], "Oven")
                     CookEvent:FireServer("CompleteTask", tycoon7.Items.Surface:GetChildren()[5], "Oven", false)
                  end)
               end

               local currentChars = LocalPlayer.Character
               local currentRoot = currentChars and currentChars:FindFirstChild("HumanoidRootPart")
               if currentRoot and fixedSafeCFrame2 then
                  currentRoot.CFrame = fixedSafeCFrame2
                  currentRoot.Anchored = false
               end

               task.wait(1.5)
            end
         end)
      else
         fixedSafeCFrame2 = nil
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

-- 3. สวิตช์ออโต้เก็บเงินร้านที่ 2 (รวมโค้ดใหม่ของคุณเข้าไปแล้ว)
Shop2Tab:CreateToggle({
   Name = "💵 ออโต้เก็บเงินร้านที่ 2 (Collect Bill)",
   CurrentValue = false,
   Flag = "AutoCollect2Toggle",
   Callback = function(Value)
      AutoCollect2Enabled = Value
      if AutoCollect2Enabled then
         task.spawn(function()
            local InteractEvent = ReplicatedStorage.Events.Restaurant.Interactions.Interacted
            local TaskCompletedEvent = ReplicatedStorage.Events.Restaurant.TaskCompleted

            while AutoCollect2Enabled do
               local tycoon7 = workspace.Tycoons:GetChildren()[7]
               if tycoon7 and tycoon7:FindFirstChild("Items") then
                  pcall(function()
                     -- 1. ยิงรีโมต Interact เก็บเงินตามโค้ดใหม่ที่คุณส่งมา
                     InteractEvent:FireServer(
                         tycoon7,
                         {
                             WorldPosition = Vector3.new(960.1484375, 0.91826272010803223, -392.20278930664062),
                             GamepadKeyCode = Enum.KeyCode.ButtonX,
                             ActionText = "",
                             Id = "29",
                             TemporaryPart = GetNil("Part", "0_454848"),
                             Range = 7.2000000000000002,
                             KeyboardKeyCode = Enum.KeyCode.E,
                             IsCustomerPrompt = true,
                             Key = "CollectBill",
                             Model = tycoon7.Items.Surface.T1,
                             InteractionType = "CollectBill",
                             Prompt = GetNil("29", "0_454847"),
                             HoldDuration = 0,
                             Part = GetNil("Part", "0_454848")
                         }
                     )

                     -- 2. สั่งจบงานเก็บเงินจากโต๊ะชิ้นที่ 8 เดิม
                     TaskCompletedEvent:FireServer({
                         Tycoon = tycoon7,
                         Name = "CollectBill",
                         FurnitureModel = tycoon7.Items.Surface:GetChildren()[8]
                     })
                  end)
               end
               task.wait(1)
            end
         end)
      end
   end,
})
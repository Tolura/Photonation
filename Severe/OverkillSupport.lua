--!optimize 2

local Workspace = game:GetService("Workspace")

local Tracked, List = {}, 0

local Ignored = {
    Camera = true,
    Debris = true,
    Debug = true,
    Objects = true,
    VFX = true,
    Terrain = true,
}

local Aimparts = {"LowerTorso", "LeftLowerLeg", "LeftUpperLeg", "RightLowerLeg", "RightUpperLeg", "LeftLowerArm", "LeftUpperArm", "RightLowerArm", "RightUpperArm", "LeftHand", "RightHand"}
local FullParts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}

local Client
local Loaded = false
local Scan = 0

RunService.PreLocal:Connect(function()
    local Children = Workspace:GetChildren()
    if type(Children) ~= "table" then return end

    -- Stability fix
    if os.clock() >= Scan then
    Scan = os.clock() + 0.25

    local Highlights, Players = 0, 0
    for _, Container in Children do
        if not Ignored[Container.Name] then
            for _, Object in Container:GetDescendants() do
                if Object.Name == "EnemyHighlight" then
                    Highlights += 1
                elseif Object.Name == "Health" and Object:IsA("Script") then
                    local Character = Object.Parent
                    if Character and Character:IsA("Model") and not string.find(Character.Name, "Dummy_") and Character:FindFirstChild("HitboxHead") then
                        Players += 1
                    end
                end
            end
        end
    end

    local Checked = Highlights > 0 and Highlights < Players

    for _, Container in Children do
        if not Ignored[Container.Name] then
            for _, Health in Container:GetDescendants() do
                if Health.Name == "Health" and Health:IsA("Script") then
                    local Character = Health.Parent
                    if Character and Character:IsA("Model") then
                        local Head = Character:FindFirstChild("Head")
                        local HRP = Character:FindFirstChild("HumanoidRootPart")
                        local Humanoid = Character:FindFirstChild("Humanoid")
                        local Hitbox = Character:FindFirstChild("HitboxHead") and Character:FindFirstChild("HitboxTorso")
                        if Head and HRP and not Hitbox then
                            Client = Character
                        end
                        local Dummy = string.find(Character.Name, "Dummy_") ~= nil
                        local Enemy = Dummy or not Checked or Character:FindFirstChild("EnemyHighlight") ~= nil
                        if Enemy and Hitbox and Head and HRP and not Tracked[Character] then
                            local Torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("LowerTorso") or HRP
                            local Parts = {
                                Head = Head,
                                HRP = HRP,
                                UpperTorso = Character:FindFirstChild("UpperTorso"),
                                LowerTorso = Character:FindFirstChild("LowerTorso"),
                                LeftUpperArm = Character:FindFirstChild("LeftUpperArm"),
                                LeftLowerArm = Character:FindFirstChild("LeftLowerArm"),
                                LeftHand = Character:FindFirstChild("LeftHand"),
                                RightUpperArm = Character:FindFirstChild("RightUpperArm"),
                                RightLowerArm = Character:FindFirstChild("RightLowerArm"),
                                RightHand = Character:FindFirstChild("RightHand"),
                                LeftUpperLeg = Character:FindFirstChild("LeftUpperLeg"),
                                LeftLowerLeg = Character:FindFirstChild("LeftLowerLeg"),
                                LeftFoot = Character:FindFirstChild("LeftFoot"),
                                RightUpperLeg = Character:FindFirstChild("RightUpperLeg"),
                                RightLowerLeg = Character:FindFirstChild("RightLowerLeg"),
                                RightFoot = Character:FindFirstChild("RightFoot"),
                            }
                            local Aim, Full = {}, {}
                            for _, Name in Aimparts do
                                if Parts[Name] then Aim[#Aim + 1] = {name = Name, part = Parts[Name]} end
                            end
                            for _, Name in FullParts do
                                if Parts[Name] then Full[#Full + 1] = {name = Name, part = Parts[Name]} end
                            end
                            List += 1
                            local Model = tostring(List)

                            add_model_data({
                                Username = Dummy and "Dummy" .. tostring(List) or "Enemy" .. tostring(List),
                                Displayname = Dummy and "Dummy" ..tostring(List) or "Enemy" .. tostring(List),
                                Userid = math.random(2, 10000),
                                Character = Character,
                                PrimaryPart = HRP,
                                Humanoid = Humanoid,
                                Head = Head,
                                Torso = Torso,
                                UpperTorso = Torso,
                                LowerTorso = Parts.LowerTorso or Torso,
                                LeftArm = Parts.LeftUpperArm or Torso,
                                RightArm = Parts.RightUpperArm or Torso,
                                LeftLeg = Parts.LeftUpperLeg or Torso,
                                RightLeg = Parts.RightUpperLeg or Torso,
                                LeftUpperArm = Parts.LeftUpperArm or Torso,
                                LeftLowerArm = Parts.LeftLowerArm or Torso,
                                LeftHand = Parts.LeftHand or Torso,
                                RightUpperArm = Parts.RightUpperArm or Torso,
                                RightLowerArm = Parts.RightLowerArm or Torso,
                                RightHand = Parts.RightHand or Torso,
                                LeftUpperLeg = Parts.LeftUpperLeg or Torso,
                                LeftLowerLeg = Parts.LeftLowerLeg or Torso,
                                LeftFoot = Parts.LeftFoot or Torso,
                                RightUpperLeg = Parts.RightUpperLeg or Torso,
                                RightLowerLeg = Parts.RightLowerLeg or Torso,
                                RightFoot = Parts.RightFoot or Torso,
                                BodyHeightScale = 1,
                                RigType = 1,
                                Whitelisted = false,
                                Archenemies = false,
                                Aimbot_Part = Head,
                                Aimbot_TP_Part = HRP,
                                Triggerbot_Part = Head,
                                Health = 100,
                                MaxHealth = 100,
                                Teamname = "Enemies",
                                Toolname = "Weapon",
                                body_parts_data = Aim,
                                full_body_data = Full,
                            }, Model)
                                Tracked[Character] = Model
                        end
                    end
                end
            end
        end
    end

    for Character, Model in Tracked do
        local Destroyed = not Character.Parent
        local Teammate = Checked
            and not string.find(Character.Name, "Dummy_")
            and not Character:FindFirstChild("EnemyHighlight")
        if Destroyed or Teammate then
            remove_model_data(Model)
            Tracked[Character] = nil
        end
    end
    end

    if Client and not Loaded then
        local Head = Client:FindFirstChild("Head")
        local HRP = Client:FindFirstChild("HumanoidRootPart")
        local Humanoid = Client:FindFirstChild("Humanoid")
        if Humanoid then
            local Torso = Client:FindFirstChild("UpperTorso") or Client:FindFirstChild("LowerTorso") or HRP
            override_local_data({
                LocalPlayer = Client,
                Character = Client,
                Username = "Local",
                Displayname = "Local",
                Userid = 1,
                Humanoid = Humanoid,
                Health = 100,
                MaxHealth = 100,
                RigType = 1,
                Teamname = "Friendly",
                Toolname = "Weapon",
                Head = Head,
                RootPart = HRP,
                LowerTorso = Torso,
                UpperTorso = Torso,
                LeftArm = Client:FindFirstChild("LeftUpperArm") or Torso,
                RightArm = Client:FindFirstChild("RightUpperArm") or Torso,
                LeftLeg = Client:FindFirstChild("LeftUpperLeg") or Torso,
                RightLeg = Client:FindFirstChild("RightUpperLeg") or Torso,
                LeftFoot = Client:FindFirstChild("LeftUpperLeg") or Torso,
            })
            Loaded = true
        end
    end
end)

queue_on_teleport("loadstring(game:HttpGet("https://raw.githubusercontent.com/Tolura/Photonation/refs/heads/main/Severe/OverkillSupport.lua"))()")

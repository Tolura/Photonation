local Highlights, Players = 0, 0

local Ignored = {
    Camera = true,
    Debris = true,
    Debug = true,
    Objects = true,
    VFX = true,
    Terrain = true,
}

hook.add("init_custom_entity", "overkill", function()
    force_custom_players()
    add_custom_hitparts({"Head", "ClosestPart", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"})

    local Workspace = game:get_service("Workspace")
    if not Workspace:isvalid() then return end
    local Camera = Workspace:find_first_child_class("Camera")
    if not (Camera and Camera:isvalid()) then return end
    local CamPos = Camera.camera_position

    local Found = {}
    Highlights, Players = 0, 0

    for _, Container in pairs(Workspace:get_children()) do
        if Container:isvalid() and not Ignored[Container.name] then
            for _, Object in pairs(Container:get_descendants()) do
                if Object:isvalid() and Object.name == "Health" and Object.class_name == "Script" then
                    local Character = Object:get_parent()
                    if Character and Character:isvalid() and Character.class_name == "Model" then
                        local Humanoid = Character:find_first_child_class("Humanoid")
                        if Humanoid and Humanoid:isvalid() then
                            Found[#Found + 1] = {Character, Humanoid}
                            if Character:find_first_child("EnemyHighlight") then
                                Highlights = Highlights + 1
                            end
                            if not string.find(Character.name, "Dummy_") and Character:find_first_child("HitboxHead") then
                                Players = Players + 1
                            end
                        end
                    end
                end
            end
        end
    end

    for _, Player in pairs(Found) do
        local Character, Humanoid = Player[1], Player[2]
        if not Character:isvalid() then return end
        local Object = Character:get_parent()
        local HRP = Character:find_first_child("HumanoidRootPart")
        local Head = Character:find_first_child("Head")
        local HitboxHead = Character:find_first_child("HitboxHead")
        local HitboxTorso = Character:find_first_child("HitboxTorso")
        local Hitbox = HitboxHead and HitboxHead:isvalid() and HitboxTorso and HitboxTorso:isvalid()
        local Dummy = string.find(Character.name, "Dummy_") ~= nil
        local Near = Dummy or (HRP and HRP:isvalid() and (HRP.position:subtract(CamPos)):length() < 5000)
        local Torso = Character:find_first_child("UpperTorso") or Character:find_first_child("LowerTorso")
        local Dead = Torso and Torso:isvalid() and Torso.transparency >= 1
        local Highlight = Character:find_first_child("EnemyHighlight")
        local Team = Dummy or not (Highlights > 0 and Highlights < Players) or (Highlight and Highlight:isvalid())

        if (Dummy or Hitbox) and not Dead and Team and HRP and HRP:isvalid() and Head and Head:isvalid() and Near and not (Object and Object:isvalid() and Object.name == "Armory") then
            add_entity_ex(Dummy and "Dummy" or "Enemy", Character, Humanoid, Head, true, vector3(1.8, 4.5, 1.8), vector3(1.8, 0.7, 1.8), {
                {"Head", Head},
                {"HumanoidRootPart", HRP},
                {"UpperTorso", Character:find_first_child("UpperTorso")},
                {"LowerTorso", Character:find_first_child("LowerTorso")},
                {"LeftUpperArm", Character:find_first_child("LeftUpperArm")},
                {"LeftLowerArm", Character:find_first_child("LeftLowerArm")},
                {"LeftHand", Character:find_first_child("LeftHand")},
                {"RightUpperArm", Character:find_first_child("RightUpperArm")},
                {"RightLowerArm", Character:find_first_child("RightLowerArm")},
                {"RightHand", Character:find_first_child("RightHand")},
                {"LeftUpperLeg", Character:find_first_child("LeftUpperLeg")},
                {"LeftLowerLeg", Character:find_first_child("LeftLowerLeg")},
                {"LeftFoot", Character:find_first_child("LeftFoot")},
                {"RightUpperLeg", Character:find_first_child("RightUpperLeg")},
                {"RightLowerLeg", Character:find_first_child("RightLowerLeg")},
                {"RightFoot", Character:find_first_child("RightFoot")}
            })
        end
    end
end)

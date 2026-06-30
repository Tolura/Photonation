local Highlights, Players = 0, 0
local Ignore

hook.add("init_custom_entity", "overkill", function()
    force_custom_players()
    add_custom_hitparts({"Head", "ClosestPart", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"})

    local Workspace = game:get_service("Workspace")
    if not Workspace:isvalid() then return end
    local Camera = Workspace:find_first_child_class("Camera")
    if not (Camera and Camera:isvalid()) then return end
    local CamPos = Camera.camera_position

    local Ignored = {
        Camera = true,
        Debris = true,
        Debug = true,
        Objects = true,
        VFX = true,
        Terrain = true,
    }

    Highlights, Players = 0, 0
    for _, Container in pairs(Workspace:get_children()) do
        if Container:isvalid() and not Ignored[Container.name] then
            for _, Object in pairs(Container:get_descendants()) do
                if Object:isvalid() then
                    if Object.name == "EnemyHighlight" then
                        Highlights = Highlights + 1
                    elseif Object.name == "Health" and Object.class_name == "Script" then
                        local Char = Object:get_parent()
                        if Char and Char:isvalid() and Char.class_name == "Model" and not string.find(Char.name, "Dummy_") then
                            Players = Players + 1
                        end
                    end
                end
            end
        end
    end

    for _, Container in pairs(Workspace:get_children()) do
        if Container:isvalid() and not Ignored[Container.name] then
            for _, Health in pairs(Container:get_descendants()) do
                if Health:isvalid() and Health.name == "Health" and Health.class_name == "Script" then
                    local Character = Health:get_parent()
                    if Character and Character:isvalid() and Character.class_name == "Model" then
                        local Object = Character:get_parent()
                        local Child = Character:find_first_child_class("Humanoid")
                        local HRP = Character:find_first_child("HumanoidRootPart")
                        local Head = Character:find_first_child("Head")
                        local HitboxHead = Character:find_first_child("HitboxHead")
                        local HitboxTorso = Character:find_first_child("HitboxTorso")
                        local Hitbox = HitboxHead and HitboxHead:isvalid() and HitboxTorso and HitboxTorso:isvalid()
                        local Dummy = string.find(Character.name, "Dummy_") ~= nil
                        local Near = Dummy or (HRP and HRP:isvalid() and (HRP.position:subtract(CamPos)):length() < 5000)

                        if (Dummy or Hitbox) and not Ignore(Character) and Child and Child:isvalid() and HRP and HRP:isvalid() and Head and Head:isvalid() and Near
                            and not (Object and Object:isvalid() and Object.name == "Armory") then
                            add_entity_ex(Dummy and "Dummy" or "Enemy", Character, Child, Head, true, vector3(1.8, 4.5, 1.8), vector3(1.8, 0.7, 1.8), {
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
                end
            end
        end
    end
end)

function Ignore(Character)
    if not (Character and Character:isvalid()) then return false end
    if string.find(Character.name, "Dummy_") then return false end
    if not (Highlights > 0 and Highlights < Players) then return false end
    local Highlight = Character:find_first_child("EnemyHighlight")
    return not (Highlight and Highlight:isvalid())
end

hook.add("esp_ignore", "overkill_esp", function(Character)
    return Ignore(Character)
end)

hook.add("aimbot_ignore", "overkill_aim", function(Character)
    return Ignore(Character)
end)

hook.add("triggerbot_ignore", "overkill_tb", function(Character)
    return Ignore(Character)
end)

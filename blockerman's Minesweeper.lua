local Players = game:get_service("Players")
local Workspace = game:get_service("Workspace")
local LocalPlayer = Players.local_player

local BLoaded = true
local cache = {
    Prediction = false,
    AutoFlag = true,
    Dirty = true,
    Parts = nil,
    Locked = nil,
    LockedPos = nil,
    PrevClick = 0,
    PrevSolve = 0,
    PrevRescan = 0,
    PrevUpdate = 0,
    Tiles = {},
    Grid = {},
    Neighbors = {},
    Render = {},
    DrawList = {},
    Check = {},
    Pending = {},
    Clicked = {},
    GuiList = {},
}

local function Init()
    cache.Parts = nil
    LocalPlayer = Players.local_player
    Workspace = game:get_service("Workspace")
    if not LocalPlayer or not LocalPlayer:isvalid() or not Workspace or not Workspace:isvalid() then return end
end

local Menu = gui.create("bLockerman's Mineshitter", false)
Menu:set_pos(100, 100)
Menu:set_size(300, 320)

local Predict = Menu:add_checkbox("Enable Prediction", false)
Predict:change_callback(function()
    cache.Prediction = Predict:get_value()
    if not cache.Prediction then
        cache.Locked = nil
        for i = 1, #cache.Render do cache.Render[i] = nil end
        for i = 1, #cache.Check do cache.Check[i] = nil end
        for k in pairs(cache.Pending) do cache.Pending[k] = nil end
        for k in pairs(cache.Clicked) do cache.Clicked[k] = nil end
        for k in pairs(cache.GuiList) do cache.GuiList[k] = nil end
    end
end)

local AutoPlaceOn = Menu:add_checkbox("Auto Place Flag", true)
local AutoKey = Menu:add_keybind("AutoKey", 0x45)
AutoPlaceOn:change_callback(function()
    cache.AutoFlag = AutoPlaceOn:get_value()
end)

local PlaceDelay = Menu:add_slider("Auto Place Delay (ms)", 50, 800, 240)
local RenderDist = Menu:add_slider("Render Radius", 15, 150, 35)
local UpdateInterval = Menu:add_slider("Update Interval (ms)", 50, 800, 150)

local function Reset()
    for i = 1, #cache.Tiles do cache.Tiles[i] = nil end
    for k in pairs(cache.Grid) do cache.Grid[k] = nil end
    for k in pairs(cache.Neighbors) do cache.Neighbors[k] = nil end
    for i = 1, #cache.Render do cache.Render[i] = nil end
    for i = 1, #cache.Check do cache.Check[i] = nil end
    for k in pairs(cache.Clicked) do cache.Clicked[k] = nil end
    for k in pairs(cache.Pending) do cache.Pending[k] = nil end
    for k in pairs(cache.GuiList) do cache.GuiList[k] = nil end
    cache.Locked = nil
    cache.Dirty = true
    cache.Parts = nil
end

local function Flagged(Part, Key)
    if not Part or not Part:isvalid() then return false end
    local Children = Part:get_children()
    if Children then
        for i = 1, #Children do
            local Child = Children[i]
            if Child and Child:isvalid() then
                local Class = Child.class_name
                if Class == "Model" or Class == "MeshPart" then return true end
            end
        end
    end
    if Key and cache.Clicked[Key] and get_tickcount() - cache.Clicked[Key] < 3000 then return true end
    return false
end

local function Classify(Part)
    if not Part or not Part:isvalid() then return "empty", 0 end
    local Gui = Part:find_first_child("NumberGui")
    local Label = Gui and Gui:isvalid() and Gui:find_first_child("TextLabel")
    if Label and Label:isvalid() then
        local Text = Label:get_label_text()
        if not Text or Text == "" or Text == " " then return "empty", 0 end
        local Num = tonumber(Text)
        if Num then return "number", Num end
        if Text:lower():find("mine") then return "mine", nil end
        return "empty", 0
    end
    return "unknown", nil
end

local Offsets = {{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}}
local function Neighbors(gx, gz)
    local Key = gx .. "|" .. gz
    local Closest = cache.Neighbors[Key]
    if Closest then return Closest end
    Closest = {}
    for i = 1, #Offsets do
        local Offset = Offsets[i]
        local Neighbor = cache.Grid[(gx + Offset[1]) .. "|" .. (gz + Offset[2])]
        if Neighbor then table.insert(Closest, Neighbor) end
    end
    cache.Neighbors[Key] = Closest
    return Closest
end

local function Solve(Nearby)
    local Changed = false
    local Limits = {}
    for i = 1, #Nearby do
        local Tile = Nearby[i]
        if Tile.type == "number" then
            local Closest = Neighbors(Tile.gx, Tile.gz)
            local Mines, Unknowns = 0, {}
            for j = 1, #Closest do
                local Neighbor = Closest[j]
                if Neighbor.type == "mine" or (Neighbor.pred == "mine" and Neighbor.conf >= 0.95) then Mines = Mines + 1
                elseif Neighbor.type == "unknown" and Neighbor.pred ~= "safe" then table.insert(Unknowns, Neighbor) end
            end
            local Need = Tile.num - Mines
            local Count = #Unknowns
            if Count > 0 then
                if Need == 0 then
                    for j = 1, Count do
                        local unknown = Unknowns[j]
                        if unknown.pred ~= "safe" then unknown.pred = "safe"; unknown.conf = 1.0; Changed = true end
                    end
                elseif Need == Count then
                    for j = 1, Count do
                        local unknown = Unknowns[j]
                        if unknown.pred ~= "mine" then unknown.pred = "mine"; unknown.conf = 1.0; Changed = true end
                    end
                else
                    table.insert(Limits, { Tile = Tile, Unknowns = Unknowns, Need = Need })
                end
            end
        end
    end
    if Changed then return true end
    for i = 1, #Limits do
        for j = i + 1, #Limits do
            local C1, C2 = Limits[i], Limits[j]
            local Shared, Only1, Only2 = {}, {}, {}
            local Set1, Set2 = {}, {}
            for k = 1, #C1.Unknowns do Set1[C1.Unknowns[k]] = true end
            for k = 1, #C2.Unknowns do Set2[C2.Unknowns[k]] = true end
            for k = 1, #C1.Unknowns do
                local Unknown = C1.Unknowns[k]
                if Set2[Unknown] then table.insert(Shared, Unknown) else table.insert(Only1, Unknown) end
            end
            for k = 1, #C2.Unknowns do
                local Unknown = C2.Unknowns[k]
                if not Set1[Unknown] then table.insert(Only2, Unknown) end
            end
            if #Shared > 0 then
                if #Only1 == 0 and #Only2 > 0 then
                    local Diff = C2.Need - C1.Need
                    if Diff == 0 then
                        for k = 1, #Only2 do
                            local Unknown = Only2[k]
                            if Unknown.pred ~= "safe" then Unknown.pred = "safe"; Unknown.conf = 1.0; Changed = true end
                        end
                    elseif Diff == #Only2 then
                        for k = 1, #Only2 do
                            local Unknown = Only2[k]
                            if Unknown.pred ~= "mine" then Unknown.pred = "mine"; Unknown.conf = 1.0; Changed = true end
                        end
                    end
                elseif #Only2 == 0 and #Only1 > 0 then
                    local Diff = C1.Need - C2.Need
                    if Diff == 0 then
                        for k = 1, #Only1 do
                            local Unknown = Only1[k]
                            if Unknown.pred ~= "safe" then Unknown.pred = "safe"; Unknown.conf = 1.0; Changed = true end
                        end
                    elseif Diff == #Only1 then
                        for k = 1, #Only1 do
                            local Unknown = Only1[k]
                            if Unknown.pred ~= "mine" then Unknown.pred = "mine"; Unknown.conf = 1.0; Changed = true end
                        end
                    end
                end
            end
            if Changed then return true end
        end
    end
    return Changed
end

local function Probable(Nearby)
    for i = 1, #Nearby do
        local Tile = Nearby[i]
        if Tile.type == "unknown" and not Tile.pred then
            Tile.prob, Tile.cc, Tile.front = 0, 0, false
            local Closest = Neighbors(Tile.gx, Tile.gz)
            for j = 1, #Closest do
                local Neighbor = Closest[j]
                if Neighbor.type == "number" or Neighbor.type == "mine" or Neighbor.pred then Tile.front = true break end
            end
        end
    end
    for i = 1, #Nearby do
        local Tile = Nearby[i]
        if Tile.type == "number" then
            local Closest = Neighbors(Tile.gx, Tile.gz)
            local Mines, Unknowns = 0, {}
            for j = 1, #Closest do
                local Neighbor = Closest[j]
                if Neighbor.type == "mine" or (Neighbor.pred == "mine" and Neighbor.conf >= 0.95) then Mines = Mines + 1
                elseif Neighbor.type == "unknown" and Neighbor.pred ~= "safe" then table.insert(Unknowns, Neighbor) end
            end
            local Need = Tile.num - Mines
            if #Unknowns > 0 and Need >= 0 then
                local Prob = Need / #Unknowns
                for j = 1, #Unknowns do
                    local Unknown = Unknowns[j]
                    if not Unknown.pred then Unknown.prob = (Unknown.prob or 0) + Prob; Unknown.cc = (Unknown.cc or 0) + 1 end
                end
            end
        end
    end
    for i = 1, #Nearby do
        local Tile = Nearby[i]
        if Tile.type == "unknown" and not Tile.pred then
            local Count = Tile.cc or 0
            if Count > 0 then
                local Conf = math.min((Tile.prob or 0) / Count, 1.0)
                if Conf == 0 then
                    Tile.pred, Tile.conf = "safe", 1.0
                else
                    Tile.conf = Conf
                end
            else
                Tile.conf = 0
            end
        end
    end
end

hook.add("render", "mineshitter", function()
    if not BLoaded or not cache.Prediction then return end
    local KeyDown = AutoKey:get_state()
    if cache.AutoFlag and KeyDown and not input.key_down(0x02) then
        if cache.LockedPos then
            local ScreenPos = world_to_screen(cache.LockedPos.pos)
            if ScreenPos and not ScreenPos:out_of_screen() then
                render.add_circle(ScreenPos, 20, color(1, 0, 0, 1))
                render.add_circle(ScreenPos, 15, color(1, 0, 0, 1))
            end
        end
    end
    -- cachhchcahwhwadhwd #B1.4
    local DrawList = cache.DrawList
    for i = 1, #DrawList do
        local Item = DrawList[i]
        local ScreenPos = world_to_screen(Item.pos)
        if ScreenPos and not ScreenPos:out_of_screen() then
            render.add_text(ScreenPos, Item.text, Item.col, 16, true)
        end
    end
end)

spawn(function()
    while BLoaded do
        local Now = get_tickcount()
        -- PLEASEEEEE #B1.3
        local Interval = UpdateInterval:get_value()
        if Now - cache.PrevUpdate < Interval then
            local Duration = math.floor(Interval - (Now - cache.PrevUpdate))
            if Duration > 0 then
                wait(Duration)
            end
            goto next
        end
        cache.PrevUpdate = Now

        if not cache.Prediction then wait(500) goto next end
        if not LocalPlayer or not LocalPlayer:isvalid() or not Workspace or not Workspace:isvalid() then
            Reset()
            Init()
            wait(250)
            goto next
        end
        if not cache.Parts or not cache.Parts:isvalid() then
            Reset()
            Init()
            if not Workspace or not Workspace:isvalid() then wait(500) goto next end
            local Flags = Workspace:find_first_child("Flag")
            if Flags and Flags:isvalid() then cache.Parts = Flags:find_first_child("Parts") end
            if not cache.Parts or not cache.Parts:isvalid() then wait(500) goto next end
        end
        if cache.Parts and cache.Parts:isvalid() then
            local Children = cache.Parts:get_children()
            if not Children then wait(50) goto next end
            local Current, BoardExists, BoardChanged = {}, false, false
            for i = 1, #Children do
                local Part = Children[i]
                if Part and Part:isvalid() then
                    BoardExists = true
                    local PartPos = Part.position
                    local Identity = Part.identity
                    local gx, gz = math.floor(PartPos.x / 5 + 0.5), math.floor(PartPos.z / 5 + 0.5)
                    local Key = gx .. "|" .. gz
                    Current[Key] = true
                    local Tile = cache.Grid[Key]
                    if Tile then
                        Tile.part = Part
                        if Tile.identity ~= Identity then
                            local Type, Value = Classify(Part)
                            Tile.identity, Tile.type, Tile.num, Tile.pred, Tile.conf, Tile.prob, Tile.cc, Tile.front = Identity, Type, Value, false, 0, 0, 0, false
                            cache.Neighbors[Key], cache.Clicked[Key], cache.Pending[Key] = nil, nil, nil
                            BoardChanged = true
                        end
                    else
                        local Type, Value = Classify(Part)
                        local NewTile = {part = Part, gx = gx, gz = gz, key = Key, identity = Identity, type = Type, num = Value, pred = false, conf = 0}
                        table.insert(cache.Tiles, NewTile)
                        cache.Grid[Key] = NewTile
                        cache.Neighbors[Key], BoardChanged = nil, true
                    end
                end
            end
            if not BoardExists then Reset() wait(1000) goto next end
            for i = #cache.Tiles, 1, -1 do
                local Tile = cache.Tiles[i]
                if not Tile.part or not Tile.part:isvalid() or not Current[Tile.key] then
                    cache.Grid[Tile.key], cache.Neighbors[Tile.key], cache.Dirty = nil, nil, true
                    table.remove(cache.Tiles, i)
                end
            end
            if BoardChanged then
                for i = 1, #cache.Check do cache.Check[i] = nil end
                for k in pairs(cache.Pending) do cache.Pending[k] = nil end
                cache.Locked, cache.Dirty = nil, true
            end
            local Character = LocalPlayer and LocalPlayer:isvalid() and LocalPlayer.character
            local HRP = Character and Character:isvalid() and Character:find_first_child("HumanoidRootPart")
            local MyPos = HRP and HRP:isvalid() and HRP.position or vector3(0, 70, 0)
            local Radius, Nearby = RenderDist:get_value(), {}
            local Refresh = cache.Dirty or BoardChanged or (Now - cache.PrevSolve >= 100)
            local Tiles, Dirty = cache.Tiles, cache.Dirty
            for i = 1, #Tiles do
                local Tile = Tiles[i]
                local Part = Tile.part
                if Part and Part:isvalid() then
                    local PartPos = Part.position
                    local dx, dz = PartPos.x - MyPos.x, PartPos.z - MyPos.z
                    if dx*dx + dz*dz <= Radius*Radius then
                        table.insert(Nearby, Tile)
                        if Refresh then
                            local Type, Value = Classify(Part)
                            if Type ~= Tile.type or Value ~= Tile.num then
                                Tile.type, Tile.num, Tile.pred, Tile.conf, Dirty = Type, Value, false, 0, true
                                cache.Neighbors[Tile.key] = nil
                            end
                        end
                    end
                end
            end
            cache.Dirty = Dirty
            if Refresh then
                for _ = 1, 15 do if not Solve(Nearby) then break end end
                Probable(Nearby)
                cache.PrevSolve, cache.Dirty = Now, false
            end
            local KeyDown = AutoKey:get_state()
            if cache.AutoFlag and KeyDown and not input.key_down(0x02) then
                local Delay = PlaceDelay:get_value()
                local CalcDelay = math.max(Delay + 150, 300)
                for i = #cache.Check, 1, -1 do
                    local Entry = cache.Check[i]
                    if Now - Entry.time >= CalcDelay then
                        local Tile = cache.Grid[Entry.key]
                        if Tile and Tile.part and Tile.part:isvalid() and (Flagged(Tile.part, Entry.key) or Tile.type == "mine") then
                            if cache.Locked and cache.Locked.key == Entry.key then cache.Locked = nil end
                        end
                        cache.Pending[Entry.key] = nil
                        table.remove(cache.Check, i)
                    end
                end
                for Key, Time in pairs(cache.Clicked) do if Now - Time > 3000 then cache.Clicked[Key] = nil end end
                if cache.Locked then
                    local Tile = cache.Grid[cache.Locked.key]
                    if not Tile or not Tile.part or not Tile.part:isvalid() or Flagged(Tile.part, cache.Locked.key) or Tile.type ~= "unknown" or cache.Pending[cache.Locked.key] then cache.Locked = nil end
                end
                if not cache.Locked and HRP and HRP:isvalid() then
                    local BestDist = 15
                    for i = 1, #Nearby do
                        local Tile = Nearby[i]
                        local Part = Tile.part
                        if Part and Part:isvalid() then
                            local PartPos = Part.position
                            if ((Tile.pred == "mine" and Tile.conf >= 0.95) or Tile.type == "mine") and not Flagged(Part, Tile.key) and not cache.Pending[Tile.key] then
                                local dx, dz = PartPos.x - MyPos.x, PartPos.z - MyPos.z
                                local Dist = math.sqrt(dx*dx + dz*dz)
                                if Dist < BestDist then BestDist, cache.Locked = Dist, {key = Tile.key, position = PartPos} end
                            end
                        end
                    end
                end
                if cache.Locked then
                    local Pos = cache.Locked.position
                    if Pos then
                        local ScreenPos = world_to_screen(Pos)
                        if ScreenPos and not ScreenPos:out_of_screen() then
                            local MousePos = input.get_mouse_position()
                            input.set_mouse_position(MousePos:lerp(ScreenPos, 0.8))
                            local NewPos = input.get_mouse_position()
                            local DistOnTile = math.sqrt((NewPos.x - ScreenPos.x)^2 + (NewPos.y - ScreenPos.y)^2)
                            if DistOnTile <= 45 and Now - cache.PrevClick >= Delay then
                                local Tile = cache.Grid[cache.Locked.key]
                                if Tile and Tile.part and Tile.part:isvalid() and not Flagged(Tile.part, Tile.key) then
                                    cache.Clicked[Tile.key], cache.PrevClick, cache.Pending[Tile.key] = Now, Now, true
                                    cache.Locked = nil
                                    wait(10)
                                    input.simulate_mouse_click(MOUSE1)
                                    table.insert(cache.Check, {key = Tile.key, time = cache.PrevClick})
                                end
                            end
                        end
                    end
                end
            else cache.Locked = nil end
            local ShouldRescan = (Now - cache.PrevRescan >= 500) or cache.Dirty or BoardChanged
            if ShouldRescan then
                local NewRenderList = {}
                local NewDrawList = {}
                local NewLockedPos = nil
                for i = 1, #Nearby do
                    local Tile = Nearby[i]
                    local Part = Tile.part
                    if Part and Part:isvalid() then
                        local PartPos = Part.position
                        local RenderItem = nil
                        local DrawItem = nil
                        if Tile.type == "mine" or (Tile.pred == "mine" and Tile.conf >= 0.95) then
                            RenderItem = {part = Part, text = "U", flagged = Flagged(Part, Tile.key)}
                            local Col = RenderItem.flagged and color(0.5, 0.5, 0.5, 1) or color(1, 0, 0, 1)
                            DrawItem = {pos = PartPos, text = "U", col = Col}
                        elseif Tile.pred == "safe" and Tile.conf >= 0.99 and Tile.type == "unknown" then
                            RenderItem = {part = Part, text = "S", col = color(0, 1, 0, 1)}
                            DrawItem = {pos = PartPos, text = "S", col = RenderItem.col}
                        elseif Tile.type == "unknown" and not Tile.pred and (Tile.front or Tile.conf > 0) then
                            local Percentage = math.floor(Tile.conf * 100)
                            if Percentage > 0 then
                                RenderItem = {part = Part, text = Percentage .. "%", col = color(0, 1, 1, 1)}
                                DrawItem = {pos = PartPos, text = RenderItem.text, col = RenderItem.col}
                            end
                        end
                        if RenderItem then table.insert(NewRenderList, RenderItem) end
                        if DrawItem then table.insert(NewDrawList, DrawItem) end
                    end
                end
                if cache.Locked then
                    local LockedKey = cache.Locked.key
                    local Tile = cache.Grid[LockedKey]
                    if Tile then
                        local TilePart = Tile.part
                        if TilePart and TilePart:isvalid() then
                            local PartPos = TilePart.position
                            NewLockedPos = {pos = PartPos}
                        end
                    end
                end
                cache.Render, cache.DrawList, cache.LockedPos, cache.PrevRescan = NewRenderList, NewDrawList, NewLockedPos, Now
            end
        end
        wait(25)
        ::next::
    end
end)

Menu:add_button("Reload", function()
    Reset()
    Init()
    if Workspace and Workspace:isvalid() then
        local Flags = Workspace:find_first_child("Flag")
        if Flags and Flags:isvalid() then cache.Parts = Flags:find_first_child("Parts") end
    end
    log.notification("Mineshitter Fixed", "info")
end)

Menu:add_button("Unload", function()
    BLoaded = false
    hook.remove("render", "mineshitter")
    gui.remove("bLockerman's Mineshitter")
end)

Init()
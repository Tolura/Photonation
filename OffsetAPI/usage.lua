--[[
API Usage Examples:
1) Print Specific Offset
-- Example: Print the value of a specific offset
print(HealthOffset)


2) Print All Offsets
-- Example: Loop through all global variables ending with "Offset"
for k, v in pairs(_G) do
    if k:match("Offset$") then
        print(k .. " = " .. tostring(v))
    end
end
]]

http.get("https://raw.githubusercontent.com/Tolura/Photonation/refs/heads/main/OffsetAPI/offset.lua", function(body, status)
    if status == 200 and body then
        local chunk = load(body)
        if chunk then chunk() end
    end
end)

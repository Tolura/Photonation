-- Original Script by insectgang

-- Change if Theo also stops updating
local Provider = "https://imtheo.lol/Offsets/Offsets.hpp"

hook.add("init", "offset_create", function()
    http.get(Provider, function(body, status)
        if status ~= 200 or not body then return end

        for Offset, Hex in body:gmatch("inline%s+constexpr%s+uintptr_t%s+([%w_]+)%s*=%s*(0x[%x]+)") do
            _G[Offset .. "Offset"] = tonumber(Hex)
        end

        hook.remove("init", "offset_create")
    end)
end)

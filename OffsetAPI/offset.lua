-- Original Script by insectgang

-- Change if Theo also stops updating
local Provider = "https://imtheo.lol/Offsets/Offsets.hpp"

hook.add("init", "offset_create", function()
    http.get(Provider, function(body, status)
        if status ~= 200 or not body then return end

        local Namespace = ""
        
        for line in body:gmatch("[^\r\n]+") do
            local InNamespace = line:match("namespace%s+([%w_]+)%s*{")
            if InNamespace then
                Namespace = InNamespace .. "_"
            elseif line:match("^%s*}") and Namespace ~= "" then
                Namespace = ""
            end
            
            local Offset, Hex = line:match("inline%s+constexpr%s+uintptr_t%s+([%w_]+)%s*=%s*(0x[%x]+)")
            if Offset then
                _G[Namespace .. Offset .. "Offset"] = tonumber(Hex)
            end
        end

        hook.remove("init", "offset_create")
    end)
end)

local GET = http.get

local LOAD_STABLE_BUILD = true
local STABLE = "https://raw.githubusercontent.com/DCons0001/Scripts/refs/heads/main/DigStable.lua"
local UNSTABLE = "https://raw.githubusercontent.com/DCons0001/Scripts/refs/heads/main/DigUnstable.lua"

GET(LOAD_STABLE_BUILD and STABLE or UNSTABLE, function(Body, Status)
    if Status == 200 then
        local Chunk = load(Body)
        if Chunk then
            local Success, ErrorMessage = pcall(Chunk)
            if not Success then
                log.add("Error executing script: " .. tostring(ErrorMessage), color(1, 0, 0, 1))
            end
        end
    end
end)
  


local HTTP_GET = http.get
local LOADER_URL = "https://raw.githubusercontent.com/glizzymuncher57/Scripts/refs/heads/main/Loader/Loader.lua"

HTTP_GET(LOADER_URL, function(Body, Status)
    if Status == 200 then
        local Loader = load(Body)
        if Loader then
            Loader()
        end
    end
end)

local Get = http.get
local Games = {}

local function logFunc(message)
    log.add(message, color(1, 0, 0, 1))
end

local function GetScript()
    local gameId = get_placeid()
    local url = Games[gameId]
    
    if not url then
        logFunc("No script found for this game.")
        return nil
    end

    Get(url, function(Body, Status)
        if Status == 200 then
            local Chunk = load(Body)
            if Chunk then
                local S, E = pcall(Chunk)
                if not S then
                    logFunc("Error loading script: "..tostring(E))
                end
            end
        else
            logFunc("Failed to fetch script (Status: "..tostring(Status)..")")
        end
    end)
end

local function GetGames(callback)
    local URL = "https://raw.githubusercontent.com/glizzymuncher57/Scripts/refs/heads/main/Gamelist.json"

    Get(URL, function(Body, Status)
        if Status == 200 then
            local Gamelist = JSON_to_table(Body)

            if Gamelist then
                Games = Gamelist
                callback(true)
            else
                logFunc("Failed to parse game list.")
                callback(false)
            end
        else
            logFunc("Failed to fetch game list: " .. tostring(Status))
            callback(false)
        end
    end)
end

GetGames(function(success)
    if success then
        logFunc("Game list loaded successfully.")
        GetScript()
    end
end)

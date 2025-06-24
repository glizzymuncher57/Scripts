local Get = http.get

local Games = {
	[126884695634066] = "https://raw.githubusercontent.com/glizzymuncher57/Scripts/refs/heads/main/Grow%20A%20Garden/TeleportScript.lua", -- Grow A Garden
	[126244816328678] = "https://raw.githubusercontent.com/glizzymuncher57/Scripts/refs/heads/main/Dig/Stable.lua", -- Dig
	[16541340872] = "https://raw.githubusercontent.com/glizzymuncher57/Scripts/refs/heads/main/Clark%20County/Stable.lua", -- Clark County
}

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
					logFunc("Error loading script: " .. tostring(E))
				end
			end
		end
	end)
end

GetScript()

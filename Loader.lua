local Games = {}

--// Cached Funcs
local Get = http.get
local JSON_to_table = JSON_to_table -- just for intellisense
local gui = gui

--// Constants
local MENU_NAME = "Game Scripts"

local function LogFunc(message)
	log.notification(message, "Info")
end

local function GetScript()
	local gameId = get_placeid()
	local url = Games[gameId]

	if not url then
		LogFunc("No script found for this game.")
		return false
	end

	Get(url, function(Body, Status)
		if Status == 200 then
			local Chunk = load(Body)
			if Chunk then
				local S, E = pcall(Chunk)
				if not S then
					LogFunc("Error loading script: " .. tostring(E))
				end

				return S
			end
		else
			LogFunc("Failed to fetch script (Status: " .. tostring(Status) .. ")")
            return false
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
				LogFunc("Failed to parse game list.")
				callback(false)
			end
		else
			LogFunc("Failed to fetch game list: " .. tostring(Status))
			callback(false)
		end
	end)
end

local function Init()
	local LoaderSuccess = false

	GetGames(function(success)
		if success then
			LoaderSuccess = true
		end
	end)

	if not LoaderSuccess then
		LogFunc("Failed to load game scripts. Please try again later.")
		return
	end

	local Menu = gui.create(MENU_NAME, false)
	Menu:set_pos(100, 100)
	Menu:set_size(300, 170)

	local AutoDetectButton = Menu:add_button("Button1", "Auto Detect Game", function()
		local Success = GetScript("Games")
		if Success then
			gui.remove(MENU_NAME)
		end
	end)

	local RemoveButton = Menu:add_button("Button2", "Close Loader", function()
		gui.remove(MENU_NAME)
	end)
end

Init()

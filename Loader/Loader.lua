local http_get = http.get
local Games = {}
local MiscComboBoxStrings = {}
local Misc = {}

local ID = "UniversalScriptLoader"
local STUPID_HACKY_SOLUTION_FOR_BUTTON_SIZE = "                            %s                            "
local MM_OPEN = false

local function Get(url, callback)
	http_get(url, function(body, status)
		if status ~= 200 then
			return callback(nil, "HTTP error: " .. tostring(status))
		end
		callback(body, nil)
	end)
end

local function logFunc(message)
	log.add(message, color(1, 0, 0, 1))
end

local function logNotification(message)
	log.notification(message, "Info")
end

local function GetGames(callback)
	local URL = "https://raw.githubusercontent.com/glizzymuncher57/Scripts/refs/heads/main/Loader/Games.json"

	Get(URL, function(body, err)
		if err then
			logFunc("Failed to fetch game list: " .. err)
			return callback(false)
		end

		local success, result = pcall(JSON_to_table, body)
		if not success or not result then
			logFunc("Failed to parse JSON: " .. tostring(result or "Unknown error"))
			return callback(false)
		end

		Games = {}
		Misc = result["Misc"] or {}

		for id, script in pairs(result) do
			if id ~= "Misc" then
				Games[id] = script
			end
		end

		-- Build misc scripts combo box
		MiscComboBoxStrings = {}
		for scriptName in pairs(Misc) do
			table.insert(MiscComboBoxStrings, scriptName)
		end

		callback(true)
	end)
end

local function LoadScript(url, onSuccess)
	Get(url, function(body, err)
		if err then
			logFunc("Failed to fetch script: " .. err)
			return
		end

		local chunk, loadErr = load(body)
		if not chunk then
			logFunc("Failed to load script: " .. tostring(loadErr))
			return
		end

		local success, execErr = pcall(chunk)
		if success then
			if onSuccess then
				onSuccess()
			end
			logNotification("Script loaded successfully")
		else
			logFunc("Error executing script: " .. tostring(execErr))
		end
	end)
end

local function CloseMenu()
	gui.remove(ID)
	gui.remove(ID .. " - Auto Detection")
	MM_OPEN = false
end

local function CreateAutoDetectionMenu()
	if MM_OPEN then
		logNotification("Please close the auto detection menu first.")
		return
	end

	local placeId = get_placeid()
	local gameId = get_gameid()
	local gameScripts = Games[tostring(gameId)] or Games[tostring(placeId)]

	if not gameScripts then
		logNotification("No scripts found for this game.")
		return
	end

	MM_OPEN = true
	local newMenu = gui.create(ID .. " - Auto Detection", false)
	newMenu:set_pos(230, 100)
	newMenu:set_size(300, 300)

	local scriptList = {}
	for scriptName in pairs(gameScripts) do
		table.insert(scriptList, scriptName)
	end

	local combo = newMenu:add_combo("Select Script", scriptList, 0)
	combo:change_callback(function()
		local selectedScript = combo:get_text()
		local scriptUrl = gameScripts[selectedScript]

		if not scriptUrl or scriptUrl == "" then
			logNotification("No script URL found for the selected script.")
			return
		end

		logNotification("Loading script: " .. selectedScript)
		LoadScript(scriptUrl, CloseMenu)
	end)

	newMenu:add_button(STUPID_HACKY_SOLUTION_FOR_BUTTON_SIZE:format("Cancel"), CloseMenu)
end

local function CreateMainMenu()
	local menu = gui.create(ID, false)
	menu:set_size(400, 230)
	menu:set_pos(100, 100)

	menu:add_label("IF YOU GET AN INVALID INSTANCE ERROR, RESTART PHOTON.")
	menu:add_button(STUPID_HACKY_SOLUTION_FOR_BUTTON_SIZE:format("Load Script"), CreateAutoDetectionMenu)
	menu:add_button(STUPID_HACKY_SOLUTION_FOR_BUTTON_SIZE:format("Cancel"), CloseMenu)

	local combo = menu:add_combo("Select Misc Scripts", MiscComboBoxStrings, 0)
	combo:change_callback(function()
		local selectedScript = combo:get_text()
		local scriptUrl = Misc[selectedScript]

		if scriptUrl then
			logNotification(selectedScript)
			logNotification("Loading misc script:")
			LoadScript(scriptUrl, CloseMenu)
		end
	end)
end

local function Initialise()
	local success, err = pcall(function()
		GetGames(function(success)
			if success then
				CreateMainMenu()
			end
		end)
	end)

	if not success then
		logFunc("Error during initialization: " .. tostring(err))
	end
end

Initialise()

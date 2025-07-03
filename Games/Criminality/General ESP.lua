-- Credits to @stallyyyyy (1380683403103571970)
local Workspace = game:get_service("Workspace")
local GameMap = Workspace:find_first_child("Map")
local GameMoney = GameMap and GameMap:find_first_child("BredMakurz")
local GameAtm = GameMap and GameMap:find_first_child("ATMz")
local GameDealers = GameMap and GameMap:find_first_child("Shopz")
local VendingMachines = GameMap and GameMap:find_first_child("VendingMachines")
local SpawnedTools = Workspace:find_first_child("Filter")
	and Workspace:find_first_child("Filter"):find_first_child("SpawnedTools")
local players = game:get_service("Players")
local localplayer = players.local_player

_G.esp_menu_open = false
_G.esp_menu = nil
_G.esp_enabled = true
_G.rainbow_enabled = false
_G.box_enabled = true
_G.name_enabled = true
_G.show_type_controls = false
_G.current_distance = 50
_G.rainbow_speed = 10
_G.rainbow_time = 0
_G.esp_types = {
	Register = { enabled = true, color = color(0.5, 0.5, 0.5, 1) },
	SmallSafe = { enabled = true, color = color(0.8, 0.6, 0, 1) },
	MediumSafe = { enabled = true, color = color(1, 0.84, 0, 1) },
	ATM = { enabled = true, color = color(0, 0.5, 1, 1) },
	Dealer = { enabled = true, color = color(0.2, 0.8, 0.2, 1) },
	ArmoryDealer = { enabled = true, color = color(0.8, 0.2, 0.2, 1) },
	VendingMachine = { enabled = true, color = color(0.4, 0.4, 0.8, 1) },
	Shiv = { enabled = true, color = color(0.7, 0.7, 0.7, 1) },
	BayonetMesh = { enabled = true, color = color(0.6, 0.6, 0.6, 1) },
	WeaponHandle = { enabled = true, color = color(0.8, 0.8, 0.8, 1) },
}

local function close_menu()
	if _G.esp_menu_open then
		gui.remove("Criminality ESP")
		_G.esp_menu_open = false
		_G.esp_menu = nil
	end
end

local function get_rainbow_color()
	local t = _G.rainbow_time * _G.rainbow_speed
	return color(math.sin(t) * 0.5 + 0.5, math.sin(t + 2.0944) * 0.5 + 0.5, math.sin(t + 4.1888) * 0.5 + 0.5, 1)
end

local function create_esp_menu()
	if _G.esp_menu_open then
		return
	end
	_G.esp_menu = gui.create("Criminality ESP", true)
	_G.esp_menu:set_pos(100, 50)
	_G.esp_menu:set_size(300, _G.show_type_controls and 1000 or 500)

	local checkboxes = {
		{ id = "esp_enabled", label = "ESP Enabled", value = _G.esp_enabled },
		{ id = "rainbow_enabled", label = "Rainbow ESP", value = _G.rainbow_enabled },
		{ id = "box_enabled", label = "Box ESP", value = _G.box_enabled },
		{ id = "name_enabled", label = "Name ESP", value = _G.name_enabled },
		{ id = "show_type_controls", label = "Show Type Controls", value = _G.show_type_controls },
	}

	for _, c in ipairs(checkboxes) do
		local cb = _G.esp_menu:add_checkbox(c.id, c.label, c.value)
		cb:change_callback(function()
			_G[c.id] = cb:get_value()
			if c.id == "show_type_controls" then
				close_menu()
				create_esp_menu()
			end
		end)
	end

	if _G.show_type_controls then
		local type_checkboxes = {
			{ id = "register_enabled", label = "Register ESP", name = "Register" },
			{ id = "smallsafe_enabled", label = "SmallSafe ESP", name = "SmallSafe" },
			{ id = "mediumsafe_enabled", label = "MediumSafe ESP", name = "MediumSafe" },
			{ id = "atm_enabled", label = "ATM ESP", name = "ATM" },
			{ id = "dealer_enabled", label = "Dealer ESP", name = "Dealer" },
			{ id = "armorydealer_enabled", label = "ArmoryDealer ESP", name = "ArmoryDealer" },
			{ id = "vendingmachine_enabled", label = "VendingMachine ESP", name = "VendingMachine" },
			{ id = "shiv_enabled", label = "Shiv ESP", name = "Shiv" },
			{ id = "bayonetmesh_enabled", label = "BayonetMesh ESP", name = "BayonetMesh" },
			{ id = "weaponhandle_enabled", label = "WeaponHandle ESP", name = "WeaponHandle" },
		}

		for _, tc in ipairs(type_checkboxes) do
			local cb = _G.esp_menu:add_checkbox(tc.id, tc.label, _G.esp_types[tc.name].enabled)
			cb:change_callback(function()
				_G.esp_types[tc.name].enabled = cb:get_value()
				close_menu()
				create_esp_menu()
			end)

			if _G.esp_types[tc.name].enabled then
				local color_picker =
					_G.esp_menu:add_color("color_" .. tc.name, tc.name .. " Color", _G.esp_types[tc.name].color)
				color_picker:change_callback(function()
					_G.esp_types[tc.name].color = color_picker:get_color()
				end)
			end
		end
	end

	local rainbow_speed_slider = _G.esp_menu:add_slider("rainbow_speed", "Rainbow Speed", 10, 100, _G.rainbow_speed)
	rainbow_speed_slider:change_callback(function()
		_G.rainbow_speed = rainbow_speed_slider:get_value()
	end)

	local distance_slider = _G.esp_menu:add_slider("esp_distance", "Max Distance", 10, 1000, _G.current_distance)
	distance_slider:change_callback(function()
		_G.current_distance = distance_slider:get_value()
	end)

	_G.esp_menu_open = true
end

local function render_objects()
	if not localplayer.character:isvalid() then
		return
	end
	local local_root = localplayer.character:find_first_child("HumanoidRootPart")
	if not local_root:isvalid() then
		return
	end
	local player_pos = local_root.position

	local objects = {}
	if GameMoney and GameMoney:isvalid() then
		for _, item in ipairs(GameMoney:get_children()) do
			if item:isvalid() then
				local name = item.name
				if
					(name:find("SmallSafe") and _G.esp_types.SmallSafe.enabled)
					or (name:find("MediumSafe") and _G.esp_types.MediumSafe.enabled)
					or (name:find("Register") and _G.esp_types.Register.enabled)
				then
					objects[#objects + 1] = item
				end
			end
		end
	end
	if GameAtm and GameAtm:isvalid() and _G.esp_types.ATM.enabled then
		for _, atm in ipairs(GameAtm:get_children()) do
			if atm:isvalid() and atm.name == "ATM" then
				objects[#objects + 1] = atm
			end
		end
	end
	if GameDealers and GameDealers:isvalid() then
		for _, dealer in ipairs(GameDealers:get_children()) do
			if
				dealer:isvalid()
				and (
					(dealer.name == "Dealer" and _G.esp_types.Dealer.enabled)
					or (dealer.name == "ArmoryDealer" and _G.esp_types.ArmoryDealer.enabled)
				)
			then
				objects[#objects + 1] = dealer
			end
		end
	end
	if VendingMachines and VendingMachines:isvalid() and _G.esp_types.VendingMachine.enabled then
		for _, vm in ipairs(VendingMachines:get_children()) do
			if vm:isvalid() and vm.name == "VendingMachine" then
				objects[#objects + 1] = vm
			end
		end
	end
	if SpawnedTools and SpawnedTools:isvalid() then
		for _, tool in ipairs(SpawnedTools:get_children()) do
			if tool:isvalid() then
				local has_shiv = tool:find_first_child("Shiv") ~= nil
				local has_bayonet = tool:find_first_child("BayonetMesh") ~= nil
				for _, part in ipairs(tool:get_children()) do
					if part:isvalid() and (part.class_name == "MeshPart" or part.class_name == "Part") then
						if
							(part.name == "Shiv" and _G.esp_types.Shiv.enabled)
							or (part.name == "BayonetMesh" and _G.esp_types.BayonetMesh.enabled)
							or (
								part.name == "WeaponHandle"
								and _G.esp_types.WeaponHandle.enabled
								and not (has_shiv or has_bayonet)
							)
						then
							objects[#objects + 1] = { item = tool, main_part = part, name = part.name }
						end
					end
				end
			end
		end
	end

	for _, obj in ipairs(objects) do
		local item = obj.item or obj
		local main_part = obj.main_part or item:find_first_child("MainPart")
		if not main_part or not main_part:isvalid() then
			goto continue
		end
		local pos = main_part.position
		if (player_pos - pos):length() > _G.current_distance then
			goto continue
		end
		local screen_pos = world_to_screen(pos)
		if not in_screen(screen_pos) then
			goto continue
		end

		local name = obj.name or item.name
		local display_name = name:match("SmallSafe")
			or name:match("MediumSafe")
			or name:match("Register")
			or (name == "ATM" and "ATM")
			or (name == "VendingMachine" and "VendingMachine")
			or name
		local default_color = _G.esp_types[display_name] and _G.esp_types[display_name].color
			or _G.esp_types[name].color
		local text_color = _G.rainbow_enabled and get_rainbow_color() or default_color

		local t, b = world_to_screen(pos + vector3(0, 1.5, 0)), world_to_screen(pos - vector3(0, 1.5, 0))
		local lx, rx = world_to_screen(pos - vector3(1.5, 0, 0)), world_to_screen(pos + vector3(1.5, 0, 0))
		if not (in_screen(t) and in_screen(b)) then
			goto continue
		end

		if _G.box_enabled then
			local h, w = math.abs(t.y - b.y), math.abs(rx.x - lx.x)
			local c = vector2((lx.x + rx.x) * 0.5, (t.y + b.y) * 0.5)
			render.add_rect(
				vector2(c.x - w * 0.5 - 0.75, c.y - h * 0.5 - 0.75),
				vector2(c.x + w * 0.5 + 0.75, c.y + h * 0.5 + 0.75),
				color(0, 0, 0, 1)
			)
			render.add_rect(vector2(c.x - w * 0.5, c.y - h * 0.5), vector2(c.x + w * 0.5, c.y + h * 0.5), text_color)
		end

		if _G.name_enabled then
			local name_size = render.get_text_size(display_name)
			local n_pos = vector2(screen_pos.x - name_size.x * 0.5, t.y - 20)
			for _, o in ipairs({ vector2(-1, 0), vector2(1, 0), vector2(0, -1), vector2(0, 1) }) do
				render.add_text(n_pos + o, display_name, color(0, 0, 0, 1))
			end
			render.add_text(n_pos, display_name, text_color)
		end

		::continue::
	end
end

hook.add("render", "Criminality ESP", function()
	_G.rainbow_time = _G.rainbow_time + 0.001
	if menu_active() then
		create_esp_menu()
	elseif _G.esp_menu_open then
		close_menu()
	end
	if not _G.esp_enabled then
		return
	end
	local success, error = pcall(render_objects)
	if not success then
		log.add("Error in ESP rendering: " .. error, color(1, 0, 0, 1))
	end
end)

log.add("Criminality ESP Menu activated", color(0, 1, 0, 1))

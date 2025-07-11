-- credits to @xaviersobased__ (1331307501924388949)

local settings = {
	["radius"] = 2,
	["height"] = 1.5,
	["head_offset"] = 0.5,
	["rainbow"] = true,
	["chunk"] = 5,
}

local localplayer = game:get_service("Players").local_player
local hue = 0
local FILE_NAME = "china_hat_settings.json"

local hsv_to_rgb = function(h, s, v)
	local c = v * s
	local x = c * (1 - math.abs((h / 60) % 2 - 1))
	local m = v - c
	local r, g, b = 0, 0, 0

	if h >= 0 and h < 60 then
		r, g, b = c, x, 0
	elseif h >= 60 and h < 120 then
		r, g, b = x, c, 0
	elseif h >= 120 and h < 180 then
		r, g, b = 0, c, x
	elseif h >= 180 and h < 240 then
		r, g, b = 0, x, c
	elseif h >= 240 and h < 300 then
		r, g, b = x, 0, c
	elseif h >= 300 and h < 360 then
		r, g, b = c, 0, x
	end

	return r + m, g + m, b + m
end

local render_shit = function()
	local local_character = localplayer.character

	if not local_character:isvalid() then
		return
	end

	local head = local_character:find_first_child("Head")

	if not head:isvalid() then
		return
	end

	local origin = local_character:isvalid() and head.position or vector3(0, 0, 0)

	local screen_pos = world_to_screen(origin:add(vector3(0, settings["height"] + settings["head_offset"], 0)))
	if screen_pos:out_of_screen() then
		return
	end

	local hawk = nil
	local last_edge = nil

	if settings["rainbow"] then
		hue = (hue + render.deltatime() * 50) % 360
		local r, g, b = hsv_to_rgb(hue, 1, 1)
		hawk = color(r, g, b, 1)
	else
		hawk = color(1, 1, 1, 1)
	end

	for angle_deg = 0, 360, settings["chunk"] do
		local angle_rad = math.rad(angle_deg)
		local x_offset = math.cos(angle_rad) * settings["radius"]
		local z_offset = math.sin(angle_rad) * settings["radius"]

		local offset_vector = vector3(x_offset, settings["head_offset"], z_offset)
		local edge_position = origin:add(offset_vector)

		local screen_pos_edge = world_to_screen(edge_position)

		if not screen_pos_edge:out_of_screen() then
			render.add_line(screen_pos, screen_pos_edge, hawk)

			if last_edge then
				render.add_line(last_edge, screen_pos_edge, hawk)
			end

			last_edge = screen_pos_edge
		end
	end
end

local savesettings = function()
	local ConfigString = table_to_JSON(settings)
	if not ConfigString then
		return
	end

	if file.exists(FILE_NAME) then
		file.overwrite(FILE_NAME, ConfigString, "binary")
	else
		file.write(FILE_NAME, ConfigString, "binary")
	end
end

local loadsettings = function()
	if not file.exists(FILE_NAME) then
		return false
	end

	local ReadSuccess, JsonResult = pcall(file.read, FILE_NAME, "binary")
	if not ReadSuccess then
		LogFunc("Failed to read configuration file: " .. JsonResult)
		return false
	end

	local ParseSuccess, TableResult = pcall(JSON_to_table, JsonResult)
	if not ParseSuccess then
		LogFunc("Failed to parse configuration JSON: " .. TableResult)
		return false
	end

	settings = {
		radius = TableResult.radius or settings["radius"],
		height = TableResult.height or settings["height"],
		head_offset = TableResult.head_offset or settings["head_offset"],
		rainbow = TableResult.rainbow or settings["rainbow"],
		chunk = TableResult.chunk or settings["chunk"],
	}

	return true
end

local function init()
	loadsettings()

	hook.add("render", "china_hat", render_shit)

	local menu = gui.create("China Hat Settings - IF YOU DIE THIS WILL CRASH!", false)
	menu:set_pos(100, 100)
	menu:set_size(340, 340)

	local warning_button = menu:add_button("chinabutton2", "WARNING: THIS WILL CRASH IF YOU DIE", function()
		log.notification("Lol Retard Why Press this", "Info")
	end)

	local button = menu:add_button("chinabutton1", "Remove China Hat", function()
		hook.remove("render", "china_hat")
		gui.remove("China Hat Settings - IF YOU DIE THIS WILL CRASH!")
	end)

	local radius_slider = menu:add_slider("chinaradius", "Radius", 1, 15, settings["radius"])
	radius_slider:change_callback(function()
		settings["radius"] = radius_slider:get_value()
		savesettings()
	end)

	local height_slider = menu:add_slider("chinaheight", "Height", 0.5, 5, settings["height"])
	height_slider:change_callback(function()
		settings["height"] = height_slider:get_value()
		savesettings()
	end)

	local head_offset_slider = menu:add_slider("chinaheadoffset", "Head Offset", 0, 2, settings["head_offset"])
	head_offset_slider:change_callback(function()
		settings["head_offset"] = head_offset_slider:get_value()
		savesettings()
	end)

	local rainbow_checkbox = menu:add_checkbox("chinarainbow", "Rainbow", settings["rainbow"])
	rainbow_checkbox:change_callback(function()
		settings["rainbow"] = rainbow_checkbox:get_value()
		savesettings()
	end)

	local chunk_slider = menu:add_slider("chinachunk", "Chunk Size", 1, 20, settings["chunk"])
	chunk_slider:change_callback(function()
		settings["chunk"] = chunk_slider:get_value()
		savesettings()
	end)
end

init()

local Workspace = game:get_service("Workspace")
local Players = game:get_service("Players")
local Player = Players.local_player

local RuntimeItems = Workspace:find_first_child("RuntimeItems")

local Picking = false
local outline_offsets = { vector2(-1, -1), vector2(-1, 1), vector2(1, -1), vector2(1, 1) }
local floor, world_to_screen, in_screen, render_add_text = math.floor, world_to_screen, in_screen, render.add_text
local vector2 = vector2
local Cached = {}
local UsefulItemsOnly = false
local UsefulItems = {
	"GoldBar",
	"SilverBar",
	"Bond",
	"Moneybag",
	"Coal",
	"Shotgun",
	"Rifle",
	"RifleAmmo",
	"Bandage",
	"ShotgunShells",
	"BankCombo",
	"Snake Oil",
	"Sawed-Off Shotgun",
	"Model_Werewolf",
	"Crucifix",
	"Holy Water"
}

-- Utility functions
local function LogFunc(message)
	print("[Dead Rails ESP] " .. message)
end

local function SafeCall(func, funcName, ...)
	local success, result = pcall(func, ...)
	if not success then
		LogFunc(("Error in %s: %s"):format(tostring(funcName), tostring(result)))
		return nil
	end
	return result
end

local function GetDistance(pos1, pos2)
	return floor((pos1 - pos2):length())
end

local function GetItemSpecific(item)
	return Cached[item] or false
end

local function GetItemPart(item)
	if not item or not item:isvalid() then
		return nil
	end

	-- Check cache first
	if Cached[item] then
		local part = item:find_first_child(Cached[item])
		if part and part:isvalid() and (part:isa("Part") or part:isa("MeshPart") or part:isa("UnionOperation")) then
			return part
		end
	end

	-- Find first valid part
	for _, part in pairs(item:get_children()) do
		if part:isvalid() and (part:isa("Part") or part:isa("MeshPart") or part:isa("UnionOperation")) then
			Cached[item] = part.name
			return part
		end
	end

	return nil
end

-- Render functions
local function CreateEspText(root, name, world_pos, objColor)
	if not root or not world_pos then
		return
	end

	local dist = GetDistance(root.position, world_pos)
	if dist <= 5 then -- Skip if too close
		return
	end

	local screen_pos = world_to_screen(world_pos)
	if not screen_pos or not in_screen(screen_pos) then
		return
	end

	local dist_text = ("[%dm]"):format(dist)
	local name_size = render.get_text_size(name)
	local dist_size = render.get_text_size(dist_text)

	local name_pos = vector2(screen_pos.x - name_size.x / 2, screen_pos.y)
	local dist_pos = vector2(screen_pos.x - dist_size.x / 2, screen_pos.y + name_size.y + 3)

	-- Outline
	for _, offset in ipairs(outline_offsets) do
		render_add_text(name_pos + offset, name, color(0, 0, 0, 1))
		render_add_text(dist_pos + offset, dist_text, color(0, 0, 0, 1))
	end

	-- Main text
	render_add_text(name_pos, name, objColor)
	render_add_text(dist_pos, dist_text, color(1, 1, 1, 1))
end

local function HandleRenderHook()
	if not RuntimeItems or not RuntimeItems:isvalid() then
		return
	end

	local character = Player.character
	if not character or not character:isvalid() then
		return
	end

	local root = character:find_first_child("HumanoidRootPart")
	if not root or not root:isvalid() then
		return
	end

	for _, item in pairs(RuntimeItems:get_children()) do
		if UsefulItemsOnly and not table.find(UsefulItems, item.name) then
			goto continue
		end
		
		local WeldData = item:find_first_child("WeldData")

		if item:isvalid() and not WeldData:isvalid() then
			local object = GetItemPart(item)
			if not object or not object:isvalid() then
				LogFunc(("Invalid part for item %s, skipping."):format(item.name))
				goto continue
			end

			CreateEspText(
				root,
				item.name,
				object.position,
				color(1, 1, 1, 1) -- White color
			)
		end

		::continue::
	end
end

local function CreateUI()
	local main = gui.create("Dead Rails ESP", false)
	main:set_pos(100, 100)
	main:set_size(250, 100)
	local checkbox = main:add_checkbox("Toggle Useful Items Only", UsefulItemsOnly)
	checkbox:change_callback(function()
		UsefulItemsOnly = checkbox:get_value()
	end)
end

local function Initialize()
	if not RuntimeItems then
		LogFunc("RuntimeItems not found - ESP disabled")
		return
	end

	SafeCall(CreateUI, "CreateUI")
	hook.add("render", "DeadRailsESP", function()
		SafeCall(HandleRenderHook, "RenderHook")
	end)

	LogFunc("Initialized successfully")
end

SafeCall(Initialize, "Initialize")

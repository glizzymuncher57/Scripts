local Workspace = game:get_service("Workspace")
local Players = game:get_service("Players")

local GameID = tonumber(get_gameid())
local Player = Players.local_player

local SupportedGamePaths = {
	[44636121] = {
		Path = function()
			return Workspace:find_first_child("Zombies")
		end,
		NPCsOnly = true,
	},
	[16680835] = {
		Path = function()
			return Workspace:find_first_child("Police")
		end,
		NPCsOnly = true,
	}
}

local function Initialise()
	local Data = SupportedGamePaths[GameID]
	if not Data then
		log.notification("Failed, check output!", "Info")
		print("This game is not currently supported ask me to support ur game man.")
		return
	end

	local Path = Data.Path()
	local NPCsOnly = Data.NPCsOnly

	if NPCsOnly then
		force_custom_players()
	end

	hook.add("init_custom_entity", "universal_npc", function()
		for _, NPC in pairs(Path:get_children()) do
			if NPC:isa("Model") and NPC:find_first_child_class("Humanoid") and NPC:isvalid() then
				local Humanoid = NPC:find_first_child_class("Humanoid")
				local Head = NPC:find_first_child("Head") or NPC:find_first_child_class("Part")

				if Humanoid and Humanoid:isvalid() then
					if NPC.name ~= Player.name and Head:isvalid() then
						local MinBound = vector3(math.huge, math.huge, math.huge)
						local MaxBound = vector3(-math.huge, -math.huge, -math.huge)

						for _, Part in pairs(NPC:get_children()) do
							if (Part:isa("MeshPart") or Part:isa("Part")) and Part:isvalid() then
								local Pos = Part.position
								local Size = Part.size / 2

								local PartMin = Pos - Size
								local PartMax = Pos + Size

								MinBound = vector3(
									math.min(MinBound.x, PartMin.x),
									math.min(MinBound.y, PartMin.y),
									math.min(MinBound.z, PartMin.z)
								)

								MaxBound = vector3(
									math.max(MaxBound.x, PartMax.x),
									math.max(MaxBound.y, PartMax.y),
									math.max(MaxBound.z, PartMax.z)
								)
							end
						end

						local BoundingSize = MaxBound - MinBound
						add_entity(NPC.name, Head, Humanoid, true, BoundingSize / 2, BoundingSize / 2)
					end
				end
			end
		end
	end)
end

Initialise()

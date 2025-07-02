local entities = game:get_service("Workspace"):find_first_child("Zombies")
local hook = hook

add_custom_hitparts({ "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" })
force_custom_players()

hook.add("init_custom_entity", "asdasdasd", function()
	for _, e in pairs(entities:get_children()) do
		if e:isvalid() then
			local parts = {
				e:find_first_child("Head"),
				e:find_first_child("Torso"),
				e:find_first_child("Left Arm"),
				e:find_first_child("Right Arm"),
				e:find_first_child("Left Leg"),
				e:find_first_child("Right Leg"),
			}

			for i, part in pairs(parts) do
				if not part:isvalid() then
					table.remove(parts, i)
					goto continue

					::continue::
				end
			end

			add_entity_ex(
				e.name,
				e,
				e:find_first_child("Humanoid") or nil_instance,
				e:find_first_child("HumanoidRootPart"),
				true,
				vector3(1, 0, 1), -- Min
				vector3(1, 1, 1), -- Max
				{
					["Head"] = parts[1],
					["Torso"] = parts[2],
					["Left Arm"] = parts[3],
					["Right Arm"] = parts[4],
					["Left Leg"] = parts[5],
					["Right Leg"] = parts[6],
				}
			)
		end
	end
end)

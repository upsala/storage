local S = rawget(_G, "intllib") and intllib.Getter() or function(s)
	return s
end

local pipeworks_enabled = minetest.get_modpath("pipeworks") ~= nil
local fs_helpers = pipeworks.fs_helpers

local tube_inject_item = pipeworks.tube_inject_item or function(pos, start_pos, velocity, item)
	local tubed = pipeworks.tube_item(vector.new(pos), item)
	tubed:get_luaentity().start_pos = vector.new(start_pos)
	tubed:setvelocity(velocity)
	tubed:setacceleration(vector.new(0, 0, 0))
end

local update_showcase = function(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local node = minetest.get_node(pos)

	if node.name:find("showcase") == nil then
		return
	end

	for _, stack in ipairs(inv:get_list("main")) do
		if stack and not stack:is_empty() then
			storage.show_item(pos, node, stack:get_name())
			return
		end
	end

	storage.show_item(pos, node, "")
end

local tubescan = pipeworks_enabled and function(pos)
	pipeworks.scan_for_tube_objects(pos)
end or nil

local function set_formspec(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", "Autofilter")
	meta:set_string("formspec", "size[8,5]" ..
			"item_image[0,0;1,1;storage:autofilter]" ..
			"label[1,0;Autofilter]" ..
			"label[3,0.3;Filteritem:]" ..
			"list[current_name;main;4,0;1,1;]" ..

			fs_helpers.cycling_button(
					meta,
					"image_button[5.5,0.35;1,0.6",
					"selflearning",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
			) ..
			"label[6.5,0.35;Self-learning]" ..
			"list[current_player;main;0,1.3;8,4;]" ..
			"listring[]")

	local inv = meta:get_inventory()
	inv:set_size("main", 1)
end

for _, data in ipairs({
	{
		name = "storage:autofilter",
		description = "Autofilter",
		tiles = "storage_autofilter_top.png"
	},
	{
		name = "storage:autofilter_showcase",
		description = "Autofilter with Showcase",
		tiles = "storage_chest_top_showcase.png"
	}
}) do

	minetest.register_node(
			data.name,
			{
				description = data.description,
				tiles = {
					data.tiles,
					"storage_autofilter_top.png",
					"storage_autofilter_output.png",
					"storage_autofilter_input.png",
					"storage_autofilter_side.png",
					"storage_autofilter_top.png",
				},
				paramtype2 = "facedir",
				legacy_facedir_simple = true,
				groups = { choppy = 2, oddly_breakable_by_hand = 2, tubedevice = 1, tubedevice_receiver = 1 },
				on_construct = set_formspec,
				after_place_node = pipeworks.after_place,
				after_dig_node = function(pos, oldnode, oldmetadata, digger)
					pipeworks.after_dig(pos)
					storage.remove_item(pos, oldnode)
				end,
				on_rotate = function(pos, node, player, mode, new_param2)
					storage.remove_item(pos, node)
					pipeworks.on_rotate(pos, node, player, mode, new_param2)
					update_showcase(pos)
				end,
				on_timer = storage.on_timer,
				on_receive_fields = function(pos, _, fields, sender)
					local name = sender:get_player_name()
					if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, { protection_bypass = true }) then
						minetest.record_protection_violation(pos, name)
						return
					end

					if fields["fs_helpers_cycling:0:selflearning"]
							or fields["fs_helpers_cycling:1:selflearning"] then
						if not pipeworks.may_configure(pos, sender) then
							return
						end
						fs_helpers.on_receive_fields(pos, fields)
					end
					set_formspec(pos)
				end,
				tube = {
					connect_sides = { right = 1, left = 1 },
					connects = function(i, param2)
						return not pipeworks.connects.facingFront(i, param2)
					end,
					input_inventory = "main",
					can_insert = function(pos, node, stack, direction, owner)
						local meta = minetest.get_meta(pos)
						local inv = meta:get_inventory()

						if meta:get_int("selflearning") == 0 then
							if inv:is_empty("main") then
								return false
							end
						end

						local dir = pipeworks.facedir_to_right_dir(node.param2)
						return vector.equals(dir, direction) and inv:is_empty("main") or inv:contains_item("main", stack:peek_item())
					end,
					insert_object = function(pos, node, stack, direction, owner)
						local meta = minetest.get_meta(pos)
						local inv = meta:get_inventory()

						if inv:is_empty("main") then
							inv:add_item("main", stack:peek_item())

							update_showcase(pos)
						end

						if inv:contains_item("main", stack:peek_item()) then
							tube_inject_item(pos, pos, pipeworks.facedir_to_right_dir(node.param2), stack)

							stack:clear()
						end

						return stack
					end,
				},
				allow_metadata_inventory_take = function(pos, listname, index, stack, player)
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()

					inv:remove_item("main", stack)

					update_showcase(pos)

					return 0
				end,
				allow_metadata_inventory_put = function(pos, _, _, stack, player)
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()

					if not inv:is_empty("main") then
						inv:remove_item("main", inv:get_stack("main", 1))
					end

					inv:add_item("main", stack:peek_item())

					update_showcase(pos)

					return 0
				end
			}
	)

end

minetest.register_craft({
	type = "shapeless",
	output = "storage:autofilter",
	recipe = { "storage:unique_locked_chest", "default:glass" }
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:autofilter_showcase",
	recipe = { "storage:autofilter", "default:glass" }
})


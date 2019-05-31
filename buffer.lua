local fs_helpers = pipeworks.fs_helpers

local tube_inject_item = pipeworks.tube_inject_item or function(pos, start_pos, velocity, item)
	local tubed = pipeworks.tube_item(vector.new(pos), item)
	tubed:get_luaentity().start_pos = vector.new(start_pos)
	tubed:setvelocity(velocity)
	tubed:setacceleration(vector.new(0, 0, 0))
end

local function send_stacks(pos, node)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	for _, stack in ipairs(inv:get_list("main")) do
		if stack:get_free_space() == 0 then
			tube_inject_item(pos, pos, pipeworks.facedir_to_right_dir(node.param2), stack)
			inv:remove_item("main", stack)
			return
		end
	end
end

local function send_top_item(pos, node)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local max = ItemStack(nil)

	for _, stack in ipairs(inv:get_list("main")) do
		if stack:get_count() > max:get_count() then
			max = stack
		end
	end

	if not max:is_empty() then
		tube_inject_item(pos, pos, pipeworks.facedir_to_right_dir(node.param2), max)
		inv:remove_item("main", max)
	end
end

local function set_formspec(meta)
	meta:set_string("infotext", "Buffer")
	meta:set_string("formspec", "size[8,5]" ..
			"item_image[0,0;1,1;storage:buffer]" ..
			"label[1,0;Buffer]" ..

			fs_helpers.cycling_button(
					meta,
					"image_button[5.5,0.15;1,0.6",
					"stackwise",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
			) ..
			"label[6.5,0.15;Stack-wise]" ..

			fs_helpers.cycling_button(
					meta,
					"image_button[5.5,0.65;1,0.6",
					"delayed",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
			) ..
			"label[6.5,0.65;Delayed]" ..

			"list[current_name;main;0,1.3;8,4;]"
	)
end

minetest.register_node(
		"storage:buffer",
		{
			description = "Buffer",
			tiles = {
				"storage_buffer_top.png",
				"storage_buffer_top.png",
				"storage_buffer_output.png",
				"storage_buffer_input.png",
				"storage_buffer_side.png",
				"storage_buffer_top.png",
			},
			paramtype2 = "facedir",
			legacy_facedir_simple = true,
			groups = { choppy = 2, oddly_breakable_by_hand = 2, tubedevice = 1, tubedevice_receiver = 1 },
			on_construct = function(pos)
				local meta = minetest.get_meta(pos)

				set_formspec(meta)

				local inv = meta:get_inventory()
				inv:set_size("main", 4 * 8)
			end,
			can_dig = function(pos, player)
				return minetest.get_meta(pos):get_inventory():is_empty("main")
			end,
			after_place_node = pipeworks.after_place,
			after_dig_node = function(pos, oldnode, oldmetadata, digger)
				pipeworks.after_dig(pos)
			end,
			on_rotate = function(pos, node, player, mode, new_param2)
				pipeworks.on_rotate(pos, node, player, mode, new_param2)
			end,
			on_receive_fields = function(pos, _, fields, sender)
				local name = sender:get_player_name()
				if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, { protection_bypass = true }) then
					minetest.record_protection_violation(pos, name)
					return
				end

				if fields["fs_helpers_cycling:0:stackwise"] or fields["fs_helpers_cycling:1:stackwise"] then
					if not pipeworks.may_configure(pos, sender) then
						return
					end
					fs_helpers.on_receive_fields(pos, fields)
				end

				if fields["fs_helpers_cycling:0:delayed"] or fields["fs_helpers_cycling:1:delayed"] then
					if not pipeworks.may_configure(pos, sender) then
						return
					end
					fs_helpers.on_receive_fields(pos, fields)
				end

				set_formspec(minetest.get_meta(pos))
			end,
			on_punch = function(pos, node, puncher)
				send_top_item(pos, node)
			end,
			tube = {
				connect_sides = { right = 1, left = 1 },
				priority = 120,
				connects = function(i, param2)
					return not pipeworks.connects.facingFront(i, param2)
				end,
				input_inventory = "main",
				can_insert = function(pos, node, stack, direction, owner)
					local dir = pipeworks.facedir_to_right_dir(node.param2)
					return vector.equals(dir, direction)
				end,
				insert_object = function(pos, node, stack, direction, owner)
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()
					local rest

					repeat
						rest = inv:add_item("main", stack)

						if meta:get_int("stackwise") ~= 0 then
							send_stacks(pos, node)
						end

						if not rest:is_empty() and not inv:room_for_item("main", rest) then
							send_top_item(pos, node)
						end
					until rest:is_empty()

					return rest
				end,
			},
			allow_metadata_inventory_take = function(pos, listname, index, stack, player)
				return 0
			end,
			allow_metadata_inventory_put = function(pos, _, _, stack, player)
				return 0
			end,
			allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
				return 0
			end
		}
)

minetest.register_craft({
	output = "storage:buffer",
	recipe = {
		{ 'default:chest', 'default:chest', 'default:chest' },
		{ 'pipeworks:tube_1', 'default:mese_crystal', 'pipeworks:tube_1' },
		{ 'default:chest', 'default:chest', 'default:chest' },
	}
})

minetest.register_abm{
	label = "storage:buffer",
	nodenames = {"storage:buffer"},
	interval = 30,
	chance = 1,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if meta:get_int("delayed") ~= 0 then
			send_top_item(pos, node)
		end
	end
}
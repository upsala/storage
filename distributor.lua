local fs_helpers = pipeworks.fs_helpers

local tube_inject_item = pipeworks.tube_inject_item or function(pos, start_pos, velocity, item)
	local tubed = pipeworks.tube_item(vector.new(pos), item)
	tubed:get_luaentity().start_pos = vector.new(start_pos)
	tubed:setvelocity(velocity)
	tubed:setacceleration(vector.new(0, 0, 0))
end

local function set_formspec(meta)
	meta:set_string("infotext", "Distributor")
	meta:set_string("formspec", "size[8,7.8]" ..
			"item_image[0,0;1,1;storage:distributor]" ..
			"label[1,0;Distributor]" ..

			"field[0.3,1.5;8,1;players;Players;${players}]" ..

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
					"limit",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
			) ..
			"label[6.5,0.65;Limit]" ..

			"list[current_name;main;0,2;8,2;]" ..
			"list[current_player;main;0,4.1;8,4;]" ..
			"listring[]"
	)
end

local function inv_change(pos, count, player)
	-- Skip check for pipeworks (fake player)
	if minetest.is_player(player) and
			not default.can_interact_with_node(player, pos) then
		return 0
	end
	return count
end

minetest.register_node(
		"storage:distributor",
		{
			description = "Distributor",
			tiles = {
				{
					name = "storage_distributor_top.png",
					animation = {
						type = "vertical_frames",
						aspect_w = 64,
						aspect_h = 64,
						length = 1.0
					}
				},
				{
					name = "storage_distributor_top.png",
					animation = {
						type = "vertical_frames",
						aspect_w = 64,
						aspect_h = 64,
						length = 1.0
					}
				},
				{
					name = "storage_distributor_side.png",
					animation = {
						type = "vertical_frames",
						aspect_w = 64,
						aspect_h = 64,
						length = 1.0
					}
				},
				{
					name = "storage_distributor_side.png",
					animation = {
						type = "vertical_frames",
						aspect_w = 64,
						aspect_h = 64,
						length = 1.0
					}
				},
				{
					name = "storage_distributor_side.png",
					animation = {
						type = "vertical_frames",
						aspect_w = 64,
						aspect_h = 64,
						length = 1.0
					}
				},
				{
					name = "storage_distributor_front.png",
					animation = {
						type = "vertical_frames",
						aspect_w = 64,
						aspect_h = 64,
						length = 1.0
					}
				}
			},
			paramtype2 = "facedir",
			legacy_facedir_simple = true,
			groups = { choppy = 2, oddly_breakable_by_hand = 2, tubedevice = 1, tubedevice_receiver = 1 },
			on_construct = function(pos)
				local meta = minetest.get_meta(pos)

				set_formspec(meta)

				local inv = meta:get_inventory()
				inv:set_size("main", 2 * 8)
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

				local meta = minetest.get_meta(pos)

				if fields["players"] then
					meta:set_string("players", fields["players"])
				end

				if fields["fs_helpers_cycling:0:stackwise"] or fields["fs_helpers_cycling:1:stackwise"] then
					if not pipeworks.may_configure(pos, sender) then
						return
					end
					fs_helpers.on_receive_fields(pos, fields)
				end

				if fields["fs_helpers_cycling:0:limit"] or fields["fs_helpers_cycling:1:limit"] then
					if not pipeworks.may_configure(pos, sender) then
						return
					end
					fs_helpers.on_receive_fields(pos, fields)
				end

				set_formspec(minetest.get_meta(pos))
			end,
			tube = {
				connect_sides = { right = 1, left = 1, top = 1, bottom = 1, front = 1, back = 1 },
				input_inventory = "main",
				can_insert = function(pos, node, stack, direction, owner)
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()

					return inv:room_for_item("main", stack:peek_item(1))
				end,
				insert_object = function(pos, node, stack, direction, owner)
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()

					return inv:add_item("main", stack)
				end,
			},
			allow_metadata_inventory_take = function(pos, listname, index, stack, player)
				return inv_change(pos, stack:get_count(), player)
			end,
			allow_metadata_inventory_put = function(pos, _, _, stack, player)
				return inv_change(pos, stack:get_count(), player)
			end,
			allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
				return inv_change(pos, count, player)
			end,
			on_metadata_inventory_move = function(pos, _, _, _, _, count, player)
				minetest.log("action", player:get_player_name() .. " moves stuff in distributor at " .. minetest.pos_to_string(pos))
			end,
			on_metadata_inventory_put = function(pos, _, _, stack, player)
				minetest.log("action", player:get_player_name() .. " puts stuff into distributor at " .. minetest.pos_to_string(pos))
			end,
			on_metadata_inventory_take = function(pos, _, _, stack, player)
				minetest.log("action", player:get_player_name() .. " takes stuff from distributor at " .. minetest.pos_to_string(pos))
			end
		}
)

minetest.register_craft({
	output = "storage:distributor",
	recipe = {
		{ 'default:chest', 'default:chest', 'default:chest' },
		{ 'pipeworks:tube_1', 'default:diamond', 'pipeworks:tube_1' },
		{ 'default:chest', 'default:chest', 'default:chest' },
	}
})

minetest.register_abm{
	label = "storage:distributor",
	nodenames = {"storage:distributor"},
	interval = 1,
	chance = 1,
	action = function(pos, node)

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if not inv:is_empty("main") then

			local stackwise = meta:get_int("stackwise") ~= 0
			local limit = meta:get_int("limit") ~= 0
			local players = meta:get_string("players") or ""
			local size = inv:get_size("main")

			for _, object in pairs(minetest.get_objects_inside_radius(pos, 5)) do
				if object:is_player() then

					if players == "" or string.find(";"..players..";", ";" .. object:get_player_name() .. ";") then

						local player_inv = object:get_inventory()
						local table = {}

						for i=1,size do
							local stack = inv:get_stack("main", i)
							local item_name = stack:get_name()

							if not table[item_name] then
								table[item_name] = stackwise and stack:get_stack_max() or 1
							end

							if stack:get_count()>table[item_name] then
								stack:take_item(stack:get_count() - table[item_name])
							end

							if (not limit) or (limit and not player_inv:contains_item("main", stack:peek_item())) then
								local rest = player_inv:add_item("main", stack)

								stack:take_item(rest:get_count())

								inv:remove_item("main", stack)

								table[item_name] = table[item_name] - stack:get_count()
							end
						end
					end
				end
			end
		end
	end

}


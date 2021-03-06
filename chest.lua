local S = rawget(_G, "intllib") and intllib.Getter() or function(s)
	return s
end

local pipeworks_enabled = minetest.get_modpath("pipeworks") ~= nil
local technic_enabled = minetest.get_modpath("technic") ~= nil

local tube_inject_item = pipeworks.tube_inject_item or function(pos, start_pos, velocity, item)
	local tubed = pipeworks.tube_item(vector.new(pos), item)
	tubed:get_luaentity().start_pos = vector.new(start_pos)
	tubed:setvelocity(velocity)
	tubed:setacceleration(vector.new(0, 0, 0))
end


local function check_fill_level(pos)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	local node = minetest.get_node(pos)

	local count = 0
	for _, stack in ipairs(inv:get_list("main")) do
		if not stack:is_empty() then
			count = count + 1
		end
	end

	local pct = math.floor(count / inv:get_size("main") * 5.1)
	pct = math.max(pct, 0)
	pct = math.min(pct, 5)

	local new_name = node.name
	local last_char = new_name:sub(#new_name)
	if last_char=="1" or last_char=="2" or last_char=="3" or last_char=="4" or last_char=="5" then
		new_name = new_name:sub(1, -2)
	end

	if pct>0 then
		new_name = new_name..pct
	end

	minetest.swap_node(pos, {name = new_name, param2 = node.param2})
end

local update_showcase = function(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local node = minetest.get_node(pos)

	check_fill_level(pos)

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

local function sendMessage(pos, msg)
	local channel = minetest.get_meta(pos):get_string("channel")
	if channel ~= nil and channel ~= "" then
		digilines.receptor_send(pos, digilines.rules.default, channel, msg)
	end
end

local function can_insert(pos, stack, unique)
	local inv = minetest.get_meta(pos):get_inventory()
	local can = true

	stack = stack:peek_item()

	if unique and not inv:is_empty("main") then
		can = inv:contains_item("main", stack:peek_item())
	end

	return can and inv:room_for_item("main", stack)
end

local function is_full(pos)
	local inv = minetest.get_meta(pos):get_inventory()

	for _, stack in ipairs(inv:get_list("main")) do
		if stack:get_free_space() > 0 then
			return false
		end
	end
	return true
end

local on_digiline_receive = function(pos, _, channel, msg)
	local meta = minetest.get_meta(pos);
	local setchan = meta:get_string("channel")
	local inv = meta:get_inventory()

	if channel ~= setchan and channel ~= "" then
		return
	end

	local action
	local msg_pos
	local msg_item

	local t_msg = type(msg)
	if t_msg == "table" then
		action = msg.action
		msg_pos = tonumber(msg.pos)
		msg_item = msg.item
	elseif t_msg == "string" then
		action = msg:match("[%w_]+")
		msg_item = msg:match("%w+%s+(.+)")
		msg_pos = tonumber(msg_item)
		if msg_pos ~= nil then
			msg_item = nil
		end
	end

	if action == nil or type(action) ~= "string" then
		return
	end

	if action == "eject" then
		if msg_pos ~= nil and msg_pos >= 1 and msg_pos <= inv:get_size("main") then
			local stack = inv:get_stack("main", msg_pos)

			if stack and not stack:is_empty() then
				tube_inject_item(pos, pos, vector.new(0, -1, 0), stack)
				sendMessage(pos, { event = "take", items = { stack:to_table() } })
				stack:clear()
				inv:set_stack("main", msg_pos, stack)
				update_showcase(pos)
				if inv:is_empty("main") then
					sendMessage(pos, { event = "empty" })
				end
			end
			return
		end

		if msg_item ~= nil then
			local stack = inv:remove_item("main", msg_item)

			if stack and not stack:is_empty() then
				tube_inject_item(pos, pos, vector.new(0, -1, 0), stack)
				sendMessage(pos, { event = "take", items = { stack:to_table() } })
				update_showcase(pos)
				if inv:is_empty("main") then
					sendMessage(pos, { event = "empty" })
				end
			end

			return
		end

		local i = 0
		for _, stack in ipairs(inv:get_list("main")) do
			i = i + 1
			if stack and not stack:is_empty() then
				tube_inject_item(pos, pos, vector.new(0, -1, 0), stack)
				sendMessage(pos, { event = "take", items = { stack:to_table() } })
				stack:clear()
				inv:set_stack("main", i, stack)
				update_showcase(pos)
				if inv:is_empty("main") then
					sendMessage(pos, { event = "empty" })
				end
				return
			end
		end
	end

	if action == "sort" then
		sort_inventory(pos)
	end

	if action == "get" then
		msg_pos = msg_pos == nil and msg_pos or 1

		if msg_pos >= 1 and msg_pos <= inv:get_size("main") then
			local stack = inv:get_stack("main", msg_pos)
			sendMessage(pos, { event = "get", item = stack:to_table() })
		end
	end

	if action == "list" then
		local t = {}
		for _, stack in ipairs(inv:get_list("main")) do
			if not stack:is_empty() then
				t[#t + 1] = stack:to_table()
			end
		end

		sendMessage(pos, { event = "items", items = t })
	end

	if action == "count" then
		if msg_pos ~= nil and msg_pos >= 1 and msg_pos <= inv:get_size("main") then
			local stack = inv:get_stack("main", msg_pos)

			sendMessage(pos, { event = "count", count = stack:get_count() })
			return
		end

		if msg_item ~= nil then
			local itemstack = ItemStack(msg_item)
			local count = 0
			for _, stack in ipairs(inv:get_list("main")) do
				if stack and itemstack:get_name() == stack:get_name() then
					count = count + stack:get_count()
				end
			end
			sendMessage(pos, { event = "count", count = math.floor(count / itemstack:get_count()) })
			return
		end

		local count = 0
		for _, stack in ipairs(inv:get_list("main")) do
			if stack then
				count = count + stack:get_count()
			end
		end
		sendMessage(pos, { event = "count", count = count })
	end

	if action == "find" then
		local found = inv:contains_item("main", msg_item)
		sendMessage(pos, { event = found and "found" or "not found" })
	end

	if action == "is_empty" then
		local empty = inv:is_empty("main")
		sendMessage(pos, { event = empty and "empty" or "not empty" })
	end

	if action == "is_full" then
		if is_full(pos) then
			sendMessage(pos, { event = "full" })
			return
		end

		sendMessage(pos, { event = "not full" })
	end
end

local tubescan = pipeworks_enabled and function(pos)
	pipeworks.scan_for_tube_objects(pos)
end or nil

local function handle_move_all_items(pos, sender, filtered, src_inv, dst_inv, user_msg, event)
	local t = {}
	local i = 0
	for _, stack in ipairs(src_inv:get_list("main")) do
		i = i + 1

		local skip = filtered and not stack:is_empty() and not dst_inv:is_empty("main") and not dst_inv:contains_item("main", stack:peek_item())

		if not skip then
			local rest = dst_inv:add_item("main", stack)

			if stack:get_count() ~= rest:get_count() then
				stack:take_item(rest:get_count())
				t[#t + 1] = stack:to_table()

				src_inv:set_stack("main", i, rest)
			end
		end
	end

	if #t ~= 0 then
		minetest.log("action", sender:get_player_name() .. user_msg .. minetest.pos_to_string(pos))

		sendMessage(pos, { event = event, items = t })

		if is_full(pos) then
			sendMessage(pos, { event = "full" })
		end

		local inv = minetest.get_meta(pos):get_inventory()
		if inv:is_empty("main") then
			sendMessage(pos, { event = "empty" })
		end
		update_showcase(pos)
	end
end

local function put_all_items(pos, sender, filtered)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()

	local player_inv = sender:get_inventory()

	handle_move_all_items(pos, sender, filtered, player_inv, inv, " puts stuff into chest at ", "put")
end

local function take_all_items(pos, sender, filtered)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()

	local player_inv = sender:get_inventory()

	handle_move_all_items(pos, sender, filtered, inv, player_inv, " takes stuff from chest at ", "take")
end

local function sort_inventory(pos)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()

	local inlist = inv:get_list("main")
	local typecnt = {}
	local typekeys = {}
	for _, st in ipairs(inlist) do
		if not st:is_empty() then
			local n = st:get_name()
			local w = st:get_wear()
			local m = st:get_metadata()
			local k = string.format("%s %05d %s", n, w, m)
			if not typecnt[k] then
				typecnt[k] = { st }
				table.insert(typekeys, k)
			else
				table.insert(typecnt[k], st)
			end
		end
	end
	table.sort(typekeys)
	inv:set_list("main", {})
	for _, k in ipairs(typekeys) do
		for _, item in ipairs(typecnt[k]) do
			inv:add_item("main", item)
		end
	end

	update_showcase(pos)
end

local function register_chest(output, drop, locked, showcase, unique, tiles, not_in_creative_inventory)
	local description = ((locked and "Locked ") or "") .. ((unique and "Unqiue ") or "") .. "Digiline-Chest" .. ((showcase and " with Showcase") or "")

	local locked_after_place = pipeworks.after_place
	local check_locked = function()
		return false
	end
	if locked then
		locked_after_place = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name() or "")
			meta:set_string("infotext", S("%s (owned by %s)"):format(description, meta:get_string("owner")))
			pipeworks.after_place(pos)
		end

		check_locked = function(pos, player)
			return not default.can_interact_with_node(player, pos)
		end
	end

	minetest.register_node(
			output,
			{
				description = description,
				tiles = tiles,
				paramtype2 = "facedir",
				legacy_facedir_simple = true,
				drop = drop,
				groups = { choppy = 2, oddly_breakable_by_hand = 2, tubedevice = 1, tubedevice_receiver = 1, not_in_creative_inventory = not_in_creative_inventory },
				on_construct = function(pos)
					local digiline_description = "Digiline-Commands,  - eject \\[<pos>|<item>\\],  - sort,  - count \\[<pos>|<item>\\],  - get \\[<pos>\\],  - is_full,  - is_empty,  - list,  - find <item>,,Digiline-Events,  - take <item>,  - put <item>,  - full,  - empty"

					local meta = minetest.get_meta(pos)
					meta:set_string("infotext", description)
					meta:set_string("formspec", "size[15,11]" ..
							"item_image[0,0;1,1;" .. output .. "]" ..
							"label[1,0;" .. description .. "]" ..
							"field[6,0.3;5,1;channel;Digiline-Channel;${channel}]" ..
							"list[current_name;main;0,1;15,6;]" ..
							"list[current_player;main;3.5,7.3;8,4;]" ..
							"listring[]" ..
							"image_button[0,7.3;1,1;storage_take_items.png;take;]" ..
							"tooltip[take;Take all items out of the chest]" ..
							"image_button[1,7.3;1,1;storage_take_filtered_items.png;take_filtered;]" ..
							"tooltip[take_filtered;Take all items out of the chest, which are the same as the player has]" ..
							"image_button[0,8.3;1,1;storage_put_items.png;put;]" ..
							"tooltip[put;Put the player's inventory into the chest]" ..
							"image_button[1,8.3;1,1;storage_put_filtered_items.png;put_filtered;]" ..
							"tooltip[put_filtered;Put all items from the player's inventory into the chest, if the chest has the same items]" ..
							"image_button[0,9.3;1,1;storage_sort_items.png;sort;]" ..
							"tooltip[sort;Sort the items in the chest]" ..
							"textlist[11.5,7.3;3.3,3.8;descr;" .. digiline_description .. "]")

					local inv = meta:get_inventory()
					inv:set_size("main", 15 * 6)
				end,
				after_place_node = locked_after_place,
				after_dig_node = function(pos, oldnode, oldmetadata, digger)
					tubescan(pos, oldnode, oldmetadata, digger)
					storage.remove_item(pos, oldnode)
				end,
				on_timer = storage.on_timer,
				can_dig = function(pos, player)
					return minetest.get_meta(pos):get_inventory():is_empty("main") and not check_locked(pos, player)
				end,
				on_receive_fields = function(pos, _, fields, sender)
					local name = sender:get_player_name()
					if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, { protection_bypass = true }) then
						minetest.record_protection_violation(pos, name)
						return
					end
					if check_locked(pos, sender) then
						return
					end
					if fields.channel ~= nil then
						minetest.get_meta(pos):set_string("channel", fields.channel)
					end
					if fields.put then
						put_all_items(pos, sender, unique)
					end
					if fields.put_filtered then
						put_all_items(pos, sender, true)
					end
					if fields.take then
						take_all_items(pos, sender)
					end
					if fields.take_filtered then
						take_all_items(pos, sender, true)
					end
					if fields.sort then
						sort_inventory(pos)
					end
				end,
				digiline = {
					receptor = {},
					effector = {
						action = function(pos, node, channel, msg)
							on_digiline_receive(pos, node, channel, msg)
						end
					}
				},
				tube = {
					connect_sides = { left = 1, right = 1, back = 1, bottom = 1, top = 1 },
					connects = function(i, param2)
						return not pipeworks.connects.facingFront(i, param2)
					end,
					input_inventory = "main",
					can_insert = function(pos, _, stack)
						return can_insert(pos, stack, unique)
					end,
					insert_object = function(pos, _, stack)
						local inv = minetest.get_meta(pos):get_inventory()

						if unique and not inv:is_empty("main") and not inv:contains_item("main", stack:peek_item()) then
							return stack
						end

						local leftover = inv:add_item("main", stack)
						stack:take_item(leftover:get_count())
						if not stack:is_empty() then
							sendMessage(pos, { event = "put", items = { stack:to_table() } })
						end

						if is_full(pos) then
							sendMessage(pos, { event = "full" })
						end

						update_showcase(pos)

						return leftover
					end,
				},
				allow_metadata_inventory_move = function(pos, _, _, _, _, count, player)
					if check_locked(pos, player) then
						return 0
					end
					return count
				end,
				allow_metadata_inventory_take = function(pos, _, _, stack, player)
					if check_locked(pos, player) then
						return 0
					end
					return stack:get_count()
				end,
				allow_metadata_inventory_put = function(pos, _, _, stack, player)
					if check_locked(pos, player) then
						return 0
					end

					if not can_insert(pos, stack, unique) then
						return 0
					end
					return stack:get_count()
				end,
				on_metadata_inventory_move = function(pos, _, _, _, _, _, player)
					minetest.log("action", player:get_player_name() .. " moves stuff in chest at " .. minetest.pos_to_string(pos))

					update_showcase(pos)
				end,
				on_metadata_inventory_put = function(pos, _, _, stack, player)
					sendMessage(pos, { event = "put", items = { stack:to_table() } })

					minetest.log("action", player:get_player_name() .. " puts stuff into chest at " .. minetest.pos_to_string(pos))

					if is_full(pos) then
						sendMessage(pos, { event = "full" })
					end

					update_showcase(pos)
				end,
				on_metadata_inventory_take = function(pos, listname, _, stack, player)
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()
					if inv:is_empty(listname) then
						sendMessage(pos, { event = "empty" })
					end
					sendMessage(pos, { event = "take", items = { stack:to_table() } })
					minetest.log("action", player:get_player_name() .. " takes stuff from chest at " .. minetest.pos_to_string(pos))

					update_showcase(pos)
				end
			}
	)
end

local tubeconn = pipeworks_enabled and "^pipeworks_tube_connection_metallic.png" or ""
local chest = technic_enabled and "technic:gold_chest" or "default:chest"
local locked_chest = technic_enabled and "technic:gold_locked_chest" or "default:chest_locked"

for i = 0, 5 do
	local name = i
	local img = "^storage_chest_fill" .. i .. "_overlay.png"
	local not_in_creative_inventory = 1
	if i == 0 then
		name = ""
		img = ""
		not_in_creative_inventory = 0
	end

	register_chest(
			"storage:chest" .. name,
			"storage:chest",
			false,
			false,
			false,
			{
				"storage_chest_top.png" .. tubeconn,
				"storage_chest_top.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_front.png" .. img,
			},
			not_in_creative_inventory
	)

	register_chest(
			"storage:locked_chest" .. name,
			"storage:locked_chest",
			true,
			false,
			false,
			{
				"storage_chest_top.png" .. tubeconn,
				"storage_chest_top.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_front.png^storage_chest_lock_overlay.png" .. img,
			},
			not_in_creative_inventory
	)

	register_chest(
			'storage:unique_chest' .. name,
			'storage:unique_chest',
			false,
			false,
			true,
			{
				"storage_chest_top_unique.png" .. tubeconn,
				"storage_chest_top_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_front_unique.png" .. img,
			},
			not_in_creative_inventory
	)

	register_chest(
			'storage:unique_locked_chest' .. name,
			'storage:unique_locked_chest',
			true,
			false,
			true,
			{
				"storage_chest_top_unique.png" .. tubeconn,
				"storage_chest_top_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_front_unique.png^storage_chest_lock_overlay.png" .. img,
			},
			not_in_creative_inventory
	)

	register_chest(
			'storage:showcase_chest' .. name,
			'storage:showcase_chest',
			false,
			true,
			false,
			{
				"storage_chest_top_showcase.png",
				"storage_chest_top.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_front.png" .. img,
			},
			not_in_creative_inventory
	)

	register_chest(
			'storage:showcase_locked_chest' .. name,
			'storage:showcase_locked_chest',
			true,
			true,
			false,
			{
				"storage_chest_top_showcase.png",
				"storage_chest_top.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_side.png" .. tubeconn,
				"storage_chest_front.png^storage_chest_lock_overlay.png" .. img,
			},
			not_in_creative_inventory
	)

	register_chest(
			'storage:showcase_unique_chest' .. name,
			'storage:showcase_unique_chest',
			false,
			true,
			true,
			{
				"storage_chest_top_showcase.png",
				"storage_chest_top_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_front_unique.png" .. img,
			},
			not_in_creative_inventory
	)

	register_chest(
			'storage:showcase_unique_locked_chest' .. name,
			'storage:showcase_unique_locked_chest',
			true,
			true,
			true,
			{
				"storage_chest_top_showcase.png",
				"storage_chest_top_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_side_unique.png" .. tubeconn,
				"storage_chest_front_unique.png^storage_chest_lock_overlay.png" .. img,
			},
			not_in_creative_inventory
	)
end



-- chest --

minetest.register_craft({
	output = "storage:chest",
	recipe = {
		{ 'dye:red', 'digilines:wire_std_00000000', 'dye:red' },
		{ 'dye:red', 'pipeworks:digiline_filter', 'dye:red' },
		{ 'dye:red', chest, 'dye:red' },
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:chest",
	recipe = { "storage:unique_chest", "dye:red" }
})

-- locked chest --

minetest.register_craft({
	output = "storage:locked_chest",
	recipe = {
		{ 'dye:red', 'digilines:wire_std_00000000', 'dye:red' },
		{ 'dye:red', 'pipeworks:digiline_filter', 'dye:red' },
		{ 'dye:red', locked_chest, 'dye:red' },
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:locked_chest",
	recipe = { "storage:chest", "default:steel_ingot" }
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:locked_chest",
	recipe = { "storage:unique_locked_chest", "dye:red" }
})

-- unique chest --

minetest.register_craft({
	output = "storage:unique_chest",
	recipe = {
		{ 'dye:green', 'digilines:wire_std_00000000', 'dye:green' },
		{ 'dye:green', 'pipeworks:digiline_filter', 'dye:green' },
		{ 'dye:green', chest, 'dye:green' },
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:unique_chest",
	recipe = { "storage:chest", "dye:green" }
})

-- unique locked chest --

minetest.register_craft({
	output = "storage:unique_locked_chest",
	recipe = {
		{ 'dye:green', 'digilines:wire_std_00000000', 'dye:green' },
		{ 'dye:green', 'pipeworks:digiline_filter', 'dye:green' },
		{ 'dye:green', locked_chest, 'dye:green' },
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:unique_locked_chest",
	recipe = { "storage:locked_chest", "dye:green" }
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:unique_locked_chest",
	recipe = { "storage:unique_chest", "default:steel_ingot" }
})

-- showcase chest --

minetest.register_craft({
	type = "shapeless",
	output = "storage:showcase_chest",
	recipe = { "storage:chest", "default:glass" }
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:showcase_chest",
	recipe = { "storage:showcase_unique_chest", "dye:red" }
})

-- showcase locked chest --

minetest.register_craft({
	type = "shapeless",
	output = "storage:showcase_locked_chest",
	recipe = { "storage:locked_chest", "default:glass" }
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:showcase_locked_chest",
	recipe = { "storage:showcase_unique_locked_chest", "dye:red" }
})

-- showcase unique chest --

minetest.register_craft({
	type = "shapeless",
	output = "storage:showcase_unique_chest",
	recipe = { "storage:unique_chest", "default:glass" }
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:showcase_unique_chest",
	recipe = { "storage:showcase_chest", "dye:green" }
})

-- showcase unique locked chest --

minetest.register_craft({
	type = "shapeless",
	output = "storage:showcase_unique_locked_chest",
	recipe = { "storage:unique_locked_chest", "default:glass" }
})

minetest.register_craft({
	type = "shapeless",
	output = "storage:showcase_unique_locked_chest",
	recipe = { "storage:showcase_locked_chest", "dye:green" }
})

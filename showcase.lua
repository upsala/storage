local on_digiline_receive = function(pos, node, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")

	if channel == setchan then
		local stack = ItemStack(msg)
		if msg=="" or stack:is_known() then
			storage.show_item(pos, node, msg)
		end
	end
end

minetest.register_node("storage:showcase", {
	description = "Showcase",
	drawtype = "nodebox",
	groups = { choppy = 3, oddly_breakable_by_hand = 2 },
	sounds = default.node_sound_wood_defaults(),
	light_source = 10,
	node_box = {
		type = "fixed",
		fixed = { { -0.5, -0.5, -0.5, 0.5, -0.5 + 0.0625, 0.5 }, } },
	tiles = { "storage_chest_top_showcase.png", "storage_chest_top_showcase.png", "storage_chest_top_showcase.png",
			  "storage_chest_top_showcase.png", "storage_chest_top_showcase.png", "storage_chest_top_showcase.png" },
	on_timer = storage.on_timer,
	after_destruct = storage.remove_item,
	digiline = {
		receptor = {},
		effector = {
			action = on_digiline_receive
		}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Showcase")
		meta:set_string("formspec",
				"size[5,2]" ..
				"item_image[0,0;1,1;storage:showcase]" ..
				"label[1,0;Showcase]" ..
				"field[0.3,1.5;5,1;channel;Channel;${channel}]")
	end,
	on_receive_fields = function(pos, _, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, { protection_bypass = true }) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if fields.channel ~= nil then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end
})


-- Recipes

minetest.register_craft({
	output = "storage:showcase",
	recipe = {
		{ "default:steel_ingot", "digilines:wire_std_00000000", "default:steel_ingot" },
		{ "default:steel_ingot", "default:paper", "default:steel_ingot" },
		{ "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" }
	}
})


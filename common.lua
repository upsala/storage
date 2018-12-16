local tmp = {}

storage = {}

function storage.remove_item(pos, node)
	local pos2 = pos
	if node.name ~= "storage:showcase" then
		pos2 = vector.add(pos, { x = 0, y = 12 / 16 + .33, z = 0 })
	end

	local objs = minetest.get_objects_inside_radius(pos2, 0.5)
	if not objs then
		return
	end

	for _, obj in pairs(objs) do
		if obj and obj:get_luaentity() and obj:get_luaentity().name == "storage:showcase_item" then
			obj:remove()
			break
		end
	end
end

function storage.update_item(pos, node)
	local meta = minetest.get_meta(pos)
	local itemstring = meta:get_string("item")

	storage.remove_item(pos, node)

	if itemstring ~= "" then
		local pos2 = pos
		if node.name ~= "storage:showcase" then
			pos2 = vector.add(pos, { x = 0, y = 12 / 16 + .33, z = 0 })
		end

		tmp.nodename = node.name
		tmp.texture = ItemStack(itemstring):get_name()

		minetest.add_entity(pos2, "storage:showcase_item")

		local timer = minetest.get_node_timer(pos)
		timer:start(15.0)
	else
		meta:set_string("item", "")
	end
end

function storage.show_item(pos, node, itemstring)
	local meta = minetest.get_meta(pos);
	local stack = ItemStack(itemstring)
	if stack:is_known() then
		meta:set_string("item", stack:get_name())
		storage.update_item(pos, node)
	else
		storage.remove_item(pos, node)
		meta:set_string("item", "")
	end
end

minetest.register_entity("storage:showcase_item", {
	hp_max = 1,
	visual = "wielditem",
	visual_size = { x = .33, y = .33 },
	collisionbox = { 0, 0, 0, 0, 0, 0 },
	physical = false,
	sunlight_propagates = true,
	textures = { "air" },
	on_activate = function(self, staticdata)
		if tmp.nodename ~= nil and tmp.texture ~= nil then
			self.nodename = tmp.nodename
			tmp.nodename = nil
			self.texture = tmp.texture
			tmp.texture = nil
		else
			if staticdata ~= nil and staticdata ~= "" then
				local data = staticdata:split(';')
				if data and data[1] and data[2] then
					self.nodename = data[1]
					self.texture = data[2]
				end
			end
		end
		if self.texture ~= nil then
			self.object:set_properties({ textures = { self.texture } })
		end
		self.object:set_properties({ automatic_rotate = 1 })
	end,
	get_staticdata = function(self)
		if self.nodename ~= nil and self.texture ~= nil then
			return self.nodename .. ';' .. self.texture
		end
		return ""
	end,
})

storage.on_timer = function(pos)
	local pos2 = pos
	if tmp.offset ~= nil then
		pos2 = vector.add(pos2, { x = 0, y = tmp.offset, z = 0 })
	end

	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local num = #minetest.get_objects_inside_radius(pos2, 0.5)

	if num == 0 and meta:get_string("item") ~= "" then
		storage.update_item(pos, node)
	end
	return true
end


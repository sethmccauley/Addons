function get_marray(--[[optional]]name)
	--[[ Format of new Mob Array
		Returns an array of comprehensive mob data. Useful fields below.
		number:
			id, index, claim_id, x, y, z, distance, facing, entity type, target index,
			spawn_type, status, model_scale, heading, model_size, movement_speed,
		string:
			name,
		booleans:
			is_npc, in_alliance, charmed, in_party, valid_target
	--]]
	local marray = windower.ffxi.get_mob_array()
	local target_name = name or nil
	local new_marray = T{}
	
	for i,v in pairs(marray) do
		if v.id == 0 or v.index == 0 then
			marray[i] = nil
		end
	end
	
	-- If passed a target name, strip those that do not match
	if target_name then
		for i,v in pairs(marray) do
			if v.name ~= target_name then
				marray[i] = nil
			end
		end
	end
	
	for i,v in pairs(marray) do 
		new_marray[#new_marray + 1] = windower.ffxi.get_mob_by_index(i)
	end
	return new_marray
end

-- Returns a table of the nearest mob to the character of all available mobs or of submitted table.
function pick_nearest(--[[optional]]t)
	local marray = t or get_marray()
	local nearest_distance = 50
	local nearest_mob = {}
	for i,v in pairs(marray) do
		if v.valid_target then
			if math.sqrt(v.distance) < nearest_distance then
				nearest_distance = math.sqrt(v.distance)
				table.clear(nearest_mob)
				nearest_mob = v
			end
		end
	end
	return nearest_mob
end

-- Returns the correct value of sparks from the incoming 0x110 packet. 
windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
	if id == 0x110 then -- Update Current Sparks via 110
		local header, value1, value2, Unity1, Unity2, Unknown = data:unpack('II')
		current_sparks = value1
	end
end)

-- Attacks target specified.
function attack(id, index)
	if id then
		local packet = packets.new('outgoing', 0x01A, {
			["Target"]=id,
			["Target Index"]=index,
			["Category"]=2,
			["Param"]=0,
			["_unknown1"]=0})
		packets.inject(packet)
	end
end

-- Prettys up some numbers for human consumption
function commaformat(number)
   return string.format("%d", number):reverse():gsub( "(%d%d%d)" , "%1," ):reverse():gsub("^,","")
end

function detect_usable_gear()
	local inventory = windower.ffxi.get_items()
	local usable_bags = T{'inventory','wardrobe','wardrobe2','wardrobe3','wardrobe4'}
	local usable_equips = T{}
	
	-- When activation_time > next_use_time then usable = true
	-- When gear not equipped the activation_time is set to server_timestamp+offset
	-- This leads to the item being usable = false, equipping the gear is the only way to 
	-- Retrieve the activation_time(?)
	for i,v in pairs(inventory) do
		if usable_bags:contains(i) then
			for key,val in pairs(v) do
				if type(val) == 'table' and val.id ~= 0 and val.extdata then
					local extdata = extdata.decode(val)
					if extdata.type == 'Enchanted Equipment' then
						usable_equips:append(val)
						usable_equips[#usable_equips].extdata = extdata
						usable_equips[#usable_equips].name = res.items[val.id].en
						usable_equips[#usable_equips].bag = i
					end
				end
			end
		end
	end
	return usable_equips
end

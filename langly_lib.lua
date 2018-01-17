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

-- Returns the correct value of sparks from the incoming 0x110 packet. 
windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
  if id == 0x110 then -- Update Current Sparks via 110
		local header, value1, value2, Unity1, Unity2, Unknown = data:unpack('II')
		current_sparks = value1
	end
end)

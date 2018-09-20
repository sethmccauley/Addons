--[[
Copyright © 2018, Langly of Quetzalcoatl
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of React nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Langly BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'NewSparks'
_addon.author = 'Langly'
_addon.version = '1.0'
_addon.date = '9.19.2018'
_addon.commands = {'newsparks','ns'}

require('tables')
require('logger')
packets = require('packets')
db = require('map')
res_items = require('resources').items

valid_spark_zones = T{
	[256] = {npc="Eternal Flame", menu=5081}, -- Western Adoulin
	[230] = {npc="Rolandienne", menu=995}, -- Southern San d'Oria
	[235] = {npc="Isakoth", menu=26}, -- Bastok Markets
	[241] = {npc="Fhelm Jobeizat", menu=850}, -- Windurst Woods
}
valid_eschan_zones = T{
	[288] = {npc="Affi", menu=9701},  -- Escha Zitah
	[289] = {npc="Dremi", menu=9701},  -- Escha RuAun
	[291] = {npc="Shiftrix", menu=9701},  -- Reisenjima
}
item = ''
current_sparks = 0
purchase_queue = T{}
col = {}
all_temp_items = T{}
current_temp_items = T{}

windower.register_event('load', function()
	get_spark_update()
end)

windower.register_event('addon command', function (command, ...)
	command = command and command:lower()
	local args = T{...}
	item = table.concat(args,' '):lower()

	if command == 'buy' then
        notice('Buying 1 '..item..'.')
        purchase_queue[1] = build_item(item)
        return
	end

	if command == 'buyall' then
		col = build_item(item)
		local purchasable = math.floor(current_sparks/col.Cost)
		
        if purchasable == 0 then
            notice('You do not have enough sparks.')
            return
        end
        
		if col then 
			local free_space = count_inv()
			local tobuy = 0
			
			if purchasable > free_space then
				notice("You have "..free_space.." free slots, buying "..item.. " until full.")
				tobuy = free_space
			else
				notice('Spending '..current_sparks..' sparks to purchase: '..purchasable..' '..item..'s.')
				tobuy = purchasable
			end
			
			for i=1,tobuy do
				table.append(purchase_queue, col);
			end
		end
		return
	end

    if command == 'find' then
		table.vprint(build_item(item))
		return
	end
    
    if command == 'test' then
        table.vprint(col)
        table.vprint(purchase_queue)
    end
    
    if command == 'fail' then
        exit_sparks()
    end
end)

windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
	--[[if id == 0x020 then
        if purchase_queue and #purchase_queue > 0 then
            local p = packets.parse('incoming',data)
            local itemID = p['Item']
            if (itemID > 0) then
                local foundItem = res_items[itemID]
                if foundItem then
                    if purchase_queue[1].enl == foundItem.en:lower() or purchase_queue[1].enl == foundItem.enl:lower() then
                        table.remove(purchase_queue, 1)
                    end
                end
            end
        end
	end]]--

	if id == 0x034 or id == 0x032 then
        if purchase_queue and #purchase_queue > 0 then
            determine_interaction(purchase_queue[1])
            return true
        end
	end

	if id == 0x110 then -- Update Current Sparks via 110
		local header, value1, value2, Unity1, Unity2, Unknown = data:unpack('II')
		current_sparks = value1
	end
end)

windower.register_event('prerender', function()
	if table.length(purchase_queue) > 0 then
		send_timer = os.clock() - local_timer
        if send_timer >= 4 then
            notice('Timed out.')
            exit_sparks()
            local_timer = os.clock()
            return
        end
		if send_timer >= 1.6 then
            purchase_item(purchase_queue[1])
			local_timer = os.clock()
		end
	else
		local_timer = os.clock()
	end
end)

function determine_interaction(obj)
    local index = purchase_queue:find(obj)
    
    if index then
        table.remove(purchase_queue, index)
    end
    
    sparks_packet(obj)
end

function count_inv()
	local playerinv = windower.ffxi.get_items().inventory
	return playerinv.max - playerinv.count
end

function purchase_item(obj)
    if #purchase_queue % 5 == 0 then
        notice('Buying #'..#purchase_queue..'.')
    end
    poke_npc(obj['Target'],obj['Target Index'])
end

function build_item(item)
	local zone = windower.ffxi.get_info()['zone']
	local target_index,target_id,distance
	local result = {}
    local distance = 50
    
	if valid_spark_zones[zone] then
		for i,v in pairs(get_marray()) do
			if v['name'] == windower.ffxi.get_player().name then
				result['me'] = v.id
			elseif v['name'] == valid_spark_zones[zone].npc then
				target_index = v['index']
				target_id = v['id']
				npc_name = v['name']
				result['Menu ID'] = valid_spark_zones[zone].menu
				distance = windower.ffxi.get_mob_by_id(target_id).distance
			end
		end

		if math.sqrt(distance)<6 then
			local iitem = fetch_db(item)
			if iitem then
				result['Target'] = target_id
				result['Option Index'] = iitem['Option']
				result['_unknown1'] = iitem['Index']
				result['Target Index'] = target_index
				result['Zone'] = zone
				result['Cost'] = iitem['Cost']
                result['enl'] = iitem['Name']:lower()
			end
		else
            warning("Too far from NPC.")
            return nil
		end
	else
        warning("Not in a zone with sparks NPC.")
        return nil
	end
	if result['Zone'] == nil then result = nil end
	return result
end

function fetch_db(item)
	for i,v in pairs(db) do
		if string.lower(v.Name) == string.lower(item) then
			return v
		end
	end
end

function get_spark_update()
	local packet = packets.new('outgoing', 0x117, {["_unknown2"]=0})
	packets.inject(packet)
end

function poke_npc(npc,target_index)
	if npc and target_index then
		local packet = packets.new('outgoing', 0x01A, {
        ["Target"]=npc,
        ["Target Index"]=target_index,
        ["Category"]=0,
        ["Param"]=0,
        ["_unknown1"]=0})
		packets.inject(packet)
	end
end

function sparks_packet(obj)
    local zone = windower.ffxi.get_info().zone
    local menuid = valid_spark_zones[zone].menu

    local packet = packets.new('outgoing', 0x05B)
    packet["Target"] = obj['Target']
    packet["Option Index"]=obj["Option Index"]
    packet["_unknown1"]=obj["_unknown1"]
    packet["Target Index"]=obj["Target Index"]
    packet["Automated Message"]=true
    packet["_unknown2"]=0
    packet["Zone"]=zone
    packet["Menu ID"]=menuid
    packets.inject(packet)
    
    local packet = packets.new('outgoing', 0x05B)
    packet["Target"] = obj['Target']
    packet["Option Index"]=0
    packet["_unknown1"]=16384
    packet["Target Index"]=obj["Target Index"]
    packet["Automated Message"]=false
    packet["_unknown2"]=0
    packet["Zone"]=zone
    packet["Menu ID"]=menuid
    packets.inject(packet)
    
    local packet = packets.new('outgoing', 0x016, {["Target Index"]=obj['me'],})
	packets.inject(packet)
end

function exit_sparks()
    local zone = windower.ffxi.get_info().zone
    local menuid = valid_spark_zones[zone].menu
    local me = 0
    local target_index = 0
    local target_id = 0
	if valid_spark_zones[zone] then
		for i,v in pairs(get_marray()) do
            if v['name'] == valid_spark_zones[zone].npc then
				target_index = v['index']
				target_id = v['id']
            elseif v['name'] == windower.ffxi.get_player().name then
                me = v['index']
            end
        end
    end

    local packet = packets.new('outgoing', 0x05B)
    packet["Target"] = target_id
    packet["Option Index"]=0
    packet["_unknown1"]=16384
    packet["Target Index"]=target_index
    packet["Automated Message"]=false
    packet["_unknown2"]=0
    packet["Zone"]=zone
    packet["Menu ID"]=menuid
    packets.inject(packet)

    local packet = packets.new('outgoing', 0x016, {["Target Index"]=me,})
    packets.inject(packet)
end

function get_marray(--[[optional]]name)
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
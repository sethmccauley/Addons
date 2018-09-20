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
_addon.command = 'ns'

require('tables')
require('logger')
packets = require('packets')
db = require('map')
res_items = require('resources').items


valid_zones = T{
	[256] = {npc="Eternal Flame", menu=5081}, -- Western Adoulin
	[230] = {npc="Rolandienne", menu=995}, -- Southern San d'Oria
	[235] = {npc="Isakoth", menu=26}, -- Bastok Markets
	[241] = {npc="Fhelm Jobeizat", menu=850}, -- Windurst Woods
	[288] = {npc="Affi", menu=9701},  -- Escha Zitah
	[289] = {npc="Dremi", menu=9701},  -- Escha RuAun
	[291] = {npc="Shiftrix", menu=9701},  -- Reisenjima
}
item = ''
current_sparks = 0
purchase_queue = T{}

windower.register_event('load', function()
	get_spark_update()
end)

windower.register_event('addon command', function (command, ...)
	command = command and command:lower()
	local args = T{...}
	item = table.concat(args," "):lower()
	
	ki = 0
	if command == 'buy' then
		if not busy then
			pkt = validate(item)
			if pkt then
				busy = true
				notice('Buying '..item..'.')
				poke_npc(pkt['Target'],pkt['Target Index'])
			else 
				Warning("Can't find item in menu.")
			end
		else
			notice("Still buying last item.")
		end
		return
	end
	
	if command == 'buyall' then
		pkt = validate(item)
		local purchasable = math.floor(current_sparks/pkt.Cost)
		local currentzone = windower.ffxi.get_info()['zone']
		
		if currentzone == 241 or currentzone == 230 or currentzone == 235 or currentzone == 256 then 
			count_inv()
			tobuy = 0
			
			if purchasable > freeslots then
				notice("You have "..freeslots.." free slots, buying "..item.. " until full.")
				tobuy = freeslots
			else
				notice("You have sparks to purchase: "..purchasable..".")
				tobuy = purchasable
			end
			
			for i=1,tobuy do
				table.append(purchase_queue, item);
			end
		else 
			notice("You are not currently in a zone with a sparks NPC.")
		end
		return
	end
end)

windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
	if id == 0x020 then
		local p = packets.parse('incoming',data)
		local itemID = p['Item']
		if (itemID > 0) then
			local foundItem = res_items[itemID]
			if (foundItem) then
				if purchase_queue and (purchase_queue[1] = foundItem.en) or (purchase_queue[1] = foundItem.enl)
                    item_received = true
                    table.remove(purchase_queue, 1)
                end
			end
		end
	end

	if id == 0x034 or id == 0x032 then
		if busy == true and pkt then
			local packet = packets.new('outgoing', 0x05B)
			-- request item
			packet["Target"]=pkt['Target']
			if npc_name ~= 'Dremi' and npc_name ~= 'Affi' and npc_name ~= 'Shiftrix' then
				packet["Option Index"]=pkt['Option Index']
				packet["_unknown1"]=pkt['_unknown1']
				packet["Target Index"]=pkt['Target Index']
				packet["Automated Message"]=true
				packet["_unknown2"]=0
				packet["Zone"]=pkt['Zone']
				packet["Menu ID"]=pkt['Menu ID']
				packets.inject(packet)

				local packet = packets.new('outgoing', 0x05B)
				packet["Target"]=pkt['Target']
				packet["Option Index"]=0
				packet["_unknown1"]=16384
				packet["Target Index"]=pkt['Target Index']
				packet["Automated Message"]=false
				packet["_unknown2"]=0
				packet["Zone"]=pkt['Zone']
				packet["Menu ID"]=pkt['Menu ID']
				packets.inject(packet)
			else  -- Reisenjima Controls
				packet["Option Index"]=pkt['Option Index']
				packet["_unknown1"]=pkt['_unknown1']
				packet["Target Index"]=pkt['Target Index']
				packet["Automated Message"]=true
				packet["_unknown2"]=0
				packet["Zone"]=pkt['Zone']
				packet["Menu ID"]=pkt['Menu ID']
				packets.inject(packet)
				if ki == 0 then
					packet["Target"]=pkt['Target']
					packet["Option Index"]=14
					packet["_unknown1"]=pkt['_unknown1']
					packet["Target Index"]=pkt['Target Index']
					packet["Automated Message"]=true
					packet["_unknown2"]=0
					packet["Zone"]=pkt['Zone']
					packet["Menu ID"]=pkt['Menu ID']
					packets.inject(packet)
				elseif ki == 1 then 
					packet["Target"]=pkt['Target']
					packet["Option Index"]=3
					packet["_unknown1"]=pkt['_unknown1']
					packet["Target Index"]=pkt['Target Index']
					packet["Automated Message"]=true
					packet["_unknown2"]=0
					packet["Zone"]=pkt['Zone']
					packet["Menu ID"]=pkt['Menu ID']
					packets.inject(packet)
				end 
				-- send exit menu
				packet["Target"]=pkt['Target']
				packet["Option Index"]=0
				packet["_unknown1"]=pkt['_unknown1']
				packet["Target Index"]=pkt['Target Index']
				packet["Automated Message"]=false
				packet["_unknown2"]=0
				packet["Zone"]=pkt['Zone']
				packet["Menu ID"]=pkt['Menu ID']
				packets.inject(packet)
			end
			local packet = packets.new('outgoing', 0x016, {["Target Index"]=pkt['me'],})
			packets.inject(packet)
			busy = false
			pkt = {}
			return true
		end
	end
	if id == 0x110 then -- Update Current Sparks via 110
		local header, value1, value2, Unity1, Unity2, Unknown = data:unpack('II')
		current_sparks = value1
	end
end)

function purchase_item(item)
    if tobuy and tobuy%5 == 0 then
        notice('Buying item: '..item..' #'..tobuy)
    end
	if not busy then
		pkt = validate(item)
		if pkt then
			busy = true
			poke_npc(pkt['Target'], pkt['Target Index'])
            tobuy = tobuy - 1
		else
			notice('Cant find item in menu.')
		end
	else
		notice('Still buying last item.')
	end
end

function validate(item)
	local zone = windower.ffxi.get_info()['zone']
	local me,target_index,target_id,distance
	local result = {}

	if valid_zones[zone] then
		for i,v in pairs(windower.ffxi.get_mob_array()) do
			if v['name'] == windower.ffxi.get_player().name then
				result['me'] = i
			elseif v['name'] == valid_zones[zone].npc then
				target_index = i
				target_id = v['id']
				npc_name = v['name']
				result['Menu ID'] = valid_zones[zone].menu
				distance = windower.ffxi.get_mob_by_id(target_id).distance
			end
		end

		if math.sqrt(distance)<6 then
			local ite = fetch_db(item)
			if ite then
				result['Target'] = target_id
				result['Option Index'] = ite['Option']
				result['_unknown1'] = ite['Index']
				result['Target Index'] = target_index
				result['Zone'] = zone
				result['Cost'] = ite['Cost']
			end
		else
		windower.add_to_chat(10,"Too far from npc")
		end
	else
	windower.add_to_chat(10,"Not in a zone with sparks npc")
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

function sparks_packet(option_index, target_index, item, msg)
    local zone = windower.ffxi.get_info().zone
    local packet = packets.new('outgoing', 0x05B)
    local menuid = valid_zones[zone].menu
    
    packet["Option Index"]=option_index
    packet["_unknown1"]=pkt['_unknown1']
    packet["Target Index"]=target_index
    packet["Automated Message"]=msg
    packet["_unknown2"]=0
    packet["Zone"]=zone
    packet["Menu ID"]=menuid
    packets.inject(packet)
end

function item_count(id)
	local count = 0
	local items = windower.ffxi.get_items().inventory
	for _,v in pairs(items) do
		if type(v) == "table" then
			for k,value in pairs(v) do
				if value == id then
					count = count +1
				end
			end
		end
	end
	return count
end

function check_que(item)
    local ind = purchase_queue:find(item)
    if ind then
        table.remove(purchase_queue, ind)
    end
    if purchase_queue[1] then
        return purchase_item(purchase_queue[1])
    else
        print('Buying Finished')
    end
end
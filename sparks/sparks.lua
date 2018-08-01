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

_addon.name = 'Sparks'
_addon.author = 'Langly - Brax/Sammeh'
_addon.version = '8.1.2018'
_addon.command = 'sparks'

require('tables')
require('chat')
require('logger')
require('functions')
packets = require('packets')
db = require('map')
res_items = require('resources').items

npc_name = ""
pkt = {}
all_temp_items = {}
current_temp_items = {}
purchase_queue = T{}
current_sparks = 0
local_timer = 0
send_timer = 0
item_received = true
busy = false
item = ""


valid_zones = T{
	[256] = {npc="Eternal Flame", menu=5081}, -- Western Adoulin
	[230] = {npc="Rolandienne", menu=995}, -- Southern San d'Oria
	[235] = {npc="Isakoth", menu=26}, -- Bastok Markets
	[241] = {npc="Fhelm Jobeizat", menu=850}, -- Windurst Woods
	[288] = {npc="Affi", menu=9701},  -- Escha Zitah
	[289] = {npc="Dremi", menu=9701},  -- Escha RuAun
	[291] = {npc="Shiftrix", menu=9701},  -- Reisenjima
}

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

	if command == 'buyki' then
		if not busy then
			ki = 1
			pkt = validate(item)
			if pkt then
				busy = true
				poke_npc(pkt['Target'],pkt['Target Index'])
			else 
				notice("Can't find item in menu.")
			end
		else
			notice("Still buying last item.")
		end
		return
	end
	
	if command == 'find' then
		table.vprint(fetch_db(item))
		return
	end
	
	if command == 'buyalltemps' then
		local currentzone = windower.ffxi.get_info()['zone']
		if currentzone == 291 or currentzone == 289 or currentzone == 288 then 
			find_current_temp_items()
			find_missing_temp_items()
			number_of_missing_items = 0
			for countmissing,countitems in pairs(missing_temp_items) do
			    number_of_missing_items = number_of_missing_items +1
			end
			warning('Number of Missing Items: '..number_of_missing_items)
			if number_of_missing_items ~= 0 then 
				for keya,itema in pairs(missing_temp_items) do
					for keyb,itemb in pairs(db) do
						if itemb.TempItem == 1 then
							if keyb == itema then
								local item = itemb.Name:lower()
								warning('Buying Temp Item:'..item)
								if not busy then
									pkt = validate(item)
									if pkt then
										busy = true
										poke_npc(pkt['Target'],pkt['Target Index'])
									else 
										notice("Can't find item in menu")
									end
								else
									notice("Still buying last item")
								end
								sleepcounter = 0
								while busy and sleepcounter < 5 do
									coroutine.sleep(1)
									sleepcounter = sleepcounter + 1
									if sleepcounter == "4" then
										notice("Probably lost a packet, waited too long!")
									end
								end
							end
						end
					end
				end
			end
		else 
		  warning('You are not in a Gaes Fete Area')
		end
		return
	end
	
	if cmd == 'listtemp' then
		local currentzone = windower.ffxi.get_info()['zone']
		if currentzone == 291 or currentzone == 289 or currentzone == 288 then 
			find_current_temp_items()
			find_missing_temp_items()
			number_of_missing_items = 0
			for countmissing,countitems in pairs(missing_temp_items) do
			    number_of_missing_items = number_of_missing_items +1
			end
			warning('Number of Missing Items: '..number_of_missing_items)
		else 
			warning('You are not in a Gaes Fete Area')
		end
		return
	end
	
	if cmd == 'listki' then
		find_missing_ki()
		for id,ki in pairs(missing_ki) do
			warning("Missing KI:"..ki)
		end
	end
	
	if cmd == 'reset' then
		reset_me()
		return
	end
	
	if cmd == 'buyallki' then
		local currentzone = windower.ffxi.get_info()['zone']
		if currentzone == 291 or currentzone == 289 or currentzone == 288 then 
			find_missing_ki()
			number_of_missing_items = 0
			for countmissing,countitems in pairs(missing_ki) do
			    number_of_missing_items = number_of_missing_items +1
			end
			warning('Number of Missing Items: '..number_of_missing_items)
			if number_of_missing_items ~= 0 then 
				for keya,itema in pairs(missing_ki) do
					for keyb,itemb in pairs(db) do
						if itemb.TempItem == 2 then
							if itemb.Name:lower() == itema:lower() then
								local item = itemb.Name:lower()
								warning('Buying Temp Item:'..item)
								if not busy then
									pkt = validate(item)
									if pkt then
										busy = true
										poke_npc(pkt['Target'],pkt['Target Index'])
									else 
										notice("Can't find item in menu")
									end
								else
									notice("Still buying last item")
								end
								sleepcounter = 0
								while busy and sleepcounter < 5 do
									coroutine.sleep(1)
									sleepcounter = sleepcounter + 1
									if sleepcounter == "4" then
										notice("Probably lost a packet, waited too long!")
									end
								end
							end
						end
					end
				end
			end
		else 
		  warning('You are not in a Gaes Fete Area')
		end
		return
	end
	
	if command == 'test' then
		notice(table.length(purchase_queue))
		notice('Busy : '..tostring(busy))
		notice('Item_recieved : '..tostring(item_received))
		notice('Send: '..send_timer..'   Local: '..local_timer)
	end
end)

function count_inv()
	local playerinv = windower.ffxi.get_items().inventory
	freeslots = playerinv.max - playerinv.count
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

function find_all_tempitems()
	for i,v in pairs(db) do
		if v.TempItem == 1 then
			all_temp_items[#all_temp_items+1] = i
		end
	end
end

function get_spark_update()
	local packet = packets.new('outgoing', 0x117, {["_unknown2"]=0})
	packets.inject(packet)
end

function find_current_temp_items()
	count = 0
	current_temp_items = {}
	tempitems = windower.ffxi.get_items().temporary
	for key,item in pairs(tempitems) do
		if key ~= 'max' and key ~= 'count'  and key ~= 'enabled' then
			for ida,itema in pairs(item) do
				if itema ~= 0 and ida == 'id' then 
					count = count + 1
					current_temp_items[#current_temp_items+1] = itema
				end
			end
		end
	end
end

function find_missing_temp_items()
	missing_temp_items = {}
	for key,item in pairs(all_temp_items) do
		itemmatch = 0
		for keya,itema in pairs(current_temp_items) do
			if item == itema then
				itemmatch = 1
			end
		end
		if itemmatch == 0 then
			missing_temp_items[#missing_temp_items+1] = item
		end
	end
end

function find_missing_ki()
	missing_ki = {}
	found_mollifier = 0
	found_radialens = 0
	found_tribulens = 0
	local keyitems = windower.ffxi.get_key_items()
	for id,ki in pairs(keyitems) do
		if ki == 3032 then
			found_mollifier = 1
		elseif ki == 3031 then
			found_radialens = 1
		elseif ki == 2894 then
			found_tribulens = 1
		end
	end
	if found_mollifier == 0 then
		missing_ki[#missing_ki+1] = "mollifier"
	end
	if found_tribulens == 0 then
		missing_ki[#missing_ki+1] = "tribulens"
	end
	if found_radialens == 0 then
		missing_ki[#missing_ki+1] = "radialens"
	end
end

windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
	if id == 0x020 then
		local p = packets.parse('incoming',data)
		local itemID = p['Item']
		if (itemID > 0) then
			local foundItem = res_items[itemID]
			if (foundItem) then
				local itemName = foundItem.en
				item_received = true
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

windower.register_event('load', function()
	find_all_tempitems()
	get_spark_update()
end)

windower.register_event('prerender', function()
	if table.length(purchase_queue) > 0 then
		send_timer = os.clock() - local_timer
		if send_timer >= 1.1 then
			if item_received then
				item_received = false
				purchase_item(purchase_queue[1])
				table.remove(purchase_queue, 1)
			end
			local_timer = os.clock()
		end
	else
		local_timer = os.clock()
	end
end)

function purchase_item(item)
	notice('Buying item: '..item..' #'..tobuy)
	if not busy then
		pkt = validate(item)
		if pkt then
			busy = true
			poke_npc(pkt['Target'], pkt['Target Index'])
			tobuy = tobuy - 1
		else
			notice('Cant find item in menu.')
		end;
	else
		notice('Still buying last item.')
	end;
end;

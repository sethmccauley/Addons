--[[

Copyright © 2017, Langly of Quetzalcoatl
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

_addon.name = 'AutoSparks'
_addon.author = 'Langly@Quetz'
_addon.version = '1.11.29.2017'
_addon.language = 'English'
_addon.commands = {'autosparks', 'as'}

packets = require('packets')
pack = require('pack')
config = require('config')
res = require('resources')
texts = require('texts')

----------------------
-- Set Globals
----------------------
if windower.ffxi.get_player() then 
	player = windower.ffxi.get_player()
	world = windower.ffxi.get_info()
	current_zone = res.zones[world.zone].en
	current_sparks = 0
	busy = false
	status = nil
	runtarget = {}
	last_task = nil
	running = false
end

--NPCs and NavPoints for W.Adoulin
npc = {sparks = {id = 17826103, name="Eternal Flame", x=13.5, y=-121, z=0, zone=256},
		shop = {id = 17826074, name="Defliaa", x=44, y=-118, z=0, index=282, zone=256},
		midpoint = {id = 0, name="midpoint_1", x=24, y=-120, z=0, zone=256},
		accolade = {id = 17826181, name="Nunaarl Bthtrogg", x=14, y=-111, z=0, index=389, menuid=5149, zone=256},
		portal = {id = 17195620, name="Dimensional Portal", x=0, y=0, z=0, index=612, menuid=222},
		ingress = {id = 17969975, name="Ethereal Ingress #1", x=-495, y=-477, z=0, index=823}
	}

--------------------------------
-- Set text Object
--------------------------------
statustext = texts.new('${Player|(None)} in ${PlayerZone|(None)} has ${Sparks|0}/99,999 Sparks. Status: ${Status|None}. Busy: ${busy|false}.', {text = {size = 10}})
statustext.Player = player.name
statustext.PlayerZone = current_zone
statustext.Sparks = 0
statustext.Status = status
statustext.busy = busy
statustext:show()

--------------------------------
-- Load / Packet Parser / Cmds
--------------------------------
windower.register_event('load', function()
	get_spark_update()
	windower.send_command("lua load sellnpc")
	windower.send_command("lua load sparks")
end)

windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
    if id == 0x113 then -- Update Current Sparks via 113
        local p = packets.parse('incoming',data)
		statustext.Sparks,current_sparks = p['Sparks of Eminence'],p['Sparks of Eminence']
    end
    if id == 0x110 then -- Update Current Sparks via 110
		local header, value1, value2, Unity1, Unity2, Unknown = data:unpack('II')
		statustext.Sparks,current_sparks = value1,value1
		--windower.send_command("input /p Total Sparks: "..value1..".")
	end
	if id == 0x00A then -- Update Current Zone via 00A
		local p = packets.parse('incoming',data)
		statustext.PlayerZone,current_zone = res.zones[p['Zone']].en,res.zones[p['Zone']].en
	end
	if id == 0x034 or id == 0x032 then -- Enter Reisenjima (NO VALIDATION)
		if current_zone == "La Theine Plateau" then
			local packet = packets.new('outgoing', 0x05B)
			packet["Option Index"]= 0
			packet["_unknown1"]= 0
			packet["Target Index"]= npc.portal.index
			packet["Automated Message"]= true
			packet["_unknown2"]= 0
			packet["Zone"]= 102
			packet["Menu ID"]= 222
			packets.inject(packet)

			packet["Target"]=npc.portal.id
			packet["Option Index"]=2
			packet["_unknown1"]=0
			packet["Target Index"]=npc.portal.index
			packet["Automated Message"]=true
			packet["_unknown2"]=0
			packet["Zone"]=102
			packet["Menu ID"]=222
			packets.inject(packet)

			packet["Target"]=npc.portal.id
			packet["Option Index"]=2
			packet["_unknown1"]=0
			packet["Target Index"]=npc.portal.index
			packet["Automated Message"]=false
			packet["_unknown2"]=0
			packet["Zone"]=102
			packet["Menu ID"]=222
			packets.inject(packet)
			local packet = packets.new('outgoing', 0x016, {["Target Index"]=player.index,})
			packets.inject(packet)
		end
		if current_zone == "Western Adoulin" and status == "Keying" then
			local packet = packets.new('outgoing', 0x05B)
			packet["Option Index"]= 10
			packet["_unknown1"]= 0
			packet["Target Index"]= npc.accolade.index
			packet["Automated Message"]= true
			packet["_unknown2"]= 0
			packet["Zone"]= 256
			packet["Menu ID"]= 5149
			packets.inject(packet)

			packet["Target"]=npc.accolade.id
			packet["Option Index"]=35
			packet["_unknown1"]=0
			packet["Target Index"]=npc.accolade.index
			packet["Automated Message"]=true
			packet["_unknown2"]=0
			packet["Zone"]=256
			packet["Menu ID"]=5149
			packets.inject(packet)

			packet["Target"]=npc.accolade.id
			packet["Option Index"]=49188
			packet["_unknown1"]=0
			packet["Target Index"]=npc.accolade.index
			packet["Automated Message"]=true
			packet["_unknown2"]=0
			packet["Zone"]=256
			packet["Menu ID"]=5149
			packets.inject(packet)
			
			packet["Target"]=npc.accolade.id
			packet["Option Index"]=49188
			packet["_unknown1"]=0
			packet["Target Index"]=npc.accolade.index
			packet["Automated Message"]=false
			packet["_unknown2"]=0
			packet["Zone"]=256
			packet["Menu ID"]=5149
			packets.inject(packet)
			local packet = packets.new('outgoing', 0x016, {["Target Index"]=player.index,})
			packets.inject(packet)
			unbusy()
		end
	end
end)

windower.register_event('addon command', function (command, ...)
	command = command and command:lower()
	local args = T{...}
	if command == "test" then

	end
	if command == "start" then
		windower.add_to_chat(10, "Hit Start Command")
		running = true
		status = "Starting"
		Engine()
	end
	if command == "stop" then
		running = false
		status = "Stopping"
		busy = false
		windower.add_to_chat(10, "Hit Stop Command")
	end
end)

function debugthis()

end

--------------------------------
-- Buying/Selling + Helpers
--------------------------------

function poke_npc(id, index)
	if id and index then
		local packet = packets.new('outgoing', 0x01A, {
			["Target"]=id,
			["Target Index"]=index,
			["Category"]=0,
			["Param"]=0,
			["_unknown1"]=0})
		packets.inject(packet)
	end
end

function sellnpc_acheron()
	busy = true
	windower.send_command("sellnpc Acheron Shield")
	status = "Selling"
end

function sparks_buyall()
	busy = true
	windower.send_command("sparks buyall Acheron Shield")
	status = "Buying"
end

function buy_keys()
	busy = true
	status = "Keying"
	poke_npc(npc.accolade.id, npc.accolade.index)
end

function inventory_space()
	local inventory = windower.ffxi.get_bag_info(0)
	local free = inventory.max - inventory.count
	return free
end

function shield_count()
	local count = 0
	local items = windower.ffxi.get_items(res.bags:with('english', 'Inventory').id)
	for _,v in pairs(items) do
		if type(v) == "table" then
			for k,value in pairs(v) do
				if value == 12385 then
					count = count +1
				end
			end
		end
	end
	return count
end

--------------------------------
-- Navigators
--------------------------------

-- Run to Target
function runto(target)
	busy = true
	runtarget.x = target.x
	runtarget.y = target.y
	local self_vector = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0)
	local angle = (math.atan2((target.y - self_vector.y), (target.x - self_vector.x))*180/math.pi)*-1
	windower.ffxi.run((angle):radian())
end

-- Check Distance for the Observer
function distance(x, y)
	local self_vector = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0)
	local dx = x - self_vector.x
	local dy = y - self_vector.y
	return math.sqrt(dx*dx + dy*dy)
end

-- Zone Change Observer
windower.register_event('Zone Change', function()
	status = "Zoned"
	coroutine.schedule(unbusy, 7)
end)

function unbusy()
	busy = false
end

function teleport_ring()
	if status ~= "Teleporting" then
		-- ToDo: Setup test to ensure ring recast is ready, if not to wait, and if ring not equipped to send command to equip ring and gs disable + wait
		busy = true
		windower.send_command('input /item "Dim. Ring (Holla)" <me>')
	end
	status = "Teleporting"
end

function warp()
	if status ~= "Warping" then
		if player.main_job == "BLM" or player.sub_job == "BLM" then
			busy = true
			windower.send_command('input /ma "Warp" <me>')
		else
			-- ToDo: Setup test to ensure ring recast is ready, if not to wait, and if ring not equipped to send command to equip ring and gs disable + wait
			busy = true
			windower.send_command('input /item "Warp Ring" <me>')
		end
	end
	status = "Warping"
end

function hp_warp()
	local zone = statustext.PlayerZone
	if zone ~= "Western Adoulin" and status ~= "HPWarping" then
		for i,v in pairs(windower.ffxi.get_mob_array()) do
			if string.find(v['name'],'Home Point') then
				local distance = windower.ffxi.get_mob_by_id(v['id']).distance
				if math.sqrt(distance)<6 then
					busy = true
					windower.send_command("hp warp Western Adoulin 2")
					status = "HPWarping"
				else
					break
				end
			end
		end
	end
end

function enter_reisen()
	-- Enter Reisen from La Theine Plateau
	if current_zone == "La Theine Plateau" and status == "Zoned" then
		for i,v in pairs(windower.ffxi.get_mob_array()) do
			if string.find(v['name'],'Dimensional Portal')then
				busy = true
				poke_npc(npc.portal.id, npc.portal.index)
				
				local packet = packets.new('outgoing', 0x05B)
				packet["Target"]= 17195620
				packet["Option Index"]= 0
				packet["_unknown1"]= 0
				packet["Target Index"]= 612
				packet["Automated Message"]= true
				packet["_unknown2"]= 0
				packet["Zone"]= 102
				packet["Menu ID"]= 222
				packets.inject(packet)
				
				local packet = packets.new('outgoing', 0x05B)
				packet["Target"]= 17195620
				packet["Option Index"]= 0
				packet["_unknown1"]= 0
				packet["Target Index"]= 612
				packet["Automated Message"]= true
				packet["_unknown2"]= 0
				packet["Zone"]= 102
				packet["Menu ID"]= 222
				packets.inject(packet)
				
				local packet = packets.new('outgoing', 0x05B)
				packet["Target"]= 17195620
				packet["Option Index"]= 2
				packet["_unknown1"]= 0
				packet["Target Index"]= 612
				packet["Automated Message"]= false
				packet["_unknown2"]= 0
				packet["Zone"]= 102
				packet["Menu ID"]= 222
				packets.inject(packet)
			end
		end
	end
end

-- Main Observer: Stops running actions when target hit / modifies status when necessary
windower.register_event('prerender', function()
	if next(runtarget) ~= nil then
		status = "Running"
		if distance(runtarget.x, runtarget.y) < 2 then
			windower.ffxi.run(false)
			runtarget = {}
			unbusy()
			status = "Idle"
		end
	end
	if statustext.Status ~= status then
		statustext.Status = status
	end
	if statustext.busy ~= busy then
		statustext.busy = busy
	end
	if status == "Buying" then -- Watch for the last possible shield purchase
		local free = inventory_space()
		local shields = shield_count()
		if free == 0 or shields == 36 then
			status = "Idle"
			unbusy()
		end
	end
	if status == "Selling" then -- Watch for the last shield sale
		local shields = shield_count()
		if shields == 0 then
			status = "Idle"
			unbusy()
		end
	end
	if status == "Gaining" then
		if tonumber(current_sparks) > 99180 then
			status = "ToAdoulin"
		end
	end
end)

--------------------------------
-- Engine
--------------------------------

function Engine()
	determine_status()
	
	if status == "ToReisen" then -- Get to Reisenjima via La Theine Plateau
		if current_zone ~= "La Theine Plateau" then
			if busy == false then
				teleport_ring()
			end
		end
	elseif status == "ToAdoulin" then -- Get to Adoulin
		if current_zone == "Reisenjima" then
			if busy == false then
				warp()
			end
		end
	elseif status == "Zoned" then -- Zone Action Follow Ups
		if current_zone == "La Theine Plateau" then -- We just zoned into La Theine, enter the portal.
			if busy == false then
				enter_reisen()
			end
		elseif current_zone == "Western Adoulin" then -- We just zoned into Adoulin, run to Sparks NPC
			if busy == false then
				runto(npc.sparks)
			end
		elseif current_zone == "Reisenjima" then -- We just zoned in, run to Ingress to appear like we're not horrible cheaters
			if busy == false then
				runto(npc.ingress)
			end
		else
			if busy == false then
				hp_warp()
			end
		end
	elseif status == "Idle" then -- Idle Only Occurs after a runto completed
		if current_zone == "Western Adoulin" then
			local free = inventory_space()
			local shields = shield_count()
			if tonumber(current_sparks) > 2755 and free > 0 then
				for i,v in pairs(windower.ffxi.get_mob_array()) do
					if string.find(v['name'],'Eternal Flame') then
						local distance = windower.ffxi.get_mob_by_id(v['id']).distance
						if math.sqrt(distance) < 6 then
							sparks_buyall()
						else
							runto(npc.sparks)
						end
					end
				end
			elseif status ~= "Buying" and shields > 0 then
				for i,v in pairs(windower.ffxi.get_mob_array()) do
					if string.find(v['name'],'Defliaa') then
						local distance = windower.ffxi.get_mob_by_id(v['id']).distance
						if math.sqrt(distance) < 6 then
							poke_npc(npc.shop.id, npc.shop.index)
							coroutine.schedule(sellnpc_acheron, 2)
							status = "Selling"
							busy = true
						else
							if busy == false then
								runto(npc.shop)
							end
						end
					end
				end
			elseif tonumber(current_sparks) < 2755 and shields == 0 then
				local distance = windower.ffxi.get_mob_by_id(npc.shop.id).distance
				local distance2 = windower.ffxi.get_mob_by_id(npc.accolade.id).distance
				if math.sqrt(distance) < 6 and busy == false then
					runto(npc.midpoint)
				elseif math.sqrt(distance2) > 6 and busy == false then
					runto(npc.accolade)
				elseif math.sqrt(distance2) < 6 and busy == false  then
					if status ~= "Keying" and busy == false then
						buy_keys()
					else
						status = "ToReisen"
					end
				end
			end
		elseif current_zone == "Reisenjima" then
			for i,v in pairs(windower.ffxi.get_mob_array()) do
				if string.find(v['name'],'Ethereal Ingress #1') then
					local distance = windower.ffxi.get_mob_by_id(v['id']).distance
					if math.sqrt(distance) < 6 then
						windower.send_command("pt point gainexp")
					elseif tonumber(current_sparks) < 99180 then
						status = "Gaining"
					end
				end
			end
		end
	end
	if running == true then
		coroutine.schedule(Engine,1)
	end
end

function determine_status()
	local shields = shield_count()
	if status == "Starting" then -- When //as start determine where we need to go
		if tonumber(current_sparks) > 99180 then
			if current_zone == "Western Adoulin" then
				status = "Idle"
			else
				status = "ToAdoulin"
			end
		else
			if shields > 0 then
				status = "Idle"
			else
				if current_zone == "Reisenjima" then
					status = "Idle"
				else
					status = "ToReisen"
				end
			end
		end
	end
end

function get_spark_update()
	local packet = packets.new('outgoing', 0x117, {["_unknown2"]=0})
	packets.inject(packet)
end
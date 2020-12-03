--[[
Copyright © 2018, Bolteux of Quetzalcoatl
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
DISCLAIMED. IN NO EVENT SHALL Bolteux BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANhw3Y THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'BuyCells'
_addon.author = 'Bolteux'
_addon.version = '1.0'
_addon.date = '10.13.2018'
_addon.commands = {'Buycells','bc'}

require('tables')
require('logger')
packets = require('packets')

status = 'none'

windower.register_event('addon command', function (command, ...)
    command = command and command:lower()
    local args = T{...}
    
    if command == 'rubicund' then
        status = 'rubicund'
        local officer = pick_nearest(get_marray('Voidwatch Officer'))
        if officer[1].distance:sqrt() < 6 then
            poke_npc(officer[1].id,officer[1].index)
        else
            warning('Not close enough to a Voidwatch Officer. Cancelling')
        end
    end
    
end)

windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
    if id == 0x034 and status == 'rubicund' then
        local officer = pick_nearest(get_marray('Voidwatch Officer'))
        if officer[1].distance:sqrt() < 6 then
            local p = packets.parse('incoming', data)
            local zone = p['Zone']
            local id = p['NPC']
            local index = p['NPC Index']
            local menu_id = p['Menu ID']
            
            local packet = packets.new('outgoing', 0x05B, {
                ["Target"] = id,
                ["Target Index"] = index,
                ["_unknown1"] = 770,
                ["Automated Message"] = false,
                ["_unknown2"] = 0,
                ["Option Index"] = 2,
                ["Menu ID"]=menu_id,
                ["Zone"]=zone,})
            packets.inject(packet)
            player_update()
            status = 'none'
            return true
        else
            warning('Aborting. Get closer to the VW Officer.')
        end
    end
end)

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

function pick_nearest(--[[optional]]mob_table)
    local dist_target = 0
    local closest_key = 0
    local marray = mob_table or get_marray()
    local new_marray = T{}
    
    for k,v in pairs(marray) do
        if dist_target == 0 then
            closest_key = k
            dist_target = math.sqrt(v['distance'])
        elseif math.sqrt(v['distance']) < dist_target then
            closest_key = k
            dist_target = math.sqrt(v['distance'])
        end
    end

    for k,v in pairs(marray) do
        if k == closest_key then
            new_marray[1] = v
        end
    end
    
    return new_marray
end

function player_update()
    local packet = packets.new('outgoing', 0x016, {["Target Index"]=windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).index,})
    packets.inject(packet)
end
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

_addon.name = 'gobbie'
_addon.author = 'Langly'
_addon.version = '1.0'
_addon.date = '9.20.2018'
_addon.language = 'English'
_addon.commands = {'gobbie'}

packets = require('packets')
res = require('resources')
require('logger')
require('tables')

NPCs = T{'habitox', 'mystrix', 'bountibox', 'specilox', 'arbitrix', 'funtrox', 'sweepstox', 'priztrix', 'wondrix', 'rewardox', 'winrix' }
Keys = T{ 9274, 9217, 8973 }

-- CURRENT TOTAL OF KEYS
AB_Keys = 0
SP_Keys = 0
ANV_Keys = 0

continue = false

windower.register_event('addon command', function(...)
	local args = T{...}
	local cmd = args[1]
	if cmd then 
		if cmd:lower() == 'start' then
            continue = true
            get_key_count()
            notice('Starting trades for: '..SP_Keys..' SP Keys; '..AB_Keys..' AB Keys; '..ANV_Keys..' #ANV Keys.')
            trade_gobbie()
        end
        if cmd:lower() == 'stop' then
            continue = false
        end
    end
    return
end)

function trade_gobbie()
    if continue and (AB_Keys > 0 or SP_Keys > 0 or ANV_Keys > 0) then
        local goblins = get_marray(NPCs)
        if goblins and goblins[1] and goblins[1].distance:sqrt() < 6 then
            local inv = windower.ffxi.get_items(0)
            local idx = 1
            for index=1,inv.max do
                if type(inv[index]) == 'table' and Keys:contains(inv[index].id) then
                    local trade_packet = packets.new('outgoing', 0x36, {
                    ['Target'] = goblins[1].id,
                    ['Target Index'] = goblins[1].index,
                    ['Item Index %d':format(idx)] = index,
                    ['Item Count %d':format(idx)] = 1,
                    ['Number of Items'] = 1})
                    packets.inject(trade_packet)
                    break
                end
            end
        end
    end
end

windower.register_event('incoming text', function(original, modified, original_mode, modified_mode, blocked)
    if blocked or text == '' then
        return
    end

    local msg = original:lower();
    if msg:find('obtained: ') then
        coroutine.schedule(trade_gobbie, 4)
    end
    get_key_count()
    local keys_left = 0
    keys_left = ANV_Keys + SP_Keys + AB_Keys
    if keys_left == 1 then
        notice('Gobbie Trading Finished.')
    end
end)

function get_key_count()
    local inv = windower.ffxi.get_items(0)
    ANV_Keys = 0
    SP_Keys = 0
    AB_Keys = 0
    for index = 1, inv.max do
        if inv[index].id == 9274 then
            ANV_Keys = ANV_Keys + inv[index].count
        elseif inv[index].id == 9217 then
            AB_Keys = AB_Keys + inv[index].count
        elseif inv[index].id == 8973 then
            SP_Keys = SP_Keys + inv[index].count
        end
    end
end

function get_marray(--[[optional]]names)
	local marray = windower.ffxi.get_mob_array()
	local target_names = T{}
    local new_marray = T{}

    if type(names) == 'table' then 
        for i,v in pairs(names) do
            target_names[i] = {['name'] = v:lower()}
        end
    elseif type(names) == 'string' then target_names = T{['name'] = names and names:lower() or nil} end

	for i,v in pairs(marray) do
		if v.id == 0 or v.index == 0 or v.status == 3 then
			marray[i] = nil
		end
	end
    
    for i,v in pairs(marray) do
        local delete = false
        if not target_names:with('name', v.name:lower()) then
            delete = true
        end
        if delete then
            marray[i] = nil
        end
    end

    for i,v in pairs(marray) do
        new_marray[#new_marray +1] = v
    end
    
	return new_marray
end

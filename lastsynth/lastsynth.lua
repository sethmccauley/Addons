_addon.command = 'lastsynth'

packets = require('packets')
require('chat')


continue = false

windower.register_event('addon command', function(...)
	local args = T{...}
	local cmd = args[1]
	if cmd then 
		if cmd:lower() == 'stop' then
			continue = false
            windower.add_to_chat(3,"Stopping lastsynth.")
            return
		end
        if cmd:lower() == 'start' then
            continue = true
            windower.send_command('input /lastsynth')
            windower.add_to_chat(3,"Starting lastsynth.")
        end
    end
end)

windower.register_event('incoming chunk', function(id, data)
    if continue then
        if id == 0x037 then 
            local update = packets.parse('incoming', data)
            if update.Status == 0 then
                windower.send_command("wait 3;input /lastsynth")
            end
        end
    end
end)

windower.register_event('incoming text', function(original, modified, original_mode, modified_mode, blocked)
    if blocked or text == '' then
        return
    end

	if original:strip_format() == "Synthesis canceled." or original:strip_format() == 'Unable to execute that command. Your inventory is full.' then
		continue = false
	end
end)
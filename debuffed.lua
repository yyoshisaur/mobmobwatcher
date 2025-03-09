local texts = require('texts')

local debuff_text = texts.new({pos={x=500,y=100},padding=1,bg={alpha=64},text={font='MS Gothic', size=10,stroke={width = 2,alpha=144}},flags={bold=true}})
local update_time = os.clock()
local tick = 1/15

local debuff = T{}
local debuffed = {}

local bar_colors = function()
    local colors = L{}
    for i = 1, 10 do
        r = math.floor(255 * (1-(i-1)/9))
        g = math.floor(255 * ((i-1)/9))
        b = 0
        colors:append({red=r, green=g, blue=b})
    end
    return colors
end()

local dispose_bag = DisposeBag.new()

debuffed.init = function(alliance, renderer)
    for p in alliance:get_parties():it() do
        dispose_bag:add(p:get_target_tracker():on_targets_changed():addAction(function(tracker, targets_added, targets_removed)
            for t in targets_added:it() do
                dispose_bag:add(t.debuff_tracker:on_gain_debuff():addAction(function(id, debuff_id)
                    if debuff[id] then
                        if debuff[id][debuff_id] then
                            debuff[id][debuff_id]['gain'] = os.time()
                            debuff[id][debuff_id]['lose'] = nil
                        else
                            debuff[id][debuff_id] = T{}
                            debuff[id][debuff_id]['gain'] = os.time()
                            debuff[id][debuff_id]['lose'] = nil
                        end
                    else
                        debuff[id] = T{}
                        debuff[id][debuff_id] = T{}
                        debuff[id][debuff_id]['gain'] = os.time()
                        debuff[id][debuff_id]['lose'] = nil
                    end
                    IpcRelay.shared():send_message(GainDebuffMessage.new(id, debuff_id))
                end), t.debuff_tracker:on_gain_debuff())

                dispose_bag:add(t.debuff_tracker:on_lose_debuff():addAction(function(id, debuff_id)
                    if debuff[id] then
                        if debuff[id][debuff_id] then
                            debuff[id][debuff_id]['lose'] = os.time()
                            local current_duration = debuff[id][debuff_id]['lose'] - debuff[id][debuff_id]['gain']
                            local last_duration = debuff[id][debuff_id]['duration'] or 0

                            debuff[id][debuff_id]['duration'] = current_duration

                            if last_duration - current_duration > 0 + 1 then
                                debuff[id][debuff_id]['shoter'] = true
                            else
                                debuff[id][debuff_id]['shoter'] = false
                            end
                        end
                    end
                    IpcRelay.shared():send_message(LoseDebuffMessage.new(id, debuff_id))
                end), t.debuff_tracker:on_lose_debuff())

            end
        
            for t in targets_removed:it() do
                if debuff[t:get_id()] then
                    debuff[t:get_id()] = nil
                end
            end
        end), p:get_target_tracker():on_targets_changed())
    end

    dispose_bag:add(renderer.shared():onPrerender():addAction(function()
        local current_time = os.clock()
        if current_time < update_time + tick then return end

        local st = windower.ffxi.get_mob_by_target('st')
        local t =  windower.ffxi.get_mob_by_target('t')
        local bt = windower.ffxi.get_mob_by_target('bt')

        local monitor_target = st or t
        if monitor_target and debuff[monitor_target.id] then
            local d_lines = L{}
            local gain_ids, lose_ids = L{}, L{}

            local hpp_to_text = function(hpp)
                local hpp_level = math.ceil(hpp/10)
                hpp_level = hpp_level < 1 and 1 or hpp_level 
                return '%3d%%':format(hpp):text_color(bar_colors[hpp_level].red, bar_colors[hpp_level].green, bar_colors[hpp_level].blue)
            end

            local debuff_to_text = function(state, id, name, time, duration)
                local gain = '✔':text_color(0, 255, 192)
                local lose = '✖':text_color(255, 0, 96)
                if state == 'gain' then
                    if duration then
                        local expected_remaining_time = duration - time
                        if expected_remaining_time < 0 then
                            name = name:text_color(0, 192, 0)
                        elseif expected_remaining_time < 10 then
                            name = name:text_color(192, 0, 0)
                        elseif expected_remaining_time < 30 then
                            name = name:text_color(255, 128, 0)
                        elseif expected_remaining_time < 60 then
                            name = name:text_color(255, 192, 0)
                        end
                        return string.format('%3d %s %s +%3d [%3d]', id, gain, name, time, duration)
                    else
                        return string.format('%3d %s %s +%3d', id, gain, name, time)
                    end
                elseif state == 'lose' then
                    return string.format('%3d %s %s -%3d [%3d]', id, lose, name, time, duration)
                elseif state == 'shoter_lose' then
                    return string.format('%3d %s %s -%3d [%3d]', id, lose, name:text_color(144, 64, 255), time, duration)
                end
            end

            for k, v in pairs(debuff[monitor_target.id]) do
                if v.lose then
                    lose_ids:append(k)
                else
                    gain_ids:append(k)
                end
            end

            lose_ids:sort(function(a, b) return a < b end)
            gain_ids:sort(function(a, b) return a < b end)

            d_lines:append(string.format('◤ %s %s (%d) ◥', hpp_to_text(monitor_target.hpp), monitor_target.name, monitor_target.index))

            for id in lose_ids:it() do
                local elapsed_time = os.time()-debuff[monitor_target.id][id].lose
                if elapsed_time < 300 then
                    if debuff[monitor_target.id][id].shoter then
                        d_lines:append(debuff_to_text('shoter_lose', id, res.buffs[id].name, elapsed_time, debuff[monitor_target.id][id].duration))
                    else
                        d_lines:append(debuff_to_text('lose', id, res.buffs[id].name, elapsed_time, debuff[monitor_target.id][id].duration))
                    end
                end
            end

            for id in gain_ids:it() do
                d_lines:append(debuff_to_text('gain', id, res.buffs[id].name, os.time()-debuff[monitor_target.id][id].gain, debuff[monitor_target.id][id].duration))
            end

            debuff_text:clear()
            debuff_text:append(d_lines:concat('\n'))
            debuff_text:show()
        else
            debuff_text:clear()
            debuff_text:hide()
        end
        -- table.vprint(action_notifier)
        current_time = update_time
    end), renderer.shared():onPrerender())
end

debuffed.dispose = function()
    IpcRelay.shared():destroy()
    dispose_bag:destroy()
end

return debuffed
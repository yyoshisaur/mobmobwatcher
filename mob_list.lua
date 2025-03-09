local chat = require('chat')
local texts = require('texts')
local mob_list_text = texts.new({pos={x=450,y=500},padding=1,bg={alpha=64},text={font='MS Gothic', size=10,stroke={width = 2,alpha=144}},flags={bold=true}})

local update_time = os.clock()
local tick = 1/15

local mobs = S{}
local mob_list = {}
local target_colors = {
    bt = {red=255, green=0, blue=0},
    t = {red=255, green=192, blue=0},
    st = {red=0, green=192, blue=255},
}
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

mob_list.init = function(alliance, renderer)
    for p in alliance:get_parties():it() do
        dispose_bag:add(p:get_target_tracker():on_targets_changed():addAction(function(tracker, targets_added, targets_removed)
            for t in targets_added:it() do
                if not mobs:contains(t:get_id()) then
                    mobs:add(t:get_id())
                end
            end
            for t in targets_removed:it() do
                if mobs:contains(t:get_id()) then
                    mobs:remove(t:get_id())
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

        if not mobs:empty() then
            local m = L(mobs:copy():map(function(a) return a end))
            local m_lines = L{}

            m:sort(function(a, b)
                local t_a = windower.ffxi.get_mob_by_id(a)
                local t_b = windower.ffxi.get_mob_by_id(b)
                return (t_a and t_a.distance:sqrt() or 0) < (t_b and t_b.distance:sqrt() or 0)
            end)

            local hpp_to_bar_text = function(hpp)                
                local text = ''
                for i=1, 10 do
                    if math.ceil(hpp/10) < i then
                        text = text..'■':text_color(0, 0, 0)
                    else
                        text = text..'■':text_color(bar_colors[i].red, bar_colors[i].green, bar_colors[i].blue)
                    end
                end
                return text
            end
            
            local hpp_to_text = function(hpp)
                local hpp_level = math.ceil(hpp/10)
                hpp_level = hpp_level < 1 and 1 or hpp_level 
                return '%3d':format(hpp):text_color(bar_colors[hpp_level].red, bar_colors[hpp_level].green, bar_colors[hpp_level].blue)
            end

            for mob_id in m:it() do
                local mob = windower.ffxi.get_mob_by_id(mob_id)
                local target_mark = ''

                if bt and bt.id == mob_id then
                    local tc = target_colors.bt
                    target_mark = target_mark..'▼':text_color(tc.red, tc.green, tc.blue)
                end
                if t and t.id == mob_id then
                    local tc = target_colors.t
                    target_mark = target_mark..'▼':text_color(tc.red, tc.green, tc.blue)
                end
                if st and st.id == mob_id then
                    local tc = target_colors.st
                    target_mark = target_mark..'▼':text_color(tc.red, tc.green, tc.blue)
                end

                if bt and bt.id == mob_id then
                    local tc = target_colors.bt
                    m_lines:append('%6.2f %s %s %s(%3d) %s':format(
                        bt.distance:sqrt(),
                        hpp_to_text(bt.hpp),
                        hpp_to_bar_text(bt.hpp),
                        bt.name:text_color(tc.red, tc.green, tc.blue),
                        bt.index,
                        target_mark
                    ))
                elseif t and t.id == mob_id then
                    local tc = target_colors.t
                    m_lines:append('%6.2f %s %s %s(%3d) %s':format(
                        t.distance:sqrt(),
                        hpp_to_text(t.hpp),
                        hpp_to_bar_text(t.hpp),
                        t.name:text_color(tc.red, tc.green, tc.blue),
                        t.index,
                        target_mark
                    ))
                elseif st and st.id == mob_id then
                    local tc = target_colors.st
                    m_lines:append('%6.2f %s %s %s(%3d) %s':format(
                        st.distance:sqrt(),
                        hpp_to_text(st.hpp),
                        hpp_to_bar_text(st.hpp),
                        st.name:text_color(tc.red, tc.green, tc.blue),
                        st.index,
                        target_mark
                    ))
                else
                    if mob then
                        m_lines:append('%6.2f %s %s %s(%3d) %s':format(
                            mob.distance:sqrt(),
                            hpp_to_text(mob.hpp),
                            hpp_to_bar_text(mob.hpp),
                            mob.name,
                            mob.index,
                            target_mark
                        ))
                    end
                end

                if mob and mobs:contains(mob.id) and (mob.hpp <= 0 or not mob.valid_target) then
                    mobs:remove(mob_id)
                end
            end

            mob_list_text:clear()
            mob_list_text:append(m_lines:concat('\n'))
            mob_list_text:show()
        else
            mob_list_text:clear()
            mob_list_text:hide()
        end

    end), renderer.shared():onPrerender())
end

mob_list.dispose = function()
    dispose_bag:destroy()
end

return mob_list

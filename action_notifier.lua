local texts = require('texts')

local action_notifier_conf = require('action_notifier_conf')
local reaction_conf = require('reaction_conf')
-- table.vprint(reaction_conf.reaction)

local action_notifier_text = texts.new({pos={x=100,y=160},padding=1,bg={alpha=64},text={font='MS Gothic', size=12,stroke={width = 3,alpha=255}},flags={bold=true}})
local update_time = os.clock()
local tick = 1/15
local notication_timeout = 3
local action_history = T{}
local action_notifier = {}

local reaction_list = T{
    import_names = S{},
    begin_ability = L{},
    finish_ability = L{},
    begin_spell = L{},
    finish_spell = L{}
}
local reaction_debounce_time = 2
local last_reaction_time = os.clock()

local dispose_bag = DisposeBag.new()

local function reaction_execute(reactions, actor_id, target_id, action_id)
    local current_time = os.clock()
    for react in reactions:it() do
        if (current_time - last_reaction_time > reaction_debounce_time) and
            react.action_ids:contains(action_id) then
            -- exec react.command
            send_command = react.command:gsub('@actor@', actor_id):gsub('@target@', target_id)

            for char_name in send_command:gmatch("@([^@]+)@") do
                local p = windower.ffxi.get_mob_by_name(char_name)
                send_command = p and send_command:gsub('@%s@':format(char_name), p.id) or send_command
            end

            windower.send_command(windower.to_shift_jis(send_command))
            last_reaction_time = current_time
        end
    end 
end

action_notifier.init = function(alliance, renderer)
    reaction_conf.init()
    for p in alliance:get_parties():it() do
        dispose_bag:add(p:get_target_tracker():on_targets_changed():addAction(function(tracker, targets_added, targets_removed)
            for t in targets_added:it() do
                if not action_history[t:get_id()] then
                    action_history[t:get_id()] = {
                        ['abilities'] = T{},
                        ['spells'] = T{}
                    }
                end
            end
            for t in targets_removed:it() do
                if action_history[t:get_id()] then
                    action_history[t:get_id()] = nil
                end
            end
        end), p:get_target_tracker():on_targets_changed())
    end

    dispose_bag:add(WindowerEvents.Action:addAction(function (act)
        local begin_ability = function (actor_id, target_id, ability_id)
            if action_history[actor_id] then
                if not action_history[actor_id]['abilities'][ability_id] then
                    action_history[actor_id]['abilities'][ability_id] = T{}
                end
                action_history[actor_id]['abilities'][ability_id]['target'] = target_id
                action_history[actor_id]['abilities'][ability_id]['begin'] = os.clock()
            end
        end
    
       local finish_ability = function (actor_id, target_id, ability_id)
            if action_history[actor_id] then
                if not action_history[actor_id]['abilities'][ability_id] then
                    action_history[actor_id]['abilities'][ability_id] = T{}
                end
                if action_notifier_conf.sp_ability_ids:contains(ability_id) then
                    action_history[actor_id]['abilities'][ability_id]['target'] = target_id
                    action_history[actor_id]['abilities'][ability_id]['begin'] = os.clock()
                else
                    action_history[actor_id]['abilities'][ability_id]['target'] = target_id
                    action_history[actor_id]['abilities'][ability_id]['finish'] = os.clock()
                end
            end
        end
    
        local begin_spell = function (actor_id, target_id, spell_id)
            if action_history[actor_id] then
                if not action_history[actor_id]['spells'][spell_id] then
                    action_history[actor_id]['spells'][spell_id] = T{}
                end
                action_history[actor_id]['spells'][spell_id]['target'] = target_id
                action_history[actor_id]['spells'][spell_id]['begin'] = os.clock()
            end
        end
        
        local finish_spell = function (actor_id, target_id, spell_id)
            if action_history[actor_id] then
                if not action_history[actor_id]['spells'][spell_id] then
                    action_history[actor_id]['spells'][spell_id] = T{}
                end
                action_history[actor_id]['spells'][spell_id]['target'] = target_id
                action_history[actor_id]['spells'][spell_id]['finish'] = os.clock()
            end
        end

        if act.category == 4 then
            if act.param and res.spells[act.param] and act.targets[1] then
                local actor_id = act.actor_id
                local target_id = act.targets[1].id
                local spell_id = act.param
                finish_spell(actor_id, target_id, spell_id)
                reaction_execute(reaction_list.finish_spell, actor_id, target_id, spell_id)
            end
        elseif act.category == 7 then
            if act.targets[1] and act.targets[1].actions[1] then
                local actor_id = act.actor_id
                local target_id = act.targets[1].id
                local ability_id = act.targets[1].actions[1].param
                if res.monster_abilities[ability_id] then
                    begin_ability(action_id, target_id, ability_id)
                    reaction_execute(reaction_list.begin_ability, actor_id, target_id, ability_id)
                end
            end
        elseif act.category == 8 then
            if act.targets[1] and act.targets[1].actions[1] then
                local actor_id = act.actor_id
                local target_id = act.targets[1].id
                local spell_id = act.targets[1].actions[1].param
                if res.spells[spell_id] then
                    begin_spell(actor_id, target_id, spell_id)
                    reaction_execute(reaction_list.begin_spell, actor_id, target_id, spell_id)
                end
            end
        elseif act.category == 11 then
            if act.param and res.monster_abilities[act.param] and act.targets[1] then
                local actor_id = act.actor_id
                local target_id = act.targets[1].id
                local ability_id = act.param
                finish_ability(actor_id, target_id, ability_id)
                reaction_execute(reaction_list.finish_ability, actor_id, target_id, ability_id)
            end
        end
    end), WindowerEvents.Action)

    dispose_bag:add(renderer.shared():onPrerender():addAction(function()
        local current_time = os.clock()
        if current_time < update_time + tick then return end

        local st = windower.ffxi.get_mob_by_target('st')
        local t =  windower.ffxi.get_mob_by_target('t')
        local bt = windower.ffxi.get_mob_by_target('bt')

        local ability_to_colorize_text = function (id)
            local name = res.monster_abilities[id].name
            if not name then return '' end
            if action_notifier_conf.sp_ability_ids:contains(id) then
                local c = action_notifier_conf.sp_abilities_color
                return '✖ %s ✖':format(name):text_color(c.red, c.green, c.blue)
            elseif action_notifier_conf.danger_ability_ids:contains(id)then
                local c = action_notifier_conf.danger_abilities_color
                return '✖ %s ✖':format(name):text_color(c.red, c.green, c.blue)
            else
                return name
            end
        end
 
        local spell_to_colorize_text = function (id)
            local name = res.spells[id].name
            if not name then return '' end
            if action_notifier_conf.danger_spell_ids:contains(id) then
                local c = action_notifier_conf.danger_spells_color
                return '✖ %s ✖':format(name):text_color(c.red, c.green, c.blue)
            else
                return name
            end
        end

        local valid_action = L{}
        for mob_id, action in pairs(action_history) do
            local actor = windower.ffxi.get_mob_by_id(mob_id)

            for id, ability in pairs(action.abilities) do
                local action_time = ability.begin and current_time - ability.begin or notication_timeout
                if action_time < notication_timeout then
                    target = windower.ffxi.get_mob_by_id(ability.target)
                    valid_action:append({
                        ['time'] = action_time,
                        ['name'] = ability_to_colorize_text(id),
                        ['actor'] = actor and actor.name or '',
                        ['target'] = target and target.name or ''
                    })
                end
            end
            for id, spell in pairs(action.spells) do
                local action_time = spell.begin and current_time - spell.begin or notication_timeout
                if action_time < notication_timeout then
                    target = windower.ffxi.get_mob_by_id(spell.target)
                    valid_action:append({
                        ['time'] = action_time,
                        ['name'] = spell_to_colorize_text(id),
                        ['actor'] = actor and actor.name or '',
                        ['target'] = target and target.name or ''
                    })
                end
            end
        end

        if valid_action:length() > 0 then
            valid_action:sort(function(a, b) return a.time > b.time end)

            local n_lines = L{}
            for action in valid_action:it() do
                -- n_lines:append('%.2f %s ▶▶▶ %s (%s)':format(action.time, action.name, action.target, action.actor))
                n_lines:append('%s ▶▶▶ %s (%s)':format(action.name, action.target, action.actor))
            end
            action_notifier_text:clear()
            action_notifier_text:append(n_lines:concat('\n'))
            action_notifier_text:show()
        else
            action_notifier_text:clear()
            action_notifier_text:hide()
        end

    end), renderer.shared():onPrerender())
end

action_notifier.dispose = function ()
    dispose_bag:destroy()
end

action_notifier.reaction_command = function (cmd, ...)
    local reaction_names = L{...}
    if cmd:lower() == 'set' then
        for name in reaction_names:it() do
            if reaction_conf.reaction[name] and not reaction_list.import_names:contains(name) then
                reaction_list[reaction_conf.reaction[name].category]:append(reaction_conf.reaction[name])
                reaction_list.import_names:add(name)
            end
        end
    elseif cmd:lower() == 'clear' then
        reaction_list = T{
            import_names = S{},
            begin_ability = L{},
            finish_ability = L{},
            begin_spell = L{},
            finish_spell = L{}
        }
    end
end

return action_notifier
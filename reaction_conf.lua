local conf = T{}
conf.reaction = T{}

conf.init = function()
    for k, v in pairs(conf.reaction) do
        if v.category:find('ability') then
            v.action_ids = S(
                res.monster_abilities:map(function(i) 
                    if v.action:contains(i.name) then
                        return i.id 
                    end
                end)
            )
        elseif v.category:find('spell') then
            v.action_ids = S(
                res.spells:map(function(i)
                    if v.action:contains(i.name) then
                        return i.id
                    end
                end)
            )
        end
    end
end

-- category: begin_ability/finish_ability/begin_spell/finish_spell
-- command: @actor@/@target@/@char_name@
conf.reaction['rabbit1'] = {
    category = 'begin_ability',
    action = S{'土煙'},
    command = 'face away',
}

conf.reaction['rabbit3'] = {
    category = 'finish_ability',
    action = S{'土煙'},
    command = 'face',
}

conf.reaction['rabbit2'] = {
    category = 'begin_ability',
    action = S{'フットキック'},
    command = 'input /ma ウォータ @actor@',
}

conf.reaction['rab'] = {
    category = 'begin_spell',
    action = S{'デス'},
    command = '/ma スタン @actor@',
}

return conf
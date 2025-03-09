local conf = T{}
conf.reaction = T{}

conf.init = function()
    for k, v in pairs(conf.reaction) do
        v.action.ability_ids = S(
            res.monster_abilities:map(function(i) 
                if v.action.abilities:contains(i.name) then
                     return i.id 
                end
            end))
        v.action.spell_ids = S(
            res.spells:map(function(i)
                if v.action.spells:contains(i.name) then
                    return i.id
                end
            end))
    end
end

-- category: begin_ability/finish_ability/begin_spell/finish_spell
-- command: @actor@/@target@/@char_name@
conf.reaction['stun'] = {
    category = 'begin_ability',
    action = {
        abilities = S{'土煙'},
        spells = S{'デス'},
    },
    command = '/ma スタン @actor@',
}

return conf
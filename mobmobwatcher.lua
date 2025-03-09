_addon.name = 'mobmobwatcher'
_addon.command = 'mobmobwatcher'
_addon.author = 'yoshisaur'
_addon.version = '0.01'
_addon.commands = {'mmw'}

require('luau')

local renderer = require('cylibs_include')

local action_notifier = require('action_notifier')
local debuffed = require('debuffed')
local mob_list = require('mob_list')

local alliance = nil
local player = nil

function loaded()
    local party_chat = PartyChat.new(true)
    alliance = Alliance.new(party_chat)
    alliance:monitor()

    debuffed.init(alliance, renderer)
    action_notifier.init(alliance, renderer)
    mob_list.init(alliance, renderer)

    -- get_target_tracker.on_targets_changedを追加してから、プレイヤーを追加しないとターゲットを取りこぼす
    player = windower.ffxi.get_player()
    alliance:get_parties()[1]:add_party_member(player.id, player.name)
end

function unloaded()
    alliance:get_parties()[1]:remove_party_member(player.id)
    debuffed.dispose()
    action_notifier.dispose()
    mob_list.dispose()
    renderer.shared():destroy()
    alliance:destroy()
end

windower.register_event('load', loaded)
windower.register_event('unload', unloaded)
windower.register_event('logout', function() windower.send_command(string.format('lua unload %s', _addon.name)) end)
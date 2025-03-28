package.path = package.path..';'..windower.windower_path..'addons/trust/?.lua'

windower.trust = {}
windower.trust.get_temp_dir = function(file_name)
    if file_name then
        return string.format("%s/temp/%s", windower.addon_path..'data', file_name)
    else
        return string.format("%s/temp", windower.addon_path..'data')
    end
end

local temp_dirs = L{
    windower.trust.get_temp_dir(),
    windower.trust.get_temp_dir(windower.ffxi.get_player().name),
}
for dir in temp_dirs:it() do
    if not windower.dir_exists(dir) then
        windower.create_dir(dir)
    end
end

require('cylibs/util/Modes')
require('cylibs/util/States')
ActionQueue = require('cylibs/actions/action_queue')
WindowerEvents = require('cylibs/Cylibs-Windower-Events')
player_util = require('cylibs/util/player_util')
party_util = require('cylibs/util/party_util')
buff_util = require('cylibs/util/buff_util')
battle_util = require('cylibs/util/battle_util')
logger = require('cylibs/logger/logger')
IpcRelay = require('cylibs/messages/ipc/ipc_relay')
LoseDebuffMessage = require('cylibs/messages/lose_buff_message')
GainDebuffMessage = require('cylibs/messages/gain_buff_message')
DisposeBag = require('cylibs/events/dispose_bag')
PartyChat = require('cylibs/chat/party_chat')
Alliance = require('cylibs/entity/alliance/alliance')

local renderer = require('cylibs/ui/views/render')

player ={
    ['trust']={
        ['main_job'] = {
            ['role_with_type'] = function (roleType)
                if roleType == 'follower' then -- Cylibs-Windower-Events on_message_received
                    return false
                end
                -- error('Unexpected call to trust.main_job.role_with_type(): roleType = %s.':format(roleType))
            end
        }
    }
}

return renderer
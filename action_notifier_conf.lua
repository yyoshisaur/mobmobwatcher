local res = require('resources')
local conf = T{
    sp_abilities = S{
        'マイティストライク', 'ブラーゼンラッシュ',
        '百烈拳',
        '女神の祝福',
        '魔力の泉',
        '連続魔',
        '絶対回避', 'ラーセニー',
        'インビンシブル', 'インターヴィーン',
        'ブラッドウェポン', 'ソールエンスレーヴ',
        '使い魔',
        'ソウルボイス',
        'イーグルアイ',
        '明鏡止水',
        '微塵がくれ', '身影',
        '竜剣',
        'アストラルフロウ',
        'アジュールロー',
        'ワイルドカード',
        'オーバードライヴ',
        'トランス',
        '連環計',
        'E.スフォルツォ',
        'ボルスター',
    },
    sp_abilities_color = {
        red=192,
        green=0,
        blue=255
    },
    danger_abilities = S{
        '暗黒',
        'あやつる',
        '痛覚同化',
        'ターゲッティング',
        'ゼロアワー',
        'ダンシングフラー',
        'アンファルタリングブラバード',
        'エビュリエントナリフィケーション',
        'ガールデ',
        'プロフィラクシス',
        'スライミープロポーズ',
        'ビューティフルデス',
        '鬼神技・閻魔',
        'ジャストデザーツ',
    },
    danger_abilities_color = {
        red=255,
        green=192,
        blue=0
    },
    danger_spells = S{
        'ファイア',
        'デス',
        'メルトン',
        'ドレッドスパイク',
        '乙女のヴィルレー'
    },
    danger_spells_color = {
        red=255,
        green=192,
        blue=0
    },
}
conf.sp_ability_ids = S(res.monster_abilities:map(function(i)
    if conf.sp_abilities:contains(i.name) then
        return i.id
    end
end))

conf.danger_ability_ids  = S(res.monster_abilities:map(function(i)
    if conf.danger_abilities:contains(i.name) then
        return i.id
    end
end))

conf.danger_spell_ids = S(res.spells:map(function(i)
    if conf.danger_spells:contains(i.name) then
        return i.id
    end
end))

return conf
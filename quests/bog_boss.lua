local fun = require "util/fun"


local QDEF = QuestDef.Define
{
    title = "Survive the Bog Onslaught!",
    icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    act_filter = "SAL_BRAWL",
    desc = "Your forces are divided and are under attack by the locals! They aren't too happy about the renovations you made to their home.",
    cooldown = EVENT_COOLDOWN.NONE, 
    qtype = QTYPE.STORY,
    focus = QUEST_FOCUS.COMBAT,
}

:AddCast{
    cast_id = "target",
    no_validation = true,
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( quest.param.boss_id or "ADMIRALTY_GOON" ) )
    end,
}
:AddCastByAlias{
    cast_id = "fallon",
    alias = "FALLON_PAST_DIALOGUE"
}

:AddObjective{
    id = "start",
    title = "Survive the Onslaught!",
    --desc = "kill {target} for {giver}.",
}

QDEF:AddConvo("start")
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !left
                player:
                    !right
                fallon:
                    !left
                player:
                    What IS THAT thing?!
                fallon:
                    Hey Kashio you're just in time for some fun
                    We've been held up here for quite some time since you went off by yourself
                player:
                    I've noticed.
                    What's going on?
                fallon:
                    Big guy woke up and he didn't look happy, went into a rage and now we're here trying to hold off the assault it's been throwing at us.
                    The slimy green projectiles it shoots at range isn't helping us get through this guy let alone fend him off.
                    Glad you could join the party.
                player: 
                    Likewise.
                    Any game plan to get rid of this thing?
                fallon:
                    The main problem is getting even near this thing, didn't even suffer a small scratch yet.
                    Before you showed up my men have been pinned down by it's ranged capabilities, raining down fire upon us everytime we clear it's minions out.
                    Let my squad clear a path for your forces then we will be able to get in range of this thing, take it down once and for all and get the hell out of here
                player:
                    !happy
                    Sounds good
                    It's clean up time
            ]],
            OPT_ATTACK = "Eliminate the Bog Monstrocity!",
            DIALOG_ATTACK = [[
                player:
                    !fight
                agent:
                    !right
            ]],

            DIALOG_WON = [[
                * The Bog Monster explodes into pieces, leaving huge pools of highly acidic slime around the forest while smaller Bog creatures awake from their slumber
                * Rise forces are split into groups and are forced to retreat due to the chaos that has ensued
                * You hear Fallon shouting at you from a distance
                player:
                    !left
                fallon: 
                    !right
                    Kashio!
                    We have succeeded surviving against all odds but now we must retreat!
                    Rendezvous on the other side of the forest!
                    We will regroup and escape the bog!
                * You nod at Fallon as you turn to escape the battlefield
            ]],

        }
        :Fn(function(cxt) 
            cxt.encounter:DoLocationTransition(TheGame:GetGameState():GetMainQuest():DefFn("GetRandomLocation"))
            -- cxt:TalkTo("target")
            cxt:TalkTo("target")
            cxt:Dialog("DIALOG_INTRO")
            local battle_flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.BOSS_FIGHT
           
            cxt:Opt("OPT_ATTACK")
                :Dialog("DIALOG_ATTACK")
                :Battle{
                    flags = battle_flags,
                }
                    :OnWin()
                        :Fn(function() 
                            cxt:Dialog("DIALOG_WON")
                            cxt.quest:Complete()
                            StateGraphUtil.AddEndOption(cxt)
                        end)
        end)
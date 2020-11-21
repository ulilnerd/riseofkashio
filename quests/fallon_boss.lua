local fun = require "util/fun"


local QDEF = QuestDef.Define
{
    title = "Defeat Dal Fallon",
    icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    act_filter = "SAL_BRAWL",
    desc = [[{target} is looking to kill you. Get {target.himher} first!]],
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


:AddObjective{
    id = "start",
    title = "Defeat Fallon!",
    --desc = "kill {target} for {giver}.",
}

QDEF:AddConvo("start")
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right
                player:
                    !left
                agent:
                    !right
                    !point
                    !crossed
                    Kashio wait up!!
                    I know what you're about to do
                    We can fix everything, you just have to listen to me.
                player:
                    Fallon nothing will change if we don't act now
                    Havaria will fall victim to those who seek power for the sake of being above others
                    I thought you of all people would understand.
                agent:
                    No, I get it, I understand that completely
                    But this is just... Kashio... 
                    You gathered up Rise and Spark Baron forces for an expedition to find this thing to pay off your debt. 
                    The result... both sides, Rise and Spark Baron's alike are fighting for their lives and being slaughtered all throughout the Bog
                    You've backstabbed your own forces and now you've set off a monstrocity in a rampage in the middle of the Bog to create confusion
                player:
                    Correct.
                    All according to plan.
                agent:
                    This is not the way of the Rise.
                    You've crossed too many lines here Kashio
                player:
                    !point
                    And what are you going to do about it?
                agent:
                    I sense a dark future ahead of us
                    I'll do what I must
                Player:
                    !angry
                    Out of my way Fallon!
            ]],

            OPT_ATTACK = "Showdown with Dal Fallon!",
            DIALOG_ATTACK = [[
                player:
                    !fight
                agent:
                    !right
            ]],

            DIALOG_WON = [[
                agent:
                    !right
                player:
                    !left
                agent:
                    !right
                    !injured
                    You impress me once again.
                    I had hoped that you would be my successor, a ruthless leader and fighter who will lead the Rise and stop the Spark Barons from further forced labour.
                    To bring balance amongst the working class
                    But I suppose we had different ideals
                player:
                    !left
                    We had very diferrent ideals from the very start.
                    I've become more powerful than anyone in Havaria, and I'm planning on keeping it that way.
                    You will rot in this forest, and the Rise Organization will be left in the dirt, forgotten.
                agent:
                    Please, take care of my daughter
                    Once I'm gone there will be no one else left to let her live a normal life
                player:
                    We will see.
                * You finish off Fallon, now just a lifeless corpse, seeping away into the dirt
                player:
                    !left 
                    No regrets.
            ]],

        }
        :Fn(function(cxt) 
            cxt.encounter:DoLocationTransition(TheGame:GetGameState():GetMainQuest():DefFn("GetRandomLocation"))
            cxt:TalkTo("target")
            -- cxt:TalkTo("target")
            cxt:Dialog("DIALOG_INTRO")
            local battle_flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.BOSS_FIGHT
            -- RISE_RADICAL, RISE_REBEL
           
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
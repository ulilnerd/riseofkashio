local fun = require "util/fun"


local QDEF = QuestDef.Define
{
    title = "Defeat Fssh Menewene",
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
    title = "Defeat the boss!",
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
                    !angry
                    KASHIO!!
                    Kashio, how could you?!
                    Slaughtering your own forces, betraying Fallon, and taking the Vagarant technology to the Spark Barons
                    We were supposed to be family!  
                player:
                    !left
                    You should understand what I need to do Fssh
                    It's the only way to fix things.
                agent:
                    !right
                    I know you, I know you wouldn't sell everyone out for your own benefit
                    No, you're not the Kashio we know
                    You're just a monster
                player:
                    You can't stop me even if you tried.
                agent:
                    Even if it costs me my life, I won't let you destroy everything that we've built
                player:
                    !point
                    !angry
                    Then bring it!
            ]],

            OPT_ATTACK = "Showdown with Fssh Menewene!",
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
                    You've bested me, like always Kashio
                    Now think really hard, do you really want to do this?
                    Throw everything away to repay some stupid debt?
                    Have you forgotten our promise to Fallon?? About our little niece Sal? you can't do this...
                player:
                    !left
                    Nothing you say can stop me from handing this over to the Spark Barons
                    I will achieve greatness and Havaria will bow down to my prowess
                    But I'll spare you for now...
                * You leave Fssh on the ground injured, dirty, and soaking wet.
            ]],

        }
        :Fn(function(cxt) 
            
            cxt.encounter:DoLocationTransition(TheGame:GetGameState():GetMainQuest():DefFn("GetRandomLocation"))
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
                                if TheGame:GetGameState():GetPlayerAgent():GetContentID() == "SAL" then
                                    ConvoUtil.GiveBossRewards(cxt)
                                else
                                    ConvoUtil.GiveGraftChoice(cxt, RewardUtil.GetGrafts(cxt.quest:GetRank() + 1, TheGame:GetGameState():GetGraftDraftDetails().count))
                                end
                
                            cxt.quest:Complete()
                            StateGraphUtil.AddEndOption(cxt)
                        end)
        end)
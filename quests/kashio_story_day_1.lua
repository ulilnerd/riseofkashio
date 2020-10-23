
local QDEF = QuestDef.Define
{
    title = "Baby Sal",
    qtype = QTYPE.STORY,
    icon = engine.asset.Texture("icons/quests/rook_story_stepping_in_it.tex"),

    on_start = function(quest)
        quest:Activate("meet_fssh")
    end,

   
}

:AddCastByAlias{
    cast_id = "fssh",
    alias = "FSSH",
    no_validation = true,
}

:AddObjective{
    id = "meet_fssh",
    state = QSTATUS.ACTIVE,
    on_complete = function(quest)
        quest:Activate("")
    end,
}

QDEF:AddConvo("meet_fssh")
    :Confront(function(cxt)
      
        return "STATE_TALK"
        
    end)

    :State("STATE_TALK")
        
        :Loc{

            DIALOG_INTRO = [[
                * {player} and {fssh} arrive at the rendezvous point
                fssh:
                    !right
                    Are you ready to train baby Sal {player}?
                player:
                    !left
                    I've never been more ready
                    Let's give her a demonstration!
            ]],
            DIALOG_WON = [[
                player:
                    !left 
                    See little Sal?
                    That's how auntie Kashio fights.
            ]],
            OPT_SPAR_FSSH = "Spar with Fssh",
                
        }

        :SetLooping()
        :Fn(function(cxt) 
            if cxt:FirstLoop() then
                cxt.quest:Complete("meet_fssh")
                cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("fssh"))
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:Opt("OPT_SPAR_FSSH")
            :Battle{
                flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.NO_FLEE
            }
            :OnWin()
            :Fn(function() 
                cxt:Dialog("DIALOG_WON")
                cxt.quest:Complete()
            end)
        end)

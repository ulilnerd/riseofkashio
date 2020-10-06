local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
    on_init = function(quest)
        TheGame:GetGameState():GetCaravan():MoveToLocation(TheGame:GetGameState():GetLocation("GB_GATE"))
    end,
}

:AddCastByAlias{
    cast_id = "kalandra",
    alias = "KALANDRA",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_GATE"):GetProprietor())
    end,
}

:AddCast{
    cast_id = "admiralty_goon",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_GATE"):GetProprietor())
    end,
}

:AddCast{
    cast_id = "gate_guard",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_GATE"):GetProprietor())
    end,
}

:AddObjective{
    id = "trouble_at_gate",
    title = "To Spark a Baron",
    desc = "Things are about to go down.",
    state = QSTATUS.ACTIVE,
}

QDEF:AddConvo("trouble_at_gate") 
    :Confront(function(cxt)
            return "STATE_START"
    end)

    :State("STATE_START")
    :Loc{ -- intro plays no matter what
        DIALOG_INTRO = [[
        * You make it around to the gate
        * A distinct silence fills the air. 
        * An Admiralty Officer steps out from behind the gate
           
        ]],
        DIALOG_REINTRO = [[
                kalandra:
                    !crossed
                    Alright Kashio, no more day dreaming.
                    !happy
                    Lets get back to work so I can get that promotion of mine
            ]],
   
        
       -- initiate negotiation or fight with kalandra

    }
    -- above: 
    :SetLooping()
    :Fn(function(cxt) 
        if cxt:FirstLoop() then
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("kalandra"))
            cxt:Dialog("DIALOG_INTRO")
        else
            cxt:Dialog("DIALOG_REINTRO")
        end
    end)

local QDEF = QuestDef.Define
{
    title = "Just another day",
    qtype = QTYPE.STORY,
    icon = engine.asset.Texture("icons/quests/rook_story_stepping_in_it.tex"),

    on_start = function(quest)
        quest:Activate("intro_scene")
    end,

    events = 
    {
    },
}

:AddSubQuest{
    id = "intro_scene",
    quest_id = "KASHIO_INTRO",
    on_complete = function(quest)
       quest:Activate("trouble_at_gate")
    end,
}

:AddLocationCast{
    cast_id = "lumin_mine_gate",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_GATE"))
    end,
}

:AddCast{
    cast_id = "gate_guard",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_GATE"):GetProprietor())
    end,
}
:AddCastByAlias{
    cast_id = "oolo",
    alias = "MURDER_BAY_ADMIRALTY_CONTACT",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_GATE"):GetProprietor())
    end,
}
:AddCastByAlias{
    cast_id = "kalandra",
    alias = "KALANDRA",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_GATE"):GetProprietor())
    end,
}
:AddCastByAlias{
    cast_id = "admiralty_goon",
    alias = "WEEZIL",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_GATE"):GetProprietor())
    end,
}

:AddObjective{
    id = "trouble_at_gate",
    title = "To Spark a Baron",
    desc = "Check out what's happening at the gate.",
    mark = {"gate_guard"},
    icon = engine.asset.Texture("icons/quests/rook_story_work_for_fellemo.tex"),
    on_complete = function(quest) 
        
    end,
}

QDEF:AddConvo("trouble_at_gate") 
    :Confront(function(cxt)
            return "STATE_START"
    end)

    :State("STATE_START")
    :Loc{ 
        DIALOG_INTRO = [[
        * You make it around to the gate
        * It looks likes theres a whole army of Admiralty out there...
        * Silence fills the air. 
        * An Admiralty Officer steps out from behind the gate
        oolo:
            !left
            Greetings from Admiralty Headquarters
            I, Oolo, a trustworthy representative of the Admiralty, have come to collect a debt from the Spark Barons of this filthy land
            We request that this factory will transfer 60 tons of Lumin Ore to our convoy or there will be consequences
        * Kalandra and Kashio in the background
        kalandra:
            !right
            Sweet jesus!
            We don't even mine that much ore in a year!
            I wondering what's up with that kind of demand for Lumin
        player: 
            !left 
            Well we're about to find out...
        gate_guard:
            !right
            Sorry I'm not sure if I recall owing some fancy pancy Admiralty any Lumin ore of some sort
            We own this mine and own one hundred percent of the resources that we produce
            You'll probably have to look else where bud.
        oolo:
            !left
            Nonsense! WE, have provided YOU, with the tools needed to extract the ore, and the agreement was a 50/50 split!
        gate_guard:
            !right
            Well the deal's off, we're not going to give a single drop of Lumin ore to you Admiralty scumbags.
        oolo:
            !left
            You have no right to make a decision here
            I have a whole army outside of this gate waiting to take out all of your men on my mark
            Either you comply to our demand or we will take it by force.
            You have been warned.
        gate_guard:
            !right
            shrugs shoulders.
            Beats me.
        * You hear yelling and running foot steps of many in the distance
        * CHAAAAAAAAAAAAAAAARGE!
        * a HUGE group of Spark Baron soldiers charge in from behind the Admiralty
        * Admiralty soldiers break and rush through the gate trying to create a chokepoint while fending off the Spark Barons from inside as well
        * The Spark Barons and Admiralty clash with one another, with some unlucky workers also getting caught between the crossfire
        * The worksite is in complete chaos 
        * Kashio and Kalandra try to sneak out from the back
        admiralty_goon:
            !right
            ARGHHHHHH KILL THEM ALL KILL ALL THE SPARK BARONS 
        * The enraged Admiralty Goon swings his weapon at you
        kalandra:
            !left 
            Kashio watch out!!
        * Kalandra pushes you out the of way just in time without both of you getting injured
        admiralty_goon:
            !right
            YOU CAN'T LEAVE, YOU CAN'T ESCAPE 
            THE ONLY OTHER WAY
            IS DEATH
        player:
            !left
            Kalandra I don't think he's going to let us through
            We can try another path, or run back to Headquarters.
            Kalandra?
        * Kalandra rushes towards the Admiralty Goon
        player:
            !left
            sigh
        * You follow through with Kalandra's assault on the goon 
        ]],
        DIALOG_REINTRO = [[
                kalandra:
                    !crossed
                    You've made it to the end of the campaign
                player:
                    Oh noes!
            ]],
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






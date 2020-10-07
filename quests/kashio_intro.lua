local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
    on_init = function(quest)
        TheGame:GetGameState():GetCaravan():MoveToLocation(TheGame:GetGameState():GetLocation("GB_WORKSITE_1"))
    end,
}

:AddCastByAlias{
    cast_id = "kalandra",
    alias = "KALANDRA",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_WORKSITE_1"):GetProprietor())
    end,
}

:AddCastByAlias{
    cast_id = "lumin_miner",
    alias = "HEBBEL",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GB_WORKSITE_1"):GetProprietor())
    end,
}

:AddObjective{
    id = "work_with_kalandra",
    title = "Another day, Another time",
    desc = "Just another day of working in the mine.",
    state = QSTATUS.ACTIVE,
}

-- below is you and kalandra talking
QDEF:AddConvo("work_with_kalandra") 
    :Confront(function(cxt)
        return "STATE_START"
    end)

    :State("STATE_START")
    :Loc{ -- intro plays no matter what
        DIALOG_INTRO = [[
        * The sky is filled with foul black smoke from the machinery being operated, you day dream, as you look up and take a small glimpse of the moon being covered by the smoke. 
        * You wonder how amazing the sky would look if this land wasn't filled with such crude machinery
            player:
                !left
            kalandra:
                !right
                Hello Kashio? Are you day dreaming again?
                I'm done mining this Lumin ore and it's your turn to smelt the bars.
            player:
                !left
                Ah, hey Kalandra, sorry I'll get right to it, just lost myself for a second
            kalandra:
                !right
                Oh Kashio, were you thinking about quitting this job <b>AGAIN</b>?
                You do know that we are very fortunate to even have a job in Grout Bog, let alone a very IMPORTANT one.
                Most of the work here is either industrial or criminal.
                Don't want to mess with those Spree Bandits, they've been stiring up a lot of trouble lately.
                Anyways, we've done a pretty good job so far mining and smelting this Lumin ore so the Spark Barons can make powerful equipment.
                Speaking of a good job I was hoping to get a promotion soon.
            player:
                !left 
                Yeah I suppose, but what kind of life is waking up everyday to black smoke in the sky and noisy machinery?
                But a promotion... Hmm that would be nice, I could use some of those new Cybernetics those rich Grifters implanted into their heads, very fancy kind of stuff
            kalandra:
                !right
                Meh, not really into those cybernetics, way too advanced technology for our time.
                Plus these cybernetics...
                They were never thoroughly tested before releasing it to the public.
                Anyways, going back to our <i>promotion</i> talk, I was thinking that we could visit this bar down on Grout Road, grab a few drinks and have a good old time.
            player:
                !left
                You mean that new bar around town?
                Kalandra you do know we're both short on funds, and we can't really afford to drink during this time of the year, so....
            kalandra:
                !right
                So I've gotten this grand of idea of us practicing our "negotiate for a better salary" kind of idea!
            player:
                !left
                Oh brother not this again.
                We're also on shift Kalandra.
            kalandra:
                !right
                Come on! It will be fun!
                and besides did you already forget while working here for 3 years already?
                We set our own time for breaks! 
                Just imagine us at the bar, getting smashed out of our minds, and witnessing insane bar fights!
                Orrrrrr we can have a little bar brawl of our own!
        ]],
        DIALOG_REINTRO = [[
                kalandra:
                    !crossed
                    Alright Kashio, no more day dreaming.
                    !happy
                    Lets get back to work so I can get that promotion of mine
            ]],
        -- fight option and dialog
        OPT_FIGHT_KALANDRA = "Time to get your hands a little dirty.",
        DIALOG_FIGHT_KALANDRA = [[
            player:
                !left
                Well, I guess you leave me no choice
                But I'm warning you, you'll be sorry.
        ]],
        -- negotiation option and dialog
        OPT_NEGOTIATE = "Show her who's boss around here",
        DIALOG_NEGOTIATE = [[
            player:
            !left
            Well, I guess you leave me no choice
            But I'm warning you, you'll be sorry.
        ]],
        DIALOG_SUCCESS = [[
            kalandra:
                !right
                !happy
                Wow Kashio! You're way better than I expected!
                You really showed me that I don't deserve that promotion
                It's time to practice two times a day instead of one!
                Until next time, you've won this time around
            player:
                !left
                !happy
                Well I did say I wouldn't go easy on you
                Better luck next time
        ]],
        DIALOG_FAIL = [[
            kalandra:
                !right
                Yep, and that is how and why I deserve to get paid more
            player:
                !left
                I guess you sure do want this promotion badly
        ]],
    }
    -- above: 
    :SetLooping()
    :Fn(function(cxt) 
        if cxt:FirstLoop() then
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("kalandra"))
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_FIGHT_KALANDRA")
            :Dialog("DIALOG_FIGHT_KALANDRA")
            :Battle{
                
                -- on_success = function(cxt) 
                    
                -- end,
                -- on_fail = function(cxt)
                --     -- cxt:Dialog("DIALOG_FAIL")
                -- end,
            }     
        cxt:Opt("OPT_NEGOTIATE")
                :Dialog("DIALOG_NEGOTIATE")
                :Negotiation{
                    -- on_success = function(cxt) 
                    --     -- cxt:Dialog("DIALOG_SUCCESS")
                        
                    -- end,
                    -- on_fail = function(cxt)
                    --     -- cxt:Dialog("DIALOG_FAIL")
                    -- end,
                }    
        else
            -- cxt:Dialog("DIALOG_REINTRO")
            cxt:Dialog("DIALOG_SUCCESS")
            cxt:GoTo("STATE_TROUBLE_AT_GATE")
        end
    end)

    :State("STATE_TROUBLE_AT_GATE")
    :Loc{ 
        DIALOG_GATE_TROUBLE = [[
            * SCREEEEEEEEEEEECH
            * Workers and Spark Barons alike gather around the gate
            * One of the workers near Kashio fumbles to the ground as he bumps into Kalandra
            lumin_miner:
                !right
                OOOOOF 
                ouch
            kalandra:
                !left
                Hey buddy, watch it!
            player:
                !right
                Kalandra knock it off
            lumin_miner:
                !left
            player:
                !right
                Are you alright?
                What's happening up there?
            lumin_miner:
                !left
                I am so sorry ma'am 
                I was just working on crafting some Lumin Infused weapons for the Admirality who live up at Murder Bay
                Ya know, where them rich and fortunate people live
                Anyway, had a talk with one of them Spark Baron Task Leaders at our station
                Said we wouldn't be handing these over to the Admirality and their order would not be delivered
                So now some wild machine is beeping and booping and screeching around making a ton of noise and hurtin me eardrums
                This thing is just right outside of our gate and it doesn't look friendly
            player:
                !right
                Thank you for informing us, you can go on your way now.
            kalandra: 
                !left
                Well he sure was rude
            player:
                !right
                Just relax, he is the least of our problems at the moment
                Right now we need to head over to that main gate and see whats about to go down
            kalandra:
                !left
                I'm right with you Kashio, and whatever happens, I will be with you every single step of the way.
            player:
                !right 
                Likewise.
        ]],
        OPT_LEAVE = "Get to the main gate",     
    }
    :SetLooping()
    :Fn(function(cxt) 
        cxt:Dialog("DIALOG_GATE_TROUBLE")
        cxt:Opt("OPT_LEAVE")
            :PreIcon( global_images.close)
            :CompleteQuest()
            :Travel()
            -- :Fn(function() 
            --     cxt.quest:Activate("trouble_at_gate")
            -- end)
            
    end)
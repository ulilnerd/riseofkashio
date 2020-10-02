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
                Wow Kashio! You're way better than I expected!
                You really showed me that I don't deserve that promotion
                It's time to practice two times a day instead of one!
                Until next time, you've won this time around
            player:
                !left
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

        cxt:Opt("OPT_FIGHT_KALANDRA")
            :Dialog("DIALOG_FIGHT_KALANDRA")
            :Battle{
                on_success = function(cxt) 
                    cxt:Dialog("DIALOG_SUCCESS")
                    cxt:GoTo("GATE_TROUBLE") -- when the admirality show up at the lumin mine gate
                end,
                on_fail = function(cxt)
                    cxt:Dialog("DIALOG_FAIL")
                    cxt:GoTo("GATE_TROUBLE") -- when the admirality show up at the lumin mine gate
                end,
                -- GATE_TROUBLE plays no matter if you win or lose
            }    
            
            
        cxt:Opt("OPT_NEGOTIATE")
                :Dialog("DIALOG_NEGOTIATE")
                :Negotiation{
                    on_success = function(cxt) 
                        cxt:Dialog("DIALOG_SUCCESS")
                        cxt:GoTo("GATE_TROUBLE") -- when the admirality show up at the lumin mine gate
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_FAIL")
                        cxt:GoTo("GATE_TROUBLE") -- when the admirality show up at the lumin mine gate
                    end,
                    -- GATE_TROUBLE plays no matter if you win or lose
                }
    end)



AddPlayerCharacter(
    PlayerBackground{
            id = "KASHIO_PLAYER",

            player_agent = "KASHIO_PLAYER",
            player_agent_skin = "c095c17d-98ac-463c-b70f-5eedae4a5fc3",

            name = "Kashio",
            title = "The Kingpin",
            desc = "A loyal working class citizen just trying to scrape by",
            advancement = DEFAULT_ADVANCEMENT,

            pre_battle_music = "event:/music/dailyrun_precombat_sal",
            deck_music = "event:/music/viewdecks_sal",
            boss_music = "event:/music/adaptive_battle_boss",
            battle_music = "event:/music/adaptive_battle",
            negotiation_music = "event:/music/adaptive_negotiation_barter",

            ambush_neutral = "event:/music/stinger/ambush_neutral",
            ambush_bad = "event:/music/stinger/ambush_bad",

    }

    :AddAct{
        id = "RISE_OF_KASHIO",
        
        name = "At the brink of opportunity",
        title = "The Rise of Kashio",
        desc = "A Kashio prequel story.",
        
        act_image = engine.asset.Texture("UI/char_1_campaign.tex"),
        colour_frame = "0xFFDE5Aff",
        colour_text = "0xFFFF94ff",
        colour_background = "0xFFA32Aff",

        world_region = "grout_bog",

        max_resolve = 35,

        main_quest = "KASHIO_STORY",
        game_type = GAME_TYPE.CAMPAIGN,

        starting_fn = function( agent, game_state) 
            agent:DeltaMoney( 50 )
        end,
    }

    :AddAct{
        id = "ROOK_BRAWL",
        unlock_id = "ROOK_BRAWL_PLAYABLE",
        name = "Rook's Brawl",
        title = "Working All of the Sides",
        desc = "Survive an escalating series of Rook's schemes as Kashio.",

        game_type = GAME_TYPE.BRAWL,
        
        act_image = engine.asset.Texture("UI/char_2_brawl.tex"),
        colour_frame = "0xA866F3ff",
        colour_text = "0xE4BFFFff",
        colour_background = "0xFF31E4ff",

        world_region = "brawl_region",
        main_quest = "ROOK_BRAWL",
    }

        :AddAct{
            id = "SAL_BRAWL",
            unlock_id = "SAL_BRAWL_PLAYABLE",
            name = "Sal's Brawl",
            title = "Havarian Gig Economy",
            desc = "Survive an escalating series of jobs as Sal works for a living as Kashio.",

            act_image = engine.asset.Texture("UI/char_1_brawl.tex"),
            colour_frame = "0xA866F3ff",
            colour_text = "0xE4BFFFff",
            colour_background = "0xFF31E4ff",

            world_region = "brawl_region",
            main_quest = "SAL_BRAWL",
            game_type = GAME_TYPE.BRAWL,

    })

local act = GetPlayerActData( "RISE_OF_KASHIO" )
GetPlayerBackground( "ROOK" ):AddClonedAct( act, "ROOKS_ADVENTURE" )


local decks = 
{
    NegotiationDeck("negotiation_basic", "KASHIO_PLAYER", "SAL")
        :AddCards{ 
            fast_talk = 3,
            threaten = 2,
            deflection = 3,
            quick_thinking = 1,
            sals_instincts = 1,
        },
    
    BattleDeck("battle_basic", "KASHIO_PLAYER")
        :AddCards{ 
            flail_crack = 3,
            flail_smash = 3,
            flail_slam = 1,
            safeguard = 3,
            devise = 1,
            swap_weapon = 1
        },
}

for k,v in ipairs(decks) do
    Content.AddDeck(v)
end


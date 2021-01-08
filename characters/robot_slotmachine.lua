local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

Content.AddCharacterDef
(
	CharacterDef("ROBOT_SLOTMACHINE",
	{
		base_def = "NPC_BASE",

		name = "LOTO 649",
		title = "Multipurpose Microtransaction Machine",
		renown = 2,
		combat_strength = 2,
		voice_actor = "robotSteven",
		alias = "ROBOT_SLOTMACHINE",
		desc = "Scam Bot",

        faction_id = "NEUTRAL",
		gender = GENDER.MALE,
        species = SPECIES.HUMAN,
        unique = true,
        
        -- head = "head_automech_boss",
        hair_colour = 3434903039,
        skin_colour = 1652061183,
        build = "combat_drone",

		-- combat_anims = { "anim/med_combat_automech_boss.zip" },
		-- anims = { "anim/weapon_knife_kalandra.zip" },

		fight_data = 
		{
			MAX_MORALE = MAX_MORALE_LOOKUP.MEDIUM,
			MAX_HEALTH = MAX_HEALTH_LOOKUP.MEDIUM,

			attacks = 
            {
               
            },


			behaviour = 
			{
				
			},

		},
	})
)


local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local def = CharacterDef("MAL_PAST",
    {
        name = "Mal Fallon",
        base_def = "NPC_BASE",
        alias = "MAL_PAST",
        id = "MAL_PAST",

        anims = { "anim/weapon_blaster_rook.zip","anim/weapon_blaster_phicket_assassin_02.zip","anim/weapon_rifle_phicket_assassin_02.zip"},
    	combat_anims = { "anim/med_combat_rook.zip","anim/med_combat_blaster_phicket_assassin_02.zip" },

        head = "head_female_guard_05",
        build = "rise_female",
        
        hair_colour = 0xF8F8FFFF,
        skin_colour = 0xd2a18cff,
        species = "HUMAN",
        unique = true,
        boss = true,
        gender = GENDER.FEMALE,
    

        fight_data = 
        {
            MAX_HEALTH = 180,
            formation = FIGHTER_FORMATION.FRONT_Z,
            actions = 1,

        }
    })
    def:InheritBaseDef()
    Content.AddCharacterDef( def )
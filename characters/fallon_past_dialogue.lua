local def = CharacterDef("FALLON_PAST_DIALOGUE",
    {
        name = "Dal Fallon",
        base_def = "NPC_BASE",
        alias = "FALLON_PAST_DIALOGUE",
        id = "FALLON_PAST_DIALOGUE",

        combat_anims = {"anim/med_combat_rentorian.zip" },
        anims = {"anim/weapon_double_bladed_staff_rentorian.zip"},

        head = "head_male_hesh_luminiciate",
        build = "male_rise_promoted_build",
        
        hair_colour = 0xCB5D3Cff,
        skin_colour = 0xd2a18cff,
        species = "HUMAN",
        unique = true,
        -- boss = true,
        gender = GENDER.MALE,
    })
    def:InheritBaseDef()
    Content.AddCharacterDef( def )
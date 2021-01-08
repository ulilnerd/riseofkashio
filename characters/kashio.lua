local def = CharacterDef("KASHIO_PLAYER",
{
    base_def = "PLAYER_BASE",
    default_skin = "c095c17d-98ac-463c-b70f-5eedae4a5fc3",

    -- "anim/weapon_double_bladed_staff_rentorian.zip" 
    -- "anim/med_combat_rentorian.zip"

    anims = {"anim/weapon_blaster_phicket_assassin_02.zip","anim/weapon_flail_kashio.zip" },
    combat_anims = { "anim/med_combat_blaster_phicket_assassin_02.zip","anim/med_combat_flail_kashio.zip" },

    voice_actor = "kashio",
    -- battle_preview_anim = "anim/boss_kashio_slide.zip",
    -- battle_preview_offset = { x = 200, y = 50 },
    -- battle_preview_glow = { colour = 0xFF9501ff, bloom = 0.13, threshold = 0.02 },

    battle_preview_anim_fn = function( build )
        local anims = {
            ["kashio_base"] = { anim = "anim/boss_kashio_slide.zip", offset = { x = 200, y = 50, scale = 1}, glow = { colour = 0xFF9501ff, bloom = 0.13, threshold = 0.02 }, audio = nil },
        }
        return anims[build] or anims["kashio_base"]
    end,
    
    max_grafts = {
        [GRAFT_TYPE.COMBAT] = 6,
        [GRAFT_TYPE.NEGOTIATION] = 3,
    },

    max_resolve = 45,

    fight_data = 
    {
        MAX_HEALTH = 50,
        ranged_riposte = true,
        actions = 3,
        formation = FIGHTER_FORMATION.FRONT_X,


        anim_mapping =
        {
            riposte = "attack1",
            execute = "spin_attack",
        },

        behaviour =
        {
            OnActivate = function( self )
                self.fighter:AddCondition("equip_flail")
            end,
        },

        anim_mapping_flail =
        {
            idle = "idle",
            defend = "defend",
            death = "death",
            hit_mid = "hit_mid",
            hit_mid_pst_idle = "hit_mid_pst_idle",
            hit_mid_pst_stunned = "hit_mid_pst_stunned",
            hit_mid_pst_surrender = "hit_mid_pst_surrender",
            run_forward = "run_forward",
            run_forward_pre = "run_forward_pre",
            run_forward_pre_turn = "run_forward_pre_turn",
            run_forward_pst = "run_forward_pst",
            run_forward_pst_turn = "run_forward_pst_turn",
            step_back = "step_back",
            step_forward = "step_forward",
            stunned = "stunned",
            stunned_pre = "stunned_pre",
            stunned_pst = "stunned_pst",
            surrender_pre = "surrender_pre",
            surrender_pst = "surrender_pst",
            surrender = "surrender",
            riposte = "gun2",
            throw1 = "throw",
            death_holo = "death_holo",
            taunt = "taunt",
            holo_spawn_2 = "holo_spawn",
        },

        anim_mapping_glaive =
        {
            idle = "idle2",
            defend = "defend2",
            death = "death2",
            hit_mid = "hit_mid2",
            hit_mid_pst_idle = "hit_mid2_pst_idle",
            hit_mid_pst_stunned = "hit_mid2_pst_stunned",
            hit_mid_pst_surrender = "hit_mid2_pst_surrender",
            run_forward = "run_forward2",
            run_forward_pre = "run_forward2_pre",
            run_forward_pre_turn = "run_forward2_pre_turn",
            run_forward_pst = "run_forward2_pst",
            run_forward_pst_turn = "run_forward_pst2_turn",
            step_back = "step_back2",
            step_forward = "step_forward2",
            stunned = "stunned2",
            stunned_pre = "stunned2_pre",
            stunned_pst = "stunned2_pst",
            surrender_pre = "surrender2_pre",
            surrender_pst = "surrender2_pst",
            surrender = "surrender2",
            riposte = "gun2",
            throw1 = "throw2",
            death_holo = "death_holo2",
            taunt = "taunt4",
            holo_spawn_2 = "holo_spawn",
        },

       
    },

    negotiation_data =
    {
        behaviour =
        {
            OnInit = function( self, difficulty )
                self.negotiator:AddModifier( "GRIFTER" )
            end,
        }
    },

    card_series = { "GENERAL", "KASHIO_PLAYER" },
    graft_series = { "GENERAL", "SAL", "KASHIO_PLAYER" },

    hair_colour = 0xCB5D3Cff,
    skin_colour = 0xd2a18cff,
    text_colour = 0xd16160FF,
        
    faction_id = PLAYER_FACTION,
})
def:InheritBaseDef()

Content.AddCharacterDef( def )

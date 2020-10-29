local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local def = CharacterDef("FSSH_PAST",
    {
        title = "Spark Baron Fssh",
        base_def = "NPC_BASE",
        alias = "FSSH_PAST",

        anims = { "anim/weapon_knife_guard_lumin.zip","anim/weapon_blaster_sal.zip", "anim/med_dial_sal.zip"},
        combat_anims = { "anim/med_combat_sal.zip" },
        -- default_skin = "d18e5b49-45a2-4561-aaae-37338243c36d",

        head = "head_fssh",
        build = "guard_female_offduty",

        is_hologram = true,

        fight_data = 
        {
            MAX_HEALTH = 80,
            formation = FIGHTER_FORMATION.FRONT_Z,
            actions = 1,

            attacks = 
            {
              
                
            },

            OnJoinBattle = function( fighter, anim_fighter )
                AddHoloEffect( anim_fighter )
            end,

            behaviour =
            {
                OnActivate = function( self, fighter)
                  
                        self:SetPattern( self.Cycle )
                end,

                Cycle = function( self )
                    
                end,
            }
        }
    })
    def:InheritBaseDef()
    Content.AddCharacterDef( def )
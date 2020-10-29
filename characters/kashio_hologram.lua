local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS



local KASHIO_FLASH_VALUES = 
{ 
    colour = 0xff00ffff,
    time_in = 0.1, 
    time_out = 0.3, 
    max_intensity = 1
}
local KASHIO_HOLOGRAM_VALUES =
{
     scale = -1.0, 
   -- colour = 0x9900ffff,
    colour = 0x9900FFff,
    alpha = {0.7, 0.3, 2.0}, -- Alpha for each layer of the FX
    speed = {0.05, 0.07, 0.5},
    layersTexture = engine.asset.Texture("rgba/character_hover.tex"),

    glitchSpeed = 0.07, 
    glitchScale = 6.0,
    glitchTexture = engine.asset.Texture("glitch/holo_glitch.tex"),

    colormatrixHue = {1.0,0.5,3.0},
    colormatrixSaturation = 0.0,
    colormatrixBrightness = 0.0,
    colormatrixContrast = 1.5, 
}
local function AddHoloEffect( anim_fighter )
    local x, y = anim_fighter.sim:GetCamera():WorldToScreen( anim_fighter:GetStatusWidgetPosition() )
    local width = TheGame:FE():GetScreenDims()
    local screen_pos = math.abs(x)/width
    local pan_pos = easing.linear( screen_pos, -1, 2, 1 )
    AUDIO:PlayParamEvent("event:/sfx/battle/atk_anim/kashio/hologram_on", "position", pan_pos)
    anim_fighter:Flash(KASHIO_FLASH_VALUES.colour, KASHIO_FLASH_VALUES.time_in, KASHIO_FLASH_VALUES.time_out, KASHIO_FLASH_VALUES.max_intensity)    
    anim_fighter:SetHologramEffect(true, KASHIO_HOLOGRAM_VALUES)
end

local def = CharacterDef("KASHIO_HOLO_PLAYER",
    {
        title = "Kashio Hologram",
        base_def = "NPC_BASE",
        alias = "KASHIO_HOLOGRAM",

        anims = {"anim/weapon_flail_kashio.zip" },
        combat_anims = { "anim/med_combat_flail_kashio.zip" },
        default_skin = "c095c17d-98ac-463c-b70f-5eedae4a5fc3",
        is_hologram = true,

        fight_data = 
        {
            MAX_HEALTH = 1,
            formation = FIGHTER_FORMATION.FRONT_Z,
            actions = 1,

            attacks = 
            {
                flail_smash1 = table.extend(NPC_MELEE)
                {
                    name = "Smash",
                    anim = "smash",
                    flags = CARD_FLAGS.MELEE,
        
                    base_damage = { 2, 4, 6 },

                },

                flail_crack1 = table.extend(NPC_MELEE)
                {
                    name = "Crack",
                    anim = "crack",
                    flags = CARD_FLAGS.MELEE | CARD_FLAGS.DEBUFF,
                    base_damage = { 1, 2, 3 },
        
                    features =
                    {
                        WOUND = 1,
                    },
                },

                flail_slam1 = table.extend(NPC_MELEE)
                {
                    name = "Slam",
                    anim = "slam",
                    flags = CARD_FLAGS.MELEE,
        
                    base_damage = { 2, 4, 6 },
                },

                nothing_card = table.extend(NPC_MELEE)
                {
                    name = "does nothing",
                    anim = "taunt",
                    flags = CARD_FLAGS.SKILL,
        
                },
                
                
            },

            OnJoinBattle = function( fighter, anim_fighter )
                AddHoloEffect( anim_fighter )
            end,

            behaviour =
            {
                OnActivate = function( self, fighter)
                    self.flail_attacks = self:MakePicker()
                        :AddID( "flail_crack1", 2)
                        :AddID( "flail_smash1", 2)
                        :AddID( "flail_slam1", 2)
                        self:SetPattern( self.Cycle )
                end,

                Cycle = function( self )
                    self.flail_attacks:ChooseCard()
                end,
            }
        }
    })
    def:InheritBaseDef()
    Content.AddCharacterDef( def )
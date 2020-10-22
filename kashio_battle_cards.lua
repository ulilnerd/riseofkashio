local battle_defs = require "battle/battle_defs"
local CARD_FLAGS = battle_defs.CARD_FLAGS
local EVENT = battle_defs.EVENT
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
require "eventsystem"

local CARDS =
{
    improvise_smokescreen = 
    {
        name = "Smokescreen",
        anim = "throw2",
        desc = "Gain {EVASION} then {IMPAIR} self.",
        icon = "RISE:textures/smokescreen.png",

        min_damage =  0,
        max_damage =  1,
        
        rarity = CARD_RARITY.UNIQUE,
        cost = 0,
        flags = CARD_FLAGS.RANGED | CARD_FLAGS.EXPEND, 
        target_mod = TARGET_MOD.TEAM,
        
        evasion_amt = 1,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("IMPAIR", 2 )
            self.owner:AddCondition("EVASION", self.evasion_amt, self)
        end
    },

    improvise_rage = 
    {
        name = "Rage",
        anim = "taunt",
        target_type = TARGET_TYPE.SELF,
        desc = "Gain {1} {POWER_LOSS} then {WOUND} self.",
        icon = "RISE:textures/rage.png",

        rarity = CARD_RARITY.UNIQUE,
        cost = 0,
        flags = CARD_FLAGS.SKILL| CARD_FLAGS.EXPEND,
        power_amt = 2,
        wound_amt = 2,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.power_amt ))
        end,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("POWER_LOSS", self.power_amt )
            self.owner:AddCondition("POWER", self.power_amt )
            self.owner:AddCondition("WOUND", self.wound_amt )
        end
    },

    improvise_burningsmash = 
    {
        name = "Burning Smash",
        anim = "smash",
        desc = "Apply {1} {BURN}.",
        icon = "RISE:textures/burningsmash.png",

        rarity = CARD_RARITY.UNIQUE,
        cost = 0,
        flags = CARD_FLAGS.EXPEND | CARD_FLAGS.MELEE,
        burn_amount = 3,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.burn_amount ))
        end,
        
        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    target:AddCondition("BURN", self.burn_amount, self)
                end
            end
        end
    },

    improvise_invincible = 
    {
        name = "Invincible",
        anim = "taunt",
        desc = "An attack from an enemy on you will deal 0 damage, Gain 2 {DEFECT}.",
        icon = "battle/bring_it_on.tex",

        rarity = CARD_RARITY.UNIQUE,
        cost = 0,
        flags = CARD_FLAGS.EXPEND | CARD_FLAGS.SKILL,
        burn_amount = 3,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("INVINCIBLE", 1, self)
            if self.owner:HasCondition("INVINCIBLE") then
                self.owner:AddCondition("DEFECT", self.owner:GetConditionStacks("INVINCIBLE") + 1)
            end
        end,
    },

    improvise_weird_colored_flask =
    {
        name = "Weird Colored Flask",
        anim = "taunt",
        desc = "Gain a random buff or debuff.",
        icon = "battle/oshnu_bile.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            local posConditions = {"BLEED", "IMPAIR", "BURN", "STUN", "WOUND", "EXPOSED"}
            local posPosConditions = {"POWER", "ARMOURED", "NEXT_TURN_DRAW", "RIPOSTE", "METALLIC", "EVASION"}
            local randomCon = math.random(1,2)
            local randomNum = math.random(1,6)
            if randomCon == 1 then
                self.owner:AddCondition(posConditions[randomNum], 1, self)
            elseif randomCon == 2 then
                self.owner:AddCondition(posPosConditions[randomNum], 1, self)
            end
        end
    },

    improvise_drink = 
    {
        name = "Hand Me A Drink",
        anim = "taunt",
        desc = "Shuffle 2 random drink cards into your deck.",
        icon = "battle/slam.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            local drinkCards = {"green_flask", "red_flask", "purple_flask"}
            local randomCard1 = math.random(1,3)
            local randomCard2 = math.random(1,3)

            local card1 = Battle.Card( drinkCards[randomCard1], self.owner )
            battle:DealCard( card1, battle:GetDeck( DECK_TYPE.DRAW ) )

            local card2 = Battle.Card( drinkCards[randomCard2], self.owner )
            battle:DealCard( card2, battle:GetDeck( DECK_TYPE.DRAW ) )
        end
    },
    green_flask = 
    {
        name = "Green Flask",
        anim = "taunt",
        desc = "Heal {1}.",
        icon = "battle/lean_green.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.REPLENISH | CARD_FLAGS.HEAL,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        heal_amount = 2,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.heal_amount ))
        end,

        OnPostResolve = function( self, battle, attack)
            self.owner:HealHealth(self.heal_amount, self)
        end
    },
    red_flask = 
    {
        name = "Red Flask",
        anim = "taunt",
        desc = "Deal Damage.",
        icon = "battle/speed_tonic.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.REPLENISH,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,
      
        min_damage = 1,
        max_damage = 2,
    },
    purple_flask = 
    {
        name = "Purple Flask",
        anim = "taunt",
        desc = "Allies gain {POWER_LOSS}.",
        icon = "battle/vial_of_slurry.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.REPLENISH,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,
        target_mod = TARGET_MOD.TEAM,
       
        OnPostResolve = function( self, battle, attack, fighter)
            for i, ally in self.owner:GetTeam():Fighters() do
                if fighter ~= self.owner then
                    ally:AddCondition("POWER", 1, self)
                    ally:AddCondition("POWER_LOSS", 1, self)
                end
            end
        end
    },

    dodge_and_compromise = 
    {
        name = "Dodge and Compromise",
        anim = "taunt3",
        desc = "Gain {EVASION} and {1} {IMPAIR}.",
        icon = "RISE:textures/unrelenting.png",

        flags =  CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.BASIC,
        target_mod = TARGET_MOD.TEAM,
        target_type = TARGET_TYPE.FRIENDLY_OR_SELF,

        impair_amount = 2,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.impair_amount))
        end,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("EVASION", 1, self)
            self.owner:AddCondition("IMPAIR", self.impair_amount, self)
        end
    },
    dodge_and_compromise_plus = 
    {
        name = "Dodge and Don't Compromise",
        desc = "Gain {EVASION}.",
        manual_desc = true,
    
        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("EVASION", 1, self)
        end
    },
    dodge_and_compromise_plus2 = 
    {
        name = "Double Dodge and Compromise",
        desc = "Gain <#UPGRADE>2</> {EVASION} and {IMPAIR}.",
        manual_desc = true,
    
       features = 
       {
            EVASION = 1,
       }
    },
    dodge_and_compromise_plus3 = 
    {
        name = "Dodge and Compromise of Clarity",
        desc = "Gain <#UPGRADE>4</> {EVASION} and {IMPAIR} <#UPGRADE>{CONSUME}</>.",
        manual_desc = true,
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.CONSUME,
        features = 
        {
            EVASION = 2,
        }
    },
    dodge_and_compromise_plus4 = 
    {
        name = "Dodge and Compromise of Lucidity",
        desc = "Gain <#UPGRADE>3</> {EVASION} and {IMPAIR} <#UPGRADE>{EXPEND}</>.",
        manual_desc = true,
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        features = 
        {
            EVASION = 1,
        }
    },
    dodge_and_compromise_plus5 = 
    {
        name = "Dodge and Compromise of Vision",
        desc = "Gain {EVASION} and {IMPAIR}. <#UPGRADE>Draw a card</>.",
        manual_desc = true,
        OnPostResolve = function( self, battle, attack)
            battle:DrawCards(1)
        end
    },
    dodge_and_compromise_plus6 = 
    {
        name = "Dodge and Compromise of Power",
        desc = "Gain {EVASION}, {IMPAIR} and <#UPGRADE>{TEMP_POWER} </>.",
        manual_desc = true,
        features = 
        {
            TEMP_POWER = 1,
            POWER = 1,
        }
    },
    dodge_and_compromise_plus7 = 
    {
        name = "Spiked Dodge and Compromise",
        desc = "Gain {EVASION}, {IMPAIR} and <#UPGRADE>3 {RIPOSTE} </>.",
        manual_desc = true,
        features = 
        {
            RIPOSTE = 3,
        }
    },
    dodge_and_compromise_plus8 = 
    {
        name = "Dodge and Compromise of Health",
        desc = "Gain {EVASION}, {IMPAIR} and <#UPGRADE>Heal for 2 health </>.",
        manual_desc = true,
        OnPostResolve = function( self, battle, attack )
            self.owner:HealHealth(2, self)
            self.owner:AddCondition("EVASION", 1, self)
            self.owner:AddCondition("IMPAIR", self.impair_amount, self)
        end,
    },

    flail_crack = 
    {
        name = "Flail Crack",
        rarity = CARD_RARITY.BASIC,
        cost = 1,
        max_xp = 6,
        flags = CARD_FLAGS.MELEE,
        icon = "RISE:textures/flailcrack.png",
        min_damage = 2,
        max_damage = 5,
        anim = "crack",
        
    },
    flail_crack_plus = 
    {
        name = "Boosted Flail Crack",
        min_damage = 3,
        max_damage = 6,
    },
    flail_crack_plus2 = 
    {
        name = "Mirrored Flail Crack",
        desc = "<#UPGRADE>Attack twice</>.",
        hit_anim = true,
        manual_desc = true,
        hit_count = 2,
    },
    flail_crack_plus3 = 
    {
        name = "Flail Crack of Clarity",
        desc = "<#UPGRADE>{CONSUME}</>.",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE | CARD_FLAGS.CONSUME,
        
        min_damage = 8,
        max_damage = 8,
    },
    flail_crack_plus4 = 
    {
        name = "Flail Crack of Lucidity",
        desc = "<#UPGRADE>{EXPEND}</>.",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,
        
        min_damage = 6,
        max_damage = 6,
    },
    flail_crack_plus5 = 
    {
        name = "Flail Crack of Stone",
        desc = "<#UPGRADE>Gain 2 {DEFEND}</>.",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE,
    
        features = 
        {
            DEFEND = 2,
        }
    },
    flail_crack_plus6 = 
    {
        name = "Flail Crack of Wounding",
        desc = "<#UPGRADE>Apply 1 {WOUND}</>.",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE,
        features = 
        {
            WOUND = 1,
        }
    },
    flail_crack_plus7 = 
    {
        name = "Flail Crack of Crippling",
        desc = "<#UPGRADE>Apply 1 {IMPAIR}</>.",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE,
        features = 
        {
            IMPAIR = 1,
        }
    },
    flail_crack_plus8 = 
    {
        name = "Flail Crack of Opportunity",
        desc = "<#UPGRADE>Shuffle a random weapon card into your draw pile</>.",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE,
        OnPostResolve = function( self, battle, attack)
            local weaponCards = {"flail_swap", "glaive_swap"}
            local randomCard = math.random(1,2)
            local card = Battle.Card( weaponCards[randomCard], self.owner )
            battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
        end
        
    },

    flail_smash = 
    {
        name = "Flail Smash",
        rarity = CARD_RARITY.BASIC,
        cost = 1,
        max_xp = 4,
        flags = CARD_FLAGS.MELEE,
        icon = "RISE:textures/flailsmash.png",
        min_damage = 2,
        max_damage = 4,
        anim = "smash",
        desc = "Deal damage then apply {1} {BURN}",
        burn_amount = 1,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.burn_amount ))
        end,
        
        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    target:AddCondition("BURN", self.burn_amount, self)
                end
            end
        end
    },
    flail_smash_plus =
    {
        name = "Burning Flail Smash",
        desc = "Apply <#UPGRADE>{1}</> {BURN}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.features.BURN ))
        end,
        manual_desc = true,
        features = 
        {
            BURN = 3,
        }
    },
    flail_smash_plus2 =
    {
        name = "Flail Smash of Clarity",
        desc = "<#UPGRADE>{CONSUME}</>",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE | CARD_FLAGS.CONSUME,
        
        min_damage = 8,
        max_damage = 8,
    },
    flail_smash_plus3 =
    {
        name = "Flail Smash of Lucidity",
        desc = "<#UPGRADE>{EXPEND}</>",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,
        
        min_damage = 6,
        max_damage = 6,
    },
    flail_smash_plus4 =
    {
        name = "Flail Smash of Stone",
        desc = "<#UPGRADE>Gain 2 {DEFEND}</>",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE,
        
       features = 
       {
        DEFEND = 2,
       }
    },
    flail_smash_plus5 =
    {
        name = "Boosted Flail Smash",
        flags = CARD_FLAGS.MELEE,
        
        min_damage = 3,
        max_damage = 5,
    },
    flail_smash_plus6 =
    {
        name = "Flail Smash of Opportunity",
        desc = "<#UPGRADE>Shuffle a random weapon card into your deck.</>",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE,
        
        OnPostResolve = function( self, battle, attack)
            local weaponCards = {"glaive_swap", "flail_swap"}
            local randomCard = math.random(1,2)
            local card = Battle.Card( weaponCards[randomCard], self.owner )
            battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
        end
    },
    flail_smash_plus7 =
    {
        name = "Spiked Flail Smash",
        desc = "<#UPGRADE>Gain 3 {RIPOSTE}.</>",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE,
        
        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("RIPOSTE", 3, self)
        end
    },
    flail_smash_plus8 =
    {
        name = "Flail Smash of Vision",
        desc = "<#UPGRADE>Draw a card.</>",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE,
        
        OnPostResolve = function( self, battle, attack )
            battle:DrawCards(1)
        end,
    },

    flail_slam = 
    {
        name = "Flail Slam",
        desc = "Apply {WOUND} then {WOUND} self.",
        icon = "RISE:textures/flailslam.png",
        anim = "slam",

        flags = CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.BASIC,

        cost = 1,
        max_xp = 6,
        min_damage = 4,
        max_damage = 4,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition( "WOUND", 1 )
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    -- target:AddCondition("IMPAIR", 1, self)
                    target:AddCondition("WOUND", 1, self)
                end
            end
        end
    },
    flail_slam_plus = 
    {
        name = "Flail Slam of Crippling",
        desc = "Apply {WOUND} and <#UPGRADE>{IMPAIR}</> then {WOUND} self.",   
        manual_desc = true,
        features = 
        {
            IMPAIR = 1,
            WOUND = 1,
        }
    },
    flail_slam_plus2 = 
    {
        name = "Boosted Flail Slam",
        desc = "Apply {WOUND} then {WOUND} self.",   
        manual_desc = true,
        
        min_damage = 5,
        max_damage = 6,
    },
    flail_slam_plus3 = 
    {
        name = "Flail Slam of Wounding",
        desc = "Apply <#UPGRADE>2</> {WOUND} then {WOUND} self.",   
        manual_desc = true,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.features.WOUND ))
        end,

        features = 
        {
            WOUND = 2,
        }
    },
    flail_slam_plus4 = 
    {
        name = "Flail Slam of Lucidity",
        desc = "Apply {WOUND} then {WOUND} self <#UPGRADE>{EXPEND}</>.",   
        manual_desc = true,

        flags = CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,

        min_damage = 8,
        max_damage = 10,

    },
    flail_slam_plus5 = 
    {
        name = "Flail Slam of Vision",
        desc = "Apply {WOUND} then {WOUND} self. <#UPGRADE>Draw a Card</>.",   
        manual_desc = true,

        flags = CARD_FLAGS.MELEE,

        OnPostResolve = function( self, battle, attack )
            battle:DrawCards(1)
        end,
    },
    flail_slam_plus6 = 
    {
        name = "Flail Slam of Normalty",
        desc = "<#UPGRADE>Apply {WOUND}</>.",   
        manual_desc = true,

        flags = CARD_FLAGS.MELEE,

        OnPostResolve = function( self, battle, attack )
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    -- target:AddCondition("IMPAIR", 1, self)
                    target:AddCondition("WOUND", 1, self)
                end
            end
        end,
    },

    safeguard = 
    {
        name = "Safeguard",
        rarity = CARD_RARITY.BASIC,
        cost = 1,
        desc = "Apply {1} {DEFEND} then gain {equip_flail}.",

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.defend_amount ))
        end,

        icon = "RISE:textures/safeguard.png",
        anim = "defend",
        target_type = TARGET_TYPE.FRIENDLY_OR_SELF,
        rarity = CARD_RARITY.BASIC,
        cost = 1,
        max_xp = 6,
        flags = CARD_FLAGS.SKILL,
        defend_amount = 4,

        OnPostResolve = function( self, battle, attack )
            attack:AddCondition( "DEFEND", self.defend_amount, self )
            self.owner:AddCondition("equip_flail", 1, self)
        end,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_flail)
        end
    },
    safeguard_plus = 
    {
        name = "Boosted Safeguard",
        desc = "Apply 6 {DEFEND} then <#UPGRADE>equip {equip_flail}</>.",
        
        manual_desc = true,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.features.DEFEND ))
        end,    

        features = 
        {
            DEFEND = 2,
        }
    },
    safeguard_plus2 = 
    {
        name = "Safeguard of Opportunity",
        desc = "Apply 4 {DEFEND} then <#UPGRADE>equip {equip_glaive}</>.",
        manual_desc = true,
        anim = "transition1",

        OnPostResolve = function( self, battle, attack )
            attack:AddCondition( "DEFEND", self.defend_amount, self )
            self.owner:AddCondition("equip_glaive", 1, self)
        end,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        end
    },
    safeguard_plus3 = 
    {
        name = "Safeguard of Clarity",
        desc = "Apply <#UPGRADE>10</> {DEFEND} and gain {equip_flail}. <#UPGRADE>{CONSUME}</>.",
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.CONSUME,

        manual_desc = true,

        features = 
        {
            DEFEND = 6,
        }
    },
    safeguard_plus4 = 
    {
        name = "Safeguard of Lucidity",
        desc = "Apply <#UPGRADE>8</> {DEFEND} and gain {equip_flail}. <#UPGRADE>{EXPEND}</>.",
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,

        manual_desc = true,

        features = 
        {
            DEFEND = 4,
        }
    },
    safeguard_plus5 = 
    {
        name = "Safeguard of Vision",
        desc = "Apply 6 {DEFEND}. <#UPGRADE>Draw a card</> and gain {equip_flail}.",
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,

        manual_desc = true,

        OnPostResolve = function( self, battle, attack )
            attack:AddCondition( "DEFEND", self.defend_amount, self )
            battle:DrawCards(1)
        end,
    },
    safeguard_plus5 = 
    {
        name = "Spiked Safeguard",
        desc = "Apply 4 {DEFEND}. <#UPGRADE>Gain 2 {RIPOSTE}</> and gain {equip_flail}.",
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,

        manual_desc = true,

        OnPostResolve = function( self, battle, attack )
            self.owner:AddCondition("RIPOSTE", 2, self)
        end,
    },
    safeguard_plus6 = 
    {
        name = "Safeguard of Hesh",
        desc = "Apply {1} {DEFEND}.\n<#UPGRADE>Remove a random debuff and gain {equip_flail}</>.",
        flags = CARD_FLAGS.SKILL,

        OnPostResolve = function( self, battle, attack )
            attack.target:AddCondition("DEFEND", self.defend_amount, self)
            attack.target:RemoveDebuff()
        end,
    },
    safeguard_plus7 = 
    {
        name = "Safeguard of Variety",
        desc = "Apply {1} {DEFEND}.\n<#UPGRADE>Shuffle a random weapon card into your draw pile and gain {equip_flail}</>.",
        flags = CARD_FLAGS.SKILL,

        OnPostResolve = function( self, battle, attack )
            attack:AddCondition( "DEFEND", self.defend_amount, self )
            local weaponCards = {"glaive_swap", "flail_swap"}
            local randomCard = math.random(1,2)
            local card = Battle.Card( weaponCards[randomCard], self.owner )
            battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
        end,
    },
    safeguard_plus8 = 
    {
        name = "Safeguard of Wealth",
        desc = "Apply {1} {DEFEND}.\n<#UPGRADE>Shuffle 2 drink cards into your draw pile and gain {equip_flail}</>.",
        flags = CARD_FLAGS.SKILL,

        OnPostResolve = function( self, battle, attack )
            attack:AddCondition( "DEFEND", self.defend_amount, self )
            local drinkCards = {"green_flask", "red_flask", "purple_flask"}
            local randomCard1 = math.random(1,3)
            local randomCard2 = math.random(1,3)

            local card1 = Battle.Card( drinkCards[randomCard1], self.owner )
            battle:DealCard( card1, battle:GetDeck( DECK_TYPE.DRAW ) )

            local card2 = Battle.Card( drinkCards[randomCard2], self.owner )
            battle:DealCard( card2, battle:GetDeck( DECK_TYPE.DRAW ) )
        end,
    },

    devise = 
    {
        name = "Devise",
        anim = "taunt",
        desc = "{IMPROVISE} a card from a pool of special cards.",
        target_type = TARGET_TYPE.SELF,

        icon = "RISE:textures/devise.png",
        rarity = CARD_RARITY.BASIC,
        flags = CARD_FLAGS.SKILL,
        cost = 1,
        has_checked = false,

        pool_size = 3,

        pool_cards = {"improvise_rage", "improvise_burningsmash", "improvise_smokescreen", "improvise_invincible", "improvise_weird_colored_flask", "improvise_drink" },

        OnPostResolve = function( self, battle, attack)
            local cards = ObtainWorkTable()

            cards = table.multipick( self.pool_cards, self.pool_size )
            for k,id in pairs(cards) do
                cards[k] = Battle.Card( id, self.owner  )
            end
            battle:ImproviseCards( cards, 1 )
            ReleaseWorkTable(cards)
        end
    },

    quickdraw = 
    {
        name = "Quickdraw",
        anim = "gun2",
        desc = "Blast an enemy for every 2 cards in your discard pile.",
        icon = "battle/bog_blaster.tex",
        -- icon = "RISE:textures/quickdraw.png",
        min_damage = 2,
        max_damage = 2,
        max_xp = 6,
        cost = 1,
        flags = CARD_FLAGS.RANGED,
        rarity = CARD_RARITY.COMMON,
        hit_anim = true,

        OnPostResolve = function( self, battle, attack )
            self.hit_count = 1
        end,

        event_handlers =
        {
            [ BATTLE_EVENT.START_RESOLVE ] = function( self, battle, attack )
                if attack == self then
                    if self.engine:GetDiscardDeck():CountCards() > 0 then
                        self.hit_count = (self.hit_count or 1) + self.engine:GetDiscardDeck():CountCards() / 2
                    end
                end
            end,
        }
    },

    sliceup =
    {
        name = "Slice Up",
        anim = "slash_up",
        desc = "{KINGPIN} 10: Apply random debuffs, random stacks of the debuff and a random amount of debuffs to enemies.",
        icon = "RISE:textures/sliceup1.png",
        
        min_damage = 5,
        max_damage = 7,
        cost = 1,
        max_xp = 6,
        flags = CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNCOMMON,

        -- desc_fn = function(self, fmt_str)
        --     return loc.format(fmt_str, self:CalculateDefendText( self.bleed_amount ))
        -- end,

        OnPostResolve = function( self, battle, attack)
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 10 then
                    local randomDebuffList = {"SHATTER", "EXPOSED", "TARGETED", "WOUND", "DEFECT", "IMPAIR", "BLEED"}
                    local amountOfDebuffs = math.random(1,3)
                    for i, hit in attack:Hits() do
                        local target = hit.target
                        if not hit.evaded then 
                            for i=1, amountOfDebuffs, 1 do
                                local randomDebuff = math.random(1,7)
                                local randomStacks = math.random(1,3)
                                target:AddCondition(randomDebuffList[randomDebuff], randomStacks, self)
                            end
                        end
                    end
                end
            end
        end
    },

    spinningslash = 
    {
        name = "Spinning Slash",
        anim = "spin_attack",
        desc = "{KINGPIN} 10: Deal bonus for every 5 {KINGPIN} stacks.",
        icon = "RISE:textures/spinningslash.png",

        min_damage = 4,
        max_damage = 6,
        cost = 1,
        max_xp = 6,
        flags = CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNCOMMON,
        bonus_damage = 1,

        event_handlers = 
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card == self then
                    if self.owner:HasCondition("KINGPIN") then
                        if self.owner:GetConditionStacks("KINGPIN") >= 10 then
                            dmgt:AddDamage(math.floor(self.owner:GetConditionStacks("KINGPIN") / 5), math.floor(self.owner:GetConditionStacks("KINGPIN") / 5), self)
                        end
                    end
                end
            end
        }
        
    },

    swap_weapon = 
    {
        name = "Swap Weapons",
        anim = "taunt",
        desc = "Insert {flail_swap} or {glaive_swap} into your hand.",
        icon = "RISE:textures/swap_weapon.png",

        rarity = CARD_RARITY.BASIC,
        flags = CARD_FLAGS.SKILL,
        target_type = TARGET_TYPE.SELF,

        cost = 1,

        OnPostResolve = function( self, battle, attack)
            local cards = {
                Battle.Card( "flail_swap", self.owner ),
                Battle.Card( "glaive_swap", self.owner ),
            }
            battle:ChooseCardsForHand( cards )
        end,
    },
    swap_weapon_plus = 
    {
        name = "Weapon Swap of Opportunity",
        desc = "<#UPGRADE>Shuffle 4 random weapon swap cards into your draw or discard pile</>.",
       
        OnPostResolve = function( self, battle, attack )
            local cards = {"glaive_swap", "flail_swap"}
            local deckType = { "DISCARDS", "DRAW" }
            for i=1,4,1 do
                local randomCard = math.random(1,2)
                local randomDeck = math.random(1,2)
                local card = Battle.Card( cards[randomCard], self.owner )
                battle:DealCard( card, battle:GetDeck( deckType[randomDeck] ) )
            end
        end,
    },
    swap_weapon_plus2 = 
    {
        name = "Weapon Swap of Precision",
        desc = "Insert {flail_swap} or {glaive_swap} into your hand then <#UPGRADE>shuffle the opposite weapon card you have equipped to your draw pile</>.",
       
        OnPostResolve = function( self, battle, attack )
            local cards = {
                Battle.Card( "flail_swap", self.owner ),
                Battle.Card( "glaive_swap", self.owner ),
            }
            battle:ChooseCardsForHand( cards )
            if self.owner:HasCondition("equip_glaive") then
                local card = Battle.Card( "flail_swap", self.owner )
                battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
            elseif self.owner:HasCondition("equip_flail") then 
                local card = Battle.Card( "glaive_swap", self.owner )
                battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
            end
        end,
    },
    swap_weapon_plus3 = 
    {
        name = "Weapon Swap of the Gods",
        desc = "<#UPGRADE>Swap to the next weapon, then shuffle 2 weapon cards of the same weapon you were using</>.",

        PostPresAnim = function( self, anim_fighter )
            if self.owner:HasCondition("equip_flail") then
                anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
            elseif self.owner:HasCondition("equip_glaive") then
                anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_flail)
            end
        end,
       
        OnPostResolve = function( self, battle, attack )
            if self.owner:HasCondition("equip_glaive") then
                self.owner:AddCondition("equip_flail", 1, self)
                for i=1,2,1 do
                    local card = Battle.Card( "glaive_swap", self.owner )
                    battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
                end
            elseif self.owner:HasCondition("equip_flail") then
                self.owner:AddCondition("equip_glaive", 1, self)
                for i=1,2,1 do
                    local card = Battle.Card( "flail_swap", self.owner )
                    battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
                end
            end

        end,
    },
    swap_weapon_plus4 = 
    {
        name = "Glory to Rentoria",
        desc = "<#UPGRADE>Gain 5 {KINGPIN} and 5 {DEFEND}</>.",
        icon = "battle/assassins_mark.tex",

        OnPostResolve = function( self, battle, attack )
            self.owner:AddCondition("KINGPIN", 5, self)
            self.owner:AddCondition("DEFEND", 5, self)
        end,
    },

    flail_swap =
    {
        name = "Kashio's Flail",
        desc = "Equip {equip_flail} and gain {DEFEND} equal to 5% of your maximum health and current defend then {HEAL} self for 10% of your missing health every turn. Also have a 25% chance to apply a random debuff to an enemy on hit.",
        icon = "battle/overloaded_spark_hammer.tex",
        anim = "taunt",

        flags = CARD_FLAGS.BUFF | CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.REPLENISH,
        target_type = TARGET_TYPE.SELF,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,


        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_flail)
        end,

        OnPostResolve = function( self, battle, attack )
            self.owner:AddCondition("equip_flail", 1 )
        end,

       
    },

    glaive_swap = 
    {
        name = "Kashio's Force Glaive",
        desc = "Equip the Rentorian Force Glaive gaining extra damage with your attacks and an extra action per turn at the cost of taking more damage and halving {DEFEND}.",
        icon = "battle/rentorian_force_glaive.tex",
        anim = "transition1",

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.REPLENISH,
        target_type = TARGET_TYPE.SELF,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        end,
        
        OnPostResolve = function( self, battle, attack )
            self.owner:AddCondition("equip_glaive", 1 )
        end,
    },

    suitcase_grenade = 
    {
        name = "Suitcase Grenades",
        anim = "throw1",
        icon = "battle/suitcase_grenades.tex",
        desc = "Hits all enemies {1} times. {KINGPIN} 10: Have a chance to gain {INVINCIBLE}.",

        target_mod = TARGET_MOD.TEAM,
        flags = CARD_FLAGS.RANGED,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        min_damage = 1,
        max_damage = 2,
        max_xp = 6,
        hit_count = 3,
        hit_anim = true,

        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self:CalculateDefendText(self.hit_count))
        end,

        OnPostResolve = function( self, battle, attack )
            self.owner:AddCondition("equip_glaive", 1 )
            local randomChance = math.random(1,2)
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 10 then
                    if randomChance == 1 then
                        self.owner:AddCondition("INVINCIBLE", 1, self)
                    end
                end
            end
        end,

    },

    call_lumicyte = 
    {
        name = "Call Lumicyte",
        anim = "taunt4",
        desc = "Summons your Lumicyte pet to fight for you.",
        icon = "battle/krill_ichor.tex",

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.REPLENISH | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,
        target_type = TARGET_TYPE.SELF,

        CanPlayCard = function( self, battle, target )
            return self.owner:GetTeam():NumActiveFighters() < self.owner:GetTeam():GetMaxFighters(), CARD_PLAY_REASONS.TEAM_FULL
        end,

        OnPostResolve = function( self, battle, attack )
            local summon = Agent( "LUMICYTE_UPGRADED" )
            local fighter = Fighter.CreateFromAgent( summon, battle:GetScenario():GetAllyScale() )
            self.owner:GetTeam():AddFighter( fighter )
            self.owner:GetTeam():ActivateNewFighters()
        end,
    },

    kill_with_kindness = 
    {
        name = "Kill With Kindness",
        anim = "taunt3",
        desc = "Deal damage to all enemies equal to half your block.",
        icon = "battle/dugout.tex",

        flags = CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
        target_mod = TARGET_MOD.TEAM,
        min_damage = 0,
        max_damage = 0,

        event_handlers = 
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card == self then
                    if self.owner:HasCondition("DEFEND") then
                        dmgt:AddDamage( math.round(self.owner:GetConditionStacks("DEFEND")) / 2, math.round(self.owner:GetConditionStacks("DEFEND")) / 2 , self )
                    end
                end
            end
        }

    },

    deflect = 
    {
        name = "Deflect",
        anim = "taunt3",
        desc = "Gain {1} {DEFLECTION}, {KINGPIN} 15: Deal half the damage enemies will deal to you instead and defend for the same amount.",
        icon = "battle/hammer_swing.tex",

        flags = CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        deflection_amount = 3,

        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.deflection_amount or 1 )
        end,

        OnPostResolve = function( self, battle, attack )
            self.owner:AddCondition("DEFLECTION", self.deflection_amount)
        end
    },

    afterburner_gloves =
    {
        name = "Afterburner Gloves", 
        anim = "taunt",
        desc = "Gain {AFTERBURN_GLOVES} and apply {BURN} to all fighters.",
        icon = "battle/workers_gloves.tex",

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_mod = TARGET_MOD.TEAM,
        burn_amount = 1,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                if not attack:CheckHitResult( hit.target, "evaded" ) then
                    hit.target:AddCondition("BURN", 1)
                end
            end
            self.owner:AddCondition("BURN", self.burn_amount, self)
            self.owner:AddCondition("AFTERBURN_GLOVES", 3, self)
        end,
    },

    masochistic_strike =
    {
        name = "Masochistic Strikes",
        anim = "crack",
        desc = "Hit your target for every debuff a random enemy has then gain all of your target's conditions.",
        icon = "battle/weakness_slow.tex",

        flags = CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
        min_damage = 2,
        max_damage = 2,
        hit_anim = true,

        PreReq = function( self, battle, target, attack )
            local count = 0
            local target_fighter = {}
            battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
            for i=1, #target_fighter do
                for i,condition in pairs(target_fighter[i]:GetConditions()) do
                    if condition.ctype == CTYPE.DEBUFF then
                        count = count + condition:GetStacks()
                    end
                end
            end
            if count > 0 then 
                self.hit_count = count
            end
            if count == 0 then 
                self.hit_count = 1
            end
        end,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                for i,condition in pairs(hit.target:GetConditions()) do
                    if condition.ctype == CTYPE.DEBUFF then
                        self.owner:AddCondition(condition:GetID(), condition:GetStacks(), self)
                    end
                end
            end
        end,
    },

    hologram_belt = 
    {
        name = "Kashio's Hologram Belt",
        anim = "taunt4",
        desc = "Summon two copies of Kashio to fight for you.",
        icon = "battle/hologram_projection_belt.tex",

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.REPLENISH | CARD_FLAGS.EXPEND,
        cost = 0,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,
        target_type = TARGET_TYPE.SELF,

        CanPlayCard = function( self, battle, target )
            return self.owner:GetTeam():NumActiveFighters() < self.owner:GetTeam():GetMaxFighters(), CARD_PLAY_REASONS.TEAM_FULL
        end,

        OnPostResolve = function( self, battle, attack )
            local summon = Agent( "KASHIO_HOLO_PLAYER" )
            local summon2 = Agent( "KASHIO_HOLO_PLAYER" )

            local fighter = Fighter.CreateFromAgent( summon, battle:GetScenario():GetAllyScale() )
            local fighter2 = Fighter.CreateFromAgent( summon2, battle:GetScenario():GetAllyScale() )

            self.owner:GetTeam():AddFighter( fighter )
            self.owner:GetTeam():AddFighter( fighter2 )
            self.owner:GetTeam():ActivateNewFighters()
        end,
    },

    summon_auto_mech =
    {
        name = "Summon Sparkbaron Automech",
        anim = "taunt",
        desc = "Summon a Sparkbaron Automech to fight for you.",
        icon = "battle/screamer.tex",

        target_type = TARGET_TYPE.SELF,
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 2,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,

        OnPostResolve = function( self, battle, attack )
            local agent = Agent("SPARK_BARON_AUTOMECH")
            local fighter = Fighter.CreateFromAgent( agent, 1 )
            self.owner:GetTeam():AddFighter( fighter )
            self.owner:GetTeam():ActivateNewFighters()
        end
    },

    sonic_pistol = 
    {
        name = "Sonic Pistol",
        anim = "gun1",
        desc = "This card costs 0 if you have {equip_glaive} equipped.  {KINGPIN} 15: Gain {INVINCIBLE}",
        icon = "battle/lifeline.tex",

        min_damage = 2,
        max_damage = 3,

        flags = CARD_FLAGS.RANGED,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        OnPostResolve = function( self, battle, attack )
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 15 then
                    self.owner:AddCondition("INVINCIBLE", 1 , self)
                end
            end
        end,

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_ACTION_COST ] = function( self, cost_acc, card, target )
                if card == self then
                    if self.owner:HasCondition("equip_glaive") then
                        cost_acc:ModifyValue(0, self)
                    end
                end
            end
        },

    },

    undying_will = 
    {
        name = "Undying Will",
        anim = "taunt4",
        desc = "{HEAL} for {1} for every debuff you have.",
        icon = "RISE:textures/undyingwill.png",

        flags = CARD_FLAGS.BUFF | CARD_FLAGS.HEAL | CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        heal_amount = 2,
        target_type = TARGET_TYPE.SELF,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.heal_amount))
        end,

        OnPostResolve = function( self, battle, attack)
            local count = 0
            for i,condition in pairs(self.owner:GetConditions()) do
                if condition.ctype == CTYPE.DEBUFF then
                    count = count + 1 
                end
            end
            self.owner:HealHealth(self.heal_amount + count, self)
        end,
    },

    taste_of_blood = 
    {
        name = "Taste of Blood",
        anim = "slash_up",
        desc = "Apply {1} {BLEED} to target enemy and to self. {KINGPIN} 10: Apply double the amount of bleed to the enemy.",
        icon = "RISE:textures/cripplingstrike.png",

        flags = CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
        
        min_damage = 3,
        max_damage = 5,

        bleed_amount = 3,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.bleed_amount))
        end,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    if self.owner:HasCondition("KINGPIN") then
                        if self.owner:GetConditionStacks("KINGPIN") >= 10 then
                            target:AddCondition("BLEED", self.bleed_amount * 2, self)
                        else
                            target:AddCondition("BLEED", self.bleed_amount, self)
                        end
                    else
                        target:AddCondition("BLEED", self.bleed_amount, self)
                    end
                    self.owner:AddCondition("BLEED", self.bleed_amount, self)
                end
            end
        end
        
    },

    crippling_slice = 
    {
        name = "Crippling Slice",
        anim = "slash_up",
        desc = "Apply {1} {IMPAIR} to target enemy if you have Taste of Blood in your hand.  {KINGPIN} 5: Apply {1} {IMPAIR}.",
        icon = "battle/weakness_old_injury.tex",

        flags = CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
        
        min_damage = 3,
        max_damage = 5,

        impair_amount = 2,
        hasTOB = false,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.impair_amount))
        end,

        OnPostResolve = function( self, battle, attack)
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 5 then
                    for i, hit in attack:Hits() do
                        local target = hit.target
                        if not hit.evaded then 
                            target:AddCondition("IMPAIR", self.impair_amount, self)
                        end
                    end
                end
            end
            for i, card in battle:GetHandDeck():Cards() do
                if card.id == "taste_of_blood" then
                    self.hasTOB = true
                end
            end
            if self.hasTOB == true then
                for i, hit in attack:Hits() do
                    local target = hit.target
                    if not hit.evaded then 
                        target:AddCondition("IMPAIR", self.impair_amount, self)
                    end
                end
            end
        end
    },

    feel_what_i_feel = 
    {
        name = "Feel What I Feel",
        anim = "crack",
        desc = "Apply all self debuffs to target enemy.",
        icon = "RISE:textures/feelwhatifeel.png",

        flags = CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        -- target_type = TARGET_TYPE.ENEMY,
        min_damage = 3,
        max_damage = 5,

        OnPostResolve = function( self, battle, attack)
            for i,condition in pairs(self.owner:GetConditions()) do
                if condition.ctype == CTYPE.DEBUFF then
                    attack:AddCondition(condition:GetID(), condition:GetStacks(), self)
                end
            end
        end
    },

    the_culling = 
    {
        name = "The Culling",
        anim = "spin_attack",
        desc = "Deal damage to all enemies and deal bonus damage equal to your debuff stacks.",
        icon = "RISE:textures/theculling.png",

        flags = CARD_FLAGS.MELEE,
        cost = 2,
        rarity = CARD_RARITY.RARE,
        max_xp = 3,
        target_mod = TARGET_MOD.TEAM,

        min_damage = 5,
        max_damage = 5,

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                local count = 0
                if card == self then
                    for i,condition in pairs(self.owner:GetConditions()) do
                        if condition.ctype == CTYPE.DEBUFF then
                            count = count + condition:GetStacks(condition:GetID())
                        end
                    end
                    dmgt:AddDamage( count, count, self )
                end
            end
        }
    },

    raging_slam =
    {
        name = "Raging Slam",
        anim = "slam",
        desc = "Damage a random enemy and gain {EXPOSED}. If {equip_flail} is active, the enemy hit gains {IMPAIR}.",
        icon = "RISE:textures/ragingslam.png",

        flags = CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
        target_mod = TARGET_MOD.RANDOM1,

        min_damage = 6,
        max_damage = 7,  
        exposed_amount = 1,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.exposed_amount))
        end,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("EXPOSED", self.exposed_amount)
            if self.owner:HasCondition("equip_flail") then
                for i, hit in attack:Hits() do
                    local target = hit.target
                    if not hit.evaded then 
                        target:AddCondition("IMPAIR", self.exposed_amount, self)
                    end
                end
            end
        end

    },

    strength_of_one_thousand = 
    {
        name = "Strength of One Thousand",
        anim = "defend",
        desc = "Gain {scaling_defense}.",
        icon = "RISE:textures/strengthofonethousand.png",

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.BUFF,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("scaling_defense", 1)
        end
    },

    no_mercy = 
    {
        name = "No Mercy",
        anim = "spin_attack",
        desc = "Deals 75% of the enemy's missing health. {KINGPIN} 15: This card costs 1.",
        icon = "battle/bonkers.tex",

        flags = CARD_FLAGS.MELEE,
        cost = 2,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 2,
        max_damage = 2,

        OnPostResolve = function( self, battle, attack)
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 15 then
                    cost_acc:ModifyValue(1, self)
                end
            end
        end,
        
        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card == self and target then
                    local bonus = math.floor(( target:GetMaxHealth() - target:GetHealth()) * 0.75)
                    dmgt:AddDamage( bonus, bonus )
                end
            end,
        },
    },

    half_and_half = 
    {
        name = "Half and Half",
        anim = "throw2",
        desc = "Deals damage then applies {BURN} or {BLEED} equal to the damage dealt by this card.",
        icon = "RISE:textures/halfandhalf.png",
        flavour = "You don't know what you're going to get inside, either a 3rd degree burn or a pile of spikes, right to the face.",

        flags = CARD_FLAGS.RANGED,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 1,
        max_damage = 5,

        OnPostResolve = function( self, battle, attack)
            local randomNum = math.floor(math.random() * 2)
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    if randomNum == 0 then
                        target:AddCondition("BLEED", hit.damage, self)
                    end
                    if randomNum == 1 then 
                        target:AddCondition("BURN", hit.damage, self)
                    end
                end
            end
        end
    },

    defensive_manuevers = 
    {
        name = "Defensive Manuevers",
        anim = "defend",
        desc = "Gain {1} {DEFEND}, if {equip_flail} is active gain 7 {DEFEND} instead.",
        icon = "battle/scatter.tex",

        flags = CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        defend_amount = 4,
        target_type = TARGET_TYPE.SELF,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText(self.defend_amount))
        end,

        OnPostResolve = function( self, battle, attack)
            if self.owner:HasCondition("equip_flail") then
                self.owner:AddCondition("DEFEND", 7)
            else
                self.owner:AddCondition("DEFEND", self.defend_amount)
            end
        end
    },

    bait_and_switch = 
    {
        name = "Bait and Switch",
        anim = "spin_attack",
        desc = "Deal damage then switch to {equip_glaive}. If it is already equipped, draw a card.",
        icon = "RISE:textures/baitandswitch.png",

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 2,
        max_damage = 3,

        OnPostResolve = function( self, battle, attack)
            if self.owner:HasCondition("equip_glaive") then
                 battle:DrawCards(1)
            else
                self.owner:AddCondition("equip_glaive", 1)
            end
        end,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        end,
        
    },

    bounce_back = 
    {
        name = "Bounce Back",
        anim = "slam",
        desc = "Deal damage equal to half the amount of damage the enemy team is intending to inflict to your team.",
        icon = "battle/weakness_blind_spot.tex",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,

        min_damage = 0,
        max_damage = 0,

        OnPostResolve = function( self, battle, attack )
                   
        end,

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card == self then
                    local count = 0
                    for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                        if enemy.prepared_cards then
                            for i, card in ipairs( enemy.prepared_cards ) do
                                if card:IsAttackCard() then
                                    count = count + card.max_damage
                                end
                            end
                        end
                        dmgt:ModifyDamage( math.floor(count/2), math.floor(count/2), self )
                    end
                end
            end
        }
        
    },

    grandslam = 
    {
        name = "Grand Slam",
        anim = "slam",
        desc = "Damage all enemies and deal bonus damage if {equip_flail} is active.",
        icon = "RISE:textures/grandslam.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 2,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,

        min_damage = 5,
        max_damage = 6,
        target_mod = TARGET_MOD.TEAM,

        event_priorities =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = EVENT_PRIORITY_SETTOR,
        },

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card == self then
                    if self.owner:HasCondition("equip_flail") then
                        dmgt:AddDamage( 2, 3, self )
                    end
                end
            end
        }
    },

    consume_pain = 
    {
        name = "Consume Pain",
        anim = "taunt",
        desc = "Consume all debuffs, dealing 1 damage to self for each debuff then gain power equal to consumed debuffs.",
        icon = "battle/improvise_chug.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 2,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 4,
        target_type = TARGET_TYPE.SELF,

        OnPreResolve = function(self, battle, attack, card)
            for i, condition in pairs(self.owner:GetConditions()) do
                if condition.ctype == CTYPE.DEBUFF then
                    self.owner:AddCondition("POWER", condition:GetStacks(), self)
                    self.owner:DeltaHealth(-condition:GetStacks())
                    -- self.owner:RemoveCondition(condition:GetID(), condition:GetStacks()
                end
            end
        end,

        OnPostResolve = function( self, battle, attack, card )
            for i, condition in pairs(self.owner:GetConditions()) do
                if condition.ctype == CTYPE.DEBUFF then
                    self.owner:RemoveCondition(condition:GetID())
                end
            end
        end,
    },

    force_field = 
    {
        name = "Rentorian Force Field",
        anim = "taunt",
        desc = "Gain {FORCE_FIELD}. If {equip_glaive} is active, gain 3 stacks of {FORCE_FIELD}.",
        icon = "battle/arc_deflection.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 2,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 4,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack, card )
            if self.owner:HasCondition("equip_glaive") then
                self.owner:AddCondition("FORCE_FIELD", 3, self)
            else
                self.owner:AddCondition("FORCE_FIELD", 1, self)
            end
        end,
    },

    fake_surrender = 
    {
        name = "Plead for Life",
        anim = "surrender",
        desc = "Have a small chance of gaining {PLEAD_FOR_LIFE} for 1 turn depending on your missing health.",
        icon = "battle/doomed.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 2,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 4,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack, card )
            local chance = math.floor(self.owner:GetHealth() / self.owner:GetMaxHealth() * 100)
            chance = 100 - chance
            local randomChance = math.random(1,100)
            if chance >= randomChance then
                self.owner:AddCondition("PLEAD_FOR_LIFE", 1 , self)
                for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                    enemy:AddCondition("DEFECT", 1)
                end
            end
        end,

        -- event_handlers = 
        -- {
        --     [ BATTLE_EVENT.PLAY_ANIM ] = function( self, anim_fighter, battle )
        --         anim_fighter:Flash(0xff00ffff, 0.1, 0.3, 1)
        --     end
        -- }
    },


 blade_dance = 
    {
        name = "Blade Dance",
        anim = "transition1",
        desc = "Gain stacks of {BLADE_DANCE} depending on a random enemy's current health, place {flail_swap} or {glaive_swap} into your hand depending on what weapon is currently equipped.",
        icon = "battle/blade_fury.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 2,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function(self, battle, attack, card)
            self.owner:AddCondition("equip_glaive", 1)
            local randomEnemyHealth = 0
            local target_fighter = {}
            battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
                for i=1, #target_fighter do
                    randomEnemyHealth = target_fighter[i]:GetHealth()
                end
                randomEnemyHealth = math.round(randomEnemyHealth * 0.60)
            self.owner:AddCondition("BLADE_DANCE", randomEnemyHealth, self)
            local weapons = {"flail_swap", "glaive_swap"}
            if self.owner:HasCondition("equip_glaive") then
                local card = Battle.Card( weapons[1], self.owner )
                battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
            elseif self.owner:HasCondition("equip_flail") then
                local card = Battle.Card( weapons[2], self.owner )
                battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
            end
        end
    },


    flurry = 
    {
        name = "Flurry",
        anim = "taunt4",
        desc = "Gain {FLURRY} and gain 5 flurry daggers.",
        icon = "battle/daggerstorm.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 2,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("FLURRY")
            for i=0,4,1 do
                local card = Battle.Card( "flurry_dagger", self.owner )
                card:TransferCard( battle:GetHandDeck() )
            end
        end,
    },

    flurry_dagger = 
    {
        name = "Flurry Dagger",
        anim = "spin_attack",
        icon = "battle/discharge.tex",

        flags =  CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,
        
        min_damage = 1,
        max_damage = 1,
    },

    the_execution = 
    {
        name = "The Execution",
        desc = "Gain {KINGPIN} status, which can unlock the full potential of certain cards.",
        anim = "transition1",
        icon = "RISE:textures/tempt.png",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.REPLENISH,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        -- PostPresAnim = function( self, anim_fighter )
        --     anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        -- end,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("KINGPIN", 1, self)
            -- self.owner:AddCondition("equip_glaive", 1 )
        end
    },

    slice_and_dice = 
    {
        name = "Slice and Dice",
        desc = "{KINGPIN} 5: Draw Slicer and Dicer into your hand.",
        anim = "spin_attack",
        icon = "RISE:textures/slice_and_dice.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 2,
        max_damage = 4,

        OnPostResolve = function( self, battle, attack, card )
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 5 then
                    local card1 = Battle.Card( "slicer", self.owner )
                    local card2 = Battle.Card( "dicer", self.owner )
                    card1:TransferCard( battle:GetHandDeck() )
                    card2:TransferCard( battle:GetHandDeck() )
                end
            end
        end
    },
    
    slicer = 
    {
        name = "Slicer",
        anim = "spin_attack",
        icon = "battle/duster.tex",

        flags =  CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,

        min_damage = 3,
        max_damage = 3,
    },

    dicer = 
    {
        name = "Dicer",
        anim = "slash_up",
        icon = "battle/gash.tex",

        flags =  CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,

        min_damage = 2,
        max_damage = 6,
    },

    readied_assault =
    {
        name = "Readied Assault",
        anim = "spin_attack",
        desc = "{KINGPIN} 10: Deal max damage and gain {DEFEND} equal to your max damage.",
        icon = "RISE:textures/readied_assault.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 1,
        max_damage = 6,

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if self.owner:HasCondition("KINGPIN") then
                    if self.owner:GetConditionStacks("KINGPIN") >= 10 then
                        if self.owner == card.owner then
                            dmgt:ModifyDamage( dmgt.max_damage, dmgt.max_damage, self )
                            self.owner:AddCondition("DEFEND", self.max_damage, self)
                        end
                    end
                end
            end,
        }
    },

    ultimate_hunter = 
    {
        name = "Ultimate Hunter",
        anim = "taunt",
        desc = "Gain {ULTIMATE_HUNTER} then place {flail_swap} or {glaive_swap} in your hand depending on which weapon you currently have equipped.",
        icon = "battle/butcher_of_the_bog.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("ULTIMATE_HUNTER", 1, self)
            -- if self.owner:HasCondition("equip_flail") then
            --     self.owner:AddCondition("equip_glaive", 1 , self)
            -- elseif self.owner:HasCondition("equip_glaive") then
            --     self.owner:AddCondition("equip_flail", 1, self)
            -- end
            local weapons = {"flail_swap", "glaive_swap"}
                if self.owner:HasCondition("equip_glaive") then
                    local card = Battle.Card( weapons[1], self.owner )
                    battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
                elseif self.owner:HasCondition("equip_flail") then
                    local card = Battle.Card( weapons[2], self.owner )
                    battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
                end
        end
    },

    control_cee =
    {
        name = "Control CEE",
        anim = "taunt",
        desc = "Gain {1} {DEFEND}, {KINGPIN} 5: Draw Control VEE into your hand.",
        icon = "battle/scanner.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        defend_amount = 4,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText(self.defend_amount))
        end,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("DEFEND", self.defend_amount, self)
            if self.owner:GetConditionStacks("KINGPIN") >= 5 then
                local card = Battle.Card( "control_vee", self.owner )
                card:TransferCard( battle:GetHandDeck() )
            end
        end
    },

    control_vee =
    {
        name = "Control VEE",
        anim = "taunt",
        desc = "Gain {1} {DEFEND}.",
        icon = "battle/whirl.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 0,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        defend_amount = 4,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText(self.defend_amount))
        end,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("DEFEND", self.defend_amount, self)
        end
    },

    irritating_blow = 
    {
        name = "Irritating Blow",
        anim = "crack",
        desc = "{KINGPIN} 5: Shuffle a copy of Irritating Blow into your draw pile.",
        icon = "battle/weakness_quick_jab.tex",

        flags =  CARD_FLAGS.MELEE,
        cost = 0,
        rarity = CARD_RARITY.COMMON,
        max_xp = 8,
        
        min_damage = 1,
        max_damage = 3,

        OnPostResolve = function( self, battle, attack, card )
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 5 then
                    local card = Battle.Card( "irritating_blow", self.owner )
                    battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
                    -- battle:DrawCards(1)
                end
            end
        end
    },

    playing_with_fire =
    {
        name = "Playing With Fire",
        anim = "slam",
        desc = "Apply a random negative condition to either you or the enemy {KINGPIN} 10: Always apply a random debuff to an enemy.",
        icon = "battle/weakness_inflammable.tex",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 8,
        
        min_damage = 2,
        max_damage = 4,

        debuff_amount = 1,

        OnPostResolve = function( self, battle, attack, card )
            local randomPerson = math.random(1,2)
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 10 then
                    randomPerson = 1
                end
            end
            local randomDebuff = math.random(1,7)
            local randomDebuffList = {"SHATTER", "EXPOSED", "TARGETED", "WOUND", "DEFECT", "IMPAIR", "BLEED"}
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    if randomPerson == 1 then
                        target:AddCondition(randomDebuffList[randomDebuff], self.debuff_amount, self)
                    end
                end
            end
            if randomPerson == 2 then 
                self.owner:AddCondition(randomDebuffList[randomDebuff], self.debuff_amount, self)
            end
        end
    },

    great_escape =
    {
        name = "The Great Escape",
        anim = "taunt4",
        desc = "Gain {EVASION}, {DEFEND}, {EXPOSED}, or {IMPAIR}, {KINGPIN} 15: Gain {EVASION} or {DEFEND}.",
        icon = "battle/misdirection.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 8,
        target_type = TARGET_TYPE.SELF,

        condition_amount = 3,
        defend_amount = 10,

        OnPostResolve = function( self, battle, attack, card )
            local randomChance = math.random(1,4)
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 15 then
                    randomChance = math.random(1,2)
                end
            end
            local randomConditionList = {"EVASION", "DEFEND", "EXPOSED", "IMPAIR"}
            if randomChance == 2 then 
                self.owner:AddCondition(randomConditionList[randomChance], self.defend_amount, self)
            else
                self.owner:AddCondition(randomConditionList[randomChance], self.condition_amount, self)
            end
            
        end
    },

    battle_cry_rejuvenate = 
    {
        name = "Battle Cry: Rejuvenate",
        anim = "taunt4",
        desc = "Consume all of your {TAG_TEAM} stacks to apply stacks of {MENDING} evenly amongst your team depending on how many {TAG_TEAM} stacks were consumed.",
        icon = "battle/healing_vapors.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,
        target_mod = TARGET_MOD.TEAM,

        OnPostResolve = function( self, battle, attack, card )
            local stacks = 0
            local teammates = 0
            for i, ally in self.owner:GetTeam():Fighters() do
                teammates = i
            end
            if self.owner:HasCondition("TAG_TEAM") then
                stacks = self.owner:GetConditionStacks("TAG_TEAM")
                for i, ally in self.owner:GetTeam():Fighters() do
                    ally:AddCondition("MENDING", math.round(stacks / teammates)  , self)
                end
            end
            self.owner:RemoveCondition("TAG_TEAM", self.owner:GetConditionStacks("TAG_TEAM"), self)
        end
    },

    battle_cry_inspire = 
    {
        name = "Battle Cry: Inspire",
        anim = "taunt4",
        desc = "Consume all of your {TAG_TEAM} stacks to apply stacks of {POWER_LOSS} evenly amongst your team depending on how many {TAG_TEAM} stacks were consumed.",
        icon = "battle/adrenaline_shot.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,
        target_mod = TARGET_MOD.TEAM,

        OnPostResolve = function( self, battle, attack, card )
            local stacks = 0
            local teammates = 0
            for i, ally in self.owner:GetTeam():Fighters() do
                teammates = i
            end
            if self.owner:HasCondition("TAG_TEAM") then
                stacks = self.owner:GetConditionStacks("TAG_TEAM")
                for i, ally in self.owner:GetTeam():Fighters() do
                    ally:AddCondition("POWER", math.round(stacks / teammates)  , self)
                    ally:AddCondition("POWER_LOSS", math.round(stacks / teammates)  , self)
                end
            end
            self.owner:RemoveCondition("TAG_TEAM", self.owner:GetConditionStacks("TAG_TEAM"), self)
        end
    },

    battle_cry_hold_line = 
    {
        name = "Battle Cry: Hold The Line",
        anim = "taunt4",
        desc = "Consume all of your {TAG_TEAM} stacks to apply stacks of {ARMOURED} evenly amongst your team depending on how many {TAG_TEAM} stacks were consumed.",
        icon = "battle/get_down.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,
        target_mod = TARGET_MOD.TEAM,

        OnPostResolve = function( self, battle, attack, card )
            local stacks = 0
            local teammates = 0
            for i, ally in self.owner:GetTeam():Fighters() do
                teammates = i
            end
            if self.owner:HasCondition("TAG_TEAM") then
                stacks = self.owner:GetConditionStacks("TAG_TEAM")
                for i, ally in self.owner:GetTeam():Fighters() do
                    ally:AddCondition("ARMOURED", math.round(stacks / teammates)  , self)
                end
            end
            self.owner:RemoveCondition("TAG_TEAM", self.owner:GetConditionStacks("TAG_TEAM"), self)
        end
    },

    tag_team = 
    {
        name = "Tag Team",
        anim = "transition1",
        desc = "Gain {TAG_TEAM} and place {flail_swap} or {glaive_swap} into your hand depending on the current weapon equipped.",
        icon = "battle/baron_expedition.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("TAG_TEAM", 1, self)
            local weapons = {"flail_swap", "glaive_swap"}
            if self.owner:HasCondition("equip_glaive") then
                local card = Battle.Card( weapons[1], self.owner )
                battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
            elseif self.owner:HasCondition("equip_flail") then
                local card = Battle.Card( weapons[2], self.owner )
                battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
            end
        end
    },

    bleeding_edge = 
    {
        name = "Bleeding Edge",
        anim = "slash_up",
        desc = "Slashes an enemy inflicting them with {BLEEDING_EDGE}.",
        icon = "battle/hemorrhage.tex",

        flags =  CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,
        cost = 2,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 4,
      
        min_damage = 5,
        max_damage = 7,

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, card, hit ) 
                local enemy_health = 0
                if hit.target:HasCondition("BLEED") then
                    if hit.target ~= self.owner then
                        enemy_health = math.round((hit.target:GetMaxHealth() * 0.30) - hit.target:GetConditionStacks("BLEED"))
                        hit.target:AddCondition("BLEEDING_EDGE", enemy_health)
                    end
                else
                    if hit.target ~= self.owner then
                        enemy_health = math.round((hit.target:GetMaxHealth() * 0.30))
                        hit.target:AddCondition("BLEEDING_EDGE", enemy_health)
                    end
                end
            end
        }
    },

    run_it_back = 
    {
        name = "Run it Back", -- won't hit twice
        anim = "slam",
        desc = "If {equip_flail} is active, have a chance to stun the target and draw a card.",
        icon = "battle/the_sledge.tex",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
      
        min_damage = 2,
        max_damage = 5,

        OnPostResolve = function( self, battle, attack, card )
            local randomNum = math.random(1,3)
            if self.owner:HasCondition("equip_flail") then
                battle:DrawCards(1)
                for i, hit in attack:Hits() do
                    if not attack:CheckHitResult( hit.target, "evaded" ) then
                        if randomNum == 1 then
                            hit.target:AddCondition("STUN", 1, self)
                        end
                    end
                end
            end
        end,

        
    },

    finish_them =
    {
        name = "Finish Them",
        anim = "slash_up",
        desc = "Deal bonus damage equal to how many cards were played this turn if you have {equip_glaive}.",
        icon = "battle/weakness_telegraphed.tex",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
      
        min_damage = 3,
        max_damage = 3, 

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                local stacks = self.engine:CountCardsPlayed()
                if self == card and self.owner:HasCondition("equip_glaive") then
                    dmgt:AddDamage( stacks, stacks, self )
                end
            end,
        },
    },

    exposeaid =
    {
        name = "Exposeaid",
        anim = "crack",
        desc = "If you have {equip_flail} gain {SHATTER} for one turn.",
        icon = "RISE:textures/overdrive.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
      
        min_damage = 2,
        max_damage = 4, 

        OnPostResolve = function( self, battle, attack, card )
            if self.owner:HasCondition("equip_flail") then
                self.owner:AddCondition("SHATTER", 1, self)
                self.owner:AddCondition("TEMP_SHATTER", 1, self)
            end
        end,
    },

    nice_knowin_ya = 
    {
        name = "Nice Knowin Ya",
        anim = "spin_attack",
        desc = "If you have {equip_glaive}, have a chance to deal double or triple damage or decreased damage.",
        icon = "RISE:textures/gumption.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
      
        min_damage = 1,
        max_damage = 3, 

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                local damageChance = math.random(1,3)
                if card == self then
                    if self.owner:HasCondition("equip_glaive") then
                        if damageChance == 3 then
                            dmgt:ModifyDamage( dmgt.min_damage * 2, dmgt.max_damage * 2, self ) -- triple damage
                        elseif damageChance == 2 then
                            dmgt:ModifyDamage( dmgt.min_damage * 1, dmgt.max_damage * 1, self ) -- double damage
                        elseif damageChance == 1 then
                            dmgt:ModifyDamage( dmgt.min_damage - 1, dmgt.max_damage - 1, self ) -- decreased damage
                        end
                    end
                end
            end,
        },
    },

    it_wasnt_me = 
    {
        name = "It Wasn't Me!!",
        anim = "slash_up",
        desc = "If you have {equip_glaive}, gain {1} {EVASION} and  {2} {WOUND}.",
        icon = "RISE:textures/save_face.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
      
        min_damage = 2,
        max_damage = 5, 

        evasion_amount = 1,
        wound_amount = 2,

        desc_fn = function ( self, fmt_str )
            return loc.format(fmt_str, self.evasion_amount, self.wound_amount)
        end,

        OnPostResolve = function( self, battle, attack, card )
            if self.owner:HasCondition("equip_glaive") then
                self.owner:AddCondition("EVASION", self.evasion_amount, self)
                self.owner:AddCondition("WOUND", self.wound_amount, self)
            end
        end,
        
    },

    call_it_even = 
    {
        name = "Call it Even",
        anim = "slam",
        desc = "Gain 3 random debuffs. {KINGPIN} 15: Don't gain any debuffs.",
        icon = "RISE:textures/ransack.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
      
        min_damage = 10,
        max_damage = 10, 

        OnPostResolve = function( self, battle, attack, card ) -- sometimes only gives you 2 debuffs
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 15 then
                
                else
                    local randomCon1 = math.random(1,5)
                    local randomCon2 = math.random(1,5)
                    local randomCon3 = math.random(1,5)
                    local posConditions = {"BLEED", "IMPAIR", "BURN", "WOUND", "EXPOSED"}
                    self.owner:AddCondition(posConditions[randomCon1], 1, self)
                    self.owner:AddCondition(posConditions[randomCon2], 1, self)
                    self.owner:AddCondition(posConditions[randomCon3], 1, self)
                end
            end
            if not self.owner:HasCondition("KINGPIN") then
                local randomCon1 = math.random(1,5)
                local randomCon2 = math.random(1,5)
                local randomCon3 = math.random(1,5)
                local posConditions = {"BLEED", "IMPAIR", "BURN", "WOUND", "EXPOSED"}
                self.owner:AddCondition(posConditions[randomCon1], 1, self)
                self.owner:AddCondition(posConditions[randomCon2], 1, self)
                self.owner:AddCondition(posConditions[randomCon3], 1, self)
            end
        end
    },

    under_pressure = 
    {
        name = "Excel Under Pressure",
        anim = "spin_attack",
        desc = "Deal 1 extra damage for each enemy in the fight.  If {equip_glaive} is active and there is more than 1 enemy, gain {INVINCIBLE}.",
        icon = "battle/garbage_day.tex",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
      
        min_damage = 2,
        max_damage = 3, 

        OnPostResolve = function( self, battle, attack, card ) 
            local enemyCount = 0
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                enemyCount = enemyCount + 1
            end
            if self.owner:HasCondition("equip_glaive") and enemyCount > 1 then
                self.owner:AddCondition("INVINCIBLE", 1)
            end
        end,

        event_handlers = 
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                local enemyCount = 0
                for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                    enemyCount = enemyCount + 1
                end
                dmgt:AddDamage(enemyCount,enemyCount,self)
            end,
        }
        
    },

    -- BOG CARDS BELOW
    parasite_infusion =
    {
        name = "Parasite Infusion", -- bugged when you have more than one copy in your hand: enemies gain more stacks than intended and gain even more stacks while attacking not with this card
        anim = "throw1",
        desc = "Infuses an enemy with {PARASITIC_INFUSION}, gaining stacks depending on the target enemy's max health. {BOG_ABILITY}.",
        icon = "battle/branch.tex",

        flags =  CARD_FLAGS.RANGED | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,

        min_damage = 4,
        max_damage = 7,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("ONE_WITH_THE_BOG", 1, self)
        end,

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, card, hit ) 
                local enemy_health = 0
                if hit.target ~= self.owner then
                    if not hit.target:HasCondition("PARASITIC_INFUSION") then
                        enemy_health = math.round(hit.target:GetMaxHealth() * 0.40)
                        hit.target:AddCondition("PARASITIC_INFUSION", enemy_health)
                    end
                end
            end
        }
    },

    contaminate = 
    {
        name = "Contaminate",
        anim = "slash_up",
        desc = "Contaminates an enemy, which grants them stacks of {CONTAMINATION} based on their current health. {BOG_ABILITY}.",
        icon = "battle/giant_stinger.tex",

        flags =  CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,
        cost = 2,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,

        min_damage = 4,
        max_damage = 7,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("ONE_WITH_THE_BOG", 1, self)
            for i, hit in attack:Hits() do
                if not attack:CheckHitResult( hit.target, "evaded" ) and not hit.target:HasCondition("CONTAMINATION") then
                    hit.target:AddCondition("CONTAMINATION", math.round(hit.target:GetHealth() * 0.80) , self)
                end
            end
        end
    },

    remote_plague =
    {
        name = "Remote Plague",
        anim = "throw2",
        desc = "Contaminates an enemy, which grants them random stacks of {REMOTE_PLAGUE}. {BOG_ABILITY}.",
        icon = "battle/funky_fungi.tex",

        flags =  CARD_FLAGS.RANGED,
        cost = 1,
        rarity = CARD_RARITY.RARE,
    
        min_damage = 4,
        max_damage = 5,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("ONE_WITH_THE_BOG", 1, self)
            local randomNum = math.random(3,10)
            for i, hit in attack:Hits() do
                if not attack:CheckHitResult( hit.target, "evaded" ) then
                    hit.target:AddCondition("REMOTE_PLAGUE", randomNum, self)
                end
            end
            local randomNum = math.random(1,3)
            local remoteCards = {"remote_expunge", "remote_blind", "remote_virus"}
            local card = Battle.Card( remoteCards[randomNum], self.owner )
            card:TransferCard( battle:GetDrawDeck() )
        end
    },

    remote_expunge = 
    {
        name = "Remote: Expunge",
        anim = "taunt",
        desc = "Deal damage to all enemies with {REMOTE_PLAGUE} equal to their stacks * 2, then remove all stacks of {REMOTE_PLAGUE}.",
        icon = "battle/automech_access_code.tex",
        -- planning on making a condition that can count how much damage you did during your turn, apply the damage to this card

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNIQUE,
        target_mod = TARGET_MOD.TEAM,

        expunge_damage = 2,

        PreReq = function( self, minigame )
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                return enemy:HasCondition("REMOTE_PLAGUE")
            end
        end,

        OnPostResolve = function( self, battle, attack)
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                if enemy:HasCondition("REMOTE_PLAGUE") then
                    enemy:ApplyDamage( math.round(enemy:GetConditionStacks("REMOTE_PLAGUE") * self.expunge_damage), math.round(enemy:GetConditionStacks("REMOTE_PLAGUE") * self.expunge_damage), self)
                    enemy:RemoveCondition("REMOTE_PLAGUE", enemy:GetConditionStacks("REMOTE_PLAGUE"))
                end
            end
            
        end
    },

    remote_blind = -- WORK IN PROGRESS
    {
        name = "Remote: Blind",
        anim = "taunt",
        desc = "Enemies with {REMOTE_PLAGUE} will gain stacks of {BLINDED} depending on their stacks of {REMOTE_PLAGUE}.",
        icon = "battle/automech_access_code.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNIQUE,
        target_mod = TARGET_MOD.TEAM,

        PreReq = function( self, minigame )
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                return enemy:HasCondition("REMOTE_PLAGUE")
            end
        end,

        OnPostResolve = function( self, battle, attack)
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                if enemy:HasCondition("REMOTE_PLAGUE") then
                    enemy:AddCondition("BLINDED", enemy:GetConditionStacks("REMOTE_PLAGUE"))
                end
            end
        end
    },

    remote_virus = 
    {
        name = "Remote: Virus",
        anim = "taunt",
        desc = "Enemies with {REMOTE_PLAGUE} will gain {REMOTE_VIRUS} which will inflict a random debuff every turn.",
        icon = "battle/automech_access_code.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNIQUE,
        target_mod = TARGET_MOD.TEAM,

        PreReq = function( self, minigame )
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                return enemy:HasCondition("REMOTE_PLAGUE")
            end
        end,

        OnPostResolve = function( self, battle, attack)
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                if enemy:HasCondition("REMOTE_PLAGUE") then
                    enemy:AddCondition("REMOTE_VIRUS", 1)
                end
            end
        end
    },



    epidemic = 
    {
        name = "Epidemic",
        anim = "throw1",
        desc = "Deal damage to all enemies and have a chance to inflict enemies with a virus called {EPIDEMIC} for 3 turns. Minimum 1 enemy will be inflicted. {BOG_ABILITY}.",
        icon = "battle/tendrils.tex",

        flags =  CARD_FLAGS.RANGED | CARD_FLAGS.EXPEND,
        cost = 2,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,
        target_mod = TARGET_MOD.TEAM,

        min_damage = 3,
        max_damage = 6,

        enemy_inflicted = false,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("ONE_WITH_THE_BOG", 1, self)
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                if self.enemy_inflicted == false then
                    enemy:AddCondition("EPIDEMIC", 3, self)
                    self.enemy_inflicted = true
                else
                    local randomChance = math.random(1,4)
                    if randomChance == 1 then
                        enemy:AddCondition("EPIDEMIC", 3, self)
                    end
                end
            end
        end
    },

    viral_sadism = -- bugged when shuffled into deck; cannot target anyone, but card fully function when brought to hand with debugger
    {
        name = "Viral Sadism",
        anim = "spin_attack",
        desc = "Only deals damage to enemies with {EPIDEMIC}.",
        icon = "battle/beast_of_the_bog.tex",
        
        cost = 0,

        flags =  CARD_FLAGS.MELEE | CARD_FLAGS.REPLENISH | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,

        min_damage = 0,
        max_damage = 0,

        event_handlers = 
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card == self and target then
                    if target:HasCondition("EPIDEMIC") then
                        dmgt:AddDamage(10,10,self)
                    end
                end
            end,
        }
    },

    armor_of_disease = 
    {
        name = "Armor of Disease",
        anim = "taunt4",
        desc = "Gain {ARMOR_OF_DISEASE}. {BOG_ABILITY}.",
        icon = "battle/bough.tex",
        
        cost = 2,
        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.RARE,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("ONE_WITH_THE_BOG", 1, self)
            self.owner:AddCondition("ARMOR_OF_DISEASE", 1, self)
        end
    },

    infestation = 
    {
        name = "Infestation",
        anim = "taunt",
        desc = "Shuffle 2 Bog Cards to your hand and expend a non unique card from your draw and discard pile each.  If any enemies have a Bog Condition, raise a bog creature to your side or the enemy's side. {BOG_ABILITY}.",
        icon = "negotiation/voices.tex",
        
        cost = 2,
        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.RARE,
        target_type = TARGET_TYPE.SELF,

        bogCards =  {"infest", "conceal", "lifestealer", "exhume", "reconstruction", "gather_their_souls", "nightmare_blade", "bog_regeneration", "viral_outbreak", "evolve", "relentless_predator"},

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("ONE_WITH_THE_BOG", 1, self)
            if battle:GetDrawDeck():CountCards() > 0  then
                local randomCard1 = battle:GetDrawDeck():PeekRandom()
                for i, card in battle:GetDrawDeck():Cards() do
                    if randomCard1.rarity == CARD_RARITY.UNIQUE then -- basically doesn't throw away unique rarity cards; items, bog cards.
                        randomCard1 = battle:GetDrawDeck():PeekRandom()
                    else
                        battle:ExpendCard(randomCard1)
                        -- get bog card below
                        local bogCard = math.random(1,11)
                        local card = Battle.Card( self.bogCards[bogCard], self.owner )
                        battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
                        break
                    end
                end
            end
            if battle:GetDiscardDeck():CountCards() > 0 then
                local randomCard2 = battle:GetDiscardDeck():PeekRandom()
                for i, card in battle:GetDiscardDeck():Cards() do
                    if randomCard2.rarity == CARD_RARITY.UNIQUE then
                        randomCard2 = battle:GetDiscardDeck():PeekRandom()
                    else
                        battle:ExpendCard(randomCard2)
                        local bogCard = math.random(1,11)
                        local card = Battle.Card( self.bogCards[bogCard], self.owner )
                        battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
                        break
                    end
                end
            end
           for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                local randomMonster = math.random(1,2) -- change to 1-3 after fixing grout eye
                if enemy:HasCondition("EPIDEMIC") or enemy:HasCondition("PARASITIC_INFUSION") or enemy:HasCondition("REMOTE_PLAGUE") or enemy:HasCondition("CONTAMINATION") then
                    if randomMonster == 1 then
                        local groutKnuckle = Agent( "GROUT_KNUCKLE" )
                        local fighter = Fighter.CreateFromAgent( groutKnuckle, battle:GetScenario():GetAllyScale() )
                        self.owner:GetTeam():AddFighter( fighter )
                        self.owner:GetTeam():ActivateNewFighters()
                    -- elseif randomMonster == 3 then
                    --     local groutEye = Agent( "GROUT_EYE" ) -- grout eye bugged; won't appear on screen (game issue?)
                    --     local fighter = Fighter.CreateFromAgent( groutEye, battle:GetScenario():GetAllyScale() )
                    --     self.owner:GetTeam():AddFighter( fighter )
                    --     self.owner:GetTeam():ActivateNewFighters()
                    elseif randomMonster == 2 then
                        local sparkMine = Agent( "GROUT_SPARK_MINE" )
                        local fighter = Fighter.CreateFromAgent( sparkMine, battle:GetScenario():GetAllyScale() )
                        self.owner:GetEnemyTeam():AddFighter( fighter )
                        self.owner:GetEnemyTeam():ActivateNewFighters()
                    end
                end
           end
        end
    },

    infest = 
    {
        name = "Infest",
        anim = "crack",
        desc = "Deal damage and have a chance to inflict an enemy with a bog condition. <i>{BEE}</i>.",
        icon = "RISE:textures/infest.png",
        
        cost = 1,
        flags =  CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNIQUE,
        
        min_damage = 6,
        max_damage = 8,

        OnPostResolve = function( self, battle, attack)
            local randomDebuff = math.random(1,4)
            local debuffList = {"EPIDEMIC", "REMOTE_VIRUS", "PARASITIC_INFUSION", "CONTAMINATION"}
            local debuffStacks = 0

            -- change stacks inflicted on enemy depending on the condition
            if randomDebuff == 1 then
                debuffStacks = 3
            elseif randomDebuff == 2 then
                debuffStacks = math.random(3,10)
                local randomNum = math.random(1,2)
                local remoteCards = {"remote_expunge", "remote_virus", "remote_blind"}
                local card = Battle.Card( remoteCards[randomNum], self.owner )
                card:TransferCard(battle:GetDrawDeck())
            elseif randomDebuff == 3 then
                debuffStacks = math.round(attack.attacker:GetMaxHealth() * 0.60)
            elseif randomDebuff == 4 then
                debuffStacks = math.round(attack.attacker:GetHealth() * 0.75)
            end
           
            for i, hit in attack:Hits() do
                if not attack:CheckHitResult( hit.target, "evaded" ) then
                    if hit.target:HasCondition("PARASITIC_INFUSION") or hit.target:HasCondition("CONTAMINATION") then

                    else
                        hit.target:AddCondition(debuffList[randomDebuff], debuffStacks, self)
                    end
                end
            end
        end
    },

    conceal = 
    {
        name = "Conceal",
        anim = "taunt",
        desc = "Gather your bog friends around to defend you, gain 6-12 {DEFEND}. <i>{BEE}</i>.",
        -- Gain {2} extra {DEFEND} and have a chance to gain a random buff for every bog monster in the fight
        icon = "RISE:textures/conceal.png",
        
        cost = 1,
        flags =  CARD_FLAGS.SKILL,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.FRIENDLY_OR_SELF,
        
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.defend_amount ), self.extra_defend)
        end,

        defend_amount = 8,
        extra_defend = 2,

        OnPostResolve = function( self, battle, attack)
            local randomDefend = math.random(6,12)
            self.defend_amount = randomDefend
            -- local posPosConditions = {"POWER", "ARMOURED", "NEXT_TURN_DRAW", "RIPOSTE", "METALLIC", "EVASION"}
            -- local randomBuff = math.random(1,6)
            -- local randomChance = math.random(1,2)
            -- for i, ally in self.owner:GetTeam():Fighters() do 
            --     if ally.id == "GROUT_KNUCKLE" or ally.id == "GROUT_EYE" then
            --         self.defend_amount = self.defend_amount + self.extra_defend
            --         if randomChance == 1 then
            --             self.owner:AddCondition(posPosConditions[randomBuff], 1, self)
            --         end
            --     end
            -- end
            -- for i, enemy in self.owner:GetEnemyTeam():Fighters() do
            --     if enemy.id == "GROUT_SPARK_MINE" then
            --         self.defend_amount = self.defend_amount + self.extra_defend
            --         if randomChance == 1 then
            --             self.owner:AddCondition(posPosConditions[randomBuff], 1, self)
            --         end
            --     end
            -- end
            self.owner:AddCondition("DEFEND", self.defend_amount, self)
        end
    },

    lifestealer = 
    {
        name = "Lifestealer",
        anim = "slash_up",
        desc = "Deal damage and steal health equal to the damage dealt. <i>{BEE}</i>.",
        icon = "RISE:textures/lifestealer.png",
        
        cost = 1,
        flags =  CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNIQUE,

        min_damage = 5,
        max_damage = 9,

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                if hit.card == self and not hit.evaded then
                    self.owner:HealHealth( hit.damage, self )
                end
            end
        },
        
    },

    exhume = 
    {
        name = "Exhume",
        anim = "taunt",
        desc = "Deal damage to all enemies and steal one of their buffs. <i>{BEE}</i>.",
        icon = "RISE:textures/exhume.png",
        
        cost = 1,
        flags =  CARD_FLAGS.SKILL,
        rarity = CARD_RARITY.UNIQUE,
        target_mod = TARGET_MOD.TEAM,

        min_damage = 4,
        max_damage = 6,

        OnPostResolve = function( self, battle, attack)
            local target_fighter = {}
            battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
            for i=1, #target_fighter do
                for i,condition in pairs(target_fighter[i]:GetConditions()) do
                    if condition.ctype == CTYPE.BUFF then
                        self.owner:AddCondition(condition.id, condition.stacks, self)
                        target_fighter[1]:RemoveCondition(condition.id, condition.stacks)
                        break
                    end
                end
            end
        end
    },

    reconstruction = 
    {
        name = "Reconstruction",
        anim = "taunt4",
        desc = "Heal health to full then gain 99 stacks of a random debuff. <i>{BEE}</i>.",
        icon = "RISE:textures/reconstruction.png",
        
        cost = 1,
        flags =  CARD_FLAGS.SKILL,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            local debuffs = {"IMPAIR", "STAGGER", "DEFECT", "EXPOSED", "TARGETED", "RICOCHET", "TRAUMA"}
            local randomDebuff = math.random(1,7)
            self.owner:HealHealth( self.owner:GetMaxHealth(), self )
            self.owner:AddCondition(debuffs[randomDebuff], 99, self)
        end
    },

    gather_their_souls = 
    {
        name = "Gather Their Souls",
        anim = "taunt",
        desc = "Steal a buff every turn then inflict a debuff to a random enemy. <i>{BEE}</i>.",
        icon = "RISE:textures/gathertheirsouls.png",
        
        cost = 1,
        flags =  CARD_FLAGS.SKILL,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("GATHER_THEIR_SOULS", 3, self)
        end
    },

    nightmare_blade = 
    {
        name = "Nightmare Blade",
        anim = "spin_attack",
        desc = "Incept a {NIGHTMARE} into an enemy, a {NIGHTMARE} inflicted enemy will take more damage from all sources and deal less damage.  All allies gain {TARGETED}. <i>{BEE}</i>.",
        -- icon = "RISE:textures/infestation.png",
        
        cost = 1,
        flags =  CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNIQUE,

        min_damage = 4,
        max_damage = 10,

        OnPostResolve = function( self, battle, attack, fighter)
            for i, ally in self.owner:GetTeam():Fighters() do
                if not fighter == self then
                    ally:AddCondition("TARGETED", 2, self)
                end
            end
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    target:AddCondition("NIGHTMARE", 1, self)
                end
            end
        end
    },

    bog_regeneration = 
    {
        name = "Bog Regeneration",
        anim = "taunt",
        desc = "Heal health equal to half the damage you took last turn. <i>{BEE}</i>.",
        icon = "RISE:textures/bogregeneration.png",
        
        cost = 1,
        flags =  CARD_FLAGS.SKILL,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            if self.owner:HasCondition("ONE_WITH_THE_BOG") then
                self.owner:HealHealth(self.owner:GetCondition("ONE_WITH_THE_BOG").damageTaken, self)
            end
        end
    },

    viral_outbreak = -- will crash if you don't have ONE WITH THE BOG unsurprisingly // due to damageTaken doesn't exist without it
    {
        name = "Viral Outbreak",
        anim = "slash_up",
        desc = "Deal bonus damage equal to 10% of the total damage you took then apply {PARASITIC_INFUSION} to an enemy, the stacks gained are equal to half the total damage you took. <i>{BEE}</i>.",
        icon = "RISE:textures/viraloutbreak.png",
        
        cost = 1,
        flags =  CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNIQUE,

        min_damage = 3,
        max_damage = 6,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    if not target:HasCondition("PARASITIC_INFUSION") then
                        if self.owner:GetCondition("ONE_WITH_THE_BOG").damageTaken > 0 then
                            target:AddCondition("PARASITIC_INFUSION",self.owner:GetCondition("ONE_WITH_THE_BOG").damageTaken, self)
                        end
                    end
                end
            end
        end,

        event_handlers = 
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt, hit )
                if card.owner == self.owner and card == self then
                    if self.owner:HasCondition("ONE_WITH_THE_BOG") then
                        dmgt:AddDamage(  math.round(self.owner:GetCondition("ONE_WITH_THE_BOG").damageTaken / 10),
                                            math.round(self.owner:GetCondition("ONE_WITH_THE_BOG").damageTaken / 10),
                                        self )
                    end
                end
            end,
        }
        
    },

    evolve = 
    {
        name = "Evolve",
        anim = "taunt",
        desc = "Evolve, gaining Regeneration and {DEFEND} per turn equal to 10% total damage dealt this fight. Add 10 to your damage dealt counter if you already have {EVOLUTION}. <i>{BEE}</i>.",
        icon = "RISE:textures/evolve.png",
        
        cost = 1,
        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack)
            if self.owner:HasCondition("EVOLUTION") then
                self.owner:GetCondition("ONE_WITH_THE_BOG").damageDealt = self.owner:GetCondition("ONE_WITH_THE_BOG").damageDealt + 10
            end
            
            if self.owner:HasCondition("ONE_WITH_THE_BOG") then
                self.owner:AddCondition("EVOLUTION", 1, self)
            end
        end,
    },

    relentless_predator = 
    {
        name = "Relentless Predator",
        anim = "spin_attack",
        desc = "Gain {RELENTLESS_PREDATOR}. <i>{BEE}</i>.",
        icon = "RISE:textures/relentlesspredator.png",

        min_damage = 7,
        max_damage = 9,
        
        cost = 1,
        flags =  CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNIQUE,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("RELENTLESS_PREDATOR", 1, self)
        end,
    },

    transform_bog_one = 
    {
        name = "Transform: The Bog One",
        anim = "taunt3",
        desc = "Transform in into the ultimate monstrocity, all of your non unique cards are expended and replaced with the all powerful bog cards!  (All non ability bog card <i>{BEE}</i>).",
        icon = "negotiation/hyperactive.tex",

        cost = 2,
        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.BURNOUT | CARD_FLAGS.AMBUSH,
        rarity = CARD_RARITY.UNIQUE,
        target_type = TARGET_TYPE.SELF,

        bogCards =  {"infest", "conceal", "lifestealer", "exhume", "reconstruction", "gather_their_souls", "nightmare_blade", "bog_regeneration", "viral_outbreak", "evolve", "relentless_predator"},

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("ONE_WITH_THE_BOG", 1, self)

            if battle:GetDrawDeck():CountCards() > 0  then
                for i, card in battle:GetDrawDeck():Cards() do
                    if card.rarity == CARD_RARITY.UNIQUE then -- basically doesn't throw away unique rarity cards; items, bog cards.
                        
                    else
                        battle:ExpendCard(card)
                        local bogCard = math.random(1,11)
                        local card = Battle.Card( self.bogCards[bogCard], self.owner )
                        battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
                    end
                end
            end
            if battle:GetDiscardDeck():CountCards() > 0 then
                for i, card in battle:GetDiscardDeck():Cards() do
                    if card.rarity == CARD_RARITY.UNIQUE then
                       
                    else
                        battle:ExpendCard(card)
                        local bogCard = math.random(1,11)
                        local card = Battle.Card( self.bogCards[bogCard], self.owner )
                        battle:DealCard( card, battle:GetDeck( DECK_TYPE.DISCARDS ) )
                    end
                end
            end
            if battle:GetHandDeck():CountCards() > 0 then
                for i, card in battle:GetHandDeck():Cards() do
                    if card.rarity == CARD_RARITY.UNIQUE then
                       
                    else
                        battle:ExpendCard(card)
                        local bogCard = math.random(1,11)
                        local card = Battle.Card( self.bogCards[bogCard], self.owner )
                        battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
                    end
                end
            end
        end,
    }
        -- blind_grenade = 
    -- {
    --     name = "Blinding Grenade",
    --     anim = "throw1",
    --     desc = "Have a small chance to blind all enemies.",
    --     icon = "battle/lumin_grenade.tex",

    --     flags =  CARD_FLAGS.RANGED | CARD_FLAGS.EXPEND,
    --     cost = 1,
    --     rarity = CARD_RARITY.UNCOMMON,
    --     max_xp = 6,
    --     target_mod = TARGET_MOD.TEAM,

    --     OnPostResolve = function( self, battle, attack)
    --         local randomChance = math.random(1,4)
    --         for i, enemy in self.owner:GetEnemyTeam():Fighters() do
    --             enemy:AddCondition("BLINDED", 1, self)
    --             -- need to add random chance
    --         end
    --     end
    -- },

        -- gravemind = 
    -- {
    --     name = "Gravemind",
    --     anim = "taunt",
    --     desc = "have a chance to inflict all enemies with deceive, this will cause their next attack to miss and you will counter their missed attack.",
    --     icon = "battle/improvise_chug.tex",

    --     flags =  CARD_FLAGS.SKILL,
    --     cost = 2,
    --     rarity = CARD_RARITY.UNCOMMON,
    --     max_xp = 4,
    --     target_type = TARGET_TYPE.SELF,
    -- },

    -- deceived = 
    -- {
    --     name = "Deceive",
    --     anim = "taunt",
    --     desc = "have a chance to inflict all enemies with deceive, this will cause their next attack to miss and you will counter their missed attack.",
    --     icon = "battle/improvise_chug.tex",

    --     flags =  CARD_FLAGS.SKILL,
    --     cost = 2,
    --     rarity = CARD_RARITY.UNCOMMON,
    --     max_xp = 4,
    --     target_type = TARGET_TYPE.SELF,
    -- },

     -- devious_taunt = 
    -- {
    --     name = "Devious Taunt",
    --     anim = "surrender",
    --     desc = "if an enemy is not preparing an attack card on to you, they will be forced to attack you this turn then gain a random buff.",
    --     icon = "battle/improvise_chug.tex",

    --     flags =  CARD_FLAGS.SKILL,
    --     cost = 2,
    --     rarity = CARD_RARITY.UNCOMMON,
    --     max_xp = 4,
    --     target_type = TARGET_TYPE.SELF,
    -- },

    -- even_the_odds = 
    -- {
    --     name = "Even the Odds",
    --     anim = "taunt",
    --     desc = "Singles out a random enemy, while this effect is active, you and the random enemy are the only fighters that can attack and can only attack eachother.",
    --     icon = "battle/single_out.tex",

    --     flags =  CARD_FLAGS.SKILL,
    --     cost = 2,
    --     rarity = CARD_RARITY.UNCOMMON,
    --     max_xp = 4,
    --     target_type = TARGET_TYPE.SELF,

    --     OnPreResolve = function( self, battle, attack, card, fighter )
    --         self.owner:AddCondition("EVEN_ODDS", 1 , self)
    --         local target_fighter = {}
    --         battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
    --         for i=1, #target_fighter do
    --             target_fighter[i]:AddCondition("EVEN_ODDS", 1, self)
    --         end
    --     end,

    --     OnPostResolve = function( self, battle, attack, card, fighter )
    --         for i, enemy in self.owner:GetEnemyTeam():Fighters() do
    --             if not enemy:HasCondition("EVEN_ODDS") then
    --                 enemy:AddCondition("OUT_OF_WAY")
    --             end
    --         end
    --         for i, ally in self.owner:GetEnemyTeam():Fighters() do
    --             if not ally:HasCondition("EVEN_ODDS") then
    --                 ally:AddCondition("OUT_OF_WAY")
    --             end
    --         end
    --     end,
    -- },

 -- hypnotize = 
    -- {
    --     name = "Hypnotize",
    --     anim = "taunt",
    --     desc = "Hypnotizes an enemy forcing them to become your ally for a few turns and attack their former allies.",
    --     icon = "battle/improvise_chug.tex",

    --     flags =  CARD_FLAGS.SKILL,
    --     cost = 2,
    --     rarity = CARD_RARITY.UNCOMMON,
    --     max_xp = 4,
    --     target_type = TARGET_TYPE.SELF,
    -- },

}

for i, id, carddef in sorted_pairs( CARDS ) do
    carddef.series = carddef.series or "KASHIO_PLAYER"
    Content.AddBattleCard( id, carddef )
end

local CONDITIONS = 
{
        -- EVEN_ODDS = 
    -- {
    --     name = "Even The Odds",
    --     desc = "All fighters in the battle are unable to attack except the two fighters with this condition, they may only attack eachother.",
    --     icon = "battle/conditions/vendetta.tex",
    --     apply_sound = "event:/sfx/battle/status/system/Status_Buff_Attack",
    --     max_stacks = 1,

    --     CanBeTargetted = function( self, card, fighter)
    --         if fighter:GetTeam() ~= card:GetOwner():GetTeam() and fighter:GetTeam() == self.owner:GetTeam() then
    --             if fighter:HasCondition("OUT_OF_WAY") then
    --                 if fighter ~= self.owner and self.owner:IsAlive() then
    --                     return false
    --                 end
    --             end
    --         end
    --         return true
    --     end
    -- },

    -- OUT_OF_WAY =
    -- {
    --     name = "Out of the way",
    --     desc = "Fighters waiting for the brawl to come to a closure.",
    --     icon = "battle/conditions/favorite_of_hesh.tex",
    --     -- apply_sound = "event:/sfx/battle/status/system/Status_Buff_Attack",
    --     max_stacks = 1,

    --     -- CanBeTargetted = function( self, card, fighter )
    --     --     if fighter:HasCondition("OUT_OF_WAY") then
    --     --         return false
    --     --     end
            
    --     -- end
    -- },
    BOG_ABILITY = 
    {
        name = "Bog Ability", 
        desc = "Bog Ability cards trigger {ONE_WITH_THE_BOG}.",
    },

    BEE = 
    {
        name = "Art made by Bee", 
        desc = "This card art was designed and drawn by Bee. You can check Bee out at: https://twitter.com/OneTinyBeeDraws",
     
    },

    RELENTLESS_PREDATOR = 
    {
        name = "Relentless Predator", 
        desc = "Gain 1 bonus damage on your attacks for every 3 stacks of {RELENTLESS_PREDATOR}.",
        icon = "battle/conditions/annihilation.tex",   

        ctype = CTYPE.BUFF,

        damageAccumulated = 0,

        event_handlers = 
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt, hit )
                if card.owner == self.owner then
                    dmgt:ModifyDamage(  dmgt.min_damage + math.floor(self.owner:GetConditionStacks("RELENTLESS_PREDATOR") / 3),
                     dmgt.max_damage + math.floor(self.owner:GetConditionStacks("RELENTLESS_PREDATOR") / 3),
                    self )
                end
            end,

            -- [ BATTLE_EVENT.POST_RESOLVE ] = function( self, card, target, dmgt, hit )
            --     local stacksDamage = math.round(self.owner:GetConditionStacks("RELENTLESS_PREDATOR") / 2)
            --     if stacksDamage == 0 then
            --         self.damageAccumulated = self.damageAccumulated + 1
            --     end
            -- end
        }  
    },

    EVOLUTION = 
    {
        name = "Evolution", 
        desc = "Gain Regeneration and {DEFEND} per turn equal to 10% total damage dealt this fight. At 100 damage, gain an extra action per turn.",
        icon = "battle/conditions/blood_bind.tex",   

        ctype = CTYPE.BUFF,
        max_stacks = 1,

        event_handlers = 
        {
            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, card, target, dmgt, hit )
                self.owner:AddCondition("DEFEND", math.round(self.owner:GetCondition("ONE_WITH_THE_BOG").damageDealt / 10), self)
                self.owner:HealHealth(math.round(self.owner:GetCondition("ONE_WITH_THE_BOG").damageDealt / 10), self)
                if self.owner:GetCondition("ONE_WITH_THE_BOG").damageDealt >= 100 then
                    self.owner:AddCondition("NEXT_TURN_ACTION", 1 , self)
                end
            end
        }  
    },

    NIGHTMARE = 
    {
        name = "NIGHTMARE", 
        desc = "Enemies inflicted with {NIGHTMARE} take more damage from all sources and deal less damage.",
        icon = "battle/conditions/cruelty.tex",   

        ctype = CTYPE.DEBUFF,

        event_handlers = 
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt, hit )
                if target == self.owner then
                    dmgt:AddDamage( math.round(dmgt.min_damage * 0.5), math.round(dmgt.max_damage * 0.5), self )
                end
                if card.owner == self.owner then
                    dmgt:ModifyDamage( math.round( dmgt.min_damage * 0.5 ),
                                       math.round( dmgt.max_damage * 0.5 ),
                                       self )
                end
            end,

            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, card, target, dmgt, hit )
                self.owner:RemoveCondition("NIGHTMARE", 1, self)
            end
        }
    },

    GATHER_THEIR_SOULS = 
    {
        name = "Gather Their Souls", 
        desc = "Steal a buff from a random enemy and inflict them with a random debuff.",
        icon = "battle/conditions/favorite_of_hesh.tex",  

        ctype = CTYPE.BUFF,

        OnApply = function( self, battle )
            local target_fighter = {}
            local posConditions = {"BLEED", "IMPAIR", "BURN", "STUN", "WOUND", "EXPOSED"}
            local randomCon = math.random(1,6)
            battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
            for i=1, #target_fighter do
                for i, condition in pairs(target_fighter[1]:GetConditions()) do
                    if condition.ctype == CTYPE.BUFF then
                        self.owner:AddCondition(condition.id, 1, self)
                        target_fighter[1]:RemoveCondition(condition.id, 1)
                        target_fighter[1]:AddCondition(posConditions[randomCon], 1)
                        break
                    end
                end
            end
        end,

        event_handlers = 
        {
            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle, attack, hit )
                local target_fighter = {}
                local posConditions = {"BLEED", "IMPAIR", "BURN", "STUN", "WOUND", "EXPOSED"}
                local randomCon = math.random(1,6)
                battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
                for i=1, #target_fighter do
                    for i, condition in pairs(target_fighter[1]:GetConditions()) do
                        if condition.ctype == CTYPE.BUFF then
                            self.owner:AddCondition(condition.id, 1, self)
                            target_fighter[1]:RemoveCondition(condition.id, 1)
                            target_fighter[1]:AddCondition(posConditions[randomCon], 1)
                            break
                        end
                    end
                end
                self.owner:RemoveCondition("GATHER_THEIR_SOULS", 1, self)
            end
        }
    },

    INVINCIBLE = 
    {
        name = "Invincible", 
        desc = "An attack from an enemy on you will deal 0 damage.",
        icon = "battle/conditions/shield_of_hesh.tex",  

        ctype = CTYPE.BUFF,

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                if attack.attacker ~= self.owner then
                    self.owner:RemoveCondition("INVINCIBLE", 1, self)
                end
            end,

            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle, attack, hit )
                local target_fighter = {}
                local isAttack = false
                battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
                while (isAttack == false) do 
                    if target_fighter[1].prepared_cards then
                        if target_fighter[1].prepared_cards[1]:IsAttackCard() then
                            target_fighter[1].prepared_cards[1].min_damage = 0
                            target_fighter[1].prepared_cards[1].max_damage = 0
                            isAttack = true
                        else
                            battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
                        end
                    end
                end
                if self.owner:HasCondition("INVINCIBLE") then
                    self.owner:RemoveCondition("INVINCIBLE", 1, self)
                end
            end
        }
    },

    ONE_WITH_THE_BOG = 
    {
        name = "One With The Bog", 
        desc = "You gain this condition after using a Kashio Bog Ability.  You cannot gain KINGPIN stacks while this is active and cannot equip any weapons. Removes {KINGPIN}, {equip_flail} and {equip_glaive} on activation. Every turn, have a chance to shuffle a Bog ability card into your hand (regardless if you picked up the card) then shuffle a Bog card into your draw/discard pile while expending a non Item/Bog card in your draw/dicard pile.",
        icon = "battle/conditions/heart_of_the_bog.tex",  
        
        max_stacks = 1,

        bogCards = {"infest", "conceal", "lifestealer", "exhume", "reconstruction", "gather_their_souls", "nightmare_blade", "bog_regeneration", "viral_outbreak", "evolve", "relentless_predator"},
        bogCardList = {"contaminate", "remote_plague", "armor_of_disease", "epidemic", "infestation", "parasite_infusion"},

        damageTaken = 0,
        damageDealt = 0,

        OnApply = function( self, battle )
            -- remove other abilities
            if self.owner:HasCondition("equip_flail") then
                self.owner:RemoveCondition("equip_flail", self.owner:GetConditionStacks("equip_flail"), self)
            end
            if self.owner:HasCondition("equip_glaive") then
                self.owner:RemoveCondition("equip_glaive", self.owner:GetConditionStacks("equip_glaive"), self)
            end
            if self.owner:HasCondition("KINGPIN") then
                self.owner:RemoveCondition("KINGPIN", self.owner:GetConditionStacks("KINGPIN"), self)
            end
        end,

        event_handlers =
        {
            -- cannot have flail, glaive, or kingpin active while this ability is active
            [ BATTLE_EVENT.CARD_MOVED ] = function( self, battle, attack, hit )
                if self.owner:HasCondition("equip_flail") then
                    self.owner:RemoveCondition("equip_flail", self.owner:GetConditionStacks("equip_flail"), self)
                end
                if self.owner:HasCondition("equip_glaive") then
                    self.owner:RemoveCondition("equip_glaive", self.owner:GetConditionStacks("equip_glaive"), self)
                end
                if self.owner:HasCondition("KINGPIN") then
                    self.owner:RemoveCondition("KINGPIN", self.owner:GetConditionStacks("KINGPIN"), self)
                end
            end,
            -- have a chance to gain bog abilities every turn, free until played.
            [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, battle, attack, hit )
                
                local randomCard = math.random(1,6)
                local randomChance = math.random(1,2)
                if randomChance == 1 then
                    local card = Battle.Card( self.bogCardList[randomCard], self.owner )
                    card:TransferCard( battle:GetHandDeck() )
                    card:SetFlags( CARD_FLAGS.FREEBIE )
                end
            end,
            -- expend 1 card from draw and discard pile, add bog card to draw and discard pile.  Extremely buggy unsurprisingly :/
            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle, attack, hit )
                if battle:GetDrawDeck():CountCards() > 0  then
                    local randomCard1 = battle:GetDrawDeck():PeekRandom()
                    for i, card in battle:GetDrawDeck():Cards() do
                        if randomCard1.rarity == CARD_RARITY.UNIQUE then -- basically doesn't throw away unique rarity cards; items, bog cards.
                            randomCard1 = battle:GetDrawDeck():PeekRandom()
                        else
                            battle:ExpendCard(randomCard1)
                            -- get bog card below
                            local bogCard = math.random(1,11)
                            local card = Battle.Card( self.bogCards[bogCard], self.owner )
                            battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
                            break
                        end
                    end
                end
                if battle:GetDiscardDeck():CountCards() > 0 then
                    local randomCard2 = battle:GetDiscardDeck():PeekRandom()
                    for i, card in battle:GetDiscardDeck():Cards() do
                        if randomCard2.rarity == CARD_RARITY.UNIQUE then
                            randomCard2 = battle:GetDiscardDeck():PeekRandom()
                        else
                            battle:ExpendCard(randomCard2)
                            local bogCard = math.random(1,11)
                            local card = Battle.Card( self.bogCards[bogCard], self.owner )
                            battle:DealCard( card, battle:GetDeck( DECK_TYPE.DISCARDS ) )
                            break
                        end
                    end
                end
            end,
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit, target )
                if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                    self.damageTaken = self.damageTaken + math.round(hit.damage / 2)
                end
                if attack.attacker == self.owner and attack.card:IsAttackCard() and not hit.evaded then
                    self.damageDealt = self.damageDealt + hit.damage
                end
                
            end
        }

    },

    ARMOR_OF_DISEASE = 
    {
        name = "Armor Of Disease", 
        desc = "The next enemy that attacks you, will gain {EPIDEMIC}, {REMOTE_PLAGUE}, {PARASITIC_INFUSION} or {CONTAMINATION}.",
        icon = "battle/conditions/armored_pet.tex",  

        ctype = CTYPE.BUFF,
        
        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT] = function(self, battle, attack, hit, target)
                local randomDebuff = math.random(1,4)
                local debuffList = {"EPIDEMIC", "REMOTE_VIRUS", "PARASITIC_INFUSION", "CONTAMINATION"}
                local debuffStacks = 0

                -- change stacks inflicted on enemy depending on the condition
                if randomDebuff == 1 then
                    debuffStacks = 3
                elseif randomDebuff == 2 then
                    debuffStacks = math.random(3,10)
                    local randomNum = math.random(1,3)
                    local remoteCards = {"remote_expunge", "remote_blind", "remote_virus"}
                    local card = Battle.Card( remoteCards[randomNum], battle:GetPlayerFighter()  )
                    card:TransferCard(battle:GetDrawDeck())
                elseif randomDebuff == 3 then
                    debuffStacks = math.round(attack.attacker:GetMaxHealth() * 0.6)
                elseif randomDebuff == 4 then
                    debuffStacks = math.round(attack.attacker:GetHealth() * 0.80)
                end

                if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                    attack.attacker:AddCondition(debuffList[randomDebuff], debuffStacks, self)
                    self.owner:RemoveCondition("ARMOR_OF_DISEASE", self.owner:GetConditionStacks("ARMOR_OF_DISEASE"), self)
                end
            end
        }
    },

    EPIDEMIC = 
    {
        name = "The Epidemic", 
        desc = "Every turn, shuffle a Viral Sadism card into your discard pile for every enemy with this condition then have a chance to spread the virus to an ally.",
        icon = "battle/conditions/burr_eye_stalk_vision.tex",  

        ctype = CTYPE.DEBUFF,

        max_stacks = 3,

        event_handlers = 
        {
            [ BATTLE_EVENT.END_PLAYER_TURN] = function(self, battle, hit, target, fighter)
                local virusCount = 0
                local randomChance = math.random(1,4)
                for i, ally in self.owner:GetTeam():Fighters() do
                    if ally:HasCondition("EPIDEMIC") then
                        virusCount = virusCount + 1
                    end
                    if not ally:HasCondition("EPIDEMIC") then
                        if randomChance == 1 then
                            ally:AddCondition("EPIDEMIC", 3, self)
                        end
                    end
                end
                if virusCount > 0 then
                    for i=1, virusCount, 1 do
                        local card = Battle.Card( "viral_sadism", battle:GetPlayerFighter() )
                        battle:DealCard( card, battle:GetDeck( DECK_TYPE.DISCARDS ) )
                        virusCount = 0
                    end
                end
                self.owner:RemoveCondition("EPIDEMIC", 1, self)
            end
        }
    },

    REMOTE_VIRUS = -- implement: if enemy with remote virus dies, it is spread to another enemy.
    {
        name = "Remote Virus", 
        desc = "Every turn, inflict this target with a random debuff as long as {REMOTE_PLAGUE} is active.",
        icon = "battle/conditions/eyes_of_the_bog_debuff.tex",  

        ctype = CTYPE.DEBUFF,

        OnApply = function( self, battle )
            local randomDebuff = math.random(1,3)
            local debuffList = {"BLEED", "IMPAIR", "DEFECT", "STUN", "WOUND", "TARGETED", "EXPOSED",}
            if self.owner:HasCondition("REMOTE_PLAGUE") then
                self.owner:AddCondition(debuffList[randomDebuff], 1, self)
            end
        end,

        event_handlers = 
        {
            [ BATTLE_EVENT.BEGIN_PLAYER_TURN] = function(self, battle, attack, hit, target, fighter)
                local randomDebuff = math.random(1,7)
                local debuffList = {"BLEED", "IMPAIR", "DEFECT", "STUN", "WOUND", "TARGETED", "EXPOSED",}
                if self.owner:HasCondition("REMOTE_PLAGUE") then
                    self.owner:AddCondition(debuffList[randomDebuff], 1, self)
                else
                    self.owner:RemoveCondition("REMOTE_VIRUS", self.owner:GetConditionStacks("REMOTE_VIRUS"), self)
                end
            end
        }
         
    },

    BLINDED = -- work in progress
    {
        name = "Blinded", 
        desc = "This enemy is blinded and will miss their next attack and following attacks depending on the stacks of {BLINDED}. Remove one stack every attack.",
        icon = "battle/conditions/lumin_burnt.tex",  
        ctype = CTYPE.DEBUFF,

        OnPreDamage = function( self, damage, attacker, battle, source )
           
        end,

         
    },

    REMOTE_PLAGUE = 
    {
        name = "Remotely Plagued", -- using an OnApply to give a remote card to you is bugged (use Remote Plague card instead)
        desc = "Shuffle a Plague Remote into your deck which will do certain effects depending on the remote.  Every turn reduce this condition by 1",
        icon = "battle/conditions/acidic_slime.tex",  

        ctype = CTYPE.DEBUFF,

        -- OnApply = function( self, battle )
        --     local randomNum = math.random(1,1)
        --     local remoteCards = {"remote_expunge"}
        --     local card = Battle.Card( remoteCards[randomNum], self.owner )
        --     card:TransferCard( battle:GetDrawDeck() )
        -- end,

        event_handlers = 
        {
            [ BATTLE_EVENT.BEGIN_PLAYER_TURN] = function(self, battle, attack, hit, target, fighter)
                self.owner:RemoveCondition("REMOTE_PLAGUE", 1, self)
            end
        }
    },

    CONTAMINATION = 
    {
        name = "Contamination",
        desc = "Dealing damage to this enemy will decrease the stacks of {CONTAMINATION} depending on the damage. When stacks hit 0, deal damage depending on the inflicted user's max health then all enemies gain {CONTAMINATION}.",
        icon = "battle/conditions/acidic_slime.tex",  
        ctype = CTYPE.DEBUFF,

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT] = function(self, battle, attack, hit, target, fighter)
                if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                    self.owner:RemoveCondition( "CONTAMINATION", hit.damage )
                    if self.owner:GetConditionStacks("CONTAMINATION") <= 1 or hit.damage >= self.owner:GetConditionStacks("CONTAMINATION") then
                        for i, ally in self.owner:GetTeam():Fighters() do
                            ally:AddCondition("CONTAMINATION", math.round(ally:GetHealth()))
                            ally:ApplyDamage( math.round(self.owner:GetMaxHealth() * 0.25), math.round(self.owner:GetMaxHealth() * 0.25), self)
                        end
                    end
                end
            end
        }
    },


    TEMP_SHATTER = 
    {
        name = "Temporary Shatter",
        desc = "When your turn ends, remove 1 shatter.",
        icon = "battle/conditions/power_loss.tex",

        event_handlers =
        {
            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, card, target )
                self.owner:RemoveCondition("SHATTER")
                self.owner:RemoveCondition(self.id)
            end,
        },
    },

    BLEEDING_EDGE = 
    {
        name = "Bleeding Edge",
        desc = "Gives an enemy stacks of {BLEEDING_EDGE} depending on their health, if the target has bleed, they start with lower stacks, attacking this target will decrease stacks, deal massive damage and heal after stacks have depleted to 0.",
        icon = "battle/conditions/bloodbath.tex",

        ctype = CTYPE.DEBUFF,

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT] = function(self, battle, attack, hit, target, fighter)
                if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                    self.owner:RemoveCondition( "BLEEDING_EDGE", attack.card.max_damage )
                    if self.owner:GetConditionStacks("BLEEDING_EDGE") <= 1 or hit.damage >= self.owner:GetConditionStacks("BLEEDING_EDGE") then
                        self.owner:ApplyDamage( math.round(self.owner:GetMaxHealth() * 0.25), 10, self )
                        attack.attacker:HealHealth(math.round(self.owner:GetMaxHealth() * 0.25), self)
                    end
                end
            end
        }
    },

    PARASITIC_INFUSION = 
    {
        name = "Parasitic Infusion",
        desc = "Dealing damage to this target will decrease {PARASITIC_INFUSION} stacks, After {PARASITIC_INFUSION} stacks hit 0, spawn a Grout Eye or Grout Knuckle to your side or a Grout Mine to the enemy team.",
        icon = "battle/conditions/brain_of_the_bog_debuff.tex",

        ctype = CTYPE.DEBUFF,

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT] = function(self, battle, attack, hit, target, fighter)
                if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                    self.owner:RemoveCondition( "PARASITIC_INFUSION", hit.damage )
                    local randomNum = math.random(1,2)
                    if self.owner:GetConditionStacks("PARASITIC_INFUSION") <= 1 or hit.damage > self.owner:GetConditionStacks("PARASITIC_INFUSION") and randomNum == 1 then
                        local sparkMine = Agent( "GROUT_SPARK_MINE" )
                        local fighter = Fighter.CreateFromAgent( sparkMine, battle:GetScenario():GetAllyScale() )
                        self.owner:GetTeam():AddFighter( fighter )
                        self.owner:GetTeam():ActivateNewFighters()
                        self.owner:RemoveCondition("PARASITIC_INFUSION", self.owner:GetConditionStacks("PARASITIC_INFUSION"),self)
                    elseif self.owner:GetConditionStacks("PARASITIC_INFUSION") <= 1 or hit.damage > self.owner:GetConditionStacks("PARASITIC_INFUSION") and randomNum == 2 then
                        local groutKnuckle = Agent( "GROUT_KNUCKLE" )
                        local fighter = Fighter.CreateFromAgent( groutKnuckle, battle:GetScenario():GetAllyScale() )
                        self.owner:GetEnemyTeam():AddFighter( fighter )
                        self.owner:GetEnemyTeam():ActivateNewFighters()
                        self.owner:RemoveCondition("PARASITIC_INFUSION", self.owner:GetConditionStacks("PARASITIC_INFUSION"),self)
                    end
                    -- elseif self.owner:GetConditionStacks("PARASITIC_INFUSION") <= 1 or hit.damage > self.owner:GetConditionStacks("PARASITIC_INFUSION") and randomNum == 3 then
                    --     local groutEye = Agent( "GROUT_EYE" )
                    --     local fighter = Fighter.CreateFromAgent( groutEye, battle:GetScenario():GetAllyScale() )
                    --     self.owner:GetTeam():AddFighter( fighter )
                    --     self.owner:GetTeam():ActivateNewFighters()
                    -- end
                end
            end
        }
    },

    TAG_TEAM = 
    {
        name = "Tag Team",
        desc = "Your team generates {TAG_TEAM} stacks every time your team makes an action, these stacks can be consumed to use powerful team abilities. After you end your turn, you will shuffle 1 Battle Cry card into your deck if you have less than 2 Battle Cry cards.",
        icon = "battle/conditions/ai_spark_baron_goon_buff.tex",

        min_stacks = 1,
        bc_cards = 0,
        cardCount = 0,

        OnApply = function( self, battle )
            local randomNum = math.random(1,3)
            local battleCryCards = {"battle_cry_rejuvenate", "battle_cry_inspire", "battle_cry_hold_line"}
            local card1 = Battle.Card( battleCryCards[randomNum], self.owner )
            self.bc_cards = self.bc_cards + 1
            card1:TransferCard( battle:GetDrawDeck() )
        end,

        event_handlers =
        {

                [ BATTLE_EVENT.ON_HIT] = function(self, card, fighter, hit)
                    if hit.attacker ~= self.owner then
                        for i, ally in ipairs(self.owner:GetTeam():GetFighters()) do
                            if ally.prepared_cards then
                                for i, card in ipairs( ally.prepared_cards ) do
                                    self.owner:AddCondition("TAG_TEAM", 1)
                                end
                            end
                        end
                    end
                 end,

                 [ BATTLE_EVENT.PRE_RESOLVE] = function(self, battle, attack)
                    self.cardCount = 0
                    for i, card in battle:GetDrawDeck():Cards() do
                        if card.id == "battle_cry_rejuvenate" then
                            self.cardCount = self.cardCount + 1
                        end
                        if card.id == "battle_cry_inspire" then
                            self.cardCount = self.cardCount + 1
                        end
                        if card.id == "battle_cry_hold_line" then
                            self.cardCount = self.cardCount + 1
                        end
                    end
                    for i, card in battle:GetDiscardDeck():Cards() do
                        if card.id == "battle_cry_rejuvenate" then
                            self.cardCount = self.cardCount + 1
                        end
                        if card.id == "battle_cry_inspire" then
                            self.cardCount = self.cardCount + 1
                        end
                        if card.id == "battle_cry_hold_line" then
                            self.cardCount = self.cardCount + 1
                        end
                    end
                    for i, card in battle:GetHandDeck():Cards() do
                        if card.id == "battle_cry_rejuvenate" then
                            self.cardCount = self.cardCount + 1
                        end
                        if card.id == "battle_cry_inspire" then
                            self.cardCount = self.cardCount + 1
                        end
                        if card.id == "battle_cry_hold_line" then
                            self.cardCount = self.cardCount + 1
                        end
                    end
                    self.bc_cards = self.cardCount
                 end,

                 [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, fighter, battle)
                    local randomNum = math.random(1,3)
                    local battleCryCards = {"battle_cry_rejuvenate", "battle_cry_inspire", "battle_cry_hold_line"}
                    if self.bc_cards < 2 then
                        local card1 = Battle.Card( battleCryCards[randomNum], self.owner )
                        card1:TransferCard( self.battle:GetDrawDeck() )
                        self.bc_cards = self.bc_cards + 1
                    end
                end,
        }

        
    },

    DEFLECTION = 
    {
        name = "Deflection",
        desc = "Deal damage to enemies equal to 25% of the damage they will deal to you and your team and gain {DEFEND} equal to that amount {KINGPIN} 15: Deal 50% damage back instead and gain {DEFEND} for the same amount.",
        icon = "battle/conditions/shield_of_hesh.tex",

        event_handlers =
        {
                [ BATTLE_EVENT.END_PLAYER_TURN ] = function(self, card, fighter)
                    local count = 0
                        for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                            if enemy.prepared_cards then
                                for i, card in ipairs( enemy.prepared_cards ) do
                                    if card:IsAttackCard() then
                                        if self.owner:HasCondition("KINGPIN") then
                                            if self.owner:GetConditionStacks("KINGPIN") >= 15 then
                                                self.owner:AddCondition("DEFEND", math.round(card.max_damage / 2), self)
                                            end
                                        else
                                            self.owner:AddCondition("DEFEND", math.round(card.max_damage / 4), self)
                                        end
                                        count = count + card.max_damage
                                    end
                                end
                            end
                            if self.owner:HasCondition("KINGPIN") then
                                if self.owner:GetConditionStacks("KINGPIN") >= 15 then
                                    enemy:ApplyDamage( math.round(count / 2), math.round(count / 2), self )
                                end
                            else
                                enemy:ApplyDamage( math.round(count / 4), math.round(count / 4), self )
                            end
                        end
                    self.owner:RemoveCondition("DEFLECTION", 1)
                end
        }
    },

    ULTIMATE_HUNTER = 
    {
        name = "Ultimate Hunter",
        desc = "Gain {DEFEND} whenever you swap weapons. Shuffle {equip_flail} or {equip_glaive} into your draw pile after every turn end depending on which weapon you have equipped.",
        icon = "battle/conditions/vroc_howl.tex",

        flailCount = 0,
        glaiveCount = 0,

        event_handlers =
        {
            [ BATTLE_EVENT.CARD_MOVED ] = function( self, battle, attack, hit )
                if self.owner:HasCondition("equip_flail") then
                    self.flailCount = 1
                end
                if self.owner:HasCondition("equip_glaive") then
                   self.glaiveCount = 1
                end
                if self.flailCount == 1 and self.glaiveCount == 1 then
                    self.flailCount = 0
                    self.glaiveCount = 0
                    self.owner:AddCondition("DEFEND", 5, self)
                end
            end,

            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle, attack, hit )
                local weapons = {"flail_swap", "glaive_swap"}
                if self.owner:HasCondition("equip_glaive") then
                    local card = Battle.Card( weapons[1], self.owner )
                    battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
                elseif self.owner:HasCondition("equip_flail") then
                    local card = Battle.Card( weapons[2], self.owner )
                    battle:DealCard( card, battle:GetDeck( DECK_TYPE.DRAW ) )
                end
            end
        }
    },

    AFTERBURN_GLOVES = 
    {
        name = "Afterburner Gloves",
        desc = "For 3 turns, all of your attacks apply burn to enemies and yourself, if {equip_flail} is active gain defend equal to your {BURN}.",
        icon = "battle/conditions/sharpened_blades.tex",

        event_handlers =
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                if attack.attacker == self.owner and attack.card:IsAttackCard() and not hit.evaded then
                    for i, hit in attack:Hits() do
                        local target = hit.target
                        if not hit.evaded then 
                            target:AddCondition("BURN", self.burn_amount, self)
                        end
                    end
                    self.owner:AddCondition("BURN", 1)
                    if self.owner:HasCondition("equip_flail") then
                        self.owner:AddCondition("DEFEND", 1)
                    end
                end
            end,
            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle, attack, hit )
                self.owner:RemoveCondition("AFTERBURN_GLOVES", 1)
            end
        }

    },

    BLADE_DANCE = 
    {
        name = "Blade Dance",
        desc = "Gain stacks of {BLADE_DANCE} depending on a random enemy's health which will decrease the stacks for every point of damage you deal, when the stacks reach 0, gain evade and place {glaive_swap} or {flail_swap} into your hand.",
        icon = "battle/conditions/sharpened_blades.tex",

        min_stacks = 1,
         
        event_handlers =
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                if attack.attacker == self.owner and attack.card:IsAttackCard() and not hit.evaded then
                    for i, hit in attack:Hits() do
                        if not hit.evaded then
                            self.owner:RemoveCondition("BLADE_DANCE", hit.damage, self)
                    end
                    end
                    if self.owner:GetConditionStacks("BLADE_DANCE") <= 1 then
                        -- get new weapon cards
                        local weapons = {"flail_swap", "glaive_swap"}
                        if self.owner:HasCondition("equip_glaive") then
                            local card = Battle.Card( weapons[1], self.owner )
                            battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
                        elseif self.owner:HasCondition("equip_flail") then
                            local card = Battle.Card( weapons[2], self.owner )
                            battle:DealCard( card, battle:GetDeck( DECK_TYPE.IN_HAND ) )
                        end
                        -- get evasion
                        local randomEnemyHealth = 0
                        local target_fighter = {}
                        battle:CollectRandomTargets( target_fighter, self.owner:GetEnemyTeam().fighters, 1 )
                            for i=1, #target_fighter do
                                randomEnemyHealth = target_fighter[i]:GetHealth()
                            end
                            randomEnemyHealth = math.round(randomEnemyHealth * 0.75)
                        self.owner:AddCondition("BLADE_DANCE", randomEnemyHealth, self)
                        self.owner:AddCondition("EVASION", 1, self)
                        for i, hit in attack:Hits() do
                            if not hit.evaded then
                                self.owner:RemoveCondition("BLADE_DANCE", hit.damage, self)
                        end
                        end
                    end
                end
            end
        }
    },

    KINGPIN = 
    {
        name = "Kingpin",
        desc = "Gain {KINGPIN} by making 6 actions using the same weapon consecutively. {KINGPIN} can unlock the full potential of certain cards, every action a fighter makes generates {KINGPIN}.  Swapping weapons removes {KINGPIN}. Every 10 stacks of {KINGPIN} triggers a special ability",
        icon = "battle/conditions/burr_boss_enrage.tex",
        
        glaive_equipped = false,
        flail_equipped = false,

        -- 10 stacks: gain METALLIC
        -- 20 stacks: Your attacks on an enemy have a small chance of granting you a random buff

        -- not yet implemented:
        -- 30 stacks: random enemy gains DEFECT every turn
        -- 40 stacks: your attacks have a chance to inflict an enemy with PARASITIC_INFUSION or BLEEDING_EDGE
        -- 50 stacks: every turn a random enemy gains all of your current debuffs

        OnApply = function( self )
            if self.owner:HasCondition("equip_glaive") then
                self.glaive_equipped = true
            end
            if self.owner:HasCondition("equip_flail") then
                self.flail_equipped = true
            end
        end,

        event_handlers =
        {
            [ BATTLE_EVENT.POST_RESOLVE ] = function( self, battle, fighter )
                self.owner:AddCondition("KINGPIN", 1, self)
                -- check which weapon is equipped
                if self.owner:HasCondition("equip_glaive") then
                    self.glaive_equipped = true
                end
                if self.owner:HasCondition("equip_flail") then
                    self.flail_equipped = true
                end
                
                -- remove all stacks of kingpin if you switch weapons
                if self.glaive_equipped == true and self.flail_equipped == true and self.owner:GetConditionStacks("KINGPIN") >= 2 then
                    self.owner:RemoveCondition("KINGPIN", self.owner:GetConditionStacks("KINGPIN"))
                    if not self.owner:HasCondition("equip_glaive") then
                        self.glaive_equipped = false
                    end
                    if not self.owner:HasCondition("equip_flail") then
                        self.flail_equipped = false
                    end
                end

                -- 10 stacks: gain metallic 
                if self.owner:GetConditionStacks("KINGPIN") >= 10 then
                    if not self.owner:HasCondition("METALLIC") then
                        self.owner:AddCondition("METALLIC", 1, self)
                        if self.owner:HasCondition("BLEED") then
                            self.owner:RemoveCondition("BLEED", self.owner:GetConditionStacks("BLEED"))
                        end
                        if self.owner:HasCondition("WOUND") then
                            self.owner:RemoveCondition("WOUND", self.owner:GetConditionStacks("WOUND"))
                        end
                    end
                end
            end,

            -- 20 stacks: have a chance to gain a random buff on each attack
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, fighter, attack, target )
                local randomBuffs = {"POWER", "ARMOURED", "NEXT_TURN_DRAW", "RIPOSTE", "EVASION", "DEFLECT", "FORCE_FIELD", "FLURRY", "BLADE_DANCE", "TAG_TEAM"}
                local randomNum = math.random(1,10)
                local randomChance = math.random(1,4)
                if attack.attacker == self.owner then
                    if self.owner:GetConditionStacks("KINGPIN") >= 20 and randomChance == 1 then
                        self.owner:AddCondition(randomBuffs[randomNum], 1, self)
                    end
                end
            end
        }
    },

    PLEAD_FOR_LIFE = 
    {
        name = "Pleaded for Life",
        desc = "You pleaded for you life and your enemies think you surrendered, stopping enemies from attacking you and lowering their guard dealing more damage to them with attack cards.",
        icon = "battle/conditions/bloody_mess.tex",
        max_stacks = 1,  

        CanBeTargetted = function( self, card, fighter )
            if fighter:HasCondition("PLEAD_FOR_LIFE") then
                return false
            end
            return true
        end,

        event_handlers = 
        {
            [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, battle, fighter )
                self.owner:RemoveCondition("PLEAD_FOR_LIFE", 1, self)
            end
        }
    },

    FLURRY = 
    {
        name = "Flurry",
        desc = "Apply a buff or debuff to you or an enemy whenever you attack an enemy for one turn.",
        icon = "battle/conditions/bloody_mess.tex",
        -- apply_sound = "event:/sfx/battle/status/system/Status_Buff_Attack",
        max_stacks = 1,

        event_handlers =
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                local randomConNum = math.floor(math.random(1,6))
                local randomTeam = math.random(1,2)
                local posConditions = {"BLEED", "IMPAIR", "BURN", "STUN", "WOUND", "EXPOSED"}
                local posPosConditions = {"POWER", "ARMOURED", "NEXT_TURN_DRAW", "RIPOSTE", "METALLIC", "EVASION"}
                if attack.attacker == self.owner and attack.card:IsAttackCard() and not hit.evaded then
                    if randomTeam == 1 then
                        hit.target:AddCondition( posConditions[randomConNum], 1, self)
                    elseif randomTeam == 2 then
                        self.owner:AddCondition( posPosConditions[randomConNum], 1, self)
                    end
                    
                end
            end,

            [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle )
                self.owner:RemoveCondition("FLURRY")
            end,
        }

    },

    FORCE_FIELD =
    {
        name = "Rentorian Force Field",
        desc = "Gain a shield that will negate all damage unless the enemy that is attacking you has higher damage than the threshold, the threshold is equal to 10% of your max health plus current defend value.",
        icon = "battle/conditions/active_shield_generator.tex",


        -- local function shieldVisual( fighter )
        --     fighter.battle:BroadcastEvent( BATTLE_EVENT.CUSTOM, fighter, function( fight_screen, ent )
        --         local anim_fighter = ent.cmp.AnimFighter
        --         anim_fighter:Flash(0xff00ffff, 0.1, 0.3, 1) 
        --     end)
        -- end


        event_handlers = 
        {
            [ BATTLE_EVENT.END_PLAYER_TURN ] = function (self, battle, attack)
                local threshold = math.round(self.owner:GetMaxHealth() * 0.10)
                for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                    if enemy.prepared_cards then
                        for i, card in ipairs( enemy.prepared_cards ) do
                            if card:IsAttackCard() then
                                if card.max_damage <= threshold then
                                    card.min_damage = 0
                                    card.max_damage = 0
                                end
                                if card.max_damage > threshold then
                                    if self.owner:HasCondition("DEFEND") then
                                        if card.max_damage < threshold + self.owner:GetConditionStacks("DEFEND") then
                                            card.min_damage = 0
                                            card.max_damage = 0
                                        else
                                            self.owner:RemoveCondition("FORCE_FIELD", 1, self)
                                        end
                                    else
                                        self.owner:RemoveCondition("FORCE_FIELD", 1, self)
                                    end
                                end
                            end
                        end
                    end
                end
            end,
        }
    },

    scaling_defense = 
    {
        name = "Strength of One Thousand",
        desc = "Gain {ARMOURED} every turn, you will gain one more stack of {ARMOURED} than you had last turn.",
        icon = "battle/conditions/rentorian_battle_armor.tex",

        OnApply = function( self )
            self.owner:AddCondition("ARMOURED", 1)
        end,

        event_handlers = 
        {
            [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function (self, battle, attack)
                self.owner:AddCondition("ARMOURED", 1)
            end
        }
    },

    equip_glaive = 
    {
        name = "Kashio's Force Glaive",
        desc = "Deal extra damage with your attacks and gain an extra action per turn at the cost of taking more damage and halving {DEFEND}.",
        -- desc = "Deal extra damage on your first attack and gain an extra action per turn at the cost of taking more damage and halving {DEFEND}.",
        icon = "battle/conditions/kashio_glaive.tex",

        max_stacks = 1,
        momentum = 0,

        OnApply = function( self, card )
            if self.owner:HasCondition("equip_flail") then
                self.owner:RemoveCondition("equip_flail", 1, self)
            end
            self.owner:AddCondition("NEXT_TURN_ACTION", 1, self)
            -- if self.owner == card.owner and not card.name == "glaive_swap" then
            --     self.owner:BroadcastEvent( BATTLE_EVENT.PLAY_ANIM, "transition1", false, true)
            -- end
        end,

        event_handlers = 
        {

            [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function (self, battle, fighter)
                self.owner:AddCondition("NEXT_TURN_ACTION", 1, self)
            end,

            -- take roughly 30% more damage and deal 30% more damage
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card.owner == self.owner and card:IsAttackCard() then
                    dmgt:ModifyDamage( math.round(dmgt.min_damage + dmgt.min_damage * 0.3), math.round(dmgt.max_damage + dmgt.max_damage * 0.3), self )
                end
                if target == self.owner then
                    dmgt:ModifyDamage( math.round(dmgt.min_damage + dmgt.min_damage * 0.3), math.round(dmgt.max_damage + dmgt.max_damage * 0.3), self )
                end
            end,

            -- defend for less
            [ BATTLE_EVENT.CALC_MODIFY_STACKS ] = function( self, acc, condition_id, fighter, source )
                if condition_id == "DEFEND" and fighter == self.owner then
                    if acc.value > 0 then
                        acc:AddValue( -math.floor( acc.value / 2 ), self )
                    end
                end
            end,
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, fighter, attack, target)
                if attack.attacker == self.owner then
                    if battle:GetDrawDeck():HasCard("the_execution") or battle:GetHandDeck():HasCard("the_execution") or battle:GetDiscardDeck():HasCard("the_execution") then
                        self.momentum = 0
                    end
                    self.momentum = self.momentum + 1
                    if self.owner:HasCondition("KINGPIN") then
                        self.momentum = 0
                    end
                    if self.momentum >= 6 then
                        local card = Battle.Card( "the_execution", self.owner )
                        card:TransferCard( self.battle:GetHandDeck() )
                        self.momentum = 0
                    end
                end
            end,
        }
    },

    equip_flail = 
    {
        name = "Kashio's Flail",
        desc = "Gain {DEFEND} equal to 5% of your current health and {DEFEND} then {HEAL} self for 10% of your missing health every turn. Also have a chance 25% chance to apply a random debuff to an enemy on hit.",
        -- desc = "Gain {DEFEND} for every 10 current health then {HEAL} self for 10% of your missing health every turn.", -- new description
        icon = "battle/conditions/spree_rage.tex",

        max_stacks = 1,
        momentum = 0,

        OnApply = function( self )
            if self.owner:HasCondition("equip_glaive") then
                self.owner:RemoveCondition("equip_glaive", 1, self)
                self.owner:RemoveCondition("NEXT_TURN_ACTION", 1, self)
            end
            -- self.owner:BroadcastEvent( BATTLE_EVENT.PLAY_ANIM, "taunt", false, true)
        end,

        event_handlers = 
        {
            -- 25% chance to apply debuff to enemy 
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                local randomNum = math.random(1,4) -- 1 to 4
                local randomConNum = math.random(1,6) -- 1 to 6, kept crashing because arrays start at index 1  in lua
                local posConditions = {"BLEED", "IMPAIR", "BURN", "STUN", "WOUND", "EXPOSED"}
                if randomNum == 1 then
                    if attack.attacker == self.owner and attack.card:IsAttackCard() then
                            if not hit.evaded then 
                                hit.target:AddCondition(posConditions[randomConNum], 1, self)
                            end
                    end  
                end      
            end,

            -- defense and healing every turn
            [ BATTLE_EVENT.END_PLAYER_TURN ] = function (self, battle, attack)
                self.owner:AddCondition("DEFEND", math.round(self.owner:GetHealth() * 0.05), self)
                self.owner:HealHealth(math.round((self.owner:GetMaxHealth() - self.owner:GetHealth()) * 0.10), self)
            end,

             -- gain card "the_execution after using the same weapon for 6 actions"
            [ BATTLE_EVENT.ON_HIT] = function( self, battle, fighter, attack, target)
                if attack.attacker == self.owner then
                    if battle:GetDrawDeck():HasCard("the_execution") or battle:GetHandDeck():HasCard("the_execution") or battle:GetDiscardDeck():HasCard("the_execution") then
                        self.momentum = 0
                    end
                    self.momentum = self.momentum + 1
                    if self.owner:HasCondition("KINGPIN") then
                        self.momentum = 0
                    end
                    if self.momentum >= 6 then
                        local card = Battle.Card( "the_execution", self.owner )
                        card:TransferCard( self.battle:GetHandDeck() )
                        self.momentum = 0
                    end
                end
            end,

        }
    },
}

for id, def in pairs( CONDITIONS ) do
    Content.AddBattleCondition( id, def )
end
local battle_defs = require "battle/battle_defs"
local CARD_FLAGS = battle_defs.CARD_FLAGS
local EVENT = battle_defs.EVENT
local BATTLE_EVENT = battle_defs.BATTLE_EVENT

local CARDS =
{
    improvise_smokescreen = 
    {
        name = "Smokescreen",
        anim = "throw2",
        max_xp = 0,
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
            self.owner:AddCondition("IMPAIR", 1 )
            self.owner:AddCondition("EVASION", self.evasion_amt, self)
        end
    },

    improvise_rage = 
    {
        name = "Rage",
        anim = "taunt",
        max_xp = 0,
        target_type = TARGET_TYPE.SELF,
        desc = "Gain {1} {POWER_LOSS} then {WOUND} self.",
        icon = "RISE:textures/rage.png",

        rarity = CARD_RARITY.UNIQUE,
        cost = 0,
        flags = CARD_FLAGS.SKILL| CARD_FLAGS.EXPEND,
        power_amt = 2,
        wound_amt = 1,

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
        max_xp = 0,
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
        name = "Burning Flail Crack",
        desc = "<#UPGRADE>Apply {1} {BURN}.</>",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.features.BURN ))
        end,
        manual_desc = true,
        features = 
        {
            BURN = 1,
        }
    },
    flail_crack_plus3 = 
    {
        name = "Flail Crack of Clarity",
        desc = "<#UPGRADE>{CONSUME}</>",
        manual_desc = true,
        flags = CARD_FLAGS.MELEE | CARD_FLAGS.CONSUME,
        
        min_damage = 7,
        max_damage = 7,
    },

    flail_smash = 
    {
        name = "Flail Smash",
        rarity = CARD_RARITY.BASIC,
        cost = 1,
        max_xp = 4,
        flags = CARD_FLAGS.MELEE,
        icon = "RISE:textures/flailsmash.png",
        min_damage = 1,
        max_damage = 3,
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
        desc = "<#UPGRADE>Apply {1} {BURN}.</>",
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
        
        min_damage = 6,
        max_damage = 6,
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
        desc = "<#UPGRADE>Apply {WOUND} and {IMPAIR} then {WOUND} self</>.",   
        manual_desc = true,
        features = 
        {
            IMPAIR = 1,
        }
    },
    flail_slam_plus2 = 
    {
        name = "Boosted Flail Slam",
        desc = "<#UPGRADE>Apply {WOUND} then {WOUND} self</>.",   
        manual_desc = true,
        
        min_damage = 5,
        max_damage = 6,
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
        desc = "<#UPGRADE>Apply {1} {DEFEND} then equip {equip_flail}</>.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.features.DEFEND ))
        end,    
        manual_desc = true,
        features = 
        {
            DEFEND = 6,
        }
    },
    safeguard_plus2 = 
    {
        name = "Offensive Safeguard",
        desc = "<#UPGRADE>Apply {1} {DEFEND} then equip {equip_glaive}</>.",
            
        manual_desc = true,
        equip_flail = 0,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.features.DEFEND ))
        end,

        features = 
        {
            DEFEND = 4,
        },

        OnPostResolve = function( self, battle, attack )
            self.owner:AddCondition("equip_glaive", 1, self)
        end,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        end
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

        pool_cards = {"improvise_rage", "improvise_burningsmash", "improvise_smokescreen" },

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
        desc = "Slice an enemy inflicting {1} {BLEED} and  {1} {BURN}.",
        icon = "RISE:textures/sliceup1.png",
        
        min_damage = 5,
        max_damage = 7,
        cost = 2,
        max_xp = 6,
        flags = CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNCOMMON,

        bleed_amount = 4,
        burn_amount = 4,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.bleed_amount ))
        end,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.burn_amount ))
        end,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    target:AddCondition("BURN", self.burn_amount, self)
                    target:AddCondition("BLEED", self.bleed_amount, self)
                end
            end
        end
    },

    spinningslash = 
    {
        name = "Spinning Slash",
        anim = "spin_attack",
        desc = "Deal bonus damage equal to the number of stacks of {BLEED} and {BURN}.",
        icon = "RISE:textures/spinningslash.png",

        min_damage = 4,
        max_damage = 6,
        cost = 1,
        max_xp = 6,
        flags = CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNCOMMON,
        bonus_damage = 1,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                if not attack:CheckHitResult( hit.target, "evaded" ) then
                    hit.target:ApplyDamage( hit.target:GetConditionStacks("BLEED") + hit.target:GetConditionStacks("BURN"), attack.attacker, hit, self.piercing )
                end
            end
        end,
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

    flail_swap =
    {
        name = "Kashio's Flail",
        desc = "Equip {equip_flail} and gain {DEFEND} equal to 5% of your maximum health and current defend then {HEAL} self for 10% of your missing health every turn. Also have a chance a 25% chance to apply a random debuff to an enemy on hit.",
        icon = "battle/overloaded_spark_hammer.tex",
        anim = "taunt",

        flags = CARD_FLAGS.BUFF | CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
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

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
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
        desc = "Hits all enemies {1} times.",

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

    },

    call_lumicyte = 
    {
        name = "Call Lumicyte",
        anim = "taunt4",
        desc = "Summons your Lumicyte pet to fight for you.",
        icon = "battle/krill_ichor.tex",

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.REPLENISH | CARD_FLAGS.EXPEND,
        cost = 0,
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
        desc = "Gain {1} {DEFLECTION}, {KINGPIN} 10: Deal half the damage enemies will deal to you instead and defend for the same amount.",
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
        cost = 0,
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
        desc = "This card costs 0 if you have {equip_glaive} equipped.",
        icon = "battle/lifeline.tex",

        min_damage = 2,
        max_damage = 3,

        flags = CARD_FLAGS.RANGED,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

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

    crippling_slice = 
    {
        name = "Crippling Slice",
        anim = "slash_up",
        desc = "Apply {1} {BLEED} to target enemy and to self.",
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
                    target:AddCondition("BLEED", self.bleed_amount, self)
                    self.owner:AddCondition("BLEED", self.bleed_amount, self)
                end
            end
        end
        
    },

    feel_what_i_feel = 
    {
        name = "Feel What I Feel",
        anim = "taunt3",
        desc = "Apply all self debuffs to target enemy.",
        icon = "RISE:textures/feelwhatifeel.png",

        flags = CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_type = TARGET_TYPE.ENEMY,
        min_damage = 0,

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
        cost = 3,
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
        desc = "Damage a random enemy and gain {EXPOSED}.",
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
        desc = "Deals 75% of the enemy's missing health.",
        icon = "battle/bonkers.tex",

        flags = CARD_FLAGS.MELEE,
        cost = 2,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 2,
        max_damage = 2,
        
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
        max_damage = 3,

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
        desc = "Gain {1} {DEFEND} and {IMPAIR} self, if {equip_flail} is active gain 7 {DEFEND} instead.",
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
                self.owner:AddCondition("IMPAIR", 2)
            end
        end
    },

    bait_and_switch = 
    {
        name = "Bait and Switch",
        anim = "spin_attack",
        desc = "Deal damage then switch to {equip_glaive}.",
        icon = "RISE:textures/baitandswitch.png",

        flags = CARD_FLAGS.SKILL | CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 2,
        max_damage = 3,

        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("equip_glaive", 1)
            self.owner:AddCondition("EXPOSED", 1)
        end,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        end,
        
    },

    highground = 
    {
        name = "I Have The Highground",
        anim = "slam",
        desc = "Draw an extra card next turn then switch to {equip_flail}.",
        icon = "battle/cataclysm.tex",

        flags =  CARD_FLAGS.MELEE | CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 2,
        max_damage = 3,

        OnPostResolve = function( self, battle, attack )
            self.owner:AddCondition( "NEXT_TURN_DRAW", self.draw_bonus )
            self.owner:AddCondition("equip_flail", 1)
        end,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_flail)
        end
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
        desc = "Gain {FORCE_FIELD} if {equip_glaive} is active, gain 3 stacks of Rentorian Force Field.",
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
        desc = "Gain stacks of {BLADE_DANCE} depending on a random enemy's current health, switch to {equip_glaive}.",
        icon = "battle/blade_fury.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 2,
        rarity = CARD_RARITY.RARE,
        max_xp = 4,
        target_type = TARGET_TYPE.SELF,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        end,

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
        desc = "Gain {KINGPIN} status, which can unlock the full potential of certain cards, switch to {equip_glaive}.",
        anim = "taunt2",
        icon = "RISE:textures/tempt.png",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.REPLENISH | CARD_FLAGS.AMBUSH,
        cost = 0,
        rarity = CARD_RARITY.RARE,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        end,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("KINGPIN", 1, self)
            self.owner:AddCondition("equip_glaive", 1 )
        end
    },

    slice_and_dice = 
    {
        name = "Slice and Dice",
        desc = "{KINGPIN} 4: Draw Slicer and Dicer into your hand.",
        anim = "spin_attack",
        icon = "RISE:textures/slice_and_dice.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 1,
        max_damage = 4,

        OnPostResolve = function( self, battle, attack, card )
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 3 then
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
        max_xp = 6,

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
        max_xp = 6,

        min_damage = 2,
        max_damage = 6,
    },

    readied_assault =
    {
        name = "Readied Assault",
        anim = "spin_attack",
        desc = "{KINGPIN} 7: Deal max damage and gain {DEFEND} equal to your max damage.",
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
                    if self.owner:GetConditionStacks("KINGPIN") >= 4 then
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
        desc = "Whenever you swap weapons, gain {DEFEND}. Swap to next weapon.",
        icon = "battle/butcher_of_the_bog.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("ULTIMATE_HUNTER", 1, self)
            if self.owner:HasCondition("equip_flail") then
                self.owner:AddCondition("equip_glaive", 1 , self)
            elseif self.owner:HasCondition("equip_glaive") then
                self.owner:AddCondition("equip_flail", 1, self)
            end
        end
    },

    control_cee =
    {
        name = "Control CEE",
        anim = "taunt",
        desc = "Gain {1} {DEFEND}, {KINGPIN} 7: Draw Control VEE into your hand.",
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
            if self.owner:GetConditionStacks("KINGPIN") >= 7 then
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
        cost = 1,
        rarity = CARD_RARITY.UNIQUE,
        max_xp = 6,
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
        desc = "{KINGPIN} 4: Shuffle a copy of Irritating Blow into your draw pile.",
        icon = "battle/weakness_quick_jab.tex",

        flags =  CARD_FLAGS.MELEE,
        cost = 0,
        rarity = CARD_RARITY.COMMON,
        max_xp = 8,
        
        min_damage = 1,
        max_damage = 3,

        OnPostResolve = function( self, battle, attack, card )
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 4 then
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
        desc = "Apply a random negative condition to either you or the enemy {KINGPIN} 15: Always apply a random debuff to an enemy.",
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
                if self.owner:GetConditionStacks("KINGPIN") >= 15 then
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
        desc = "Gain {EVASION}, {DEFEND}, {EXPOSED}, or {IMPAIR}, {KINGPIN} 23: Gain {EVASION} or {DEFEND}.",
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
                if self.owner:GetConditionStacks("KINGPIN") >= 23 then
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
        desc = "Consume all of your {TAG_TEAM} stacks to apply stacks of {MENDING} evenly depending on how many {TAG_TEAM} stacks were consumed.",
        icon = "battle/healing_vapors.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
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
        desc = "Consume all of your {TAG_TEAM} stacks to apply stacks of {POWER_LOSS} evenly depending on how many {TAG_TEAM} stacks were consumed.",
        icon = "battle/adrenaline_shot.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
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
        desc = "Consume all of your {TAG_TEAM} stacks to apply stacks of {ARMOURED} evenly depending on how many {TAG_TEAM} stacks were consumed.",
        icon = "battle/get_down.tex",

        flags =  CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
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
        desc = "Gain {TAG_TEAM} and swap to {equip_glaive}.",
        icon = "battle/baron_expedition.tex",

        flags =  CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_type = TARGET_TYPE.SELF,

        PostPresAnim = function( self, anim_fighter )
            anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
        end,

        OnPostResolve = function( self, battle, attack, card )
            self.owner:AddCondition("equip_glaive", 1, self)
            self.owner:AddCondition("TAG_TEAM", 1, self)
        end
    },

    parasite_infusion =
    {
        name = "Parasite Infusion", -- bugged when you have more than one copy in your hand: enemies gain more stacks than intended and gain even more stacks while attacking not with this card
        anim = "throw1",
        desc = "Infuses an enemy with {PARASITIC_INFUSION}, gaining stacks depending on the target enemy's max health.",
        icon = "battle/branch.tex",

        flags =  CARD_FLAGS.RANGED | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 4,

        min_damage = 1,
        max_damage = 2,

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, card, hit ) 
                local enemy_health = 0
                if hit.target ~= self.owner then
                    enemy_health = math.round(hit.target:GetMaxHealth() * 0.6)
                    hit.target:AddCondition("PARASITIC_INFUSION", enemy_health)
                end
            end
        }
    },

    bleeding_edge = 
    {
        name = "Bleeding Edge",
        anim = "slash_up",
        desc = "Slashes an enemy causing them to gain {BLEEDING_EDGE}.",
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
        desc = "If {equip_flail} is active, attack twice instead and draw a card.",
        icon = "battle/the_sledge.tex",

        flags =  CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,
      
        min_damage = 2,
        max_damage = 3,

        PreReq = function( self, battle )
            if self.owner:HasCondition("equip_flail") then
                self.hit_count = 2
                return true
            else
                self.hit_count = 1
                return false
            end
        end,

        OnPostResolve = function( self, battle, attack, card )
            if self.owner:HasCondition("equip_flail") then
                battle:DrawCards(1)
            end
        end,

        event_handlers =
        {
            [ BATTLE_EVENT.START_RESOLVE ] = function( self, battle, card )
                if card == self then
                    if self.owner:HasCondition("equip_flail") then
                        self.hit_count = 2
                    else
                        self.hit_count = 1
                    end
                end
            end,
        },
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
        desc = "If you have {equip_flail} gain {SHATTER}.",
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
      
        min_damage = 1,
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
        desc = "Gain 3 random debuffs. {KINGPIN} 20: Don't gain any debuffs.",
        icon = "RISE:textures/ransack.png",

        flags =  CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
      
        min_damage = 15,
        max_damage = 15, 

        OnPostResolve = function( self, battle, attack, card ) -- sometimes only gives you 2 debuffs
            if self.owner:HasCondition("KINGPIN") then
                if self.owner:GetConditionStacks("KINGPIN") >= 20 then
                
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
    }

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



         -- contaminate = 
    -- {
    --     name = "Contaminate",
    --     anim = "throw2",
    --     desc = "Contaminates an enemy, which grants them stacks of {CONTAMINATION} based on their missing health, dealing damage to this enemy will deal damage to enemies as well and decreasing the stacks.",
            -- when stacks hit 0, all enemies gain {CONTAMINATION}
    --     icon = "battle/improvise_chug.tex",

    --     flags =  CARD_FLAGS.MELEE,
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
        icon = "battle/conditions/brain_of_the_bog_debuff.tex",

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT] = function(self, battle, attack, hit, target, fighter)
                if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                    self.owner:RemoveCondition( "BLEEDING_EDGE", attack.card.max_damage )
                    if self.owner:GetConditionStacks("BLEEDING_EDGE") <= 1 then
                        self.owner:ApplyDamage( math.round(self.owner:GetMaxHealth() * 0.40), 10, self )
                        attack.attacker:HealHealth(math.round(self.owner:GetMaxHealth() * 0.40), self)
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

        event_handlers = 
        {
            [ BATTLE_EVENT.ON_HIT] = function(self, battle, attack, hit, target, fighter)
                if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                    self.owner:RemoveCondition( "PARASITIC_INFUSION", attack.card.max_damage )
                    local randomNum = math.random(1,3)
                    if self.owner:GetConditionStacks("PARASITIC_INFUSION") <= 1 and randomNum == 1 then
                        local sparkMine = Agent( "GROUT_SPARK_MINE" )
                        local fighter = Fighter.CreateFromAgent( sparkMine, battle:GetScenario():GetAllyScale() )
                        self.owner:GetTeam():AddFighter( fighter )
                        self.owner:GetTeam():ActivateNewFighters()
                    elseif self.owner:GetConditionStacks("PARASITIC_INFUSION") <= 1 and randomNum == 2 then
                        local groutKnuckle = Agent( "GROUT_KNUCKLE" )
                        local fighter = Fighter.CreateFromAgent( groutKnuckle, battle:GetScenario():GetAllyScale() )
                        self.owner:GetEnemyTeam():AddFighter( fighter )
                        self.owner:GetEnemyTeam():ActivateNewFighters()
                    elseif self.owner:GetConditionStacks("PARASITIC_INFUSION") <= 1 and randomNum == 3 then
                        local groutEye = Agent( "GROUT_EYE" )
                        local fighter = Fighter.CreateFromAgent( groutEye, battle:GetScenario():GetAllyScale() )
                        self.owner:GetEnemyTeam():AddFighter( fighter )
                        self.owner:GetEnemyTeam():ActivateNewFighters()
                    end
                end
            end
        }
    },

    TAG_TEAM = 
    {
        name = "Tag Team",
        desc = "Your team generates {TAG_TEAM} stacks every time your team makes an action, these stacks can be consumed to use powerful team abilities.",
        icon = "battle/conditions/ai_spark_baron_goon_buff.tex",

        min_stacks = 1,

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

                 [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, fighter )
                    if fighter == self.owner then
                        self.owner:RemoveCondition( "TAG_TEAM", 1 )
                    end
                end,
        }

        
    },

    DEFLECTION = 
    {
        name = "Deflection",
        desc = "Deal damage to enemies equal to 25% of the damage they will deal to you and gain {DEFEND} equal to that amount {KINGPIN} 10: Deal 50% damage back instead and gain {DEFEND} for the same amount.",
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
                                            if self.owner:GetConditionStacks("KINGPIN") >= 10 then
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
                                if self.owner:GetConditionStacks("KINGPIN") >= 10 then
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
        desc = "Gain {DEFEND} whenever you swap weapons.",
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
        desc = "Gain stacks of {BLADE_DANCE} depending on a random enemy's health which will decrease the stacks for every point of damage you deal, when the stacks reach 0, gain evade.",
        icon = "battle/conditions/sharpened_blades.tex",

        min_stacks = 1,
         
        event_handlers =
        {
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                for i, hit in attack:Hits() do
                    if not hit.evaded then
                        self.owner:RemoveCondition("BLADE_DANCE", hit.damage, self)
                   end
                end
                if self.owner:GetConditionStacks("BLADE_DANCE") <= 1 then
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
        }
    },

    KINGPIN = 
    {
        name = "Kingpin",
        desc = "Gain stacks of {KINGPIN} which will unlock the full potential of certain cards, every action generates {KINGPIN}.  Swapping weapons resets {KINGPIN} to 1 stack.",
        icon = "battle/conditions/burr_boss_enrage.tex",
        max_stacks = 30,
        event_handlers =
        {
            [ BATTLE_EVENT.CARD_MOVED ] = function( self, battle )
                    self.owner:AddCondition("KINGPIN", 1, self)
            end,
            -- [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
            --     if card.owner == self.owner and card:IsAttackCard() then
            --         dmgt:ModifyDamage( math.round(dmgt.min_damage + dmgt.min_damage * 0.3), math.round(dmgt.max_damage + dmgt.max_damage * 0.3), self )
            --     end
            --     if target == self.owner then
            --         dmgt:ModifyDamage( math.round(dmgt.min_damage + dmgt.min_damage * 0.3), math.round(dmgt.max_damage + dmgt.max_damage * 0.3), self )
            --     end
            -- end,
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

            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card.owner == self.owner and card:IsAttackCard() then
                    dmgt:ModifyDamage( math.round(dmgt.min_damage + dmgt.min_damage * 0.3), math.round(dmgt.max_damage + dmgt.max_damage * 0.3), self )
                end
                if target == self.owner then
                    dmgt:ModifyDamage( math.round(dmgt.min_damage + dmgt.min_damage * 0.3), math.round(dmgt.max_damage + dmgt.max_damage * 0.3), self )
                end
            end,

            [ BATTLE_EVENT.CALC_MODIFY_STACKS ] = function( self, acc, condition_id, fighter, source )
                if condition_id == "DEFEND" and fighter == self.owner then
                    if acc.value > 0 then
                        acc:AddValue( -math.floor( acc.value / 2 ), self )
                    end
                end
            end,
        }
    },

    equip_flail = 
    {
        name = "Kashio's Flail",
        -- desc = "Gain {DEFEND} equal to 5% of your current health and {DEFEND} then {HEAL} self for 10% of your missing health every turn. Also have a chance 25% chance to apply a random debuff to an enemy on hit.",
        desc = "Gain {DEFEND} for every 10 current health then {HEAL} self for 10% of your missing health every turn.", -- new description
        icon = "battle/conditions/spree_rage.tex",

        OnApply = function( self )
            if self.owner:HasCondition("equip_glaive") then
                self.owner:RemoveCondition("equip_glaive", 1, self)
                self.owner:RemoveCondition("NEXT_TURN_ACTION", 1, self)
            end
            -- self.owner:BroadcastEvent( BATTLE_EVENT.PLAY_ANIM, "taunt", false, true)
        end,

        max_stacks = 1,

        event_handlers = 
        {
            -- 25% chance to apply debuff to enemy // removed since flail gives too much as is and would be more of a defensive "weapon"
            -- [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
            --     local randomNum = math.random(1,4) -- 1 to 4
            --     local randomConNum = math.random(1,6) -- 1 to 6, kept crashing because arrays start at index 1  in lua
            --     local posConditions = {"BLEED", "IMPAIR", "BURN", "STUN", "WOUND", "EXPOSED"}
            --     if randomNum == 1 then
            --         if attack.attacker == self.owner and attack.card:IsAttackCard() then
            --                 if not hit.evaded then 
            --                     hit.target:AddCondition(posConditions[randomConNum], 1, self)
            --                 end
            --         end  
            --     end      
            -- end,

            [ BATTLE_EVENT.END_PLAYER_TURN ] = function (self, battle, attack)
                -- self.owner:AddCondition("DEFEND", math.round(self.owner:GetHealth() * 0.05), self)
                self.owner:AddCondition("DEFEND", math.round(self.owner:GetHealth() * 0.10), self) -- gains more defense due to less offensive capability and less confusing tooltip
                self.owner:HealHealth(math.round((self.owner:GetMaxHealth() - self.owner:GetHealth()) * 0.10), self)
            end,
        }
    },
}

for id, def in pairs( CONDITIONS ) do
    Content.AddBattleCondition( id, def )
end


-- local FEATURES =
-- {
--     equip_flail = 
--     {
--         name = "Kashio's Flail",
--         desc = "gain {DEFEND} equal to 5% of your current health and {DEFEND} then {HEAL} self for 10% of your missing health every turn. Also have a chance 25% chance to apply a random debuff to an enemy on hit.",
--     },
--     equip_glaive =
--     {
--         name="Kashio's Glaive",
--         desc = "Deal extra damage with your attacks and gain an extra action per turn at the cost of taking more damage and halving {DEFEND}.",
--     },
-- }

-- for id, data in pairs( FEATURES ) do
--     local def = BattleFeatureDef(id, data)
--     Content.AddBattleCardFeature(id, def)
--     CARD_FEATURES[id] = def
-- end


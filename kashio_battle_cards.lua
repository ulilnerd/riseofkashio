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
        min_damage = 3,
        max_damage = 5,
        anim = "crack",
        
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

    flail_slam = 
    {
        name = "Flail Slam",
        rarity = CARD_RARITY.BASIC,
        cost = 1,
        max_xp = 6,
        flags = CARD_FLAGS.MELEE,
        icon = "RISE:textures/flailslam.png",
        min_damage = 5,
        max_damage = 5,
        anim = "slam",
        desc = "Apply {IMPAIR {1}} and {WOUND {1}} then {WOUND {1}} self.",
        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition( "WOUND", 1 )
            for i, hit in attack:Hits() do
                local target = hit.target
                if not hit.evaded then 
                    target:AddCondition("IMPAIR", self.impair_per_bleed, self)
                    target:AddCondition("WOUND", self.wound_amount, self)
                end
            end
        end
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
        anim = "taunt",
        desc = "Equip {equip_flail} and gain {DEFEND} equal to 5% of your maximum health and current defend then {HEAL} self for 10% of your missing health every turn. Also have a chance a 25% chance to apply a random debuff to an enemy on hit.",
        icon = "battle/overloaded_spark_hammer.tex",

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
        anim = "transition1",
        desc = "Equip the Rentorian Force Glaive gaining {POWER} and an extra action every turn.",
        icon = "battle/rentorian_force_glaive.tex",

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
        desc = "Deal damage to all enemies equal to half the damage they will deal to you after your turn ends and gain {DEFEND} equal to that amount.",
        icon = "battle/hammer_swing.tex",

        flags = CARD_FLAGS.SKILL,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_mod = TARGET_MOD.TEAM,
        min_damage = 0,
        max_damage = 0,

        OnPostResolve = function( self, battle, attack )
            for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                if enemy.prepared_cards then
                    for i, card in ipairs( enemy.prepared_cards ) do
                        if card:IsAttackCard() then
                            self.owner:AddCondition("DEFEND", math.round(card.min_damage / 2), self)
                        end
                    end
                end
            end
        end,

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                local count = 0
                if card == self then
                for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                    if enemy.prepared_cards then
                        for i, card in ipairs( enemy.prepared_cards ) do
                            if card:IsAttackCard() then
                                count = count + card.min_damage
                            end
                        end
                    end
                end
                dmgt:AddDamage( math.round(count / 2), math.round(count / 2), self )
                end
            end,
        }

    },

    afterburner_gloves =
    {
        name = "Afterburner Gloves", -- apply Afterburner Gloves to self
        anim = "taunt4",
        desc = "Apply {BURN} to all enemies, Gain {1} {DEFEND} per {BURN} on enemy.", -- AfterBurner Gloves: all of your attacks apply 1 burn to enemy and yourself, gain defense if kashio's flail is active depending on burn count
        icon = "battle/workers_gloves.tex",

        flags = CARD_FLAGS.RANGED,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        max_xp = 6,
        target_mod = TARGET_MOD.TEAM,
        defend_amount = 1,
        burn_amount = 1,

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateDefendText( self.defend_amount ))
        end,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                if not attack:CheckHitResult( hit.target, "evaded" ) then
                    hit.target:AddCondition("BURN", 1)
                    self.defend_amount = self.defend_amount + hit.target:GetConditionStacks("BURN")
                end
            end
            self.owner:AddCondition("DEFEND", self.defend_amount, self)
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
        rarity = CARD_RARITY.UNCOMMON,
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
        desc = "This card costs 0 if you have the {equip_glaive} equipped.",
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
        desc = "Damage a random enemy and gain {1} {EXPOSED}.",
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

    the_bigger_they_are = 
    {
        name = "The Bigger They are...",
        anim = "spin_attack",
        desc = "Deals damage equal to 15% of the target's current health.",
        icon = "RISE:textures/thebiggertheyare.png",

        flags = CARD_FLAGS.MELEE,
        cost = 1,
        rarity = CARD_RARITY.COMMON,
        max_xp = 6,

        min_damage = 0,
        max_damage = 0,
        
        event_handlers =
        {
            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card == self and target then
                    local bonus = math.floor( target:GetHealth() * 0.15 )
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
        end
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

        OnPostResolve = function( self, battle, attack, card )
            for i, condition in pairs(self.owner:GetConditions()) do
                if condition.ctype == CTYPE.DEBUFF then
                    self.owner:AddCondition("POWER", condition:GetStacks(), self)
                    self.owner:DeltaHealth(-condition:GetStacks())
                    self.owner:RemoveCondition(condition:GetID(), condition:GetStacks())
                end
            end
        end,
        -- event_handlers =
        -- {
        --     [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle, attack, card )
        --         for i, condition in pairs(self.owner:GetConditions()) do
        --             if condition.ctype == CTYPE.DEBUFF then
        --                 self.owner:RemoveCondition(condition:GetID(), condition:GetStacks(), self)
        --             end
        --         end
        --     end,
        -- }
        
    }

    -- force_field = 
    -- {
    --     name = "Rentorian Force Field",
    --     anim = "taunt",
    --     desc = "Gain a shield that will shield you from all damage as long as the damage is below the threshhold, if above the threshhold, remove 1 stack, at 1 stack and stack is removed take normal damage
    --     if {equip_glaive} is active, gain 3 stacks of Rentorian Force Field.",
    --     icon = "battle/improvise_chug.tex",

    --     flags =  CARD_FLAGS.SKILL,
    --     cost = 2,
    --     rarity = CARD_RARITY.UNCOMMON,
    --     max_xp = 4,
    --     target_type = TARGET_TYPE.SELF,
    -- },

    -- fake_surrender = 
    -- {
    --     name = "Plead Guilty",
    --     anim = "surrender",
    --     desc = "Have a small chance of gaining -Pleaded for life- for 1 turn, stopping enemies from attacking you and lowering their guard dealing more damage to them with attack cards.",
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
    --     desc = "if an enemy is not preparing an attack card on to you, they will be forced to attack you this turn then gain a random buff depending on attackers.",
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
    scaling_defense = 
    {
        name = "Strength of One Thousand",
        desc = "Gain {ARMOURED} every turn.",
        icon = "battle/conditions/active_shield_generator.tex",

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
        desc = "Gain {POWER} and an extra action per turn at the cost of gaining {EXPOSED} and {WOUND}.",
        icon = "battle/conditions/kashio_glaive.tex",

        max_stacks = 1,

        OnApply = function( self )
            if self.owner:HasCondition("equip_flail") then
                self.owner:RemoveCondition("equip_flail", 1, self)
            end
            self.owner:AddCondition("EXPOSED", 1, self)
            self.owner:AddCondition("WOUND", 1, self)
            self.owner:AddCondition("NEXT_TURN_ACTION", 1, self)
        end,


        event_handlers = 
        {
            [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function (self, battle, fighter)
                self.owner:AddCondition("EXPOSED", 1, self)
                self.owner:AddCondition("WOUND", 1, self)
                self.owner:AddCondition("NEXT_TURN_ACTION", 1, self)
            end,

            [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                if card.owner == self.owner and card:IsAttackCard() then
                    dmgt:ModifyDamage( dmgt.min_damage + 2, dmgt.max_damage + 2, self )
                end
            end,
        }
    },

    equip_flail = 
    {
        name = "Kashio's Flail",
        desc = "gain {DEFEND} equal to 5% of your current health and {DEFEND} then {HEAL} self for 10% of your missing health every turn. Also have a chance 25% chance to apply a random debuff to an enemy on hit.",
        icon = "battle/conditions/spree_rage.tex",

        OnApply = function( self )
            if self.owner:HasCondition("equip_glaive") then
                self.owner:RemoveCondition("equip_glaive", 1, self)
            end
        end,

        max_stacks = 1,

        event_handlers = 
        {
            [ BATTLE_EVENT.END_PLAYER_TURN ] = function (self, battle, attack)
                self.owner:AddCondition("DEFEND", math.round(self.owner:GetConditionStacks("DEFEND") * 0.05 + self.owner:GetHealth() * 0.05) , self)
                self.owner:HealHealth(math.round((self.owner:GetMaxHealth() - self.owner:GetHealth()) * 0.10), self)
            end,

            -- 25% chance to apply debuff to enemy
            -- [ BATTLE_EVENT.POST_RESOLVE ] = function( self, card, attack )
            --     local randomNum = math.floor(math.random() * 2) -- 0 to 1
            --     local randomChance = math.floor(math.random() * 1 + 1) -- 1 or 2
            --     local randomConNum = math.floor(math.random() * 7) -- 0 to 6
            --     local posConditions = {"BLEED", "IMPAIR", "BURN", "STUN", "STAGGER", "WOUND", "EXPOSED"}
            --     for i, hit in attack:Hits() do
            --         if hit.target ~= self then
            --             if randomNum == 1 then
            --                 hit.target:AddCondition(posConditions[randomConNum], randomChance)
            --             end
            --         end
            --     end        
            -- end,
        }
    },
}


for id, def in pairs( CONDITIONS ) do
    Content.AddBattleCondition( id, def )
end


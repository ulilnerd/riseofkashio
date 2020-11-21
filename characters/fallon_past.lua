local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local def = CharacterDef("FALLON_PAST",
    {
        name = "Dal Fallon",
        base_def = "NPC_BASE",
        alias = "FALLON_PAST",
        id = "FALLON_PAST",

        combat_anims = {"anim/med_combat_rentorian.zip" },
        anims = {"anim/weapon_double_bladed_staff_rentorian.zip"},

        head = "head_male_hesh_luminiciate",
        build = "male_rise_promoted_build",
        
        hair_colour = 0xCB5D3Cff,
        skin_colour = 0xd2a18cff,
        species = "HUMAN",
        unique = true,
        boss = true,
        gender = GENDER.MALE,
    

        fight_data = 
        {
            MAX_HEALTH = 180,
            formation = FIGHTER_FORMATION.FRONT_Z,
            actions = 1,

            conditions = 
            {
                FALLON_GLAIVE = 
                {
                    name = "Fallon's Force Glaive",
                    desc = "Everytime Fallon switches to his Force Glaive, he gains {DEFEND}. Additionally, if he ends his turn while {FALLON_GLAIVE} is active, he gains {DEFEND} equal to 2% of his current health and heals health equal 2% of his missing health.",
                    icon = "battle/conditions/spree_rage.tex",
            
                    max_stacks = 1,
            
                    OnApply = function( self )
                        if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                            self.owner:RemoveCondition("FALLON_DUAL_BLADES", 1, self)
                        end
                        -- swapping to glaive instantly grants defend and heals fallon
                        self.owner:AddCondition("DEFEND", 2, self)
                        self.owner:HealHealth(2, self)
                    end,

                    event_handlers = 
                    {
                        -- defense and healing every turn
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function (self, battle, attack)
                            self.owner:AddCondition("DEFEND", 5 ,self)
                            -- self.owner:HealHealth(math.round((self.owner:GetMaxHealth() - self.owner:GetHealth()) * 0.05), self)
                        end,
                    }
                },
                FALLON_DUAL_BLADES = 
                {
                    name = "Fallon's Dual Blades",
                    desc = "While {FALLON_DUAL_BLADES} is active, Fallon deals increased damage and has a chance to use attacks from a special pool of cards.",
                    icon = "battle/conditions/kashio_glaive.tex",
            
                    max_stacks = 1,
            
                    OnApply = function( self, card )
                        if self.owner:HasCondition("FALLON_GLAIVE") then
                            self.owner:RemoveCondition("FALLON_GLAIVE", 1, self)
                        end
                        self.owner:AddCondition("POWER", 2 ,self)
                    end,
                },
                FALLON = -- condition is used to track weapon swaps, show useful user information/tooltips and store various variables (some conditions dependant on this, yeah i know it's bad)
                {
                    name = "Fallon's Fury",
                    desc = "Fallon is an experienced fighter that showers you with a flurry of attacks every round and deals massive damage, although he does not have much defensive capability as a downfall.\n\nDespite being an experienced fighter in combat, Fallon still suffers from fatigue.\n\nEverytime you attack Fallon, you will deal bonus damage equal to how many actions he has made last turn.",
                    icon = "battle/conditions/brutality.tex",
                    max_stacks = 1,
                    -- hidden = true,

                    baitSwitch = false,
                    glaiveEquipped = 0,
                    dualBladesEquipped = 0,
                    weaponSwapped = false,
                    actionsMade = 0,
                    bonusDamageDealt = false,
                    
                    OnApply = function( self )
                        if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                            self.dualBladesEquipped = 1
                        end
                        if self.owner:HasCondition("FALLON_GLAIVE") then
                            self.glaiveEquipped = 1
                        end
                    end,

                    event_handlers = 
                    {
                        [ BATTLE_EVENT.CARD_MOVED ] = function( self, battle, attack, hit )
                            if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                                self.dualBladesEquipped = 1
                            end
                            if self.owner:HasCondition("FALLON_GLAIVE") then
                                self.glaiveEquipped = 1
                            end
                            if self.weaponSwapped == true then
                                self.dualBladesEquipped = 0
                                self.glaiveEquipped = 0
                                self.weaponSwapped = false
                            end
                        end,
                        [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit, target )
                            if attack.attacker == self.owner and attack.card:IsAttackCard() and not hit.evaded then
                                if self.owner:HasCondition("POWER") then
                                    self.owner:RemoveCondition("POWER", 1, self)
                                end
                                self.actionsMade = self.actionsMade + 1
                            end
                            if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                                self.bonusDamageDealt = true
                                self.actionsMade = 0
                            end
                        end,
                        [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                            if target == self.owner and self.bonusDamageDealt == false then
                                dmgt:AddDamage(self.actionsMade, self.actionsMade, self)
                            end
                        end,
                        [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle, attack, hit )
                            self.bonusDamageDealt = false
                        end
                    }
                },
                FALLON_EXTREME_FOCUS = 
                {
                    name = "Extreme Focus",
                    desc = "While this condition is active, Fallon hits you an additional time.",
                    icon = "battle/conditions/focus.tex",   

                    event_handlers = 
                    {
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, card, battle )
                            if self.owner:HasCondition("FALLON_EXTREME_FOCUS") then
                                self.owner:RemoveCondition("FALLON_EXTREME_FOCUS", 1, self)
                            end
                        end,
                    }
                },
                FALLON_BLADE_DANCE = 
                {
                    name = "Blade Dance",
                    desc = "Every 3 attacks, Fallon gains {EVASION}.",
                    icon = "battle/conditions/sharpened_blades.tex",  

                    evasionCount = 0,

                    event_handlers = 
                    {
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, card, battle )
                            if self.owner:HasCondition("FALLON_BLADE_DANCE") then
                                self.owner:RemoveCondition("FALLON_BLADE_DANCE", 1, self)
                            end
                        end,
                        [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit, target )
                            if attack.attacker == self.owner and attack.card:IsAttackCard() and not hit.evaded then
                                self.evasionCount = self.evasionCount + 1
                                if self.evasionCount >= 3 then
                                    self.owner:AddCondition("EVASION", 1, self)
                                    self.evasionCount = 0
                                end
                            end
                        end,
                    }
                },
                FALLON_WEAPON_PROFICIENCY = 
                {
                    name = "Weapon Swap Proficiency",
                    desc = "Everytime Fallon swaps weapons, he gains 3 random buffs.",
                    icon = "battle/conditions/steady_hands.tex",  

                    buff_amount = 2,

                    event_handlers = 
                    {
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, card, battle )
                            if self.owner:HasCondition("FALLON_WEAPON_PROFICIENCY") then
                                self.owner:RemoveCondition("FALLON_WEAPON_PROFICIENCY", 1, self)
                            end
                        end,
                        [ BATTLE_EVENT.POST_RESOLVE ] = function( self, battle, attack, hit, fighter )
                            if fighter == self then
                                if self.owner:GetCondition("FALLON").glaiveEquipped == 1 and self.owner:GetCondition("FALLON").dualBladesEquipped == 1 then
                                    local posConditions = {"POWER", "ARMOURED", "RIPOSTE", "EVASION", "DEFEND"}
                                    local randomCon = math.random(1,5)
                                    if randomCon == 5 then
                                        self.buff_amount = 5
                                    end
                                    self.owner:AddCondition(posConditions[randomCon], self.buff_amount , self)
                                    self.owner:GetCondition("FALLON").weaponSwapped = true
                                end
                            end
                        end
                    }
                },
                FALLON_FORCE_FIELD = 
                {
                    name = "Fallon's Force Field",
                    desc = "Everytime Fallon is attacked, if the damage dealt to him is lower or equal to the threshold, Fallon heals equal to the damage dealt. The threshold is equal to Fallon's Force Field stacks.",
                    icon = "battle/conditions/active_shield_generator.tex",

                    threshold =  0,

                    OnApply = function( self )
                        self.threshold = self.owner:GetConditionStacks("FALLON_FORCE_FIELD")
                    end,

                    event_handlers = 
                    {
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, card, battle )
                            if self.owner:HasCondition("FALLON_FORCE_FIELD") then
                                self.threshold = self.owner:GetConditionStacks("FALLON_FORCE_FIELD")
                                self.owner:RemoveCondition("FALLON_FORCE_FIELD", 1, self)
                            end
                        end,
                        [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit, target )
                            if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                                if hit.damage <= self.threshold and not self.owner:HasCondition("DEFEND") then
                                    self.owner:HealHealth(hit.damage, attack.attacker)
                                end
                            end
                        end,
                    }
                },
                FALLON_MASSACRE = 
                {
                    name = "Massacre",
                    desc = "Every 3 attacks, Fallon gains {POWER}.",
                    icon = "battle/conditions/concentration.tex",  

                    hitCount = 0,

                    event_handlers = 
                    {
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, card, battle )
                            if self.owner:HasCondition("FALLON_MASSACRE") then
                                self.owner:RemoveCondition("FALLON_MASSACRE", 1, self)
                            end
                        end,
                        [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit, target )
                            if attack.attacker == self.owner and attack.card:IsAttackCard() and not hit.evaded then
                                self.hitCount = self.hitCount + 1
                                if self.hitCount >= 3 then
                                    self.owner:AddCondition("POWER", 1, self)
                                    self.hitCount = 0
                                end
                            end
                        end,
                    }
                },
            },

            attacks = 
            {
               fallon_equip_glaive = table.extend(NPC_BUFF)
                {
                    name = "Equip Glaive", 
                    anim = "transition2",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    PostPresAnim = function( self, anim_fighter )
                        anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_glaive)
                    end,

                    OnPostResolve = function( self, battle, attack)
                        if self.owner:HasCondition("FALLON_GLAIVE") then
                            self.owner:AddCondition("DEFEND", 5, self)
                        end
                        self.owner:AddCondition("FALLON_GLAIVE", 1, self)
                    end
                },
                fallon_equip_dualblades = table.extend(NPC_BUFF)
                {
                    name = "Equip Dual Blades", 
                    anim = "transition1",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    PostPresAnim = function( self, anim_fighter )
                        anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_dualblades)
                    end,

                    OnPostResolve = function( self, battle, attack)
                        
                        self.owner:AddCondition("FALLON_DUAL_BLADES", 1, self)
                    end
                },
                fallon_bait_and_switch = table.extend(NPC_MELEE)
                {
                    name = "Bait and Switch", -- attack then if using glaive, switch to dual blades. If dual blades is already active, attack again
                    anim = "attack2",
        
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 3,
                    
                    PostPresAnim = function( self, anim_fighter )
                        anim_fighter:SetAnimMapping(self.owner.agent.fight_data.anim_mapping_dualblades)
                    end,

                    OnPostResolve = function( self, battle, attack)
                        if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                            self.owner:GetCondition("FALLON").baitSwitch = true
                        end
                        -- self.owner:AddCondition("FALLON_DUAL_BLADES", 1, self)
                    end,
                },
                fallon_exposeaid = table.extend(NPC_MELEE)
                {
                    name = "Exposeaid", -- gain shatter for one turn if you have glaive equipped
                    anim = "attack1",
        
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 4,
                    
                    OnPostResolve = function( self, battle, attack)
                        if self.owner:HasCondition("FALLON_GLAIVE") then
                            self.owner:AddCondition("SHATTER", 1, self)
                            self.owner:AddCondition("TEMP_SHATTER", 1, self)
                        end
                    end,
                },
                fallon_excel_pressure = table.extend(NPC_MELEE)
                {
                    name = "Excel Under Pressure", -- deal 1 bonus damage for every enemy, then gain invicible if you have dual blades equipped
                    anim = "attack1",
        
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 4,
                    
                    -- OnPostResolve = function( self, battle, attack)
                    --     if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                    --         self.owner:AddCondition("FSSH_INVINCIBLE", 1, self)
                    --     end
                    -- end,
                    event_handlers = 
                    {
                        [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                            if card == self then
                                local enemyCount = 0
                                for i, enemy in self.owner:GetEnemyTeam():Fighters() do
                                    enemyCount = enemyCount + 1
                                end
                                dmgt:AddDamage(enemyCount,enemyCount,self)
                            end
                        end,
                    }
                },
                fallon_extreme_focus = table.extend(NPC_MELEE)
                {
                    name = "Extreme Focus", -- deal damage then gain a condition that will allow fallon to swap weapons an additional time 
                    anim = "attack_dual",
        
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 6,
                    
                    OnPostResolve = function( self, battle, attack)
                        self.owner:AddCondition("FALLON_EXTREME_FOCUS", 2, self)
                    end,
                },
                fallon_nice_knowin_ya = table.extend(NPC_MELEE)
                {
                    name = "Nice Knowin Ya", -- have a chance to deal double damage for this attack
                    anim = "attack_dual",
        
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 4,
                    
                    event_handlers =
                    {
                        [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                            local damageChance = math.random(1,2)
                            if card == self then
                                if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                                    if damageChance == 2 then
                                        dmgt:ModifyDamage( dmgt.min_damage + 1, dmgt.max_damage + 3 , self ) -- double damage
                                    end
                                end
                            end
                        end,
                    },
                },
                fallon_grand_slam = table.extend(NPC_MELEE)
                {
                    name = "Grand Slam", -- deals damage to all enemies, applies wound to all enemies if glaive equipped
                    anim = "attack2",
                    pre_anim = "taunt",
                    flags = CARD_FLAGS.MELEE,
                    base_damage = 5,
                    target_mod = TARGET_MOD.TEAM,

                    OnPostResolve = function( self, battle, attack)
                        if self.owner:HasCondition("FALLON_GLAIVE") then
                            for i, hit in attack:Hits() do
                                local target = hit.target
                                if not hit.evaded then
                                    target:AddCondition("WOUND", 2)
                                end
                            end
                        end
                    end
                },
                fallon_infinity_blade = table.extend(NPC_MELEE)
                {
                    name = "Infinity Blade", -- deals damage then enemy gains DEFECT if dual blades active
                    anim = "attack1",
                    pre_anim = "taunt",
                    flags = CARD_FLAGS.MELEE,
                    base_damage = 7,

                    OnPostResolve = function( self, battle, attack)
                        if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                            for i, hit in attack:Hits() do
                                local target = hit.target
                                if not hit.evaded then
                                    target:AddCondition("DEFECT", 1)
                                end
                            end
                        end
                    end
                },
                fallon_flurry_dagger = table.extend(NPC_MELEE)
                {
                    name = "Flurry Dagger", -- deals light damage, 5 used when flurry is active
                    anim = "attack2_dual",
        
                    flags = CARD_FLAGS.MELEE,
                    hit_count = 5,
                    hit_anim = true,
                    base_damage = 1,
                },
                fallon_flurry = table.extend(NPC_BUFF)
                {
                    name = "Flurry", -- gains kashio's flurry and 5 flurry daggers
                    anim = "taunt2",
        
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:AddCondition("FLURRY", 1, self)
                    end
                },
                fallon_blade_dance = table.extend(NPC_BUFF)
                {
                    name = "Blade Dance", -- after 3 attacks, fallon gains evasion
                    anim = "taunt",
        
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:AddCondition("FALLON_BLADE_DANCE", 3, self)
                    end
                },
                fallon_weapon_proficiency = table.extend(NPC_BUFF)
                {
                    name = "Weapon Swap Proficiency", -- gains buffs everytime fallon swaps weapons
                    anim = "taunt2",
        
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:AddCondition("FALLON_WEAPON_PROFICIENCY", 3, self)
                    end
                },
                fallon_force_field = table.extend(NPC_BUFF)
                {
                    name = "Fallon's Force Field", -- if an enemy attacks fallon with this condition, and the damage is lower than the threshold, fallon gains health equal to the damage
                    anim = "taunt",
        
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:AddCondition("FALLON_FORCE_FIELD", 3, self)
                    end
                },
                fallon_massacre = table.extend(NPC_MELEE)
                {
                    name = "Massacre", -- deals damage then gain massacre; fallon gains power every turn as long as massacre is active
                    anim = "attack_dual",
                    pre_anim = "taunt",
                    post_anim = "taunt2",
                    flags = CARD_FLAGS.MELEE,
                    base_damage = 6,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:AddCondition("FALLON_MASSACRE", 2, self)
                    end
                },
            },

            behaviour =
            {
                OnActivate = function( self, fighter)
                    self.fighter:AddCondition("FALLON", 1, self)
                    self.fighter:AddCondition("FALLON_GLAIVE",1,self)
                    self.basicCards = self:MakePicker()
                        :AddID( "fallon_bait_and_switch", 2)
                        :AddID( "fallon_exposeaid", 2)
                        :AddID( "fallon_excel_pressure", 2)
                        :AddID( "fallon_extreme_focus", 2)
                        :AddID( "fallon_nice_knowin_ya", 2)
                    self.swapCards = self:MakePicker()
                        :AddID( "fallon_equip_glaive", 2)
                        :AddID( "fallon_equip_dualblades", 2)
                    self.advancedCards = self:MakePicker()
                        :AddID( "fallon_grand_slam", 2)
                        :AddID( "fallon_infinity_blade", 2)
                        :AddID( "fallon_massacre", 2)
                    self.buffCards = self:MakePicker()
                        :AddID( "fallon_flurry", 1)
                        :AddID( "fallon_blade_dance", 1)
                        :AddID( "fallon_weapon_proficiency", 1)
                        :AddID( "fallon_force_field", 1)
                    self.flurryCards = self:MakePicker()
                        :AddID( "fallon_flurry_dagger", 2)
                    self:SetPattern( self.Cycle )
                end,

                Cycle = function( self )
                    local randomAction = math.random(1,2)
                    local swaps = math.random(1,3)

                    -- hits you with 5 flurry daggers if fallon has flurry
                    if self.fighter:HasCondition("FLURRY") then
                        self.flurryCards:ChooseCards(1)
                    end

                    -- fallon gains an extra attack when extreme focus is active
                    if self.fighter:HasCondition("FALLON_EXTREME_FOCUS") then
                        swaps = swaps + 1
                    end
            
                    -- hits 1 to 3 times
                    if randomAction == 1 then
                        self.basicCards:ChooseCards(swaps)
                    elseif randomAction == 2 then
                        self.buffCards:ChooseCards(1)
                    end

                    -- extra attack with bait and switch
                    if self.fighter:HasCondition("FALLON") then
                        if self.fighter:GetCondition("FALLON").baitSwitch == true then
                            self.basicCards:ChooseCards(1)
                            self.fighter:GetCondition("FALLON").baitSwitch = false
                        end
                    end

                    -- fallon uses attacks from advanced attack pool 
                    if self.fighter:HasCondition("FALLON_DUAL_BLADES") then
                        self.advancedCards:ChooseCards(1)
                    end
                    
                    -- always swaps weapons after turn
                    self.swapCards:ChooseCards(1)
                end,
            },

            anim_mapping_dualblades =
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
                run_forward_pst_turn = "run_forward2_pst_turn",
                step_back = "step_back2",
                step_forward = "step_forward2",
                stunned = "stunned2",
                stunned_pre = "stunned2_pre",
                stunned_pst = "stunned2_pst",
                surrender_pre = "surrender2_pre",
                surrender_pst = "surrender2_pst",
                surrender = "surrender2",
                riposte = "attack_dual",
            },
            anim_mapping_glaive =
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
                riposte = "attack1",
            },
        }
    })
    def:InheritBaseDef()
    Content.AddCharacterDef( def )
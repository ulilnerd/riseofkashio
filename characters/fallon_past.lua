local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local def = CharacterDef("FALLON_PAST",
    {
        name = "Fallon",
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
            MAX_HEALTH = 150,
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
                    momentum = 0,
            
                    OnApply = function( self )
                        if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                            self.owner:RemoveCondition("FALLON_DUAL_BLADES", 1, self)
                        end
                    end,

                    event_handlers = 
                    {
                        -- defense and healing every turn
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function (self, battle, attack)
                            self.owner:AddCondition("DEFEND", math.round(self.owner:GetHealth() * 0.02), self)
                            self.owner:HealHealth(math.round((self.owner:GetMaxHealth() - self.owner:GetHealth()) * 0.02), self)
                        end,
                    }
                },
                FALLON_DUAL_BLADES = 
                {
                    name = "Fallon's Dual Blades",
                    desc = "While {FALLON_DUAL_BLADES} is active, Fallon deals increased damage and has a chance to use attacks from a special pool of cards, at the cost of halving {DEFEND}.",
                    icon = "battle/conditions/kashio_glaive.tex",
            
                    max_stacks = 1,
            
                    OnApply = function( self, card )
                        if self.owner:HasCondition("FALLON_GLAIVE") then
                            self.owner:RemoveCondition("FALLON_GLAIVE", 1, self)
                        end
                    end,

                    event_handlers = 
                    {
                        -- take roughly 30% more damage and deal 30% more damage
                        [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                            if card.owner == self.owner and card:IsAttackCard() then
                                dmgt:ModifyDamage( math.round(dmgt.min_damage + (dmgt.min_damage * 0.30)), math.round(dmgt.max_damage + (dmgt.max_damage * 0.30)), self )
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
                    }
                },
                FALLON = 
                {
                    name = "Fallon",
                    desc = "This is Fallon, condition is used to track weapon swaps and other various variables.",
                    -- icon = "battle/conditions/kashio_glaive.tex",
                    max_stacks = 1,
                    hidden = true,

                    baitSwitch = false,
                    powerGained = false,
                    powerCount = 0,

                    event_handlers = 
                    {
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, battle, attack)
                            if self.powerGained == true then
                                self.powerCount = self.powerCount + 1
                            end
                            if self.powerCount == 2 then
                                if self.owner:HasCondition("POWER") then
                                    self.owner:RemoveCondition("POWER", 1, self)
                                    self.powerGained = 0
                                end
                            end
                        end
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
                            self.owner:AddCondition("DEFEND", 7, self)
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
                        if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                            self.owner:AddCondition("POWER", 1 ,self)
                            self.owner:GetCondition("FALLON").powerGained = true
                        end
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
                        self.owner:AddCondition("FALLON_DUAL_BLADES", 1, self)
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
                    
                    OnPostResolve = function( self, battle, attack)
                        if self.owner:HasCondition("FALLON_DUAL_BLADES") then
                            -- self.owner:AddCondition("FSSH_INVINCIBLE", 1, self)
                        end
                    end,
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
                    self.swapCards = self:MakePicker()
                        :AddID( "fallon_equip_glaive", 1)
                        :AddID( "fallon_equip_dualblades", 1)
                    self:SetPattern( self.Cycle )
                    self.glaive = self:AddCard( "fallon_equip_glaive" )
                    self.dualblades = self:AddCard( "fallon_equip_dualblades" )
                    self.underPressure = self:AddCard( "fallon_excel_pressure" )
                end,

                Cycle = function( self )
                    local swaps = math.random(1,4)
                    self.basicCards:ChooseCards(swaps)
                    if self.fighter:HasCondition("FALLON") then
                        if self.fighter:GetCondition("FALLON").baitSwitch == true then
                            self:ChooseCard( self.underPressure )
                            self.fighter:GetCondition("FALLON").baitSwitch = false
                        end
                    end
                    -- if self.fighter:HasCondition("FALLON_GLAIVE") then
                    --     self:ChooseCard( self.dualblades )
                    -- elseif self.fighter:HasCondition("FALLON_DUAL_BLADES") then
                    --     self:ChooseCard( self.glaive )
                    -- end
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
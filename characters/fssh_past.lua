local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local def = CharacterDef("FSSH_PAST",
    {
        name = "Fssh Menewene",
        -- title = "Dag n'Gurr",
        base_def = "NPC_BASE",
        alias = "FSSH_PAST",
        id = "FSSH_PAST",

        anims = { "anim/weapon_knife_guard_lumin.zip","anim/weapon_blaster_sal.zip", "anim/med_dial_sal.zip"},
        combat_anims = { "anim/med_combat_sal.zip" },

        head = "head_fssh",
        build = "guard_female_offduty",
        skin_colour = 1956283903,
        hair_colour = 2775271167,
        species = "KRADESHI",
        unique = true,
    

        fight_data = 
        {
            MAX_HEALTH = 120,
            formation = FIGHTER_FORMATION.FRONT_Z,
            actions = 1,

            conditions = 
            {
                FINAL_EFFORT =
                {
                    name = "Final Effort",
                    desc = "Fssh gains a stack of {FINAL_EFFORT} everytime a fighter makes an action, every 10 stacks she will gain a buff.",
                    icon = "battle/conditions/burr_boss_enrage.tex",

                    slicerDicerUsed = false,
                    petCalled = false,

                    -- OnApply = function( self, battle )
                    --     self.owner:AddCondition("FSSH_UNBREAKABLE", 1, self)
                    -- end,

                    event_handlers =
                    {
                        [ BATTLE_EVENT.POST_RESOLVE ] = function( self, battle, attack)
                            self.owner:AddCondition("FINAL_EFFORT", 1, self)
                            if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                                self.owner:AddCondition("FSSH_BETRAYED", 1, self)
                            end
                            if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                                self.owner:AddCondition("FSSH_UNBREAKABLE", 1, self)
                            end
                        end,
                    },
                },
                FSSH_UNBREAKABLE = 
                {
                    name = "Unbreakable",
                    desc = "Everytime Fssh gets hit, she gains 2 Defend.",
                    icon = "battle/conditions/barbed_defense.tex",
            
                    max_stacks = 1,
                    event_handlers = 
                    {
                        [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                            if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                                self.owner:AddCondition("DEFEND", 2, self)
                            end
                        end,
                    }
                },
                FSSH_BETRAYED = 
                {
                    name = "Betrayed",
                    desc = "All of Fssh's basic attacks are enhanced, applying a variety of effects.",
                    -- icon = "battle/conditions/barbed_defense.tex",
                    max_stacks = 1,
                },
            },

            attacks = 
            {
                fssh_readied_assault = table.extend(NPC_MELEE)
                {
                    name = "Readied Assault",
                    anim = "slash",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 6,
                    OnPostResolve = function( self, battle, attack)
                        if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                            self.owner:AddCondition("DEFEND", 6, self)
                        end
                    end
                },
                fssh_slice_and_dice = table.extend(NPC_MELEE)
                {
                    name = "Slice and Dice",
                    anim = "attack2",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 3,
                    OnPostResolve = function( self, battle, attack)
                        if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                            self.owner:AddCondition(self.id)
                        end
                    end,

                    condition = 
                    {
                        hidden = true,
                        max_stacks = 1,
                        event_handlers =
                        {
                            [ BATTLE_EVENT.END_TURN ] = function( self, battle, fighter )
                                if self.owner:HasCondition(self.id) then
                                    if self.owner:GetCondition("FINAL_EFFORT").slicerDicerUsed == true then
                                        self.owner:RemoveCondition(self.id)
                                        self.owner:GetCondition("FINAL_EFFORT").slicerDicerUsed = false
                                    end
                                end
                            end,
                        }
                    }
                },
                fssh_slicer = table.extend(NPC_MELEE)
                {
                    name = "Slicer",
                    anim = "bladeflash",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 3,
                },
                fssh_dicer = table.extend(NPC_MELEE)
                {
                    name = "Dicer",
                    anim = "bladefury",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 5,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:GetCondition("FINAL_EFFORT").slicerDicerUsed = true
                    end
                },
                fssh_crippling_slice = table.extend(NPC_MELEE)
                {
                    name = "Crippling Slice",
                    anim = "double_stab",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 4,
                    OnPostResolve = function( self, battle, attack)
                        if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                            for i, hit in attack:Hits() do
                                local target = hit.target
                                if not hit.evaded then
                                    target:AddCondition("IMPAIR", 1)
                                end
                            end
                        end
                    end
                },
                fssh_taste_of_blood = table.extend(NPC_MELEE)
                {
                    name = "Taste of Blood",
                    anim = "attack1",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 3,
                    OnPostResolve = function( self, battle, attack)
                        if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                            for i, hit in attack:Hits() do
                                local target = hit.target
                                if not hit.evaded then
                                    target:AddCondition("BLEED", 6)
                                end
                            end
                        else
                            for i, hit in attack:Hits() do
                                local target = hit.target
                                if not hit.evaded then
                                    target:AddCondition("BLEED", 3)
                                end
                            end
                        end
                    end
                },
                fssh_it_wasnt_me = table.extend(NPC_MELEE)
                {
                    name = "It Wasn't Me!!",
                    anim = "hiltbash",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 3,
                    OnPostResolve = function( self, battle, attack)
                        if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                            self.owner:AddCondition("EVASION", 1, self)
                        end
                    end
                },
                fssh_call_crayote = table.extend(NPC_BUFF)
                {
                    name = "Call Crayote",
                    anim = "taunt2",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,

                    OnPostResolve = function( self, battle, attack)
                        local summon = Agent( "CRAYOTE_UPGRADED" )
                        local fighter = Fighter.CreateFromAgent( summon, battle:GetScenario():GetAllyScale() )
                        self.owner:GetTeam():AddFighter( fighter )
                        self.owner:GetTeam():ActivateNewFighters()
                    end
                },
            },

            behaviour =
            {
                OnActivate = function( self, fighter)
                    self.fighter:AddCondition("FINAL_EFFORT")
                    self.sliceCards = self:MakePicker()
                        :AddID( "fssh_readied_assault", 1)
                        :AddID( "fssh_slice_and_dice", 1)
                        :AddID( "fssh_crippling_slice", 1)
                        :AddID( "fssh_taste_of_blood", 1)
                        :AddID( "fssh_it_wasnt_me", 1)
                        self:SetPattern( self.Cycle )
                        self.slicer = self:AddCard( "fssh_slicer" )
                        self.dicer = self:AddCard( "fssh_dicer" )
                        self.crayote = self:AddCard( "fssh_call_crayote" )
                end,

                Cycle = function( self )
                    local randomCards = math.random(1,2)
                    if self.fighter:GetConditionStacks("FINAL_EFFORT") >= 10 then
                        local randomNum = math.random(1,4)
                        if self.fighter:GetTeam():NumActiveFighters() < 2 and randomNum == 4 then
                            self:ChooseCard( self.crayote )
                        end
                    end
                    if randomCards == 1 then
                        self.sliceCards:ChooseCards(2)
                        if self.fighter:HasCondition("fssh_slice_and_dice") then
                            self:ChooseCard( self.slicer )
                            self:ChooseCard( self.dicer )
                        end
                    elseif randomCards == 2  then
                        self.fighter:AddCondition("DEFEND", 10)
                        self.fighter:AddCondition("POWER", 1)
                        self.fighter:AddCondition("POWER_LOSS", 1)
                    end
                end,
            }
        }
    })
    def:InheritBaseDef()
    Content.AddCharacterDef( def )
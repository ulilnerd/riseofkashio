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
        species = "HUMAN",
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
                    ctype = CTYPE.DEBUFF,

                    slicerDicerUsed = false,
                    petCalled = false,
                    powerGained = false,

                    -- OnApply = function( self, battle )
                    --     self.owner:AddCondition("FSSH_UNBREAKABLE", 1, self)
                    -- end,

                    -- 10 stacks: all basic attacks gain various debuffs
                    -- 20 stacks: have a chance to spawn an upgraded crayote
                    -- 30 stacks: gain 2 defend per hit from you

                    event_handlers =
                    {
                        [ BATTLE_EVENT.POST_RESOLVE ] = function( self, battle, attack)
                            self.owner:AddCondition("FINAL_EFFORT", 1, self)
                            -- 10 stacks: all basic attacks gain various debuffs
                            if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                                self.owner:AddCondition("FSSH_BETRAYED", 1, self)
                            end
                            -- 20 stacks: gain 2 defend per hit from you
                            if self.owner:GetConditionStacks("FINAL_EFFORT") >= 30 then
                                self.owner:AddCondition("FSSH_UNBREAKABLE", 1, self)
                            end
                            if self.powerGained == true then
                                if self.owner:HasCondition("POWER") then
                                    self.owner:RemoveCondition("POWER", 1, self)
                                end
                            end
                        end,
                    },
                },
                FSSH_UNBREAKABLE = 
                {
                    name = "Unbreakable",
                    desc = "Everytime Fssh gets hit, she gains 2 Defend.",
                    icon = "battle/conditions/barbed_defense.tex",
                    ctype = CTYPE.DEBUFF,
            
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
                    icon = "battle/conditions/annihilation.tex",
                    max_stacks = 1,
                    ctype = CTYPE.DEBUFF,
                },
                FSSH_BLEEDING_EDGE = 
                {
                    name = "Bleeding Edge",
                    desc = "Attacking an enemy with {FSSH_BLEEDING_EDGE} decreases stacks, at 0 stacks, deal tons of damage to the target.",
                    icon = "battle/conditions/bloodbath.tex",
            
                    ctype = CTYPE.DEBUFF,
            
                    event_handlers = 
                    {
                        [ BATTLE_EVENT.ON_HIT] = function(self, battle, attack, hit, target, fighter)
                            if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                                self.owner:RemoveCondition( "FSSH_BLEEDING_EDGE", attack.card.max_damage )
                                if self.owner:GetConditionStacks("FSSH_BLEEDING_EDGE") <= 1 or hit.damage >= self.owner:GetConditionStacks("FSSH_BLEEDING_EDGE") then
                                    attack.attacker:HealHealth(3, self)
                                    self.owner:RemoveCondition("FSSH_BLEEDING_EDGE")
                                end
                            end
                        end
                    }
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
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        local summon = Agent( "CRAYOTE_UPGRADED" )
                        local fighter = Fighter.CreateFromAgent( summon, battle:GetScenario():GetAllyScale() )
                        self.owner:GetTeam():AddFighter( fighter )
                        self.owner:GetTeam():ActivateNewFighters()
                    end
                },
                fssh_great_escape = table.extend(NPC_BUFF)
                {
                    name = "The Great Escape",
                    anim = "taunt2",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    defend_amount = 7,
                    evasion_amount = 1,

                    OnPostResolve = function( self, battle, attack)
                        local randomChance = math.random(1,2)
                        local randomConditionList = {"EVASION", "DEFEND"}
                        if randomChance == 2 then 
                            self.owner:AddCondition(randomConditionList[randomChance], self.defend_amount, self)
                        else
                            self.owner:AddCondition(randomConditionList[randomChance], self.evasion_amount, self)
                        end
                    end
                },
                fssh_rage = table.extend(NPC_BUFF)
                {
                    name = "Rage",
                    anim = "taunt",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:GetCondition("FINAL_EFFORT").powerGained = false
                        self.owner:AddCondition("POWER", 1 , self)
                    end
                },
                fssh_bleeding_edge = table.extend(NPC_MELEE)
                {
                    name = "Bleeding Edge",
                    anim = "lacerate",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 6,
                    OnPostResolve = function( self, battle, attack)
                        local randomChance = math.random(1,4)
                        if randomChance == 2 then
                            for i, hit in attack:Hits() do
                                local target = hit.target
                                if not hit.evaded then
                                    target:AddCondition("FSSH_BLEEDING_EDGE", math.round(target:GetMaxHealth() * 0.25))
                                end
                            end
                        end
                    end
                },
                fssh_slice_up = table.extend(NPC_MELEE)
                {
                    name = "Slice Up",
                    anim = "uppercut",
                    flags = CARD_FLAGS.MELEE,

                    base_damage = 2,
                    OnPostResolve = function( self, battle, attack)
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
                },
                fssh_spinning_slash = table.extend(NPC_MELEE)
                {
                    name = "Spinning Slash",
                    anim = "uppercut",
                    flags = CARD_FLAGS.MELEE,

                    pre_anim = "taunt2",
                    anim = "double_stab",

                    base_damage = 2,
                    OnPostResolve = function( self, battle, attack)
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
                },
            },

            behaviour =
            {
                OnActivate = function( self, fighter)
                    self.fighter:AddCondition("FINAL_EFFORT")
                    self.basicCards = self:MakePicker()
                        :AddID( "fssh_readied_assault", 1)
                        :AddID( "fssh_slice_and_dice", 1)
                        :AddID( "fssh_crippling_slice", 1)
                        :AddID( "fssh_taste_of_blood", 1)
                        :AddID( "fssh_it_wasnt_me", 1)
                    self.buffCards = self:MakePicker()
                        :AddID( "fssh_great_escape", 2)
                        :AddID( "fssh_rage", 2)
                    self.advancedCards = self:MakePicker()
                        :AddID( "fssh_bleeding_edge", 2)
                        :AddID( "fssh_slice_up", 2)
                        :AddID( "fssh_spinning_slash", 2)
                        self:SetPattern( self.Cycle )
                        self.slicer = self:AddCard( "fssh_slicer" )
                        self.dicer = self:AddCard( "fssh_dicer" )
                        self.crayote = self:AddCard( "fssh_call_crayote" )
                end,

                Cycle = function( self )
                     -- 20 stacks: have a chance to summon upgraded crayote
                    local randomCards = math.random(1,2)
                    if self.fighter:GetConditionStacks("FINAL_EFFORT") >= 20 then
                        local randomNum = math.random(1,4)
                        if self.fighter:GetTeam():NumActiveFighters() < 2 and randomNum == 4 then
                            self:ChooseCard( self.crayote )
                        end
                    end
                    if randomCards == 1 then
                        self.basicCards:ChooseCards(2)
                        self.fighter:GetCondition("FINAL_EFFORT").powerGained = true
                        if self.fighter:HasCondition("fssh_slice_and_dice") then
                            self:ChooseCard( self.slicer )
                            self:ChooseCard( self.dicer )
                        end
                    elseif randomCards == 2  then
                      self.buffCards:ChooseCards(2)
                    end
                    -- 40 stacks: gains an extra attack from a pool of advanced cards
                    if self.fighter:GetConditionStacks("FINAL_EFFORT") >= 40 then
                        self.advancedCards:ChooseCards(1)
                    end
                end,
            }
        }
    })
    def:InheritBaseDef()
    Content.AddCharacterDef( def )
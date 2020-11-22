local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local def = CharacterDef("FSSH_PAST",
    {
        name = "Fssh Menewene",
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
        boss = true,
        gender = GENDER.FEMALE,
    

        fight_data = 
        {
            MAX_HEALTH = 160,
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

                    max_stacks = 50,

                    slicerDicerUsed = false,
                    -- petCalled = false,
                    powerGained = false,
                    invincibleUsed = false,
                    killingSpreeUsed = false,
                    timesHit = 0,
                    firstPet = true,
                    calledJakesFighters = false,

                    -- OnApply = function( self, battle )
                    --     self.owner:AddCondition("FSSH_UNBREAKABLE", 1, self)
                    -- end,

                    -- 10 stacks: all basic attacks gain various debuffs
                    -- 20 stacks: have a chance to spawn an upgraded crayote
                    -- 30 stacks: gain 2 defend per hit from you
                    -- 40 stacks: gains an extra attack from a pool of advanced cards
                    -- 50 stacks: gains an extra attack from the basic card pool

                    event_handlers =
                    {
                        [ BATTLE_EVENT.POST_RESOLVE ] = function( self, battle, attack)
                            self.owner:AddCondition("FINAL_EFFORT", 1, self)
                            -- 10 stacks: all basic attacks gain various debuffs
                            if self.owner:GetConditionStacks("FINAL_EFFORT") >= 10 then
                                self.owner:AddCondition("FSSH_BETRAYED", 1, self)
                            end
                            -- 30 stacks: gain 2 defend per hit from you
                            if self.owner:GetConditionStacks("FINAL_EFFORT") >= 30 then
                                self.owner:AddCondition("FSSH_UNBREAKABLE", 1, self)
                            end
                            if self.powerGained == true then
                                if self.owner:HasCondition("POWER") then
                                    self.owner:RemoveCondition("POWER", 1, self)
                                end
                            end
                        end,
                        [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit, target )
                            if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() and self.owner:HasCondition("KILLING_SPREE") then
                                self.timesHit = self.timesHit + 3 -- gains 3 damage everytime she gets hit
                            end
                        end,
                        [ BATTLE_EVENT.BEGIN_PLAYER_TURN ] = function( self, battle, attack)
                            if self.killingSpreeUsed == true then
                                if self.owner:HasCondition("FSSH_KILLING_SPREE") then
                                    self.timesHit = 0
                                    self.killingSpreeUsed = false
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
                FSSH_INVINCIBLE = 
                {
                    name = "Invincible",
                    desc = "Everytime Fssh gets hit, she gains 2 counter.",
                    icon = "battle/conditions/shield_of_hesh.tex",
                    max_stacks = 1,
                    ctype = CTYPE.BUFF,

                    event_handlers = 
                    {
                        [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit, target)
                            if attack:IsTarget( self.owner ) and attack.card:IsAttackCard() then
                                self.owner:AddCondition("RIPOSTE", 2)
                            end
                        end,
                        [ BATTLE_EVENT.END_PLAYER_TURN ] = function( self, battle, attack, hit, target)
                            if self.owner:GetCondition("FINAL_EFFORT").invincibleUsed == true then
                                self.owner:RemoveCondition("FSSH_INVINCIBLE", 1, self)
                                self.owner:GetCondition("FINAL_EFFORT").invincibleUsed = false
                            end
                        end
                    }
                },
                FSSH_KILLING_SPREE = 
                {
                    name = "Killing Spree",
                    desc = "While Fssh has this condition, on her next attack she will shower her enemy with attacks, dealing bonus damage depending on how much damage was dealt to her last turn / 2.",
                    icon = "battle/conditions/bloody_mess.tex",
                    max_stacks = 1,
                    ctype = CTYPE.BUFF,
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

                    base_damage = 4,
                    
                    event_handlers = 
                    {
                        [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                            if card == self then
                                if self.owner:HasCondition("FINAL_EFFORT") then
                                    if self.owner:GetConditionStacks("FINAL_EFFORT") >= 40 then
                                        dmgt:AddDamage(math.floor(self.owner:GetConditionStacks("FINAL_EFFORT") / 10), math.floor(self.owner:GetConditionStacks("FINAL_EFFORT") / 10), self)
                                    end
                                end
                            end
                        end
                    }
                },
                fssh_invincible = table.extend(NPC_BUFF)
                {
                    name = "Invincible", -- every time Fssh gets hit, she gains 2 counter
                    anim = "taunt3",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:AddCondition("FSSH_INVINCIBLE", 1, self)
                        self.owner:GetCondition("FINAL_EFFORT").invincibleUsed = true
                    end
                },
                fssh_killing_spree = table.extend(NPC_MELEE)
                {
                    name = "Killing Spree", -- deals bonus damage depending on how many times she was hit last turn
                    pre_anim = "quickdraw",
                    anim = "punch",
                    post_anim = "slash",

                    flags = CARD_FLAGS.MELEE,

                    base_damage = 7,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:GetCondition("FINAL_EFFORT").killingSpreeUsed = true
                        self.owner:RemoveCondition("FSSH_KILLING_SPREE", 1, self)
                    end,
                    
                    event_handlers = 
                    {
                        [ BATTLE_EVENT.CALC_DAMAGE ] = function( self, card, target, dmgt )
                            if card == self then
                                if self.owner:HasCondition("FINAL_EFFORT") then
                                    dmgt:AddDamage(self.owner:GetCondition("FINAL_EFFORT").timesHit , self.owner:GetCondition("FINAL_EFFORT").timesHit, self)
                                end
                            end
                        end
                    }
                },
                fssh_charge_up = table.extend(NPC_BUFF)
                {
                    name = "Charge Flurry", 
                    pre_anim = "taunt2",
                    anim = "hero_taunt2",
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        self.owner:AddCondition("FSSH_KILLING_SPREE", 1, self)
                        self.owner:HealHealth(5,self)
                    end
                },
                fssh_dagger_throw = table.extend(NPC_RANGED)
                {
                    name = "Dagger Throw", -- deals damage twice
                    pre_anim = "taunt",
                    anim = "targetpractice2",
                    hit_anim = true,
                
                    flags = CARD_FLAGS.RANGED,
                    hit_count = 3,
                    base_damage = 2,
                },
                fssh_deadly_precision = table.extend(NPC_RANGED)
                {
                    name = "Deadly Precision", 
                    pre_anim = "taunt2",
                    anim = "targetpractice1",
                    flags = CARD_FLAGS.RANGED,
                    
                    base_damage = 7,
                },
                fssh_blast = table.extend(NPC_RANGED)
                {
                    name = "Quickdraw", 
                    -- pre_anim = "blast_pre",
                    -- anim = "blast",
                    -- post_anim = "blast_pst",
                    anim = "shoot",
                    flags = CARD_FLAGS.RANGED,
                    
                    base_damage = 7,
                },
                fssh_call_to_jakes = table.extend(NPC_BUFF)
                {
                    name = "Call To Jakes", -- calls jakes backup to help, summons 2 jakes fighters from a random list at the start of battle.
                    anim = "taunt",
        
                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack)
                        local riseUnits = {"JAKES_SMUGGLER", "JAKES_RUNNER", "JAKES_LIFTER"}
                        local randomUnit1 = math.random(1,3)
                        local randomUnit2 = math.random(1,3)
                        local randomUnit3 = math.random(1,3)

                        local summon = Agent( riseUnits[randomUnit1] )
                        local riseFighter1 = Fighter.CreateFromAgent( summon, battle:GetScenario():GetAllyScale() )
                        self.owner:GetTeam():AddFighter( riseFighter1 )

                        local summon = Agent( riseUnits[randomUnit2] )
                        local riseFighter2 = Fighter.CreateFromAgent( summon, battle:GetScenario():GetAllyScale() )
                        self.owner:GetTeam():AddFighter( riseFighter2 )

                        -- local summon = Agent( riseUnits[randomUnit3] )
                        -- local riseFighter3 = Fighter.CreateFromAgent( summon, battle:GetScenario():GetAllyScale() )
                        -- self.owner:GetTeam():AddFighter( riseFighter3 )

                        self.owner:GetTeam():ActivateNewFighters()
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
                        :AddID( "fssh_invincible", 2)
                        :AddID( "fssh_charge_up", 2)
                    self.advancedCards = self:MakePicker()
                        :AddID( "fssh_bleeding_edge", 2)
                        :AddID( "fssh_slice_up", 2)
                        :AddID( "fssh_spinning_slash", 2)
                    self.rangedCards = self:MakePicker()
                        :AddID( "fssh_dagger_throw", 2)
                        :AddID( "fssh_deadly_precision", 2)
                        :AddID( "fssh_blast", 2)
                        self:SetPattern( self.Cycle )
                        self.slicer = self:AddCard( "fssh_slicer" )
                        self.dicer = self:AddCard( "fssh_dicer" )
                        self.crayote = self:AddCard( "fssh_call_crayote" )
                        self.callJakes = self:AddCard( "fssh_call_to_jakes" )
                        self.killingSpree = self:AddCard( "fssh_killing_spree" )
                end,

                Cycle = function( self )
                    if self.fighter:GetCondition("FINAL_EFFORT").calledJakesFighters == false then
                        self:ChooseCard( self.callJakes )
                        self.fighter:GetCondition("FINAL_EFFORT").calledJakesFighters = true
                    end

                    local randomCards = math.random(1,3)
                    -- 20 stacks: have a chance to summon upgraded crayote
                    if self.fighter:GetConditionStacks("FINAL_EFFORT") >= 20 then
                        if self.fighter:GetCondition("FINAL_EFFORT").firstPet == true then -- fssh calls pet regardless the first time she gets 20 stacks of final effort
                            self:ChooseCard( self.crayote )
                            self.fighter:GetCondition("FINAL_EFFORT").firstPet = false
                        else
                            local hasCrayote = false
                            for i, ally in self.fighter:GetTeam():Fighters() do -- if crayote is not already, active and the first crayote was slain, have a chance to call another crayote
                                if ally.id == "CRAYOTE_UPGRADED" then
                                    hasCrayote = true
                                end
                            end
                            if hasCrayote == false then
                                local randomNum = math.random(1,4)
                                if self.fighter:GetTeam():NumActiveFighters() < 2 and randomNum == 4 then
                                    self:ChooseCard( self.crayote )
                                end
                            end
                        end
                    end
                    -- basic attacks
                    if randomCards == 1 then
                        self.basicCards:ChooseCards(2)
                        self.fighter:GetCondition("FINAL_EFFORT").powerGained = true
                        if self.fighter:HasCondition("fssh_slice_and_dice") then
                            self:ChooseCard( self.slicer )
                            self:ChooseCard( self.dicer )
                        end
                    -- buffs
                    elseif randomCards == 2  then
                        self.buffCards:ChooseCards(2)
                    elseif randomCards == 3  then
                        self.rangedCards:ChooseCards(3)
                    end
                    -- 40 stacks: gains an extra attack from a pool of advanced cards
                    if self.fighter:GetConditionStacks("FINAL_EFFORT") >= 40 then
                        self.advancedCards:ChooseCards(1)
                    end
                    -- 50 stacks: gains an extra attack from the basic card pool
                    if self.fighter:GetConditionStacks("FINAL_EFFORT") >= 50 then
                        self.basicCards:ChooseCards(1)
                    end
                    if self.fighter:HasCondition("FSSH_KILLING_SPREE") then
                        self:ChooseCard( self.killingSpree )
                    end
                end,
            }
        }
    })
    def:InheritBaseDef()
    Content.AddCharacterDef( def )
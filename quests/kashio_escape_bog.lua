local fun = require "util/fun"
local daily = require "daily_util"

local ally_options = 
{
    "WANDERING_CHEF", "BRAVE_MERCHANT"
}

local boss_options =
{
    {"SPARK_BARON_BOSS", "DRONE_GOON", "HESH_BOSS", "RENTORIAN_BOSS"},
    {"JAKES_ASSASSIN", "JAKES_ASSASSIN2"},
    {"SPARK_SECOND", "RISE_SECOND", "SHROOG", "DRUSK_1"},
    {"MURDER_BAY_BANDIT_CONTACT", "MURDER_BAY_ADMIRALTY_CONTACT"},
    {"BOGGER_BOSS", "KASHIO"},
}

local boss_backup =
{
    KASHIO = {"ADMIRALTY_GOON"},
    BOGGER_BOSS = {"SPARK_BARON_GOON"},
    MURDER_BAY_BANDIT_CONTACT = {"ADMIRALTY_GOON", "ADMIRALTY_CLERK"},
    MURDER_BAY_ADMIRALTY_CONTACT = {"BANDIT_GOON", "BANDIT_GOON"},
    SHROOG = {"JAKES_SMUGGLER"},
    DRUSK_1 = {"JAKES_SMUGGLER"},
}


local function DoCardDraft(cxt, difficulty, subtitle_text)
    local function OnDone()
        cxt.encounter:ResumeEncounter()
    end
    local draft_popup = Screen.DraftPackPopup()
    draft_popup:DraftPacks( cxt.player, Battle.Card, difficulty, OnDone, subtitle_text, cxt:GetRNG( "CARDS" ))
    TheGame:FE():InsertScreen( draft_popup )
    cxt.enc:YieldEncounter()
end

local function DoGraftDraft( cxt, difficulty )

    local rng = cxt:GetRNG( "GRAFTS" )
    if rng then
        push_random( function( n, m )
            return rng:Random( n, m )
        end )
    end

    local grafts = RewardUtil.GetPooledGrafts( difficulty, 3, cxt.quest.param.graft_pool )

    if rng then
        pop_random()
    end

    local popup = Screen.PickGraftScreen(grafts, false, function(...) cxt.enc:ResumeEncounter(...) end)
    popup:SetMusicEvent( TheGame:LookupPlayerMusic( "deck_music" ))
    TheGame:FE():InsertScreen( popup )

    local chosen_graft = cxt.enc:YieldEncounter()
end

local boon_options = 
{
    remove_card = function(cxt)
            cxt:Opt( "OPT_REMOVE_BATTLE_CARD" )
                :PreIcon( global_images.removecombat )
                :Fn( function( cxt )
                        cxt:Wait()
                        AgentUtil.RemoveBattleCard( cxt.player, function( card_id )
                            cxt.enc:ResumeEncounter()
                        end)
                    cxt.enc:YieldEncounter()
                    cxt:GoTo("STATE_ENCOUNTER")
                end)
    end,
    draft_card = function(cxt)
            cxt:Opt( "OPT_BATTLE_DRAFT" )
                :PreIcon( global_images.buycombat )
                :Fn( function( cxt )
                    cxt:Wait()

                    DoCardDraft(cxt, 3)
                    cxt:GoTo("STATE_ENCOUNTER")
                end )
    end,
    triage = function( cxt )
        cxt:Opt( "OFFER_TRIAGE_KIT", "healing_vapors" )
            :PreIcon( global_images.giving )
            :Quip( cxt:GetAgent(), "chum_bonus", "triage_kit" )
            :GainCards{"healing_vapors", "healing_vapors"}
            :GoTo("STATE_ENCOUNTER")
    end,
    boombox = function( cxt )
        local function IsGrenade( def )
            return CheckBits(def.item_tags or 0, ITEM_TAGS.GRENADE)
        end

        local cards = {}
        for i = 1, 2 do
            local def = BattleCardCollection.AllLocalItems( IsGrenade ):Pick(1)[1]
            if def then
                table.insert( cards, def.id )
            end
        end

        cxt:Opt( "OFFER_BOOM_BOX", cards )
            :PreIcon( global_images.giving )
            :Quip( cxt:GetAgent(), "chum_bonus", "boom_box" )
            :GainCards(cards)
            :GoTo("STATE_ENCOUNTER")
    end,
    graft_slot = function( cxt )
        local txt = "OFFER_BATTLE_SLOT"
        cxt:Opt( txt )
            :PreIcon( global_images.graft )
            :Quip( cxt:GetAgent(), "chum_bonus", "graft" )
            :Fn( function( cxt )
                cxt.player.graft_owner:IncreaseMaxGrafts( GRAFT_TYPE.COMBAT, 1 )
                cxt:GoTo("STATE_ENCOUNTER")
            end )
    end,
    score_cards = StateGraphUtil.OfferScoreCards("STATE_ENCOUNTER"),
}

local QDEF = QuestDef.Define
{
    title = "Boss Rush",
    icon = engine.asset.Texture("icons/quests/daily_escape_cave.tex"),
    desc = [[Defeat a series of bosses in quick succession.]],
    qtype = QTYPE.DAILY,
    on_complete = function( quest )
        TheGame:Win()
    end,
    
    ChooseCharacter = function( self, rng )
        return character_options[rng:Random(#character_options)]
    end,
    
    GenerateMutatorsAndFeats = function(self, rng, character_id)
        
        local arg = {
            battle_draft = {
                "havarian_mulligan_battle",
                "battle_bundle",
                "picky_draft_battle",
                "veteran",
            },
            always_take = {
                "brilliance",
                "pet_owner",
                "daily_boss_health",
            },
            mutators = {
                "parasitology",
                "roll_with_it",
                "mental_overload",
                "contaminated_equipment",
                "score_card_mutator",
                "keepsake_mutator",
                "mutator",
            },
            feats = {
                {"vicious_feat", "no_sweat", "not_a_scratch"},
                {"smashing", "play_dead", "take_your_shot"},
                {"smashing", "no_sweat", "take_your_shot"},
                {"cheapskate", "thorough_search", "clean_fight"},
                {"vicious_feat", "play_dead", "quick_work"},
                {"smashing", "tank_up", "take_your_shot"},

            },
            min_mutators = 2,
            max_mutators = 3,
        }

        return daily.GenerateMutatorsAndFeats(rng, character_id, arg)
    end,


    plax = "EXT_Bog_Forest_01",


    on_init = function(quest)
        TheGame:GetGameState():SetDifficulty( 2 ) -- For better initial draft.
        TheGame:GetGameState():GetCaravan():MoveToLocation(quest:GetCastMember("the_forest"))
    end,

    GenerateParams = function( self, rng )
        local param = {}
        
        param.available_encounters = {}
        for i,options in ipairs(boss_options) do
            table.insert(param.available_encounters, options[rng:Random(#options)])
        end

        param.available_bonuses = {}
        for i=1, (#param.available_encounters - 1) do
            local temp_options = {}
            for k,v in pairs(boon_options) do
                table.insert(temp_options, k)
            end
            table.seeded_shuffle(temp_options, rng)
            for i=1,2 do
                table.insert(param.available_bonuses, table.remove(temp_options, 1))
            end
        end

        param.kashio_conditions = {}
        local AUCTION_DATA = require "content/grafts/kashio_boss_fight_defs"
        local candidates = {}
        for k,v in pairs(AUCTION_DATA.CONDITION_LOOKUPS) do
            table.insert(candidates, v)
        end
        table.seeded_shuffle(candidates, rng)
        
        local NUM_PICKS = 3
        
        for k = 1, math.min(NUM_PICKS, #candidates) do
            table.insert(param.kashio_conditions, candidates[k])
        end
        param.all_encounters = shallowcopy(param.available_encounters)
        param.step = 0
        return param
    end,


    GenerateProgressionData = function(qdef, param)
        local current_day = {}
        local next_step = param.step
        
        if param.all_encounters then
            for step,def in ipairs(param.all_encounters) do
                table.insert(current_day, {id="BOSS", boss = def})
                if next_step == step then
                    current_day[#current_day].right_now = true
                elseif next_step > step then
                    current_day[#current_day].success = true
                end
            end
        end
        return {current_day}
    end,


    get_progression = function(quest)
        return quest:GetQuestDef().GenerateProgressionData(quest:GetQuestDef(), quest.param)
    end,



}

:AddScoreDefs{
    
    SKIPPED_BONUS = 
    {
        name = "Skipped Bonus",
        value = 30,
    },
    
    SKIPPED_HEALING = 
    {
        name = "Skipped Healing",
        value = 40,
    },

    PET_SURVIVED = {
        name = "Pet Survived",
        value = 150,
    },
    WON_DAILY = {
        name = "Defeated All Bosses",
        value = 500,
    },
    
    LEFT_SURVIVOR = {
        name = "Let Companion Go",
        value = 100,
    }
}

:AddObjective{
    id = "start",
    title = "Defeat the Bosses",
    on_activate = function( quest)
        quest.param.location = quest:SpawnTempLocation("GROUT_BOG_FOREST", "the_forest" )
    end,
    state = QSTATUS.ACTIVE,
}

:AddCast{
    cast_id = "the_forest",
    when = QWHEN.MANUAL,
}

:AddCast{
    cast_id = "pet",
    when = QWHEN.MANUAL,
}

local function FindNewOptions(cxt)
        if #cxt.quest.param.available_encounters > 0 then
            cxt.quest.param.step = cxt.quest.param.step + 1
            cxt.quest.param.next_boss = table.remove(cxt.quest.param.available_encounters, 1)
            cxt.quest:NotifyChanged()
            return true
        else
            return false
        end
end

local function InitializeRun( cxt )
    local function Filter( graft_def )
        return graft_def.type == GRAFT_TYPE.COMBAT
    end
    cxt.quest.param.graft_pool = GraftCollection.GraftPool( cxt.player, Filter, cxt:GetRNG( "GRAFTS" ) )

    cxt.encounter:DoLocationTransition( cxt.quest.param.location )
    cxt.quest:SetRank(2)
    cxt.quest:NotifyChanged()
end

local function OfferBonuses(cxt)
    local bonuses = {}
    for i=1, 2 do
        table.insert( bonuses, table.remove(cxt.quest.param.available_bonuses))
    end

    for i, id in ipairs( bonuses ) do
        boon_options[id](cxt)
    end
    cxt:Opt("OPT_SKIP")
        :AddScore("SKIPPED_BONUS")
        :GoTo("STATE_ENCOUNTER")
end


QDEF:AddConvo("start")
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
            ]],
            OPT_GET_GRAFT = "Choose a graft",
            OPT_DO_DRAFT = "Draft some cards",
        }
        :Fn(function(cxt) 

            if StateGraphUtil.RestoreDaily( cxt ) then
                return
            end

            InitializeRun(cxt)

            local pet = TheGame:GetGameState():GetCaravan():GetPet()
            if pet then
                cxt.quest:AssignCastMember("pet", pet)
            end

            cxt:Dialog("DIALOG_INTRO")

            DoGraftDraft(cxt, 2)

            cxt:GoTo("STATE_ENCOUNTER") 
        end)

    :State("STATE_ENCOUNTER")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right
                    !angryHostile
                    !fight
                player:
                    !left
                    !fight
                {first_time?
                    * A challenger arrives!
                }
                {not first_time?
                    * The next challenger arrives!
                }
                
            ]],
            DIALOG_BACKUP = [[
                * You spot {1} ready to fight {agent} by your side.
            ]],
            OPT_FIGHT = "Defend yourself",
            OPT_CONTINUE = "Continue",
            DIALOG_CLEAR = [[
                player:
                    !exit
                agent:
                    !exit
            ]],

            DIALOG_SURVIVOR = [[
                agent:
                    !right
                    I owe you one. Do you need my help?
            ]],
            OPT_TAKE_SURVIVOR = "Take {agent} with you",
            DIALOG_TAKE_SURVIVOR = [[
                agent:
                    !exit
                * {agent} joins you.
            ]],
            OPT_LEAVE_SURVIVOR = "Let {agent} go",
            DIALOG_LEAVE_SURVIVOR = [[
                agent:
                    !happy
                    Thanks for helping me!
                    !exit
                * You lost a companion, but gained a friend.
            ]],

        }
        :Fn(function(cxt) 
                FindNewOptions(cxt)
                local boss = cxt.quest:CreateSkinnedAgent( cxt.quest.param.next_boss )
                cxt.enc:SetPrimaryCast(boss)
                cxt:Dialog("DIALOG_INTRO")
                local back_up = {}
                if boss_backup[cxt.quest.param.next_boss] then
                    for i,id in ipairs(boss_backup[cxt.quest.param.next_boss]) do
                        local agent = TheGame:GetGameState():AddAgent(Agent( id ))
                        table.insert(back_up, agent)
                    end
                    cxt:Dialog("DIALOG_BACKUP", back_up[1])
                end
                local add_conditions = {}
                local flags
                if cxt.quest.param.next_boss == "KASHIO" then
                    add_conditions = cxt.quest.param.kashio_conditions
                end
                if #cxt.quest.param.available_encounters == 0 then
                    flags = BATTLE_FLAGS.ISOLATED | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.BOSS_FIGHT | BATTLE_FLAGS.NO_REWARDS
                else
                    flags = BATTLE_FLAGS.ISOLATED | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.BOSS_FIGHT
                end

                cxt:Opt("OPT_FIGHT")
                    :Battle{
                        flags = flags,
                        allies = back_up,
                        on_start_battle = function(battle) 
                            local fighter = battle:GetFighterForAgent(cxt:GetAgent())
                            if fighter then
                                for k,v in ipairs(add_conditions) do
                                    fighter:AddCondition(v)
                                end
                                fighter:ClearPreparedCards()
                                fighter:PrepareTurn()
                            end
                            if on_start_boss[cxt:GetAgent():GetContentID()] then
                                on_start_boss[cxt:GetAgent():GetContentID()](battle)
                            end
                        end,
                        on_win = function(cxt) 
                            cxt:Opt("OPT_CONTINUE")
                                :Fn(function(cxt)
                                    cxt:Dialog("DIALOG_CLEAR")
                                    if #cxt.quest.param.available_encounters == 0 then
                                        local pet = cxt.enc:GetCastAgent("pet")
                                        if pet and not pet:IsDead() and pet:IsInPlayerParty() then
                                            cxt.quest:AddScore("PET_SURVIVED")
                                        end
                                        cxt.quest:Complete()
                                    else
                                        local diff_table = {3, 4, 4, 5}
                                        local diff = diff_table[math.min(cxt.quest.param.step, #diff_table)]
                                        DoGraftDraft(cxt, diff)
                                        DoCardDraft(cxt, diff)

                                        local survivors = {}
                                        for k,v in ipairs(back_up) do
                                            if not v:IsDead() then
                                                table.insert(survivors, v)
                                            end
                                        end
                                        
                                        if #survivors == 0 then
                                            cxt:GoTo("STATE_HEALING")
                                        else
                                            cxt:RunLoop(function() 
                                                if #survivors == 0 then
                                                    cxt:GoTo("STATE_HEALING")
                                                end

                                                local survivor = table.remove(survivors)
                                                cxt:TalkTo(survivor)
                                                cxt:Dialog("DIALOG_SURVIVOR")

                                                cxt:Opt("OPT_TAKE_SURVIVOR")
                                                    :Dialog("DIALOG_TAKE_SURVIVOR")
                                                    :Fn(function() 
                                                        survivor:Recruit(PARTY_MEMBER_TYPE.CREW)
                                                    end)
                                                
                                                cxt:Opt("OPT_LEAVE_SURVIVOR")
                                                    :Dialog("DIALOG_LEAVE_SURVIVOR")
                                                    :AddScore("LEFT_SURVIVOR")
                                                    :ReceiveOpinion(OPINION.SAVED_LIFE)
                                                    :Fn(function() 
                                                        cxt:GetAgent():MoveToLimbo()
                                                    end)
                                            end)
                                        end
                                        
                                    end
                                end)
                        end,
                    }
            end)

    :State("STATE_HEALING")
        :Loc{
            DIALOG_INTRO = [[
                * You have some time to tend to your wounds.
            ]],
            OPT_SKIP = "Skip",
            OPT_HEAL = "Tend to your injuries",
            OPT_HEAL_PET = "Heal your pet",
            TT_HEAL = "This also heals your pet",
        }
        :Fn(function(cxt) 
            cxt:Dialog("DIALOG_INTRO")
            cxt.enc:SetPrimaryCast(nil)

            local pet = cxt.enc:GetCastAgent("pet")

            cxt:Opt("OPT_HEAL")
                :PreIcon(global_images.heal)
                :PostText("TT_HEAL")
                :DeltaHealth(20)
                :Fn(function()
                    if pet and not pet:IsRetired() then
                        pet:GetAspect("health"):Delta(20)
                    end
                    cxt:GoTo("STATE_BONUS")
                end)

            if cxt.player:GetAspect("health"):GetPercent() == 1 and pet and not pet:IsRetired() then
                cxt:Opt("OPT_HEAL_PET")
                    :PreIcon(global_images.heal)
                    :Fn(function()
                        pet:GetAspect("health"):Delta(20)
                        cxt:GoTo("STATE_BONUS")
                    end)
            end

            cxt:Opt("OPT_SKIP")
                :AddScore("SKIPPED_HEALING")
                :GoTo("STATE_BONUS")
        end)

    :State("STATE_BONUS")
        :Loc{
            DIALOG_INTRO = [[
                * Choose a bonus reward before starting the next fight.
            ]],
            OPT_SKIP = "Skip",
            OPT_CONTINUE_TO_FIGHT = "Continue to the next fight",
            OPT_REMOVE_BATTLE_CARD = "Remove a battle card",
            OPT_BATTLE_DRAFT = "Draft a pack of battle cards",
        }
        :Fn(function(cxt) 
            cxt:Dialog("DIALOG_INTRO")
            cxt.enc:SetPrimaryCast(nil)
            cxt:RunFn(OfferBonuses)
        end)
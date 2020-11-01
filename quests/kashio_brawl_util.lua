local fun = require "util/fun"
require "brawlschedule"

local STARTING_MONEY = 70
local SLOT_HEALTH = 20
local SLOT_COST = 150
local MAX_GRAFTS = 6

local PET_HEAL_COST = 150
local PET_COST = 250
local PET_UPGRADE_COST = 300

local FSSHCAKE_COST = 40
local FSSHCAKE_HEAL = 15


local VENDOR_DATA = {
    grafts = {objective = "graft_sale"},
    negotiation = {objective = "negotiation_sale"},
    battle = {objective = "battle_sale"},
    pets = {objective = "pet_sale"},
    coins = {objective = "coin_trade"}
}

local PETS = {
    FLEAD = {def = "FLEAD", cost = .8, upgrade_def = "FLEAD_UPGRADED"},
    CRAYOTE = {def = "CRAYOTE", cost = 1, upgrade_def = "CRAYOTE_UPGRADED"},
    VROC = {def = "VROC", cost = 1.2, upgrade_def = "VROC_UPGRADED"},
    SHROOGLET = {def = "SHROOGLET", cost = .25, upgrade_def = "SHROOGLET_UPGRADED"},
    ERCHIN = {def = "ERCHIN", cost = .25, upgrade_def = "ERCHIN_UPGRADED"},
}


local function FindCoinGrafts( number, rarity )
    local owner = TheGame:GetGameState():GetPlayerAgent()
    local collection = GraftCollection.RewardableCoin(owner):Rarity(rarity)
    local grafts = collection:Generate(number)
    
    if grafts then
        for k,graft in ipairs(grafts) do
            TheGame:GetGameProfile():SetSeenGraft( graft.id )
        end
    end
    
    return grafts
end



local BRAWL_LOCATIONS = {
    "EXT_BOGGER_HIDEOUT_01",
    "EXT_BOG_DEEPBOG",
    "EXT_Bog_Forest_01",
    "EXT_Bog_HedgeGod_01",
    "Ext_Bog_Illegal_Worksite_1",
    "EXT_Bog_Outcrop_01",
    "EXT_DROPSITE",
    "INT_Bog_Cave_01",
    "INT_BOG_MINE",
}


local bonus_loc = {
    OPT_BONUS_MONEY = "Take money",
    DIALOG_BONUS_MONEY = [[
        * You get {1#money}.
    ]],
    DIAL_REMOVE_CARD = [[
        agent:
            Feels lighter, doesn't it?
    ]],
    REQ_AT_FULL_HEALTH = "At full health",
    REQ_AT_FULL_RESOLVE = "At full resolve",
    OPT_HEAL_HEALTH = "Restore <#HEALTH>{1} Health</>",
    OPT_HEAL_RESOLVE = "Restore <#TITLE>{1} Resolve</>",

    OPT_GAIN_MAX_HEALTH = "Increase max health by {1}",
    OPT_GAIN_MAX_RESOLVE = "Increase max resolve by {1}",
    OPT_GAIN_ITEMS = "Get {1#card_list}",
    OPT_DRAFT_BATTLE_CARD = "Draft 2 battle cards",
    OPT_DRAFT_NEGOTIATION_CARD = "Draft 2 negotiation cards",
}


local bonuses = 
{
    money = 
    {
        convo = function(cxt) 
            local diff = TheGame:GetGameState():GetCurrentBaseDifficulty() 
            local amt = diff*50
            cxt:Opt("OPT_BONUS_MONEY")
                :ReceiveMoney(amt, {no_scale = true})
                :Dialog("DIALOG_BONUS_MONEY", amt)
                :DoneConvo()
        end,
    },
    
    negotiation_removal = 
    {
        convo = function(cxt) 
                cxt:Opt("OPT_REMOVE_NEGOTIATION_CARD")
                    :Fn(function() 
                            AgentUtil.RemoveNegotiationCard( cxt.player, function( card )
                                cxt.enc:ResumeEncounter( card )
                            end)
                            
                            local card = cxt.enc:YieldEncounter()
                            if card then
                                cxt:Dialog("DIAL_REMOVE_CARD")
                                StateGraphUtil.AddEndOption(cxt)
                            end
                        end)
            end,
    },
    
    battle_removal = 
    {
        convo = function(cxt) 
                cxt:Opt("OPT_REMOVE_BATTLE_CARD")
                    :Fn(function() 
                            AgentUtil.RemoveBattleCard( cxt.player, function( card )
                                cxt.enc:ResumeEncounter( card )
                            end)
                            
                            local card = cxt.enc:YieldEncounter()
                            if card then
                                cxt:Dialog("DIAL_REMOVE_CARD")
                                StateGraphUtil.AddEndOption(cxt)
                            end
                        end)
            end,
    },


    battle_draft = 
    {
        convo = function(cxt) 
                cxt:Opt("OPT_DRAFT_BATTLE_CARD")
                    :Fn(function(cxt) 
                        local function OnDone()
                            cxt.encounter:ResumeEncounter()
                        end

                        for i = 1, 2 do
                            local draft_popup = Screen.DraftChoicePopup()
                            local cards = RewardUtil.GetBattleCards( TheGame:GetGameState():GetCurrentBaseDifficulty(), 3, cxt.player )
                            draft_popup:DraftCards( cxt.player, Battle.Card, cards, OnDone )
                            TheGame:FE():InsertScreen( draft_popup )
                            cxt.enc:YieldEncounter()
                        end            
                                StateGraphUtil.AddEndOption(cxt)
                        end)
            end,
    },
    negotiation_draft = 
    {
        convo = function(cxt) 
                cxt:Opt("OPT_DRAFT_NEGOTIATION_CARD")
                    :Fn(function(cxt) 
                        local function OnDone()
                            cxt.encounter:ResumeEncounter()
                        end
                        for i=1, 2 do
                            local draft_popup = Screen.DraftChoicePopup()
                            local cards = RewardUtil.GetNegotiationCards( TheGame:GetGameState():GetCurrentBaseDifficulty(), 3, cxt.player )
                            draft_popup:DraftCards( cxt.player, Negotiation.Card, cards, OnDone )
                            TheGame:FE():InsertScreen( draft_popup )
                            cxt.enc:YieldEncounter()
                        end
                                StateGraphUtil.AddEndOption(cxt)
                        end)
            end,
    },
    
    heal_health = 
    {
        condition = function(quest) 
            local current_health, max_health = TheGame:GetGameState():GetPlayerAgent():GetHealth()
            return current_health < max_health
        end,
        convo = function(cxt) 
                    local current_health, max_health = TheGame:GetGameState():GetPlayerAgent():GetHealth()
                    local restore_amt = 30
                    cxt:Opt("OPT_HEAL_HEALTH", restore_amt)
                        :ReqCondition(current_health < max_health, "REQ_AT_FULL_HEALTH")
                        :DeltaHealth( restore_amt )
                        :DoneConvo()
            end,

    },
    
    heal_resolve = 
    {
        condition = function(quest) 
            local resolve, resolve_max = TheGame:GetGameState():GetCaravan():GetResolve()
            return resolve < resolve_max
        end,

        convo = function(cxt) 
                    local resolve, resolve_max = TheGame:GetGameState():GetCaravan():GetResolve()
                    local restore_amt = 30
                    cxt:Opt("OPT_HEAL_RESOLVE", restore_amt)
                        :ReqCondition(resolve < resolve_max, "REQ_AT_FULL_RESOLVE" )
                        :DeltaResolve( restore_amt )
                        :DoneConvo()
                end,
    },

    gain_max_health = 
    {
        condition = function(quest) 
            local current_health, max_health = TheGame:GetGameState():GetPlayerAgent():GetHealth()
            return max_health < 80
        end,
        convo = function(cxt)
                    local gain_amount = 5
                    cxt:Opt("OPT_GAIN_MAX_HEALTH", gain_amount)
                        :Fn(function() 
                            cxt.caravan:UpgradeHealth( gain_amount )
                            StateGraphUtil.AddEndOption(cxt) 
                        end)
                end,
    },
    
    gain_max_resolve = {
        condition = function(quest) 
            local resolve, resolve_max = TheGame:GetGameState():GetCaravan():GetResolve()
            return resolve_max < 50
        end,
        convo = function(cxt)
                    local gain_amount = 5
                    cxt:Opt("OPT_GAIN_MAX_RESOLVE", gain_amount)
                        :Fn(function() 
                            cxt.caravan:UpgradeResolve( gain_amount )
                            StateGraphUtil.AddEndOption(cxt) 
                        end)
                end,
    },
    
    items = {
        init = function(cxt)
                    cxt.enc.scratch.bonus_items = {}
                    for i, card in ipairs(BattleCardCollection.AllItems():Pick(2)) do
                        table.insert(cxt.enc.scratch.bonus_items, card.id)
                    end
                end,
        
        convo = function(cxt) 
                cxt:Opt("OPT_GAIN_ITEMS", cxt.enc.scratch.bonus_items)
                    :GainCards(cxt.enc.scratch.bonus_items)
                    :DoneConvo()
        end,
    }

}

local all_bonuses = {}
for k,v in pairs(bonuses) do
    table.insert(all_bonuses, k)
end

local function PickMerchants(options, num_to_pick)
    num_to_pick = num_to_pick or #options
    local ret = {}
    table.shuffle(options)
    for k = 1, math.min(num_to_pick, #options) do
        table.insert(ret, options[k])
    end
    return ret
end

local function PickBoss(options, already_selected)
    table.shuffle(options)
    table.stable_sort(options, function(a, b) return (already_selected[a] or 0) < (already_selected[b] or 0) end)
    local ret = options[1]
    already_selected[ret] = already_selected[ret] or 0 + 1
    return ret
end

local function PickQuests(all_valid, already_selected, rank, num_to_pick, min_negotiation, min_combat)
    local all_valid_scores = {}
    for k,def in pairs(all_valid) do
        local defmin, defmax = def:GetRankRange()
        if rank >= defmin and rank <= defmax then
            table.insert(all_valid_scores, {score = already_selected[def.id] or 0, def = def})
        end
    end
    table.shuffle(all_valid_scores)
    table.stable_sort(all_valid_scores, function(a,b) return a.score < b.score end )


    local ret = {}

    for _ = 1, min_negotiation do 
        for k, score in ipairs(all_valid_scores) do
            if score.def.focus ~= QUEST_FOCUS.COMBAT then
                local to_add = table.remove(all_valid_scores, k)
                already_selected[ to_add.def.id ] = (already_selected[ to_add.def.id ] or 0) + 1
                table.insert(ret, to_add.def.id)
                break
            end
        end
    end
    
    for _ = 1, min_combat do 
        for k, score in ipairs(all_valid_scores) do
            if score.def.focus ~= QUEST_FOCUS.NEGOTIATION then
                local to_add = table.remove(all_valid_scores, k)
                already_selected[ to_add.def.id ] = (already_selected[ to_add.def.id ] or 0) + 1
                table.insert(ret, to_add.def.id)
                break
            end
        end
    end

    for k = 1, num_to_pick - min_combat - min_negotiation do
        local to_add = all_valid_scores[k]
        already_selected[ to_add.def.id ] = (already_selected[ to_add.def.id ] or 0) + 1
        table.insert(ret, to_add.def.id)
    end

    table.shuffle(ret)
    return ret
end



local function do_next_quest_step(quest)
    local event = quest.param.schedule[quest.param.next_schedule_step]
    if event then
        quest.param.next_schedule_step = quest.param.next_schedule_step + 1 
        if event.id == "quest_phase" then
            quest:Activate(event.objective)
            return do_next_quest_step(quest)
        elseif event.id == "bonus" then
            local candidates = {}
            quest.param.bonuses_offered = quest.param.bonuses_offered or {}
            if event.options then
                for k,v in pairs(event.options) do
                    if bonuses[v] then
                        if bonuses[v].condition == nil or bonuses[v].condition(quest) then
                            table.insert(candidates, v)
                        end
                    end
                end
            end
            quest.param.bonus_options = {}
            table.shuffle(candidates) 
            for k = 1, math.min(#candidates, event.num) do
                local id = candidates[k]
                table.insert(quest.param.bonus_options, id)
                quest.param.bonuses_offered[id] = (quest.param.bonuses_offered[id] or 0) + 1
            end
            quest:Activate("do_bonus")
        elseif event.id == "quest" then
            quest.param.boss_time = false
            if quest.param.current_job and not quest.param.current_job:IsDone() then
                quest.param.current_job:Cancel()
            end
            local new_quest, err = QuestUtil.SpawnQuest( event.quest, { qrank = event.rank or TheGame:GetGameState():GetCurrentBaseDifficulty(), parameters = event.params }  ) 
            if new_quest then
                new_quest.extra_reward = EXTRA_QUEST_REWARD.NONE
                quest.param.current_job = new_quest
                quest:Activate("pick_job")            
            else
                DBG(err)
            end
        elseif event.id == "set_home" then
            quest:UnassignCastMember( "home" )
            quest:AssignCastMember("home", quest:GetCastMember(event.cast_id))
            return do_next_quest_step(quest)
        elseif event.id == "night" then 
            UIHelpers.PassTime(DAY_PHASE.NIGHT)
            return do_next_quest_step(quest)
        elseif event.id == "difficulty" then 
            TheGame:GetGameState():SetDifficulty(event.diff or 1)
            return do_next_quest_step(quest)
        elseif event.id == "boss" then 
            if quest.param.current_job and not quest.param.current_job:IsDone() then
                quest.param.current_job:Cancel()
            end
            quest.param.boss_time = true
            local new_quest, err = QuestUtil.SpawnQuest( "SAL_BRAWL_BOSS_FIGHT", { qrank = TheGame:GetGameState():GetCurrentBaseDifficulty() , parameters = {boss_id = event.def, give_graft = event.give_graft } }  ) 
            quest.param.current_job = new_quest
            quest:Activate("pick_job")            
        elseif event.id == "sleep" then 
            quest:Activate("sleep")
        elseif event.id == "win" then 
            TheGame:GetGameState():AddScore("PROGRESS", quest.param.day)
            TheGame:Win()            
        elseif event.id == "merchants" then 
            if event.vendors then
                for k, v in ipairs(event.vendors) do
                    if VENDOR_DATA[v] then
                        quest:Activate(VENDOR_DATA[v].objective)
                    end
                end
            end

            return do_next_quest_step(quest)
        end

    end
end

-- Convo("BRAWL_HOME_LOCATION_CONVO")
--     :State("STATE_SLEEP")
--         :Fn(function(cxt) 
--                 cxt:FadeOut()
--                 ConvoUtil.DoSleep(cxt)
--                 LocationUtil.SendPatronsAway(cxt.location)
--                 cxt:FadeIn()
--                 cxt.quest:Cancel("sleep")
--                 cxt.quest.param.day = cxt.quest.param.day + 1
--                 TheGame:GetGameState():AddScore("PROGRESS", cxt.quest.param.day)
--                 TheGame:GetGameState():SetActProgress(cxt.quest.param.day)
--                 do_next_quest_step(cxt.quest)
--             end)


local function CreateBrawlQuest(id, data)

    local QDEF = QuestDef.Define
    {
        title = data.title,
        id = id,
        icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
        qtype = QTYPE.STORY,
        on_init = function(quest)

            TheGame:GetGameState():GetCaravan():SetMoney(STARTING_MONEY)
            TheGame:GetGameState():SetMainQuest(quest)
            TheGame:GetGameState().brawl = true

            quest.param.schedule = data.MakeBrawlSchedule(data)
            quest.param.quest_results = {}
            quest.param.next_schedule_step = 1
            quest.param.day = 1
            TheGame:GetGameState():AddScore("PROGRESS", 1)
            do_next_quest_step(quest)
            TheGame:GetGameState():GetCaravan():MoveToLocation(quest:GetCastMember("home"))
            DoAutoSave()

        end,

        restrict_exit = function(quest, location)
            return true
        end,

        get_progression = function(quest)
            local days = {}
            local current_day = {}
            table.insert(days, current_day)
            
            for k, v in ipairs(quest.param.schedule) do
                if v.id == "quest" then
                    table.insert(current_day, {id="QUEST", quest = v.quest} )
                elseif v.id == "sleep" then
                    current_day = {}
                    table.insert(days, current_day)
                elseif v.id == "boss" then
                    table.insert(current_day, {id="BOSS", boss = v.def})
                end
                
                if quest.param.next_schedule_step == k+1 then
                    if current_day[#current_day] then
                        current_day[#current_day].right_now = true
                    end
                end

                if quest.param.quest_results and quest.param.quest_results[k] then
                    if quest.param.quest_results[k] == QSTATUS.COMPLETE then
                        current_day[#current_day].success = true
                    elseif quest.param.quest_results[k] == QSTATUS.FAILED then
                        current_day[#current_day].failed = true
                    end
                end


            end

            return days
        end,

        get_narrative_progress = function(quest)
            local percent = (quest.param.next_schedule_step-1) / #quest.param.schedule
            local title = loc.format(LOC "CALENDAR.DAY_FMT", quest.param.day)
            return percent, title, quest.param.day_quest and quest.param.day_quest:GetTitle() or ""
        end,


        events = {
            quests_changed = function(quest, event_quest) 
                if quest:IsActive("do_job") then
                    if event_quest == quest.param.current_job then
                        
                        if not event_quest:IsActive() then
                            quest.param.quest_results[quest.param.next_schedule_step-1] = event_quest:GetStatus()
                            quest:Cancel("do_job")
                            quest:Activate("return_to_bar")
                        end
                    end
                end
            end           
        },

        GetRandomLocation = function (quest)
            local location = quest:SpawnTempLocation("TEMP_LOCATION")
            local plax_id = fun(BRAWL_LOCATIONS):filter(function(id) return TheGame:GetGameProfile():HasSeenPlax(id) end):randomPick() or "EXT_Forest_1"
            location:SetPlax(plax_id)
            return location
        end

    }
    :AddLocationDefs{
        TEMP_LOCATION = {
            name = "TempLocation",
        },
    }

    :AddCastByAlias{
        cast_id = "bartender",
        alias = data.bartender_alias,
    }

    :AddLocationCast{
        cast_id = "home",
        no_validation = true,
        when = QWHEN.MANUAL,
    }

    :AddCastByAlias{
        cast_id = "plocka",
        alias = "PLOCKA",
    }


    QDEF:AddCastByAlias{
        cast_id = "battle_shop",
        alias = "RAKE",
        on_assign = function(quest, agent)
            quest:GetCastMember("battle_shop"):GainAspect("cardshop"):SetStockID("MURDER_BAY_NIGHT_MARKET_BATTLE")
        end,    
    }

    QDEF:AddCastByAlias{
        cast_id = "coin_trader",
        alias = "COIN_TRADER",
    }


    QDEF:AddCastByAlias{
        cast_id = "pet_shop",
        alias = "BEASTMASTER",
    }

    QDEF:AddCastByAlias{
        cast_id = "negotiation_shop",
        alias = "ENDO",
        on_assign = function(quest, agent)
            quest:GetCastMember("negotiation_shop"):GainAspect("cardshop"):SetStockID("MURDER_BAY_NIGHT_MARKET_NEGOTIATION")
        end,    
    }


    :AddObjective{
        id = "starting",
        title = "Starting out",
        desc = "",
        hide_in_overlay = true,
        --state = QSTATUS.ACTIVE,
    }


    :AddObjective{
        id = "get_healing",
        mark = {"bartender"},
        hide_in_overlay = true,
        state = QSTATUS.ACTIVE,
    }

    :AddObjective{
        id = "do_bonus",
        hide_in_overlay = true,
    }


    :AddObjective{
        id = "do_job",
        hide_in_overlay = true,
    }

    :AddObjective{
        id = "return_to_bar",
        hide_in_overlay = true,
    }


    :AddObjective{
        id = "sleep",
        hide_in_overlay = true,
    }


    :AddObjective{
        id = "pick_job",
        title = "Leave the Bar and Find Work",
        desc = "You need to earn your keep. Pick a job and reap the rewards.",
    }

    :AddObjective{
        id = "graft_sale",
        hide_in_overlay = true,
        mark = {"plocka"},
        
        on_activate = function(quest)
            quest.param.negotiation_grafts = GenerateGrafts(GRAFT_TYPE.NEGOTIATION)
            quest.param.combat_grafts = GenerateGrafts(GRAFT_TYPE.COMBAT)
            quest:GetCastMember("plocka"):MoveToLocation(quest:GetCastMember("home"))
            quest:GetCastMember("plocka"):SetLocationRole(CHARACTER_ROLES.VENDOR)
        end,

        on_deactivate = function(quest)
             quest:GetCastMember("plocka"):MoveToLimbo()
        end,

    }

    :AddObjective{
        id = "battle_sale",
        mark = {"battle_shop"},
        hide_in_overlay = true,
        on_activate = function(quest)
            quest:GetCastMember("battle_shop"):MoveToLocation(quest:GetCastMember("home"))
            quest:GetCastMember("battle_shop"):SetLocationRole(CHARACTER_ROLES.VENDOR)
            quest:GetCastMember("battle_shop"):GetAspect("cardshop"):ForceRestock()
        end,
        
        on_deactivate = function(quest)
             quest:GetCastMember("battle_shop"):MoveToLimbo()
        end,
    }

    :AddObjective{
        id = "coin_trade",
        mark = {"coin_trader"},
        hide_in_overlay = true,
        on_activate = function(quest)
            local COIN_RARITY_TABLE = {
                CARD_RARITY.COMMON,
                CARD_RARITY.UNCOMMON,
                CARD_RARITY.UNCOMMON,
                CARD_RARITY.RARE,
                CARD_RARITY.RARE,
            }

            local trader = quest:GetCastMember("coin_trader")
            if trader and not trader:IsRetired() then
                quest.param.coins = FindCoinGrafts(3, COIN_RARITY_TABLE[math.min(#COIN_RARITY_TABLE, TheGame:GetGameState():GetCurrentBaseDifficulty())])
                trader:MoveToLocation(quest:GetCastMember("home"))
                trader:SetLocationRole(CHARACTER_ROLES.VENDOR)
            end
        end,
        
        on_deactivate = function(quest)
            local trader = quest:GetCastMember("coin_trader")
            if trader and not trader:IsRetired() then
                quest:GetCastMember("coin_trader"):MoveToLimbo()
            end
        end,
    }

    :AddObjective{
        id = "pet_sale",
        mark = {"pet_shop"},
        hide_in_overlay = true,
        on_activate = function(quest)
            quest.param.beasts = GeneratePets()
            quest:GetCastMember("pet_shop"):MoveToLocation(quest:GetCastMember("home"))
            quest:GetCastMember("pet_shop"):SetLocationRole(CHARACTER_ROLES.VENDOR)
        end,
        
        on_deactivate = function(quest)
             quest:GetCastMember("pet_shop"):MoveToLimbo()
        end,
    }

    :AddObjective{
        id = "negotiation_sale",
        mark = {"negotiation_shop"},
        hide_in_overlay = true,
        on_activate = function(quest)
            quest:GetCastMember("negotiation_shop"):MoveToLocation(quest:GetCastMember("home"))
            quest:GetCastMember("negotiation_shop"):SetLocationRole(CHARACTER_ROLES.VENDOR)
            quest:GetCastMember("negotiation_shop"):GetAspect("cardshop"):ForceRestock()
        end,
        
        on_deactivate = function(quest)
             quest:GetCastMember("negotiation_shop"):MoveToLimbo()
        end,
    }


    QDEF:AddConvo("starting")
        :ConfrontState("CONF")
            :Loc{
                DIALOG_INTRO = [[
                    player:
                        !left
                    {player_sal?
                        player:
                            !thought
                        * You've set your mind to revenge...
                    }
                    {player_rook?
                        player:
                            !thought
                        * Your schemes have schemes to hatch...
                    }
                ]],

                DIALOG_INTRO_2 = [[
                    
                    {player_sal?
                        player:
                            !hips
                        agent:
                            !right
                            !happy
                            !point
                            Get out there and get stronger! Kashio is waiting for you!
                    }
                    {player_rook?
                        player: 
                            !crossed
                        agent:
                            !right
                            !point
                            Don't you have anything better to do? Get out there!
                    }
                ]],

                OPT_DO_DRAFT = "Starting Draft",
                OPT_SKIP = "Skip",
                OPT_NEGOTIATION_GRAFT = "Choose a Negotiation Graft",
                OPT_BATTLE_GRAFT = "Choose a Battle Graft"
            }
            :Fn(function(cxt) 
                cxt.quest:Complete("starting")
                TheGame:GetGameState():SetActProgress(cxt.quest.param.day)
                cxt:TalkTo("bartender")
                cxt:Dialog("DIALOG_INTRO")

                local did_draft, took_battle_graft, took_negotiation_graft = false

                cxt:RunLoop(function( ... )
                    if did_draft and took_negotiation_graft and took_battle_graft then
                        cxt:Dialog("DIALOG_INTRO_2")
                        StateGraphUtil.AddEndOption(cxt)
                    else
                        if not did_draft then
                            cxt:Opt("OPT_DO_DRAFT")
                                :Fn(function() 
                                    did_draft = true
                                    local function OnDone()
                                        cxt.encounter:ResumeEncounter()
                                    end
                                    
                                    for i = 1, 2 do
                                        local draft_popup = Screen.DraftChoicePopup()
                                        local cards = RewardUtil.GetBattleCards( 1, 3, cxt.player )
                                        draft_popup:DraftCards( cxt.player, Battle.Card, cards, OnDone )
                                        TheGame:FE():InsertScreen( draft_popup )
                                        cxt.enc:YieldEncounter()
                                    end

                                    for i = 1, 2 do
                                        local draft_popup = Screen.DraftChoicePopup()
                                        local cards = RewardUtil.GetNegotiationCards( 1, 3, cxt.player )
                                        draft_popup:DraftCards( cxt.player, Negotiation.Card, cards, OnDone )
                                        TheGame:FE():InsertScreen( draft_popup )
                                        cxt.enc:YieldEncounter()
                                    end
                                end)
                        end
                        if not took_negotiation_graft then
                            cxt:Opt("OPT_NEGOTIATION_GRAFT")
                                :Fn(function(cxt)
                                    took_negotiation_graft = true
                                    local collection = GraftCollection(function(graft_def) return graft_def.brawl == true and graft_def.type == GRAFT_TYPE.NEGOTIATION end):NotInstalled(cxt.player):NotRestricted(cxt.player)
                                    local grafts = collection:Generate(TheGame:GetGameState():GetGraftDraftDetails().count)
                                    local popup = Screen.PickGraftScreen(grafts, false, function(...) cxt.enc:ResumeEncounter(...) end)
                                    TheGame:FE():InsertScreen( popup )

                                    local chosen_graft = cxt.enc:YieldEncounter()
                                    cxt.player.graft_owner:IncreaseMaxGrafts( GRAFT_TYPE.NEGOTIATION, 1 )
                                end)
                        end
                        if not took_battle_graft then
                            cxt:Opt("OPT_BATTLE_GRAFT")
                                :Fn(function(cxt)
                                    took_battle_graft = true
                                    local collection = GraftCollection(function(graft_def) return graft_def.brawl == true and graft_def.type == GRAFT_TYPE.COMBAT end):NotInstalled(cxt.player):NotRestricted(cxt.player)
                                    local grafts = collection:Generate(TheGame:GetGameState():GetGraftDraftDetails().count)
                                    local popup = Screen.PickGraftScreen(grafts, false, function(...) cxt.enc:ResumeEncounter(...) end)
                                    TheGame:FE():InsertScreen( popup )

                                    local chosen_graft = cxt.enc:YieldEncounter()
                                    cxt.player.graft_owner:IncreaseMaxGrafts( GRAFT_TYPE.COMBAT, 1 )
                                end)
                        end
                        cxt:Opt("OPT_SKIP")
                            :Fn(function() 
                                cxt:Dialog("DIALOG_INTRO_2")
                                StateGraphUtil.AddEndOption(cxt)
                            end)
                    end
                end)

                

            end)




    QDEF:AddAttract("graft_sale", "plocka",
        [[
            agent:
                !cruel
                Need some adjustments?
        ]])


    QDEF:AddConvo("graft_sale", "plocka")
            :Loc{
                OPT_SELL_GRAFT = "Purchase {1#graft}",
                DIALOG_SELL_GRAFT = [[
                    agent:
                        $happyThanks
                        Good choice. You won't regret it.
                ]],
                REQ_FULL = "You have too many grafts of this type",
                OPT_SEE_NEGOTIATION_GRAFTS = "Buy negotiation grafts...",
                OPT_SEE_COMBAT_GRAFTS = "Buy battle grafts...",
                OPT_GET_MORE_SLOTS = "Add more graft slots...",
                DIALOG_GET_MORE_SLOTS = [[
                    agent:
                        I can drill you a new slot, but I'm not going to lie:
                        !interest
                        It's going to hurt like hell.
                ]],
                
                DIALOG_ADD_SLOT_1 = [[
                    agent:
                        This is going to sting a little.
                        !exit
                    player:
                        !exit
                ]],
                DIALOG_ADD_SLOT_2 = [[
                    agent:
                        !right
                    player:
                        !left
                    agent:
                        Good as new!                    

                ]],
            }
            :Hub( function(cxt, who)

                cxt:Opt("OPT_SEE_NEGOTIATION_GRAFTS")
                    :PreIcon( engine.asset.Texture( "UI/ic_graftscompendium.tex"), UICOLOURS.NEGOTIATION )
                    :Fn(PresetGrafts(cxt.quest.param.negotiation_grafts))
                
                cxt:Opt("OPT_SEE_COMBAT_GRAFTS")
                    :PreIcon( engine.asset.Texture( "UI/ic_graftscompendium.tex"), UICOLOURS.FIGHT )
                    :Fn(PresetGrafts(cxt.quest.param.combat_grafts))

                cxt:Opt("OPT_GET_MORE_SLOTS")
                    :PreIcon( engine.asset.Texture( "UI/ic_graftscompendium.tex"), UICOLOURS.OBJECTIVE )
                    :Dialog("DIALOG_GET_MORE_SLOTS")
                    :Fn(function(cxt)

                            ConvoUtil.OptBuyGraftSlot( cxt, GRAFT_TYPE.NEGOTIATION, "DIALOG_ADD_SLOT_1", SLOT_HEALTH, SLOT_COST )
                                :PreIcon( engine.asset.Texture( "UI/ic_graftscompendium.tex"), UICOLOURS.NEGOTIATION )
                                :Dialog( "DIALOG_ADD_SLOT_2" )

                            ConvoUtil.OptBuyGraftSlot( cxt, GRAFT_TYPE.COMBAT, "DIALOG_ADD_SLOT_1", SLOT_HEALTH, SLOT_COST )
                                :PreIcon( engine.asset.Texture( "UI/ic_graftscompendium.tex"), UICOLOURS.FIGHT )
                                :Dialog( "DIALOG_ADD_SLOT_2" )

                            StateGraphUtil.AddBackButton(cxt)  
                        end)
            end )



    QDEF:AddAttract("battle_sale", "battle_shop",
        [[
            agent:
                Today's a good day to fight!
        ]])


    QDEF:AddConvo("battle_sale", "battle_shop")
            :Loc{
                OPT_SHOP = "Buy Battle Cards...",
                DIAL_REMOVE_CARD = [[
                    agent:
                        It's easy to forget!
                ]],
            }
            :Hub( function(cxt, who)
                
                cxt:Opt("OPT_SHOP")
                    :IsHubOption(true)
                    :PreIcon( global_images.shop, UICOLOURS.MONEY_LIGHT )
                    :Fn(function()
                        cxt.enc:WaitOnLine()
                        local screen = Screen.CardShopScreen( cxt:GetAgent(), function() cxt.enc:ResumeEncounter() end )
                        TheGame:FE():InsertScreen( screen )
                        cxt.enc:YieldEncounter()
                    end)

                StateGraphUtil.AddRemoveBattleCardOption( cxt, "DIAL_REMOVE_CARD" )                

            end )



    QDEF:AddAttract("coin_trade", "coin_trader",
        [[
            agent:
                Always looking for a good coin.
        ]])


    QDEF:AddConvo("coin_trade", "coin_trader")
            :Loc{
                OPT_TRADE_COINS = "Trade Coins...",
                DIALOG_NEW_COIN = [[
                    agent:
                        !happy
                        Excellent choice!
                ]],
                DIALOG_NO_COIN = [[
                    agent:
                        !sigh
                        Maybe next time?
                        
                ]]
            }
            :Hub( function(cxt, who)
                
                cxt:Opt("OPT_TRADE_COINS")
                    :PreIcon( global_images.receiving )
                    :Fn(function() 
                        cxt.enc:WaitOnLine()
                        local popup = Screen.PickCoinScreen(cxt.quest.param.coins, false, function(graft) print (graft) cxt.enc:ResumeEncounter(graft) end, true)
                        TheGame:FE():InsertScreen( popup )

                        local chosen_coin = cxt.enc:YieldEncounter()
                        cxt.enc:Wait()
                        if chosen_coin then
                            cxt:Dialog("DIALOG_NEW_COIN", chosen_coin)
                            cxt:GetAgent():MoveToLimbo()
                            cxt.quest:Cancel('coin_trade')
                        else
                            --cxt.enc:Next()
                            cxt:Dialog("DIALOG_NO_COIN")
                        end
                    end)
            end)


    QDEF:AddAttract("negotiation_sale", "negotiation_shop",
        [[
            agent:
                Today's a good day to fight!
        ]])


    QDEF:AddConvo("negotiation_sale", "negotiation_shop")
            :Loc{
                OPT_SHOP = "Buy Negotiation Cards...",
                DIAL_REMOVE_CARD = [[
                    agent:
                        Let Hesh touch your mind...
                ]],
            }
            :Hub( function(cxt, who)
                
                cxt:Opt("OPT_SHOP")
                    :IsHubOption(true)
                    :PreIcon( global_images.shop, UICOLOURS.MONEY_LIGHT )
                    :Fn(function()
                        cxt.enc:WaitOnLine()
                        local screen = Screen.CardShopScreen( cxt:GetAgent(), function() cxt.enc:ResumeEncounter() end )
                        TheGame:FE():InsertScreen( screen )
                        cxt.enc:YieldEncounter()
                    end)

                StateGraphUtil.AddRemoveNegotiationCardOption( cxt, "DIAL_REMOVE_CARD" )                

            end )



    QDEF:AddConvo("pick_job")
        :Loc{
            OPT_FIND_WORK = "Venture forth! {1#quest}",
            OPT_FIGHT_BOSS = "Fight a boss!",
        }
        :Hub_Location( function(cxt)
                        local opt = cxt:Opt(cxt.quest.param.boss_time and "OPT_FIGHT_BOSS" or "OPT_FIND_WORK", cxt.quest.param.current_job) 
                            :Fn(function() 
                                    cxt.quest:Complete('pick_job')
                                    
                                    cxt.quest.param.current_job:VerifyRewards()
                                    cxt.quest.param.current_job:Activate("start")

                                    cxt.quest:Activate('do_job')
                                    cxt:End()
                                    TheGame:GetGameState():GetCaravan():RefreshConfronts()
                                    TheGame:GetGameState():GetCaravan():CheckConfronts()
                                end)
                            :SetQuestMark(cxt.quest.param.current_job)

                        if cxt.quest.param.current_job:GetFocus() == QUEST_FOCUS.NEGOTIATION then
                            opt:PostIcon(global_images.negotiation)
                        elseif cxt.quest.param.current_job:GetFocus() == QUEST_FOCUS.COMBAT then
                            opt:PostIcon(global_images.combat)        
                        elseif cxt.quest.param.current_job:GetFocus() == QUEST_FOCUS.BALANCED then
                            opt:PostIcon(global_images.balanced)        
                        end

                    end)

    QDEF:AddConvo("sleep")
        :Loc{
            OPT_GO_SLEEP = "Go to Sleep",
        }
        :Hub_Location( function(cxt)
                        cxt:Opt("OPT_GO_SLEEP") 
                            :PreIcon(global_images.sleep)
                            :Fn(function() 
                                    cxt:End()
                                    UIHelpers.DoSpecificConvo( cxt.quest:GetCastMember("handler"), "BRAWL_HOME_LOCATION_CONVO", "STATE_SLEEP" ,nil,nil,cxt.quest)
                                end)
                    end)



    QDEF:AddConvo("return_to_bar")
        :ConfrontState("CONF")
            :Fn(function(cxt) 

                for k,v in pairs(VENDOR_DATA) do
                    if cxt.quest:IsActive(v.objective) then
                        cxt.quest:Cancel(v.objective)
                    end
                    
                end

                if not cxt.player.graft_owner:GetGraft( "loyalty" ) then
                    local to_dismiss = {}
                    for k,v in cxt.caravan:Members() do
                        if v:IsHiredMember() then
                            table.insert(to_dismiss, v)
                        end
                    end
                    for k,v in pairs(to_dismiss) do
                        v:Dismiss()
                    end
                end
                
                cxt.quest:Complete("return_to_bar")

                do_next_quest_step(cxt.quest)
                if TheGame:GetGameState():GetGameOver() then
                    cxt:End()
                    return
                end

                cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("home"))
                
                local current_patrons = {}
                for k,v in cxt.quest:GetCastMember("home"):Agents() do
                    if v:GetRoleAtLocation() == CHARACTER_ROLES.PATRON then
                        table.insert(current_patrons, v)
                    end
                end
                LocationUtil.SendPatronsAway(cxt.quest:GetCastMember("home")) 
                cxt.quest:GetCastMember("home"):SetCurrentPatronCapacity() --eh....
                LocationUtil.PopulateLocation(cxt.quest:GetCastMember("home"), function(agent) return not agent:HasQuestMembership() and not table.arrayfind(current_patrons, agent) end)
                DoAutoSave()
            end)



    QDEF:AddConvo("pet_sale", "pet_shop")
            :Loc{
                OPT_BUY_PET = "Buy {1#agent}",
                OPT_HEAL_PET = "Heal {1#agent}",
                REQ_AT_FULL_HEALTH = "Your pet is at full health already",     
                DIALOG_HEAL_PET = [[
                    * {pet} healed for {1} HP.
                ]],
                OPT_UPGRADE_PET = "Upgrade {1#agent}",
                DIALOG_UPGRADE_PET = [[
                    * {pet} upgraded.
                ]],
                OPT_SELL_PET = "Sell {1#agent}",
                DIALOG_SELL_PET = [[
                    agent:
                        !right
                        !happy
                        I'm always looking for spare parts!
                ]],
                DIALOG_BUY_PET = [[
                    player:
                        I'll take {1}!
                ]]

            }    
            :Hub(function(cxt)
                local can_own, reason = cxt.caravan:CanOwnPet()
                for k,v in ipairs(cxt.quest.param.beasts) do
                    local data = PETS[v:GetContentID()]
                    
                    if data then
                        cxt:Opt("OPT_BUY_PET", v)
                            :ReqCondition( can_own, reason )
                            :Dialog("DIALOG_BUY_PET", v)
                            :DeliverMoney(math.round( PET_COST*(data.cost or 1)),{ is_shop = true })
                            :Fn(function() 
                                table.arrayremove(cxt.quest.param.beasts, v)
                                v:Recruit(PARTY_MEMBER_TYPE.CREW)
                            end)
                    end
                end

                local pets = TheGame:GetGameState():GetCaravan():GetPets()
                for k, pet in ipairs (pets) do
                    local DATA = PETS[pet:GetContentID()]
                    
                    local sell_cost = DATA and DATA.cost
                    if not sell_cost then
                        for k,v in pairs(PETS) do
                            if v.upgrade_def == pet:GetContentID() then
                                sell_cost = v.cost*2
                                break
                            end
                        end
                    end

                    if sell_cost then
                        cxt:Opt("OPT_SELL_PET", pet)
                            :Fn(function() 
                                cxt:ReassignCastMember("pet", pet)
                            end)
                            :Dialog("DIALOG_SELL_PET")
                            :ReceiveMoney(math.round( .5*PET_COST*(sell_cost or 1)))
                            :Fn(function() 
                                pet:Dismiss()
                                pet:Retire()
                            end)
                    end

                    local current, max, min = pet.health:Get()
                    cxt:Opt("OPT_HEAL_PET", pet)
                        :Fn(function() 
                            cxt:ReassignCastMember("pet", pet)
                        end)
                        :ReqCondition(pet.health:GetPercent() < 1, "REQ_AT_FULL_HEALTH")
                        :DeliverMoney(math.round(PET_HEAL_COST*(1-pet.health:GetPercent())), { is_shop = true })
                        :Dialog("DIALOG_HEAL_PET", math.round( (1-pet.health:GetPercent())*max))
                        :Fn(function() 
                            pet.health:SetPercent(1)
                        end)

                    if DATA and DATA.upgrade_def then
                        cxt:Opt("OPT_UPGRADE_PET", pet)
                            :PostText("TT_PET_UPGRADE")
                            :Fn(function() 
                                cxt:ReassignCastMember("pet", pet)
                            end)
                            :DeliverMoney(math.round( PET_UPGRADE_COST*(DATA.cost or 1)),{ is_shop = true })
                            :Fn(function() 
                                local upgrade_def = Content.GetCharacterDef( DATA.upgrade_def )
                                    pet:ReinitializeAgent( upgrade_def )
                            end)
                            :Dialog("DIALOG_UPGRADE_PET")
                    end

                end
            end)

    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    QDEF:AddConvo("get_healing", "bartender")
        :Priority(CONVO_PRIORITY_LOW)
        :Loc{
            OPT_BUY_FOOD_FSSH = "Eat one of Fssh's famous Fsshcakes",
            OPT_BUY_FOOD = "Buy some food",
            
            DIALOG_BUY_FOOD = [[
                player:
                    $neutralResigned
                    I'm hurt, {agent}.
                agent:
                    !give
                    $happyGreeting
                    Here. Eat this.
            ]],
            REQ_TOO_FULL = "You have too many {1#card} cards in your deck already!",
            TT_CAKES = "Restore {1} health.\nInsert {2#card} to your battle deck.",
        }

        :Hub( function(cxt, who)
                cxt:Opt(who:GetContentID() == "FSSH" and "OPT_BUY_FOOD_FSSH" or "OPT_BUY_FOOD")
                    :PreIcon( cxt.quest:GetMarkData() )
                    :Dialog( "DIALOG_BUY_FOOD" )
                    :DoEat(FSSHCAKE_COST, FSSHCAKE_HEAL)
            end
        )




    QDEF:AddConvo()
        :Loc{

            OPT_HIRE_MERC = "Hire {agent} for your next job",
            DIALOG_HIRED = [[
                player:
                    !permit
                    $miscAlluring
                    I'm hiring, if you're not afraid of trouble.
            ]],
        }
        :Hub(function(cxt)
            if cxt.quest:IsActive("pick_job") and cxt.location == cxt.quest:GetCastMember("home") and cxt:GetAgent():GetRoleAtLocation() == CHARACTER_ROLES.PATRON and not cxt:GetAgent():HasQuestMembership() then
                local cost = cxt:GetAgent():GetCombatStrength() * 100
                
                cxt:Opt("OPT_HIRE_MERC")
                    :SetQuestMark()
                    :DeliverMoney(cost)
                    :Fn(function(cxt) 
                        cxt:Dialog("DIALOG_HIRED")
                        cxt:GetAgent():Recruit( PARTY_MEMBER_TYPE.HIRED )
                        StateGraphUtil.AddEndOption(cxt)
                    end)
                end
        end)


    QDEF:AddConvo("do_bonus", "bartender")
        :ConfrontState("CONF")
            :Loc(bonus_loc)
            :Loc{
                DIALOG_INTRO = [[
                    * {bartender} pulls you aside.
                    {player_sal?
                        bartender:
                            !happy
                            I've got a little something for you, kid. 
                            Go ahead, pick one:
                    }
                    {player_rook?
                        bartender:
                            !happy
                            I'm contractually obliged to help you out.
                            Don't get used to it.

                    }
                ]],
                OPT_SKIP = "Skip {bartender}'s gift",
                DIALOG_SKIP = [[
                    player:
                        No thanks!
                ]]
            }
            :Fn(function(cxt) 
                cxt.quest:Complete("do_bonus")
                do_next_quest_step(cxt.quest)
                cxt:Dialog("DIALOG_INTRO")

                for k,v in ipairs(cxt.quest.param.bonus_options) do
                    if bonuses[v] and bonuses[v].init then
                        bonuses[v].init(cxt)
                    end
                end

                cxt:RunLoop(function()
                    for k,v in ipairs(cxt.quest.param.bonus_options) do
                        if bonuses[v] and bonuses[v].convo then
                            bonuses[v].convo(cxt)
                        end
                    end

                    cxt:Opt("OPT_SKIP")
                        :Dialog("DIALOG_SKIP")
                        :DoneConvo()
                end)
            end)
    

    return QDEF            
end


return {
    CreateBrawlQuest = CreateBrawlQuest,
    PickQuests = PickQuests,
    PickMerchants = PickMerchants,
    PickBoss = PickBoss,
    base_data = {all_bonuses = all_bonuses},
}
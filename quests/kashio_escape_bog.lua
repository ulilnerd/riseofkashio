-- local brawl = require "content/quests/brawl/brawl_util"
local brawl = require "RISE:quests/kashio_brawl_util"

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

    OPT_GAIN_MAX_HEALTH = "Increase max health by {1}",
    OPT_GAIN_ITEMS = "Get {1#card_list}",
}
local kashio_bonuses = 
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

local all_kashio_bonuses = {}
for k,v in pairs(kashio_bonuses) do
    table.insert(all_kashio_bonuses, k)
end


local data = table.extend(brawl.base_data)
{
    home_loc_name = "Grout Bog",
    home_loc_desc = "Grout Bog Forest",
    home_loc_plax = "EXT_Bog_Forest_01",
    bartender_alias = "SMITH",

    merchant_list = {
        "grafts", "pets", "battle"
    },

    bosses = {
        {"FSSH_PAST"},
        {"FSSH_PAST"},
        {"FSSH_PAST"},
        {"FSSH_PAST"},
        {"BOGGER_BOSS"},
    }
}

data.MakeBrawlSchedule = function(data)

    local all_valid_quests = {}
    for id, def in pairs( Content.GetAllQuests() ) do
        if def.qtype == QTYPE.SIDE and not def:HasTag("manual_spawn") and def:FilterForAct( "SAL_BRAWL" ) and (def.character_specific == nil or table.contains(def.character_specific, "KASHIO_PLAYER")) then
            table.insert(all_valid_quests, def)
        end
    end
    local used_bosses = {}
    local selected_quests = {}

    local day_1_quests = brawl.PickQuests(all_valid_quests, selected_quests, 1, 4, 0, 4)
    -- local day_2_quests = brawl.PickQuests(all_valid_quests, selected_quests, 2, 4, 0, 4)
    -- local day_3_quests = brawl.PickQuests(all_valid_quests, selected_quests, 3, 4, 0, 4)
    -- local day_4_quests = brawl.PickQuests(all_valid_quests, selected_quests, 4, 4, 0, 4)
    -- local day_5_quests = brawl.PickQuests(all_valid_quests, selected_quests, 5, 4, 0, 4)

    local bs = BrawlSchedule()
    bs:SetCurrentHome("home_hq")
    bs:SetDifficulty(1)
        :QuestPhase("starting_kashio")
        :Boss(brawl.PickBoss(data.bosses[1], used_bosses) )
        :Bonus(all_kashio_bonuses, 2)
        :Night()
        :Bonus(all_kashio_bonuses, 2)
        :Sleep()
        :Win()
    return bs.events
end

local QDEF = brawl.CreateBrawlQuest("KASHIO_ESCAPE_BOG", data)

QDEF:AddQuestLocation{
    cast_id = "home_hq",
    name = "Grout Bog",
    desc = "Escape Grout Bog",
    plax = "EXT_BOG_DEEPBOG",
    show_agents = true,
    tags = {"tavern"},
    indoors = true,
    work = 
    {
        bartender = CreateClosedJob( PHASE_MASK_ALL, "Bartender", CHARACTER_ROLES.PROPRIETOR, "GROG_N_DOG_ITEMS"),
    },
    on_assign = function(quest, location)
        AgentUtil.TakeJob(quest:GetCastMember("bartender"), location, "bartender")
    end,

}

:AddObjective{
    id = "starting_kashio",
    title = "Starting out",
    desc = "",
    hide_in_overlay = true,
}

QDEF:AddConvo("starting_kashio")
        :ConfrontState("CONF")
            :Loc{
                DIALOG_INTRO = [[
                    * Kashio makes her way to what it appears to be a pile of metal junk 
                    player:
                        !left
                        Excellent, this will do for the Spark Barons.
                        Time to pay off my debt.
                    agent:
                        !right 
                        !happy
                        Greetings!
                    player:
                        !left
                        !point
                        Who the hell are you?
                    agent:
                        !right
                        !happy
                        I am the strongest Kra'deshi in all of Havaria!
                        RAWR XD fear meme!!
                    player:
                        !left
                        Whatever.
                    * Hanging outside of Smith's pocket, Kashio sees a small bug crawling up the sleeve of his shirt
                ]],
                OPT_DO_DRAFT = "Starting Draft",
                OPT_TRANSFORM = "Obtain {1#card}",
                OPT_SKIP = "Skip",
                OPT_REMOVE_BATTLE_CARDS = "Remove up to 3 Cards"
            }
:Fn(function(cxt) 
    cxt.quest:Complete("starting_kashio")
    TheGame:GetGameState():SetActProgress(cxt.quest.param.day)
    cxt:TalkTo("bartender")
    cxt:Dialog("DIALOG_INTRO")
    
    local did_draft, got_bug, remove_cards = false
    cxt:RunLoop(function( ... )
        if not got_bug then
            cxt:Opt("OPT_TRANSFORM", "transform_bog_one")
                :PreIcon( global_images.buycombat )
                :GainCards{"transform_bog_one"}
                :Fn(function()
                    got_bug = true
                end)
        end

        if not did_draft then
            cxt:Opt("OPT_DO_DRAFT")
                :Fn(function() 
                    did_draft = true
                    local function OnDone()
                        cxt.encounter:ResumeEncounter()
                    end
                    for i = 1, 3 do
                        local draft_popup = Screen.DraftChoicePopup()
                        local cards = RewardUtil.GetBattleCards( 1, 3, cxt.player )
                        draft_popup:DraftCards( cxt.player, Battle.Card, cards, OnDone )
                        TheGame:FE():InsertScreen( draft_popup )
                        cxt.enc:YieldEncounter()
                    end
                end)
        end
        
        if not remove_cards then
            cxt:Opt("OPT_REMOVE_BATTLE_CARDS")
                        :Fn(function() 
                                remove_cards = true
                                for i = 1, 3 do
                                    AgentUtil.RemoveBattleCard( cxt.player, function( card )
                                        cxt.enc:ResumeEncounter( card )
                                    end)
                                    local card = cxt.enc:YieldEncounter()
                                end
                            end)
        end

        cxt:Opt("OPT_SKIP")
            :Fn(function() 
                StateGraphUtil.AddEndOption(cxt)
                end)
    end)
end)



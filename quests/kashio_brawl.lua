local brawl = require "content/quests/brawl/brawl_util"

local patron_weights = {
    ADMIRALTY_PATROL_LEADER = 1,
    WEALTHY_MERCHANT = 1,
    FOREMAN = 1,

    SPARK_BARON_GOON = 1,
    SPARK_BARON_TASKMASTER = 1,
    SPARK_BARON_PROFESSIONAL = 1,

    JAKES_RUNNER = 1,
    JAKES_SMUGGLER = 1,
    JAKES_LIFTER = 1,

    BOGGER_CLOBBER = .5,
    BOGGER_CULTIVATOR = .5,
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
    home_loc_name = "The Last Stand",
    home_loc_desc = "Hebbel's bar",
    home_loc_plax = "INT_Neutral_Bar",
    bartender_alias = "FSSH",

    merchant_list = {
        "grafts", "pets", "battle"
    },

    bosses = {
        {"SPARK_BARON_BOSS", "DRONE_GOON", "HESH_BOSS", "RENTORIAN_BOSS"},
        {"JAKES_ASSASSIN", "JAKES_ASSASSIN2", "FLEAD_QUEEN", "AUTOMECH_BOSS"},
        {"SPARK_SECOND", "RISE_SECOND", "SHROOG", "DRUSK_1"},
        {"MURDER_BAY_BANDIT_CONTACT", "MURDER_BAY_ADMIRALTY_CONTACT"},
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
    local day_2_quests = brawl.PickQuests(all_valid_quests, selected_quests, 2, 4, 0, 4)
    local day_3_quests = brawl.PickQuests(all_valid_quests, selected_quests, 3, 4, 0, 4)
    local day_4_quests = brawl.PickQuests(all_valid_quests, selected_quests, 4, 4, 0, 4)
    local day_5_quests = brawl.PickQuests(all_valid_quests, selected_quests, 5, 4, 0, 4)

    local bs = BrawlSchedule()
    bs:SetCurrentHome("home_hq")
	bs:SetDifficulty(1)
        :Merchants(data.merchant_list)
        :QuestPhase("starting_kashio")
        :Quest(table.remove(day_1_quests))
        :Bonus(all_kashio_bonuses, 2)
        :Quest(table.remove(day_1_quests))
        :QuestPhase("gift_from_fssh1")
        :Night()
        :Merchants(brawl.PickMerchants(data.merchant_list,1))
        :Boss(brawl.PickBoss(data.bosses[1], used_bosses) )
        :QuestPhase("gift_from_fssh1")
        :Quest(table.remove(day_1_quests))
        :Bonus(all_kashio_bonuses, 2)
        :Quest(table.remove(day_1_quests))
        :Boss(brawl.PickBoss(data.bosses[3], used_bosses), true)
        :QuestPhase("gift_from_fssh1")
        :Merchants(brawl.PickMerchants(data.merchant_list,1))
        :Sleep()

    bs:SetDifficulty(2)
        
        :Quest(table.remove(day_2_quests))
        :Bonus(all_kashio_bonuses, 2)
        :Quest(table.remove(day_2_quests))
        :Night()
        :Merchants(brawl.PickMerchants(data.merchant_list,1))
        :Boss(brawl.PickBoss(data.bosses[2], used_bosses))
        :QuestPhase("gift_from_fssh1")
        :Quest(table.remove(day_2_quests))
        :Bonus(all_kashio_bonuses, 2)
        :Quest(table.remove(day_2_quests))
        :Boss(brawl.PickBoss(data.bosses[4], used_bosses))
        :QuestPhase("gift_from_fssh1")
        :Sleep()
        
    bs:SetDifficulty(3)
    :Quest(table.remove(day_3_quests))
    :Bonus(all_kashio_bonuses, 2)
    :Quest(table.remove(day_3_quests))
    :Bonus(all_kashio_bonuses, 2)
    :Quest(table.remove(day_3_quests))
    :Merchants(brawl.PickMerchants(data.merchant_list,2))
    :Boss(brawl.PickBoss(data.bosses[1], used_bosses) )
    :QuestPhase("gift_from_fssh2")
    
    :Night()
    :Quest(table.remove(day_3_quests))
    :Merchants({"coins"})
    :Boss(brawl.PickBoss(data.bosses[3], used_bosses), true)
    :QuestPhase("gift_from_fssh2")
    :Merchants(brawl.PickMerchants(data.merchant_list,2))
    :Sleep()

bs:SetDifficulty(4)
    :Quest(table.remove(day_4_quests))
    :Bonus(all_kashio_bonuses, 2)
    :Quest(table.remove(day_4_quests))
    :Quest(table.remove(day_4_quests))
    :Merchants(brawl.PickMerchants(data.merchant_list,2))
    :Bonus(all_kashio_bonuses, 2)
    :Boss(brawl.PickBoss(data.bosses[2], used_bosses))
    :QuestPhase("gift_from_fssh2")
     
    :Night()
    :Quest(table.remove(day_4_quests))
    :Merchants({"coins"})        
    :Boss(brawl.PickBoss(data.bosses[4], used_bosses), true)
    :QuestPhase("gift_from_fssh2")
    :Merchants(brawl.PickMerchants(data.merchant_list,2))
    :Sleep()

bs:SetDifficulty(5)
    :Quest(table.remove(day_5_quests))
    :Bonus(all_kashio_bonuses, 2)
    :Quest(table.remove(day_5_quests))
    :Merchants(brawl.PickMerchants(data.merchant_list,2))
    :Quest(table.remove(day_5_quests))
    :QuestPhase("gift_from_fssh2")
    
    :Night(3)
    :Quest(table.remove(day_5_quests))
    :Merchants(brawl.PickMerchants(data.merchant_list,2))
    :Boss(brawl.PickBoss( data.bosses[5], used_bosses))
    :Win()

    
    return bs.events
end

local QDEF = brawl.CreateBrawlQuest("KASHIO_BATTLE_BRAWL", data)

QDEF:AddQuestLocation{
    cast_id = "home_hq",
    name = "The Last Stand",
    desc = "Hebbel's bar",
    plax = "INT_Neutral_Bar",
    show_agents = true,
    tags = {"tavern"},
    indoors = true,
    work = 
    {
        bartender = CreateClosedJob( PHASE_MASK_ALL, "Bartender", CHARACTER_ROLES.PROPRIETOR, "GROG_N_DOG_ITEMS"),
    },
    patron_data = {
        num_patrons = 4,
        patron_generator = function(location)
            local def = weightedpick(patron_weights)
            TheGame:GetGameState():AddSkinnedAgent(def):GetBrain():SendToPatronize(location)
        end
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
                    player:
                        !left
						!palm
					* Just another ordinary day working with the Spark Barons.
					** Hello and welcome to the Kashio Battle Brawl Demo.
					** This is a highly work in progress project and nothing in the current build is final.
                    ** So far, the mod has 80+ battle cards that are made purely from curiosity and are not tested to be balanced and the cards may or may not flow well together.  Despite the high battle card count, this mod does not contain a single custom negotiation card.
                    ** As for as the brawl mode goes, it does have negotiation but is unnecessary to complete the brawl (ie, convince patron to help you fight a boss).  I've provided a few of Sal's basic cards to help with that.
                ]],

                DIALOG_INTRO_2 = [[
                    player:
                        !left
                    agent:
                        !right
                        !happy
						!shrug
						I don't know why we were ordered to setup at this bar, but it will do as our base of operations for the time being.
                        !point
                        Time to go {player}, let's run it back.
                ]],
            }
:Fn(function(cxt) 
    cxt.quest:Complete("starting_kashio")
    TheGame:GetGameState():SetActProgress(cxt.quest.param.day)
    cxt:TalkTo("bartender")
    cxt:Dialog("DIALOG_INTRO")

    cxt:RunLoop(function( ... )
            cxt:Dialog("DIALOG_INTRO_2")
            StateGraphUtil.AddEndOption(cxt)
    end)
end)

QDEF:AddObjective{
    id = "gift_from_fssh1",
    desc = "",
    mark = {"bartender"},
    hide_in_overlay = true,
}
local randomCard = math.random(1,6)
QDEF:AddConvo("gift_from_fssh1", "bartender")
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right 
                    Hello Kashio, I've brought you a gift.
                player:
                    !left
                    Thanks Fssh.
            ]],
            OPT_DEFLECT = "Obtain Deflect",
            OPT_FORCE_FIELD = "Obtain Rentorian Force Field",
            OPT_BLEEDING_EDGE = "Obtain Bleeding Edge",
            OPT_ULTIMATE_HUNTER = "Obtain Ultimate Hunter",
            OPT_TAG_TEAM = "Obtain Tag Team",
            OPT_PLEAD = "Obtain Plead for Life",
            OPT_SKIP = "Skip Card"
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            if randomCard == 1 then
            cxt:Opt("OPT_DEFLECT")
                :PreIcon( global_images.buycombat )
                :GainCards{"deflect"}
                :Fn(function(cxt)
                    cxt.quest:Complete("gift_from_fssh1")
                end)
            end
            if randomCard == 2 then
                cxt:Opt("OPT_FORCE_FIELD")
                    :PreIcon( global_images.buycombat )
                    :GainCards{"force_field"}
                    :Fn(function(cxt)
                        cxt.quest:Complete("gift_from_fssh1")
                    end)
                end
            if randomCard == 3 then
                cxt:Opt("OPT_BLEEDING_EDGE")
                    :PreIcon( global_images.buycombat )
                    :GainCards{"bleeding_edge"}
                    :Fn(function(cxt)
                        cxt.quest:Complete("gift_from_fssh1")
                end)
            end
            if randomCard == 4 then
                cxt:Opt("OPT_ULTIMATE_HUNTER")
                    :PreIcon( global_images.buycombat )
                    :GainCards{"ultimate_hunter"}
                    :Fn(function(cxt)
                        cxt.quest:Complete("gift_from_fssh1")
                end)
            end
            if randomCard == 5 then
                cxt:Opt("OPT_TAG_TEAM")
                    :PreIcon( global_images.buycombat )
                    :GainCards{"tag_team"}
                    :Fn(function(cxt)
                        cxt.quest:Complete("gift_from_fssh1")
                end)
            end
            if randomCard == 6 then
                cxt:Opt("OPT_PLEAD")
                    :PreIcon( global_images.buycombat )
                    :GainCards{"fake_surrender"}
                    :Fn(function(cxt)
                        cxt.quest:Complete("gift_from_fssh1")
                end)
            end

            cxt:Opt("OPT_SKIP")
                :Fn(function(cxt)
                    cxt.quest:Complete("gift_from_fssh1")
                    StateGraphUtil.AddEndOption(cxt)
                end)

            StateGraphUtil.AddEndOption(cxt):Fn( function( cxt ) cxt.quest:Complete("gift_from_fssh1" ) end )
        end)

        QDEF:AddObjective{
            id = "gift_from_fssh2",
            desc = "",
            mark = {"bartender"},
            hide_in_overlay = true,
        }
        local randomCard2 = math.random(1,11)
        QDEF:AddConvo("gift_from_fssh2", "bartender")
            :ConfrontState("CONF")
                :Loc{
                    DIALOG_INTRO = [[
                        agent:
                            !right 
                            Hello Kashio, I've brought you a gift.
                        player:
                            !left
                            Thanks Fssh.
                    ]],
                    OPT_BLADE_DANCE = "Obtain Blade Dance",
                    OPT_FLURRY = "Obtain Flurry",
                    OPT_HOLOGRAM_BELT = "Obtain Kashio's Hologram Belt",
                    OPT_THE_CULLING = "Obtain The Culling",
                    OPT_CALL_LUMICYTE = "Obtain Call Lumicyte",

                    OPT_ARMOR_OF_DISEASE = "Obtain Armor of Disease",
                    OPT_CONTAMINATE = "Obtain Contaminate",
                    OPT_EPIDEMIC = "Obtain Epidemic",
                    OPT_INFESTATION = "Obtain Infestation",
                    OPT_PARASITE_INFUSION = "Obtain Parasite Infusion",
                    OPT_REMOTE_PLAGUE = "Obtain Remote Plague",


                    OPT_SKIP = "Skip Card"
                }
                :Fn(function(cxt)
                    cxt:Dialog("DIALOG_INTRO")
        
                    if randomCard2 == 1 then
                    cxt:Opt("OPT_BLADE_DANCE")
                        :PreIcon( global_images.buycombat )
                        :GainCards{"blade_dance"}
                        :Fn(function(cxt)
                            cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
                    if randomCard2 == 2 then
                        cxt:Opt("OPT_FLURRY")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"flurry"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                            end)
                        end
                    if randomCard2 == 3 then
                        cxt:Opt("OPT_HOLOGRAM_BELT")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"hologram_belt"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
                    if randomCard2 == 4 then
                        cxt:Opt("OPT_THE_CULLING")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"the_culling"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
                    if randomCard2 == 5 then
                        cxt:Opt("OPT_CALL_LUMICYTE")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"call_lumicyte"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
                    if randomCard2 == 6 then
                        cxt:Opt("OPT_ARMOR_OF_DISEASE")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"armor_of_disease"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end

                    if randomCard2 == 7 then
                        cxt:Opt("OPT_CONTAMINATE")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"contaminate"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
                    if randomCard2 == 8 then
                        cxt:Opt("OPT_EPIDEMIC")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"epidemic"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
                    if randomCard2 == 9 then
                        cxt:Opt("OPT_INFESTATION")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"infestation"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
                    if randomCard2 == 10 then
                        cxt:Opt("OPT_PARASITE_INFUSION")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"parasite_infusion"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
                    if randomCard2 == 11 then
                        cxt:Opt("OPT_REMOTE_PLAGUE")
                            :PreIcon( global_images.buycombat )
                            :GainCards{"remote_plague"}
                            :Fn(function(cxt)
                                cxt.quest:Complete("gift_from_fssh2")
                        end)
                    end
        
                    cxt:Opt("OPT_SKIP")
                        :Fn(function(cxt)
                            cxt.quest:Complete("gift_from_fssh2")
                            StateGraphUtil.AddEndOption(cxt)
                        end)
        
                    StateGraphUtil.AddEndOption(cxt):Fn( function( cxt ) cxt.quest:Complete("gift_from_fssh2" ) end )
                end)

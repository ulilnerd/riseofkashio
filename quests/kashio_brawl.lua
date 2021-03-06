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
        {"SPARK_BARON_BOSS", "DRONE_GOON", "HESH_BOSS", "RENTORIAN_BOSS", "FSSH_PAST"},
        {"JAKES_ASSASSIN", "JAKES_ASSASSIN2", "FLEAD_QUEEN", "AUTOMECH_BOSS", "FSSH_PAST"},
        {"SPARK_SECOND", "RISE_SECOND", "SHROOG", "DRUSK_1", "FSSH_PAST"},
        {"MURDER_BAY_BANDIT_CONTACT", "MURDER_BAY_ADMIRALTY_CONTACT", "FSSH_PAST"},
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
        :QuestPhase("strange_request")
        :Quest(table.remove(day_1_quests))
        :Bonus(all_kashio_bonuses, 2)
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
					** Welcome to the Kashio Battle Brawl Demo.
					** This is a work in progress project and nothing in the current build is final.
                    ** So far, the mod has 100+ battle cards.  Despite the high battle card count, this mod does not contain a single custom negotiation card.
                    ** As for as the brawl mode, it does have negotiation but is unnecessary to complete the brawl (ie, convince patron to help you fight a boss).  I've provided a few of Sal's cards to help with that.
                ]],

                DIALOG_INTRO_2 = [[
                    player:
                        !left
                    agent:
                        !right
                        !happy
						!shrug
						HQ ordered us to setup here to find that lost technology within the Bog.
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
local giftFssh1 = {"deflect", "force_field", "extreme_focus", "ultimate_hunter", "tag_team", "weapon_swap_proficiency", "massacre", "prepared_circumstances", "bleeding_edge", "grandslam", "feel_what_i_feel"}
local count = 0
for i, card in pairs(giftFssh1) do
    count = count + 1
end
QDEF:AddConvo("gift_from_fssh1", "bartender")
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right 
                    Hello {player}, I've brought you a gift.
                player:
                    !left
                    Thanks Fssh.
            ]],
            OPT_TAKE_CARD = "Obtain {1#card}",
            OPT_SKIP = "Skip Card"
        }
        :Fn(function(cxt) 
            cxt:Dialog("DIALOG_INTRO")
            local randomCard1 = math.random(1,count)
            local randomCard2 = math.random(1,count)
            local randomCard3 = math.random(1,count)

            cxt:Opt("OPT_TAKE_CARD", giftFssh1[randomCard1])
                :PreIcon( global_images.buycombat )
                :GainCards{giftFssh1[randomCard1]}
                :Fn(function(cxt)
                    cxt.quest:Complete("gift_from_fssh1")
                end)
            cxt:Opt("OPT_TAKE_CARD", giftFssh1[randomCard2])
                :PreIcon( global_images.buycombat )
                :GainCards{giftFssh1[randomCard2]}
                :Fn(function(cxt)
                    cxt.quest:Complete("gift_from_fssh1")
                end)
            cxt:Opt("OPT_TAKE_CARD", giftFssh1[randomCard3])
                :PreIcon( global_images.buycombat )
                :GainCards{giftFssh1[randomCard3]}
                :Fn(function(cxt)
                    cxt.quest:Complete("gift_from_fssh1")
                end)
    
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
        local count = 0
        local fsshGift2 = {"blade_dance", "flurry", "hologram_belt", "the_culling", "call_lumicyte", "armor_of_disease", "contaminate", "epidemic", "infestation", "parasite_infusion", "remote_plague", "infinity_blade", "killing_spree", "soul_bound", "strengh_of_one_thousand", "unbreakable"}
        for i, card in pairs(fsshGift2) do
            count = count + 1
        end
        QDEF:AddConvo("gift_from_fssh2", "bartender")
            :ConfrontState("CONF")
                :Loc{
                    DIALOG_INTRO = [[
                        agent:
                            !right 
                            Hello {player}, I've brought you a gift.
                        player:
                            !left
                            Thanks Fssh.
                    ]],
                    OPT_TAKE_CARD = "Obtain {1#card}",
                    OPT_SKIP = "Skip Card"
                }
                :Fn(function(cxt)
                    local randomCard1 = math.random(1,count)
                    local randomCard2 = math.random(1,count)
                    local randomCard3 = math.random(1,count)

                    cxt:Dialog("DIALOG_INTRO")
                    cxt:Opt("OPT_TAKE_CARD", fsshGift2[randomCard1])
                        :PreIcon( global_images.buycombat )
                        :GainCards{fsshGift2[randomCard1]}
                        :Fn(function(cxt)
                            cxt.quest:Complete("gift_from_fssh2")
                        end)
                    cxt:Opt("OPT_TAKE_CARD", fsshGift2[randomCard2])
                        :PreIcon( global_images.buycombat )
                        :GainCards{fsshGift2[randomCard2]}
                        :Fn(function(cxt)
                            cxt.quest:Complete("gift_from_fssh2")
                        end)
                    cxt:Opt("OPT_TAKE_CARD", fsshGift2[randomCard3])
                        :PreIcon( global_images.buycombat )
                        :GainCards{fsshGift2[randomCard3]}
                        :Fn(function(cxt)
                            cxt.quest:Complete("gift_from_fssh2")
                        end)
                   
                    
                    cxt:Opt("OPT_SKIP")
                        :Fn(function(cxt)
                            cxt.quest:Complete("gift_from_fssh2")
                            StateGraphUtil.AddEndOption(cxt)
                        end)
        
                    StateGraphUtil.AddEndOption(cxt):Fn( function( cxt ) cxt.quest:Complete("gift_from_fssh2" ) end )
                end)

                
                QDEF:AddObjective{
                    id = "strange_request",
                    desc = "",
                    mark = {"bartender"},
                    hide_in_overlay = true,
                }
                
                
                local bogCards = {"parasite_infusion", "contaminate", "remote_plague", "epidemic", "armor_of_disease", "infestation", "transform_bog_one"}
                QDEF:AddConvo("strange_request", "bartender")
                    :ConfrontState("CONF")
                        :Loc{
                            DIALOG_INTRO = [[
                                agent:
                                    !right 
                                    Hey {player} I was doing a little snooping around the bar and this shady guy left this at one of the tables. I'm sure you'll have a use for it. 
                                player:
                                    !left
                                    What is it?
                                agent:
                                    !right
                                    Beats me.
                                player:
                                    !left
                                    Only one way to find out.
                            ]],
                            OPT_TRANSFORM = "Obtain {1#card}",
                        
                            OPT_SKIP = "Skip Card"
                        }
                        :Fn(function(cxt)
                            local randomBogCard = math.random(1,7)
                            cxt:Dialog("DIALOG_INTRO")
                            cxt:Opt("OPT_TRANSFORM", bogCards[randomBogCard])
                            :PreIcon( global_images.buycombat )
                            :GainCards{bogCards[randomBogCard]}
                            :Fn(function(cxt)
                                cxt.quest:Complete("strange_request")
                            end)
                            cxt:Opt("OPT_SKIP")
                            :Fn(function(cxt)
                                cxt.quest:Complete("strange_request")
                                StateGraphUtil.AddEndOption(cxt)
                            end)
                        end)
                        
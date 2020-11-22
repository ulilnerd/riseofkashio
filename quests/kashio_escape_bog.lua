-- local brawl = require "content/quests/brawl/brawl_util"
local brawl = require "RISE:quests/kashio_brawl_util"

local data = table.extend(brawl.base_data)
{
    home_loc_name = "Grout Bog",
    home_loc_desc = "Grout Bog Forest",
    home_loc_plax = "EXT_Bog_Forest_01",
    bartender_alias = "ROBOT_BARTENDER",

    merchant_list = {
        "grafts", "pets", "battle"
    },

    bosses = {
        {"FALLON_PAST"},
        {"FSSH_PAST"},
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

    local bs = BrawlSchedule()
    bs:SetCurrentHome("home_hq")
    bs:SetDifficulty(5)
        :QuestPhase("starting_kashio")
        :QuestPhase("backupRise")
        :QuestPhase("riseHub")
        :Boss(brawl.PickBoss(data.bosses[1], used_bosses) ) -- fallon
        :Bonus(data.all_bonuses, 2)
        :Night()
        :Boss(brawl.PickBoss(data.bosses[2], used_bosses) ) -- fssh
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
-- CUSTOM VARIABLES -- 
local backupTaken = false
------------------------

QDEF:AddObjective{
    id = "backupRise",
    desc = "",
    mark = {"riseBackup"},
    hide_in_overlay = true,

    on_activate = function(quest)
        quest:GetCastMember("riseBackup"):MoveToLocation(quest:GetCastMember("home"))
    end,
}
:AddCastByAlias{
    cast_id = "riseBackup",
    alias = "RISE_TURNCOAT_BOSS",
}
QDEF:AddConvo("backupRise", "riseBackup")
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right
                player:
                    !left
                agent:
                    Ma'am, I've rounded up our remaining forces and we're ready to move to the rendezvous.
                player:
                    Excellent
                    !point
                    Move out on my mark.
            ]],
            DIALOG_SKIP = [[
                agent:
                    !right
                player:
                    !left
                player:
                    !point
                    Hold your positions.
                agent:
                   Yes Ma'am.
            ]],
            DIALOG_TAKE_BACKUP = [[
                agent:
                    !right
                player:
                    !left
                player:
                    !point
                    !angry
                    Move your ass soldier!
                agent:
                    Yes Ma'am!
            ]],
            DIALOG_STATUS = [[
                agent:
                    !right
                player:
                    !left
                player:
                    Status report on our allies?
                agent:
                    General Fallon is out in the Bog with our remaining Rise Forces and Liutenant Fssh is being accompanied by the mercenaries we hired for this expedition.
                player:
                    Copy that.
            ]],
            OPT_BACKUP = "Get Backup",
            OPT_SKIP = "Skip Backup",
            OPT_STATUS = "Status Report"
        }
        :Fn(function(cxt) 
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_BACKUP")
                :Dialog("DIALOG_TAKE_BACKUP")
                :PreIcon( engine.asset.Texture( "UI/ic_graftscompendium.tex"), UICOLOURS.NEGOTIATION )
                :Fn(function(cxt)
                    local riseUnits = {"RISE_REBEL", "RISE_PAMPHLETEER", "RISE_RADICAL", "RISE_AUTOMECH", "RISE_REBEL_PROMOTED"}
                    local randomUnit1 = math.random(1,5)
                    local randomUnit2 = math.random(1,4)
                    local randomUnit3 = math.random(1,4)
                    if backupTaken == false then
                        local riseSoldier1 = TheGame:GetGameState():AddAgent(Agent(riseUnits[randomUnit1]))
                        riseSoldier1:Recruit(PARTY_MEMBER_TYPE.CREW)

                        local riseSoldier2 = TheGame:GetGameState():AddAgent(Agent(riseUnits[randomUnit2]))
                        riseSoldier2:Recruit(PARTY_MEMBER_TYPE.CREW)

                        local riseSoldier3 = TheGame:GetGameState():AddAgent(Agent(riseUnits[randomUnit3]))
                        riseSoldier3:Recruit(PARTY_MEMBER_TYPE.CREW)

                        backupTaken = true
                        cxt.quest:Complete("backupRise")
                    end
                end)
            cxt:Opt("OPT_SKIP")
                :Dialog("DIALOG_SKIP")
                :Fn(function() 
                    StateGraphUtil.AddEndOption(cxt):Fn( function( cxt ) cxt.quest:Complete("backupRise" ) end )
                end)
        end)
        

    QDEF:AddObjective{
        id = "riseHub",
        desc = "",
        mark = {"riseBackup"},
        hide_in_overlay = true,
    }
    QDEF:AddConvo("riseHub", "riseBackup")
        :Loc{
            DIALOG_STATUS = [[
                agent:
                    !right
                player:
                    !left
                player:
                    Status report on our allies?
                agent:
                    General Fallon is out in the Bog with our remaining Rise Forces and Liutenant Fssh is being accompanied by the mercenaries we hired for this expedition.
                player:
                    Copy that.
            ]],
            DIALOG_TAKE_BACKUP = [[
                agent:
                    !right
                player:
                    !left
                player:
                    !point
                    !angry
                    Move your ass soldier!
                agent:
                    Yes Ma'am!
            ]],
            OPT_STATUS = "Status Report",
            OPT_BACKUP = "Get Backup",
        }
        :Hub( function(cxt, who)
            cxt:Opt("OPT_STATUS")
                :Dialog("DIALOG_STATUS")
                :Fn(function(cxt) 
                    StateGraphUtil.AddEndOption(cxt)
                end)
            if backupTaken == false then
                cxt:Opt("OPT_BACKUP")
                    :Dialog("DIALOG_TAKE_BACKUP")
                    :PreIcon( engine.asset.Texture( "UI/ic_graftscompendium.tex"), UICOLOURS.NEGOTIATION )
                    :Fn(function(cxt)
                        local riseUnits = {"RISE_REBEL", "RISE_PAMPHLETEER", "RISE_RADICAL", "RISE_AUTOMECH", "RISE_REBEL_PROMOTED"}
                        local randomUnit1 = math.random(1,5)
                        local randomUnit2 = math.random(1,4)
                        local randomUnit3 = math.random(1,4)
                        
                            local riseSoldier1 = TheGame:GetGameState():AddAgent(Agent(riseUnits[randomUnit1]))
                            riseSoldier1:Recruit(PARTY_MEMBER_TYPE.CREW)

                            local riseSoldier2 = TheGame:GetGameState():AddAgent(Agent(riseUnits[randomUnit2]))
                            riseSoldier2:Recruit(PARTY_MEMBER_TYPE.CREW)

                            local riseSoldier3 = TheGame:GetGameState():AddAgent(Agent(riseUnits[randomUnit3]))
                            riseSoldier3:Recruit(PARTY_MEMBER_TYPE.CREW)

                            backupTaken = true
                            cxt.quest:Complete("backupRise")
                        
                    end)
            end
        end)

        
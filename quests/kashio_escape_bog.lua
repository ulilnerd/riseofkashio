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
    bs:SetDifficulty(1)
        :QuestPhase("starting_kashio")
        :Boss(brawl.PickBoss(data.bosses[1], used_bosses) )
        :Bonus(data.all_bonuses, 2)
        :Night()
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
local START_DIFFICULTY =1

local MAX_DIFFICULTY = 1

local DAY_SCHEDULE = {
    {quest = "KASHIO_STORY_DAY_1", difficulty = 1},  
}



local QDEF = QuestDef.Define
{
    title = "Scraping by",
    icon = engine.asset.Texture("icons/quests/rook_story_living_at_bar.tex"),
    qtype = QTYPE.STORY,
    
    on_init = function(quest)
        TheGame:GetGameState():SetMainQuest(quest)
        TheGame:GetGameState():GetCaravan():MoveToLocation(TheGame:GetGameState():GetLocation("GB_NEUTRAL_BAR"))
        TheGame:GetGameState():SetDifficulty(START_DIFFICULTY)
        QuestUtil.StartDayQuests(DAY_SCHEDULE, quest)

        QuestUtil.DoNextDay(DAY_SCHEDULE, quest, quest.param.start_on_day  )
    end,

    max_day = 1,
    on_post_load = function(quest)
        QuestUtil.StartDayQuests(DAY_SCHEDULE, quest)        
    end,

    get_narrative_progress = function(quest)
        
        local total_days = 4
        local completed_days = (quest.param.day or 1)-1
        if quest.param.day_quest == nil then
            return 0, loc.format( LOC "CALENDAR.DAY_FMT", 1 ), ""
        end

        local percent = (completed_days) / total_days
        local title = loc.format(LOC "CALENDAR.DAY_FMT", quest.param.day or 1)
        return percent, title, quest.param.day_quest and quest.param.day_quest:GetTitle() or ""
    end,

    plot_armour_fn = function(quest, agent)
        return agent:IsCastInQuest(quest)
    end,
}

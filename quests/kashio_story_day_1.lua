
local QDEF = QuestDef.Define
{
    title = "Just another day",
    qtype = QTYPE.STORY,
    icon = engine.asset.Texture("icons/quests/rook_story_stepping_in_it.tex"),

    on_start = function(quest)
        quest:Activate("intro_scene")
    end,

    events = 
    {
    },
}

:AddSubQuest{
    id = "intro_scene",
    quest_id = "KASHIO_INTRO",
    on_complete = function(quest)
       quest:Activate("intro_gate")
    end,
}

:AddSubQuest{
    id = "intro_gate",
    quest_id = "KASHIO_TROUBLE_AT_GATE",
    on_complete = function(quest)
       
    end,
}
local filepath = require "util/filepath"

-- OnNewGame is called whenever a new game is started.
local function OnNewGame( mod, game_state )
    -- Require this Mod to be installed to launch this save game.
    if game_state:GetCurrentActID() == "RISE_OF_KASHIO" then
        game_state:RequireMod( mod )
    end
end

local function PostLoad( mod )
    print( "PostLoad", mod.id )
end


-- OnLoad is called on startup after all core game content is loaded.
local function OnLoad( mod )

    ------------------------------------------------------------------------------------------
    -- These additional names are available for randomly generated characters across all campaigns.



    ------------------------------------------------------------------------------------------
    -- Aspects

    require "RISE:kashio_story_locations"

    ------------------------------------------------------------------------------------------
    -- Player backgrounds

    require "RISE:rise_of_kashio"
    
    ------------------------------------------------------------------------------------------
    -- Factions

    ------------------------------------------------------------------------------------------
    -- Codex

    ------------------------------------------------------------------------------------------
    -- Cards / Grafts


    require "RISE:kashio_battle_cards"


    ------------------------------------------------------------------------------------------
    -- Characters
    for k, filepath in ipairs( filepath.list_files( "RISE:characters", "*.lua", true )) do
        filepath = filepath:match( "^(.+)[.]lua$")
        require( filepath )
    end
   
    ------------------------------------------------------------------------------------------
    -- Convos / Quests


    for k, filepath in ipairs( filepath.list_files( "RISE:conversations", "*.lua", true )) do
        filepath = filepath:match( "^(.+)[.]lua$")
        require( filepath )
    end

    for k, filepath in ipairs( filepath.list_files( "RISE:events", "*.lua", true )) do
        filepath = filepath:match( "^(.+)[.]lua$")
        require( filepath )
    end

    for k, filepath in ipairs( filepath.list_files( "RISE:quests", "*.lua", true )) do
        filepath = filepath:match( "^(.+)[.]lua$")
        require( filepath )
    end

   

    ------------------------------------------------------------------------------------------
    -- Locations

 

    return PostLoad
end

return
{
    -- [optional] version is a string specifying the major, minor, and patch version of this mod.
    version = "0.1.1",

    -- Pathnames to files within this mod can be resolved using this alias.
    alias = "RISE",
    
    -- Mod API hooks.
    OnPreLoad = OnPreLoad,
    OnLoad = OnLoad,
    OnNewGame = OnNewGame,
    OnGameStart = OnGameStart,

    -- UI information about this mod.
    title = "Rise of Kashio",

    -- You can embed this mod's descriptive text directly...
    -- description = "Play as Shel and guide her to riches and discover the mysterious Lost Passage!",

    -- or look it up in an external file.
    description_file = "RISE:about.txt",

    -- This preview image is uploaded if this mod is integrated with Steam Workshop.
    previewImagePath = "preview.png",
}

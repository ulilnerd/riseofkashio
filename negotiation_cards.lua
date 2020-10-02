
local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local CARDS =
{
  
}

for i, id, carddef in sorted_pairs( CARDS ) do
    Content.AddNegotiationCard( id, carddef )
end

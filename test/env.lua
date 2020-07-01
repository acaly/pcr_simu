package.path = "./../src/?.lua;" .. package.path
local pcr =
{
	core = require("pcrcore"),
	common = require("pcrcommon"),
	characters = require("pcrcharacters"),
	utils = require("pcrutils"),
}

function pcr.utils.makecharacterstate(character)
	if type(character) == "table" then
		return pcr.core.internal.characterstate(character, 10000, 0, 0, 0, nil, {}, {})
	end
	if pcr.common.emptycharacters[character] == nil then
		print("unknown character name ".. character)
	end
	return pcr.core.internal.characterstate(pcr.common.emptycharacters[character], 10000, 0, 0, 0, nil, {}, {})
end

function pcr.utils.maketeam(characters)
	local t = {}
	if type(characters) == "string" then
		for x in string.gmatch(characters, "[^,]+") do
			table.insert(t, pcr.utils.makecharacterstate(x))
		end
	elseif type(characters) == "table" then
		for _, x in next, characters do
			table.insert(t, pcr.utils.makecharacterstate(x))
		end
	end
	return t
end

function pcr.utils.makebattle(team1, team2)
	return pcr.core.simulation.firstframe(pcr.core.internal.battlestate(0, pcr.utils.maketeam(team1), pcr.utils.maketeam(team2)))
end

return pcr

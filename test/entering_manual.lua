package.path = "./../src/?.lua;" .. package.path
pcr =
{
	core = require("pcrcore"),
	common = require("pcrcommon"),
}

local function getremaining(ch)
	local ret = nil
	if ch.skilldata ~= nil then
		ret = ch.skilldata.remaining
	end
	return ret or 1000
end

local function getglobalremaining(frame)
	local minremaining = -1
	for _, character in next, frame.state.team1 do
		local r = getremaining(character)
		if minremaining < 0 or r < minremaining then minremaining = r end
	end
	for _, character in next, frame.state.team2 do
		local r = getremaining(character)
		if minremaining < 0 or r < minremaining then minremaining = r end
	end
	return minremaining
end

local function printinfo(frame)
	local function width(str, w)
		local ret = str
		while #ret < w do
			ret = ret .. " "
		end
		return ret
	end

	local minremaining = getglobalremaining(frame)
	local function printcharacter(team, character, index)
		if index ~= 1 then team = width("", 5) end
		print(
			team .. "\t" .. 
			width(character.character.name, 10) .. "\t" .. 
			character.pos .. "\t-" .. 
			getremaining(character) - minremaining)
	end

	print("-----")
	for index, character in next, frame.state.team1 do
		printcharacter("ally", character, index)
	end
	for index, character in next, frame.state.team2 do
		printcharacter("enemy", character, index)
	end
	print("-----")
end

local function simulate(team1names, team2names)
	if team2names == nil then team2names = team1names end

	local function characterstate(name)
		if pcr.common.emptycharacters[name] == nil then
			print("unknown character name ".. name)
		end
		return pcr.core.internal.characterstate(pcr.common.emptycharacters[name], 10000, 0, 0, 0, nil, {}, {})
	end
	local function maketeamname(team)
		local ret = ""
		for index, nn in next, team do
			if index ~= 1 then ret = ret .. " " end
			ret = ret .. nn
		end
		return ret
	end

	print("simulate start");
	print("team1: " .. maketeamname(team1names))
	print("team2: " .. maketeamname(team2names))

	local team1 = {}
	for _, nn in next, team1names do
		table.insert(team1, characterstate(nn))
	end
	local team2 = {}
	for _, nn in next, team2names do
		table.insert(team2, characterstate(nn))
	end
	local f0 = pcr.core.simulation.firstframe(pcr.core.internal.battlestate(0, team1, team2))
	local f1000 = pcr.core.simulation.run(f0, nil, 1000)
	printinfo(f1000)
	return f1000
end

local t1 = {}
local t2 = {}

for x in string.gmatch(arg[1], "[^,]+") do
	table.insert(t1, x)
end
for x in string.gmatch(arg[2], "[^,]+") do
	table.insert(t2, x)
end
simulate(t1, t2)

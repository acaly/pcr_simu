package.path = "./../src/?.lua;" .. package.path
pcr =
{
	core = require("pcrcore"),
	common = require("pcrcommon"),
}

local options = {
	showresults = false,
}
for _, aa in next, arg do
	if options[aa] ~= nil then options[aa] = true end
end

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
	if not options.showresults then return end
	
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

local function findinteam(team, id)
	for _, ch in next, team do
		if ch.character.id == id then return ch end
	end
	return nil
end

local function mirrorrelativetime(frame)
	local time = {}
	for _, ch in next, frame.state.team1 do
		time[ch.character.id] = getremaining(ch)
	end
	for _, ch in next, frame.state.team2 do
		time[ch.character.id] = getremaining(ch) - (time[ch.character.id] or 10000)
	end
	return time
end

local function teamtime(frame)
	local g = getglobalremaining(frame)
	local ret = { team1 = {}, team2 = {} }
	for _, ch in next, frame.state.team1 do
		ret.team1[ch.character.id] = getremaining(ch) - g
	end
	for _, ch in next, frame.state.team2 do
		ret.team2[ch.character.id] = getremaining(ch) - g
	end
	return ret
end

local function check(desc, r)
	if _G.failurecount == nil then _G.failurecount = 0 end
	if _G.successcount == nil then _G.successcount = 0 end
	if not r then
		print("FAIL:" .. desc)
		_G.failurecount = _G.failurecount + 1
	else
		_G.successcount = _G.successcount + 1
	end
end

print("test 1: compare rino teams")
print("==========")
do
	local f = simulate({ "lima", "yukari", "saren_summer", "rino", "yuki" }, nil)

	local mirror = mirrorrelativetime(f)
	check("yukari relative time", mirror.yukari == 0)
	check("saren relative time", mirror.saren_summer == -1)
	check("rino relative time", mirror.rino == 0)
	check("yuki relative time", mirror.yuki == 0)

	local team = teamtime(f)
	check("yukari vs saren", team.team1.saren_summer - team.team1.yukari == 1)
end
do
	local f = simulate({ "kokkoro_spring", "yukari", "saren_summer", "rino", "yuki" }, nil)
	local mirror = mirrorrelativetime(f)
	check("rino relative time", mirror.rino == -1)
	--relative time of others not confirmed
end
do
	local f = simulate({ "miyako", "yukari", "mitsuki", "rino", "yuki" }, nil)
	local mirror = mirrorrelativetime(f)
	check("rino relative time", mirror.miyako == 0)
	check("rino relative time", mirror.yukari == -1)
	check("rino relative time", mirror.mitsuki == 0)
	check("rino relative time", mirror.rino == 0)
	check("rino relative time", mirror.yuki == 0)
end
print()

print("test 1 additional: yukari + saren_summer vs karyl")
do
	local f = simulate({ "karyl" }, { "lima", "yukari", "saren_summer" })
	
	local team = teamtime(f)
	check("yukari vs saren", team.team2.saren_summer - team.team2.yukari == 2)
end

--TODO the new algorithm gives error in this test, because it effectively extends both distances by 12
--frame count differences between characters are consistent with experiment
--TODO add frame diff
print("test 2: rino vs kyouka")
print("==========")
do
	local f = simulate({ "lima", "yukari", "mitsuki", "rino", "yuki" },
		{ "nozomi", "makoto", "tamaki", "maho", "kyouka" })
	check("rino attacking", math.abs(findinteam(f.state.team1, "rino").pos - findinteam(f.state.team2, "kyouka").pos) > 1150 + 100)

	local team = teamtime(f)
	check("yukari time", team.team1.yukari == 0)
	check("mitsuki time", team.team1.mitsuki == 1)
	check("rino time", team.team1.rino == 4)
	check("yuki time", team.team1.yuki == 8)
	check("kyouka time", team.team2.kyouka == 31)
end
do
	local f = simulate({ "nozomi", "makoto", "tamaki", "maho", "kyouka" },
		{ "lima", "yukari", "mitsuki", "rino", "yuki" })
	check("rino defending", math.abs(findinteam(f.state.team2, "rino").pos - findinteam(f.state.team1, "kyouka").pos) < 1150 + 100)

	local team = teamtime(f)
	check("yukari time", team.team2.yukari == 0)
	check("mitsuki time", team.team2.mitsuki == 2)
	check("rino time", team.team2.rino == 5)
	check("yuki time", team.team2.yuki == 9)
	check("kyouka time", team.team1.kyouka == 33)
end
print()

print("test 3: kuuka + jun")
print("==========")
do
	local f = simulate({ "kuuka", "jun" }, { "nozomi" })
	check("vs nozomi", findinteam(f.state.team1, "kuuka").pos < findinteam(f.state.team1, "jun").pos)

	local team = teamtime(f)
	check("nozomi time", team.team2.nozomi == 0)
	check("kuuka time", team.team1.kuuka == 2)
	check("jun time", team.team1.jun == 19)
end
do
	local f = simulate({ "kuuka", "jun" }, { "miyako" })
	check("vs miyako", findinteam(f.state.team1, "kuuka").pos > findinteam(f.state.team1, "jun").pos)

	local team = teamtime(f)
	check("miyako time", team.team2.miyako == 0)
	check("kuuka time", team.team1.kuuka == 0)
	check("jun time", team.team1.jun == 15)
end
do
	local f = simulate({ "kuuka", "jun" }, { "lima_only" })
	check("vs miyako", findinteam(f.state.team1, "kuuka").pos > findinteam(f.state.team1, "jun").pos)

	local team = teamtime(f)
	check("lima time", team.team2.lima == 0)
	check("kuuka time", team.team1.kuuka == 0)
	check("jun time", team.team1.jun == 15)
end
print()

print("test 4: yukari + miyako_halloween")
print("==========")
do
	local f = simulate({ "yukari", "miyako_halloween" }, { "lima", "yukari", "miyako_halloween" })

	local mirror = mirrorrelativetime(f)
	check("yukari relative time", mirror.yukari == -1)
	check("saren relative time", mirror.miyako_halloween == 0)

	local team = teamtime(f)
	check("yukari vs miyako", team.team1.miyako_halloween - team.team1.yukari == 0)
end
print()

print("" .. (successcount or 0) .. " successes, " .. (failurecount or 0) .. " failures")
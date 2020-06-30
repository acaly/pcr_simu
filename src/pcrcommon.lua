local core = require("pcrcore")
local common = {}

function common.concatname(name, subname)
	if subname == nil then
		return name
	else
		return name .. "_" .. subname
	end
end

function common.makeemptycharacter(name, attackrange, subname)
	return {
		name = name,
		subname = subname,
		id = common.concatname(name, subname),
		skills = {
			[1] = {
				name = "idle",
				idle = true,
				action = core.common.idleskill(1, attackrange, 12, true),
			},
			[2] = {
				name = "empty",
				idle = false,
				action = core.common.emptyskill(60 * 90), --90 seconds
			}
		},
		initskill = function() return { 1 } end,
		loopskill = function() return { 2 } end,
		order = attackrange,
	}
end

function common.makeemptycharacter_lima(name, attackrange, subname)
	return {
		name = name,
		subname = subname,
		id = common.concatname(name, subname),
		skills = {
			[1] = {
				name = "wait",
				idle = false,
				action = core.common.emptyskill(200), --wait for 200 ticks
			},
			[2] = {
				name = "empty",
				idle = false,
				action = core.common.emptyskill(60 * 90), --90 seconds
			}
		},
		initskill = function() return { 1 } end,
		loopskill = function() return { 2 } end,
		order = attackrange,
	}
end

common.emptycharacters =
{
	lima_only = common.makeemptycharacter("lima", 105),
	lima = common.makeemptycharacter_lima("lima", 105),

	miyako = common.makeemptycharacter("miyako", 125),
	kuuka = common.makeemptycharacter("kuuka", 130),
	jun = common.makeemptycharacter("jun", 135),
	peko = common.makeemptycharacter("peko", 155),
	kokkoro_spring = common.makeemptycharacter("kokkoro", 159, "spring"),
	nozomi = common.makeemptycharacter("nozomi", 160),
	makoto = common.makeemptycharacter("makoto", 165),
	tsumugi = common.makeemptycharacter("tsumugi", 195),
	misogi = common.makeemptycharacter("misogi", 205),
	tamaki = common.makeemptycharacter("tamaki", 215),
	djeeta = common.makeemptycharacter("djeeta", 245),
	yukari = common.makeemptycharacter("yukari", 405),
	nino = common.makeemptycharacter("nino", 415),
	saren = common.makeemptycharacter("saren", 430),
	kokkoro = common.makeemptycharacter("kokkoro", 500),
	rin = common.makeemptycharacter("rin", 550),
	saren_summer = common.makeemptycharacter("saren", 585, "summer"),
	miyako_halloween = common.makeemptycharacter("miyako", 590, "halloween"),
	mitsuki = common.makeemptycharacter("mitsuki", 565),
	rino = common.makeemptycharacter("rino", 700),
	suzuna = common.makeemptycharacter("suzuna", 705),
	io = common.makeemptycharacter("io", 715),
	karyl = common.makeemptycharacter("karyl", 750),
	hatsune = common.makeemptycharacter("hatsune", 755),
	misaki = common.makeemptycharacter("misaki", 760),
	maho = common.makeemptycharacter("maho", 795),
	chika_christmas = common.makeemptycharacter("chika", 77, "christmas"),
	yuki = common.makeemptycharacter("yuki", 805),
	kyouka = common.makeemptycharacter("kyouka", 810),
}

return common

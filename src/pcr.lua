local pcr = {}

pcr.internal = {}

--[[
	character table:
		name: string, for display only
		initskill: a function returning a list of skill index filled initially
		loopskill: a function returning a list of skill index after the initskill
		skills: a list of skill table
		order: equals attack range, except for using 0 for lima
			may be fractional (to give characters with equal attack ranges strict order)
		note that characters with different skills (different stars) should have different character table
	skill table:
		name: string, for display only
		idle: true for idle skill, false otherwise (the system treat idle as a separate skill)
		action: function(battlestate, characterstate), called each frame (the first time skilldata will be nil)
			note that this function should not modify the state but returning a list of events
			the simulation system is responsible to execute them
			currently testidleskill modifies the skilldata table (remaining time), but leaves other changes to events
				probably we can use this convention for all skills
	event table:
		action: function(battlestate, characterstate) that updates the state
		maybe other fields
]]

pcr.internal.teams = {
	{ ally = "team1", enemy = "team2", direction = 1 },
	{ ally = "team2", enemy = "team1", direction = -1 },
}

function pcr.internal.cloneskillidlist(list)
	if list == nil then return nil end
	local ret = {}
	for index, val in next, list do
		ret[index] = val
	end
	return ret
end

function pcr.internal.cloneskilldata(data)
	--simply copy each field
	--we may need more complicated method later (deep copy)
	return pcr.internal.cloneskillidlist(data)
end

function pcr.internal.clonebufflist(data)
	--simply copy each field
	--we may need more complicated method later (deep copy)
	return pcr.internal.cloneskillidlist(data)
end

function pcr.internal.characterstate(character, hp, tp, pos, skillid, skilldata, skilllist, bufflist)
	return {
		character = character, --table
		hp = hp, --int
		tp = tp, --int
		pos = pos, --int
		skillid = skillid, --int, 0 is no skill (simulation system will initialize the next skill in next frame)
		skilldata = skilldata, --skill-defined value (usually a table)
		skilllist = skilllist, -- a list of skills (index) that would start after the current one
		bufflist = bufflist, --not supported yet (TODO need to have a separate clone logic!)
		--TODO other parameters (atk, def, etc.)

		--do not write team (we don't know)
		--it's handled by battle state instead

		clone = function(s)
			return pcr.internal.characterstate(s.character,
				s.hp, s.tp, s.pos, s.skillid,
				pcr.internal.cloneskilldata(s.skilldata),
				pcr.internal.cloneskillidlist(s.skilllist),
				pcr.internal.clonebufflist(s.bufflist))
		end
	}
end

function pcr.internal.cloneteam(team)
	local newteam = {}
	for index, ch in next, team do
		newteam[index] = ch:clone()
	end
	return newteam
end

function pcr.internal.battlestate(time, team1, team2)
	--set labels to help find allies/enemies
	for index, ch in next, team1 do
		ch.team = pcr.internal.teams[1]
	end
	for index, ch in next, team2 do
		ch.team = pcr.internal.teams[2]
	end

	return {
		time = time, --int, frame index starting from 0
		team1 = team1, --a list of characters
		team2 = team2, --a list of characters
		clone = function(s)
			return pcr.internal.battlestate(s.time,
				pcr.internal.cloneteam(s.team1), pcr.internal.cloneteam(s.team2))
		end
	}
end

function pcr.internal.frame(parent, options, state, eventlist)
	return {
		parent = parent, --another frame table
		options = options, --not supported yet
		state = state, --battle state table
		eventlist = eventlist, --a list of events (function that applied to the last battle state)
	}
end

pcr.simulation = {}

function pcr.simulation.firstframe(s)
	--sort characters
	table.sort(s.team1, function(ch1, ch2) return ch1.character.order > ch2.character.order end) --big to small
	table.sort(s.team2, function(ch1, ch2) return ch1.character.order < ch2.character.order end) --small to big

	--set initial position
	for index, ch in next, s.team1 do
		ch.pos = -660 - 200 * (#s.team1 - index)
	end
	for index, ch in next, s.team2 do
		ch.pos = 660 + 200 * (index - 1)
	end

	--set initial skills
	for index, ch in next, s.team1 do
		ch.skillid = 0
		ch.skilllist = ch.character.initskill()
	end
	for index, ch in next, s.team2 do
		ch.skillid = 0
		ch.skilllist = ch.character.initskill()
	end

	return pcr.internal.frame(nil, nil, s, {})
end

function pcr.simulation.makeevents(s) --TODO need options parameter
	local updatecharacter = function(character, battle)
		if character.skillid == 0 then
			--start next skill
			if #character.skilllist == 0 then
				character.skilllist = character.character.loopskill()
			end
			character.skillid = table.remove(character.skilllist, 1)
			character.skilldata = nil
		end
		local skill = character.character.skills[character.skillid]
		return skill.action(battle, character) --call skill action function
	end
	local updateteam = function(team, battle, results)
		--remove dead characters (TODO is it before or after? 2 teams together or separate?)
		local i = 1
		while i <= #team do
			if team[i].hp == 0 then
				table.remove(team, i)
			else
				i = i + 1
			end
		end

		--get a list of events and merge them to results
		for index, character in next, team do
			local newresults = updatecharacter(character, battle)
			for index, newevent in next, newresults do
				newevent.action(battle, character) --execute immediately
				table.insert(results, newevent)
			end
		end
	end

	local r = {}
	updateteam(s.team1, s, r)
	updateteam(s.team2, s, r)
	--according to Xier, Lima is updated separately, but currently I have no evidence

	return r
end

function pcr.simulation.next(frame, options)
	local nextstate = frame.state:clone()
	nextstate.time = nextstate.time + 1
	local events = pcr.simulation.makeevents(nextstate)
	return pcr.internal.frame(frame, options, nextstate, events)
end

function pcr.simulation.run(frame, options, count)
	local result = frame
	for i = 1, count do
		result = pcr.simulation.next(result, options)
	end
	return result
end

--common script

pcr.common = {}
pcr.common.utils = {}

function pcr.common.utils.findnearest(character, team)
	local nearestenemy = nil
	local nearestdist = -1
	for index, enemy in next, team do
		local dd = math.abs(enemy.pos - character.pos)
		if nearestdist < 0 or dd < nearestdist then
			nearestdist = dd
			nearestenemy = enemy
		end
	end
	return nearestenemy, nearestdist
end

function pcr.common.utils.getcharactermovement(character)
	--a tricky way (only idle skill can be considered moving)
	if character.skillid ~= 0 and
			character.character.skills[character.skillid].idle then
		return character.skilldata.movement
	end
	return 0
end

--implementation of empty skill (doing nothing, for testing only)

function pcr.common.emptyskill(totaltime)
	return function(battle, character)
		--init skill data
		if character.skilldata == nil then
			character.skilldata = {
				remaining = totaltime,
			}
		end

		--update counter
		character.skilldata.remaining = character.skilldata.remaining - 1
		if character.skilldata.remaining == 0 then
			character.skillid = 0 --end current skill
		end

		--no event
		return {}
	end
end

--implementation of idle skill (also used when starting the battle)

function pcr.common.idleskill(idletime, attackrange, velocity, checkonce)
	return function(battle, character)
		--init skill data
		if character.skilldata == nil then
			character.skilldata = {
				remaining = idletime,
				firststop = false,
				movement = 0, --will be properly set later
			}
		end

		--determine whether we move (and set movement variable)
		local shouldcheck = not character.skilldata.firststop or not checkonce
		local nearestenemy, nearestdist = pcr.common.utils.findnearest(character, battle[character.team.enemy])
		character.skilldata.movement = 0
		if shouldcheck then
			--TODO > or >= ?
			--TODO parameterize 100
			if nearestdist >= attackrange + 100 then
				character.skilldata.movement = velocity
			else
				--there are 2 places we set first stop, and this is the first
				--the other is in event action function
				character.skilldata.firststop = true
			end
		end

		if character.skilldata.movement == 0 then
			character.skilldata.remaining = character.skilldata.remaining - 1
			if character.skilldata.remaining == 0 then
				character.skillid = 0 --end current skill
			end
			return {}
		else
			return {
				{
					action = function(battle1, character1)
						--TODO Lima can stand within enemies
						--how will this affect move direction?
						character1.pos = character1.pos + character1.team.direction * velocity

						--second stop check
						--here we consider the movement of the target
						local newdist = nearestdist - velocity
						newdist = newdist - pcr.common.utils.getcharactermovement(nearestenemy)

						--TODO < or <=
						if newdist < attackrange + 100 then
							--set to stop but don't modify movement
							character1.skilldata.firststop = true
						end
					end
				}
			}
		end
	end
end

pcr.test = {}

--a simple test

function pcr.test.makeemptycharacter(name, attackrange)
	return {
		name = name,
		skills = {
			[1] = {
				name = "idle",
				idle = true,
				action = pcr.common.idleskill(1, attackrange, 12, true), --idle for 1 frame TODO get the actual number
			},
			[2] = {
				name = "empty",
				idle = false,
				action = pcr.common.emptyskill(60 * 90), --90 seconds
			}
		},
		initskill = function() return { 1 } end,
		loopskill = function() return { 2 } end,
		order = attackrange,
	}
end

function pcr.test.makeemptycharacter_lima(name, attackrange)
	return {
		name = name,
		skills = {
			[1] = {
				name = "empty",
				idle = false,
				action = pcr.common.emptyskill(60 * 90), --90 seconds
			}
		},
		initskill = function() return { 1 } end,
		loopskill = function() return { 1 } end,
		order = attackrange,
	}
end

pcr.test.emptycharacters = {}

pcr.test.emptycharacters.miyako = pcr.test.makeemptycharacter("miyako", 125)
pcr.test.emptycharacters.kuuka = pcr.test.makeemptycharacter("kuuka", 130)
pcr.test.emptycharacters.jun = pcr.test.makeemptycharacter("jun", 135)
pcr.test.emptycharacters.nozomi = pcr.test.makeemptycharacter("nozomi", 160)
pcr.test.emptycharacters.tamaki = pcr.test.makeemptycharacter("tamaki", 215)
pcr.test.emptycharacters.makoto = pcr.test.makeemptycharacter("makoto", 165)
pcr.test.emptycharacters.suzuna = pcr.test.makeemptycharacter("suzuna", 705)
pcr.test.emptycharacters.maho = pcr.test.makeemptycharacter("maho", 795)

pcr.test.emptycharacters.yukari = pcr.test.makeemptycharacter("yukari", 405)
pcr.test.emptycharacters.saren_summer = pcr.test.makeemptycharacter("saren", 585)
pcr.test.emptycharacters.mitsuki = pcr.test.makeemptycharacter("mitsuki", 565)
pcr.test.emptycharacters.rino = pcr.test.makeemptycharacter("rino", 700)

pcr.test.emptycharacters.peko = pcr.test.makeemptycharacter("peko", 155)
pcr.test.emptycharacters.lima_only = pcr.test.makeemptycharacter("lima", 105)
pcr.test.emptycharacters.lima = pcr.test.makeemptycharacter_lima("lima", 105)

pcr.test.emptycharacters.kokkoro_spring = pcr.test.makeemptycharacter("kokkoro", 159)
pcr.test.emptycharacters.yuki = pcr.test.makeemptycharacter("yuki", 805)
pcr.test.emptycharacters.kyouka = pcr.test.makeemptycharacter("kyouka", 810)

pcr.test.emptycharacters.miyako_halloween = pcr.test.makeemptycharacter("miyako", 590)

function pcr.test.characterstate(character)
	return pcr.internal.characterstate(character, 10000, 0, 0, 0, nil, {}, {})
end

function pcr.test.makefirstframe(team1characters, team2characters)
	local team1 = {}
	for index, ch in next, team1characters do
		table.insert(team1, pcr.test.characterstate(ch))
	end

	local team2 = {}
	for index, ch in next, team2characters do
		table.insert(team2, pcr.test.characterstate(ch))
	end

	return pcr.simulation.firstframe(pcr.internal.battlestate(0, team1, team2))
end

return pcr

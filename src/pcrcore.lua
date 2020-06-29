local core = {}

core.internal = {}

--[[
	character table:
		name: string, for display only
		subname: string or nil, for display only
		id: string, used internally to identify different characters in a same team
			within one team id must be unique
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

core.internal.teams = {
	{ ally = "team1", enemy = "team2", direction = 1 },
	{ ally = "team2", enemy = "team1", direction = -1 },
}

function core.internal.cloneskillidlist(list)
	if list == nil then return nil end
	local ret = {}
	for index, val in next, list do
		ret[index] = val
	end
	return ret
end

function core.internal.cloneskilldata(data)
	--simply copy each field
	--we may need more complicated method later (deep copy)
	return core.internal.cloneskillidlist(data)
end

function core.internal.clonebufflist(data)
	--simply copy each field
	--we may need more complicated method later (deep copy)
	return core.internal.cloneskillidlist(data)
end

function core.internal.characterstate(character, hp, tp, pos, skillid, skilldata, skilllist, bufflist)
	return {
		character = character, --table
		hp = hp, --int
		tp = tp, --int
		pos = pos, --int
		skillid = skillid, --int, 0 is no skill (simulation system will initialize the next skill in next frame)
		skilldata = skilldata, --skill-defined value (usually a table)
		skilllist = skilllist, -- a list of skills (index) that would start after the current one
		bufflist = bufflist, --not supported yet
		--TODO other parameters (atk, def, etc.)

		--do not write team (we don't know)
		--it's handled by battle state instead

		clone = function(s)
			return core.internal.characterstate(s.character,
				s.hp, s.tp, s.pos, s.skillid,
				core.internal.cloneskilldata(s.skilldata),
				core.internal.cloneskillidlist(s.skilllist),
				core.internal.clonebufflist(s.bufflist))
		end
	}
end

function core.internal.cloneteam(team)
	local newteam = {}
	for index, ch in next, team do
		newteam[index] = ch:clone()
	end
	return newteam
end

function core.internal.battlestate(time, team1, team2)
	--set labels to help find allies/enemies
	for _, ch in next, team1 do
		ch.team = core.internal.teams[1]
	end
	for _, ch in next, team2 do
		ch.team = core.internal.teams[2]
	end

	return {
		time = time, --int, frame index starting from 0
		team1 = team1, --a list of characters
		team2 = team2, --a list of characters
		clone = function(s)
			return core.internal.battlestate(s.time,
				core.internal.cloneteam(s.team1), core.internal.cloneteam(s.team2))
		end
	}
end

function core.internal.frame(parent, options, state, eventlist)
	return {
		parent = parent, --another frame table
		options = options, --not supported yet
		state = state, --battle state table
		eventlist = eventlist, --a list of events (containing function applied to the last battle state)
	}
end

core.simulation = {}

function core.simulation.firstframe(s)
	--sort characters
	table.sort(s.team1, function(ch1, ch2) return ch1.character.order > ch2.character.order end) --big to small
	table.sort(s.team2, function(ch1, ch2) return ch1.character.order < ch2.character.order end) --small to big
	--TODO need confirmation: according to Xier, team1 should also sort from small to big

	--set initial position
	for index, ch in next, s.team1 do
		ch.pos = -660 - 200 * (#s.team1 - index)
	end
	for index, ch in next, s.team2 do
		ch.pos = 660 + 200 * (index - 1)
	end

	--set initial skills
	for _, ch in next, s.team1 do
		ch.skillid = 0
		ch.skilllist = ch.character.initskill()
	end
	for _, ch in next, s.team2 do
		ch.skillid = 0
		ch.skilllist = ch.character.initskill()
	end

	return core.internal.frame(nil, nil, s, {})
end

function core.simulation.makeevents(s) --TODO need options parameter
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
		for _, character in next, team do
			local newresults = updatecharacter(character, battle)
			for _, newevent in next, newresults do
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

function core.simulation.next(frame, options)
	local nextstate = frame.state:clone()
	nextstate.time = nextstate.time + 1
	local events = core.simulation.makeevents(nextstate)
	return core.internal.frame(frame, options, nextstate, events)
end

function core.simulation.run(frame, options, count)
	local result = frame
	for i = 1, count do
		result = core.simulation.next(result, options)
	end
	return result
end

--common script

core.common = {}
core.common.utils = {}

function core.common.utils.findnearest(character, team)
	local nearestenemy = nil
	local nearestdist = -1
	for _, enemy in next, team do
		local dd = math.abs(enemy.pos - character.pos)
		if nearestdist < 0 or dd < nearestdist then
			nearestdist = dd
			nearestenemy = enemy
		end
	end
	return nearestenemy, nearestdist
end

function core.common.utils.getcharactermovement(character)
	--a tricky way (only idle skill can be considered moving)
	if character.skillid ~= 0 and
			character.character.skills[character.skillid].idle then
		return character.skilldata.movement
	end
	return 0
end

--implementation of empty skill (doing nothing, for testing only)

function core.common.emptyskill(totaltime)
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

function core.common.idleskill(idletime, attackrange, velocity, checkonce)
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
		local nearestenemy, nearestdist = core.common.utils.findnearest(character, battle[character.team.enemy])
		character.skilldata.movement = 0
		if shouldcheck then
			--TODO > or >=
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
						local newdist = nearestdist - velocity * 2

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

return core

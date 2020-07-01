local common = {}

--common script

common.utils = {}

function common.utils.findnearest(character, team)
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

function common.utils.getcharactermovement(character)
	--a tricky way (only idle skill can be considered moving)
	if character.skillid ~= 0 and
			character.character.skills[character.skillid].idle then
		return character.skilldata.movement
	end
	return 0
end

--implementation of empty skill (doing nothing, for testing only)

function common.emptyskill(totaltime)
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

function common.idleskill(idletime, attackrange, velocity, checkonce)
	return function(battle, character)
		--init skill data
		if character.skilldata == nil then
			character.skilldata = {
				remaining = idletime,
				firststop = false,
				movement = 0, --will be properly set later
				--TODO currently this movement variable is never read outside the function
				--maybe we should remove it
			}
		end

		--determine whether we should move (and set movement variable)

		local shouldcheck = not character.skilldata.firststop or not checkonce
		local nearestenemy, nearestdist = common.utils.findnearest(character, battle[character.team.enemy])
		character.skilldata.movement = 0

		--temporary fix: prevent move when checkonce is true
		--TODO need to allow checking
		if not checkonce then
			shouldcheck = false
		end

		if shouldcheck then
			--TODO > or >=
			--TODO parameterize 100
			if nearestdist >= attackrange + 100 then
				character.skilldata.movement = velocity
			else
				--there are 2 places we set first stop, and this is the first
				--the other is in event action function
				character.skilldata.firststop = true
				character.readytime = character.readytime or battle.time
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
							character.readytime = character.readytime or battle.time
						end
					end
				}
			}
		end
	end
end

function common.waitskill(totaltime, attackrange)
	return common.idleskill(totaltime, attackrange, 12, false) --TODO velocity is 7.5?
end

--empty characters

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
				action = common.idleskill(1, attackrange, 12, true),
			},
			[2] = {
				name = "empty",
				idle = false,
				action = common.emptyskill(60 * 90), --90 seconds
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
				action = common.emptyskill(200), --wait for 200 ticks
			},
			[2] = {
				name = "empty",
				idle = false,
				action = common.emptyskill(60 * 90), --90 seconds
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
	eriko = common.makeemptycharacter("eriko", 230),
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

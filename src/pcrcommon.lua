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

function common.utils.anyenemyinrange(character, battle, totaldistance)
	for _, ee in next, battle[character.team.enemy] do
		if math.abs(ee.pos - character.pos) < totaldistance + 100 then
			return true
		end
	end
	return false
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

function common.idleskill(idletime, velocity)
	return function(battle, character)
		--init skill data
		if character.skilldata == nil then
			character.skilldata = {
				remaining = idletime,
				--firststop = false,
				ismoving = false,
			}
		end

		if not character.skilldata.ismoving then
			--only check for starting
			--don't move in this frame
			--TODO need to match frame delay when enemy is killed (between hp -> 0 and ismoving -> true)

			--start check (with extension of last move)
			local checkrange = character.checkrange or 0
			local findenemy = common.utils.anyenemyinrange(character, battle,
				character.character.attackrange + checkrange)

			--set up moving state
			if not findenemy then
				character.skilldata.ismoving = true
				character.checkrange = velocity
			end
			
			--decrement counter
			character.skilldata.remaining = character.skilldata.remaining - 1
			if character.skilldata.remaining == 0 then
				character.skillid = 0 --end current skill
			end

			return {}
		else
			--first check (no extension)
			local firstcheck = common.utils.anyenemyinrange(character, battle,
				character.character.attackrange)
			
			if firstcheck then
				--don't need to move
				--set up stopped state
				character.skilldata.ismoving = false
				character.readytime = character.readytime or battle.time

				--decrement counter
				character.skilldata.remaining = character.skilldata.remaining - 1
				if character.skilldata.remaining == 0 then
					character.skillid = 0 --end current skill
				end

				return {}
			else
				--move
				local moveevent = 
				{
					action = function(battle1, character1)
						character1.pos = character1.pos + character1.team.direction * velocity

						--second check (with extension)
						local secondcheck = common.utils.anyenemyinrange(character1, battle1,
							character1.character.attackrange + character1.checkrange)

						if secondcheck then
							--we should stop here
							character1.skilldata.ismoving = false
							character1.readytime = character1.readytime or battle.time
						end
					end
				}
				return { moveevent }
			end
		end
	end
end

function common.enterskill()
	return common.idleskill(151, 12)
end

function common.waitskill(totaltime)
	return common.idleskill(totaltime, 7.5)
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

		attackrange = attackrange,
		order = attackrange,

		skills = {
			[1] = {
				name = "idle",
				idle = true,
				action = common.idleskill(1, 12, true),
			},
			[2] = {
				name = "empty",
				idle = false,
				action = common.emptyskill(60 * 90), --90 seconds
			}
		},
		initskill = { 1 },
		loopskill = { 2 },
	}
end

function common.makeemptycharacter_lima(name, attackrange, subname)
	return {
		name = name,
		subname = subname,
		id = common.concatname(name, subname),

		attackrange = attackrange,
		order = attackrange,

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
		initskill = { 1 },
		loopskill = { 2 },
	}
end

common.emptycharacters =
{
	lima_only = common.makeemptycharacter("lima", 105),
	lima = common.makeemptycharacter_lima("lima", 105),

	miyako = common.makeemptycharacter("miyako", 125),
	kuuka = common.makeemptycharacter("kuuka", 130),
	jun = common.makeemptycharacter("jun", 135),
	kaori = common.makeemptycharacter("kaori", 145),
	peko = common.makeemptycharacter("peko", 155),
	kokkoro_spring = common.makeemptycharacter("kokkoro", 159, "spring"),
	nozomi = common.makeemptycharacter("nozomi", 160),
	makoto = common.makeemptycharacter("makoto", 165),
	tsumugi = common.makeemptycharacter("tsumugi", 195),
	hiyori = common.makeemptycharacter("hiyori", 200),
	misogi = common.makeemptycharacter("misogi", 205),
	tamaki = common.makeemptycharacter("tamaki", 215),
	eriko = common.makeemptycharacter("eriko", 230),
	djeeta = common.makeemptycharacter("djeeta", 245),
	rei = common.makeemptycharacter("rei", 250),
	yukari = common.makeemptycharacter("yukari", 405),
	monika = common.makeemptycharacter("monika", 410),
	nino = common.makeemptycharacter("nino", 415),
	mifuyu = common.makeemptycharacter("mifuyu", 420),
	illya = common.makeemptycharacter("illya", 425),
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
	chika_christmas = common.makeemptycharacter("chika", 770, "christmas"),
	yuki = common.makeemptycharacter("yuki", 805),
	kyouka = common.makeemptycharacter("kyouka", 810),
}

return common

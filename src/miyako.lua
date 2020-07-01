local common = require("pcrcommon")

local miyako = {}

local function create(skill1level)
	local attackrange = 125 --TODO move attackrange to character table
	return {
		name = "miyako",
		subname = nil,
		id = "miyako",
		skills = {
			[1] = {
				name = "enter",
				idle = true,
				action = common.idleskill(46, attackrange, 12, true),
			},
			[2] = {
				name = "wait_attack",
				idle = true,
				action = common.waitskill(105, attackrange),
			},
			[3] = {
				name = "attack",
				idle = false,
				action = common.emptyskill(91),
			},
			[4] = {
				name = "wait_skill1+",
				idle = true,
				action = common.waitskill(3, attackrange),
			},
			[5] = {
				name = "skill1+",
				idle = false,
				action = common.emptyskill(56 + 180 + math.floor(skill1level * 0.01 * 60)),
			},
			[6] = {
				name = "wait_skill2",
				idle = true,
				action = common.waitskill(19, attackrange),
			},
			[7] = {
				name = "skill2",
				idle = false,
				action = common.emptyskill(187),
			},
		},
		initskill = function() return { 1, 2, 3, 2, 3, 4, 5, 2, 3, 6, 7 } end,
		loopskill = function() return { 2, 3, 2, 3, 4, 5, 6, 7 } end,
		order = attackrange,
	}
end

function miyako.default()
	return create(154)
end

return miyako

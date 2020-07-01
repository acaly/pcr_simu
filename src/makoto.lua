local common = require("pcrcommon")

local makoto = {}

local function create()
	local attackrange = 165 --TODO move attackrange to character table
	return {
		name = "makoto",
		subname = nil,
		id = "makoto",
		skills = {
			[1] = {
				name = "enter",
				idle = true,
				action = common.idleskill(36, attackrange, 12, true),
			},
			[2] = {
				name = "wait_attack",
				idle = true,
				action = common.waitskill(129, attackrange),
			},
			[3] = {
				name = "attack",
				idle = false,
				action = common.emptyskill(68),
			},
			[4] = {
				name = "wait_skill1+",
				idle = true,
				action = common.waitskill(69, attackrange),
			},
			[5] = {
				name = "skill1+",
				idle = false,
				action = common.emptyskill(120),
			},
			[6] = {
				name = "wait_skill2",
				idle = true,
				action = common.waitskill(115, attackrange),
			},
			[7] = {
				name = "skill2",
				idle = false,
				action = common.emptyskill(74),
			},
		},
		initskill = function() return { 1, 6, 7, 4, 5 } end,
		loopskill = function() return { 2, 3, 2, 3, 6, 7, 2, 3, 4, 5 } end,
		order = attackrange,
	}
end

function makoto.default()
	return create()
end

return makoto

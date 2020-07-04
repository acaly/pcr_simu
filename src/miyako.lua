local common = require("pcrcommon")

local miyako = {}

local function create(skill1level)
	return {
		name = "miyako",
		subname = nil,
		id = "miyako",

		attackrange = 125,
		order = 125,
		
		skills = {
			[1] = {
				name = "enter",
				idle = true,
				action = common.enterskill(),
			},
			[2] = {
				name = "wait_attack",
				idle = true,
				action = common.waitskill(1.7),
			},
			[3] = {
				name = "attack",
				idle = false,
				action = common.emptyskill(93),
			},
			[4] = {
				name = "wait_skill1+",
				idle = true,
				action = common.waitskill(0),
			},
			[5] = {
				name = "skill1+",
				idle = false,
				action = common.emptyskill(58 + 180 + math.floor(skill1level * 0.01 * 60)),
			},
			[6] = {
				name = "wait_skill2",
				idle = true,
				action = common.waitskill(0.27),
			},
			[7] = {
				name = "skill2",
				idle = false,
				action = common.emptyskill(189),
			},
		},
		initskill = { 1, 3, 2, 3, 4, 5, 2, 3, 6, 7 },
		loopskill = { 2, 3, 2, 3, 4, 5, 6, 7 },
	}
end

function miyako.default()
	return create(154)
end

return miyako

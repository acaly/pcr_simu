local pcr =
{
	core = require("pcrcore"),
	common = require("pcrcommon"),
}
local miyako = {}

local function create(skill1level)
	local attackrange = 125
	return {
		name = "miyako",
		subname = nil,
		id = "miyako",
		skills = {
			[1] = {
				name = "enter",
				idle = true,
				--46 frames before waiting for the first move
				action = pcr.core.common.idleskill(46, attackrange, 12, true),
			},
			[2] = {
				name = "wait_attack",
				idle = true,
				action = pcr.core.common.idleskill(105, attackrange, 12, false), --TODO speed is 7.5?
			},
			[3] = {
				name = "attack",
				idle = false,
				action = pcr.core.common.emptyskill(91),
			},
			[4] = {
				name = "wait_skill1",
				idle = true,
				action = pcr.core.common.idleskill(3, attackrange, 12, false), --TODO speed is 7.5?
			},
			[5] = {
				name = "skill1",
				idle = false,
				action = pcr.core.common.emptyskill(56 + 180 + math.floor(skill1level * 0.01 * 60)), --level 154
			},
			[6] = {
				name = "wait_skill2",
				idle = true,
				action = pcr.core.common.idleskill(19, attackrange, 12, false), --TODO speed is 7.5?
			},
			[7] = {
				name = "skill2",
				idle = false,
				action = pcr.core.common.emptyskill(187),
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

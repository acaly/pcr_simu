local utils = {}

function utils.getfirstreadytime(battlestate)
	local t = -1
	for _, c in next, battlestate.team1 do
		local readytime = c.readytime or t
		if t < 0 or t > readytime then
			t = readytime
		end
	end
	for _, c in next, battlestate.team2 do
		local readytime = c.readytime or t
		if t < 0 or t > readytime then
			t = readytime
		end
	end
	return t
end

function utils.printinfo(frame)
	local function width(str, w)
		local ret = str
		while #ret < w do
			ret = ret .. " "
		end
		return ret
	end

	local firstreadytime = utils.getfirstreadytime(frame.state)
	local function printcharacter(team, character, index)
		if index ~= 1 then team = width("", 5) end
		if character.readytime == nil then
			print(
				team .. "\t" .. 
				width(character.character.name, 10) .. "\t" .. 
				character.pos .. "\t" .. 
				"nil\tnil")
		else
			print(
				team .. "\t" .. 
				width(character.character.name, 10) .. "\t" .. 
				character.pos .. "\t" .. 
				character.readytime .. "\t-" .. 
				character.readytime - firstreadytime)
		end
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

return utils

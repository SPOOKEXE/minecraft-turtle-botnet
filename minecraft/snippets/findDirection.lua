local turtle
-->> IGNORE ABOVE IN PRODUCTION <<--

local signRotationToAxis = {
	['8'] = 'south',
	['12'] = 'west',
	['0'] = 'north',
	['4'] = 'east',
}

local function findItemSlotsByPattern( pattern )
	local slots = { }
	for index = 1, 16 do
		local data = turtle.getItemDetail( index )
		if data and string.match(data.name, pattern) then
			table.insert(slots, index)
		end
	end
	return slots
end

local function findFacingDirection()
	local signSlots = findItemSlotsByPattern( 'minecraft:(%a+)_sign' )
	if #signSlots == 0 then
		return -1
	end
	-- place a sign down
	turtle.select(signSlots[1])
	turtle.place()
	-- read the sign data
	local _, detail = turtle.inspect()
	-- dig the sign back up
	turtle.dig()
	-- return the direction
	return signRotationToAxis[ tostring(detail.state.rotation) ] or -1
end

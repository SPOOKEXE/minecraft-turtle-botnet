
local turtle
-->> IGNORE ABOVE IN PRODUCTION <<--

local function readInventory()
	local slots = { }
	for index = 1, 16 do
		local data = turtle.getItemDetail( index ) or false
		table.insert(slots, data)
	end
	return slots
end

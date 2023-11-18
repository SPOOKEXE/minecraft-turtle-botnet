
local turtle
-->> IGNORE ABOVE IN PRODUCTION <<--

local function tableFind( array, value )
	for index, item in ipairs(array) do
		if item == value then
			return index
		end
	end
	return nil
end

local function readInventory()
	local slots = { }
	for index = 1, 16 do
		local data = turtle.getItemDetail( index ) or false
		table.insert(slots, data)
	end
	return slots
end

-- returns false if no inventory room
local function getEquippedItems()
	local items = readInventory()
	local index = tableFind(items, false)
	if not index then
		return false
	end

	local equipped = {}
	turtle.select( index )

	turtle.equipLeft()
	table.insert(equipped, turtle.getItemDetail() or false)
	turtle.equipLeft()

	turtle.equipRight()
	table.insert(equipped, turtle.getItemDetail() or false)
	turtle.equipRight()

	return equipped
end


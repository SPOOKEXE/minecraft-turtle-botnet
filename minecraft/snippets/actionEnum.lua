
local turtle
-->> IGNORE ABOVE IN PRODUCTION <<--

local isTurtleBusy = false

local ActionEnum = {
	getInfo = function(...)
		return { }
	end,

	-- Movement actions
	forward = turtle.forward,
	backward = turtle.backward,
	up = turtle.up,
	down = turtle.down,
	turnLeft = turtle.turnLeft,
	turnRight = turtle.turnRight,

	-- World-interaction actions
	attackFront = turtle.attack,
	attackAbove = turtle.attackUp,
	attackBelow = turtle.attackDown,
	digFront = turtle.dig,
	digAbove = turtle.digUp,
	digBelow = turtle.digDown,
	placeFront = turtle.place,
	placeAbove = turtle.placeUp,
	placeBelow = turtle.placeDown,
	detectFront = turtle.detect,
	detectAbove = turtle.detectUp,
	detectBelow = turtle.detectDown,
	inspectFront = turtle.inspect,
	inspectAbove = turtle.inspectUp,
	inspectBelow = turtle.inspectDown,
	compareFront = turtle.compare,
	compareAbove = turtle.compareUp,
	compareBelow = turtle.compareDown,
	dropFront = turtle.drop,
	dropAbove = turtle.dropUp,
	dropBelow = turtle.dropDown,
	suckFront = turtle.suck,
	suckAbove = turtle.suckUp,
	suckBelow = turtle.suckDown,

	-- Inventory management actions
	craftItems = turtle.craft,
	selectSlot = turtle.select,
	getSelectedSlot = turtle.getSelectedSlot,
	getItemCountInSlot = turtle.getItemCount,
	getItemSpaceInSlot = turtle.getItemSpace,
	getItemDetailsInSlot = turtle.getItemDetail,
	equipLeft = turtle.equipLeft,
	equipRight = turtle.equipRight,
	refuel = turtle.refuel,
	getFuelLevel = turtle.getFuelLevel,
	getFuelLimit = turtle.getFuelLimit,
	transferTo = turtle.transferTo,

	-- CUSTOMS
	getDirectionFromSign = findFacingDirection,
	readInventory = readInventory,
	findItemSlotsByPattern = findItemSlotsByPattern,
	getEquippedItems = getEquippedItems,
	procreate = procreate,

	isBusy = function()
		return isTurtleBusy
	end
}

local function parseEnum( enumName, ... )
	if not ActionEnum[ enumName ] then
		return nil
	end
	isTurtleBusy = true
	local returns = { pcall( ActionEnum[ enumName ], ... ) }
	local success = table.remove(returns, 1)
	if not success then print( tostring(returns[1]) ) end
	isTurtleBusy = false
	return table.unpack(returns)
end

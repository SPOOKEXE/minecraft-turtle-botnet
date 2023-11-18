
local turtle
-->> IGNORE ABOVE IN PRODUCTION <<--

local ActionEnum = {
	getInfo = function( )
		return { }
	end,

	-- Movement actions
	forward = function(...)
		return turtle.forward(...)
	end,
	backward = function(...)
		return turtle.backward(...)
	end,
	up = function(...)
		return turtle.up(...)
	end,
	down = function(...)
		return turtle.down(...)
	end,
	turnLeft = function(...)
		return turtle.turnLeft(...)
	end,
	turnRight = function(...)
		return turtle.turnRight(...)
	end,

	-- World-interaction actions
	attackFront = function(...)
		return turtle.attack(...)
	end,
	attackAbove = function(...)
		return turtle.attackUp(...)
	end,
	attackBelow = function(...)
		return turtle.attackDown(...)
	end,
	digFront = function(...)
		return turtle.dig(...)
	end,
	digAbove = function(...)
		return turtle.digUp(...)
	end,
	digBelow = function(...)
		return turtle.digDown(...)
	end,
	placeFront = function(...)
		return turtle.place(...)
	end,
	placeAbove = function(...)
		return turtle.placeUp(...)
	end,
	placeBelow = function(...)
		return turtle.placeDown(...)
	end,
	detectFront = function(...)
		return turtle.detect(...)
	end,
	detectAbove = function(...)
		return turtle.detectUp(...)
	end,
	detectBelow = function(...)
		return turtle.detectDown(...)
	end,
	inspectFront = function(...)
		return turtle.inspect(...)
	end,
	inspectAbove = function(...)
		return turtle.inspectUp(...)
	end,
	inspectBelow = function(...)
		return turtle.inspectDown(...)
	end,
	compareFront = function(...)
		return turtle.compare(...)
	end,
	compareAbove = function(...)
		return turtle.compareUp(...)
	end,
	compareBelow = function(...)
		return turtle.compareDown(...)
	end,
	dropFront = function(...)
		return turtle.drop(...)
	end,
	dropAbove = function(...)
		return turtle.dropUp(...)
	end,
	dropBelow = function(...)
		return turtle.dropDown(...)
	end,
	suckFront = function(...)
		return turtle.suck(...)
	end,
	suckAbove = function(...)
		return turtle.suckUp(...)
	end,
	suckBelow = function(...)
		return turtle.suckDown(...)
	end,

	-- Inventory management actions
	craftItems = function(...)
		return turtle.craft(...)
	end,
	selectSlot = function(...)
		return turtle.select(...)
	end,
	getSelectedSlot = function(...)
		return turtle.getSelectedSlot(...)
	end,
	getItemCountInSlot = function(...)
		return turtle.getItemCount(...)
	end,
	getItemSpaceInSlot = function(...)
		return turtle.getItemSpace(...)
	end,
	getItemDetailsInSlot = function(...)
		return turtle.getItemDetail(...)
	end,
	equipLeft = function(...)
		return turtle.equipLeft(...)
	end,
	equipRight = function(...)
		return turtle.equipRight(...)
	end,
	refuel = function(...)
		return turtle.refuel(...)
	end,
	getFuelLevel = function(...)
		return turtle.getFuelLevel(...)
	end,
	getFuelLimit = function(...)
		return turtle.getFuelLimit(...)
	end,
	transferTo = function(...)
		return turtle.transferTo(...)
	end,
}

local function parseEnum( enumName, ... )
	if ActionEnum[ enumName ] then
		return ActionEnum[ enumName ]( ... )
	end
	return nil
end

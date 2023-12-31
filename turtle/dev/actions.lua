local fs, turtle, peripheral, sleep, http, textutils
-->> IGNORE ABOVE IN PRODUCTION <<--

local SIGN_ROTATION_TO_DIRECTION = { ['8'] = 'south', ['12'] = 'west', ['0'] = 'north', ['4'] = 'east', }

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
	return SIGN_ROTATION_TO_DIRECTION[ tostring(detail.state.rotation) ] or -1
end

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

local function populateDisk()
	assert( fs.isDir('/disk'), "No disk inserted into disk drive." )
	local source = fs.open('startup.lua', 'r').readAll()
	-- create a new startup script inside the turtle that loads the actual turtle brain into the turtle itself
	source = 'local SRC = [===[' .. source .. ']' .. '===]'
	source = source..string.format([[
		file = fs.open('startup.lua', 'w')
		file.write(SRC)
		file.close()
		shell.execute('reboot')
	]], source)
	local file = fs.open('/disk/startup', 'w')
	file.write(source)
	file.close()
end

-- NOTE: make sure to have a pickaxe equipped in left hand
local function procreate( disk_drive_slot, floppy_slot, turtle_slot, fuel_slot )
	-- place the disk drive
	turtle.select(disk_drive_slot)
	turtle.place()
	-- place floppy inside disk drive
	turtle.select(floppy_slot)
	turtle.drop( 1 )
	-- write the turtle source to the disk drive floppy
	populateDisk()
	-- go upward and place new turtle
	turtle.up()
	turtle.select(turtle_slot)
	turtle.place()
	-- give the new turtle some fuel
	turtle.select(fuel_slot)
	turtle.drop(4) -- TODO: check fuel type and give an amount based on that
	-- turn on the turtle and let it load the brain
	peripheral.call('front', 'turnOn')
	peripheral.call('front', 'reboot')
	sleep(2)
	-- go down and pickup the floppy/disk drive
	turtle.down()
	turtle.select(floppy_slot) -- floppy
	turtle.suck(1)
	turtle.select(disk_drive_slot) -- disk drive
	turtle.dig('left')
end

local ActionEnum = {

	getTurtleInfo = function ()
		return {
			selectedSlot = turtle.getSelectedSlot(),
			fuel = turtle.getFuelLevel(),
			inventory = readInventory(),
			equipped = getEquippedItems(),
			direction = findFacingDirection(),
		}
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
}

local function parseEnum( enumName, ... )
	if not ActionEnum[ enumName ] then
		return nil
	end
	local returns = { pcall( ActionEnum[ enumName ], ... ) }
	local success = table.remove(returns, 1)
	if not success then print( tostring(returns[1]) ) end
	return success, table.unpack(returns)
end

local actions = { parseEnum = parseEnum, ActionEnum = ActionEnum }

return actions

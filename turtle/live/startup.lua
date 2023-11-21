
local WEBSOCKET_URL = "127.0.0.1:5757"

local function string_split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

local utility = {}

function utility.RequestSocket( message )
	local socket, errmsg = http.websocket(WEBSOCKET_URL)
	assert( socket, errmsg )
	socket.send( textutils.serialiseJSON(message) )
	local response = socket.receive()
	socket.close()
	return textutils.unserialiseJSON( response )
end

function utility.GetQueuedJobs( turtle_id )
	--[[
		{ success : bool, data : dict | list | None, message : string? }
	]]
	return utility.RequestSocket({
		turtle_id = turtle_id,
		job = 'turtle_get_jobs'
	}).data
end

function utility.ReturnJobResults( turtle_id, values, tracker_id )
	return utility.RequestSocket({
		turtle_id = turtle_id,
		job = 'turtle_set_results',
		data = values,
		tracker_id = tracker_id,
	})
end

function utility.AskForUserInput( prompt, input_validator )
	print(prompt)
	local success, err = input_validator( read() )
	while not success do
		print(err)
		print(prompt)
		success, err = input_validator( read() )
	end
	return err
end

function utility.InitializeTurtle()

	-- ask for user input
	print('Welcome to the HIVE.')
	print("We'll need two pieces of information before continuing.")
	print()

	local function CheckPassedCoordinates( response )
		local splits = string_split(response, ' ')
		if #splits ~= 3 then
			return false, 'Incorrectly entered. Enter as "[X] [Y] [Z]"'
		end
		for _, item in ipairs(splits) do
			if tonumber(item) and (not string.find(item, '.')) and (not string.find(item, 'e')) then
				return false, 'Only whole numbers are allowed as X/Y/Z coordinates.'
			end
		end
		return true, splits
	end

	local function CheckDirectionValue( response )
		local isDirection = response == 'north' or response == 'south' or response == 'west' or response == 'east'
		return isDirection, isDirection and response or 'Invalid direction value; must be one of "north", "south", "east" or "west".'
	end

	print('What is the X/Y/Z coordinate of the TURTLE block?')
	print('Enter in the following format: "[X] [Y] [Z]" where there are spaces inbetween the integers.')
	local xyz_coords = utility.AskForUserInput('>', CheckPassedCoordinates )

	print('What is the direction the turtle facing?')
	print('The direction can be: "north", "south", "east" or "west".')
	local direction = utility.AskForUserInput('>', CheckDirectionValue )

	-- if turtle already has an id
	--[[if fs.exists('tid') then
		local file = fs.open('tid', 'r')
		local tid = file.read()
		file.close()
		return tid
	end]]

	-- turtle does not exist, request for an id
	local response = utility.RequestSocket({ job = 'create_turtle', xyz = xyz_coords, direction = direction })
	print( textutils.serialiseJSON(response) )
	local tid = response['data']
	assert( type(tid) == "string", "Could not get turtle id from server." )
	-- store for when turtle restarts
	local file = fs.open('tid', 'w')
	file.write(tid)
	file.close()
	return tid
end

--------------================================================

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

--------------================================================

local turtle_id = utility.InitializeTurtle()

while true do
	-- get queued jobs
	local queued_jobs = utility.GetQueuedJobs(turtle_id)
	if queued_jobs == nil or queued_jobs.success == false then
		print('Server errored - killed turtle.')
		break
	end

	local tracker_id = queued_jobs['tracker_id']
	local jobs_list = queued_jobs['data']
	--[[
		{ success : bool, data : dict | list | None, message : string?, tracker_id : string? }
	]]

	-- execute and prepare results
	local jobs_results = { }
	for _, jobEnum in ipairs( jobs_list ) do
		local success, results = actions.parseEnum( table.unpack(jobEnum) ) -- job and arguments passed in
		if not success then
			break -- if len(results) ~= len(jobs) -> something was not successful, end early.
		end
		table.insert(jobs_results, results)
	end

	-- send back to the server
	local _ = utility.ReturnJobResults(turtle_id, jobs_results, tracker_id)
end

local fs, turtle, peripheral, sleep, http, textutils
-->> IGNORE ABOVE IN PRODUCTION <<--

local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}

local function isArray(t)
	local max = 0
	for k,v in pairs(t) do
		if type(k) ~= "number" then
			return false
		elseif k > max then
			max = k
		end
	end
	return max == #t
end

local whites = {['\n']=true; ['\r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
local function removeWhite(str)
	while whites[str:sub(1, 1)] do
		str = str:sub(2)
	end
	return str
end

local function encodeCommon(val, pretty, tabLevel, tTracking)
	local str = ""
	-- Tabbing util
	local function tab(s)
		str = str .. ("\t"):rep(tabLevel) .. s
	end
	local function arrEncoding(val, bracket, closeBracket, iterator, loopFunc)
		str = str .. bracket
		if pretty then
			str = str .. "\n"
			tabLevel = tabLevel + 1
		end
		for k,v in iterator(val) do
			tab("")
			loopFunc(k,v)
			str = str .. ","
			if pretty then str = str .. "\n" end
		end
		if pretty then
			tabLevel = tabLevel - 1
		end
		if str:sub(-2) == ",\n" then
			str = str:sub(1, -3) .. "\n"
		elseif str:sub(-1) == "," then
			str = str:sub(1, -2)
		end
		tab(closeBracket)
	end
	-- Table encoding
	if type(val) == "table" then
		assert(not tTracking[val], "Cannot encode a table holding itself recursively")
		tTracking[val] = true
		if isArray(val) then
			arrEncoding(val, "[", "]", ipairs, function(k,v)
				str = str .. encodeCommon(v, pretty, tabLevel, tTracking)
			end)
		else
			arrEncoding(val, "{", "}", pairs, function(k,v)
				assert(type(k) == "string", "JSON object keys must be strings", 2)
				str = str .. encodeCommon(k, pretty, tabLevel, tTracking)
				str = str .. (pretty and ": " or ":") .. encodeCommon(v, pretty, tabLevel, tTracking)
			end)
		end
	-- String encoding
	elseif type(val) == "string" then
		str = '"' .. val:gsub("[%c\"\\]", controls) .. '"'
	-- Number encoding
	elseif type(val) == "number" or type(val) == "boolean" then
		str = tostring(val)
	else
		error("JSON only supports arrays, objects, numbers, booleans, and strings", 2)
	end
	return str
end

local function encode(val)
	return encodeCommon(val, false, 0, {})
end

local function encodePretty(val)
	return encodeCommon(val, true, 0, {})
end

local decodeControls = {}
for k,v in pairs(controls) do
	decodeControls[v] = k
end

local function parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, removeWhite(str:sub(5))
	else
		return false, removeWhite(str:sub(6))
	end
end

local function parseNull(str)
	return nil, removeWhite(str:sub(5))
end

local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
local function parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = removeWhite(str:sub(i))
	return val, str
end

local function parseString(str)
	str = str:sub(2)
	local s = ""
	while str:sub(1,1) ~= "\"" do
		local next = str:sub(1,1)
		str = str:sub(2)
		assert(next ~= "\n", "Unclosed string")
		if next == "\\" then
			local escape = str:sub(1,1)
			str = str:sub(2)
			next = assert(decodeControls[next..escape], "Invalid escape character")
		end
		s = s .. next
	end
	return s, removeWhite(str:sub(2))
end

local function parseArray(str)
	str = removeWhite(str:sub(2))
	local val = {}
	local i = 1
	while str:sub(1, 1) ~= "]" do
		local v = nil
		v, str = parseValue(str)
		val[i] = v
		i = i + 1
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))
	return val, str
end

function parseObject(str)
	str = removeWhite(str:sub(2))
	local val = {}
	while str:sub(1, 1) ~= "}" do
		local k, v = nil, nil
		k, v, str = parseMember(str)
		val[k] = v
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))
	return val, str
end

function parseMember(str)
	local k = nil
	k, str = parseValue(str)
	local val = nil
	val, str = parseValue(str)
	return k, val, str
end

function parseValue(str)
	local fchar = str:sub(1, 1)
	if fchar == "{" then
		return parseObject(str)
	elseif fchar == "[" then
		return parseArray(str)
	elseif tonumber(fchar) ~= nil or numChars[fchar] then
		return parseNumber(str)
	elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
		return parseBoolean(str)
	elseif fchar == "\"" then
		return parseString(str)
	elseif str:sub(1, 4) == "null" then
		return parseNull(str)
	end
	return nil
end

local function decode(str)
	str = removeWhite(str)
	local t = parseValue(str)
	return t
end

local json = { encode = encode, decode = decode, encodePretty = encodePretty }

-- ================================== --

local signRotationToAxis = {
	['8'] = 'south',
	['12'] = 'west',
	['0'] = 'north',
	['4'] = 'east',
}

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
	return signRotationToAxis[ tostring(detail.state.rotation) ] or -1
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
	end,
}

local function parseEnum( enumName, ... )
	if ActionEnum[ enumName ] then
		isTurtleBusy = true

		local returns = { pcall( ActionEnum[ enumName ], ... ) }
		local success = table.remove(returns, 1)
		if not success then
			print( tostring(returns[1]) )
		end

		isTurtleBusy = false
		return table.unpack(returns)
	end
	return nil
end

-- ============= --

local SocketJobs = { turtle_get_jobs = 'turtle_get_jobs', turtle_send_results = 'turtle_send_results' }

local function SendAndReceive( message )
	local socket, errmsg = http.websocket("127.0.0.1:5757")
	assert( socket, errmsg )

	socket.send( message )
	local response = socket.receive()
	socket.close()
	return json.decode( response )
end

print("Turtle Started!")
print("Requesting Command-and-Control-Center")

local query = encode({job = 'turtle_create'})
local response = SendAndReceive( query )
assert( response, 'Failed to generate a unique turtle id.' )

local turtle_id = response['message']
print("Turtle Unique ID: ", turtle_id)

print("Starting Core Loop")
while true do
	query = encode({ turtle_id = turtle_id, job = SocketJobs.turtle_get_jobs })

	response = SendAndReceive( query )
	if not response then
		print( tostring(response or 'No values were returned.') )
		break
	end

	print( textutils.serialise(response) )
	sleep(1)

	if response['success'] == false then
		print('Request failed due to an error:')
		print( response['message'] )
	end

	local results = {}
	if response['jobs'] then
		for _, jobItem in ipairs( response['jobs'] ) do
			if jobItem == 'close' then
				break
			end
			print( textutils.serialise(jobItem) )
			local result = { parseEnum(table.unpack(jobItem)) }
			table.insert(results, result)
		end
		query = encode({ turtle_id = turtle_id, job = SocketJobs.turtle_send_results, results = results })
		SendAndReceive(query)
	end
	sleep(1)
end

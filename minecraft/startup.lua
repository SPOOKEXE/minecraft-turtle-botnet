local fs, turtle, peripheral, sleep, http, textutils
-->> IGNORE ABOVE IN PRODUCTION <<--

local json = { null = {} }

local function kind_of(obj)
	if type(obj) ~= 'table' then return type(obj) end
	local i = 1
	for _ in pairs(obj) do if obj[i] ~= nil then i = i + 1 else return 'table' end end
	if i == 1 then return 'table' else return 'array' end
end

local function escape_str(s)
	local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
	local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
	for i, c in ipairs(in_char) do s = s:gsub(c, '\\' .. out_char[i]) end
	return s
end

local function skip_delim(str, pos, delim, err_if_missing)
	pos = pos + #str:match('^%s*', pos)
	if str:sub(pos, pos) ~= delim then
		if err_if_missing then error('Expected ' .. delim .. ' near position ' .. pos) end
		return pos, false
	end
	return pos + 1, true
end

local function parse_str_val(str, pos, val)
	val = val or ''
	local early_end_error = 'End of input found while parsing string.'
	if pos > #str then error(early_end_error) end
	local c = str:sub(pos, pos)
	if c == '"'  then return val, pos + 1 end
	if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
	local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
	local nextc = str:sub(pos + 1, pos + 1)
	if not nextc then error(early_end_error) end
	return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

local function parse_num_val(str, pos)
	local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
	local val = tonumber(num_str)
	if not val then error('Error parsing number at position ' .. pos .. '.') end
	return val, pos + #num_str
end

function json.stringify(obj, as_key)
	local s = {}  -- We'll build the string as an array of strings to be concatenated.
	local kind = kind_of(obj)  -- This is 'array' if it's an array or type(obj) otherwise.
	if kind == 'array' then
		if as_key then error('Can\'t encode array as key.') end
		s[#s + 1] = '['
		for i, val in ipairs(obj) do
		if i > 1 then s[#s + 1] = ', ' end
		s[#s + 1] = json.stringify(val)
		end
		s[#s + 1] = ']'
	elseif kind == 'table' then
		if as_key then error('Can\'t encode table as key.') end
		s[#s + 1] = '{'
		for k, v in pairs(obj) do
		if #s > 1 then s[#s + 1] = ', ' end
		s[#s + 1] = json.stringify(k, true)
		s[#s + 1] = ':'
		s[#s + 1] = json.stringify(v)
		end
		s[#s + 1] = '}'
	elseif kind == 'string' then
		return '"' .. escape_str(obj) .. '"'
	elseif kind == 'number' then
		if as_key then return '"' .. tostring(obj) .. '"' end
		return tostring(obj)
	elseif kind == 'boolean' then
		return tostring(obj)
	elseif kind == 'nil' then
		return 'null'
	else
		error('Unjsonifiable type: ' .. kind .. '.')
	end
	return table.concat(s)
end

function json.parse(str, pos, end_delim)
	pos = pos or 1
	if pos > #str then error('Reached unexpected end of input.') end
	local pos = pos + #str:match('^%s*', pos)  -- Skip whitespace.
	local first = str:sub(pos, pos)
	if first == '{' then  -- Parse an object.
		local obj, key, delim_found = {}, true, true
		pos = pos + 1
		while true do
			key, pos = json.parse(str, pos, '}')
			if key == nil then return obj, pos end
			if not delim_found then error('Comma missing between object items.') end
			pos = skip_delim(str, pos, ':', true)  -- true -> error if missing.
			obj[key], pos = json.parse(str, pos)
			pos, delim_found = skip_delim(str, pos, ',')
		end
	elseif first == '[' then  -- Parse an array.
		local arr, val, delim_found = {}, true, true
		pos = pos + 1
		while true do
			val, pos = json.parse(str, pos, ']')
			if val == nil then return arr, pos end
			if not delim_found then error('Comma missing between array items.') end
			arr[#arr + 1] = val
			pos, delim_found = skip_delim(str, pos, ',')
		end
	elseif first == '"' then
		return parse_str_val(str, pos + 1)
	elseif first == '-' or first:match('%d') then
		return parse_num_val(str, pos)
	elseif first == end_delim then
		return nil, pos + 1
	else
		local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
		for lit_str, lit_val in pairs(literals) do
			local lit_end = pos + #lit_str - 1
			if str:sub(pos, lit_end) == lit_str then return lit_val, lit_end + 1 end
		end
		local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
		error('Invalid json syntax starting at ' .. pos_info_str)
	end
end

-- ================================== --

local signRotationToAxis = { ['8'] = 'south', ['12'] = 'west', ['0'] = 'north', ['4'] = 'east', }

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
	getInfo = function(...) return { } end,
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

-- ============= --

local SocketJobs = { turtle_get_jobs = 'turtle_get_jobs', turtle_send_results = 'turtle_send_results' }

local function SendAndReceive( message )
	local socket, errmsg = http.websocket("127.0.0.1:5757")
	assert( socket, errmsg )
	socket.send( message )
	local response = socket.receive()
	socket.close()
	return json.parse( response )
end

print("Turtle Started!")
print("Requesting Command-and-Control-Center")

local query = json.stringify({job = 'turtle_create'})
local response = SendAndReceive( query )
assert( response, 'Failed to generate a unique turtle id.' )

local turtle_id = response['message']
print("Turtle Unique ID: ", turtle_id)

print("Starting Core Loop")
while true do
	query = json.stringify({ turtle_id = turtle_id, job = SocketJobs.turtle_get_jobs })
	response = SendAndReceive( query )
	if not response then
		print( tostring(response or 'No values were returned.') )
		break
	end
	print( textutils.serialise(response) )
	sleep(0.2)
	if response['success'] == false then
		print('Request failed due to an error:')
		print( response['message'] )
	end
	local results = {}
	if response['jobs'] then
		for _, jobItem in ipairs( response['jobs'] ) do
			if jobItem == 'close' then break end
			-- print( textutils.serialise(jobItem) )
			local result = { parseEnum(table.unpack(jobItem)) }
			table.insert(results, result)
		end
		query = json.stringify({ turtle_id = turtle_id, job = SocketJobs.turtle_send_results, results = results })
		SendAndReceive(query)
	end
	sleep(0.2)
end

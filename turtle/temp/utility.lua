
local fs, turtle, peripheral, sleep, http, textutils, read

-->> IGNORE ABOVE IN PRODUCTION <<--

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

-- // utility // --
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
	if tracker_id == 'none' then
		tracker_id = nil
	end
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
	print('Make sure to have a COAL BLOCK and a CRAFT TABLE inside the turtle before continuing.')
	read() -- wait for user input
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

return utility

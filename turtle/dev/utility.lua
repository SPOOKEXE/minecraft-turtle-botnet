
local fs, turtle, peripheral, sleep, http, textutils
-->> IGNORE ABOVE IN PRODUCTION <<--

local WEBSOCKET_URL = "127.0.0.1:5757"

-- // Module // --
local Module = {}

function Module.RequestSocket( message )
	local socket, errmsg = http.websocket(WEBSOCKET_URL)
	assert( socket, errmsg )
	socket.send( textutils.serialiseJSON(message) )
	local response = socket.receive()
	socket.close()
	return textutils.unserialiseJSON( response )
end

function Module.GetQueuedJobs( turtle_id )
	--[[
		{ success : bool, data : dict | list | None, message : string? }
	]]
	return Module.RequestSocket({
		turtle_id = turtle_id,
		job = 'get_jobs'
	}).data
end

function Module.ReturnJobResults( turtle_id, values, tracker_id )
	return Module.RequestSocket({
		turtle_id = turtle_id,
		job = 'send_results',
		data = values,
		tracker_id = tracker_id,
	})
end

function Module.InitializeTurtle()
	-- if turtle already has an id
	if fs.exists('tid') then
		local file = fs.open('tid', 'r')
		local tid = file.read()
		file.close()
		return tid
	end
	-- turtle does not exist, request for an id
	local response = Module.RequestSocket({ job = 'create_turtle' })
	local tid = response['data']
	assert( type(tid) == "string", "Could not get turtle id from server." )
	-- store for when turtle restarts
	local file = fs.open('tid', 'w')
	file.write(tid)
	file.close()
	return tid
end

return Module

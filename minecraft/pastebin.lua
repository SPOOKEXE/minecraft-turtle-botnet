-- IGNORE THESE IN LIVE

local http
local json = require("json")

-- INSERT JSON CODE HERE

local socket, err = http.websocket("127.0.0.1:5757")
assert( socket, err )

print("Turtle Started!")

socket.send('create_turtle')
local turtle_id, _ = socket.receive()
print("The turtle unique id is: ", turtle_id)

socket.send('kill_turtle')

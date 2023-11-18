
local socket, err = http.websocket("127.0.0.1:5757")
if socket == false then
	error(err)
end

print("Turtle Started!")

socket.send("Hello server!")

message, _ = socket.receive()
print("Received: ", message)
socket.close()

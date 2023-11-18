

import threading
import json
import traceback

from time import sleep, time
from websockets.sync.server import ServerConnection, serve
from websockets.exceptions import ConnectionClosed
from ccturtle import create_turtle_instance, handle_turtle_request

JSON_DECODE_ERR = json.dumps({ "success" : False, "message" : "Failed to decode the json data." })
TURTLE_ID_ERR = json.dumps({ "success" : False, "message" : "You must include the turtle_id in the json data." })

# internally handle the request
def handle_request( ws : ServerConnection, incoming : str | bytes ) -> None:
	# check if its a generate_id request
	if incoming == "kill_turtle": return ws.close()
	if incoming == "create_turtle": return create_turtle_instance()

	try: incoming = json.loads( incoming )
	except json.JSONDecodeError: return JSON_DECODE_ERR

	try: turtle_id = int( incoming['turtle_id'], 2 )
	except KeyError: return TURTLE_ID_ERR

	print("Turtle Request: ", incoming)
	success, rdata, message = False, None, None
	try:
		success, rdata, message = handle_turtle_request( turtle_id, incoming )
		if type(rdata) == dict: rdata = json.dumps(rdata)
	except Exception as exception:
		print(traceback.format_exception(exception))
		success, message = False, "An internal server error occured."
	return json.dumps({"success" : success, "data" : rdata, "message" : message})

# handle requests until the connection is closed!
def handle_connection(ws : ServerConnection) -> None:
	while True:
		try:
			incoming = ws.recv(timeout=None)
			if type(incoming) == bytes: incoming = incoming.decode('utf-8')
			response = handle_request(ws, incoming)
			if response != None: ws.send(response)
		except ConnectionClosed:
			print(f'[{ round( time(), 2 ) }] Turtle connection is closed, ending handle connection loop.')
			break
		except Exception as exception:
			print(f'An exception occured: { traceback.format_exception( exception ) }')
			break

print("Setting up Websocket")
ws_server = serve(handle_connection, '127.0.0.1', 5757, compression=None)
serverThread = threading.Thread(target=ws_server.serve_forever, group=None)
serverThread.start()

print("Websocket Server Started!")
while True:
	try:
		sleep(0.1)
	except KeyboardInterrupt:
		break
	except Exception as exception:
		print(exception)



import threading
import json
import traceback

from time import sleep, time
from websockets.sync.server import ServerConnection, serve
from websockets.exceptions import ConnectionClosed
from ccturtle import create_turtle_instance, handle_turtle_request, is_turtle_id

JSON_DECODE_ERR = json.dumps({ "success" : False, 'jobs' : [], "message" : "Failed to decode the json data." })
TURTLE_ID_ERR = json.dumps({ "success" : False, 'jobs' : [], "message" : "You must include the turtle_id in the json data." })

# generate a closing command
def generate_closing_command( message : str ) -> str:
	return json.dumps( {'success' : False, 'jobs' : ['close'], 'message' : message } )

# internally handle the request
def handle_request( ws : ServerConnection, incoming : str | bytes ) -> None:
	# check if its a generate_id request
	if incoming == "create_turtle": return create_turtle_instance()
	if incoming == "kill_turtle": return generate_closing_command('Killed the turtle.')

	try: incoming = json.loads( incoming )
	except json.JSONDecodeError: return JSON_DECODE_ERR

	try: turtle_id = int( incoming['turtle_id'], 2 )
	except KeyError: return TURTLE_ID_ERR

	if not is_turtle_id( turtle_id ):
		return generate_closing_command('No such turtle id exists.')

	print("Turtle Request: ", incoming)
	try:
		handle_turtle_request( ws, turtle_id, incoming )
	except Exception as exception:
		print("An internal server error occured.")
		print(traceback.format_exception(exception))

# handle requests until the connection is closed!
def handle_connection(ws : ServerConnection) -> None:
	while True:
		try:
			incoming = ws.recv(timeout=None)
			if type(incoming) == bytes: incoming = incoming.decode('utf-8')
			handle_request(ws, incoming)
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


import threading

from time import sleep
from websockets.sync.server import ServerConnection, serve

def handle_new_ws(ws : ServerConnection):
	value = ws.recv()
	print("From Client: ", value)
	ws.send("Hello client!")
	ws.close()

ws_server = serve(handle_new_ws, '127.0.0.1', 5757, compression=None)
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

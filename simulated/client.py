
from websockets.sync.client import connect

client_uids : list[str] = [ ]
TIMEOUT : int = 10

for _ in range(10):
	with connect("ws://127.0.0.1:5757") as websocket:
		websocket.send('create')
		client_uids.append( websocket.recv(timeout=TIMEOUT) )

print(client_uids)


import asyncio

from uuid import uuid4
from websockets.server import WebSocketServerProtocol, serve

class Host:

	def __init__(self, ip='127.0.0.1', port=5757):
		self.ip = ip
		self.port = port

	async def handle_request( self, ws : WebSocketServerProtocol  ) -> None:
		'''
		Handle incoming requests.
		'''
		# raise NotImplementedError

		message : str = await ws.recv()
		uid : str = uuid4().hex
		print(message, '->', uid)
		await ws.send( uid )
		await ws.close()

	async def _internal_start( self ) -> None:
		async with serve(self.handle_request, self.ip, self.port):
			await asyncio.Future()

	def start( self ) -> None:
		asyncio.run(self._internal_start())

host = Host()
host.start()

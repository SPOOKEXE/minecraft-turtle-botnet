
import asyncio

from websockets.server import WebSocketServerProtocol, serve

class BaseWebSocket:

	def __init__(self, ip='127.0.0.1', port=5757):
		self.ip = ip
		self.port = port

	async def handle_request( self, ws : WebSocketServerProtocol  ) -> None:
		'''
		Handle incoming requests.

		You must override this method otherwise it will raise a NotImplementedError.
		'''
		raise NotImplementedError

	async def _internal_start( self ) -> None:
		async with serve(self.handle_request, self.ip, self.port, compression=None):
			await asyncio.Future()

	def start( self ) -> None:
		asyncio.run(self._internal_start())

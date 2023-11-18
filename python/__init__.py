
import asyncio
import traceback
import json

from uuid import uuid4
from websockets.server import WebSocketServerProtocol, serve
from ccturtle import create_turtle_instance, get_turtle_jobs, is_turtle_id, put_turtle_results

JSON_DECODE_ERR = json.dumps({ "success" : False, 'jobs' : [], "message" : "Failed to decode the json data." })
JOB_ID_ERR = json.dumps({ "success" : False, 'jobs' : [], "message" : "Job does not exist in the JSON data." })
TURTLE_ID_ERR = json.dumps({ "success" : False, 'jobs' : [], "message" : "You must include the turtle_id in the json data." })

def generate_close_command( message : str ) -> str:
	return {'success' : False, 'jobs' : ['close'], 'message' : message }

def generate_fail_command( message : str ) -> str:
	return {'success' : False, 'jobs' : None, 'message' : message }

def generate_success_command( jobs : list | None, message : str ) -> str:
	return {'success' : True, 'jobs' : jobs, 'message' : message }

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

class CCTurtleHost(BaseWebSocket):

	async def handle_turtle_request( self, ws : WebSocketServerProtocol, data : dict ) -> None:
		print(data)

		# find the request's job
		job : str = data.get('job')
		if job == None: return JOB_ID_ERR

		if job == "turtle_create": return generate_success_command( None, await create_turtle_instance() )
		if job == "turtle_kill": return generate_close_command('The turtle has been slain.')

		# find the turtle id
		turtle_id : str = data.get('turtle_id')
		if turtle_id == None: return TURTLE_ID_ERR

		if not await is_turtle_id( turtle_id ): return generate_close_command('No such turtle exists.')

		if job == 'turtle_get_jobs': return await get_turtle_jobs( ws, turtle_id, data )
		if job == "turtle_set_results": return await put_turtle_results( ws, turtle_id, data )

		return generate_fail_command('No such job exists: ' + str(job))

	async def handle_request( self, ws : WebSocketServerProtocol  ) -> None:
		'''
		Handle incoming requests.
		'''
		incoming : str = await ws.recv()
		try: data = json.loads( incoming )
		except json.JSONDecodeError:
			await ws.send( generate_fail_command( JSON_DECODE_ERR ) )
			return

		try:
			response = await self.handle_turtle_request( ws, data )
		except Exception as exception:
			print("An error occured:")
			print( traceback.format_exception(exception) )
			response = generate_fail_command( 'A core server error occured.' )
		await ws.send( json.dumps(response) )

host = CCTurtleHost()
host.start()

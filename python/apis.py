
import json
import traceback

from typing import Any

from library.websocks import BaseWebSocket
from library.ccturtle import TurtleAPI, BehaviorTrees
from websockets.server import WebSocketServerProtocol

def dump_json2( value : dict | list ) -> str:
	'''
	This version of json.dumps removes unnecessary spaces and gaps

	*sugar syntax*
	'''
	return json.dumps(value, separators=(',', ':'))

def construct_response( success : bool = True, data : dict | list | Any = None, message : str = None ) -> str:
	return { "success" : success, 'data' : data, "message" : message }

class CCTurtleHost(BaseWebSocket):

	# TODO: set world here?

	def __init__(self, *args, **kwargs):
		super().__init__(*args, **kwargs)

	async def handle_turtle_request( self, ws : WebSocketServerProtocol, data : dict ) -> dict:
		print(data)

		job : str = data.get('job')
		if job == None:
			return construct_response(success=False, message="JSON data does not include the 'job' key.")

		if job == "turtle_create":
			tid = await create_turtle_instance()
			return construct_response(data = tid)

		# find the turtle id
		turtle_id : str = data.get('turtle_id')
		if turtle_id == None:
			return construct_response(success=False, message="Must include the 'turtle_id' in the json data")

		if not await is_turtle_id( turtle_id ):
			return construct_response(success=False, jobs=['close'], message='No such turtle exists.')

		if job == "turtle_destroy":
			await destroy_turtle_instance( turtle_id )
			return construct_response(message='The turtle has been slain.')

		if job == 'turtle_get_jobs':
			job_queue = await get_turtle_jobs( ws, turtle_id, data )
			return construct_response(data = job_queue, message=None)

		inner_data : dict | list | Any | None = data.get('data')

		if job == "turtle_set_results":
			if inner_data == None:
				return construct_response(success=False, message='The results were not included.')
			await put_turtle_results( ws, turtle_id, data )
			return construct_response(message='The results were appended.')

		return construct_response(success=False, message='Job does not exist.')

	async def handle_request( self, ws : WebSocketServerProtocol  ) -> None:
		'''
		Handle incoming requests.
		'''
		incoming : str = await ws.recv()
		try:
			data = json.loads( incoming )
		except json.JSONDecodeError:
			response = construct_response(success=False, message="Failed to decode the passed json.")
			await ws.send( dump_json2(response) )
			return

		try:
			response = await self.handle_turtle_request( ws, data )
		except Exception as exception:
			print("An error occured:")
			print( traceback.format_exception(exception) )
			response = construct_response(success=False, message='An internal server error occured.')
		await ws.send( dump_json2(response) )

# socket = CCTurtleHost()
# world = World()


import json
import traceback

from typing import Any

from library.websocks import BaseWebSocket
from library.ccturtle import TurtleAPI, BehaviorTrees, Turtle
from library.minecraft import Point3, World
from library.recipes import RECIPES, resolve_multi_tree
from library.behaviortree import BaseSequenceItem
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

	world : World

	def __init__(self, world : World, *args, **kwargs):
		super().__init__(*args, **kwargs)
		self.world = world

	async def handle_turtle_request( self, ws : WebSocketServerProtocol, data : dict ) -> dict:
		print(data)

		job : str = data.get('job')
		if job == None:
			return construct_response(success=False, message="JSON data does not include the 'job' key.")

		if job == "create_turtle":
			xyz_cords = data.get('xyz')
			if type(xyz_cords) != list or len(xyz_cords) != 3:
				return construct_response(success=False, message='Invalid XYZ coordinates.')

			direction = data.get('direction')
			if type(direction) != str or (direction != 'north' and direction != 'south' and direction != 'east' and direction != 'west'):
				return construct_response(success=False, message='Invalid facing direction.')

			tid = TurtleAPI.create_turtle_instance(
				world = self.world,
				position = Point3(x=xyz_cords[0], y=xyz_cords[1], z=xyz_cords[2]),
				direction = direction
			)
			return construct_response(data = tid, message='Created a new turtle.')

		# find the turtle id
		turtle_id : str = data.get('turtle_id')
		if turtle_id == None:
			return construct_response(success=False, message="Must include the 'turtle_id' in the json data")

		if not TurtleAPI.does_turtle_exist( world, turtle_id ):
			return construct_response(success=False, jobs=['close'], message='No such turtle exists.')

		if job == "turtle_destroy":
			TurtleAPI.destroy_turtle( world, turtle_id )
			return construct_response(message='The turtle has been slain.')

		if job == 'turtle_get_jobs':
			job_queue = TurtleAPI.get_turtle_jobs( world, turtle_id )
			return construct_response(data=job_queue, message=None)

		inner_data : dict | list | Any | None = data.get('data')

		if job == "turtle_set_results":
			if inner_data == None:
				return construct_response(success=False, message='The results were not included.')
			TurtleAPI.put_turtle_results( world, turtle_id, inner_data )
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
		print(response)
		await ws.send( dump_json2(response) )

class TurtleSequencer:

	def __init__( self, world : World, turtle : Turtle ):
		self.world = world
		self.turtle = turtle
		self.sequencer = BehaviorTrees.INITIALIZER.create_sequencer_item(
			conditionAutoParams = [ turtle, world ],
			functionAutoParams = [ turtle, world ]
		)

world = World()
turtle = Turtle()
sequencer = BaseSequenceItem(
	wrapToRoot = False,
	conditionAutoParams = [ turtle, world ],
	functionAutoParams = [ turtle, world ],
	data = { },
)

BehaviorTrees.INITIALIZER.start_auto_updater()

BehaviorTrees.INITIALIZER.append_sequencer( sequencer )
BehaviorTrees.INITIALIZER.await_sequencer_completion( sequencer )

print( 'COMPLETED!' )

BehaviorTrees.INITIALIZER.pop_sequencer( sequencer )

BehaviorTrees.INITIALIZER.stop_auto_updater()

# socket = CCTurtleHost(world=world)
# socket.start()

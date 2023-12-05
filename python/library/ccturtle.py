
from uuid import uuid4
from time import sleep, time
from uuid import uuid4
from time import sleep

from library.minecraft import Point3, World, Turtle, Turtle, WorldAPI
from library.behaviortree import BaseBehaviorTree, BaseSequenceItem, BehaviorTreeBuilder, BehaviorTreeNode, TreeNodeFactory

class TurtleAPI:

	@staticmethod
	def create_turtle_instance( world : World, position : Point3, direction : str ) -> str:
		return WorldAPI.create_new_turtle( world, position=position, direction=direction ).uid

	@staticmethod
	def does_turtle_exist( world : World, turtle_id : str ) -> bool:
		return WorldAPI.does_turtle_exist( world, turtle_id )

	@staticmethod
	def destroy_turtle( world : World, turtle_id : str ) -> None:
		return WorldAPI.destroy_turtle( world, turtle_id )

	@staticmethod
	def get_turtle_jobs( world : World, turtle_id : str ) -> list:
		raise NotImplementedError

	@staticmethod
	def put_turtle_results( world : World, turtle_id : str, results : list ) -> None:
		raise NotImplementedError

	@staticmethod
	def send_tracked_jobs( turtle : Turtle, jobs : list[ list ] ) -> str:
		'''
		Send tracked jobs to the turtle - await results with "TurtleAPI.yield_tracked_results"
		'''
		tracker_id : str = uuid4().hex
		data = { "turtle_id" : turtle.uid, "jobs" : jobs, "tracker_id" : tracker_id }
		turtle.queued_jobs.append(data)
		return tracker_id

	@staticmethod
	def yield_tracked_results( turtle : Turtle, tracker_id : str, timeout : int = 60 ) -> tuple[bool, list[list] | None]:
		'''
		Yield until the tracked results are returned for the turtle.
		'''
		timeoutTime = time() + timeout
		while turtle.tracker_results.get( tracker_id ) == None and time() < timeoutTime:
			sleep(0.1)
		try: return True, turtle.tracker_results.pop( tracker_id )
		except: return False, None

	# @staticmethod
	# def query_turtle_initializer( turtleInstance : Turtle ) -> tuple[bool, list[list] | None]:
	# 	tracker_id : str = TurtleAPI.send_tracked_jobs(turtleInstance, [
	# 		[ TurtleActions.readInventory ],
	# 		[ TurtleActions.getEquippedItems ]
	# 	])
	# 	return TurtleAPI.yield_tracked_results( tracker_id )

class BehaviorFunctions:

	# functionz
	HAS_MINIMUM_COAL = None

class BehaviorTrees:

	# UNCONCIOUS ACTIONS AND BEHAVIORS
	FIND_COAL_RESOURCE = None

	# CONCIOUS ACTIONS AND BEHAVIORS
	FIND_RESOURCE = None

	# MAIN BEHAVIOR LOOPS

	pass
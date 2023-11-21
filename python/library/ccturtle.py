
import pickle

from typing import Any
from dataclasses import dataclass
from uuid import uuid4
from time import sleep, time
from typing import Any, Callable
from uuid import uuid4
from time import sleep

from library.minecraft import Block, Chest, Furnace, Item, Point3, World, Inventory, Turtle, TurtleActions, Turtle, WorldAPI
from library.websocks import BaseWebSocket, construct_response
from library.behaviortree import BaseBehaviorTree, BaseSequenceItem, BehaviorTreeBuilder, BehaviorTreeNode, TreeNodeFactory

class TurtleAPI:

	@staticmethod
	def create_turtle_instance( world : World, position : Point3, direction : str ) -> str:
		return WorldAPI.create_new_turtle( world, position=position, direction=direction )

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

class BehaviorTrees:
	pass

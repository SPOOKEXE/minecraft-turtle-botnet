
import json

from threading import Thread
from time import sleep
from uuid import uuid4
from websockets.sync.server import ServerConnection

from .consts.minecraft import ( Turtle, World )
from .utility.behaviortree import ( BehaviorTreeNode, TreeNodeFactory, BaseBehaviorTree, BehaviorTreeBuilder )

active_turtles = { }

# is turtle id
async def is_turtle_id( turtle_id : str ) -> bool:
	global active_turtles
	return active_turtles.get(turtle_id) != None

# create a new turtle instance
async def create_turtle_instance( ) -> str:
	global active_turtles
	nid = uuid4().hex
	active_turtles[nid] = Turtle()
	return nid

async def get_turtle_jobs( ws : ServerConnection, turtle_id : str, data : dict ) -> dict:
	global active_turtles
	turtle : Turtle = active_turtles[turtle_id]
	print( turtle.active_jobs )
	if len(turtle.active_jobs) == 0:
		if len(turtle.job_queue) == 0:
			return { 'success' : True, 'jobs' : None, 'message' : 'Turtle has no jobs in queue.' }
		turtle.active_jobs = turtle.job_queue
		turtle.job_queue = []
		turtle.is_busy = True
	return { 'success' : True, 'jobs' : turtle.active_jobs, 'message' : 'Queued items have been returned.' }

async def put_turtle_results( ws : ServerConnection, turtle_id : str, data : dict ) -> dict:
	global active_turtles
	# get the turtle
	turtle : Turtle = active_turtles[turtle_id]
	# put results
	print( turtle.results )
	turtle.results = data.get('results')
	turtle.results_ready = True
	return { 'success' : True, 'jobs' : None, 'message' : 'Results have been saved. Repeat call_jobs until there are new jobs available.' }

def behavior_tree_loop( ) -> None:
	global active_turtles
	while True:
		for uid, turtle in active_turtles.items():
			# tree.update(turtle) # would do all the below :)

			# new job which is to get fuel level
			if not turtle.is_busy:
				turtle.results = None
				turtle.results_ready = False
				if len(turtle.job_queue) == 0:
					turtle.job_queue.append(['getFuelLevel'])
				continue

			# await results
			if turtle.is_busy:
				if not turtle.results_ready:
					continue
				print( uid, turtle.results )
				turtle.is_busy = False
				turtle.results = []
				turtle.results_ready = False

		sleep(0.1)

Thread(target=behavior_tree_loop).start()

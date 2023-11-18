
import json

from dataclasses import dataclass, field
from uuid import uuid4
from websockets.sync.server import ServerConnection

active_turtles = { }

@dataclass
class Turtle:
	queue : list[str | list] = field(default_factory=list)
	responses : list[str | list | dict] = field(default_factory=list)
	is_busy : bool = False
	responses_ready : bool = False

# is turtle id
def is_turtle_id( turtle_id : str ) -> bool:
	return active_turtles.get(turtle_id) != None

# create a new turtle instance
def create_turtle_instance( ) -> str:
	nid = uuid4().hex
	active_turtles[nid] = Turtle()
	return nid

# handle a turtle request given the id and data
def handle_turtle_request( ws : ServerConnection, turtle_id : str, data : dict ) -> None:
	# get the turtle
	turtle : Turtle = active_turtles[turtle_id]
	if turtle.is_busy:
		ws.send(json.dumps({ 'success' : True, 'jobs' : None, 'message' : 'Turtle is busy.' }))
		return
	turtle.is_busy = True
	# get the queue
	currentQueue = turtle.queue
	# reset the queue
	turtle.queue = []
	# send the jobs to the turtle
	print( turtle_id, currentQueue )
	ws.send(json.dumps({ 'success' : True, 'jobs' : json.dumps(currentQueue), 'message' : None }))
	# wait for the response
	response = ws.recv(15)
	response = json.loads(response)
	# place the responses in the turtle
	turtle.responses = response['return_values']
	turtle.responses_ready = True
	turtle.is_busy = False

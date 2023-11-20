
import json

from typing import Any
from consts import actions
from library import minecraft, turtle, websocks, behaviortree

socket = websocks.TurtleWebSocket()

class TurtleAPI:

	@staticmethod
	def _dump_str( value : dict ) -> str:
		return json.dumps(value, separators=(',', ':'))

	@staticmethod
	def query_jobs_to_turtle( turtle : turtle.Turtle, jobs : list[ list ] ) -> list[bool | Any]:
		return socket.await_tracker_response(socket.request_with_tracker(
			TurtleAPI._dump_str({ "turtle_id" : turtle.uid, "jobs" : jobs })
		))

	@staticmethod
	def query_turtle_inventory( turtle : turtle.Turtle ) -> list | None:
		return TurtleAPI.query_jobs_to_turtle( turtle, [["readInventory"]] )

class BehaviorTrees:
	pass

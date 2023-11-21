
from __future__ import annotations

from typing import Any
from uuid import uuid4
from pydantic import BaseModel
from enum import Enum

def array_find( array : list, value : Any ) -> int:
	try: return array.index(value)
	except: return -1

class Direction(Enum):
	north = "north"
	south = "south"
	west = "west"
	east = "east"

class Point3(BaseModel):
	x : int = 0
	y : int = 0
	z : int = 0

# individual items
class Item(BaseModel):
	name : str
	quantity : int

# individual inventories
class Inventory(BaseModel):
	inventory : list[Item] = list()

# block of any kind
class Block(BaseModel):
	uid : str = lambda _ : uuid4().hex
	name : str = "minecraft:air"
	position : Point3 = Point3()

# blocks
class Chest(Block, Inventory, BaseModel):
	name : str = "minecraft:chest"

class Furnace(Block, Inventory, BaseModel):
	name : str = "minecraft:furnace"

# turtle
class TurtleActions(Enum):
	'''
	Contains all the possible turtle actions.
	'''
	getTurtleInfo = 1

	'''
	Movement actions.
	'''
	forward = 5
	backward = 6
	up = 7
	down = 8
	turnLeft = 9
	turnRight = 10

	'''
	World-interaction actions.
	'''
	attackFront = 20
	attackAbove = 21
	attackBelow = 22
	digFront = 23
	digAbove = 24
	digBelow = 25
	placeFront = 26
	placeAbove = 27
	placeBelow = 28
	detectFront = 29
	detectAbove = 30
	detectBelow = 31
	inspectFront = 32
	inspectAbove = 33
	inspectBelow = 34
	compareFront = 35
	compareAbove = 36
	compareBelow = 37
	dropFront = 38
	dropAbove = 39
	dropBelow = 40
	suckFront = 41
	suckAbove = 42
	suckBelow = 43

	'''
	Inventory management actions.
	'''
	craftItems = 53
	selectSlot = 54
	getSelectedSlot = 55
	getItemCountInSlot = 56
	getItemSpaceInSlot = 57
	getItemDetailsInSlot = 58
	equipLeft = 59
	equipRight = 60
	refuel = 61
	getFuelLevel = 62
	getFuelLimit = 63
	transferTo = 64

	'''
	Customs
	'''
	getDirectionFromSign = 78
	readInventory = 79
	findItemSlotsByPattern = 80
	getEquippedItems = 81
	procreate = 82
	isBusy = 83

class Turtle(Block, Inventory, BaseModel):
	uid : str = lambda _ : uuid4().hex
	name : str = "computercraft:crafty_turtle"
	label : str = "Unknown"
	selectedSlot : int = 1
	fuel : int = 0
	position : Point3 = Point3()
	direction : Direction = Direction.north

	inventory : Inventory = list()
	left_hand : Item = None
	right_hand : Item = None

	tracker_results : dict = dict()
	queued_jobs : list = list()
	active_jobs : list = list()

class World(BaseModel):
	uid : str = lambda _ : uuid4().hex
	block_cache : dict = dict()
	turtle_ids : list[str] = list()
	turtles_map : dict[str, Turtle] = dict()

class WorldAPI:

	@staticmethod
	def does_turtle_id_exist( world : World, turtle_id : str ) -> bool:
		return array_find( world.turtle_ids, turtle_id ) != -1

	@staticmethod
	def create_new_turtle( world : World, position : Point3, direction : str ) -> str:
		turtle = Turtle(position=position, direction=direction)
		world.turtle_ids.append(turtle.uid)
		world.turtles_map[turtle.uid] = turtle
		WorldAPI.push_block( world, position, turtle )
		return turtle.uid

	@staticmethod
	def get_turtle_jobs( turtle_id : str, data : dict ) -> dict:
		raise NotImplementedError

	@staticmethod
	def put_turtle_results( turtle_id : str, data : dict ) -> list:
		pass

	@staticmethod
	def update_behavior_trees( ) -> None:
		raise NotImplementedError

	@staticmethod
	def push_block( world : World, position : Point3, block : Block ) -> bool:
		raise NotImplementedError

	@staticmethod
	def pop_block( world : World, position : Point3 ) -> bool:
		raise NotImplementedError

	@staticmethod
	def pathfind_to( world : World, turtle : Turtle, target : Point3 | Block ) -> tuple[bool, list]:
		if type(target) == Block: target = target.position
		target : Point3 = target

		# A* pathfinding / other method (such as directly going there)
		raise NotImplementedError

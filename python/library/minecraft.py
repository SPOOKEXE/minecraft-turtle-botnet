
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
	uid : str = uuid4().hex
	name : str = "minecraft:air"
	position : Point3 = Point3()
	traversible : bool = True

# blocks
class Chest(Block, Inventory, BaseModel):
	name : str = "minecraft:chest"
	traversible : bool = False

class Furnace(Block, Inventory, BaseModel):
	name : str = "minecraft:furnace"
	traversible : bool = False

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
	uid : str = uuid4().hex
	name : str = "computercraft:crafty_turtle"
	label : str = "Unknown"
	selectedSlot : int = 1
	fuel : int = 0
	position : Point3 = Point3()
	direction : Direction = Direction.north
	traversible : bool = False

	inventory : Inventory = list()
	left_hand : Item = None
	right_hand : Item = None

	tracker_results : dict = dict()
	queued_jobs : list = list()
	active_jobs : list = list()

class World(BaseModel):
	uid : str = uuid4().hex
	unique_blocks : list[str] = list()
	block_cache : dict = dict()

	turtle_ids : list[str] = list()
	turtles_map : dict[str, Turtle] = dict()

	pathfind_cache : dict[str, list] = dict()

class WorldAPI:

	@staticmethod
	def does_turtle_exist( world : World, turtle_id : str ) -> bool:
		return array_find( world.turtle_ids, turtle_id ) != -1

	@staticmethod
	def create_new_turtle( world : World, position : Point3, direction : str ) -> Turtle:
		turtle = Turtle(position=position, direction=direction)
		world.turtle_ids.append(turtle.uid)
		world.turtles_map[turtle.uid] = turtle
		WorldAPI.push_block( world, position, turtle )
		return turtle

	@staticmethod
	def destroy_turtle( world : World, turtle_id : str ) -> None:
		idx = array_find( world.turtle_ids, turtle_id )
		if idx == -1: return
		world.turtle_ids.pop(idx)

	@staticmethod
	def get_turtle_jobs( world : World, turtle_id : str ) -> list:
		turtle : Turtle = world.turtles_map.get(turtle_id)
		if turtle == None: return [ ]
		raise NotImplementedError

	@staticmethod
	def put_turtle_results( world : World, turtle_id : str, tracker_id : str, data : list ) -> None:
		turtle : Turtle = world.turtles_map.get(turtle_id)
		if turtle == None: return
		turtle.tracker_results[tracker_id] = data

	@staticmethod
	def get_block( world : World, position : Point3 ) -> Block | None:
		x = str(position.x)
		z = str(position.z)
		y = str(position.y)
		if world.block_cache.get(x) == None:
			return None
		if world.block_cache.get(x).get(z) == None:
			return None
		return world.block_cache[x][z].get(y)

	@staticmethod
	def push_block( world : World, position : Point3, block : Block ) -> bool:
		# cache unique block names
		index = array_find(world.unique_blocks, block.name)
		if index == -1:
			world.unique_blocks.append( [block.uid, block.name] )
			index = len(world.unique_blocks)
		x = str(position.x)
		z = str(position.z)
		y = str(position.y)
		if world.block_cache.get(x) == None:
			world.block_cache[x] = { }
		if world.block_cache.get(x).get(z) == None:
			world.block_cache[x][z] = { }
		world.block_cache[x][z][y] = index

	@staticmethod
	def pop_block( world : World, position : Point3 ) -> None:
		x = str(position.x)
		z = str(position.z)
		y = str(position.y)
		if world.block_cache.get(x) == None:
			return
		if world.block_cache.get(x).get(z) == None:
			return
		try: world.block_cache.get(x).get(z).pop(y)
		except: pass

	@staticmethod
	def pathfind2d_to( world : World, start : Point3, goal : Point3 ) -> tuple[bool, list]:
		'''
		Pathfind on the X/Z axis ONLY.
		'''
		pass

	@staticmethod
	def get_block_neighbours( world : World, source : Point3, allow_diagonals : bool = True, allow_vertical : bool = True, filter_traversible : bool = True ) -> list[Block]:

		leftPlane = source.x - 1
		rightPlane = source.x + 1
		forwardPlane = source.z + 1
		backwardPlane = source.z - 1
		upAxis = source.y + 1
		downAxis = source.y - 1

		def checkNodePath( x : int, z : int, y : int ) -> Block:
			nonlocal world
			position : Point3 = Point3(x=x, y=y, z=z)
			block = WorldAPI.get_block( world, position )
			return block == None and Block(position=position) or block

		neighbour_nodes = [
			checkNodePath( leftPlane, source.z, source.y ), # left-middle-middle
			checkNodePath( rightPlane, source.z, source.y ), # right-middle-middle
			checkNodePath( source.x, forwardPlane, source.y ), # middle-forward-middle
			checkNodePath( source.x, backwardPlane, source.y ), # middle-forward
		]

		if allow_vertical:
			neighbour_nodes.extend([
				checkNodePath( source.x, source.z, upAxis ), # top-middle
				checkNodePath( source.x, source.z, downAxis ) # bottom-middle
			])

		if allow_diagonals:
			neighbour_nodes.extend([
				checkNodePath(leftPlane, forwardPlane, source.y),
				checkNodePath(leftPlane, backwardPlane, source.y),
				checkNodePath(rightPlane, forwardPlane, source.y),
				checkNodePath(rightPlane, backwardPlane, source.y),
			])

		if allow_vertical and allow_diagonals:
			neighbour_nodes.extend([
				checkNodePath(leftPlane, forwardPlane, upAxis),
				checkNodePath(leftPlane, forwardPlane, downAxis),
				checkNodePath(leftPlane, source.z, upAxis),
				checkNodePath(leftPlane, source.z, downAxis),
				checkNodePath(leftPlane, backwardPlane, upAxis),
				checkNodePath(leftPlane, backwardPlane, downAxis),
				checkNodePath(rightPlane, forwardPlane, upAxis),
				checkNodePath(rightPlane, forwardPlane, downAxis),
				checkNodePath(rightPlane, source.z, upAxis),
				checkNodePath(rightPlane, source.z, downAxis),
				checkNodePath(rightPlane, backwardPlane, upAxis),
				checkNodePath(rightPlane, backwardPlane, downAxis),
				checkNodePath(source.x, forwardPlane, upAxis),
				checkNodePath(source.x, forwardPlane, downAxis),
				checkNodePath(source.x, backwardPlane, upAxis),
				checkNodePath(source.x, backwardPlane, downAxis)
			])

		reverse : int = (source.x + source.z + source.y) % 2 == 0
		neighbours : list[Block] = []
		for p in neighbour_nodes:
			if filter_traversible and p.traversible == False:
				continue
			if reverse:
				neighbours.insert(0, p)
			else:
				neighbours.append(p)
		return neighbours

	@staticmethod
	def pathfind3d_to( world : World, start : Point3, goal : Point3 ) -> tuple[bool, list]:
		'''
		Pathfind on the X/Y/Z axis from the start location to the goal location.
		'''
		# A* pathfinding / other method (such as directly going there)

		cacheindex = str(hash( str(start) + str(goal) ))
		if world.pathfind_cache.get( cacheindex ):
			return world.pathfind_cache.get( cacheindex )

		raise NotImplementedError

	@staticmethod
	def on_path_blocked( world : World, path : list[Point3], blockedIndex : int ) -> None:
		raise NotImplementedError

	@staticmethod
	def update_behavior_trees( world : World ) -> None:
		raise NotImplementedError

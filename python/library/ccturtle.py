
from __future__ import annotations

from uuid import uuid4
from time import sleep, time
from uuid import uuid4
from time import sleep

from library.minecraft import Point3, World, Turtle, TurtleActions, WorldAPI
from library.behaviortree import BehaviorTreeBuilder, BaseSequenceItem, TreeNodeFactory
from library.recipes import RECIPES, resolve_multi_tree, resolve_recipe_tree

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

	@staticmethod
	def query_turtle_initializer( turtleInstance : Turtle ) -> tuple[bool, list[list] | None]:
		tracker_id : str = TurtleAPI.send_tracked_jobs(turtleInstance, [
			[ TurtleActions.getTurtleInfo ]
		])
		return TurtleAPI.yield_tracked_results( tracker_id )

def increment_dictionary( cache : dict, index : str, amount : int ) -> None:
	try: cache[index] += amount
	except: cache[index] = amount

class CONSTANTS:

	# https://minecraft.fandom.com/wiki/Ore
	COAL_Y_HEIGHT = 44
	LAPIS_Y_HEIGHT = -1
	IRON_Y_HEIGHT = 15
	REDSTONE_Y_HEIGHT = -59

class BehaviorFunctions:

	# does the turtle have the items in its inventory / equipped?
	def HAS_ITEMS_IN_INVENTORY( turtle : Turtle, items : list[tuple[str, int]] ) -> bool:
		# map the inventory
		inventory_mapping = {}
		for (item_id, amount) in turtle.inventory: increment_dictionary( inventory_mapping, item_id, amount )
		if turtle.left_hand != None: increment_dictionary( inventory_mapping, turtle.left_hand.name, turtle.left_hand.quantity )
		if turtle.right_hand != None: increment_dictionary( inventory_mapping, turtle.right_hand.name, turtle.right_hand.quantity )
		# check requirements
		for (item_id, amount) in items:
			if inventory_mapping.get(item_id) == None or inventory_mapping.get(item_id) < amount:
				return False
		# has requirements
		return True

	# is the turtle a brand new one?
	def IS_BRAND_NEW_TURTLE( _, __, world : World, turtle : Turtle ) -> bool:
		return WorldAPI.does_turtle_exist( world, turtle.uid ) # is the turtle a new turtle?

	# does the turtle have the minimum requirements?
	def HAS_NEW_TURTLE_REQUIREMENTS( _, __, ___, turtle : Turtle ) -> bool:
		# check for iron pickaxe and crafting table
		if not BehaviorFunctions.HAS_ITEMS_IN_INVENTORY( turtle, [
			('minecraft:iron_pickaxe', 1),
			('minecraft:crafting_table', 1)
		] ): return False
		# check for fuel / coal_block
		if turtle.fuel < 800 and not BehaviorFunctions.HAS_ITEMS_IN_INVENTORY( turtle, [('minecraft:coal_block', 1)] ):
			return False
		# has requirements
		return True

	# post 'HAS_ABOVE_MINIMUM_COAL' to determine when to search for fuel again
	def HAS_LOW_FUEL( _, __, ___, turtle : Turtle ) -> bool:
		y_diff = abs(turtle.position.y - CONSTANTS.COAL_Y_HEIGHT)
		return (turtle.fuel - y_diff) < 100 # allows 100 blocks to find coal at the COAL_Y_HEIGHT

	# set target resource
	def SET_TARGET_ORE( seq : BaseSequenceItem, block : str, amount : int ) -> None:
		seq.data = (block, amount)

# MAIN BEHAVIOR LOOPS
class BehaviorTrees: pass

BehaviorTrees.FIND_ORE_RESOURCE = BehaviorTreeBuilder.build_from_nested_dict(
	TreeNodeFactory.condition_truefalse_node(

	)
)

BehaviorTrees.FIND_SURFACE_RESOURCE = None # REQUIREMENT : fuel
BehaviorTrees.FIND_UNDERGROUND_RESOURCE = None # REQUIREMENT : fuel
BehaviorTrees.FIND_SAND_RESOURCE = None # REQUIREMENT : fuel
BehaviorTrees.FIND_WOOD_RESOURCE = None # REQUIREMENT : fuel

BehaviorTrees.FIND_TARGET_RESOURCE = None
BehaviorTrees.CRAFT_TARGET_RESOURCE = None
BehaviorTrees.SMELT_TARGET_RESOURCE = None
BehaviorTrees.BREAK_ORE_VEIN = None # follow and break the block vein
BehaviorTrees.FARM_TREE_SAPLING = None # place dirt, plant sapling, wait until grows, dig log + leaves

# main brain loop
BehaviorTrees.MAIN_LOOP = BehaviorTreeBuilder.build_from_nested_dict(
	TreeNodeFactory.condition_truefalse_node(
		BehaviorFunctions.HAS_LOW_FUEL,
		TreeNodeFactory.hook_behavior_tree(
			BehaviorTrees.FIND_ORE_RESOURCE,
			lambda _, seq, __, ___ : BehaviorFunctions.SET_TARGET_ORE(seq, 'minecraft:coal_ore', 4),
			None
		),
		None,
		None
	)
)

# very first thing that runs, check if is a new turtle and if has the required items to start
BehaviorTrees.INITIALIZER = BehaviorTreeBuilder.build_from_nested_dict(
	TreeNodeFactory.condition_truefalse_node(
		BehaviorFunctions.IS_BRAND_NEW_TURTLE,
		TreeNodeFactory.condition_truefalse_node(
			BehaviorFunctions.HAS_NEW_TURTLE_REQUIREMENTS,
			TreeNodeFactory.action_node(
				lambda *args : print('Turtle has all the requirements to start.'),
				TreeNodeFactory.pass_to_behavior_tree( BehaviorTrees.MAIN_LOOP, None )
			),
			TreeNodeFactory.multi_action_node([
				lambda *args : print('Turtle does not have all the requirements to start.'),
				lambda bt, seq, _, __ : bt.pop_sequencer( seq )
			], None),
			None
		),
		TreeNodeFactory.action_node(
			lambda *args : print('Turtle has already been initialized, skipping.'),
			TreeNodeFactory.pass_to_behavior_tree( BehaviorTrees.MAIN_LOOP, None )
		),
		None
	)
)


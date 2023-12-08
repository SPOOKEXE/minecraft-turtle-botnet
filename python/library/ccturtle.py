
from __future__ import annotations

from uuid import uuid4
from time import sleep, time
from uuid import uuid4
from time import sleep

from library.minecraft import Point3, World, Turtle, TurtleActions, WorldAPI
from library.behaviortree import BaseBehaviorTree, BehaviorTreeBuilder, BaseSequenceItem, TreeNodeFactory
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
	def send_untracked_jobs( turtle : Turtle, jobs : list[list] ) -> None:
		'''
		Send untracked jobs to the turtle.
		'''
		turtle.queued_jobs.append({ "turtle_id" : turtle.uid, "jobs" : jobs })

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

# https://minecraft.fandom.com/wiki/Ore
ORE_LEVEL_CONSTANTS = {
	'minecraft:coal_ore' : 44,
	'minecraft:lapis_ore' : -1,
	'minecraft:iron_ore' : 15,
	'minecraft:redstone_ore' : -59
}

# WHITELISTED_BLOCKS = {
# 	# block_name : max_quantity
# 	'minecraft:cobblestone' : 32,
# 	'minecraft:redstone' : 64,
# 	'minecraft:lapis_lazuli' : 64,
# 	'minecraft:iron_ingot' : 64,
# 	'minecraft:sand' : 64,

# 	'minecraft:chest' : 4,
# }

class ERROR_MESSAGES:
	NO_DESIGNATED_ORE = 'Turtle {} has no designated ore target.'
	UNKNOWN_DESIGNATED_ORE = 'Turtle {} has an unknown designated ore target: {}'
	MINING_FAILED_TO_REACH_Y_LEVEL = 'Turtle {} failed to mine to the Y level - exiting MINE_ORE_RESOURCE tree.'

class BehaviorFunctions:

	# count the amount of a specific item in the inventory
	def COUNT_INVENTORY_ITEMS( turtle : Turtle ) -> dict:
		inventory_mapping = {}
		for (item_id, amount) in turtle.inventory: increment_dictionary( inventory_mapping, item_id, amount )
		if turtle.left_hand != None: increment_dictionary( inventory_mapping, turtle.left_hand.name, turtle.left_hand.quantity )
		if turtle.right_hand != None: increment_dictionary( inventory_mapping, turtle.right_hand.name, turtle.right_hand.quantity )
		return inventory_mapping

	# does the turtle have the items in its inventory / equipped?
	def HAS_ITEMS_IN_INVENTORY( turtle : Turtle, items : list[tuple[str, int]] ) -> bool:
		# map the inventory
		inventory_mapping = BehaviorFunctions.COUNT_INVENTORY_ITEMS( turtle )
		# check requirements
		for (item_id, amount) in items:
			if inventory_mapping.get(item_id) == None or inventory_mapping.get(item_id) < amount:
				return False
		return True # has requirements

	# is the turtle a brand new one?
	def IS_BRAND_NEW_TURTLE( world : World, turtle : Turtle ) -> bool:
		return turtle.is_new_turtle

	# does the turtle have the minimum requirements?
	def HAS_NEW_TURTLE_REQUIREMENTS( _, __, ___, turtle : Turtle ) -> bool:
		# check for iron pickaxe and crafting table
		if not BehaviorFunctions.HAS_ITEMS_IN_INVENTORY( turtle, [
			('minecraft:iron_pickaxe', 1),
			('minecraft:iron_shovel', 1),
			('minecraft:iron_axe', 1),
			('minecraft:crafting_table', 1),
		] ): return False
		# check for fuel / coal_block
		if turtle.fuel < 800 and not BehaviorFunctions.HAS_ITEMS_IN_INVENTORY( turtle, [('minecraft:coal_block', 1)] ):
			return False
		# has requirements
		return True

	# post 'HAS_ABOVE_MINIMUM_COAL' to determine when to search for fuel again
	def HAS_LOW_FUEL( turtle : Turtle ) -> bool:
		y_diff = abs(turtle.position.y - ORE_LEVEL_CONSTANTS['minecraft:coal_ore'])
		return (turtle.fuel - y_diff) < 100 # allows 100 blocks to find coal at the COAL_Y_HEIGHT

	# set target resource
	def SET_TARGET_ORE( seq : BaseSequenceItem, block : str, amount : int ) -> None:
		seq.data['target_ore'] = (block, amount)

	# get the ore resource information
	def FIND_ORE_RESOURCE_INFO( block_id : str ) -> dict | None:
		return ORE_LEVEL_CONSTANTS.get(block_id)

	# go to Y level
	def MINE_TO_Y_LEVEL( turtle : Turtle, y_level : int ) -> bool:
		if y_level == turtle.position.y: return True # already here
		distance = abs( y_level - turtle.position.y )
		if y_level < turtle.position.y:
			jobs = [ [TurtleActions.digBelow], [TurtleActions.down] ] * distance
		else:
			jobs = [ [TurtleActions.digAbove], [TurtleActions.up] ] * distance
		tracker_id = TurtleAPI.send_tracked_jobs(turtle, jobs)
		success, results = TurtleAPI.yield_tracked_results( turtle, tracker_id, timeout=10 + int(distance * 1.5) )
		if (not success) or (False in results):
			print( turtle.uid, 'failed to dig to y-level ' + y_level )
			index = results.index(False)
			print('Failed on instruction enumeration:', jobs[index])
			return False
		return True

# MAIN BEHAVIOR LOOPS
class BehaviorTrees:
	BREAK_ORE_VEIN : BaseBehaviorTree
	DIG_TUNNEL : BaseBehaviorTree
	MINE_ORE_RESOURCE : BaseBehaviorTree

	LOW_FUEL_RESOLVER : BaseBehaviorTree

	# FIND_SURFACE_RESOURCE : BaseBehaviorTree
	# FIND_UNDERGROUND_RESOURCE : BaseBehaviorTree
	# FIND_TARGET_RESOURCE : BaseBehaviorTree

	# CRAFT_TARGET_RESOURCE : BaseBehaviorTree
	# SMELT_TARGET_RESOURCE : BaseBehaviorTree
	# FARM_TREE_SAPLING : BaseBehaviorTree

	MAIN_LOOP : BaseBehaviorTree
	INITIALIZER : BaseBehaviorTree

BehaviorTrees.BREAK_ORE_VEIN = BehaviorTreeBuilder.build_from_nested_dict(

)
BehaviorTrees.DIG_TUNNEL = BehaviorTreeBuilder.build_from_nested_dict(

)

def _3_condition_switch( _, __, seq : BaseSequenceItem, ___ ) -> int:
	if type(seq.data.get('target_ore')) != tuple: return 1
	yHeight = ORE_LEVEL_CONSTANTS.get(seq.data['target_ore'][0])
	if yHeight == None: return 2
	seq.data['target_height'] = yHeight
	return 3

BehaviorTrees.MINE_ORE_RESOURCE = BehaviorTreeBuilder.build_from_nested_dict(

	TreeNodeFactory.condition_switch_node(
		_3_condition_switch,
		# no target ore selected
		TreeNodeFactory.action_node(
			lambda _, __, ___, turtle : print(ERROR_MESSAGES.NO_DESIGNATED_ORE.format(turtle.uid)),
			None
		),
		# could not find the ore y-level
		TreeNodeFactory.action_node(
			lambda _, __, ___, turtle : print( ERROR_MESSAGES.NO_DESIGNATED_ORE.format(turtle.uid, turtle.data['target_ore'][0]) ),
			None
		),
		# ore was found, proceed with mining (go to y level first then mine)
		TreeNodeFactory.condition_truefalse_node(
			# mine to the target Y level
			lambda _, seq, __, turtle : BehaviorFunctions.MINE_TO_Y_LEVEL( turtle, seq.data.get('target_height') ),
			# while hasn't achieved total goal, keep mining until low-fuel (if not getting coal) or goal has been achieved.
			TreeNodeFactory.while_condition_node(
				lambda *args : True,
				lambda _, __, ___, ____ : None,
				None
			),
			lambda _, __, ___, turtle : print(ERROR_MESSAGES.MINING_FAILED_TO_REACH_Y_LEVEL.format(turtle.uid)),
			None
		)
	)
)

def _4_switch_condition( _, __, ___, turtle : Turtle ) -> int:
	inventory_mapping = BehaviorFunctions.COUNT_INVENTORY_ITEMS( turtle )
	if inventory_mapping.get('minecraft:coal') == None:
		# no coal, go mining
		return 3
	if inventory_mapping.get('minecraft:coal') >= 9:
		if inventory_mapping.get('minecraft:chest') >= 1:
			return 2 # craft a coal block then consume it
		return 1 # burn the coal in inventory and dont worry about crafting a coal block
	# coal is in the inventory but its not enough so keep mining
	return 3

BehaviorTrees.LOW_FUEL_RESOLVER = BehaviorTreeBuilder.build_from_nested_dict(

	TreeNodeFactory.condition_switch_node(
		_4_switch_condition,
		[
			# burn the coal in the inventory
			None,
			# craft coal blocks then burn the coal block
			None,
			# mine for coal then come back again
			TreeNodeFactory.hook_behavior_tree(
				BehaviorTrees.MINE_ORE_RESOURCE,
				lambda _, seq, __, ___ : BehaviorFunctions.SET_TARGET_ORE(seq, 'minecraft:coal_ore', 27), # get tons of coal
				None
			),
		],
		None
	)

)

# main brain loop
def _2_switch_condition( bt : BaseBehaviorTree, _ : BaseSequenceItem, world : World, turtle : Turtle ) -> int:
	# has low fuel
	if BehaviorFunctions.HAS_LOW_FUEL( turtle ) == True:
		return 1
	# doesnt have low fuel
	return 2

BehaviorTrees.MAIN_LOOP = BehaviorTreeBuilder.build_from_nested_dict(

	TreeNodeFactory.condition_switch_node(
		_2_switch_condition,
		# has not enough fuel so resolve the issue
		BehaviorTrees.LOW_FUEL_RESOLVER,
		# has enough fuel so focus on other activities
		lambda _, __, ___, turtle : print(f'Turtle {turtle.uid} has minimum coal requirement but nothing else has been implemented!'),
		None
	)

)

# very first thing that runs, check if is a new turtle and if has the required items to start
def _1_switch_condition( _, __, world : World, turtle : Turtle ) -> int:
	if BehaviorFunctions.IS_BRAND_NEW_TURTLE(world, turtle) == True:
		return 1 # already initialized, continue to main loop
	if BehaviorFunctions.HAS_NEW_TURTLE_REQUIREMENTS(turtle) == False:
		return 2 # does not have the requirements
	return 3 # has requriements, continue to main loop

def set_turtle_is_new_to_false( turtle : Turtle ) -> None:
	turtle.label = f'{turtle.uid}'
	turtle.is_new_turtle = False

BehaviorTrees.INITIALIZER = BehaviorTreeBuilder.build_from_nested_dict(

	TreeNodeFactory.condition_switch_node(
		_1_switch_condition
		[
			# turtle already has been initialized and will start immediately.
			TreeNodeFactory.action_node(
				lambda *args : print('Turtle has already been initialized, skipping.'),
				TreeNodeFactory.pass_to_behavior_tree( BehaviorTrees.MAIN_LOOP, None )
			),
			# turtle does not have the initial requirements
			TreeNodeFactory.multi_action_node([
				lambda *args : print('Turtle does not have all the requirements to start.'),
				lambda bt, seq, _, __ : bt.pop_sequencer( seq ) # remove from behavior tree
			], None),
			# turtle has all the requirements and now it will start.
			TreeNodeFactory.multi_action_node([
					lambda *args : print('Turtle has all the requirements to start.'),
					lambda _, __, ___, turtle : set_turtle_is_new_to_false(turtle)
				],
				TreeNodeFactory.pass_to_behavior_tree( BehaviorTrees.MAIN_LOOP, None )
			)
		]
	)

)



from .consts.minecraft import ( Turtle, World )
from .consts.actions import TurtleActions
from .utility.behaviortree import ( BehaviorTreeNode, TreeNodeFactory, BaseSequenceItem, BaseBehaviorTree, BehaviorTreeBuilder )

# ARGS: (behavior_tree, sequence_items)

def query_turtle( turtle : Turtle, job : str, *args ) -> None:
	turtle.job_queue.append([job, *args])

def check_if_initial_requirements_met( bt : BaseBehaviorTree, turtle : Turtle ) -> bool:
	query_turtle( turtle, TurtleActions.readInventory )

# what to do when turtle FIRST loads EVER
# TODO: check fuel requirements (and crafting table requirement?)
INITIAL_BEHAVIOR_TREE = BehaviorTreeBuilder.build_from_nested_dict(

	TreeNodeFactory.condition_truefalse_node(
		check_if_initial_requirements_met,
		lambda bt, turtle : None,
		lambda bt, turtle : None,
		None
	)

)

# goal is to find trees / wood to eat
# NOTE: if has sapling in inventory, find dirt, plant and wait for a tree,
# destroy the tree and get saplings, repeat.
# TODO: find trees/shipwrecks/anything of WOOD / PLANKS kind.
FIND_WOOD_BEHAVIOR_TREE = BehaviorTreeBuilder.build_from_nested_dict(

)

# achieve a craft recipe
# TODO: check turtle state to see what recipe is to being crafted,
# clear inventory into ground/chest and craft the item then suck the items back up.
ACHIEVE_CRAFT_BEHAVIOR_TREE = BehaviorTreeBuilder.build_from_nested_dict(

)

# what to do when turtle starts mining
# TODO: needs scheme to find coal, upgrade tools, and finally reproduce.
MINING_BEHAVIOR_TREE = BehaviorTreeBuilder.build_from_nested_dict(

)

# TODO: scheme to find wood (as second priority) and sand
SURFACE_BEHAVIOR_TREE = BehaviorTreeBuilder.build_from_nested_dict(
	TreeNodeFactory.condition_truefalse_node(

	)
)

# TODO: map around the current area
MAP_AREA_OUT_BEHAVIOR_TREE = BehaviorTreeBuilder.build_from_nested_dict(

)

# NOTE:
# - get wood first
# - go mining and get iron/diamond tools
# - go surface and get materials to reproduce (or otherwise go mining for fuel / resources again)
# - finally reproduce and repeat the cycle

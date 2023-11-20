
# import pickle

from library import behaviortree, minecraft, turtle, websocks
from apis import TurtleAPI, BehaviorTrees

# if __name__ == '__main__':

# 	world = minecraft.World(uid="lmao", block_cache={})

# 	world.block_cache["1.1.1"] = minecraft.Chest(uid="1", container=[], location=minecraft.Point3())
# 	world.block_cache["1.1.2"] = minecraft.Chest(uid="2", container=[], location=minecraft.Point3())
# 	world.block_cache["1.1.3"] = minecraft.Furnace(uid="3", container=[], location=minecraft.Point3())
# 	world.block_cache["1.1.4"] = turtle.Turtle(uid="4", label="Jim", inventory=minecraft.Inventory())

# 	raw : bytes = pickle.dumps(world)
# 	print(raw)
# 	remade = pickle.loads(raw)
# 	print(type(remade))
# 	print(remade)

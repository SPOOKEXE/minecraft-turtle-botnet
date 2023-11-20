
from __future__ import annotations

from uuid import uuid4
from pydantic import BaseModel

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
	container : list[Item] = list()

# block of any kind
class Block(BaseModel):
	uid : str = lambda _ : uuid4().hex
	name : str = "minecraft:air"
	location : Point3 = Point3()

# blocks
class Chest(Block, Inventory, BaseModel):
	name : str = "minecraft:chest"

class Furnace(Block, Inventory, BaseModel):
	name : str = "minecraft:furnace"

class World(BaseModel):
	uid : str = lambda _ : uuid4().hex
	block_cache : dict = dict()

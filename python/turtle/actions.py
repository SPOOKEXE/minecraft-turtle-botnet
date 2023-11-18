
from enum import Enum

class MovementActions(Enum):
	'''
	These are the turtle movement actions.
	'''
	forward = 0
	backward = 1
	up = 2
	down = 3

	turnLeft = 4
	turnRight = 5

class InteractActions(Enum):
	'''
	These are the turtle world-interaction actions.
	'''
	attackFront = 0
	attackAbove = 1
	attackBelow = 2

	digFront = 3
	digAbove = 4
	digBelow = 5

	placeFront = 6
	placeAbove = 7
	placeBelow = 8

	detectFront = 9
	detectAbove = 10
	detectBelow = 11

	inspectFront = 12
	inspectAbove = 13
	inspectBelow = 14

	compareFront = 15
	compareAbove = 16
	compareBelow = 17

	dropFront = 18
	dropAbove = 19
	dropBelow = 20

	suckFront = 21
	suckAbove = 22
	suckBelow = 23

class InventoryActions(Enum):
	'''
	These are the turtle inventory management actions.
	'''
	craftItem = 0
	selectSlot = 1
	getSelectedSlot = 2
	getItemCountInSlot = 3
	getItemSpaceInSlot = 4
	getItemDetailsInSlot = 5
	equipLeft = 6
	equipRight = 7
	unequipLeft = 8
	unequipRight = 9
	refuel = 10
	getFuelLevel = 11
	getFuelLimit = 12
	transferTo = 13

class MiscActions(Enum):
	getId = 0
	getLabel = 1
	setLabel = 2


import json
import os

from utility.behaviortree import BaseSequenceItem

class Turtle(BaseSequenceItem):
	x : int
	y : int
	z : int
	orientation : int
	job_queue : list
	active_jobs : list
	is_busy : bool
	results_ready : bool
	results : list | None

	def __init__( self ):
		self.x = self.y = self.z = 0
		self.orientation = 'north'
		self.job_queue = []
		self.active_jobs = []
		self.is_busy = False
		self.results_ready = False
		self.results = None
		self.sequencer = BaseSequenceItem()

class World:
	world_id : str
	cached_voxels : list
	turtles : list[str]

	def __init__(self, world_id : str):
		self.world_id = world_id
		self.cached_voxels = []
		self.turtles = []
		self.initialize()

	def initialize( self ) -> None:
		filepath = f'world_{self.world_id}.json'
		if os.path.exists( filepath ): self.load_database( filepath )

	def save_database( self, filepath : str ) -> None:
		data = { "voxels" : self.cached_voxels, "turtles" : self.turtles }
		with open(filepath, 'r') as file: self.cached_voxels = file.write( json.dumps( data ) )

	def load_database( self, filepath : str ) -> None:
		if not os.path.exists(filepath): raise FileNotFoundError
		with open(filepath, 'r') as file: data = json.loads( file.read() )
		self.cached_voxels = data.get('voxels')
		self.turtles = data.get('turtles')


from uuid import uuid4

# create a new turtle instance
def create_turtle_instance( ) -> str:
	nid = uuid4().hex
	return nid

# handle a turtle request given the id and data
def handle_turtle_request( turtle_id : int, data : dict ) -> tuple[bool, dict, str]:
	print( turtle_id, data )
	return True, None, "NotImplementedError"

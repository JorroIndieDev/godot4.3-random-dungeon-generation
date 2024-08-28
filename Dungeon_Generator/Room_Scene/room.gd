extends RigidBody2D
class_name dungeon_room
var size : Vector2
@onready var label: Label = $Label # for debug 

func _make_room(_pos:Vector2,_size:Vector2):
	position = _pos
	size = _size
	var shape = RectangleShape2D.new()
	# Hold CTL and click the custom_solver_bias 
	# to read the documentation if you want to understand it better
	shape.custom_solver_bias = .7
	shape.size = size
	$CollisionShape2D.shape = shape

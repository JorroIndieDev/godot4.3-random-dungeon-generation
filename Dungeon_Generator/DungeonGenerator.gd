extends Node2D
class_name dungeon_generator
'''
	If you do not intend to use the BetterTerrain plugin, disable it in:
	Project->Project Settings->Plugins and disable BetterTerrain
	as for the code every region that contains the better terrain plugin is marked
	so you can comment/delete that region and leave the other regions marked as Default
	TileMap
	
	I Have a video explaining the code and i also tried to leave comments in every line that
	I thought was relevant to explain further
	
	
'''
var Room_tscn := preload("res://Dungeon_Generator/Room_Scene/room.tscn")

## TileMapLayer with the tileset to make the map
@export var Map: TileMapLayer
@export var rooms_container: Node2D

## Running the game in debug mode will show every room boundery and path lines
@export var debug_mode: bool = false

#region Room generation configuration variables
@export_category("RoomGen config")
## Size of the tiles in your tileset
@export var tile_size: int = 16
## minimum size of the rooms
@export var min_size: int = 15
## maximum size of the rooms
@export var max_size: int = 16
## Maximum number of rooms to generate
@export var num_roms: int = 50
## percentage value of how many of the generated rooms to delete
@export var cull: float = 0.5
## Horizontal spread of the rooms when generating
@export var hspread: int = 100 
#endregion

# Array that will hold the rooms organized from left to right with their connections
var ordered_rooms: Array
# for safety
var is_generating: bool = false

#region BetterTerrain
var changeset: Dictionary = {}
#endregion

func _ready() -> void:
	randomize()
	make_rooms()

func _draw() -> void:
	if debug_mode:
		for room:dungeon_room in rooms_container.get_children():
			draw_rect(Rect2(room.position - room.size,room.size),Color(0,1,0),false)
		if ordered_rooms != [] and !is_generating:
			for i in ordered_rooms:
				draw_line(i[0].position - i[0].size/2,i[1].position - i[1].size/2,Color(1,0,0,.5),3,true)

func _process(delta: float) -> void:
	
	if debug_mode: queue_redraw()
	
#region BetterTerrain
	if BetterTerrain.is_terrain_changeset_ready(changeset):
		BetterTerrain.apply_terrain_changeset(changeset)
		changeset = {}
#endregion

func _input(event: InputEvent) -> void:
	if debug_mode:
		if Input.is_action_just_pressed("ui_accept") and !is_generating: # Space / Enter
			
			clear_rooms()
			make_rooms()
		
		if Input.is_action_just_pressed("ui_cancel") and !is_generating: # Escape
			for i in range(ordered_rooms.size()-1,-1,-1):
				ordered_rooms.erase(ordered_rooms[i])
			
			make_map()
			
			ordered_rooms[0][0].label.text = "Start Room"
			ordered_rooms[-1][-1].label.text = "End Room"

## Function that instanciates the rooms and adds them to the container
func make_rooms() -> void:
	is_generating = true
	# this is only needed if you wish to make more squared rooms
	var rooms_size: Array = [min_size,max_size]
	
	for n in range(num_roms):
		
		var pos := Vector2(randi_range(0,hspread),0)
		
		var r : dungeon_room = Room_tscn.instantiate()
		# if you want to make more variated shapes uncomment
		# the lines bellow and delete the others along with the rooms_size array
		#var w: int = min_size + randi() % (max_size - min_size)
		#var h: int = min_size + randi() % (max_size - min_size)
		var w: int = rooms_size.pick_random()
		var h: int = rooms_size.pick_random()
		
		r._make_room(pos,Vector2(w,h)*tile_size)
		rooms_container.add_child(r)
		
	await get_tree().create_timer(1.1).timeout
	
	for room:dungeon_room in rooms_container.get_children():
		if randf() <= cull:
			room.queue_free()
		else:
			room.process_mode = RigidBody2D.PROCESS_MODE_DISABLED
	
	is_generating = false

## Function responsible for setting the tiles on the rooms and pathways 
func make_map() -> void:
	is_generating = true
	Map.clear()
	
	var full_rect := Rect2() as Rect2
	
	for room:dungeon_room in rooms_container.get_children():
		var rect = Rect2(room.position - room.size,room.size*2)
		full_rect = full_rect.merge(rect)
	
	var topleft = Map.local_to_map(full_rect.position)
	var bottomright = Map.local_to_map(full_rect.end)
	
#region BetterTerrain
	var update:Dictionary = {}
#endregion
	
	for x in range(topleft.x,bottomright.x):
		for y in range(topleft.y,bottomright.y):
#region BetterTerrain
			update[Vector2i(x,y)] = 2
#endregion
			#Map.set_cell(Vector2(x,y),0,Vector2i(8,7))
	
	ordered_rooms = []
	var connections: Array = []
	
	var rooms_sorted = rooms_container.get_children()
	rooms_sorted.sort_custom(func(a, b): return a.position.x - a.size.x / 2 < b.position.x - b.size.x / 2)
	
	for i in range(rooms_sorted.size() - 2):
		var room = rooms_sorted[i] # room
		var next_room = rooms_sorted[i+1] # next
		var next_next_room = rooms_sorted[i+2] # the room next to the next_room
		if room.position.distance_to(next_room.position) < room.position.distance_to(next_next_room.position):
			if not ([room,next_room] or [next_room,room]) in connections:
				connections.append([room,next_room])
		else:
			if not ([room,next_next_room] or [next_next_room,room]) in connections:
				connections.append([room,next_next_room])
		if i == rooms_sorted.size() - 3:
			connections.append([next_room,next_next_room])
	
	ordered_rooms = connections
	
	for room:dungeon_room in rooms_sorted:
		var size = floor(room.size / tile_size)
		var pos = Map.local_to_map(room.position)
		var ul = floor(room.position / tile_size) - size
		
		for x in range(2,size.x-1):
			for y in range(2,size.y-1):
#region BetterTerrain
				update[Vector2i(x + ul.x,y + ul.y)] = 3
#endregion
				#Map.set_cell(Vector2(x + ul.x,y + ul.y),0,Vector2i(9,7))
	
	for i in connections:
		var r1p = Map.local_to_map(i[0].position - i[0].size/2)
		var r2p = Map.local_to_map(i[1].position - i[1].size/2)
		carve_path(r1p,r2p,update)
	is_generating = false
#region BetterTerrain
	## BetterTerrain
	changeset = BetterTerrain.create_terrain_changeset(Map,update)
#endregion
	await get_tree().process_frame

## Function responsible for carving a pathway with tiles from [param _pos1] to [param _pos2]
func carve_path(_pos1:Vector2,_pos2:Vector2,_update:Dictionary) -> void:
	# you can remove the _update parameter if you are not using BetterTerrain
	var modifier_x = sign(_pos2.x - _pos1.x) # 1 -1
	var modifier_y = sign(_pos2.y - _pos1.y) # 1 -1
	
	if modifier_x == 0: modifier_x = pow(-1.0,randi() % 2)
	if modifier_y == 0: modifier_y = pow(-1.0,randi() % 2)
	
	var x_y = _pos1
	var y_x = _pos2
	
	if (randi()%2) > 0:
		x_y = _pos2
		y_x = _pos1
	
	for row in range(_pos1.y,_pos2.y,modifier_y):
#region BetterTerrain
		_update[Vector2i(y_x.x,row)] = 3
		_update[Vector2i(y_x.x + modifier_x,row)] = 3
#endregion
		#Map.set_cell(Vector2(y_x.x,row),0,Vector2i(9,7))
		#Map.set_cell(Vector2(y_x.x + modifier_y,row),0,Vector2i(9,7))
	for col in range(_pos1.x,_pos2.x,modifier_x):
#region BetterTerrain
		_update[Vector2i(col,x_y.y)] = 3
		_update[Vector2i(col,x_y.y + modifier_y)] = 3
#endregion
		#Map.set_cell(Vector2(col,x_y.y),0,Vector2i(9,7))
		#Map.set_cell(Vector2(col,x_y.y + modifier_y),0,Vector2i(9,7))

## Call this function after the rooms are no longer needed
## Function will clear all rooms, including the container if [param clr_all] is true
## All rooms include the array of ordered rooms, so that it does not hold references to non existing objects
func clear_rooms(clr_all: bool = false):
	for room in rooms_container.get_children():
		room.queue_free()
	for i in range(ordered_rooms.size()-1,-1,-1):
		ordered_rooms.erase(ordered_rooms[i])
	if clr_all:
		rooms_container.queue_free()

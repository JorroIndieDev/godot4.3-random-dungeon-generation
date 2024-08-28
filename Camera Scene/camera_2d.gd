extends Camera2D

func _process(delta: float) -> void:
	var dir := Vector2(Input.get_axis("Left","Right"),Input.get_axis("Up","Down"))
	position += dir * 10

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("zoom_in"):
		var zoom_val = clamp(self.zoom.x + 0.1,0.1,10)
		self.zoom = Vector2(zoom_val,zoom_val) 
	
	if Input.is_action_pressed("zoom_out"):
		var zoom_val = clamp(self.zoom.x - 0.1,0.1,10)
		self.zoom = Vector2(zoom_val,zoom_val)

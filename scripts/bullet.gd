extends Area2D

var speed = 1100
var direction = Vector2.RIGHT
var shooter_id = 0

func set_direction(new_direction):
	direction = new_direction
	
func _physics_process(delta):
	position += direction * speed * delta


func _on_body_entered(body):
	if not multiplayer.is_server():
		return
		
	if body is TileMap:
		queue_free()
		return
		
	if str(body.name) == str(shooter_id):
			return
		
	if body.is_in_group("player") or body.is_in_group("mobs"):
		if body.has_method("take_damage"):
			body.take_damage.rpc(1, shooter_id)
		
		queue_free()





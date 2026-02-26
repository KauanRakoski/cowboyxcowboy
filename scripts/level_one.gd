extends Node2D

const PLAYER_SCENE = preload("res://Scenes/player.tscn")
const match_draw = "DRAW"

@onready var players_container = $Players
@onready var countdownTimer = $Control/HBoxContainer/MarginContainer/countdown
@onready var projectiles_container = $Projectiles
@onready var start_sfx = $start_sfx
@onready var music_player = $music

@export var bullet_scene: PackedScene

func _ready():
	if multiplayer.is_server():
		add_player(1)
		
		for id in multiplayer.get_peers():
			add_player(id)
		
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	$PlayerSpawner.spawned.connect(_on_player_spawned)
	
	start_sfx.play()
	await start_sfx.finished

	music_player.play()

func _on_player_spawned(player_node):
	player_node.score_updated.connect(_update_score)
	
func _process(_delta):
	var time = $Timer.time_left
	
	var minutes = floor(time / 60)
	var seconds = int(time) % 60

	countdownTimer.text = "%d:%02d" % [minutes, seconds]
		
func add_player(id):
	var player = PLAYER_SCENE.instantiate()
	player.request_shoot.connect(_on_request_shoot)
	player.score_updated.connect(_update_score)
	player.name = str(id)
	
	players_container.add_child(player)
	player.global_position = get_best_spawn_point()
	
func remove_player(id):
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()
		
func _on_request_shoot(bullet_position, bullet_direction, shooter_id):
	var bullet_angle = bullet_direction.angle()

	var bullet = bullet_scene.instantiate()
	bullet.shooter_id = shooter_id
	
	projectiles_container.add_child(bullet)	
	
	bullet.global_position = bullet_position
	bullet.direction = bullet_direction
	bullet.rotation = bullet_angle

@rpc("call_local", "reliable")
func _update_score(new_score, player_id):
	if player_id == "1":
		$Control/HBoxContainer/PointsP1.text = str(new_score)
	else:
		$Control/HBoxContainer/PointsP2.text = str(new_score)


# =============================
#	     SPAWN LOGIC
# =============================
# Verificar função !!!
func get_best_spawn_point():
	var spawns = $SpawnPoints.get_children()
	var players_list = $Players.get_children()
	
	if spawns.is_empty():
		return Vector2.ZERO
	
	if players_list.is_empty():
		return spawns.pick_random().global_position
	
	var best_spawn = null
	var max_safety_distance = -1.0
	
	for spawn in spawns:
		var min_dist_to_enemy = INF 
		
		for player in players_list:
			if player.is_dead: 
				continue
				
			var dist = spawn.global_position.distance_to(player.global_position)
			
			if dist < min_dist_to_enemy:
				min_dist_to_enemy = dist
		
		if min_dist_to_enemy > max_safety_distance:
			max_safety_distance = min_dist_to_enemy
			best_spawn = spawn
	
	if best_spawn == null:
		return spawns.pick_random().global_position
		
	return best_spawn.global_position
	
	
# ==========================
#	GAME OVER LOGIC
# ==========================
func _on_timer_timeout():
	end_game()
	
func end_game():
	if not multiplayer.is_server():
		return
		
	var winner_id = match_draw
	var highest_score = 0
	var scores = []
	
	for player in $Players.get_children():
		scores.append(player.score)
		if player.score > highest_score:
			highest_score = player.score
			winner_id = player.name
		
	if is_draw(scores):
		winner_id = match_draw
			 
	display_game_over.rpc(winner_id)
	
func is_draw(scores):
	if scores.max() == scores.min():
		return true
	
	return false

@rpc("call_local", "authority", "reliable")
func display_game_over(winner_id):
	get_tree().paused = true
	
	music_player.stop()
	
	var my_id = multiplayer.get_unique_id()
	var my_score = 0
	
	var my_player_node = $Players.get_node_or_null(str(my_id))
	if my_player_node:
		my_score = my_player_node.score
		
		$GameOver.set_game_over_state(winner_id, my_score)
		$GameOver.unhide()

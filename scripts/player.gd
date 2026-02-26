extends CharacterBody2D

const speed = 300
const MAX_HEALTH = 3

@onready var shoot_sfx = $shootAudio
@onready var hurt_sfx = $hurtAudio
@onready var step_sfx = $footstepsAudio

@onready var step_timer = $stepTimer
var last_direction = Vector2.DOWN

signal request_shoot
signal score_updated

var is_attacking = false
var health = MAX_HEALTH
var score = 0

var coin_multiplier = 1
var coins = 0

var is_dead = false

signal coin_collected(new_amount)
signal damage_taken(new_health)

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	var camera = $Camera2D
	
	if is_multiplayer_authority():
		camera.make_current()
	
	else:
		camera.enabled = false
	
func _physics_process(_delta):
	if is_dead:
		return
				
	if is_multiplayer_authority():
		
		var direction = Input.get_vector("input_left", "input_right", "input_up", "input_down")
		velocity = direction * speed
		
		if !velocity == Vector2.ZERO: 
			last_direction = direction
		
		move_and_slide()
		
		if Input.is_action_just_pressed("input_shoot"):
			shoot.rpc()
			
	if is_attacking:
		return
		
	if !velocity == Vector2.ZERO:
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				$AnimatedSprite2D.play("walk_right")
			else:
				$AnimatedSprite2D.play("walk_left")
		else:
			if last_direction.y > 0:
				$AnimatedSprite2D.play("walk_down")
			else:
				$AnimatedSprite2D.play("walk_up")
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")

@rpc("call_local", "authority", "reliable")
func shoot():
	if is_attacking:
		return
	
	is_attacking = true
	velocity = Vector2.ZERO
	
	play_attack_animation()
	
	await get_tree().create_timer(0.2).timeout
	
	shoot_sfx.play()
	if multiplayer.is_server():
		var bullet_position = global_position - Vector2(0, 35)
		var bullet_direction = last_direction
		
		request_shoot.emit(bullet_position, bullet_direction, name.to_int())
	
@rpc("call_local", "authority", "reliable")
func play_attack_animation():
	if last_direction.y < 0:
		$AnimatedSprite2D.play("shoot_up")
	elif last_direction.y > 0:
		$AnimatedSprite2D.play("shoot_down")
	elif last_direction.x > 0:
		$AnimatedSprite2D.play("shoot_right")
	elif last_direction.x < 0:
		$AnimatedSprite2D.play("shoot_left")

func _on_animated_sprite_2d_animation_finished():
	if "shoot" in $AnimatedSprite2D.animation:
		is_attacking = false

@rpc("call_local", "any_peer", "reliable")
func take_damage(amount, attacker_id):
	if is_dead:
		return
		
	health -= amount
	modulate = Color(1, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2) 
	
	hurt_sfx.play()
	damage_taken.emit(health)
	if health <= 0:
		die.rpc(attacker_id)

func spend_coins(amount):
	if coins >= amount:
		coins -= amount
		coin_collected.emit(coins)
		return true
	return false
	
func add_coin(num_coins):
	coins += num_coins
	coin_collected.emit(coins)

@rpc("call_local", "any_peer","reliable")
func die(killer_id):
	if is_dead or not can_alter():
		return
		
	is_dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false) 
	$CollisionShape2D.set_deferred("disabled", true)
 
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	
	if multiplayer.is_server():
		var killer_node = get_parent().get_node_or_null(str(killer_id))
		
		if killer_node:
			killer_node.add_score(1)
		
		respawn.rpc()

@rpc("call_local", "any_peer", "reliable")	
func respawn():
	if not multiplayer.is_server():
		return
	
	var spawn_pos = Vector2.ZERO
	var level = get_parent().get_parent()
	
	if level.has_method("get_best_spawn_point"):
		spawn_pos = level.get_best_spawn_point()
	else:
		spawn_pos = global_position
		
	revive_visuals.rpc(spawn_pos)

@rpc("call_local", "any_peer","reliable")
func revive_visuals(new_position):
	if not can_alter():
		return
	
	global_position = new_position
	
	health = MAX_HEALTH
	is_dead = false
	is_attacking = false
	velocity = Vector2.ZERO
	
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	
	modulate = Color(1, 1, 1) 
	$AnimatedSprite2D.play("idle")
	
func add_score(amount):
	if multiplayer.is_server():
		score += amount
		update_score_ui.rpc(score, name)
	
@rpc("call_local", "any_peer","reliable")
func update_score_ui(new_val, player_id):
	score = new_val
	score_updated.emit(score, player_id)
	
func can_alter():
	var sender_id = multiplayer.get_remote_sender_id()
	
	if sender_id != 0 and sender_id != 1:
		return false
	
	return true
	
	
# ====================
#  FOOTSTEPS LOGIC
# ====================
func handle_footsteps():
	if velocity.length() > 0:
		if step_timer.is_stopped():
			play_step_sound()
			step_timer.start()
			
		else:
			step_timer.stop()

func play_step_sound():
	step_sfx.pitch_scale = randf_range(0.8, 1.2)
	step_sfx.play()

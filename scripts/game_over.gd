extends CanvasLayer

@onready var status_label = $ColorRect/VBoxContainer/StatusLabel
const match_draw = "DRAW"
@onready var won_sound = $won_sfx
@onready var lost_sound = $lost_sfx
@onready var draw_sound = $draw_sfx

var sound_to_play = null

func _ready():
	hide()

func unhide():
	sound_to_play.play()
	show()

func set_game_over_state(winner_id, my_final_score):
	var my_id = multiplayer.get_unique_id()
	
	$ColorRect/VBoxContainer/ScoreLabel.text = "My score: " + str(my_final_score)
	
	if winner_id == match_draw:
		status_label.text = "It's a Draw"
		sound_to_play = draw_sound
		return
		
	if (winner_id == str(my_id)):
		status_label.text = 'You Won!'
		sound_to_play = won_sound
		status_label.modulate = Color.GREEN
	else:
		status_label.text = 'You Lost!'
		sound_to_play = lost_sound
		status_label.modulate = Color.RED
		
func _input(event):
	if visible:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("input_shoot"):
			quit_to_main_menu()
			
func quit_to_main_menu():
	get_tree().paused = false
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	
	multiplayer.multiplayer_peer = null
	
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://Scenes/start_screen.tscn")

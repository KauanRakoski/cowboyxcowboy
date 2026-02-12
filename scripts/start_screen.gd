extends CanvasLayer

@onready var menu_inicial = $MarginContainer/InitialMenu
@onready var menu_host = $MarginContainer/MenuHost
@onready var menu_join = $MarginContainer/MenuJoin

@onready var room_code_label = $MarginContainer/MenuHost/VBoxContainer/RoomCode

@onready var input_ip = $MarginContainer/MenuJoin/VBoxContainer/InputCode
@onready var btn_start_game = $MarginContainer/MenuHost/VBoxContainer/StartBtn

@onready var host_button = $MarginContainer/InitialMenu/Butons/HBoxContainer/Host
@onready var connect_button = $MarginContainer/MenuJoin/VBoxContainer/BtnConnect

@onready var status_label = $MarginContainer/MenuHost/VBoxContainer/StatusLabel
@onready var warn_join_text = $MarginContainer/MenuJoin/VBoxContainer/WarnJoin

var current_screen = "initial"

const PLAYERS_NEEDED_TO_START_GAME = 2

func _ready():
	show_screen("initial")
	host_button.pressed.connect(_on_host_pressed)
	
	connect_button.pressed.connect(_on_connect_pressed)
	btn_start_game.pressed.connect(_on_start_pressed)
	
	NetworkManager.player_list_updated.connect(_on_players_joined)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	NetworkManager.room_created.connect(_on_room_created)
	
func show_screen(screen_name):
	menu_inicial.visible = false
	menu_host.visible = false
	menu_join.visible = false
	
	current_screen = screen_name
	
	if screen_name == "initial":
		menu_inicial.visible = true
	elif screen_name == "host":
		menu_host.visible = true
		btn_start_game.disabled = true
	elif screen_name == "join":
		menu_join.visible = true
		warn_join_text.visible = false
		input_ip.text = ""

func _on_host_pressed():
	show_screen("host")
	NetworkManager.host_game()

func _on_connect_pressed():
	var room = input_ip.text
	NetworkManager.join_game(room)

func _on_start_pressed():
	NetworkManager.start_game()
	
func _on_join_pressed():
	show_screen("join")

func _on_btn_cancel_pressed():
	NetworkManager.stop_connection()
	show_screen("initial")
	
func enable_start_button():
	btn_start_game.disabled = false

func disable_start_button():
	btn_start_game.disabled = true
	
func _on_players_joined(player_count):
	status_label.text = "Number of Players: " +  str(player_count) + "/2"
	
	if multiplayer.is_server() and player_count >= PLAYERS_NEEDED_TO_START_GAME:
		enable_start_button()
	else:
		disable_start_button()

func _on_connection_failed():
	if current_screen == "join":
		warn_join_text.text = 'Unable to join game. Check if the room exists.'
		warn_join_text.visible = true

func _on_server_disconnected():
	if current_screen == "join":
		warn_join_text.text = 'Server has been disconected, try again another time'
		warn_join_text.visible = true

func _on_room_created(room_code):
	# currently, room code is ip
	room_code_label.text = "Room Code: " + str(room_code)

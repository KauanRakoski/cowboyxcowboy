extends Node

var peer = ENetMultiplayerPeer.new()
const PORT = 6190

signal connection_ok
signal player_list_updated(count)
signal room_created(room_code)
signal connection_failed
signal server_disconnected

func _ready():
	multiplayer.connected_to_server.connect(on_connected_ok)
	multiplayer.connection_failed.connect(on_connected_fail)
	
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconected)
	
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game():
	var status = peer.create_server(PORT, 2)
	
	if status != OK:
		print("Erro ao criar servidor" + str(status))
		return
		
	multiplayer.multiplayer_peer = peer
	
	var my_ip = get_best_local_ipv4()
	room_created.emit(my_ip)
	
	print("Servidor iniciado! Esperando conexões...")
	_emit_player_count()
	
func join_game(ip_address):
	var status = peer.create_client(ip_address, PORT)
	
	if status != OK:
		on_connected_fail()
		return
	
	multiplayer.multiplayer_peer = peer
	print("Tentando conectar ao IP: " + ip_address)

func _on_server_disconnected():
	print("O servidor foi encerrado. Voltando ao menu...")
	server_disconnected.emit()
	stop_connection()
	
func on_connected_ok():
	print("Conectado com sucesso!")
	connection_ok.emit()
	
func on_connected_fail():
	connection_failed.emit()
	stop_connection()
	
func on_peer_connected(id):
	print("Peer connected")
	print("Um jogador conectou! ID: " + str(id))
	
	_emit_player_count()	

func on_peer_disconected(id):
	print("Peer disconected" + str(id))
	_emit_player_count()

func _emit_player_count():
	var count = multiplayer.get_peers().size() 
	if multiplayer.is_server():
		count += 1 
	player_list_updated.emit(count)
	
@rpc("authority", "call_local", "reliable")
func change_scene(scene_path):
	get_tree().change_scene_to_file(scene_path)
	
func start_game():
	if multiplayer.is_server():
		change_scene.rpc("res://Scenes/level_one.tscn")
		
func stop_connection():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	
func get_my_ip_address():
	var ip_address: String
	
	if OS.has_feature("windows"):
		if OS.has_environment("COMPUTERNAME"):
			ip_address = IP.resolve_hostname(
				OS.get_environment("COMPUTERNAME"), 
				1
			)

	elif OS.has_feature("linux") or OS.has_feature("macos"):
		if OS.has_environment("HOSTNAME"):
			ip_address = IP.resolve_hostname(
				OS.get_environment("HOSTNAME"), 
				1
			)
			
	return ip_address
	
func get_best_local_ipv4() -> String:
	var addresses := IP.get_local_addresses()

	for addr in addresses:
		if typeof(addr) != TYPE_STRING:
			continue

		# Apenas IPv4
		if addr.count(".") != 3:
			continue

		# Loopback
		if addr.begins_with("127."):
			continue

		# APIPA
		if addr.begins_with("169.254."):
			continue

		# Achamos um IPv4 válido (LAN ou VPN)
		return addr

	return ""

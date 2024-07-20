extends Node







#创建websocketserver
@onready var _server: WebSocketServer

#创建websocketclient
@onready var _client: WebSocketClient



var DEFAULT_PORT = 6666

# Max number of players.
const MAX_PEERS = 12

var peer = null

# Name for my player.
var player_name = "The Warrior"

# Names for remote players in id:name format.
var players = {}
var players_ready = []

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


# Callback from SceneTree.
func _player_connected(id):
	if bg000==1:
		return
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)

		


# Callback from SceneTree.
func _player_disconnected(id):
	unregister_player.rpc_id(0,id)
	if has_node("/root/"+tt): # Game is in progress.
		if multiplayer.is_server():
			game_error.emit("Player " + players[id] + " disconnected")
			#将end_game()注释，使其不重复使用
			#game_error告警弹窗才能正常弹出
			#end_game()
		else: # Game is not in progress.
			# Unregister this player.
			#unregister_player.rpc_id(0,id)
			#end_game()
			pass


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	connection_succeeded.emit()


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	game_error.emit("Server disconnected")
	#end_game()
	if has_node("/root/%s" %tt): # Game is in progress.
		# End it
		get_node("/root/%s" %tt).queue_free()

	game_ended.emit()
	players.clear()
	_client.close()
	multiplayer.multiplayer_peer=null


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	#移除peer
	multiplayer.set_multiplayer_peer(null) # Remove peer
	connection_failed.emit()


# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name):
	if bg000==0:
		var id = multiplayer.get_remote_sender_id()
		players[id] = new_player_name
	player_list_changed.emit()
	print(multiplayer.get_unique_id(),':',players)



@rpc("any_peer")
func unregister_player(id):
	#将key为id的元素移出字典
	players.erase(id)
	player_list_changed.emit()



@rpc("call_local")
func load_world():
	# Change scene.
	var world = load("res://game/"+tt+".tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

	# Set up score.
	world.get_node("Score").add_player(multiplayer.get_unique_id(), player_name)
	for pn in players:
		world.get_node("Score").add_player(pn, players[pn])
	get_tree().set_pause(false) # Unpause and unleash the game!


func host_game(new_player_name,port:int,max_peers:int):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	if peer.create_server(port, max_peers)!=OK:
		printerr('fail to create server')
		return
	multiplayer.set_multiplayer_peer(peer)
	


func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)
	print('jg')
	


func get_player_list():
	return players.values()


func get_player_name():
	return player_name



var bg000=0
var tt='0'
func begin_game():
	bg000=1

	print(_server.tcp_server.is_listening())
	assert(multiplayer.is_server())
	load_world.rpc()
	var world = get_tree().get_root().get_node(tt)
	var player_scene = load("res://player.tscn")
	
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1

	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instantiate()
		player.synced_position = spawn_pos
		player.name = str(p_id)
		player.set_player_name(player_name if p_id == multiplayer.get_unique_id() else players[p_id])
		world.get_node("Players").add_child(player)



func end_game():
	lvshow=0
	#print(get_tree().root.get_children())
	#print(tt)
	if has_node("/root/%s" %tt): # Game is in progress.
		# End it
		get_node("/root/%s" %tt).queue_free()

	game_ended.emit()
	players.clear()
	if multiplayer.is_server():
		bg000=0
		_server.stop()
		multiplayer.multiplayer_peer.close()
	else:
		_client.close()
		
		pass
		
	#自觉退
	if multiplayer.multiplayer_peer!=null:
		multiplayer.multiplayer_peer=null
		
	
	
func quit_game():
	
	pass



func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)



var lvshow=0
func _process(delta):
	pass



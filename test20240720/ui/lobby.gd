extends Control





func _ready():
	gamestate._server=$WebSocketServer
	gamestate._client=$WebSocketClient
	
	for i in range(6):
		$Players/lv.add_item(str(i))
		
	$Connect/Room.text=str(gamestate.DEFAULT_PORT)
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)
	gamestate.player_list_changed.connect(refresh_lobby)
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/Name.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		$Connect/Name.text = desktop_path[desktop_path.size() - 2]



func _process(_delta):
	if !$Connect.visible and gamestate.lvshow==1:
		$Players/lv.show()
	else:
		$Players/lv.hide()
	pass



func _on_host_pressed():
	#websocketserver
	var port = int($Connect/Room.text)
	if gamestate._server.listen(port)!= OK:
		printerr("Error listing on port %s" % port)
		return
	printerr("Listing on port %s, supported protocols: %s" % [port, gamestate._server.supported_protocols])
	
	
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return
	gamestate.lvshow=1
	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""

	var player_name = $Connect/Name.text
	gamestate.host_game(player_name,int($Connect/Room.text),gamestate.MAX_PEERS)
	refresh_lobby()



func _on_join_pressed():
	#引用websocketclient并连接url
	
	if gamestate._client.connect_to_url($Connect/IPAddress.text+':'+$Connect/Room.text)!= OK:
		printerr("Error connecting to host: %s" % $Connect/IPAddress.text)
		return
	#var ws = gamestate._client.get_socket()
	
	
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	var ip = $Connect/IPAddress.text
	#检查是否符合ip格式
	if not ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return

	$Connect/ErrorLabel.text = ""
	#$Connect/Host.disabled = true
	#$Connect/Join.disabled = true

	var player_name = $Connect/Name.text
	gamestate.join_game(ip, player_name)



func _on_connection_success():
	$Connect.hide()
	$Players.show()



func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")



func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false



func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false



func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)

	$Players/Start.disabled = not multiplayer.is_server()



func _on_start_pressed():
	gamestate.begin_game()



func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")



func _on_room_text_changed(_new_text):
	gamestate.DEFAULT_PORT=int($Connect/Room.text)
	
	pass # Replace with function body.




func _on_quit_pressed():
	gamestate.end_game()
	

		
	pass # Replace with function body.



func _on_ready_pressed():
	$Players/lvt.text=str(get_tree().get_first_node_in_group('game'))
	gamestate.tt=$Players/lvt.text
	pass # Replace with function body.



var aa=''
#点击lv列表条目时执行
func _on_lv_item_clicked(index, at_position, mouse_button_index):
	if mouse_button_index==1:
		$Players/lvt.text=$Players/lv.get_item_text(index)
		gamestate.tt=$Players/lv.get_item_text(index)
		#服务器向0：所有连接用户发送信息
		gamestate._server.send(0,gamestate.tt)



#客户端收到信息时执行
func _on_web_socket_client_message_received(message):
	print(message)
	gamestate.tt=message
	#将lvt标签的文本设置为接收到的信息
	$Players/lvt.text=message
	pass # Replace with function body.


#服务器与客户端建立连接时执行
func _on_web_socket_server_client_connected(peer_id):
	var peer: WebSocketPeer = gamestate._server.peers[peer_id]
	print("Remote client connected: %d. Protocol: %s" % [peer_id, peer.get_selected_protocol()])
	gamestate._server.send(-peer_id, "[%d] connected" % peer_id)
	#建立连接时服务器同步发送当前lvt信息
	gamestate._server.send(0,gamestate.tt)
	pass # Replace with function body.

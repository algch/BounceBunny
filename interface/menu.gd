extends Control

var player_name = ''
var server_address = ''

func _on_playerName_text_changed(text):
	player_name = text

func _on_serverAddress_text_changed(text):
	server_address = text

func _on_createServer_pressed():
	if player_name == '':
		return
	Network.create_server(player_name)
	loadGame()

func _on_joinServer_pressed():
	if player_name == '' or server_address == '':
		return
	Network.connectToServer(player_name, server_address)
	print(player_name, ' is connecting to ', server_address)
	loadGame()

func loadGame():
	get_tree().change_scene('res://worlds/mainArena.tscn')


# networking 

remote func _send_player_info(id, info):
	players[id] = info
	var new_player = load('res://player/Player.tscn').instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	$'/root/Game/'.add_child(new_player)
	new_player.init(info.name, info.position, true)

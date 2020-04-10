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
	var mainArena = load('res://worlds/mainArena.tscn').instance()
	mainArena.init('server', mainArena.DEFAULT_IP)
	mainArena.is_server = true # should be in init
	loadGame(mainArena)

func _on_joinServer_pressed():
	if player_name == '' or server_address == '':
		return
	var mainArena = load('res://worlds/mainArena.tscn').instance()
	mainArena.init('client', server_address)
	loadGame(mainArena)

func loadGame(scene):
	var root = get_tree().get_root()
	var menu = root.get_node('menu')
	root.remove_child(menu)
	menu.call_deferred('free')
	root.add_child(scene)


# networking 

remote func _send_player_info(id, info):
	var new_player = load('res://player/Player.tscn').instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	$'/root/Game/'.add_child(new_player)
	new_player.init(info.name, info.position, true)

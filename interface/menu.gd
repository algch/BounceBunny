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

func _ready():
	for ip in IP.get_local_addresses():
		if '192' in ip:
			$vbox/ip.set_text('your ip is ' + ip)

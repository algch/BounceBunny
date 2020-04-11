extends 'res://worlds/world.gd'

remote var available_positions = []

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 5

signal player_disconnected
signal server_disconnected

var is_server = false
var player_nickname = ''
var ip_address = DEFAULT_IP

remote var player_positions = {}

signal local_player_initialized

func init(nickname, ip):
	player_nickname = nickname
	ip_address = ip

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')
	for pos in get_tree().get_nodes_in_group('start_position'):
		available_positions.append(pos.position)
	if is_server:
		createServer()
	else:
		connectToServer()

func createServer():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	var pos = available_positions.pop_front()
	registerPlayer(1, pos, available_positions)

func connectToServer(): # 1
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	var peer = NetworkedMultiplayerENet.new()
	print('Requesting connection to lobby [' + ip_address + ']')
	peer.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func _connected_to_server(): # on client when connected to server
	print('we have connected to server')
	var local_player_id = get_tree().get_network_unique_id()
	rpc_id(1, 'requestGameState', local_player_id)
	print('game satate is synced')
	print('player positions ', player_positions)
	print('all graphs', all_graphs)
	print('available positions ', available_positions)

remote func requestGameState(requester_id):
	print('game state requested')
	rpc_id(requester_id, 'syncGameState', all_graphs, player_positions, available_positions)

remote func syncGameState(graphs, player_pos, available_pos):
	print('synced state receivd')
	print(graphs, player_pos, available_pos)
	all_graphs = graphs
	player_positions = player_pos
	available_positions = available_pos
	initPlayers()

func initPlayers():
	var pos = available_positions.pop_front()
	rpc('registerPlayer', get_tree().get_network_unique_id(), pos, available_positions)
	for p_id in player_positions:
		var p_pos = player_positions[p_id]
		registerPlayer(p_id, p_pos, available_positions)

remotesync func registerPlayer(player_id, pos, pos_list):
	attachNewGraph(player_id)
	var plant = load('res://plants/plant.tscn').instance()
	plant.init(pos)
	plant.set_network_master(player_id)
	add_child(plant)
	print(plant, ' was added')
	var player = load('res://player/player.tscn').instance()
	player.set_name(str(player_id))
	player.init('server', pos, plant)
	add_child(player)
	player_positions[get_tree().get_network_unique_id()] = pos
	if is_network_master():
		available_positions = pos_list
	print('[' + str(player_id) + '] has joined.' )

# remote func _send_player_info(id, pos): # 3
# 	attachNewGraph(id)
# 	print('remote _send_player_info')
# 	print(id, all_graphs, pos)
# 	var new_plant = load('res://plants/plant.tscn').instance()
# 	add_child(new_plant)
# 	new_plant.init(pos)
# 	var new_player = load('res://player/player.tscn').instance()
# 	new_player.name = str(id)
# 	new_player.set_network_master(id)
# 	add_child(new_player)
# 	new_player.init('jugador', pos, new_plant)

func _on_player_connected(connected_player_id):
	print('[' + str(connected_player_id) + '] has connected to server')
	# var local_player_id = get_tree().get_network_unique_id()
	# if not get_tree().is_network_server():
	# 	print('I am a client!')
	# 	rpc_id(1, 'printInServer', 'a message from the client')
		# rpc_id(1, '_request_player_info', local_player_id, connected_player_id)

remote func printInServer(message):
	print(message)

# remote func _request_player_info(request_from_id, player_id):
# 	print('_request_player_info ', request_from_id, player_id)
# 	if get_tree().is_network_server():
# 		print('I am a server!')
# 		var pos = Vector2(10 + randi()%500, 10 + randi()%500)
# 		print('calling _send_player_info to ', request_from_id)
# 		rpc_id(request_from_id, '_send_player_info', player_id, pos)

func _on_player_disconnected(id):
	print('player ', id, ' disconnected')
	# all_graphs.erase(id)

func getLocalPlayerNode():
	var player_path = '/root/mainArena/' + str(get_tree().get_network_unique_id())
	return get_node(player_path)

func getLocalGuiNode():
	return get_node('/root/mainArena/camera/gui')

func _on_bow_released():
	var player = getLocalPlayerNode()
	player.current_weapon = Globals.PROJECTILE_TYPES.ATTACK
	player.get_node('animation').set_animation('bow_0')
	player.get_node('animation').set_frame(0)
	player.get_node('animation').stop()

func _on_seed_released():
	var player = getLocalPlayerNode()
	player.current_weapon = Globals.PROJECTILE_TYPES.SUMMON
	player.get_node('animation').set_animation('summon_0')
	player.get_node('animation').set_frame(0)
	player.get_node('animation').stop()

func _on_options_released():
	var gui = getLocalGuiNode()
	gui.get_node('pauseScreen').visible = true
	gui.get_node('resumeRestart').visible = true
	gui.get_node('resumeRestart').set_process(true)
	gui.get_node('quit').visible = true
	gui.get_node('quit').set_process(true)

func _on_quit_released():
	get_tree().quit()

func _on_resumeRestart_released():
	var gui = getLocalGuiNode()
	gui.get_node('pauseScreen').visible = false
	gui.get_node('resumeRestart').visible = false
	gui.get_node('resumeRestart').set_process(false)
	gui.get_node('quit').visible = false
	gui.get_node('quit').set_process(false)

func _process(delta):
	var player = getLocalPlayerNode()
	if not player:
		return
	player.updateGui()
	player.update()

func _physics_process(delta):
	var player = getLocalPlayerNode()
	if not player:
		return
	player.aimingLoop()
	player.pollInput()

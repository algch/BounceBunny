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
var first_plant_id

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

remote func requestGameState(requester_id):
	print('game state requested')
	rpc_id(requester_id, 'initGameState', all_graphs, player_positions, available_positions, first_plant_id)

remote func initGameState(graphs, player_pos, available_pos, first_id):
	print('synced state receivd')
	print(graphs, player_pos, available_pos)
	all_graphs = graphs
	player_positions = player_pos
	available_positions = available_pos
	first_plant_id = first_id
	initPlayers()

func initPlayers():
	var pos = available_positions.pop_front()
	rpc('registerPlayer', get_tree().get_network_unique_id(), pos, available_positions)
	for p_id in player_positions:
		if p_id == get_tree().get_network_unique_id():
			continue
		var p_pos = player_positions[p_id]
		registerPlayer(p_id, p_pos, available_positions)

remotesync func registerPlayer(player_id, pos, pos_list):
	attachNewGraph(player_id)
	var plant = load('res://plants/plant.tscn').instance()
	if get_tree().is_network_server():
		first_plant_id = plant.get_instance_id()
	plant.init(pos, player_id, first_plant_id)
	# what should be the plant name?? check this!
	plant.set_network_master(player_id)
	add_child(plant)
	var player = load('res://player/player.tscn').instance()
	player.set_network_master(player_id)
	player.init('server', pos, plant.get_instance_id())
	add_child(player)
	player_positions[get_tree().get_network_unique_id()] = pos
	if is_network_master():
		available_positions = pos_list
	print('[' + str(player_id) + '] has joined.' )

func _on_player_connected(connected_player_id):
	print('[' + str(connected_player_id) + '] has connected to server')

remote func printInServer(message):
	print(message)

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

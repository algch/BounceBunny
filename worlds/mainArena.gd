extends 'res://worlds/world.gd'

remote var available_positions

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 5

signal player_disconnected
signal server_disconnected

var is_server = false
var player_nickname = ''
var ip_address = DEFAULT_IP

remote var player_positions = {}


func init(nickname, ip):
	player_nickname = nickname
	ip_address = ip

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')
	available_positions = get_tree().get_nodes_in_group('start_position')
	if is_server:
		createServer()
	else:
		connectToServer()

func createServer():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	attachNewGraph(1)
	var pos = available_positions.pop_front().position
	var plant = load('res://plants/plant.tscn').instance()
	plant.init(pos)
	plant.set_name(str(1))
	plant.set_network_master(str(1))
	add_child(plant)
	var player = load('res://player/player.tscn').instance()
	player.init('server', pos, plant)
	# add_child(player)
	player_positions[get_tree().get_network_unique_id()] = pos
	

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

	for p_id in player_positions:
		var plant = load('res://plants/plant.tscn').instance()
		plant.init(player_positions[p_id])
		plant.set_name(str(p_id))
		plant.set_network_master(p_id)
		add_child(plant)
		
	var pos = available_positions.pop_front().position
	rpc('registerPlayer', get_tree().get_network_unique_id(), pos, available_positions)

remote func requestGameState(graphs, player_pos, available_pos):
	rpc_id(requester_id, 'syncGameState', graphs, player_pos, available_pos)

remote func syncGameState(graphs, player_pos, available_pos):
	all_graphs = graphs
	player_positions = player_pos
	available_positions = available_pos

remotesync func registerPlayer(player_id, pos, pos_list):
	print('rigistering player...')
	attachNewGraph(player_id)
	var plant = load('res://plants/plant.tscn').instance()
	plant.init(pos + Vector2(200, 200))
	plant.set_name(str(player_id))
	plant.set_network_master(player_id)
	add_child(plant)
	print(plant, ' was added')
	var player = load('res://player/player.tscn').instance()
	player.init('server', pos, plant)
	# add_child(player)
	player_positions[get_tree().get_network_unique_id()] = pos
	if is_network_master():
		player_positions = pos_list
	print('player registered')

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

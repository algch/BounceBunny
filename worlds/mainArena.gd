extends 'res://worlds/world.gd'

onready var empty_positions = get_tree().get_nodes_in_group('start_position')

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 5

signal player_disconnected
signal server_disconnected

var is_server = false
var player_nickname = ''
var ip_address = DEFAULT_IP


func init(nickname, ip):
	player_nickname = nickname
	ip_address = ip

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')
	if is_server:
		create_server()
	else:
		connectToServer()

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	attachNewGraph(1)
	var plant = load('res://plants/plant.tscn').instance()
	plant.init(Vector2(200, 200))
	add_child(plant)
	var player = load('res://player/player.tscn').instance()
	player.init('server', Vector2(200, 200), plant)
	add_child(player)
	

func connectToServer(): # 1
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	var peer = NetworkedMultiplayerENet.new()
	print('connecting to...', ip_address)
	peer.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func _connected_to_server(): # when does this happen?
	print('_connected_to_server called')
	var local_player_id = get_tree().get_network_unique_id()
	print('created a new graph ', local_player_id)
	print('all graphs ', all_graphs)
	var pos = Vector2(10 + randi()%500, 10 + randi()%500)
	print('position of new graph ', pos)
	rpc('_send_player_info', local_player_id, pos)

remote func _send_player_info(id, pos): # 3
	attachNewGraph(id)
	print('remote _send_player_info')
	print(id, all_graphs, pos)
	var new_plant = load('res://plants/plant.tscn').instance()
	add_child(new_plant)
	new_plant.init(pos)
	var new_player = load('res://player/player.tscn').instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	add_child(new_player)
	new_player.init('jugador', pos, new_plant)

func _on_player_connected(connected_player_id): # 2
	print('_on_player_connected ', connected_player_id)
	var local_player_id = get_tree().get_network_unique_id()
	if not get_tree().is_network_server():
		print('I am a client!')
		rpc_id(1, '_request_player_info', local_player_id, connected_player_id)

remote func _request_player_info(request_from_id, player_id):
	print('_request_player_info ', request_from_id, player_id)
	if get_tree().is_network_server():
		print('I am a server!')
		var pos = Vector2(10 + randi()%500, 10 + randi()%500)
		rpc_id(request_from_id, '_send_player_info', player_id, pos)

func _on_player_disconnected(id):
	all_graphs.erase(id)

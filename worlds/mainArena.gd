extends 'res://worlds/world.gd'

onready var empty_positions = get_nodes_in_group('start_position')

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')


func _connected_to_server(): # triggered on connected_to_server
	var local_player_id = get_tree().get_network_unique_id()
	attachNewGraph(local_player_id)
	var pos = Vector2(10 + randi()%500, 10 + randi()%500)
	rpc('_send_player_info', local_player_id, all_graphs, pos)

remote func _send_player_info(id, all_graphs, pos):
	var new_plant = load('res://plants/plant.tscn').instance()
	add_child(new_plant)
	new_plant.init(pos)
	var new_player = load('res://player/player.tscn').instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	add_child(new_player)
	new_player.init('jugaor', pos)

func _on_player_connected(connected_player_id):
	var local_player_id = get_tree().get_network_unique_id()
	if not get_tree().is_network_server():
		rpc_id(1, '_request_player_info', local_player_id, connected_player_id)

remote func _request_player_info(request_from_id, player_id):
	if get_tree().is_network_server():
        rpc_id(request_from_id, '_send_player_info', player_id, all_graphs[player_id])

func _on_player_disconnected(id):
	all_graphs.erase(id)


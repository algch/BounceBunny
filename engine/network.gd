extends Node

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 5

var players = {}
var self_data = { name = '', position = Vector2(0, 0) }

signal player_disconnected
signal server_disconnected

func create_server(player_nickname):
	self_data.name = player_nickname
	players[1] = self_data
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)

func connectToServer(player_nickname, ip_address):
	self_data.name = player_nickname
	var mainArena = get_node('/root/mainArena')
	get_tree().connect('connected_to_server', mainArena, '_connected_to_server')
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

# A function to be used if needed. The purpose is to request all players in the current session.
remote func _request_players(request_from_id):
	if get_tree().is_network_server():
		for peer_id in players:
			if( peer_id != request_from_id):
				rpc_id(request_from_id, '_send_player_info', peer_id, players[peer_id])

func update_position(id, position):
    players[id].position = position

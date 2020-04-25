extends Node

var plant_class = preload('res://plants/plant.tscn')

remote var all_graphs = {}
var server_2_local = {}

func getLocalPlayerNode():
	var player_path = '/root/mainArena/' + str(get_tree().get_network_unique_id())
	return get_node(player_path)

func attachNewGraph(graph_id):
	all_graphs[graph_id] = {}

func removeGraph(graph_id):
	if graph_id in all_graphs:
		all_graphs.erase(graph_id)

func addServerNode(player, pos):
	var graph_id = int(player.get_name())
	print('addServerNode graph_id ', graph_id)
	var neighbor_id = player.current_plant

	var plant = plant_class.instance()
	var plant_id = plant.get_instance_id()
	plant.init(pos, player.get_name(), plant_id)
	add_child(plant)

	server_2_local[neighbor_id] = neighbor_id
	server_2_local[plant_id] = plant_id
	print('server 2 local ', server_2_local)

	var neighbor_plant = instance_from_id(neighbor_id)
	neighbor_plant.addNeighbor(plant)
	plant.addNeighbor(neighbor_plant)

	var plants_graph = all_graphs[graph_id]
	if neighbor_id in plants_graph:
		plants_graph[neighbor_id][plant_id] = plant_id
	else:
		plants_graph[neighbor_id] = { plant_id: plant_id }

	if plant_id in plants_graph:
		plants_graph[plant_id][neighbor_id] = neighbor_id
	else:
		plants_graph[plant_id] = { neighbor_id: neighbor_id }

	rpc('addClientNode', graph_id, plant_id, neighbor_id, pos)

remote func addClientNode(graph_id, server_plant_id, server_neighbor_id, pos):
	print('addClientNode graph_id ', graph_id)
	var plants_graph = all_graphs[graph_id]

	var player = Globals.getLocalPlayer()

	var plant = plant_class.instance()
	var local_plant_id = plant.get_instance_id()
	plant.init(pos, graph_id, server_plant_id)
	add_child(plant)

	server_2_local[server_neighbor_id] = player.current_plant
	server_2_local[server_plant_id] = local_plant_id
	print('server 2 local ', server_2_local)

	# SOMETHING VERY WEIRD IS HAPPENING HERE
	print('player current plant ', str(player.current_plant))
	var neighbor_plant = instance_from_id(int(player.current_plant))
	neighbor_plant.addNeighbor(plant)
	plant.addNeighbor(neighbor_plant)
	
	if server_neighbor_id in plants_graph:
		plants_graph[server_neighbor_id][server_plant_id] = local_plant_id
	else:
		plants_graph[server_neighbor_id] = { server_plant_id: local_plant_id }

	if server_plant_id in plants_graph:
		plants_graph[server_plant_id][server_neighbor_id] = player.current_plant
	else:
		plants_graph[server_plant_id] = { server_neighbor_id: player.current_plant }

func addNode(graph_id, source, dest, dest_instance):
	var plants_graph = all_graphs[graph_id]
	if source in plants_graph:
		plants_graph[source][dest] = dest_instance
	else:
		plants_graph[source] = { dest: dest_instance }

func removeNode(graph_id, node_id):
	var plants_graph = all_graphs[graph_id]
	for id in plants_graph:
		if node_id in plants_graph[id]:
			plants_graph[id].erase(node_id)
	plants_graph.erase(node_id)

func removeIfDetached(graph_id, node_id):
	var plants_graph = all_graphs[graph_id]
	var queue = [node_id]
	var visited = { node_id: true }
 
	while queue:
		var current_id = queue.pop_front()

		var player = getLocalPlayerNode()
		if current_id == player.current_plant:
			return

		for id in plants_graph[current_id]:
			if not id in visited:
				queue.append(plants_graph[current_id][id])
				visited[id] = true

	var node = instance_from_id(node_id)
	node.destroy()

func getNeighborIds(graph_id, node_id):
	if not graph_id in all_graphs:
		return []
	var plants_graph = all_graphs[graph_id]
	if node_id in plants_graph:
		var neighbors = plants_graph[node_id].values()
		neighbors.sort()
		return neighbors
	return []

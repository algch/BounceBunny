extends Node

var all_graphs = {}
# TODO handle player position in its own graph

func attachNewGraph(graph_id):
	all_graphs[graph_id] = {}

func removeGraph(graph_id):
	if graph_id in all_graphs:
		all_graphs.erase(graph_id)

func addNode(graph_id, source, dest):
	var plants_graph = all_graphs[graph_id]
	var source_id = source.get_instance_id()
	var dest_id = dest.get_instance_id()
	if source_id in plants_graph:
		plants_graph[source_id][dest_id] = dest
	else:
		plants_graph[source_id] = { dest_id: dest }

func removeNode(graph_id, node):
	var plants_graph = all_graphs[graph_id]
	var node_id = node.get_instance_id()
	for id in plants_graph:
		if node_id in plants_graph[id]:
			plants_graph[id].erase(node_id)
	plants_graph.erase(node_id)

func removeIfDetached(graph_id, node):
	var plants_graph = all_graphs[graph_id]
	var node_id = node.get_instance_id()
	var queue = [node]
	var visited = { node_id: true }
 
	while queue:
		var current = queue.pop_front()
		var current_id = current.get_instance_id()

		var player = get_node('/root/mainArena/player/')
		if current == player.current_plant:
			return

		for id in plants_graph[current_id]:
			if not id in visited:
				queue.append(plants_graph[current_id][id])
				visited[id] = true

	node.destroy()

func getNeighbors(graph_id, node):
	var plants_graph = all_graphs[graph_id]
	var node_id = node.get_instance_id()
	return plants_graph[node_id].values() if node_id in plants_graph else []

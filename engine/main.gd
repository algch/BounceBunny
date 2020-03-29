extends Node

var spider_class = preload('res://enemies/spider/spider.tscn')
var SPIDER_EXTENTS = Vector2(50, 50)

var TILE_SIZE = 20
var TILE_TYPES = 3

var CHANGE_TILE_PROBABILITY = 50
var MIN_TILE_STRIP_SIZE = 5

onready var SCREEN_SIZE = get_viewport().size
var X
var Y

var last_tile = null
var spawn_timer = Timer.new()
var shouldSpawn = false
onready var player = get_node('player')
var GAME_OVER = false
var score = 0
var total_plants = 0

onready var plants_graph = {}

func addNode(source, dest):
	var source_id = source.get_instance_id()
	var dest_id = dest.get_instance_id()
	if source_id in plants_graph:
		plants_graph[source_id][dest_id] = dest
	else:
		plants_graph[source_id] = { dest_id: dest }

func removeNode(node):
	var node_id = node.get_instance_id()
	for id in plants_graph:
		if node_id in plants_graph[id]:
			plants_graph[id].erase(node_id)
	plants_graph.erase(node_id)

func removeIfDetached(node):
	var node_id = node.get_instance_id()
	var queue = [node]
	var visited = { node_id: true }
 
	while queue:
		var current = queue.pop_front()
		var current_id = current.get_instance_id()

		if current == player.current_plant:
			return

		for id in plants_graph[current_id]:
			if not id in visited:
				queue.append(plants_graph[current_id][id])
				visited[id] = true

	node.destroy()

func getNeighbors(node):
	var node_id = node.get_instance_id()
	return plants_graph[node_id].values() if node_id in plants_graph else []

func gameOver():
	print('game over')
	GAME_OVER = true
	player.queue_free()

func getRandomPosition():
	return Vector2(
		randi() % int(SCREEN_SIZE.x - 20) + 20,
		randi() % int(SCREEN_SIZE.y - 20) + 20
	)

func spawnEnemy():
	# TODO use this function to position spawners in the map
	var spider = spider_class.instance()

	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.set_extents(SPIDER_EXTENTS)

	var coll_shape = CollisionShape2D.new()
	coll_shape.shape = rectangle_shape
	

	# TODO 
	# looks like this can be solved using shapes only
	# check https://godotengine.org/qa/18952/area2d-code-building-array-get_overlapping_bodies-method
	var pos_tester = Area2D.new()
	pos_tester.position = getRandomPosition()
	pos_tester.add_child(coll_shape)
	add_child(pos_tester)
	yield(get_tree(), "physics_frame")
	
	var dist_to_player = player.position.distance_to(pos_tester.position)

	var overlap = pos_tester.get_overlapping_bodies() + pos_tester.get_overlapping_areas()
	yield(get_tree(), "physics_frame")

	while overlap or dist_to_player < 320:
		pos_tester.position = getRandomPosition()
		yield(get_tree(), "physics_frame")
		overlap = pos_tester.get_overlapping_bodies()
		dist_to_player = player.position.distance_to(pos_tester.position)
	
	add_child(spider)
	spider.position = pos_tester.position

func spawnLoop():
	if GAME_OVER or not is_instance_valid(player) or player.is_queued_for_deletion():
		return
	if shouldSpawn and len(get_tree().get_nodes_in_group('enemies')) < 5:
		spawnEnemy()
		spawn_timer.set_wait_time(2.5)
		spawn_timer.start()
		shouldSpawn = false

func setSpawn():
	shouldSpawn = true

func getRandomTileId():
	var tile = int(rand_range(0, TILE_TYPES))
	while tile == last_tile:
		tile = int(rand_range(0, TILE_TYPES))
	last_tile = tile
	return tile


func shouldChangeTile():
	return (randi() % 100) < CHANGE_TILE_PROBABILITY


func isOnCorner(coord):
	var x = coord.x
	var y = coord.y

	var is_on_corner = false

	if x == 0 and y == Y - 1:
		is_on_corner = true
	if x == X - 1 and y == 0:
		is_on_corner = true
	if x == X - 1 and y == Y - 1:
		is_on_corner = true

	return is_on_corner

func _ready():
	spawn_timer.connect('timeout', self, 'setSpawn')
	add_child(spawn_timer)
	spawn_timer.start()

func _physics_process(delta):
	spawnLoop()

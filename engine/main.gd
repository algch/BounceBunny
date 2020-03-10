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

func getRandomPosition():
	return Vector2(
		randi() % int(SCREEN_SIZE.x - 20) + 20,
		randi() % int(SCREEN_SIZE.y - 20) + 20
	)

func spawnEnemy():
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
	
	var player = get_node('player')
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
	if shouldSpawn:
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
	var tilemap = $tilemap
	tilemap.clear()
	randomize()

	X = SCREEN_SIZE.x / TILE_SIZE
	Y = SCREEN_SIZE.y / TILE_SIZE

	var steps = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]

	var tiles_left = MIN_TILE_STRIP_SIZE
	var tile = getRandomTileId()
	var coord = Vector2(0, 0)
	var step = steps.pop_front()
	for i in range(0, 2 * (X + Y) - 2):
		if isOnCorner(coord):
			step = steps.pop_front()
		if tiles_left <= 0 and shouldChangeTile():
			tile = getRandomTileId()
			tiles_left = MIN_TILE_STRIP_SIZE
		tilemap.set_cellv(coord, tile)
		tiles_left -= 1

		coord += step

	spawn_timer.connect('timeout', self, 'setSpawn')
	add_child(spawn_timer)
	spawn_timer.start()

func _physics_process(delta):
	spawnLoop()

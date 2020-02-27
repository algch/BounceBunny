extends Node

var TILE_SIZE = 20
var TILE_TYPES = 3

var CHANGE_TILE_PROBABILITY = 50
var MIN_TILE_STRIP_SIZE = 5

var X
var Y

var last_tile = null


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

	var screen_size = get_viewport().size
	X = screen_size.x / TILE_SIZE
	Y = screen_size.y / TILE_SIZE

	print(X, Y)

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

extends KinematicBody2D

var direction = Vector2(0,0)
var SPEED = 500

func _ready():
	print('hello bitches')
	print(position)
	print(direction)

func _physics_process(delta):
	var motion = direction * SPEED * delta
	var collision = move_and_collide(motion)

	if collision:
		var collider = collision.collider
		direction = direction.bounce(collision.normal)
		if collider is TileMap:
			var tile_pos = collider.world_to_map(position) - collision.normal
			var tile = collision.collider.get_cellv(tile_pos)
			print('tile is ' + str(tile))

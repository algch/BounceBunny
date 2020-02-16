extends KinematicBody2D

var red_texture = preload('res://weapons/sprites/red_projectile.png')
var green_texture = preload('res://weapons/sprites/green_projectile.png')
var blue_texture = preload('res://weapons/sprites/blue_projectile.png')

var direction = Vector2(0,0)
var SPEED = 500

var COLOR_ENUM = {
	0: 'red',
	1: 'green',
	2: 'blue'
}
var COLOR = null

func setColor(tile_type):
	COLOR = COLOR_ENUM[tile_type]

	match COLOR:
		'red':
			$sprite.set_texture(red_texture)
		'green':
			$sprite.set_texture(green_texture)
		'blue':
			$sprite.set_texture(blue_texture)


func _physics_process(delta):
	var motion = direction * SPEED * delta
	var collision = move_and_collide(motion)

	if collision:
		var collider = collision.collider
		direction = direction.bounce(collision.normal)
		if collider is TileMap:
			var tile_pos = collider.world_to_map(position) - collision.normal
			var tile = collision.collider.get_cellv(tile_pos)
			setColor(tile)

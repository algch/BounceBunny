extends KinematicBody2D

var red_texture = preload('res://weapons/sprites/red_projectile.png')
var green_texture = preload('res://weapons/sprites/green_projectile.png')
var blue_texture = preload('res://weapons/sprites/blue_projectile.png')
var debug_texture = preload('res://weapons/sprites/debug_projectile.png')

var direction = Vector2(0,0)
var distance_to_tip

var power # power factor, range: [0, 1]

var MAX_SPEED = 1000.0
var speed
var MAX_DAMAGE = 3.0
var damage
var MAX_TRAVEL_TIME = 2.0
var travel_time

var travel_timer = Timer.new()

var COLOR_ENUM = {
	0: 'red',
	1: 'green',
	2: 'blue'
}
var COLOR = null


func _ready():
	rotation = direction.angle() + PI/2.0
	distance_to_tip = Vector2(0, 0).distance_to($tip.position)

	speed = MAX_SPEED * power
	damage = MAX_DAMAGE * power
	travel_time = MAX_TRAVEL_TIME * power

	travel_timer.set_wait_time(travel_time)
	travel_timer.connect('timeout', self, 'travelEnded')
	travel_timer.start()
	add_child(travel_timer)


func travelEnded():
	queue_free()


func getTipPosition():
	var tip_pos = direction * distance_to_tip
	return position + tip_pos


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
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		var collider = collision.collider
		var tip_position = getTipPosition()

		if collider is TileMap:
			var tile_pos = collider.world_to_map(tip_position) - collision.normal
			var tile = collision.collider.get_cellv(tile_pos)

			if tile != -1:
				setColor(tile)
		var collider_type = collider.get('TYPE')

		if collider.is_in_group('affected_by_weapons'):
			collider.handleWeaponCollision(self)

		direction = direction.bounce(collision.normal)
		rotation = direction.angle() + PI/2.0

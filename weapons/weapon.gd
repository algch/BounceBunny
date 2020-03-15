extends KinematicBody2D

onready var red_texture = preload('res://weapons/projectile/sprites/red_projectile.png')
onready var green_texture = preload('res://weapons/projectile/sprites/green_projectile.png')
onready var blue_texture = preload('res://weapons/projectile/sprites/blue_projectile.png')
onready var debug_texture = preload('res://weapons/projectile/sprites/debug_projectile.png')
# onready var support_class = preload('res://plants/support/support.tscn')

var direction = Vector2(0,0)
var distance_to_tip

var power # power factor, range: [0, 1]

var MAX_SPEED = 1000.0
var speed
var MAX_DAMAGE = 3.0
var damage
var MAX_TRAVEL_TIME = 2.0
var travel_time

var type = null

var travel_timer = Timer.new()

var COLOR_ENUM = {
	0: 'red',
	1: 'green',
	2: 'blue'
}
var COLOR = null

# TODO this whole file needs refactor


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
    print('NOT IMPLEMENTED')


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

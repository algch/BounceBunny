extends Area2D

var red_texture = preload('res://items/sprites/seed_red.png')
onready var player = get_node('/root/main/player')
var TYPE = globals.ITEM_TYPES.SUPPORT

func _ready():
	$sprite.set_texture(red_texture)
	connect('body_entered', self, 'bodyEntered')

func bodyEntered(body):
	if player and body.is_in_group('weapons'):
		player.addItem(self)
		queue_free()

extends Area2D

var red_texture = preload('res://items/sprites/seed_red.png')

func _ready():
	$sprite.set_texture(red_texture)
	connect('body_entered', self, 'bodyEntered')

func bodyEntered(body):
	print('body entered ', str(body))

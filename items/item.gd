extends Area2D

var red_texture = preload('res://items/sprites/seed_red.png')
onready var player = get_node('/root/main/player')
var TYPE = globals.ITEM_TYPES.SUPPORT
var LIFESPAN_TIME = 5.0
var lifespan_timer = Timer.new()

# debug --v
var message
var type_name = {
	0: 'SUPPORT',
	1: 'TELEPORT',
	2: 'HEAL',
	3: 'SCORE',
}
var default_font = DynamicFont.new()
onready var MAX_ALPHA = $sprite.modulate.a
var heal_points = 0
# debug --^


func _ready():
	TYPE = globals.getRandomItemType()
	if TYPE == globals.ITEM_TYPES.HEAL:
		heal_points = 1
	message = 'Type: ' + type_name[TYPE]
	# debug --v
	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22
	# debug --^
	$sprite.set_texture(red_texture)
	connect('body_entered', self, 'bodyEntered')
	lifespan_timer.set_wait_time(LIFESPAN_TIME)
	lifespan_timer.connect('timeout', self, 'lifespanEnded')
	lifespan_timer.start()
	add_child(lifespan_timer)


func lifespanEnded():
	queue_free()

func _draw():
	draw_string(default_font, Vector2(-20, -80),  message, Color(1, 1, 1))

func _process(delta):
	var factor = ((LIFESPAN_TIME - lifespan_timer.get_time_left())/LIFESPAN_TIME)
	$sprite.modulate.a = MAX_ALPHA - MAX_ALPHA * factor

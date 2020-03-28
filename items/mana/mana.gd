extends TouchScreenButton

onready var player = get_node('/root/main/player')
var LIFESPAN_TIME = 5.0
var lifespan_timer = Timer.new()

onready var MAX_ALPHA = $animation.modulate.a
var mana


func _ready():
	connect('pressed', self, 'itemTaken')
	lifespan_timer.set_wait_time(LIFESPAN_TIME)
	lifespan_timer.connect('timeout', self, 'lifespanEnded')
	lifespan_timer.start()
	add_child(lifespan_timer)
	assignMana()

func assignMana():
	if globals.calculateChance(0.25):
		mana = 20
		$animation.play('mana_2')
	else:
		mana = 10
		$animation.play('mana_1')

func itemTaken():
	player.addMana(mana)
	queue_free()


func lifespanEnded():
	queue_free()

func _process(delta):
	var factor = ((LIFESPAN_TIME - lifespan_timer.get_time_left())/LIFESPAN_TIME)
	$animation.modulate.a = MAX_ALPHA - MAX_ALPHA * factor

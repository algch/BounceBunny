extends StaticBody2D

var health = 3.0

var TYPE = 'plant/teleport'
var default_font = DynamicFont.new()


func _ready():
	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22

func receiveDamage(damage):
	health -= damage
	print('teleport atacado')


func healthLoop():
	if health <= 0:
		queue_free()


func handleWeaponCollision(weapon):
	if weapon.type != globals.PROJECTILE_TYPES.ATTACK:
		return
	var player = get_parent().get_node('/root/main/player')
	player.position = position
	weapon.queue_free()
	queue_free()


func _physics_process(delta):
	healthLoop()

func _draw():
	var message = 'TELEPORT'
	draw_string(default_font, Vector2(-20, -80),  message, Color(1, 1, 1))

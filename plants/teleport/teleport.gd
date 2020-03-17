extends StaticBody2D

var health = 3.0

var TYPE = 'plant/teleport'


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

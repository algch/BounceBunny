extends StaticBody2D

var TYPE = 'plant/teleport'
func handleWeaponCollision(weapon):
	if weapon.type != globals.PROJECTILE_TYPES.ATTACK:
		return
	var player = get_parent().get_node('/root/main/player')
	player.position = position
	weapon.queue_free()
	queue_free()

extends StaticBody2D

var TYPE = 'plant/teleport'
func handleWeaponCollision(collider):
	var player = get_parent().get_node('/root/main/player')
	player.position = position
	collider.queue_free()
	queue_free()

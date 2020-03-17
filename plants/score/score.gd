extends StaticBody2D

onready var main = get_node('/root/main/')
var health = 3.0


func _on_score_timer_timeout():
	main.score += 1
	$score_timer.start()

func receiveDamage(damage):
	health -= damage
	print('score atacado')

func healthLoop():
	if health <= 0:
		queue_free()


func handleWeaponCollision(weapon):
	health -= weapon.damage
	weapon.queue_free()
	

func _physics_process(delta):
	healthLoop()

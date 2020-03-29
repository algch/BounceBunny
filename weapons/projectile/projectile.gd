extends 'res://weapons/weapon.gd'

func travelEnded():
	queue_free()

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		var collider = collision.collider
		var tip_position = getTipPosition()

		print('projectile collided')

		if collider.is_in_group('affected_by_weapons'):
			print('collider ', collider)
			collider.handleWeaponCollision(self)

		direction = direction.bounce(collision.normal)
		rotation = direction.angle() + PI/2.0

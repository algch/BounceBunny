extends 'res://weapons/weapon.gd'

func travelEnded():
	queue_free()

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		var collider = collision.collider
		var tip_position = getTipPosition()

		if collider is TileMap:
			var tile_pos = collider.world_to_map(tip_position) - collision.normal
			var tile = collision.collider.get_cellv(tile_pos)

			if tile != -1:
				setColor(tile)
		var collider_type = collider.get('TYPE')

		if collider.is_in_group('affected_by_weapons'):
			collider.handleWeaponCollision(self)

		direction = direction.bounce(collision.normal)
		rotation = direction.angle() + PI/2.0

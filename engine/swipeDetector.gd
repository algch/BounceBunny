extends Node

signal swipe(direction)
signal swipe_canceled(start_position)

export(float, 1.0, 1.5) var MAX_DIAGONAL_SLOPE = 1.3

onready var timer : = $Timer
var swipe_start_position : = Vector2()

func _on_swipeDetector_gui_input(event):
	if not event is InputEventScreenTouch:
		return

	if event.pressed:
		_start_detection(event.position)
	elif not timer.is_stopped():
		_end_detection(event.position)

func _start_detection(detection_pos : Vector2):
	swipe_start_position = detection_pos
	timer.start()

func _end_detection(detection_pos: Vector2):
	timer.stop()
	var direction : =  (detection_pos - swipe_start_position).normalized()
	if abs(direction.x) + abs(direction.y) >= MAX_DIAGONAL_SLOPE:
		return
	if abs(direction.x) > abs(direction.y):
		emit_signal("swipe", Vector2(-sign(direction.x), 0.0))
	else:
		emit_signal("swipe", Vector2(0.0, -sign(direction.y)))

func _on_Timer_timeout():
	timer.stop()
	emit_signal("swipe_canceled", swipe_start_position)

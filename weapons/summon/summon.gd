extends 'res://weapons/weapon.gd'

# CREATE A BASE CLASS, INHERIT TO SOLO AND MULTIPLAYER MODES

onready var main = get_node('/root/mainArena/')
var plant_class = preload('res://plants/plant.tscn')
var mana_cost = 20.0
var first_neighbor_id
var summoner_id

func getLocalSummoner():
	return get_node('/root/mainArena/' + str(summoner_id))

func _ready():
	MAX_TRAVEL_TIME = 0.25
	MAX_SPEED = 600.0
	._ready()

func init(pos):
	position = pos

func abortSummon():
	print('colisionó, no se puede plantar')
	queue_free()

func healPlant(plant):
	plant.heal()
	plant.heal()

func handleCollision(collider):
	if collider.is_in_group('plants'):
		healPlant(collider)
		var player = getLocalSummoner()
		player.mana -= mana_cost
	abortSummon()

func travelEnded():
	print('travel ended')
	queue_free()
	if not get_tree().is_network_server():
		return

	var player = getLocalSummoner()
	print('summoner ', str(summoner_id), ' is planting...')
	# TODO create remote function to decrease mana
	player.mana -= mana_cost

	main.addServerNode(player, position)

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		handleCollision(collision.collider)

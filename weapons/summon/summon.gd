extends 'res://weapons/weapon.gd'

# CREATE A BASE CLASS, INHERIT TO SOLO AND MULTIPLAYER MODES

onready var main = get_node('/root/mainArena/')
var plant_class = preload('res://plants/plant.tscn')
var mana_cost = 20.0
var first_neighbor_id
var summoner_id

func getLocalPlayer():
	return get_node('/root/mainArena/' + str(get_tree().get_network_unique_id()))

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
		var player = getLocalPlayer()
		player.mana -= mana_cost
	abortSummon()

func travelEnded():
	queue_free()
	if not get_tree().is_network_server():
		return

	var player = getLocalPlayer()
	player.mana -= mana_cost

	var network_id = get_tree().get_network_unique_id()
	var plant = plant_class.instance()
	var plant_id = plant.get_instance_id()
	plant.init(position, network_id, plant_id)
	main.add_child(plant)
	main.addServerNode(summoner_id, plant_id, first_neighbor_id)
	main.rpc('addClientNode', summoner_id, plant_id, first_neighbor_id, position)

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		handleCollision(collision.collider)

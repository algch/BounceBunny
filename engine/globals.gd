extends Node

enum ACTIONS {
    MOVE,
    ATTACK,
    PLANT,
}

enum ITEM_TYPES {
    SEED,
    HEAL,
}

enum PROJECTILE_TYPES {
    ATTACK,
    SUMMON,
}

enum PLANT_TYPES {
    SPROUT,
    POISON,
    SPIKES,
    ARROWS,
}

enum EFFECTS {
    POISONED,
}

const PLANT_GROWTH_TIME = 5.0
const MAX_PLANT_HEALTH = 3.0

func calculateChance(probability):
    return randf() <= probability

func getRandomItemType():
    return ITEM_TYPES.values()[randi()%len(ITEM_TYPES)]

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

func calculateChance(probability):
    return randf() <= probability

func getRandomItemType():
    return ITEM_TYPES.values()[randi()%len(ITEM_TYPES)]

extends SceneTree

const DATA = preload("res://scripts/game_data.gd")
const ACTOR_SCRIPT = preload("res://scripts/arena_actor.gd")

func _init() -> void:
    var heroes := DATA.hero_defs()
    if heroes.size() != 4:
        push_error("Se esperaban 4 héroes.")
        quit(1)
        return

    var expected := {
        "AREN": "EMBESTIDA ATRAVESANTE",
        "MORVAK": "MURO DE HIERRO",
        "ARELIA": "DESTELLO REPARADOR",
        "KAIEN": "MAREA SOMBRÍA",
    }

    var actors: Array = []
    for hero_data in heroes:
        var name := str(hero_data.get("name", ""))
        if not expected.has(name):
            push_error("Héroe inesperado: %s" % name)
            quit(1)
            return
        if str(hero_data.get("ability", "")) != expected[name]:
            push_error("Habilidad incorrecta para %s." % name)
            quit(1)
            return

        var data: Dictionary = hero_data.duplicate(true)
        data["team"] = "hero"
        var actor = ACTOR_SCRIPT.new()
        actor.setup(data)
        get_root().add_child(actor)
        actors.append(actor)

    # Actor-system smoke: escudo, daño, armadura y curación siguen operativos.
    var morvak = actors[1]
    morvak.add_shield(55.0)
    if morvak.shield < 55.0:
        push_error("El sistema de escudo no funciona.")
        quit(1)
        return

    var arelia = actors[2]
    var before := arelia.hp
    arelia.take_damage(40.0)
    if arelia.hp >= before:
        push_error("El sistema de daño no funciona.")
        quit(1)
        return
    var damaged := arelia.hp
    arelia.heal(45.0)
    if arelia.hp <= damaged:
        push_error("El sistema de curación no funciona.")
        quit(1)
        return

    for actor in actors:
        actor.queue_free()

    print("VECTORFALL_GAMEPLAY_SMOKE_OK · AREN · MORVAK · ARELIA · KAIEN")
    quit(0)

extends SceneTree

func _init() -> void:
    GameState.current_level = 1

    var packed := load("res://scenes/game.tscn")
    if packed == null or not packed is PackedScene:
        push_error("No se pudo cargar la escena de juego.")
        quit(1)
        return

    var game = (packed as PackedScene).instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    if game.heroes.size() != 4:
        push_error("Se esperaban 4 héroes en combate.")
        quit(1)
        return

    if game.enemies.size() != 3:
        push_error("El nivel 1 debe comenzar con 3 enemigos.")
        quit(1)
        return

    var vektor = game.heroes[0]
    game.active_actor = vektor
    game.phase = "player_aim"
    game._use_ability()
    if not vektor.ability_used or vektor.damage_boost <= 1.0 or vektor.speed_boost <= 1.0:
        push_error("La habilidad de ASALTO no aplicó Sobrecarga.")
        quit(1)
        return

    var aegis = game.heroes[1]
    game.active_actor = aegis
    game.phase = "player_aim"
    game._use_ability()
    for hero in game.heroes:
        if hero.shield < 55.0:
            push_error("FORTALEZA no otorgó escudo al equipo.")
            quit(1)
            return

    var luma = game.heroes[2]
    var target = game.heroes[0]
    target.take_damage(90.0)
    var damaged_hp: float = target.hp

    game.active_actor = luma
    game.phase = "player_aim"
    game._use_ability()
    if target.hp <= damaged_hp:
        push_error("PULSO VITAL no curó a un aliado dañado.")
        quit(1)
        return

    var flux = game.heroes[3]
    game.active_actor = flux
    game.phase = "player_aim"
    game._use_ability()
    if not game.skip_enemy_phase:
        push_error("CAMPO ESTÁTICO no armó el salto de fase enemiga.")
        quit(1)
        return

    game.queue_free()
    await process_frame

    print("VECTORFALL_GAMEPLAY_SMOKE_OK · 4 ABILITIES")
    quit(0)

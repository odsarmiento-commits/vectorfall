extends Node2D

const ACTOR_SCRIPT = preload("res://scripts/arena_actor.gd")

const ARENA := Rect2(64.0, 112.0, 1152.0, 492.0)
const MAX_DRAG := 190.0
const STOP_SPEED := 70.0
const BOUNCE := 0.86
const MAX_MOTION_TIME := 4.5

var heroes: Array = []
var enemies: Array = []
var obstacles: Array[Rect2] = [
    Rect2(535, 215, 82, 150),
    Rect2(760, 405, 120, 58),
    Rect2(355, 430, 105, 54),
]

var phase := "boot"
var wave := 1
var active_hero_index := -1
var enemy_index := 0
var active_actor = null
var dragging := false
var drag_mouse := Vector2.ZERO
var motion_time := 0.0
var hit_registry: Dictionary = {}
var paused := false
var finished := false

var wave_label: Label
var phase_label: Label
var status_label: Label
var power_bar: ProgressBar
var result_panel: PanelContainer
var result_title: Label
var result_text: Label

func _ready() -> void:
    _build_ui()
    _spawn_heroes()
    _start_wave(1)
    queue_redraw()

func _process(delta: float) -> void:
    if paused or finished:
        return
    if phase == "player_moving" or phase == "enemy_moving":
        _step_motion(delta)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if not finished:
            paused = not paused
            phase_label.text = "PAUSA" if paused else "TU TURNO"
        return

    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
        get_tree().reload_current_scene()
        return

    if paused or finished or phase != "player_aim" or active_actor == null:
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if event.position.distance_to(active_actor.position) <= active_actor.radius + 18.0:
                dragging = true
                drag_mouse = event.position
                _update_power()
                queue_redraw()
        elif dragging:
            drag_mouse = event.position
            _update_power()
            _launch_player()
    elif event is InputEventMouseMotion and dragging:
        drag_mouse = event.position
        _update_power()
        queue_redraw()

func _build_ui() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)

    var top := ColorRect.new()
    top.color = Color(0.025, 0.045, 0.085, 0.96)
    top.position = Vector2.ZERO
    top.size = Vector2(1280, 92)
    ui.add_child(top)

    wave_label = Label.new()
    wave_label.position = Vector2(28, 16)
    wave_label.size = Vector2(420, 30)
    wave_label.add_theme_font_size_override("font_size", 22)
    wave_label.add_theme_color_override("font_color", Color("6fdcff"))
    ui.add_child(wave_label)

    phase_label = Label.new()
    phase_label.position = Vector2(28, 50)
    phase_label.size = Vector2(690, 28)
    phase_label.add_theme_font_size_override("font_size", 17)
    phase_label.add_theme_color_override("font_color", Color("c7d1e2"))
    ui.add_child(phase_label)

    var title := Label.new()
    title.text = "VECTORFALL"
    title.position = Vector2(1020, 20)
    title.size = Vector2(230, 36)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    title.add_theme_font_size_override("font_size", 28)
    ui.add_child(title)

    var bottom := ColorRect.new()
    bottom.color = Color(0.025, 0.045, 0.085, 0.98)
    bottom.position = Vector2(0, 622)
    bottom.size = Vector2(1280, 98)
    ui.add_child(bottom)

    status_label = Label.new()
    status_label.position = Vector2(28, 640)
    status_label.size = Vector2(760, 54)
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.add_theme_color_override("font_color", Color("f3e67c"))
    ui.add_child(status_label)

    power_bar = ProgressBar.new()
    power_bar.position = Vector2(930, 652)
    power_bar.size = Vector2(300, 20)
    power_bar.max_value = 100
    power_bar.show_percentage = false
    ui.add_child(power_bar)

    var hint := Label.new()
    hint.text = "POTENCIA"
    hint.position = Vector2(930, 678)
    hint.size = Vector2(300, 22)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 13)
    ui.add_child(hint)

    result_panel = PanelContainer.new()
    result_panel.position = Vector2(390, 210)
    result_panel.size = Vector2(500, 280)
    result_panel.visible = false
    ui.add_child(result_panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 16)
    result_panel.add_child(box)

    result_title = Label.new()
    result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_title.add_theme_font_size_override("font_size", 34)
    box.add_child(result_title)

    result_text = Label.new()
    result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_text.custom_minimum_size = Vector2(450, 88)
    result_text.add_theme_font_size_override("font_size", 17)
    box.add_child(result_text)

    var again := Button.new()
    again.text = "JUGAR DE NUEVO"
    again.custom_minimum_size = Vector2(320, 46)
    again.pressed.connect(func(): get_tree().reload_current_scene())
    box.add_child(again)

    var menu := Button.new()
    menu.text = "MENÚ PRINCIPAL"
    menu.custom_minimum_size = Vector2(320, 42)
    menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
    box.add_child(menu)

func _spawn_heroes() -> void:
    var data := [
        {"team":"hero","name":"PRISMA","max_hp":125.0,"damage":34.0,"radius":29.0,"color":Color("4fd6ff")},
        {"team":"hero","name":"BASTIÓN","max_hp":170.0,"damage":27.0,"radius":33.0,"color":Color("8a7bff")},
        {"team":"hero","name":"CHISPA","max_hp":105.0,"damage":31.0,"radius":26.0,"color":Color("f3d95c")},
    ]
    var positions := [Vector2(210, 245), Vector2(205, 360), Vector2(225, 490)]
    for i in range(data.size()):
        var hero = ACTOR_SCRIPT.new()
        hero.setup(data[i])
        hero.position = positions[i]
        hero.died.connect(_on_actor_died)
        add_child(hero)
        heroes.append(hero)

func _start_wave(number: int) -> void:
    wave = number
    phase = "transition"
    _clear_enemies()
    _reset_hero_positions()

    if wave > 1:
        for hero in heroes:
            if hero.alive:
                hero.heal(hero.max_hp * 0.18)

    var count := 2 + wave
    for i in range(count):
        var enemy = ACTOR_SCRIPT.new()
        var heavy := i == count - 1 and wave >= 2
        enemy.setup({
            "team":"enemy",
            "name":"NÚCLEO" if heavy else "FRAGMENTO",
            "max_hp": (92.0 + wave * 18.0) if heavy else (56.0 + wave * 12.0),
            "damage": (28.0 + wave * 3.0) if heavy else (20.0 + wave * 2.0),
            "radius": 32.0 if heavy else 25.0,
            "color": Color("ff5f7a") if not heavy else Color("ef7bff"),
        })
        var x := 930.0 + float(i % 2) * 125.0
        var y := 205.0 + float(i) * (330.0 / max(1.0, float(count - 1)))
        enemy.position = Vector2(x, y)
        enemy.died.connect(_on_actor_died)
        add_child(enemy)
        enemies.append(enemy)

    active_hero_index = -1
    await get_tree().create_timer(0.35).timeout
    if is_inside_tree() and not finished:
        _next_player_turn()

func _clear_enemies() -> void:
    for enemy in enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    enemies.clear()

func _reset_hero_positions() -> void:
    var positions := [Vector2(210, 245), Vector2(205, 360), Vector2(225, 490)]
    for i in range(heroes.size()):
        var hero = heroes[i]
        hero.stop()
        if hero.alive:
            hero.position = positions[i]
            hero.trail.clear()
            hero.queue_redraw()

func _next_player_turn() -> void:
    if _living_heroes().is_empty():
        _finish(false)
        return
    if _living_enemies().is_empty():
        _complete_wave()
        return

    for hero in heroes:
        hero.set_active(false)

    var attempts := 0
    while attempts < heroes.size():
        active_hero_index = (active_hero_index + 1) % heroes.size()
        if heroes[active_hero_index].alive:
            break
        attempts += 1

    active_actor = heroes[active_hero_index]
    active_actor.set_active(true)
    phase = "player_aim"
    dragging = false
    hit_registry.clear()
    power_bar.value = 0
    _update_hud()

func _launch_player() -> void:
    dragging = false
    var pull := active_actor.position - drag_mouse
    var strength := min(pull.length(), MAX_DRAG)
    if strength < 24.0:
        power_bar.value = 0
        queue_redraw()
        return

    var speed := lerp(420.0, 1120.0, strength / MAX_DRAG)
    active_actor.launch(pull.normalized() * speed)
    active_actor.set_active(false)
    phase = "player_moving"
    motion_time = 0.0
    hit_registry.clear()
    _update_hud()

func _step_motion(delta: float) -> void:
    if active_actor == null or not is_instance_valid(active_actor) or not active_actor.alive:
        _end_motion_phase()
        return

    motion_time += delta
    active_actor.remember_trail()
    active_actor.position += active_actor.velocity * delta
    active_actor.velocity *= pow(0.40, delta)
    _bounce_walls(active_actor)
    _bounce_obstacles(active_actor)
    _check_actor_hits(active_actor)

    if active_actor.velocity.length() < STOP_SPEED or motion_time >= MAX_MOTION_TIME:
        active_actor.stop()
        _end_motion_phase()

    queue_redraw()

func _bounce_walls(actor) -> void:
    var r: float = actor.radius
    var left := ARENA.position.x + r
    var right := ARENA.end.x - r
    var top := ARENA.position.y + r
    var bottom := ARENA.end.y - r

    if actor.position.x < left:
        actor.position.x = left
        actor.velocity.x = abs(actor.velocity.x) * BOUNCE
    elif actor.position.x > right:
        actor.position.x = right
        actor.velocity.x = -abs(actor.velocity.x) * BOUNCE

    if actor.position.y < top:
        actor.position.y = top
        actor.velocity.y = abs(actor.velocity.y) * BOUNCE
    elif actor.position.y > bottom:
        actor.position.y = bottom
        actor.velocity.y = -abs(actor.velocity.y) * BOUNCE

func _bounce_obstacles(actor) -> void:
    for obstacle in obstacles:
        var expanded := obstacle.grow(actor.radius)
        if not expanded.has_point(actor.position):
            continue
        var left_d := abs(actor.position.x - expanded.position.x)
        var right_d := abs(actor.position.x - expanded.end.x)
        var top_d := abs(actor.position.y - expanded.position.y)
        var bottom_d := abs(actor.position.y - expanded.end.y)
        var smallest := min(min(left_d, right_d), min(top_d, bottom_d))
        if smallest == left_d:
            actor.position.x = expanded.position.x
            actor.velocity.x = -abs(actor.velocity.x) * BOUNCE
        elif smallest == right_d:
            actor.position.x = expanded.end.x
            actor.velocity.x = abs(actor.velocity.x) * BOUNCE
        elif smallest == top_d:
            actor.position.y = expanded.position.y
            actor.velocity.y = -abs(actor.velocity.y) * BOUNCE
        else:
            actor.position.y = expanded.end.y
            actor.velocity.y = abs(actor.velocity.y) * BOUNCE

func _check_actor_hits(actor) -> void:
    var targets := enemies if actor.team == "hero" else heroes
    for target in targets:
        if not target.alive:
            continue
        if actor.position.distance_to(target.position) > actor.radius + target.radius:
            continue

        var key := target.get_instance_id()
        if hit_registry.has(key):
            continue
        hit_registry[key] = true

        var speed_factor := clamp(actor.velocity.length() / 850.0, 0.45, 1.45)
        var dealt := target.take_damage(actor.damage * speed_factor)

        var normal := (actor.position - target.position).normalized()
        if normal == Vector2.ZERO:
            normal = Vector2.RIGHT
        actor.position = target.position + normal * (actor.radius + target.radius + 2.0)
        actor.velocity = actor.velocity.bounce(normal) * 0.88

        _damage_popup(target.position, dealt, actor.team == "hero")

func _end_motion_phase() -> void:
    if _living_heroes().is_empty():
        _finish(false)
        return
    if _living_enemies().is_empty():
        _complete_wave()
        return

    if phase == "player_moving":
        _begin_enemy_phase()
    elif phase == "enemy_moving":
        enemy_index += 1
        _launch_next_enemy()

func _begin_enemy_phase() -> void:
    phase = "enemy_wait"
    enemy_index = 0
    active_actor = null
    _update_hud()
    await get_tree().create_timer(0.35).timeout
    if is_inside_tree() and not finished:
        _launch_next_enemy()

func _launch_next_enemy() -> void:
    var living := _living_enemies()
    if enemy_index >= living.size():
        active_actor = null
        _next_player_turn()
        return

    active_actor = living[enemy_index]
    var target = _nearest_hero(active_actor.position)
    if target == null:
        _finish(false)
        return

    var direction := (target.position - active_actor.position).normalized()
    active_actor.launch(direction * (650.0 + wave * 55.0))
    phase = "enemy_moving"
    motion_time = 0.0
    hit_registry.clear()
    _update_hud()

func _complete_wave() -> void:
    if wave >= 3:
        _finish(true)
        return
    phase = "transition"
    active_actor = null
    _update_hud()
    await get_tree().create_timer(0.55).timeout
    if is_inside_tree() and not finished:
        _start_wave(wave + 1)

func _finish(victory: bool) -> void:
    finished = true
    dragging = false
    phase = "finished"
    if active_actor != null and is_instance_valid(active_actor):
        active_actor.stop()
    for hero in heroes:
        hero.set_active(false)
    result_panel.visible = true
    if victory:
        result_title.text = "PROTOCOLO COMPLETADO"
        result_title.add_theme_color_override("font_color", Color("76edb0"))
        result_text.text = "Superaste las tres oleadas. La beta ya contiene un bucle completo de lanzamiento, rebotes, daño y turnos."
    else:
        result_title.text = "EQUIPO FUERA DE LÍNEA"
        result_title.add_theme_color_override("font_color", Color("ff728a"))
        result_text.text = "Tus tres unidades fueron derribadas. Prueba otros ángulos y encadena más rebotes."
    _update_hud()

func _living_heroes() -> Array:
    return heroes.filter(func(h): return h.alive)

func _living_enemies() -> Array:
    return enemies.filter(func(e): return e.alive)

func _nearest_hero(from_pos: Vector2):
    var best = null
    var best_distance := INF
    for hero in heroes:
        if not hero.alive:
            continue
        var d := from_pos.distance_squared_to(hero.position)
        if d < best_distance:
            best_distance = d
            best = hero
    return best

func _on_actor_died(_actor) -> void:
    _update_hud()

func _update_power() -> void:
    if active_actor == null:
        power_bar.value = 0
        return
    power_bar.value = clamp((active_actor.position - drag_mouse).length() / MAX_DRAG, 0.0, 1.0) * 100.0

func _update_hud() -> void:
    wave_label.text = "OLEADA %d / 3   ·   ENEMIGOS %d" % [wave, _living_enemies().size()]
    if finished:
        phase_label.text = "COMBATE FINALIZADO"
    elif paused:
        phase_label.text = "PAUSA"
    elif phase == "player_aim":
        phase_label.text = "TU TURNO · Arrastra el héroe activo hacia atrás y suelta"
    elif phase == "player_moving":
        phase_label.text = "LANZAMIENTO EN CURSO"
    elif phase == "enemy_wait" or phase == "enemy_moving":
        phase_label.text = "TURNO ENEMIGO"
    else:
        phase_label.text = "PREPARANDO OLEADA"

    if active_actor != null and is_instance_valid(active_actor):
        status_label.text = "%s · PV %d/%d · Daño %d" % [active_actor.actor_name, ceili(active_actor.hp), ceili(active_actor.max_hp), ceili(active_actor.damage)]
    else:
        status_label.text = "Unidades operativas: %d / %d" % [_living_heroes().size(), heroes.size()]

func _damage_popup(pos: Vector2, amount: float, friendly: bool) -> void:
    var label := Label.new()
    label.text = "-%d" % roundi(amount)
    label.position = pos + Vector2(-28, -48)
    label.size = Vector2(70, 28)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 20)
    label.add_theme_color_override("font_color", Color("7cecff") if friendly else Color("ff8195"))
    label.z_index = 50
    add_child(label)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "position", label.position + Vector2(0, -34), 0.55)
    tween.tween_property(label, "modulate:a", 0.0, 0.55)
    tween.chain().tween_callback(label.queue_free)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("07101f"), true)
    draw_rect(ARENA, Color("0b1729"), true)

    var grid := Color(0.22, 0.42, 0.58, 0.10)
    var x := ARENA.position.x + 40.0
    while x < ARENA.end.x:
        draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), grid, 1.0)
        x += 40.0
    var y := ARENA.position.y + 40.0
    while y < ARENA.end.y:
        draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), grid, 1.0)
        y += 40.0

    draw_rect(ARENA, Color("33516f"), false, 3.0)
    for obstacle in obstacles:
        draw_rect(obstacle, Color("152d49"), true)
        draw_rect(obstacle, Color("4e7598"), false, 2.0)

    for hero in heroes:
        _draw_trail(hero, Color(0.35, 0.82, 1.0, 0.28))
    for enemy in enemies:
        _draw_trail(enemy, Color(1.0, 0.34, 0.50, 0.22))

    if dragging and phase == "player_aim" and active_actor != null:
        var pull := active_actor.position - drag_mouse
        var clamped := pull.limit_length(MAX_DRAG)
        var release_point := active_actor.position - clamped
        draw_line(active_actor.position, release_point, Color("f9e36a"), 4.0)
        draw_circle(release_point, 8.0, Color("f9e36a"))
        if clamped.length() > 24.0:
            var direction := clamped.normalized()
            for i in range(1, 9):
                draw_circle(active_actor.position + direction * 43.0 * i, max(2.0, 6.0 - i * 0.4), Color(0.55, 0.92, 1.0, 0.65))

func _draw_trail(actor, color: Color) -> void:
    if actor == null or actor.trail.size() < 2:
        return
    for i in range(actor.trail.size() - 1):
        draw_line(actor.trail[i], actor.trail[i + 1], color, 3.0)

extends Node2D
class_name ArenaActor

signal died(actor)
signal health_changed(actor)

var team := "hero"
var actor_name := "UNIDAD"
var archetype := ""
var ability_name := ""
var ability_desc := ""
var glyph := ""

var max_hp := 100.0
var hp := 100.0
var damage := 25.0
var radius := 28.0
var armor := 0.0
var shield := 0.0
var ai_speed := 700.0

var damage_boost := 1.0
var speed_boost := 1.0
var ability_used := false
var stunned_turns := 0

var body_color := Color("53d5ff")
var velocity := Vector2.ZERO
var moving := false
var alive := true
var active := false
var trail: Array[Vector2] = []

func setup(data: Dictionary) -> void:
    team = str(data.get("team", "hero"))
    actor_name = str(data.get("name", "UNIDAD"))
    archetype = str(data.get("archetype", ""))
    ability_name = str(data.get("ability", ""))
    ability_desc = str(data.get("ability_desc", ""))
    glyph = str(data.get("glyph", archetype.to_lower()))

    max_hp = float(data.get("max_hp", 100.0))
    hp = max_hp
    damage = float(data.get("damage", 25.0))
    radius = float(data.get("radius", 28.0))
    armor = clampf(float(data.get("armor", 0.0)), 0.0, 0.75)
    ai_speed = float(data.get("ai_speed", 700.0))
    body_color = data.get("color", Color("53d5ff"))

    shield = 0.0
    damage_boost = 1.0
    speed_boost = 1.0
    ability_used = false
    stunned_turns = 0
    alive = true
    moving = false
    velocity = Vector2.ZERO
    trail.clear()
    queue_redraw()

func launch(v: Vector2) -> void:
    velocity = v
    moving = true
    trail.clear()

func stop() -> void:
    velocity = Vector2.ZERO
    moving = false

func set_active(value: bool) -> void:
    active = value
    queue_redraw()

func add_shield(amount: float) -> void:
    if not alive:
        return
    shield += maxf(amount, 0.0)
    health_changed.emit(self)
    queue_redraw()

func take_damage(amount: float) -> float:
    if not alive:
        return 0.0

    var reduced := maxf(amount, 0.0) * (1.0 - armor)
    var remaining := reduced

    if shield > 0.0:
        var absorbed := minf(shield, remaining)
        shield -= absorbed
        remaining -= absorbed

    if remaining > 0.0:
        hp -= remaining

    health_changed.emit(self)

    if hp <= 0.0:
        hp = 0.0
        shield = 0.0
        alive = false
        moving = false
        velocity = Vector2.ZERO
        died.emit(self)

    queue_redraw()
    return reduced

func heal(amount: float) -> float:
    if not alive:
        return 0.0
    var before := hp
    hp = minf(max_hp, hp + maxf(amount, 0.0))
    health_changed.emit(self)
    queue_redraw()
    return hp - before

func reset_temporary_buffs() -> void:
    damage_boost = 1.0
    speed_boost = 1.0

func remember_trail() -> void:
    if trail.is_empty() or trail[-1].distance_to(position) > 18.0:
        trail.append(position)
        if trail.size() > 16:
            trail.pop_front()

func _draw() -> void:
    if not alive:
        draw_circle(Vector2.ZERO, radius, Color(0.25, 0.27, 0.32, 0.55))
        draw_line(Vector2(-radius * 0.5, -radius * 0.5), Vector2(radius * 0.5, radius * 0.5), Color("b7bdc8"), 4.0)
        draw_line(Vector2(radius * 0.5, -radius * 0.5), Vector2(-radius * 0.5, radius * 0.5), Color("b7bdc8"), 4.0)
        return

    if shield > 0.0:
        draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 48, Color(0.35, 0.9, 1.0, 0.72), 3.0)

    if active:
        draw_circle(Vector2.ZERO, radius + 11.0, Color(0.98, 0.88, 0.32, 0.16))
        draw_arc(Vector2.ZERO, radius + 11.0, 0.0, TAU, 48, Color("f9e36a"), 3.0)

    if stunned_turns > 0:
        draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 32, Color("71cfff"), 4.0)

    draw_circle(Vector2.ZERO, radius, body_color)
    draw_circle(Vector2.ZERO, radius * 0.60, body_color.lightened(0.18))
    _draw_glyph()

    var ratio := clampf(hp / max_hp, 0.0, 1.0)
    var bar := Rect2(Vector2(-radius, -radius - 15.0), Vector2(radius * 2.0, 5.0))
    draw_rect(bar, Color(0.1, 0.12, 0.16, 0.92), true)
    draw_rect(
        Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)),
        Color("65e39a") if team == "hero" else Color("ff6d84"),
        true
    )

    if shield > 0.0:
        var shield_ratio := clampf(shield / 80.0, 0.0, 1.0)
        var shield_bar := Rect2(Vector2(-radius, -radius - 22.0), Vector2(radius * 2.0, 3.0))
        draw_rect(shield_bar, Color(0.08, 0.16, 0.22, 0.9), true)
        draw_rect(
            Rect2(shield_bar.position, Vector2(shield_bar.size.x * shield_ratio, shield_bar.size.y)),
            Color("67dfff"),
            true
        )

func _draw_glyph() -> void:
    var c := Color(0.04, 0.08, 0.13, 0.82)
    var r := radius * 0.34

    match archetype:
        "ASALTO":
            draw_colored_polygon(
                PackedVector2Array([
                    Vector2(0, -r),
                    Vector2(r * 0.92, r),
                    Vector2(-r * 0.92, r)
                ]),
                c
            )
        "TANQUE":
            draw_rect(Rect2(Vector2(-r, -r), Vector2(r * 2.0, r * 2.0)), c, false, 4.0)
        "APOYO":
            draw_rect(Rect2(Vector2(-r * 0.28, -r), Vector2(r * 0.56, r * 2.0)), c, true)
            draw_rect(Rect2(Vector2(-r, -r * 0.28), Vector2(r * 2.0, r * 0.56)), c, true)
        "CONTROL":
            draw_colored_polygon(
                PackedVector2Array([
                    Vector2(0, -r),
                    Vector2(r, 0),
                    Vector2(0, r),
                    Vector2(-r, 0)
                ]),
                c
            )
        _:
            match glyph:
                "brute":
                    draw_rect(Rect2(Vector2(-r, -r), Vector2(r * 2.0, r * 2.0)), c, true)
                "hunter":
                    draw_line(Vector2(-r, r), Vector2(r, -r), c, 4.0)
                    draw_line(Vector2(-r, -r * 0.2), Vector2(r * 0.2, r), c, 3.0)
                "boss":
                    draw_arc(Vector2.ZERO, r, 0.0, TAU, 6, c, 5.0)
                    draw_circle(Vector2.ZERO, r * 0.32, c)
                "sentinel":
                    draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, c, 4.0)
                _:
                    draw_colored_polygon(
                        PackedVector2Array([
                            Vector2(0, -r),
                            Vector2(r, r * 0.7),
                            Vector2(-r, r * 0.7)
                        ]),
                        c
                    )

extends Node2D
class_name ArenaActor

signal died(actor)
signal health_changed(actor)

var team := "hero"
var actor_name := "UNIDAD"
var max_hp := 100.0
var hp := 100.0
var damage := 25.0
var radius := 28.0
var body_color := Color("53d5ff")
var velocity := Vector2.ZERO
var moving := false
var alive := true
var active := false
var trail: Array[Vector2] = []

func setup(data: Dictionary) -> void:
    team = str(data.get("team", "hero"))
    actor_name = str(data.get("name", "UNIDAD"))
    max_hp = float(data.get("max_hp", 100.0))
    hp = max_hp
    damage = float(data.get("damage", 25.0))
    radius = float(data.get("radius", 28.0))
    body_color = data.get("color", Color("53d5ff"))
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

func take_damage(amount: float) -> float:
    if not alive:
        return 0.0
    var dealt := min(amount, hp)
    hp -= dealt
    health_changed.emit(self)
    if hp <= 0.0:
        hp = 0.0
        alive = false
        moving = false
        velocity = Vector2.ZERO
        died.emit(self)
    queue_redraw()
    return dealt

func heal(amount: float) -> void:
    if not alive:
        return
    hp = min(max_hp, hp + amount)
    health_changed.emit(self)
    queue_redraw()

func remember_trail() -> void:
    if trail.is_empty() or trail[-1].distance_to(position) > 18.0:
        trail.append(position)
        if trail.size() > 14:
            trail.pop_front()

func _draw() -> void:
    if not alive:
        draw_circle(Vector2.ZERO, radius, Color(0.25, 0.27, 0.32, 0.55))
        draw_line(Vector2(-radius * 0.5, -radius * 0.5), Vector2(radius * 0.5, radius * 0.5), Color("b7bdc8"), 4.0)
        draw_line(Vector2(radius * 0.5, -radius * 0.5), Vector2(-radius * 0.5, radius * 0.5), Color("b7bdc8"), 4.0)
        return

    if active:
        draw_circle(Vector2.ZERO, radius + 9.0, Color(0.98, 0.88, 0.32, 0.18))
        draw_arc(Vector2.ZERO, radius + 9.0, 0.0, TAU, 48, Color("f9e36a"), 3.0)

    draw_circle(Vector2.ZERO, radius, body_color)
    draw_circle(Vector2.ZERO, radius * 0.58, body_color.lightened(0.18))

    var ratio := clamp(hp / max_hp, 0.0, 1.0)
    var bar := Rect2(Vector2(-radius, -radius - 14.0), Vector2(radius * 2.0, 5.0))
    draw_rect(bar, Color(0.1, 0.12, 0.16, 0.9), true)
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("65e39a") if team == "hero" else Color("ff6d84"), true)

extends RefCounted
class_name GameData

static func hero_defs() -> Array:
    return [
        {
            "name": "AREN",
            "archetype": "ASALTO",
            "ability": "EMBESTIDA ATRAVESANTE",
            "ability_desc": "El siguiente lanzamiento gana +75% daño y +18% velocidad.",
            "max_hp": 128.0,
            "damage": 42.0,
            "radius": 29.0,
            "armor": 0.0,
            "color": Color("4aa8ff"),
            "sprite_path": "res://assets/heroes/aren_sprite.png"
        },
        {
            "name": "MORVAK",
            "archetype": "TANQUE",
            "ability": "MURO DE HIERRO",
            "ability_desc": "Otorga 55 de escudo a todo el equipo.",
            "max_hp": 230.0,
            "damage": 28.0,
            "radius": 36.0,
            "armor": 0.26,
            "color": Color("a65b4f"),
            "sprite_path": "res://assets/heroes/morvak_sprite.png"
        },
        {
            "name": "ARELIA",
            "archetype": "APOYO",
            "ability": "DESTELLO REPARADOR",
            "ability_desc": "Cura 45 PV a todos los aliados vivos.",
            "max_hp": 150.0,
            "damage": 29.0,
            "radius": 29.0,
            "armor": 0.08,
            "color": Color("f0d695"),
            "sprite_path": "res://assets/heroes/arelia_sprite.png"
        },
        {
            "name": "KAIEN",
            "archetype": "CONTROL",
            "ability": "MAREA SOMBRÍA",
            "ability_desc": "Anula por completo la siguiente fase enemiga.",
            "max_hp": 135.0,
            "damage": 33.0,
            "radius": 28.0,
            "armor": 0.05,
            "color": Color("238ad0"),
            "sprite_path": "res://assets/heroes/kaien_sprite.png"
        }
    ]

static func level_defs() -> Array:
    return [
        {
            "number": 1,
            "name": "MUELLE CERO",
            "subtitle": "Calibración de lanzamiento",
            "accent": Color("49c9ff"),
            "obstacles": [
                Rect2(605, 285, 72, 145)
            ],
            "enemies": [
                {"type": "shard", "pos": Vector2(930, 220)},
                {"type": "shard", "pos": Vector2(1035, 355)},
                {"type": "sentinel", "pos": Vector2(940, 505)}
            ]
        },
        {
            "number": 2,
            "name": "CÁMARA PRISMA",
            "subtitle": "Ángulos cerrados",
            "accent": Color("9c7dff"),
            "obstacles": [
                Rect2(505, 205, 68, 175),
                Rect2(735, 385, 72, 165)
            ],
            "enemies": [
                {"type": "shard", "pos": Vector2(910, 200)},
                {"type": "brute", "pos": Vector2(1040, 285)},
                {"type": "shard", "pos": Vector2(915, 440)},
                {"type": "sentinel", "pos": Vector2(1050, 535)}
            ]
        },
        {
            "number": 3,
            "name": "PASARELA ROTA",
            "subtitle": "Corredores de impacto",
            "accent": Color("55e6a5"),
            "obstacles": [
                Rect2(430, 225, 150, 54),
                Rect2(620, 425, 165, 54),
                Rect2(790, 210, 58, 125)
            ],
            "enemies": [
                {"type": "hunter", "pos": Vector2(980, 185)},
                {"type": "shard", "pos": Vector2(1060, 285)},
                {"type": "brute", "pos": Vector2(950, 390)},
                {"type": "hunter", "pos": Vector2(1070, 490)},
                {"type": "sentinel", "pos": Vector2(900, 545)}
            ]
        },
        {
            "number": 4,
            "name": "NÚCLEO MAGNÉTICO",
            "subtitle": "Cerco de alta presión",
            "accent": Color("ff8a66"),
            "obstacles": [
                Rect2(465, 185, 58, 150),
                Rect2(465, 415, 58, 150),
                Rect2(680, 300, 145, 62),
                Rect2(895, 205, 55, 135)
            ],
            "enemies": [
                {"type": "hunter", "pos": Vector2(1050, 175)},
                {"type": "brute", "pos": Vector2(1070, 270)},
                {"type": "sentinel", "pos": Vector2(985, 355)},
                {"type": "hunter", "pos": Vector2(1080, 435)},
                {"type": "brute", "pos": Vector2(1000, 520)},
                {"type": "shard", "pos": Vector2(1110, 555)}
            ]
        },
        {
            "number": 5,
            "name": "CORONA DEL ABISMO",
            "subtitle": "Despertar de Thal'Kryn",
            "accent": Color("ff5d8f"),
            "obstacles": [
                Rect2(455, 210, 70, 120),
                Rect2(455, 430, 70, 120),
                Rect2(635, 305, 95, 70),
                Rect2(820, 205, 65, 125),
                Rect2(820, 430, 65, 125)
            ],
            "enemies": [
                {"type": "hunter", "pos": Vector2(1005, 185)},
                {"type": "brute", "pos": Vector2(1090, 270)},
                {"type": "boss", "pos": Vector2(1000, 365)},
                {"type": "sentinel", "pos": Vector2(1095, 465)},
                {"type": "hunter", "pos": Vector2(995, 545)}
            ]
        }
    ]

static func get_level(level_number: int) -> Dictionary:
    var levels := level_defs()
    var index := clampi(level_number, 1, levels.size()) - 1
    return levels[index].duplicate(true)

static func enemy_stats(kind: String, level_number: int) -> Dictionary:
    var level_scale := 1.0 + float(level_number - 1) * 0.10
    match kind:
        "shard":
            return {
                "name": "FRAGMENTO",
                "max_hp": 62.0 * level_scale,
                "damage": 19.0 * level_scale,
                "radius": 24.0,
                "armor": 0.0,
                "ai_speed": 760.0,
                "color": Color("ff607d"),
                "glyph": "shard"
            }
        "brute":
            return {
                "name": "ARiete",
                "max_hp": 132.0 * level_scale,
                "damage": 28.0 * level_scale,
                "radius": 34.0,
                "armor": 0.18,
                "ai_speed": 610.0,
                "color": Color("ee77ff"),
                "glyph": "brute"
            }
        "hunter":
            return {
                "name": "RASTREADOR",
                "max_hp": 82.0 * level_scale,
                "damage": 35.0 * level_scale,
                "radius": 25.0,
                "armor": 0.04,
                "ai_speed": 890.0,
                "color": Color("ff9b55"),
                "glyph": "hunter"
            }
        "boss":
            return {
                "name": "THAL'KRYN",
                "max_hp": 390.0,
                "damage": 42.0,
                "radius": 48.0,
                "armor": 0.20,
                "ai_speed": 670.0,
                "color": Color("ff477e"),
                "glyph": "boss",
                "sprite_path": "res://assets/heroes/thal_kryn_sprite.png"
            }
        _:
            return {
                "name": "CENTINELA",
                "max_hp": 94.0 * level_scale,
                "damage": 25.0 * level_scale,
                "radius": 28.0,
                "armor": 0.08,
                "ai_speed": 700.0,
                "color": Color("e85f86"),
                "glyph": "sentinel"
            }

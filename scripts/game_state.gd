extends Node

var current_level := 1
var max_unlocked := 1
var campaign_complete := false

const SAVE_PATH := "user://vectorfall_progress.cfg"

func _ready() -> void:
    load_progress()

func select_level(level_number: int) -> void:
    current_level = clampi(level_number, 1, 5)

func unlock_level(level_number: int) -> void:
    max_unlocked = maxi(max_unlocked, clampi(level_number, 1, 5))
    save_progress()

func complete_campaign() -> void:
    campaign_complete = true
    max_unlocked = 5
    save_progress()

func load_progress() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return
    max_unlocked = clampi(int(config.get_value("progress", "max_unlocked", 1)), 1, 5)
    campaign_complete = bool(config.get_value("progress", "campaign_complete", false))
    current_level = clampi(current_level, 1, max_unlocked)

func save_progress() -> void:
    var config := ConfigFile.new()
    config.set_value("progress", "max_unlocked", max_unlocked)
    config.set_value("progress", "campaign_complete", campaign_complete)
    config.save(SAVE_PATH)

func reset_progress() -> void:
    current_level = 1
    max_unlocked = 1
    campaign_complete = false
    save_progress()

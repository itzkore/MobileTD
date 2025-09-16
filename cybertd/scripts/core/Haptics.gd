extends Node

## Cross-platform haptics helper using Input.vibrate_handheld.

var _enabled: bool = false

func _ready() -> void:
    # Enable only on mobile; actual use further checks user settings
    _enabled = OS.has_feature("mobile")

func tap() -> void:
    _vibrate_ms(15)

func success() -> void:
    _vibrate_ms(30)

func heavy() -> void:
    _vibrate_ms(50)

func _vibrate_ms(ms: int) -> void:
    if not _enabled:
        return
    # Respect user setting and avoid calling if disabled
    if not _settings_haptics_enabled():
        return
    # Only call on platforms that implement handheld vibration
    if not (OS.has_feature("Android") or OS.has_feature("iOS") or OS.has_feature("mobile")):
        return
    # Godot will no-op on unsupported devices; permission is required on Android
    Input.vibrate_handheld(ms)

func _settings_haptics_enabled() -> bool:
    var saver = get_tree().root.get_node_or_null("SaveGame")
    if saver and saver.has_method("get_settings"):
        var s: Dictionary = saver.get_settings()
        return bool(s.get("haptics", true))
    return true

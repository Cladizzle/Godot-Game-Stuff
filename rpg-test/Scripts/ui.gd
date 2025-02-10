extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	follow_viewport_enabled = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@onready var heart_ui: HBoxContainer = $heart_u  # Adjust path as needed

func update_health_ui():
	for i in range(max_health):
		heart_ui[i].visible = i < current_health  # Show or hide hearts based on health

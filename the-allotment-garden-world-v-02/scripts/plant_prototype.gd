extends "res://scripts/world.gd"
## Reuses the existing world geometry; these are prototype forms, not named species.
@export_enum("Flower", "Shrub") var plant_kind: int = 0
@export_range(0, 5) var palette: int = 0
@export_range(0, 2) var flower_variant: int = 0
@export_range(0.2, 2.0) var shrub_size: float = 0.8
@export var shrub_seed: int = 0

func _ready() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	if plant_kind == 0:
		_flower(self, Vector3.ZERO, COLOURS[palette], flower_variant)
	else:
		_shrub(self, Vector3.ZERO, shrub_size, shrub_seed)

func _process(_delta: float) -> void:
	pass

func _unhandled_input(_event: InputEvent) -> void:
	pass

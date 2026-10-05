extends Sprite3D
## Shared small atlas for bullets and pooled impact bursts.
const ATLAS = preload("res://assets/characters/ember/effects.png")
var effect_row: int = 0

func _init() -> void:
	texture = ATLAS
	hframes = 4
	vframes = 4
	pixel_size = 0.007
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shaded = false
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD

func set_pose(row: int, clock: float, direction: int = 1) -> void:
	effect_row = row
	frame = row * 4 + posmod(int(clock * 18.0), 4)
	flip_h = direction < 0

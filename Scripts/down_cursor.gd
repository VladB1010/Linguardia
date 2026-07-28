extends TextureRect

@onready var width: float  = 40
@onready var atlas_height: float = texture.atlas.get_size().x

func _on_frame_advance_timeout() -> void:
	texture.region.position.x += width
	texture.region.position.x = wrapf(texture.region.position.x, 0, atlas_height)

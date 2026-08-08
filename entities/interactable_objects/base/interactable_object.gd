class_name InteractableObject
extends Area2D

# Tín hiệu phát ra khi có người tương tác
signal interacted(player: Node2D)

@export_group("Interaction Settings")
@export var prompt_message: String = "Tương tác"
@export var is_interactable: bool = true

@export_group("Visual FX")
# Gán outline_material.tres vào đây trong Inspector
@export var outline_material: ShaderMaterial

# Nút chứa Sprite để áp dụng Shader (có thể là Sprite2D hoặc AnimatedSprite2D)
@export var target_sprite: CanvasItem

func _ready() -> void:
	# Nếu chưa gán tay Sprite trong Inspector, tự tìm Sprite2D con
	if not target_sprite:
		target_sprite = get_node_or_null("Sprite2D")

# Bật/tắt hiệu ứng sáng viền
func set_highlight(enabled: bool) -> void:
	if not is_interactable or not target_sprite:
		return
	
	if enabled and outline_material:
		target_sprite.material = outline_material
	else:
		target_sprite.material = null

# Hàm tương tác chính - Player sẽ gọi hàm này
func interact(player: Node2D) -> void:
	if not is_interactable:
		return
	
	interacted.emit(player)
	_on_interact(player)

# Hàm ảo: Các class con sẽ đè (override) lại hàm này để viết logic riêng
func _on_interact(_player: Node2D) -> void:
	pass

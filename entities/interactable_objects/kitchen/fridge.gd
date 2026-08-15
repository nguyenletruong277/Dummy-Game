extends InteractableObject

@export var task_id: String = "task_kitchen"

func _ready() -> void:
	super._ready() # Gọi hàm _ready của InteractableObject
	
	# Đợi 1 frame để TaskManager kịp load xong Database
	PlayerManager.players_state_updated.connect(_check_task_status)
	_check_task_status()

# Kiểm tra nếu Task đã làm xong thì khóa tương tác & tắt viền sáng
func _check_task_status() -> void:
	var peer_id := multiplayer.get_unique_id()
	var done_ids: Array = PlayerManager.get_done_tasks(peer_id)
	if task_id in done_ids:
		is_interactable = false
		set_highlight(false)

# Lắng nghe khi Task thay đổi trạng thái hoàn thành
func _on_task_completion_changed(id: String, completed: bool) -> void:
	if id == task_id and completed:
		is_interactable = false
		set_highlight(false)

# Ghi đè (override) hàm tương tác gốc
func _on_interact(_player: Node2D) -> void:
	print("Player tương tác với task: ", task_id)
	TaskManager.open_task_ui(task_id)

extends InteractableObject

@export var task_id: String = "task_dressing_room"

func _ready() -> void:
	super._ready() # Gọi hàm _ready của InteractableObject
	
	# Đợi 1 frame để TaskManager kịp load xong Database
	await get_tree().process_frame
	_check_task_status()

# Kiểm tra nếu Task đã làm xong thì khóa tương tác & tắt viền sáng
func _check_task_status() -> void:
	var task_res = TaskManager.get_task_info(task_id)
	if task_res:
		# Kết nối signal để tự động cập nhật khi Server báo hoàn thành Task
		if not task_res.completion_changed.is_connected(_on_task_completion_changed):
			task_res.completion_changed.connect(_on_task_completion_changed)
			
		if task_res.is_completed:
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

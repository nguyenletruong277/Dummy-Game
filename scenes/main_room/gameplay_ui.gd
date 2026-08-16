extends CanvasLayer

@onready var task_label: RichTextLabel = $TaskContainer/RichTextLabel
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	task_label.bbcode_enabled = true
	
	# Thanh tiến trình: lắng nghe signal từ TaskManager (chỉ server phát)
	# và cũng tính lại từ players_state khi state đồng bộ về client
	TaskManager.total_progress_updated.connect(_on_progress_updated)
	PlayerManager.players_state_updated.connect(_refresh)
	
	# Khởi tạo thanh progress
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	
	_refresh()


func _refresh() -> void:
	var peer_id := multiplayer.get_unique_id()
	
	# Role handle
	var is_impostor: bool = PlayerManager.get_role(peer_id) == Enums.Role.IMPOSTOR
	if is_impostor:
		$RoleIcon.texture = load("res://assets/UI/Imposter.png")
	else:
		$RoleIcon.texture = load("res://assets/UI/Chicken.png")
	
	# Tasks handle
	var task_ids: Array = PlayerManager.get_assigned_tasks(peer_id)
	var done_ids: Array = PlayerManager.get_done_tasks(peer_id)
	print("Refreshing task list, ids: ", task_ids)
	
	var text := ""
	for id in task_ids:
		var task_info := TaskManager.get_task_info(id)
		if not task_info:
			push_warning("[TaskList] No TaskResource found for id: " + str(id))
			continue
		
		var label: String = task_info.room
		if not task_info.task_name.is_empty():
			label = task_info.task_name
		
		if id in done_ids:
			text += "[color=green]%s ✓[/color]\n" % label
		else:
			text += "%s\n" % label
	
	task_label.text = text
	print("[TaskList] Set text on node: ", task_label.get_path(), " -> '", task_label.text, "'")


## Thanh tiến trình global: Server broadcast _sync_task_progress RPC → TaskManager emit signal → cập nhật tại đây
func _on_progress_updated(progress: float) -> void:
	progress_bar.value = clampf(progress, 0.0, 1.0)
	print("[GameplayUI] Global progress bar updated: ", progress * 100, "%")

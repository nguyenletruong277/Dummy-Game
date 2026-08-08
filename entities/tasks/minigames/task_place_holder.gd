extends TaskBase

# Khai báo các Node UI con
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var complete_button: Button = $Panel/VBoxContainer/CompleteButton
@onready var cancel_button: Button = $Panel/VBoxContainer/CancelButton

func _ready() -> void:
	# Bắt sự kiện bấm nút
	complete_button.pressed.connect(_on_complete_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

# Hàm này tự động chạy khi task_id được gán từ TaskManager
func _on_setup() -> void:
	if task_info:
		title_label.text = "TASK: " + task_info.task_name
	else:
		title_label.text = "TASK: " + task_id

func _on_complete_pressed() -> void:
	print("[Test UI] Đã bấm hoàn thành Task: ", task_id)
	complete() # Gọi hàm complete() có sẵn của TaskBase

func _on_cancel_pressed() -> void:
	print("[Test UI] Đã bấm hủy Task: ", task_id)
	cancel() # Gọi hàm cancel() có sẵn của TaskBase

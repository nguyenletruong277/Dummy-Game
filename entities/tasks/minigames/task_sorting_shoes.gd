extends TaskBase

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var shoe1_button: Button = $Panel/VBoxContainer/Shoe1Button
@onready var shoe2_button: Button = $Panel/VBoxContainer/Shoe2Button
@onready var shoe3_button: Button = $Panel/VBoxContainer/Shoe3Button
@onready var cancel_button: Button = $Panel/VBoxContainer/CancelButton

var shoes_sorted: int = 0
var total_shoes: int = 3

func _ready() -> void:
	# Bắt sự kiện bấm cất giày
	shoe1_button.pressed.connect(_on_shoe_pressed.bind(shoe1_button))
	shoe2_button.pressed.connect(_on_shoe_pressed.bind(shoe2_button))
	shoe3_button.pressed.connect(_on_shoe_pressed.bind(shoe3_button))
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	update_status()

func _on_setup() -> void:
	if task_info:
		title_label.text = "Nhiệm vụ: " + task_info.task_name

# Hàm dùng chung khi bấm bất kỳ nút cất giày nào
func _on_shoe_pressed(button: Button) -> void:
	button.disabled = true # Khóa nút lại (đã cất xong)
	shoes_sorted += 1
	update_status()
	
	# Nếu đã cất đủ 3 đôi thì báo hoàn thành
	if shoes_sorted == total_shoes:
		status_label.text = "Gọn gàng quá! Đã xong!"
		print("[Task T-04] Đã cất xong toàn bộ giày!")
		await get_tree().create_timer(1.0).timeout
		complete()

# Hàm cập nhật dòng trạng thái
func update_status() -> void:
	var left = total_shoes - shoes_sorted
	if left > 0:
		status_label.text = "Trạng thái: Còn " + str(left) + " đôi giày chưa cất."

func _on_cancel_pressed() -> void:
	cancel()

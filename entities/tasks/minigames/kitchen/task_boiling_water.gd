extends TaskBase

# Khai báo các Node UI
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var fill_water_button: Button = $Panel/VBoxContainer/FillWaterButton
@onready var boil_button: Button = $Panel/VBoxContainer/BoilButton
@onready var cancel_button: Button = $Panel/VBoxContainer/CancelButton
@onready var boil_timer: Timer = $BoilTimer # Kéo node Timer vào đây

var has_water: bool = false
var _is_cancelled: bool = false

func _ready() -> void:
	# Bắt sự kiện bấm nút
	fill_water_button.pressed.connect(_on_fill_water_pressed)
	boil_button.pressed.connect(_on_boil_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Bắt sự kiện Timer đếm ngược xong
	boil_timer.timeout.connect(_on_boil_timer_timeout)

	# Setup trạng thái ban đầu khi vừa mở UI
	boil_button.disabled = true # Chưa có nước thì chưa cho bật bếp
	status_label.text = "Trạng thái: Ấm đang rỗng. Hãy hứng nước!"

# Hàm này tự động chạy khi task_id được gán từ TaskManager
func _on_setup() -> void:
	if task_info:
		title_label.text = "Nhiệm vụ: " + task_info.task_name

# Xử lý khi bấm nút "Hứng nước"
func _on_fill_water_pressed() -> void:
	has_water = true
	fill_water_button.disabled = true # Hứng rồi thì tắt nút này đi
	boil_button.disabled = false      # Mở khóa nút bật bếp
	status_label.text = "Trạng thái: Đã hứng đầy nước. Bật bếp đi!"

# Xử lý khi bấm nút "Bật bếp"
func _on_boil_pressed() -> void:
	boil_button.disabled = true
	cancel_button.disabled = true # Khóa nút hủy khi đang đun
	status_label.text = "Trạng thái: Đang đun nước sùng sục..."
	
	# Bắt đầu đun trong 5 giây
	boil_timer.start(5.0)

# Xử lý khi Timer chạy hết 5 giây (Nước đã sôi)
func _on_boil_timer_timeout() -> void:
	if _is_cancelled:
		return # Người chơi đã hủy, bỏ qua
	
	status_label.text = "Trạng thái: NƯỚC ĐÃ SÔI! HOÀN THÀNH!"
	print("[Task T-02] Nước đã sôi, gọi hàm complete() báo Server!")
	
	# Đợi khoảng 1.5 giây để người chơi nhìn thấy chữ hoàn thành rồi tự đóng UI
	await get_tree().create_timer(1.5).timeout
	
	# Kiểm tra node còn tồn tại và chưa bị hủy trước khi gọi complete
	if is_inside_tree() and not _is_cancelled:
		complete() # Gọi hàm complete() gốc của TaskBase để chốt task

# Xử lý khi bấm nút "Hủy"
func _on_cancel_pressed() -> void:
	print("[Task T-02] Đã bấm hủy Task")
	_is_cancelled = true
	boil_timer.stop() # Dừng timer nếu đang đun
	cancel()

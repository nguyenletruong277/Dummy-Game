extends TaskBase

# Khai báo các Node UI
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var pick_disk_button: Button = $Panel/VBoxContainer/PickDiskButton
@onready var sort_button: Button = $Panel/VBoxContainer/SortButton
@onready var place_button: Button = $Panel/VBoxContainer/PlaceButton
@onready var cancel_button: Button = $Panel/VBoxContainer/CancelButton

const TARGET_DISKS: int = 5

var disks_collected: int = 0
var _is_cancelled: bool = false

func _ready() -> void:
	# Bắt sự kiện bấm nút
	pick_disk_button.pressed.connect(_on_pick_disk_pressed)
	sort_button.pressed.connect(_on_sort_pressed)
	place_button.pressed.connect(_on_place_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	# Setup trạng thái ban đầu khi vừa mở UI
	sort_button.disabled = true # Chưa nhặt đủ đĩa thì chưa cho sắp xếp
	place_button.disabled = true # Chưa sắp xếp thì chưa cho đặt lên kệ
	status_label.text = "Trạng thái: Đĩa đang nằm rải rác khắp phòng. Nhặt đĩa lên nào!"

# Hàm này tự động chạy khi task_id được gán từ TaskManager
func _on_setup() -> void:
	if task_info:
		title_label.text = "Nhiệm vụ: " + task_info.task_name

# Xử lý khi bấm nút "Nhặt đĩa" (sub-task 1: gom đĩa quanh phòng)
func _on_pick_disk_pressed() -> void:
	disks_collected += 1
	status_label.text = "Trạng thái: Đã nhặt %d/%d đĩa" % [disks_collected, TARGET_DISKS]

	if disks_collected >= TARGET_DISKS:
		pick_disk_button.disabled = true
		sort_button.disabled = false
		status_label.text = "Trạng thái: Đủ đĩa rồi! Hãy sắp xếp theo thể loại."

# Xử lý khi bấm nút "Sắp xếp theo thể loại" (sub-task 2: phân loại)
func _on_sort_pressed() -> void:
	sort_button.disabled = true
	place_button.disabled = false
	status_label.text = "Trạng thái: Đã sắp xếp xong theo thể loại. Đặt lên kệ thôi!"

# Xử lý khi bấm nút "Đặt lên kệ" (sub-task 3: hoàn thành)
func _on_place_pressed() -> void:
	place_button.disabled = true
	cancel_button.disabled = true # Khóa nút hủy khi sắp hoàn thành
	status_label.text = "Trạng thái: ĐÃ ĐẶT LÊN KỆ! HOÀN THÀNH!"
	print("[Task T-03] Đã sắp xếp và đặt đĩa lên kệ, gọi hàm complete() báo Server!")

	# Đợi khoảng 1 giây để người chơi nhìn thấy chữ hoàn thành rồi tự đóng UI
	await get_tree().create_timer(1.0).timeout

	# Kiểm tra node còn tồn tại và chưa bị hủy trước khi gọi complete
	if is_inside_tree() and not _is_cancelled:
		complete() # Gọi hàm complete() gốc của TaskBase để chốt task

# Xử lý khi bấm nút "Hủy"
func _on_cancel_pressed() -> void:
	print("[Task T-03] Đã bấm hủy Task")
	_is_cancelled = true
	cancel()

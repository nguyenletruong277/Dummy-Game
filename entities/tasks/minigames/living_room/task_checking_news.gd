extends TaskBase

# Khai báo các Node UI
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var tv_button: Button = $Panel/VBoxContainer/TurnOnTVButton
@onready var now_playing_label: Label = $Panel/VBoxContainer/NowPlayingLabel
@onready var headline_container: VBoxContainer = $Panel/VBoxContainer/HeadlineContainer
@onready var headline_button_1: Button = $Panel/VBoxContainer/HeadlineContainer/Headline1
@onready var headline_button_2: Button = $Panel/VBoxContainer/HeadlineContainer/Headline2
@onready var headline_button_3: Button = $Panel/VBoxContainer/HeadlineContainer/Headline3
@onready var cancel_button: Button = $Panel/VBoxContainer/CancelButton

# Danh sách tin, tin đúng sẽ được random mỗi lần bật TV
const HEADLINES: Array[String] = [
	"Weekly Market Prices Drop 5 Percent",
	"Local Team Wins Regional Championship",
	"New Recycling Program Starts Next Month",
]

var _correct_index: int = 0
var _is_cancelled: bool = false

func _ready() -> void:
	# Bắt sự kiện bấm nút
	tv_button.pressed.connect(_on_tv_pressed)
	headline_button_1.pressed.connect(_on_headline_1_pressed)
	headline_button_2.pressed.connect(_on_headline_2_pressed)
	headline_button_3.pressed.connect(_on_headline_3_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	# Setup trạng thái ban đầu khi vừa mở UI
	headline_container.visible = false
	now_playing_label.visible = false
	status_label.text = "Trạng thái: TV đang tắt. Hãy bật lên xem tin tức."

# Hàm này tự động chạy khi task_id được gán từ TaskManager
func _on_setup() -> void:
	if task_info:
		title_label.text = "Nhiệm vụ: " + task_info.task_name

# Xử lý khi bấm nút "Bật TV" (sub-task 1: mở kênh tin tức)
func _on_tv_pressed() -> void:
	tv_button.disabled = true
	_correct_index = randi() % HEADLINES.size()

	headline_button_1.text = HEADLINES[0]
	headline_button_2.text = HEADLINES[1]
	headline_button_3.text = HEADLINES[2]
	headline_container.visible = true

	# Hiển thị tin đang phát trên "TV" để người chơi có căn cứ chọn đúng
	now_playing_label.text = "Đang phát: " + HEADLINES[_correct_index]
	now_playing_label.visible = true
	status_label.text = "Trạng thái: Chọn đúng tin đang chạy trên màn hình."

# Xử lý khi chọn 1 trong 3 headline (sub-task 2: chọn đúng tin)
func _on_headline_1_pressed() -> void: _check_headline(0)
func _on_headline_2_pressed() -> void: _check_headline(1)
func _on_headline_3_pressed() -> void: _check_headline(2)

func _check_headline(index: int) -> void:
	if index != _correct_index:
		status_label.text = "Trạng thái: Chưa đúng tin, xem kỹ lại nhé!"
		return

	# Chọn đúng -> khóa hết nút, chuẩn bị hoàn thành (sub-task 3)
	headline_button_1.disabled = true
	headline_button_2.disabled = true
	headline_button_3.disabled = true
	cancel_button.disabled = true
	status_label.text = "Trạng thái: CHÍNH XÁC! HOÀN THÀNH!"
	print("[Task T-05] Đã chọn đúng tin tức, gọi hàm complete() báo Server!")

	# Đợi khoảng 1 giây để người chơi nhìn thấy chữ hoàn thành rồi tự đóng UI
	await get_tree().create_timer(1.0).timeout

	# Kiểm tra node còn tồn tại và chưa bị hủy trước khi gọi complete
	if is_inside_tree() and not _is_cancelled:
		complete() # Gọi hàm complete() gốc của TaskBase để chốt task

# Xử lý khi bấm nút "Hủy"
func _on_cancel_pressed() -> void:
	print("[Task T-05] Đã bấm hủy Task")
	_is_cancelled = true
	cancel()

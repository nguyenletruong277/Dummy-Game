extends TextureButton

# --- Dash ring settings ---
@export var dash_count: int = 12
@export var dash_radius: float = 40.0
@export var dash_length: float = 10.0
@export var dash_width: float = 4.0
@export var color_active: Color = Color(0, 1, 1) # cyan, to visually distinguish from kill's red ring
@export var color_inactive: Color = Color(0.3, 0.3, 0.3, 0.5)
const COOLDOWN_DURATION := 8.0

var my_role: Enums.Role = Enums.Role.CREWMATE
var is_on_cooldown: bool = false

@onready var cooldown_timer = $CooldownTimer
@onready var time_label = $TimerLabel

func _ready():
	pressed.connect(_on_pressed) # connect in code — don't rely on editor wiring
	if cooldown_timer:
		cooldown_timer.timeout.connect(_on_timer_timeout)
	PlayerManager.players_state_updated.connect(_check_alive_status) # add this
	_check_alive_status() # add this, in case already dead when button spawns

func setup_role(player_role: Enums.Role):
	my_role = player_role
	if my_role != Enums.Role.IMPOSTOR:
		show()
	else:
		hide()

func _update_button_visuals():
	if is_on_cooldown:
		self_modulate = Color(0.3, 0.3, 0.3, 1.0)
		disabled = true
	else:
		self_modulate = Color.WHITE
		disabled = false

func _unhandled_input(event):
	if not visible or is_on_cooldown:
		return
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		_execute_dodge()

func _on_pressed():
	if is_on_cooldown:
		return
	_execute_dodge()

func _execute_dodge():
	print(">>> [DODGE BUTTON] Dodging")

	for p in get_tree().get_nodes_in_group("players"):
		if p.is_multiplayer_authority() and p.has_method("try_dodge"):
			p.try_dodge()
			break

	start_cooldown()

func start_cooldown():
	is_on_cooldown = true
	_update_button_visuals()
	if cooldown_timer:
		cooldown_timer.start(COOLDOWN_DURATION)

func _on_timer_timeout():
	is_on_cooldown = false
	_update_button_visuals()

func _process(_delta):
	if is_on_cooldown and time_label:
		time_label.show()
		time_label.text = str(int(ceil(cooldown_timer.time_left)))
	elif time_label:
		time_label.hide()
	queue_redraw()

func _draw() -> void:
	if not is_on_cooldown or not cooldown_timer:
		return
	var progress: float = 1.0 - (cooldown_timer.time_left / COOLDOWN_DURATION)
	var lit := int(round(progress * dash_count))
	var center := size / 2.0
	for i in range(dash_count):
		var angle := (TAU / dash_count) * i - PI / 2.0
		var dir := Vector2(cos(angle), sin(angle))
		var from := center + dir * (dash_radius - dash_length / 2.0)
		var to := center + dir * (dash_radius + dash_length / 2.0)
		draw_line(from, to, color_active if i < lit else color_inactive, dash_width, true)

func _check_alive_status() -> void:
	var my_id = multiplayer.get_unique_id()
	if not PlayerManager.is_player_alive(my_id):
		hide()
		disabled = true

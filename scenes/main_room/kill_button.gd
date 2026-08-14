extends TextureButton

var current_target_id: int = -1
var my_role: Enums.Role = Enums.Role.CREWMATE
var is_on_cooldown: bool = false

@onready var cooldown_timer = $CooldownTimer # Ensure you have created a Timer Node with this name
@onready var time_label = $TimerLabel # Reference to the Label that displays the countdown seconds

func _ready():
	# Listen for the local kill target update signal
	PlayerManager.local_kill_target_updated.connect(_on_kill_target_updated)
	
	# Connect the cooldown timer timeout signal
	if cooldown_timer:
		cooldown_timer.timeout.connect(_on_timer_timeout)

func setup_role(player_role: Enums.Role):
	my_role = player_role
	if my_role == Enums.Role.IMPOSTOR:
		show()
		current_target_id = -1
		start_cooldown() # Impostors usually start with the cooldown active
	else:
		hide()

func _on_kill_target_updated(target_id: int):
	current_target_id = target_id
	_update_button_visuals()

# Update the visual state (bright/dark) of the button
func _update_button_visuals():
	if is_on_cooldown:
		self_modulate = Color(0.3, 0.3, 0.3, 1.0) # On cooldown -> Darkened
		disabled = true
	elif current_target_id != -1:
		self_modulate = Color.WHITE # Target available -> Bright/Default color
		disabled = false
	else:
		self_modulate = Color(0.3, 0.3, 0.3, 1.0) # No target -> Darkened
		disabled = true

func _unhandled_input(event):
	if not visible or is_on_cooldown or current_target_id == -1:
		return
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		_execute_kill()

func _on_pressed():
	if is_on_cooldown or current_target_id == -1:
		return
	_execute_kill()

func _execute_kill():
	print(">>> [KILL BUTTON] Killed target ID: ", current_target_id)
	
	# Send kill request to the Server (Call request_kill in ServerManager)
	if ServerManager.has_method("request_kill"):
		ServerManager.rpc_id(1, "request_kill", current_target_id)
		
	# Start the cooldown timer
	start_cooldown()

func start_cooldown():
	is_on_cooldown = true
	_update_button_visuals()
	if cooldown_timer:
		cooldown_timer.start(15.0) # 10 seconds cooldown duration

func _on_timer_timeout():
	is_on_cooldown = false
	_update_button_visuals()

func _process(_delta):
	# Update the Label to display remaining cooldown seconds
	if is_on_cooldown and time_label:
		time_label.show()
		time_label.text = str(int(ceil(cooldown_timer.time_left)))
	elif time_label:
		time_label.hide()

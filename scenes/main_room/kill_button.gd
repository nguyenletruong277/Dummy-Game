extends TextureButton

@onready var cooldown_timer = $CooldownTimer
@onready var time_label = $TimerLabel 

func _ready():
	# DEFAULT: Hide the button for safety when entering the game
	hide()
	disabled = false
	time_label.hide()
	
	# Prevent this button from grabbing keyboard focus
	focus_mode = Control.FOCUS_NONE 
	
	pressed.connect(_on_pressed)
	cooldown_timer.timeout.connect(_on_timer_timeout)

# ADD THIS FUNCTION: To receive the assigned role and update visibility
func setup_role(player_role: Enums.Role):
	if player_role == Enums.Role.IMPOSTOR: 
		show()
	else:
		hide()

func _process(_delta):
	if not cooldown_timer.is_stopped():
		# Use int() with ceil() to convert a float like 14.0 to an integer 14
		time_label.text = str(int(ceil(cooldown_timer.time_left)))

# This function allows the Spacebar to work globally regardless of mouse position
func _unhandled_input(event):
	# Check if the player presses the Space key (excluding held-down echo events)
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		# Only trigger if the button is visible and not currently on cooldown
		if not disabled and visible:
			_on_pressed() # Execute the kill action just like a mouse click

func _on_pressed():
	print("Kill triggered! Starting cooldown...")
	
	# Disable the button and dim its color
	disabled = true
	modulate = Color(0.4, 0.4, 0.4, 1) 
	
	# Show the label and start the countdown timer
	time_label.show()
	cooldown_timer.start()

func _on_timer_timeout():
	# Cooldown finished: re-enable the button, restore original color, and hide the label
	disabled = false
	modulate = Color(1, 1, 1, 1) 
	time_label.hide()

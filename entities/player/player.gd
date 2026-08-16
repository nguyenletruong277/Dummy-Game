extends CharacterBody2D

# Dash/Kill mechanics
@export var lunge_speed: float = 900.0
@export var lunge_distance: float = 120
@export var dodge_distance: float = 160 
@export var lunge_duration: float = 0.1 
var is_lunging: bool = false
var facing_direction: Vector2 = Vector2.DOWN 
var is_dodging: bool = false
@export var dodge_invuln_duration: float = 0.0

# Movement speed of the player
@export var SPEED = 300.0

# References to child nodes
@onready var camera = $Camera2D
@onready var animation = $AnimatedSprite2D

# Array store interactable object list near by Player
var interactables_in_range: Array[Area2D] = []

# --- KILL RADAR VARIABLES FOR IMPOSTOR ---
@onready var kill_radar = $KillRadar # Requires an Area2D node named "KillRadar" in the Scene
var outline_material: ShaderMaterial

var kill_targets_in_range: Array[Node2D] = []
var current_kill_target: Node2D = null

func _ready():
	# Load the yellow outline shader
	outline_material = ShaderMaterial.new()
	outline_material.shader = load("res://assets/shaders/outline.gdshader")
	
	# Listen for state changes (e.g. death) on all machines
	PlayerManager.players_state_updated.connect(_check_alive_status)
	_check_alive_status()
	
	if is_multiplayer_authority():
		camera.make_current()
		
		# 1. Listen for the signal when the role is assigned by the Server
		PlayerManager.local_role_updated.connect(_update_radar_state)
		
		# 2. Call the check function once immediately (in case the role is assigned before spawning)
		_update_radar_state(PlayerManager.get_role(multiplayer.get_unique_id()))
		
		# 3. Connect body entered/exited signals (connect only once)
		if kill_radar:
			kill_radar.body_entered.connect(_on_kill_radar_body_entered)
			kill_radar.body_exited.connect(_on_kill_radar_body_exited)
	else:
		# Disable radar for remote players to save performance
		if kill_radar:
			kill_radar.monitoring = false


func _update_radar_state(my_role: Enums.Role) -> void:
	if kill_radar:
		var is_impostor = (my_role == Enums.Role.IMPOSTOR)
		# Use set_deferred to safely enable/disable radar monitoring
		kill_radar.set_deferred("monitoring", is_impostor)
		print(">>> [SYSTEM] Radar monitoring state changed to: ", is_impostor)

func _enter_tree():
	var id = name.to_int()
	# Guarantee for standalone test
	if id == 0:
		id = 1
	
	# Set authority for Player with this Peer ID
	set_multiplayer_authority(id)
	$MultiplayerSynchronizer.set_multiplayer_authority(id)

func _physics_process(_delta):
	# 1. Only Authority of this Player can handle Movement
	if is_multiplayer_authority():
		if not is_lunging:
			var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if input_direction != Vector2.ZERO:
				velocity = input_direction * SPEED
				facing_direction = input_direction.normalized() # remember last movement direction
			else:
				velocity = Vector2.ZERO
			move_and_slide()
		
			if Input.is_action_just_pressed("interact"):
				execute_interaction()
			
			# Continuously scan for the closest kill target
			if kill_radar and kill_radar.monitoring:
				_update_closest_kill_target()
		

	# 2. Both machines (Local + Remote) auto update ANIMATION based on VELOCITY
	_update_animation()

func _update_animation():
	if is_lunging:
		return # let _start_lunge's tween/animation calls own this while lunging
		
	var peer_id := name.to_int()
	if not PlayerManager.is_player_alive(peer_id):
		if animation.animation != "rip":
			animation.play("rip")
		return

	if velocity.length_squared() > 1.0:
		# Handle walking
		if animation.animation != "walk" or not animation.is_playing():
			animation.animation = "walk"
			animation.play()
			animation.frame = 1
		
		# Handle flipping
		animation.flip_v = false
		if velocity.x != 0:
			animation.flip_h = velocity.x > 0
	else:
		# Stop animation
		if animation.is_playing():
			animation.stop()
		animation.frame = 0

func execute_interaction() -> void:
	if interactables_in_range.is_empty():
		return
	
	# Get the last interactable object
	var target = interactables_in_range.back()
	if target and target.has_method("interact"):
		target.interact(self)

# Signal triggered when entering an interactable area (Task/Vent/...)
func _on_interaction_detector_area_entered(area: Area2D) -> void:
	if area is InteractableObject and not interactables_in_range.has(area):
		# Remove highlight from the previous object before adding the new one
		_update_highlight_state(false)
		
		interactables_in_range.append(area)
		
		# Highlight the newly entered object
		_update_highlight_state(true)

# Signal triggered when exiting an interactable area
func _on_interaction_detector_area_exited(area: Area2D) -> void:
	if interactables_in_range.has(area):
		# Remove highlight from the current object
		_update_highlight_state(false)
		
		interactables_in_range.erase(area)
		
		# Highlight the next object if still standing near another one
		_update_highlight_state(true)

# Function to toggle the highlight for the currently selected object
func _update_highlight_state(enable: bool) -> void:
	if not interactables_in_range.is_empty():
		var current_target = interactables_in_range.back()
		if current_target is InteractableObject:
			current_target.set_highlight(enable)
			
# ==========================================
# KILL RADAR & OUTLINE LOGIC
# ==========================================

func _on_kill_radar_body_entered(body: Node2D) -> void:
	print(">>> [RADAR] Body entered radar: ", body.name) # Check if radar is working
	
	if body.is_in_group("players") and body != self:
		var target_id = body.name.to_int()
		var role = PlayerManager.get_role(target_id)
		var is_alive = PlayerManager.is_player_alive(target_id)
		
		print("    + ID: ", target_id, " | Role: ", role, " | Is Alive?: ", is_alive)
		
		if role != Enums.Role.IMPOSTOR and is_alive:
			kill_targets_in_range.append(body)
			print("    => TARGET ACCEPTED! Total targets in range: ", kill_targets_in_range.size())

func _on_kill_radar_body_exited(body: Node2D) -> void:
	print(">>> [RADAR] Body exited radar: ", body.name)
	if body in kill_targets_in_range:
		kill_targets_in_range.erase(body)

func _update_closest_kill_target() -> void:
	var closest_dist = INF
	var new_target = null
	
	for t in kill_targets_in_range:
		if not is_instance_valid(t):
			continue
			
		# Skip dead players
		if not PlayerManager.is_player_alive(t.name.to_int()):
			continue
			
		var dist = global_position.distance_to(t.global_position)
		if dist < closest_dist:
			closest_dist = dist
			new_target = t
			
	if new_target != current_kill_target:
		if is_instance_valid(current_kill_target):
			current_kill_target.set_player_highlight(false) 
			
		current_kill_target = new_target
		
		if is_instance_valid(current_kill_target):
			current_kill_target.set_player_highlight(true)
			# Send the victim's ID to the Kill Button
			PlayerManager.local_kill_target_updated.emit(current_kill_target.name.to_int()) 
		else:
			# Passing -1 means "No target available"
			PlayerManager.local_kill_target_updated.emit(-1)

# Allows the player character to toggle its own highlight outline
func set_player_highlight(enable: bool) -> void:
	if enable:
		animation.material = outline_material # Apply shader to AnimatedSprite2D
	else:
		animation.material = null # Revert to default material


func _check_alive_status() -> void:
	var peer_id := name.to_int()
	if not PlayerManager.is_player_alive(peer_id):
		_turn_into_dead_body()
	else:
		_reset_to_alive()

func _reset_to_alive() -> void:
	if is_multiplayer_authority():
		set_physics_process(true)
	
	if animation.animation == "rip":
		animation.animation = "walk"
		animation.frame = 0
		animation.stop()
	
	collision_layer = 2 # Restore to Layer 2 (Players)
	
	if kill_radar and is_multiplayer_authority():
		var my_role = PlayerManager.get_role(multiplayer.get_unique_id())
		kill_radar.monitoring = (my_role == Enums.Role.IMPOSTOR)

func _turn_into_dead_body() -> void:
	# 1. Tắt highlight nếu đang bị nhắm tới
	set_player_highlight(false)
	
	# 2. Khóa di chuyển (chỉ áp dụng trên máy của nạn nhân)
	if is_multiplayer_authority():
		set_physics_process(false)
		velocity = Vector2.ZERO
		PlayerManager.local_kill_target_updated.emit(-1)
	
	# 3. Đổi hình ảnh sang bia mộ rip
	animation.animation = "rip"
	animation.play("rip")
	
	# 4. Chuyển Collision Layer sang Layer 3 (Interactable) để người khác bấm Report
	collision_layer = 4 # Layer 3 trong Godot binary là 4
	
	# 5. Tắt radar quét kill nếu người chết là Impostor
	if kill_radar:
		kill_radar.monitoring = false

# Called by the Kill Button UI
func try_kill() -> void:
	if not is_multiplayer_authority():
		return
	if is_lunging:
		return
	# Pick any valid, alive target currently inside the kill radar —
	# no dependency on current_kill_target / the closest-target tracker.
	
	_start_dash(true)

func try_dodge() -> void:
	print(">>> [DODGE] try_dodge called")
	if not is_multiplayer_authority():
		print(">>> [DODGE] blocked: not authority")
		return
	if is_lunging:
		print(">>> [DODGE] blocked: already lunging")
		return
	var my_role = PlayerManager.get_role(multiplayer.get_unique_id())
	if my_role == Enums.Role.IMPOSTOR:
		print(">>> [DODGE] blocked: is impostor")
		return # dodge is crewmate-only
	print(">>> [DODGE] starting dash")
	_start_dash(false) # false = this dash should NOT kill, just move + protect
	
func _start_dash(resolve_kill: bool) -> void:
	is_lunging = true
	velocity = Vector2.ZERO
	
	var start_pos := global_position
	var dir := facing_direction
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN # fallback if somehow never moved yet
		
	var distance := lunge_distance if resolve_kill else dodge_distance
	var lunge_pos := start_pos + dir * distance

	if dir.x != 0:
		animation.flip_h = dir.x < 0
	if resolve_kill:
		animation.animation = "lunge" # replace with your real attack animation name
		animation.play("lunge")
	
	if not resolve_kill:
		_set_invulnerable(true) # start protection the instant the dodge begins
		
	var tween := create_tween()
	tween.tween_property(self, "global_position", lunge_pos, lunge_duration)
	tween.tween_callback(func():
		if resolve_kill:
			_resolve_kill_after_lunge()

		is_lunging = false
		animation.animation = "walk"
		animation.frame = 0
		animation.stop()

		if not resolve_kill:
			# stay protected briefly after landing too, not just mid-dash
			var t := get_tree().create_timer(dodge_invuln_duration)
			t.timeout.connect(func(): _set_invulnerable(false))
		
	)

func _set_invulnerable(value: bool) -> void:
	ServerManager.request_set_invulnerable.rpc_id(1, value)
	
func _resolve_kill_after_lunge() -> void:
	# Whoever is inside the kill radar right now, at the lunge's landing spot, dies.
	for t in kill_targets_in_range:
		if is_instance_valid(t) and PlayerManager.is_player_alive(t.name.to_int()):
			_send_kill_request(t)
			break # remove this line if you want the dash to hit EVERYONE currently in range
			
func _send_kill_request(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var target_id := target.name.to_int()
	if not PlayerManager.is_player_alive(target_id):
		return

	ServerManager.request_kill.rpc_id(1, target_id)

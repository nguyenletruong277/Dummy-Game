extends Node2D

@onready var ready_button: Button = $UI/LobbyUI/Control/PanelContainer/VBoxContainer/ReadyButton
@onready var start_button: Button = $UI/LobbyUI/Control/PanelContainer/VBoxContainer/StartButton
@onready var player_list_container: VBoxContainer = $UI/LobbyUI/Control/PanelContainer/VBoxContainer/PlayerListContainer
@onready var scene_container: Node2D = $World/SceneContainer
@onready var lobby_ui: CanvasLayer = $UI/LobbyUI
@onready var gameplay_ui: CanvasLayer = $UI/GameplayUI
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var role_icon = $UI/GameplayUI/RoleIcon
@onready var kill_button = $UI/GameplayUI/KillButton
const LOBBY_SCENE := preload("res://scenes/waiting_room/lobby_scene.tscn")
const GAMEPLAY_SCENE := preload("res://scenes/gameplay_room/gameplay.tscn") 

func _ready() -> void:
	ready_button.pressed.connect(_on_ready_pressed)
	start_button.pressed.connect(_on_start_pressed)

	start_button.visible = multiplayer.is_server()
	start_button.disabled = true

	gameplay_ui.visible = false
	lobby_ui.visible = true

	PlayerManager.players_state_updated.connect(_update_ui)
	GameManager.state_changed.connect(_on_state_changed)
	
	# Listen for role assignments when the match starts
	PlayerManager.local_role_updated.connect(_on_local_role_updated)

	_update_ui()
	load_scene(LOBBY_SCENE)   # start in the lobby


#swap lobby and gameplay
func load_scene(packed_scene: PackedScene) -> void:
	# Xóa map cũ
	for child in scene_container.get_children():
		child.queue_free()
	
	if packed_scene:
		# Thêm map mới (Lobby/Gameplay) vào SceneContainer
		var instance = packed_scene.instantiate()
		scene_container.add_child(instance)
		print("[Main] Peer %d — loaded scene: %s" % [multiplayer.get_unique_id(), packed_scene.resource_path])

# main_game.gd

func _on_state_changed(new_state: Enums.GameState) -> void:
	match new_state:
		Enums.GameState.LOBBY:
			lobby_ui.visible = true
			gameplay_ui.visible = false
			load_scene(LOBBY_SCENE)
			_teleport_to_current_map()

		Enums.GameState.PLAYING:
			lobby_ui.visible = false
			gameplay_ui.visible = true
			load_scene(GAMEPLAY_SCENE)
			_teleport_to_current_map()

func _teleport_to_current_map() -> void:
	await get_tree().create_timer(0.1).timeout
	if not multiplayer.is_server():
		return

	# Lấy map vừa được load
	if scene_container.get_child_count() > 0:
		var current_map = scene_container.get_child(0)
		# Tìm node SpawnPoints trong map đó
		var spawn_container = current_map.get_node_or_null("SpawnPoints")
		if spawn_container and spawn_container.get_child_count() > 0:
			# Lấy vị trí Marker2D đầu tiên tìm thấy
			var spawn_pos = spawn_container.get_child(0).global_position
			$MultiplayerSpawner.move_all_players_to(spawn_pos)

func _on_ready_pressed() -> void:
	ready_button.disabled = true
	ServerManager.request_local_ready(true)


func _on_start_pressed() -> void:
	if not multiplayer.is_server():
		return
	GameManager.request_start_match()


func _update_ui() -> void:
	for child in player_list_container.get_children():
		child.queue_free()

	for id in PlayerManager.players_state:
		var label := Label.new()
		var status := "✅ Ready" if PlayerManager.is_player_ready(id) else "⏳ Not Ready"
		var display_name: String = "Player ID: %d" % id
		label.text = "%s - %s" % [display_name, status]
		player_list_container.add_child(label)

	if multiplayer.is_server():
		start_button.disabled = not PlayerManager.all_players_ready()
		
		# ==========================================
# --- ROLE UI UPDATES ---
# ==========================================

func _on_local_role_updated(my_role: Enums.Role) -> void:
	# 1. Update the Kill Button visibility
	if kill_button.has_method("setup_role"):
		kill_button.setup_role(my_role)
	
	# 2. Update visuals based on the assigned role (IMAGE ONLY)
	if my_role == Enums.Role.IMPOSTOR:
		# Load the Impostor image
		var imp_tex = load("res://assets/UI/Imposter.png")
		if imp_tex:
			role_icon.texture = imp_tex
			
	else:
		# Load the Crewmate image
		var crew_tex = load("res://assets/UI/Chicken.png")
		if crew_tex:
			role_icon.texture = crew_tex

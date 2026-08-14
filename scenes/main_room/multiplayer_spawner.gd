extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		_spawn_player_for_id(1)

func _on_peer_connected(id: int) -> void:
	_spawn_player_for_id(id)

func _spawn_player_for_id(id: int) -> void:
	if not multiplayer.is_server():
		return

	var player = network_player.instantiate()
	player.name = str(id)

	var target_node = get_node_or_null(spawn_path)
	if target_node:
		target_node.add_child(player, true)
		player.set_multiplayer_authority(id)
		PlayerManager.register_player_node(id, player)

## Dịch chuyển tất cả player đến vị trí Vector2 truyền vào
func move_all_players_to(spawn_pos: Array[Vector2]) -> void:
	if not multiplayer.is_server():
		return
	if spawn_pos.is_empty():
		push_warning("[MultiplayerSpawner] No spawn points available.")
		return

	var target_node = get_node_or_null(spawn_path)
	
	if not target_node:
		return
		
	var shuffled_positions := spawn_pos.duplicate()
	shuffled_positions.shuffle()
	var players := target_node.get_children()
	for i in range(players.size()):
		var player = players[i]
		# Wrap around if there are more players than spawn points
		var pos: Vector2 = shuffled_positions[i % shuffled_positions.size()]
		rpc("set_player_position", player.name, pos)

@rpc("call_local", "reliable")
func set_player_position(player_name: String, pos: Vector2) -> void:
	var target_node = get_node_or_null(spawn_path)
	if target_node:
		var player_node = target_node.get_node_or_null(player_name)
		if player_node:
			player_node.global_position = pos

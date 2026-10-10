extends Node

## Tarmoq qatlami: do'stlar bilan va internetda o'ynash.
##
## Model oddiy va ishonchli: **uy egasi** (host) butun o'yinni o'zi
## hisoblaydi — botlar ham, qoidalar ham, hudud egallash ham. Mehmonlar
## faqat yo'nalishini yuboradi va tayyor holatni oladi. Shuning uchun
## hamma bir xil o'yinni ko'radi va aldash qiyin.
##
## Yuboriladigan narsa ikki xil:
##  * **ro'yxat** — o'yinchilar nomi, rangi, bayrog'i (kamdan-kam,
##    ishonchli kanal);
##  * **holat** — pozitsiyalar va o'zgargan kataklar (sekundiga
##    [SNAPSHOT_HZ] marta).
##
## Qo'shilgan mehmonga avval butun panjara bir marta siqib yuboriladi,
## keyin faqat farqlar ketadi.

signal roster_changed
## Mehmon xonaga qabul qilindi: o'yinchi raqami va maydon nomi bilan.
## Dunyo shu signalda darhol quriladi — keyingi xabarlar unga tushadi.
signal joined(player_id: int, map_id: String)
signal started
signal stopped(reason: String)
signal status(text: String)

const PORT := 7777
const MAX_CLIENTS := 15
const SNAPSHOT_HZ := 15.0

## Bitta xabarda yuboriladigan katak soni. ENet paketni o'zi bo'laklarga
## bo'ladi, lekin kichik xabar kechikishni kamaytiradi.
const CELLS_PER_MESSAGE := 400

enum Role { OFFLINE, HOST, CLIENT }

var role: Role = Role.OFFLINE
## Mehmonda: o'zining o'yinchi raqami.
var local_player_id := 1
## Uy egasida: peer -> o'yinchi raqami.
var _peer_player := {}
## Ro'yxat: [{id, name, color, avatar, country, is_bot}].
var roster: Array = []

var _world: GameWorld
var _timer := 0.0
var _profile := {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connect_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)

func is_online() -> bool:
	return role != Role.OFFLINE

func is_host() -> bool:
	return role == Role.HOST

# ——— Ulanish ———

## Xona ochadi. Xato bo'lsa sababni qaytaradi, aks holda bo'sh satr.
func host_room(port: int = PORT) -> String:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		return "xato %d" % err
	multiplayer.multiplayer_peer = peer
	role = Role.HOST
	local_player_id = 1
	return ""

## Xonaga qo'shiladi. `address` — IP yoki server manzili.
func join_room(address: String, profile: Dictionary,
		port: int = PORT) -> String:
	leave()
	_profile = profile
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return "xato %d" % err
	multiplayer.multiplayer_peer = peer
	role = Role.CLIENT
	return ""

func leave() -> void:
	if multiplayer.multiplayer_peer != null \
			and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = Role.OFFLINE
	_peer_player.clear()
	roster.clear()
	_world = null

## Shu qurilmaning mahalliy tarmoqdagi manzili — do'stlarga aytish uchun.
static func local_address() -> String:
	for address: String in IP.get_local_addresses():
		if address.begins_with("127.") or address.contains(":"):
			continue
		return address
	return "127.0.0.1"

# ——— Uy egasi ———

## O'yin boshlandi: dunyo tarmoqqa ulanadi.
func attach_world(world: GameWorld, profile: Dictionary) -> void:
	_world = world
	_profile = profile
	if role == Role.HOST:
		local_player_id = world.human().id
		_rebuild_roster()
		started.emit()

func _on_peer_connected(peer: int) -> void:
	status.emit("ulandi: %d" % peer)

func _on_peer_disconnected(peer: int) -> void:
	if role != Role.HOST or _world == null:
		return
	var id: int = _peer_player.get(peer, 0)
	_peer_player.erase(peer)
	if id > 0:
		var player := _world.player_by_id(id)
		if player != null and player.alive:
			_world.kill(player, PlayerState.DeathCause.NONE, null)
	_rebuild_roster()

func _on_connected() -> void:
	status.emit("ulandi")
	rpc_id(1, "hello", _profile)

func _on_connect_failed() -> void:
	leave()
	stopped.emit("connectFailed")

func _on_server_gone() -> void:
	leave()
	stopped.emit("hostLeft")

## Mehmon o'zini tanishtiradi; uy egasi unga o'yinchi ajratadi.
@rpc("any_peer", "reliable")
func hello(profile: Dictionary) -> void:
	if role != Role.HOST or _world == null:
		return
	var peer := multiplayer.get_remote_sender_id()
	var player := _world.add_human(
		str(profile.get("name", "?")), int(profile.get("color", 0)),
		str(profile.get("avatar", "figure:0")),
		str(profile.get("country", Profile.DEFAULT_COUNTRY)))
	if player == null:
		return
	_peer_player[peer] = player.id
	_world.spawn(player)
	_rebuild_roster()
	welcome.rpc_id(peer, player.id, _world.config.map_id)
	_send_full_state(peer)

@rpc("authority", "reliable")
func welcome(player_id: int, map_id: String) -> void:
	local_player_id = player_id
	# Dunyo shu yerda quriladi: keyin keladigan panjara va holat
	# xabarlari tayyor dunyoga tushishi kerak.
	joined.emit(player_id, map_id)

@rpc("authority", "reliable")
func set_roster(rows: Array) -> void:
	roster = rows
	roster_changed.emit()

func _rebuild_roster() -> void:
	if _world == null:
		return
	var rows: Array = []
	for p in _world.players:
		rows.append({
			"id": p.id, "name": p.player_name, "color": p.color_index,
			"avatar": p.avatar, "country": p.country, "bot": p.is_bot,
		})
	roster = rows
	roster_changed.emit()
	if role == Role.HOST:
		set_roster.rpc(rows)

# ——— Boshqaruv ———

## Mehmon yo'nalishini uy egasiga yuboradi.
func send_steer(angle: float) -> void:
	if role == Role.CLIENT:
		steer.rpc_id(1, angle)

@rpc("any_peer", "unreliable_ordered")
func steer(angle: float) -> void:
	if role != Role.HOST or _world == null:
		return
	var id: int = _peer_player.get(multiplayer.get_remote_sender_id(), 0)
	var player := _world.player_by_id(id)
	if player != null:
		player.steer_to(angle)

# ——— Holat ———

func _process(delta: float) -> void:
	if role != Role.HOST or _world == null or _peer_player.is_empty():
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 1.0 / SNAPSHOT_HZ
	_send_snapshot()

func _send_snapshot() -> void:
	var state := PackedFloat32Array()
	for p in _world.players:
		state.append(p.id)
		state.append(p.x)
		state.append(p.y)
		state.append(p.angle)
		state.append(1.0 if p.alive else 0.0)
		state.append(p.kills)
	# Pozitsiyalar kichik va tez eskiradi — ishonchsiz kanal.
	snapshot.rpc(state)

	# Kataklar esa yo'qolmasligi kerak, aks holda ikki tomondagi
	# panjara bir-biridan ajralib ketadi — ishonchli kanal, bo'lib
	# yuboriladi.
	var cells := _world.grid.take_net_dirty()
	var from := 0
	while from < cells.size():
		var to: int = mini(from + CELLS_PER_MESSAGE, cells.size())
		var part := cells.slice(from, to)
		var owners := PackedByteArray()
		var trails := PackedByteArray()
		owners.resize(part.size())
		trails.resize(part.size())
		for k in part.size():
			var i: int = part[k]
			owners[k] = _world.grid.owner_cells[i]
			trails[k] = _world.grid.trail_cells[i]
		cells_changed.rpc(part, owners, trails)
		from = to

@rpc("authority", "reliable")
func cells_changed(cells: PackedInt32Array, owners: PackedByteArray,
		trails: PackedByteArray) -> void:
	if _world == null:
		return
	for k in cells.size():
		_world.grid.set_owner_index(cells[k], owners[k])
		_world.grid.set_trail_index(cells[k], trails[k])

@rpc("authority", "unreliable_ordered")
func snapshot(state: PackedFloat32Array) -> void:
	if _world == null:
		return
	var step := 6
	for k in range(0, state.size(), step):
		var player := _world.player_by_id(int(state[k]))
		if player == null:
			continue
		player.x = state[k + 1]
		player.y = state[k + 2]
		player.cx = int(floor(player.x))
		player.cy = int(floor(player.y))
		player.angle = state[k + 3]
		player.alive = state[k + 4] > 0.5
		player.kills = int(state[k + 5])

## Yangi qo'shilganga butun panjara bir marta yuboriladi.
func _send_full_state(peer: int) -> void:
	var grid := _world.grid
	full_state.rpc_id(peer, grid.width, grid.height,
		grid.owner_cells.compress(FileAccess.COMPRESSION_ZSTD),
		grid.trail_cells.compress(FileAccess.COMPRESSION_ZSTD))

@rpc("authority", "reliable")
func full_state(width: int, height: int, owners: PackedByteArray,
		trails: PackedByteArray) -> void:
	if _world == null:
		return
	var count := width * height
	if count != _world.grid.owner_cells.size():
		push_error("Panjara o'lchami mos kelmadi")
		return
	var own := owners.decompress(count, FileAccess.COMPRESSION_ZSTD)
	var tr := trails.decompress(count, FileAccess.COMPRESSION_ZSTD)
	for i in count:
		_world.grid.set_owner_index(i, own[i])
		_world.grid.set_trail_index(i, tr[i])
	started.emit()

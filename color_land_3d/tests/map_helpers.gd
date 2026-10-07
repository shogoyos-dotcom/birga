extends RefCounted

## Testlar uchun kichik xaritalar.
##
## `class_name` ataylab yo'q — sababi `test_runner.gd` da yozilgan.
##
## Belgilar: `~` — suv, `.` — bo'sh quruqlik, raqam — o'sha ID hududi.
static func grid_from(pattern: PackedStringArray) -> GameGrid:
	var w := pattern[0].length()
	var h := pattern.size()
	var land := PackedByteArray()
	land.resize(w * h)
	for y in h:
		for x in w:
			land[y * w + x] = 0 if pattern[y][x] == "~" else 1
	var grid := GameGrid.new(w, h, land)
	for y in h:
		for x in w:
			var ch := pattern[y][x]
			if ch == "~" or ch == ".":
				continue
			grid.set_owner(x, y, int(ch))
	return grid

## Panjarani matnga aylantiradi — xato chiqqanda ko'rish uchun.
static func dump(grid: GameGrid) -> PackedStringArray:
	var out := PackedStringArray()
	for y in grid.height:
		var line := ""
		for x in grid.width:
			if not grid.is_land(x, y):
				line += "~"
			else:
				var o := grid.owner_at(x, y)
				line += "." if o == 0 else str(o)
		out.append(line)
	return out

## Testlar uchun kichik, oddiy to'rtburchak dunyo.
static func make_world(width: int = 24, height: int = 24,
		seed_value: int = 7) -> GameWorld:
	var config := GameConfig.new()
	config.world_map = false
	config.grid_width = width
	config.grid_height = height
	config.bot_count = 0
	config.player_turn_rate = 1000.0
	config.bot_turn_rate = 1000.0
	return GameWorld.new(config, seed_value)

## O'yinchini aniq joyga qo'yadi (spawn tasodifiyligisiz).
static func place_player(world: GameWorld, left: int, top: int,
		size: int = 5, is_bot: bool = false, angle: float = 0.0) -> PlayerState:
	var p := world.add_player("P", 0, is_bot)
	world.grid.fill_block(left, top, size, p.id)
	p.place_at(left + size / 2.0, top + size / 2.0, angle)
	return p

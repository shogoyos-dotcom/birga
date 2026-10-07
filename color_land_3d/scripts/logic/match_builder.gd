class_name MatchBuilder
extends RefCounted

## Bitta o'yin yaratadi: o'yinchi + botlar, hammasi joylashtirilgan.

const BOT_NAMES: PackedStringArray = [
	"Max", "Vega", "Mira", "Yuki", "Milo", "Alma", "Taho", "Luka",
	"Nova", "Pixi", "Rico", "Sora", "Omar", "Elsa", "Bodo", "Juno",
	"Zara", "Kira", "Lola", "Dino", "Tara", "Gizo", "Ravi", "Nika",
]

static func create(config: GameConfig, player_color: int, player_name: String,
		seed_value: int = 0) -> GameWorld:
	var world := GameWorld.new(config, seed_value)
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value + 1

	world.add_player(player_name, player_color % Palette.HEADS.size(), false)

	# Botlarga o'yinchinikidan boshqa ranglar beriladi.
	var colors: Array[int] = []
	for i in Palette.HEADS.size():
		if i != player_color % Palette.HEADS.size():
			colors.append(i)
	colors.shuffle()

	var names := Array(BOT_NAMES)
	names.shuffle()

	for i in config.bot_count:
		world.add_player(
			names[i % names.size()],
			colors[i % colors.size()],
			true,
			BotBrain.new(config.difficulty, rng))

	world.spawn_all()
	return world

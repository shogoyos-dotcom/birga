class_name MatchBuilder
extends RefCounted

## Bitta o'yin yaratadi: o'yinchi + botlar, hammasi joylashtirilgan.

const BOT_NAMES: PackedStringArray = [
	"Max", "Vega", "Mira", "Yuki", "Milo", "Alma", "Taho", "Luka",
	"Nova", "Pixi", "Rico", "Sora", "Omar", "Elsa", "Bodo", "Juno",
	"Zara", "Kira", "Lola", "Dino", "Tara", "Gizo", "Ravi", "Nika",
]

static func create(config: GameConfig, player_color: int, player_name: String,
		player_avatar: String = "figure:0", seed_value: int = 0) -> GameWorld:
	var world := GameWorld.new(config, seed_value)
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value + 1

	var human := world.add_player(
		player_name, player_color % Palette.color_count(), false)
	human.avatar = player_avatar

	# Botlarga o'yinchinikidan boshqa ranglar beriladi.
	var colors: Array[int] = []
	for i in Palette.color_count():
		if i != player_color % Palette.color_count():
			colors.append(i)
	colors.shuffle()

	var names := Array(BOT_NAMES)
	names.shuffle()

	for i in config.bot_count:
		var bot := world.add_player(
			names[i % names.size()],
			colors[i % colors.size()],
			true,
			BotBrain.new(config.difficulty, rng))
		bot.avatar = Profile.random_avatar(rng)

	world.spawn_all()
	return world

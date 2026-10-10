class_name ImagePicker
extends RefCounted

## O'yinchining o'z rasmini tanlash va o'yinga moslash.
##
## Tanlangan rasm kvadrat qilib qirqiladi, kichraytiriladi va
## `user://` ichiga saqlanadi — asl fayl keyin o'chirilsa ham avatar
## joyida qoladi.
##
## Tizimning o'z oynasi bo'lsa (Android, ish stoli) o'sha ishlatiladi;
## bo'lmasa o'yin ichidagi oddiy fayl oynasi ochiladi.

## Saqlanadigan rasm tomoni (piksel). Atlasdagi katak bilan bir xil.
const SIZE := 192

const FILTERS: PackedStringArray = [
	"*.png,*.jpg,*.jpeg,*.webp,*.bmp",
]

## Avatar va bayroq uchun fayl nomlari.
const AVATAR_FILE := "user://avatar.png"
const FLAG_FILE := "user://flag.png"

## Rasm tanlash oynasini ochadi. Tugagach `on_done` chaqiriladi:
## muvaffaqiyatli bo'lsa `dest`, aks holda bo'sh satr bilan.
static func open(parent: Node, dest: String, title: String,
		on_done: Callable) -> void:
	if OS.get_name() == "Android":
		# Rasmni o'qish uchun ruxsat so'raladi; rad etilsa oyna
		# baribir ochiladi va ichki xotirani ko'rsatadi.
		OS.request_permissions()

	var done := func(path: String) -> void:
		on_done.call(dest if import_image(path, dest) else "")

	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		DisplayServer.file_dialog_show(
			title, start_dir(), "", false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, FILTERS,
			func(ok: bool, files: PackedStringArray, _filter: int) -> void:
				if ok and not files.is_empty():
					done.call(files[0])
				else:
					on_done.call(""))
		return

	var dialog := FileDialog.new()
	dialog.title = title
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = FILTERS
	dialog.current_dir = start_dir()
	dialog.size = Vector2i(560, 640)
	dialog.file_selected.connect(func(path: String) -> void:
		done.call(path)
		dialog.queue_free())
	dialog.canceled.connect(func() -> void:
		on_done.call("")
		dialog.queue_free())
	parent.add_child(dialog)
	dialog.popup_centered()

## Oyna ochiladigan papka.
static func start_dir() -> String:
	if OS.get_name() == "Android":
		return "/storage/emulated/0"
	var pictures := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	return pictures if not pictures.is_empty() else OS.get_user_data_dir()

## Rasmni o'qiydi, kvadrat qirqadi, kichraytiradi va saqlaydi.
static func import_image(source: String, dest: String) -> bool:
	if source.is_empty():
		return false
	var image := Image.load_from_file(source)
	if image == null or image.is_empty():
		push_error("Rasm o'qilmadi: %s" % source)
		return false
	# Markazidan kvadrat qirqiladi — cho'zilib ketmasin.
	var side: int = mini(image.get_width(), image.get_height())
	image = image.get_region(Rect2i(
		(image.get_width() - side) / 2, (image.get_height() - side) / 2,
		side, side))
	image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGBA8)
	return image.save_png(dest) == OK

## Saqlangan rasmni teksturaga aylantiradi. Yo'q bo'lsa `null`.
static func load_texture(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

static func remove(path: String) -> void:
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

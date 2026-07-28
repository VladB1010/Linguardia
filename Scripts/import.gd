extends TextureButton

@onready var _popup: NinePatchRect = $NinePatchRect
@onready var _label: Label = $NinePatchRect/Label

var _original_text: String = ""
var _browse_btn: Button
var _file_dialog: FileDialog

func _ready() -> void:
	_popup.visible = false
	_original_text = _label.text
	pressed.connect(_on_pressed)
	_label.offset_bottom = -50

	_browse_btn = Button.new()
	_browse_btn.text = "Alege fisier .txt"
	_browse_btn.custom_minimum_size = Vector2(220, 35)

	_browse_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_browse_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_browse_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_browse_btn.offset_left = -110
	_browse_btn.offset_right = 110
	_browse_btn.offset_top = -45
	_browse_btn.offset_bottom = -10

	_browse_btn.focus_mode = Control.FOCUS_NONE
	_popup.add_child(_browse_btn)
	_browse_btn.pressed.connect(_on_browse_pressed)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = ["*.txt ; Text Files"]
	_file_dialog.title = "Selectează vocabularul (.txt)"
	if "use_native_dialog" in _file_dialog:
		_file_dialog.use_native_dialog = true
	add_child(_file_dialog)
	_file_dialog.file_selected.connect(_on_file_selected)

func _on_pressed() -> void:
	_popup.visible = !_popup.visible
	if _popup.visible:
		if not get_window().files_dropped.is_connected(_on_files_dropped):
			get_window().files_dropped.connect(_on_files_dropped)
		_label.text = _original_text
	else:
		_cleanup()

func _cleanup() -> void:
	if get_window().files_dropped.is_connected(_on_files_dropped):
		get_window().files_dropped.disconnect(_on_files_dropped)

func _exit_tree() -> void:
	_cleanup()

func _on_browse_pressed() -> void:
	_file_dialog.popup_centered(Vector2i(800, 500))

func _on_file_selected(path: String) -> void:
	_process_file(path)

func _on_files_dropped(files: PackedStringArray) -> void:
	if not _popup.visible:
		return
	if files.is_empty():
		return
	_process_file(files[0])

func _process_file(path: String) -> void:
	if not path.ends_with(".txt"):
		_label.text = "Te rog alege un fisier .txt!"
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_label.text = "Eroare la citirea fisierului."
		return

	var text: String = file.get_as_text()
	file.close()

	CustomWordList.import_from_text(text)

	_label.text = "Import reusit!\n"

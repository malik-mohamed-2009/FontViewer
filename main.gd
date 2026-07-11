extends CanvasLayer

@onready var preview_label: Label = $VBoxContainer/PreviewPanel/ScrollContainer/PreviewLabel
@onready var preview_toast_label: Label = $VBoxContainer/PreviewPanel/PreviewToast
@onready var input_field: LineEdit = $VBoxContainer/ControlsPanel/ScrollContainer/MarginContainer/GridContainer/InputField
@onready var weight_button: OptionButton = $VBoxContainer/ControlsPanel/ScrollContainer/MarginContainer/GridContainer/WeightButton
@onready var font_button: OptionButton = $VBoxContainer/ControlsPanel/ScrollContainer/MarginContainer/GridContainer/FontButton
@onready var size_slider: HSlider = $VBoxContainer/ControlsPanel/ScrollContainer/MarginContainer/GridContainer/SizeSlider
@onready var font_color_picker: ColorPicker = $VBoxContainer/ControlsPanel/ScrollContainer/MarginContainer/GridContainer/FontColorPick
@onready var import_button: OptionButton = $VBoxContainer/ControlsPanel/ScrollContainer/MarginContainer/GridContainer/ImportButton
@onready var font_file_dialog: FileDialog = $FontFileDialog

var fonts = {
	"Warm, approachable, and playful (Nunito)": {
		"Light": "res://fonts/nunito/0.ttf",
		"Regular": "res://fonts/nunito/1.ttf",
		"Medium": "res://fonts/nunito/2.ttf",
		"Bold": "res://fonts/nunito/3.ttf",
		"Extra Bold": "res://fonts/nunito/4.ttf",
		"Black": "res://fonts/nunito/5.ttf"
	}
}

func _ready():
	setup_ui_options()
	
	input_field.text_changed.connect(_on_text_changed)
	weight_button.item_selected.connect(_on_font_settings_changed)
	font_button.item_selected.connect(_on_font_settings_changed)
	size_slider.value_changed.connect(_on_size_changed)
	font_color_picker.color_changed.connect(_on_font_color_changed)
	import_button.item_selected.connect(_on_import_button_pressed)
	font_file_dialog.file_selected.connect(_on_font_file_selected)
	
	update_preview()
	
	if OS.get_name() == "Android": import_button.set_item_text(0, "Select file via Android System")
	if OS.get_name() == "PC": import_button.set_item_text(0, "Import file (DnD not possible!)")
	if OS.get_name() == "XR": import_button.set_item_text(0, "Import file (Google, Meta)")
	import_button.set_item_text(1, "Main " + OS.get_name())

func _process(delta):
	preview_toast_label.modulate.a -= delta / 2

func setup_ui_options():
	var current_selection = font_button.selected if font_button.selected != -1 else 0
	font_button.clear()
	for font_name in fonts.keys():
		font_button.add_item(font_name)
	font_button.selected = current_selection
	update_weight_options()

func update_weight_options():
	var current_font = font_button.get_item_text(font_button.selected)
	var current_weight = weight_button.get_item_text(weight_button.selected) if weight_button.selected != -1 else "Regular"
	
	weight_button.clear()
	var weights = fonts[current_font].keys()
	
	for weight in weights:
		weight_button.add_item(weight)
		
	for i in range(weight_button.item_count):
		if weight_button.get_item_text(i) == current_weight:
			weight_button.selected = i
			return
	weight_button.selected = 0

func update_preview():
	preview_label.text = input_field.text if input_field.text != "" else "FontViewer"
	
	var selected_size = int(size_slider.value)
	preview_label.add_theme_font_size_override("font_size", selected_size)
	
	var selected_font = font_button.get_item_text(font_button.selected)
	var selected_weight = weight_button.get_item_text(weight_button.selected)
	var font_target = fonts[selected_font][selected_weight]
	
	if font_target is String:
		var new_font = load(font_target)
		if new_font:
			preview_label.add_theme_font_override("font", new_font)
			font_button.add_theme_font_override("font", new_font)
	elif font_target is FontFile:
		preview_label.add_theme_font_override("font", font_target)
		font_button.add_theme_font_override("font", font_target)

func _on_text_changed(_new_text: String):
	update_preview()

func _on_font_settings_changed(_index: int):
	if font_button.has_focus() or font_button == get_viewport().gui_get_focus_owner():
		update_weight_options()
	update_preview()

func _on_size_changed(_value: int):
	preview_toast_label.text = str("Scale : ", _value, "px")
	preview_toast_label.modulate.a = 1.0
	update_preview()

func _on_font_color_changed(_color: Color):
	preview_label.add_theme_color_override("font_color", _color)
	update_preview()

func _on_import_button_pressed(_index: int):
	if _index == 1: font_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	if _index == 2: font_file_dialog.access = FileDialog.ACCESS_USERDATA
	font_file_dialog.popup_centered_ratio()
	import_button.selected = 0

func _on_font_file_selected(path: String):
	var file_name = path.get_file().get_basename()
	
	var imported_font = FontFile.new()
	imported_font.load_dynamic_font(path)
	
	fonts[file_name] = {
		"Custom": imported_font
	}
	
	setup_ui_options()
	font_button.selected = font_button.item_count - 1
	update_weight_options()
	update_preview()

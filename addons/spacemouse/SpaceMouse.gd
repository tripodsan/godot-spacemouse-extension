@tool
extends EditorPlugin

var device:SpacemouseDevice = SpacemouseDevice.new()
#register the spacemouse type

# scene for the configuration dock
var space_dock:Control = null

# if the device is connected
var connected:bool = false

# default speeds (modified by ui)
const base_translate_speed := 0.16
const base_rotate_speed := 0.0275

# main speed control for motion updates
var translate_speed:float = base_translate_speed
var rotate_speed:float = base_rotate_speed

# node to access configuration ui
var translation_speed_ui:Range = null
var rotation_speed_ui:Range = null
var control_type_ui:OptionButton = null

# name for control type
enum ControlType { OBJECT_TYPE = 0, CAMERA_TYPE = 1}

# object or camera control
var control_type := ControlType.CAMERA_TYPE

# records the current main screen editor
var current_main_screen:String = "3D"

# previously pressed button
var prev_buttons:int = 0

# on start add the configuration dock
func _enter_tree():
  # instance the dock
  space_dock = preload("res://addons/spacemouse/SpaceDock.tscn").instantiate()
  # attach signals for ui controls
  translation_speed_ui = space_dock.get_node("UI/TranslationSpeed")
  translation_speed_ui.value_changed.connect(update_config)
  rotation_speed_ui = space_dock.get_node("UI/RotationSpeed")
  rotation_speed_ui.value_changed.connect(update_config)
  control_type_ui = space_dock.get_node("UI/ControlType")
  control_type_ui.item_selected.connect(update_config)
  # add ui dock to the editor slot
  add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, space_dock)
  main_screen_changed.connect(_on_main_screen_changed)

# update the controls on ui changes
func update_config(val):
  # scale the translation and rotation speeds
  translate_speed = base_translate_speed * (translation_speed_ui.value * 0.01)
  rotate_speed = base_rotate_speed * (rotation_speed_ui.value * 0.01)
  # toggle camera control type
  control_type = control_type_ui.selected

func _get_window_layout(configuration):
  configuration.set_value("spacemouse", "translation_speed", translation_speed_ui.value)
  configuration.set_value("spacemouse", "rotation_speed", rotation_speed_ui.value)
  configuration.set_value("spacemouse", "control_type", control_type_ui.selected)

func _set_window_layout(configuration):
  translation_speed_ui.value = configuration.get_value("spacemouse", "translation_speed", base_translate_speed)
  rotation_speed_ui.value = configuration.get_value("spacemouse", "rotation_speed", base_rotate_speed)
  control_type_ui.selected = configuration.get_value("spacemouse", "control_type", ControlType.CAMERA_TYPE)

func _on_main_screen_changed(name:String):
  #prints('main screen changed: ', name)
  current_main_screen = name

# cleanup on exit
func _exit_tree():
  device.disconnect()
  remove_control_from_docks(space_dock)
  main_screen_changed.disconnect(_on_main_screen_changed)
  if is_instance_valid(space_dock):
    space_dock.queue_free()

func _ready():
  # until https://github.com/godotengine/godot-proposals/issues/2081 is fixed
  # we force a main screen change, so that we can track the current main screen
  EditorInterface.set_main_screen_editor("3D")
  connected = device.connect()

func toggle_control_type():
  control_type = (control_type + 1) % 2
  control_type_ui.selected = control_type
  #prints('set_control_type', control_type)

func reset_camera():
  var vp := EditorInterface.get_editor_viewport_3d(0)
  var camera := vp.get_camera_3d()
  var target := get_selected_position()
  var eye = target + Vector3(0, 2, -15)
  camera.look_at_from_position(eye, target, Vector3.UP)


func get_selected_position()->Vector3:
  var selection:EditorSelection = EditorInterface.get_selection()
  var selected = selection.get_top_selected_nodes()
  if selected.size() > 0 and selected[0] is Node3D:
    return selected[0].global_position
  return Vector3.ZERO

func _process(delta):
  if !connected or EditorInterface.is_playing_scene(): return
  if current_main_screen != "3D":
    # todo: also support 2D ?
    return

  # check if button was pressed
  var buttons:int = device.get_buttons()
  if buttons != prev_buttons:
    if buttons & 2 != 0:
      toggle_control_type()
    elif buttons & 1 != 0:
      reset_camera()
    prev_buttons = buttons

  if not device.is_modified():
    return

  # todo: support active viewport somehow?
  var vp := EditorInterface.get_editor_viewport_3d(0)
  var camera := vp.get_camera_3d()

  #if camera.projection != Camera3D.PROJECTION_PERSPECTIVE:
    ## todo: handle non perspective camera
    #return

  # obtain the raw translation and rotation values from the device
  var space_translation:Vector3 = device.get_translation() * translate_speed * delta
  var space_rotation:Vector3 = device.get_rotation() * rotate_speed * delta

  var target := get_selected_position()
  var tx:Transform3D = camera.global_transform

  if control_type == ControlType.OBJECT_TYPE:
    var offset := tx.origin - target
    var RIGHT:Vector3 = tx.basis.x.normalized()
    tx.origin = Vector3.ZERO

    # rotate camera and offset accordingly
    tx = tx.rotated(RIGHT, -space_rotation.x)
    tx = tx.rotated(Vector3.UP, -space_rotation.y)

    # rotate the camera around the target
    offset = offset.rotated(RIGHT, -space_rotation.x)
    offset = offset.rotated(Vector3.UP, -space_rotation.y)

    # move back
    tx.origin = target + offset - tx * space_translation

  else:
    # fly camera
    tx = tx.rotated(tx.basis.x.normalized(), space_rotation.x)
    tx = tx.rotated(tx.basis.y.normalized(), space_rotation.y)
    tx = tx.translated_local(space_translation)

  camera.global_transform = tx

# [Godot Space Mouse]
# created by Andres Hernandez
@tool
extends EditorPlugin

var device:SpacemouseDevice = SpacemouseDevice.new()
#register the spacemouse type

# scene for the configuration dock
var space_dock:Control = null

# if the device is connected
var connected:bool = false

# currently selected object
#var selection:EditorSelection = null

# the editor interface
#var editor = null

# default speeds (modified by ui)
const base_translate_speed := 0.16
const base_rotate_speed := 0.0275

# main speed control for motion updates
var translate_speed:float = base_translate_speed
var rotate_speed:float = base_rotate_speed

# sets viewport camera to the first one
const camera_index = 0

# node to access configuration ui
var translation_speed_ui = null
var rotation_speed_ui = null
var control_type_ui = null

# name for control type
const ControlType = {OBJECT_TYPE = 0, CAMERA_TYPE = 1}

# object or camera control
var control_type := ControlType.CAMERA_TYPE

# adjust fly camera translation
const adjust_translation := 0.24
const adjust_rotation := 0.98

var current_main_screen:String = "3D"

var spherical:Spherical = null

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
  prints('main screen changed: ', name)
  current_main_screen = name

# cleanup on exit
func _exit_tree():
  device.disconnect()
  remove_control_from_docks(space_dock)
  main_screen_changed.disconnect(_on_main_screen_changed)
  if is_instance_valid(space_dock):
    space_dock.queue_free()

# setup global parameters and connect to device
func _ready():
  # until https://github.com/godotengine/godot-proposals/issues/2081 is fixed
  # we force a main screen change, so that we can track the current main screen
  EditorInterface.set_main_screen_editor("3D")
  spherical = Spherical.new()
  #EditorInterface.get_editor_viewport_3d(idx).get_camera_3d()/
  #editor = get_editor_interface()
  #var viewport = editor.get_editor_viewport_3d()
  ## find all the editor cameras available
  #var cameras = find_camera(viewport, [])
  #if cameras.size() > 0:
    ## sets the camera to the first one
    #camera = cameras[camera_index]
  # get access to object selections
  #selection = editor.get_selection()
  # connect to the space mouse device
  connected = device.connect()

# main update process to adjust the viewport camera
func _process(delta):
  if !connected or EditorInterface.is_playing_scene(): return
  if current_main_screen != "3D":
    # todo: also support 2D ?
    return

  if not device.get_modified():
    return

  # todo: support active viewport somehow?
  var vp := EditorInterface.get_editor_viewport_3d(0)
  var camera := vp.get_camera_3d()
  if camera.projection != Camera3D.PROJECTION_PERSPECTIVE:
    # todo: handle non perspective camera
    return

  # obtain the raw translation and rotation values from the device
  var space_translation:Vector3 = device.translation()
  var space_rotation:Vector3 = device.rotation()

  var select_origin := Vector3.ZERO
  var selection:EditorSelection = EditorInterface.get_selection()
  var selected = selection.get_top_selected_nodes()
  if selected.size() > 0 and selected[0] is Node3D:
    select_origin = selected[0].global_position

  var position:Vector3 = camera.global_position
  var offset := position - select_origin

  spherical.set_from_vector(offset)
  spherical.theta -= space_rotation.y * rotate_speed * delta
  spherical.phi -= space_rotation.x * rotate_speed * delta
  spherical.radius -= space_translation.z * translate_speed * delta
  spherical.make_safe()

  offset = spherical.apply_to_vector(offset)
  position = select_origin + offset
  camera.look_at_from_position(position, select_origin, Vector3.UP)

  return

  var camera_transform = camera.transform
  var camera_origin = camera_transform.origin
  camera_transform.origin = Vector3.ZERO

  # orbit around selected object
  if control_type == ControlType.OBJECT_TYPE:
    # make translation slower the closer you get to the pivot point
    var offset_speed := (select_origin.distance_to(camera_origin) / 8.0) + 0.01
    offset_speed = clamp(offset_speed, 0.01, 8.0)

    # transform translation into camera local space
    space_translation = camera_transform * space_translation
    # adjust the raw readings into reasonable speeds and apply delta
    space_translation *= translate_speed * offset_speed * delta;
    space_rotation *= rotate_speed * delta
    # move the camera by the latest translation but remove the offset from the pivot
    camera_transform.origin += space_translation + camera_origin - select_origin
    # rotate the camera by the latest rotation as normal
    camera_transform = camera_transform.rotated(camera_transform.basis.x.normalized(), space_rotation.x)
    camera_transform = camera_transform.rotated(camera_transform.basis.y.normalized(), space_rotation.y)
    camera_transform = camera_transform.rotated(camera_transform.basis.z.normalized(), space_rotation.z)
    # adjust the camera back to the real location from the pivot point
    camera_transform.origin += select_origin

  # camera control type
  elif control_type == ControlType.CAMERA_TYPE:
    # adjust the raw readings into reasonable speeds and apply delta
    space_translation *= translate_speed * adjust_translation * delta;
    space_rotation *= rotate_speed * adjust_rotation * delta
    # rotate the camera in place
    camera_transform = camera_transform.rotated(camera_transform.basis.x.normalized(), -space_rotation.x)
    camera_transform = camera_transform.rotated(camera_transform.basis.y.normalized(), -space_rotation.y)
    camera_transform = camera_transform.rotated(camera_transform.basis.z.normalized(), -space_rotation.z)
    # transform translation into camera local space
    space_translation = camera_transform * space_translation
    # move the camera back to the original position
    camera_transform.origin = camera_origin - space_translation
    # apply the updated temporary transform to the actual viewport camera
  camera.transform = camera_transform

#-----------------------------------------------------------
class Spherical:
  var radius: float
  var phi: float
  var theta: float

  func _init(_radius: float = 1, _phi: float = 0, _theta: float = 0):
    radius = _radius
    phi = _phi
    theta = _theta

  func set_to(_radius: float, _phi: float, _theta: float):
    radius = _radius
    phi = _phi
    theta = _theta

  #func copy(_other_spherical: Spherical):
    #radius = _other_spherical._radius
    #phi = _other_spherical._phi
    #theta = _other_spherical._theta

  func make_safe() -> void:
    var precision: float = 0.0000000000001
    phi = max(precision, min(PI - precision, phi))

  func set_from_vector(v: Vector3):
    self.set_from_cartesian_coords(v.x, v.y, v.z)

  func dampen(damping_factor:float) ->bool:
    theta *= (1 - damping_factor)
    phi *= (1 - damping_factor)
    if abs(theta) < 0.001:
      theta = 0.0
    if abs(phi) < 0.001:
      phi = 0.0
    if theta == 0 and phi == 0:
      radius = 0
    return abs(theta) > 0 or abs(phi) > 0

  func set_from_cartesian_coords(x: float, y: float, z: float):
    radius = sqrt(x * x + y * y + z * z)
    if radius == 0:
      theta = 0
      phi = 0
    else:
      theta = atan2(x, z)
      phi = acos(clamp(y / radius, -1, 1))

  func apply_to_vector(vector: Vector3) -> Vector3:
    var sin_phi_radius = sin(phi) * radius

    vector.x = sin_phi_radius * sin(theta)
    vector.y = cos(phi) * radius
    vector.z = sin_phi_radius * cos(theta)
    return vector

class_name SpatialAudioPlayer3D extends AudioStreamPlayer3D

#-------GOALS--------------------------------------
#create audio bus for every instantiated SpatialAudioPlayer

#use raycast queries instead of nodes

#lerp target values every frame for dynamic effect
#-------------------------------------------------


var audioBus = null 
var busIndex = null
var _reverb_effect : AudioEffectReverb
var _lowpass_effect : AudioEffectLowPassFilter

var _target_reverb_room_size : float = 0.0
var _target_reverb_wetness : float = 0.0

var _target_lowpass : float = 0.0 #default lowpass is 2000
var _MAX_LOWPASS_CUTOFF : float = 2000.0

const DIRECTION_COUNT = 8
var directions = []

@export var length = 25
@export var _MAX_WETNESS : float = 0.5

func create_bus_name(index: int) -> StringName:
	return "Spatial Audio Player " + str(index)


func get_ray_distance(space_state : PhysicsDirectSpaceState3D, query : PhysicsRayQueryParameters3D) -> float: 
	var res = space_state.intersect_ray(query)
	if res:
		#print(res.collider.name)
		return query.from.distance_to(res.position)
	else:
		return -1 #defaulting to this 

func _on_update_reverb(distances : Array) -> void:
	if _reverb_effect:
		var room_size = 0.0
		var wetness = 1.0
		for dist in distances:
			if dist >= 0:
				room_size += (dist / length) / (float(distances.size()))
				room_size = min(room_size, 1.0)
			else:
				wetness -= 1.0 / float(distances.size()) #subtract 1/8th per ray missed
				wetness = max(wetness, 0.0)
		#wetness = min(wetness, _MAX_WETNESS)
		_target_reverb_room_size = room_size
		_target_reverb_wetness = wetness * _MAX_WETNESS #reduce so it isnt as harsh

func _on_update_lowpass(space_state : PhysicsDirectSpaceState3D ,origin ,_player: Node3D):
	if _lowpass_effect != null:
		var query = PhysicsRayQueryParameters3D.create(origin, _player.global_position, 1 << 0)
		var res = space_state.intersect_ray(query)
		if res and res.collider != _player:
			#filter audio
			var ray_distance = self.global_position.distance_to(res.position)
			var distance_to_player = self.global_position.distance_to(_player.global_position)
			var wall_to_player_ratio = ray_distance/max(distance_to_player, 0.001) #closer you are to wall the less sound is muffled
			_target_lowpass = 2000 * wall_to_player_ratio
		else:
			#dont filter audio
			_target_lowpass = _MAX_LOWPASS_CUTOFF

func sample_environment(_player : Node3D) -> void:
	var origin = global_transform.origin
	directions[0] = -basis.z
	directions[1] = basis.z
	directions[2] = basis.x
	directions[3] = -basis.x
	directions[4] = (-basis.z + basis.x).normalized()
	directions[5] = (-basis.z + -basis.x).normalized()
	directions[6] = (basis.z + basis.x).normalized()
	directions[7] = (basis.z + -basis.x).normalized()
	
	var distances = []
	var space_state = get_world_3d().direct_space_state
	
	for dir in directions:
		#create ray
		var end_point = origin + dir * length
		var query = PhysicsRayQueryParameters3D.create(origin, end_point, 1 << 0)
		var distance = get_ray_distance(space_state, query)
		distances.append(distance)
	
	_on_update_lowpass(space_state,origin, _player)
	_on_update_reverb(distances)

func lerp_targets(delta):
	_reverb_effect.wet = lerp(_reverb_effect.wet, _target_reverb_wetness, delta * 5)
	_reverb_effect.room_size = lerp(_reverb_effect.room_size, _target_reverb_room_size, delta * 5)
	_lowpass_effect.cutoff_hz = lerp(_lowpass_effect.cutoff_hz, _target_lowpass, delta * 10)
	print("WET: " + str(_reverb_effect.wet))
	print("ROOM: " + str(_reverb_effect.room_size))
	print("LOW PASS: " + str(_lowpass_effect.cutoff_hz))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	directions.resize(DIRECTION_COUNT)
	busIndex = AudioServer.get_bus_count()
	AudioServer.add_bus(busIndex)
	AudioServer.set_bus_name(busIndex, create_bus_name(busIndex))
	self.bus = AudioServer.get_bus_name(busIndex)
	print(AudioServer.get_bus_name(busIndex))
	AudioServer.add_bus_effect(busIndex, AudioEffectReverb.new())
	AudioServer.add_bus_effect(busIndex, AudioEffectLowPassFilter.new())
	_reverb_effect = AudioServer.get_bus_effect(busIndex, 0)
	_lowpass_effect = AudioServer.get_bus_effect(busIndex, 1)
	print(AudioServer.get_bus_effect_count(busIndex))


func _process(delta: float) -> void:
	lerp_targets(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var sampleRate = 0.3
var timer = 0.0
func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= sampleRate:
		timer = 0.0
		var player_camera = get_viewport().get_camera_3d()
		if player_camera:
			sample_environment(player_camera)
		

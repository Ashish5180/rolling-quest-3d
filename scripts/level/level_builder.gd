extends Node3D
## Builds the extended, high-intensity Level 01 track.
## Features multiple sections, dual ramps, mid-air ocean gaps, narrow bridges,
## dynamic sliders, rotating hazards, and 35 collectible coins.

# --- Track dimensions ---
const TRACK_W_NORMAL := 3.6    # Commercial track width (3.6m — true edge danger)
const TRACK_W_NARROW := 2.2    # Precision narrow bridge width (2.2m)
const PLAT_THICK := 1.0        # Platform vertical thickness

# --- Ramp config ---
const RAMP_LENGTH := 10.0
const RAMP_ANGLE_DEG := 18.0

# --- Preloaded scenes & textures ---
var _coin_scene: PackedScene = preload("res://scenes/collectibles/coin.tscn")
var _moving_obstacle_scene: PackedScene = preload("res://scenes/obstacles/moving_obstacle.tscn")
var _rotating_bar_scene: PackedScene = preload("res://scenes/obstacles/rotating_bar.tscn")
var _crate_obstacle_scene: PackedScene = preload("res://scenes/obstacles/crate_obstacle.tscn")
var _swinging_hammer_scene: PackedScene = preload("res://scenes/obstacles/swinging_hammer.tscn")
var _boost_pad_scene: PackedScene = preload("res://scenes/track/boost_pad.tscn")
var _bounce_bumper_scene: PackedScene = preload("res://scenes/obstacles/bounce_bumper.tscn")
var _wind_zone_scene: PackedScene = preload("res://scenes/obstacles/wind_zone.tscn")
var _piston_pusher_scene: PackedScene = preload("res://scenes/obstacles/piston_pusher.tscn")
var _sweeper_wiper_scene: PackedScene = preload("res://scenes/obstacles/sweeper_wiper.tscn")

var _tex_track: Texture2D = preload("res://assets/textures/track_wood.png")
var _tex_checkered: Texture2D = preload("res://assets/textures/finish_checkered.png")

# --- Shared Materials ---
var _mat_track: StandardMaterial3D
var _mat_ramp: StandardMaterial3D
var _mat_finish: StandardMaterial3D


func _ready() -> void:
	GameManager.total_coins = 35
	_create_materials()
	_build_track()
	_spawn_obstacles()
	_spawn_coins()


func _create_materials() -> void:
	_mat_track = StandardMaterial3D.new()
	_mat_track.albedo_texture = _tex_track
	_mat_track.uv1_scale = Vector3(1.0, 6.0, 1.0)
	_mat_track.roughness = 0.55

	_mat_ramp = StandardMaterial3D.new()
	_mat_ramp.albedo_color = Color(0.12, 0.88, 0.48)
	_mat_ramp.emission_enabled = true
	_mat_ramp.emission = Color(0.1, 0.7, 0.3)
	_mat_ramp.emission_energy_multiplier = 0.35
	_mat_ramp.roughness = 0.35
	_mat_ramp.metallic = 0.2

	_mat_finish = StandardMaterial3D.new()
	_mat_finish.albedo_color = Color(1.0, 0.85, 0.1)
	_mat_finish.metallic = 0.6
	_mat_finish.roughness = 0.2
	_mat_finish.emission_enabled = true
	_mat_finish.emission = Color(1.0, 0.8, 0.1)
	_mat_finish.emission_energy_multiplier = 0.4


func _build_track() -> void:
	# =========================================================================
	# SECTION 1: Ocean Start Runway (z = 0 to -35)
	# =========================================================================
	_add_platform(Vector3(0, -0.5, -17.5), Vector3(TRACK_W_NORMAL, PLAT_THICK, 35), _mat_track)

	# =========================================================================
	# LAUNCH RAMP #1 & GAP 1 (starts at z = -35, launches over open ocean)
	# Ramp ends at z ≈ -44.5. Gap spans to z = -53.5 (~9m gap)
	# =========================================================================
	_add_ramp(-35.0)

	# =========================================================================
	# SECTION 2: Island Terrace (z = -53.5 to -105)
	# =========================================================================
	var s2_len := 105.0 - 53.5
	var s2_center_z := -(53.5 + 105.0) / 2.0
	_add_platform(Vector3(0, -0.5, s2_center_z), Vector3(TRACK_W_NORMAL, PLAT_THICK, s2_len), _mat_track)

	# =========================================================================
	# LAUNCH RAMP #2 & GAP 2 (starts at z = -105, launches over deep canyon)
	# Ramp ends at z ≈ -114.5. Gap spans to z = -123.5 (~9m gap)
	# =========================================================================
	_add_ramp(-105.0)

	# =========================================================================
	# SECTION 3: The Narrow Ridge (z = -123.5 to -165)
	# Narrower 4.8m platform over the ocean requiring precise balance
	# =========================================================================
	var s3_len := 165.0 - 123.5
	var s3_center_z := -(123.5 + 165.0) / 2.0
	_add_platform(Vector3(0, -0.5, s3_center_z), Vector3(TRACK_W_NARROW, PLAT_THICK, s3_len), _mat_track)

	# =========================================================================
	# SECTION 4: The Grand Speedway & Finish (z = -165 to -235)
	# Long high-speed final stretch with obstacle gauntlet and finish gate
	# =========================================================================
	var s4_len := 235.0 - 165.0
	var s4_center_z := -(165.0 + 235.0) / 2.0
	_add_platform(Vector3(0, -0.5, s4_center_z), Vector3(TRACK_W_NORMAL, PLAT_THICK, s4_len), _mat_track)

	# =========================================================================
	# FINISH GATE at z = -228
	# =========================================================================
	_add_finish_gate(Vector3(0, 0, -228))

	# =========================================================================
	# FALL ZONE (Spans entire 240m course, triggers quick game-over on splash)
	# =========================================================================
	_add_fall_zone()


# --- Platform: StaticBody3D with box mesh + collision ---
func _add_platform(center: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.position = center
	body.name = "Platform"
	var phys := PhysicsMaterial.new()
	phys.friction = 1.0
	body.physics_material_override = phys
	add_child(body)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	body.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)


# --- Ramp: Rotated box aligned so top surface starts flush at (0, 0, start_z) ---
func _add_ramp(start_z: float) -> void:
	var angle := deg_to_rad(RAMP_ANGLE_DEG)
	var half_len := RAMP_LENGTH / 2.0
	var half_thick := PLAT_THICK / 2.0

	var center_y := half_len * sin(angle) - half_thick * cos(angle)
	var center_z := start_z - half_len * cos(angle) - half_thick * sin(angle)

	var body := StaticBody3D.new()
	body.position = Vector3(0, center_y, center_z)
	body.rotation.x = angle
	body.name = "Ramp"
	var phys := PhysicsMaterial.new()
	phys.friction = 0.95
	body.physics_material_override = phys
	add_child(body)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(TRACK_W_NORMAL, PLAT_THICK, RAMP_LENGTH)
	mi.mesh = bm
	mi.set_surface_override_material(0, _mat_ramp)
	body.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TRACK_W_NORMAL, PLAT_THICK, RAMP_LENGTH)
	col.shape = shape
	body.add_child(col)


# --- Finish gate: Area3D arch trigger ---
func _add_finish_gate(pos: Vector3) -> void:
	var area := Area3D.new()
	area.position = pos
	area.name = "FinishLine"
	add_child(area)

	# Trigger box
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TRACK_W_NORMAL, 4, 0.5)
	col.shape = shape
	col.position.y = 2.0
	area.add_child(col)

	# Checkered finish mat
	var mat_checkered := StandardMaterial3D.new()
	mat_checkered.albedo_texture = _tex_checkered
	mat_checkered.uv1_scale = Vector3(6.0, 2.0, 1.0)
	var mi_mat := MeshInstance3D.new()
	var bm_mat := BoxMesh.new()
	bm_mat.size = Vector3(TRACK_W_NORMAL, 0.04, 3.0)
	mi_mat.mesh = bm_mat
	mi_mat.set_surface_override_material(0, mat_checkered)
	mi_mat.position = Vector3(0, 0.02, 0)
	area.add_child(mi_mat)

	# Visual pillars + crossbar
	_add_gate_pillar(area, Vector3(-TRACK_W_NORMAL / 2.0 + 0.2, 1.5, 0))
	_add_gate_pillar(area, Vector3(TRACK_W_NORMAL / 2.0 - 0.2, 1.5, 0))
	_add_gate_crossbar(area, Vector3(0, 3.2, 0))

	area.body_entered.connect(_on_finish_entered)


func _add_gate_pillar(parent: Node3D, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.2
	cyl.height = 3.0
	mi.mesh = cyl
	mi.position = pos
	mi.set_surface_override_material(0, _mat_finish)
	parent.add_child(mi)


func _add_gate_crossbar(parent: Node3D, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(TRACK_W_NORMAL - 0.2, 0.35, 0.35)
	mi.mesh = bm
	mi.position = pos
	mi.set_surface_override_material(0, _mat_finish)
	parent.add_child(mi)


# --- Fall zone: invisible Area3D covering entire 250m ocean trajectory ---
func _add_fall_zone() -> void:
	var area := Area3D.new()
	area.position = Vector3(0, -10, -115)
	area.name = "FallZone"
	add_child(area)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(500, 2, 500)
	col.shape = shape
	area.add_child(col)

	area.body_entered.connect(_on_fall_zone_entered)


# --- Realistic & Tricky Obstacle Placements ---
func _spawn_obstacles() -> void:
	# -------------------------------------------------------------------------
	# SECTION 1: Ocean Start Runway (z = 0 to -35, width 3.6m, edges at ±1.8)
	# -------------------------------------------------------------------------
	# Cargo crate on right
	_spawn_instance(_crate_obstacle_scene, Vector3(0.9, 0.65, -10.0))

	# Lethal Hydraulic Piston Slammer #1 — punches from left, pushing ball off right edge
	var p1 := _spawn_instance(_piston_pusher_scene, Vector3(-2.1, 0.0, -18.0))
	if p1:
		p1.push_from_left = true
		p1.stroke_distance = 2.6
		p1.punch_force = 22.0

	# Industrial hazard slider
	_spawn_instance(_moving_obstacle_scene, Vector3(0.0, 0.45, -24.0))

	# Neon Speed Boost Pad #1 — launches player toward Ramp #1
	_spawn_instance(_boost_pad_scene, Vector3(0.0, 0.0, -30.0))

	# -------------------------------------------------------------------------
	# SECTION 2: Island Terrace (z = -53.5 to -105, width 3.6m)
	# -------------------------------------------------------------------------
	# Giant swinging pendulum mallet #1
	_spawn_instance(_swinging_hammer_scene, Vector3(0.0, 0.0, -65.0))

	# Pinball bounce bumpers flanking the chicane entry
	_spawn_instance(_bounce_bumper_scene, Vector3(-1.1, 0.0, -71.0))
	_spawn_instance(_bounce_bumper_scene, Vector3(1.1, 0.0, -71.0))

	# Alternating Piston Slammer #2 (Left, pushes right)
	var p2 := _spawn_instance(_piston_pusher_scene, Vector3(-2.1, 0.0, -77.0))
	if p2:
		p2.push_from_left = true
		p2.stroke_distance = 2.6
		p2.punch_force = 22.0
		p2.cycle_offset = 0.0

	# Alternating Piston Slammer #3 (Right, punches inward to the left!)
	var p3 := _spawn_instance(_piston_pusher_scene, Vector3(2.1, 0.0, -85.0))
	if p3:
		p3.push_from_left = false
		p3.stroke_distance = 2.6
		p3.punch_force = 22.0
		p3.cycle_offset = 0.85

	# Tall 4-blade revolving hazard turnstile (clockwise)
	var turnstile1 := _spawn_instance(_rotating_bar_scene, Vector3(0.0, 0.0, -94.0))
	if turnstile1 and "rotation_speed" in turnstile1:
		turnstile1.rotation_speed = 1.9

	# Neon Speed Boost Pad #2 — launches player toward Ramp #2
	_spawn_instance(_boost_pad_scene, Vector3(0.0, 0.0, -100.5))

	# -------------------------------------------------------------------------
	# SECTION 3: The Narrow Ridge (z = -123.5 to -165, width 2.2m, edges at ±1.1)
	# -------------------------------------------------------------------------
	# Giant swinging mallet #2 over narrow ridge
	_spawn_instance(_swinging_hammer_scene, Vector3(0.0, 0.0, -135.0))

	# Dynamic Crosswind Zone pushing ball rightward while dodging mallet #2
	_spawn_instance(_wind_zone_scene, Vector3(0.0, 0.0, -142.0))

	# Oscillating Sweeper Wiper Bar — sweeps across the entire 2.2m narrow bridge!
	var wiper := _spawn_instance(_sweeper_wiper_scene, Vector3(-1.15, 0.0, -149.0))
	if wiper:
		wiper.sweep_speed = 2.4
		wiper.sweep_force = 22.0
		wiper.sweep_to_right = true

	# Tricky edge bounce bumper — penalizes over-steering
	_spawn_instance(_bounce_bumper_scene, Vector3(-0.55, 0.0, -157.0))

	# -------------------------------------------------------------------------
	# SECTION 4: The Grand Speedway & Finish (z = -165 to -235, width 3.6m)
	# -------------------------------------------------------------------------
	# Neon Speed Boost Pad #3 — rockets into the final stretch
	_spawn_instance(_boost_pad_scene, Vector3(0.0, 0.0, -168.0))

	# Rapid moving hazard slider
	_spawn_instance(_moving_obstacle_scene, Vector3(0.0, 0.45, -180.0))

	# Bumper pair flanking the track
	_spawn_instance(_bounce_bumper_scene, Vector3(-1.1, 0.0, -191.0))
	_spawn_instance(_bounce_bumper_scene, Vector3(1.1, 0.0, -191.0))

	# High-speed 4-blade turnstile (counter-clockwise)
	var turnstile2 := _spawn_instance(_rotating_bar_scene, Vector3(0.0, 0.0, -200.0))
	if turnstile2 and "rotation_speed" in turnstile2:
		turnstile2.rotation_speed = -2.5

	# Ambush Piston Slammer #4 — high-speed strike right before the finish!
	var p4 := _spawn_instance(_piston_pusher_scene, Vector3(-2.1, 0.0, -208.0))
	if p4:
		p4.push_from_left = true
		p4.stroke_distance = 2.6
		p4.punch_force = 24.0
		p4.time_retracted = 0.95

	# Double wooden crates right before finish
	_spawn_instance(_crate_obstacle_scene, Vector3(-0.9, 0.65, -215.0))
	_spawn_instance(_crate_obstacle_scene, Vector3(0.9, 0.65, -215.0))

	# Center bumper trick obstacle right between finish crates
	_spawn_instance(_bounce_bumper_scene, Vector3(0.0, 0.0, -219.0))


# --- 35 Coin Placements across all sections & mid-air arcs ---
func _spawn_coins() -> void:
	# Section 1 Runway (7 coins)
	for z_val in [-5.0, -8.0, -11.0, -14.0, -26.0, -29.0, -32.0]:
		_spawn_instance(_coin_scene, Vector3(0.0, 0.5, z_val))

	# Ramp #1 Mid-air Ocean Arc (3 coins)
	_spawn_instance(_coin_scene, Vector3(0.0, 2.9, -46.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 2.6, -48.5))
	_spawn_instance(_coin_scene, Vector3(0.0, 1.5, -51.0))

	# Section 2 Terrace (8 coins)
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -58.0))
	_spawn_instance(_coin_scene, Vector3(-0.8, 0.5, -64.0))
	_spawn_instance(_coin_scene, Vector3(0.8, 0.5, -67.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -78.0))
	_spawn_instance(_coin_scene, Vector3(-0.8, 0.5, -84.0))
	_spawn_instance(_coin_scene, Vector3(0.8, 0.5, -87.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -98.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -102.0))

	# Ramp #2 Mid-air Ocean Arc (3 coins)
	_spawn_instance(_coin_scene, Vector3(0.0, 2.9, -116.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 2.6, -118.5))
	_spawn_instance(_coin_scene, Vector3(0.0, 1.5, -121.0))

	# Section 3 Narrow Ridge (5 coins)
	for z_val in [-128.0, -133.0, -138.0, -153.0, -158.0]:
		_spawn_instance(_coin_scene, Vector3(0.0, 0.5, z_val))

	# Section 4 Grand Finale Stretch (9 coins)
	_spawn_instance(_coin_scene, Vector3(-0.9, 0.5, -170.0))
	_spawn_instance(_coin_scene, Vector3(0.9, 0.5, -174.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -190.0))
	_spawn_instance(_coin_scene, Vector3(-0.9, 0.5, -195.0))
	_spawn_instance(_coin_scene, Vector3(0.9, 0.5, -200.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -216.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -219.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -222.0))
	_spawn_instance(_coin_scene, Vector3(0.0, 0.5, -225.0))


func _spawn_instance(scene: PackedScene, pos: Vector3) -> Node3D:
	if not scene:
		return null
	var inst := scene.instantiate() as Node3D
	inst.position = pos
	add_child(inst)
	return inst


# --- Game loop trigger callbacks ---
func _on_finish_entered(body: Node3D) -> void:
	if body.name == "Ball":
		GameManager.trigger_level_complete()


func _on_fall_zone_entered(body: Node3D) -> void:
	if body.name == "Ball":
		GameManager.trigger_game_over()
		await get_tree().create_timer(2.5).timeout
		if not GameManager.is_playing:
			GameManager.restart(get_tree())

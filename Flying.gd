extends Spatial

# for 3D
onready var cameraL:Camera = $ViewportContainerL/ViewportL/CameraL
onready var cameraR:Camera = $ViewportContainerR/ViewportR/CameraR

onready var SCENE:Spatial = $SCENE
onready var CLOUDS:Spatial = $CLOUDS
onready var SKYE:Spatial = $SKYE
onready var MARSHAL:Spatial = $MARSHAL
onready var templates:Spatial = $Templates
onready var templateX:Spatial = $Templates/templateX
onready var templateBone:Spatial = $Templates/templateBone
onready var templateCloud:Spatial = $Templates/templateCloud
onready var boerderLeft:Spatial = $BorderLeft
onready var borderRight:Spatial = $BorderRight

onready var countSKYE:Button = $countSKYE
onready var countMARSHAL:Button = $countMARSHAL
onready var countTOTAL:Button = $countTOTAL
onready var levelText:Button = $levelText

onready var audioX:AudioStreamPlayer = $AudioX
onready var audioBone:AudioStreamPlayer = $AudioBone
onready var audioSKYE:AudioStreamPlayer = $AudioSKYE
onready var audioMARSHAL:AudioStreamPlayer = $AudioMARSHAL

var scrollSpeed:Vector3 = Vector3(0,0,6)

var positionSKYE:float = 0
var speedSKYE:float = 0
var angleSKYEx:float = 0
var angleSKYEy:float = 0
var angleSKYEz:float = 0

var positionMARSHAL:float = 0
var speedMARSHAL:float = 0
var angleMARSHALx:float = 0
var angleMARSHALy:float = 0
var angleMARSHALz:float = 0

var bonesCounter:int = 0
var levelThreshold:int = 100
var bonesSKYE:int = 0
var bonesMARSHAL:int = 0

var xObjects:Array = []
var bonesObjects:Array = []
var cloudObjects:Array = []

var currentRate:float
var popRate:float
var cloudRate: float
var boneChance:float
var levelTextDissapear:float = -1
var positionGenerator: FuncRef = null


# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = get_tree().get_root().connect("size_changed", self, "resize")
	randomize()
	templates.visible = false
	boerderLeft.visible = false
	borderRight.visible = false
	SKYE.visible = true
	MARSHAL.visible = true
	apply_material_color($Templates/templateBone/Bone, 0x909030FF)
	apply_material_color($Templates/templateCloud/Cube, 0xAAAAFFFF)
	# add some clouds
	for i in range(1, 55, 8):
		createCloud(i)
	set_process_input(true)
	updateText()
	reset()
	resize()

func reset():
	scrollSpeed = Vector3(0,0,6)
	level1()
	positionSKYE = 1
	positionMARSHAL = -1
	bonesCounter = 0
	bonesSKYE = 0
	bonesMARSHAL = 0
	bonesCounter = 0
	bonesObjects.clear()
	xObjects.clear()
	delete_children(SCENE)
	updateText()

func updateText():
	countSKYE.text = "SKYE: " + str(bonesSKYE)
	countMARSHAL.text = "MARSHAL: " + str(bonesMARSHAL)
	countTOTAL.text = "TOTAL: " + str(bonesCounter)

func level1():
	boneChance = 0.1
	popRate = 1.0
	setLevelText("LEVEL 1")
	positionGenerator = funcref(self, "fiveByTwo")

func level2():
	boneChance = 0.2
	popRate = 0.8
	setLevelText("LEVEL 2")
	positionGenerator = funcref(self, "randomIntPos")

func level3():
	boneChance = 0.2
	popRate = 0.4
	setLevelText("LEVEL 3")
	positionGenerator = funcref(self, "randomFloatPos")

var lastLevel:int = -1
func setLevel(level:int):
	if lastLevel == level : return
	setLevelText("LEVEL " + str(level+1))
	lastLevel = level
	if level == 0:
		level1()
		return
	# increase the speed
	scrollSpeed += Vector3(0,0,0.1)
	#increase pop rate
	popRate *= 0.9
	#increase bomb rate
	boneChance +=0.1
	#switch variation
	var variation: int = level % 3
	if   variation == 0: positionGenerator = funcref(self, "fiveByTwo")
	elif variation == 1: positionGenerator = funcref(self, "randomIntPos")
	elif variation == 2: positionGenerator = funcref(self, "randomFloatPos")

var fiveByTwoCounter = 0
func fiveByTwo():
	var rem: int = int(fiveByTwoCounter / 5)
	var result: float
	if rem % 2 == 1: result = -2.0
	else:            result =  2.0
	fiveByTwoCounter += 1
	return result

func randomIntPos():
	return int(-4.5 + 9.0*randf())
	
func randomFloatPos():
	return -4.5 + 9.0*randf()

func _input(_ev):
	#skye movements
	if Input.is_action_pressed("skye_left"):
		angleSKYEz = -1
		speedSKYE = 3
	if Input.is_action_pressed("skye_right"):
		angleSKYEz = 1
		speedSKYE = -3
	if Input.is_action_pressed("skye_up"):
		angleSKYEz = 16
		speedSKYE = 0
	if Input.is_action_pressed("skye_down"):
		angleSKYEz = 16
		speedSKYE = 0
		
	#marshal movements
	if Input.is_action_pressed("marshal_left"):
		angleMARSHALz = -1
		speedMARSHAL = 3
	if Input.is_action_pressed("marshal_right"):
		angleMARSHALz = 1
		speedMARSHAL = -3
	if Input.is_action_pressed("marshal_up"):
		angleMARSHALz = 16
		speedMARSHAL = 0
	if Input.is_action_pressed("marshal_down"):
		angleMARSHALz = 16
		speedMARSHAL = 0

	if Input.is_action_just_pressed("sky_toggle"):
		SKYE.visible = not SKYE.visible
		if SKYE.visible : audioSKYE.play()
	elif Input.is_action_just_pressed("marshal_toggle"):
		MARSHAL.visible = not MARSHAL.visible
		if MARSHAL.visible : audioMARSHAL.play()
	elif Input.is_action_just_pressed("3d_toggle"):
		OS.window_fullscreen = not OS.window_fullscreen
		if OS.window_fullscreen:
			cameraL.translate(Vector3(-0.16,0,0))
			cameraR.translate(Vector3( 0.16,0,0))
		else:
			cameraL.translate(Vector3(0.16,0,0))
			cameraR.translate(Vector3(-0.16,0,0))
		resize()
		
	if Input.is_key_pressed(KEY_3):
		level1()
	if Input.is_key_pressed(KEY_4):
		level2()
	if Input.is_key_pressed(KEY_5):
		level3()
	if Input.is_key_pressed(KEY_R):
		reset()
	if Input.is_key_pressed(KEY_EQUAL):
		scrollSpeed += Vector3(0,0,0.1)
	if Input.is_key_pressed(KEY_MINUS):
		if scrollSpeed.z > 2:
			scrollSpeed -= Vector3(0,0,0.1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	movementAndInertial(delta)
	generateObjects(delta)
	scrollObjects(delta)
	hideLevel(delta)
	
	checkColisions()
	
	# clean up invisible objects
	cleanupInvisibleObjects(bonesObjects, -8.0)
	cleanupInvisibleObjects(xObjects, -8.0)
	cleanupInvisibleObjects(cloudObjects, -8.0)
	
	# shift levels
	if bonesCounter > 0 and bonesCounter % levelThreshold == 0:
		# integer division is intentional
# warning-ignore:integer_division
		setLevel(bonesCounter / levelThreshold )
	# if bonesCounter == 100: level2()
	# if bonesCounter == 200: level3()
	# if bonesCounter == 300: level1() scrollSpeed += Vector3(0,0,0.1)
	
func movementAndInertial(delta):
	# flaten the object when inactive fast and slow
	if(angleSKYEx > 1): angleSKYEx -= sign(angleSKYEx) * 20 * delta
	else: angleSKYEx -= sign(angleSKYEx) * 2 * delta
	if(angleSKYEy > 1): angleSKYEy -= sign(angleSKYEy) * 20 * delta
	else: angleSKYEy -= sign(angleSKYEy) * 2 * delta
	if(angleSKYEz > 1): angleSKYEz -= sign(angleSKYEz) * 20 * delta
	else: angleSKYEz -= sign(angleSKYEz) * 2 * delta
	if(angleMARSHALx > 1): angleMARSHALx -= sign(angleMARSHALx) * 20 * delta
	else: angleMARSHALx -= sign(angleMARSHALx) * 2 * delta
	if(angleMARSHALy > 1): angleMARSHALy -= sign(angleMARSHALy) * 20 * delta
	else: angleMARSHALy -= sign(angleMARSHALy) * 2 * delta
	if(angleMARSHALz > 1): angleMARSHALz -= sign(angleMARSHALz) * 20 * delta
	else: angleMARSHALz -= sign(angleMARSHALz) * 2 * delta

	# move inertially
	positionSKYE = clamp(positionSKYE + speedSKYE * delta, -4, 4)
	positionMARSHAL = clamp(positionMARSHAL + speedMARSHAL * delta, -4, 4)
	
	# slow down when inactive
	speedSKYE -= sign(speedSKYE) * 8 * delta
	speedMARSHAL -= sign(speedMARSHAL) * 8 * delta
	
	# flat position and anlgles
	if abs(speedSKYE) < 0.01: speedSKYE = 0
	if abs(angleSKYEx) < 0.01: angleSKYEx = 0
	if abs(angleSKYEy) < 0.01: angleSKYEy = 0
	if abs(angleSKYEz) < 0.01: angleSKYEz = 0
	if abs(speedMARSHAL) < 0.01: speedMARSHAL = 0
	if abs(angleMARSHALx) < 0.01: angleMARSHALx = 0
	if abs(angleMARSHALy) < 0.01: angleMARSHALy = 0
	if abs(angleMARSHALz) < 0.01: angleMARSHALz = 0
	
	#move SKYE
	SKYE.set_identity()
	SKYE.translate(Vector3(positionSKYE,0,0))
	SKYE.rotate_x(angleSKYEx)
	SKYE.rotate_y(angleSKYEy)
	SKYE.rotate_z(angleSKYEz)
	SKYE.force_update_transform()
	
	#move SKYE
	MARSHAL.set_identity()
	MARSHAL.translate(Vector3(positionMARSHAL,0,0))
	MARSHAL.rotate_x(angleMARSHALx)
	MARSHAL.rotate_y(angleMARSHALy)
	MARSHAL.rotate_z(angleMARSHALz)
	MARSHAL.force_update_transform()

func setLevelText(s:String):
	levelText.text = s
	levelTextDissapear = 3

func hideLevel(delta):
	if levelTextDissapear > 0:
		levelTextDissapear -= delta
		var rem = fmod(3*levelTextDissapear,1)
		var color = Color(1, rem, rem)
		levelText.add_color_override("font_color", color)
		if levelTextDissapear < 0:
			levelText.text = ""

func checkColisions():
	# check bone
	for ix in range(bonesObjects.size()-1, -1, -1):
		var skyWin = hasColision(positionSKYE, bonesObjects[ix].translation) 
		var marshalWin = hasColision(positionMARSHAL, bonesObjects[ix].translation)
		#SKYE.visible
		if skyWin == skyWin or marshalWin == marshalWin:
			SCENE.remove_child(bonesObjects[ix])
			bonesObjects.remove(ix)
			bonesCounter += 1
			# play coin 
			audioBone.play()
			# using that NaN is false for all operations, except NaN != NaN
			if skyWin <= marshalWin or marshalWin != marshalWin: 
				bonesSKYE += 1
				angleSKYEx = 8
			if marshalWin < skyWin or skyWin != skyWin: 
				bonesMARSHAL += 1
				angleMARSHALx = 8
			updateText()
	
	# check bomb
	for ix in range(xObjects.size()-1, -1, -1):
		var skyLose = hasColision(positionSKYE, xObjects[ix].translation) 
		var marshalLose = hasColision(positionMARSHAL, xObjects[ix].translation)
		if skyLose == skyLose or marshalLose == marshalLose:
			SCENE.remove_child(xObjects[ix])
			xObjects.remove(ix)
			# play boom
			audioX.play()
			if skyLose < marshalLose or marshalLose != marshalLose:  
				bonesSKYE -= 10
				angleSKYEy = 8
			if marshalLose < skyLose or skyLose != skyLose:  
				bonesMARSHAL -= 10
				angleMARSHALy = 8
			updateText()
	
func generateObjects(delta):
	var obj = null
	currentRate += delta
	if currentRate > popRate:
		currentRate = 0
		if randf() > boneChance : 
			obj = templateBone.duplicate()
			bonesObjects.push_front(obj)
		else: 
			obj = templateX.duplicate()
			xObjects.push_front(obj)
	
	if obj != null:
		var x:float = positionGenerator.call_func()
		obj.translation = Vector3(x,0,30)
		obj.visible = true
		SCENE.add_child(obj)
	
	#add clouds
	cloudRate += delta
	if cloudRate > 2.7:
		cloudRate = 0
		createCloud(60)

func scrollObjects(delta):
	# scroll objects
	var scroll:Vector3 = - delta * scrollSpeed
	for obj in bonesObjects:
		obj.translation += scroll
	for obj in xObjects:
		obj.translation += scroll
	for obj in cloudObjects:
		obj.translation += scroll

func hasColision(dogPosition:float, obj: Vector3):
	if (obj.z > 0 and obj.z < 1 ):
		var absDist:float = abs(dogPosition - obj.x)
		if absDist < 1.1: return absDist
	return NAN

func createCloud(z:float):
		var cloud = templateCloud.duplicate()
		var angle = randf() * PI
		var x = cos(angle) * 10
		var y = sin(angle) * -10
		cloud.translation = Vector3(x,y,z)
		cloud.scale = Vector3( 0.5 + randf()/2.0,  0.5 + randf()/2.0, 1)
		cloud.visible = true
		cloudObjects.push_front(cloud)
		CLOUDS.add_child(cloud)

func cleanupInvisibleObjects(objects: Array, z:float):
	while objects.size() > 0:
		var obj = objects.pop_back()
		if obj.translation.z > z:
			objects.push_back(obj)
			break

func apply_material_color(mesh_instance_node:MeshInstance,  color:int):
	var material = SpatialMaterial.new()
	material.albedo_color = Color(color)
	mesh_instance_node.set_material_override(material)

func resize():
	var viewport = get_tree().get_root()
	var height = viewport.get_visible_rect().size.y
	var width = viewport.get_visible_rect().size.x
	var mid = int(width/2)
	
	var D3D:bool = OS.window_fullscreen
	if D3D:
		$ViewportContainerL.margin_left = 0
		$ViewportContainerL.margin_top = 0
		$ViewportContainerL.margin_bottom = int(height/2)
		$ViewportContainerL.margin_right = int(width/2)
		$ViewportContainerL.rect_scale = Vector2(1, 2)
		$ViewportContainerL/ViewportL.set_size_override(true, Vector2(width, height))
		$ViewportContainerR.margin_left = mid
		$ViewportContainerR.margin_top = 0
		$ViewportContainerR.margin_bottom = int(height/2)
		$ViewportContainerR.margin_right = width
		$ViewportContainerR.rect_scale = Vector2(1, 2)
		$ViewportContainerR/ViewportR.set_size_override(true, Vector2(width, height))
	else:
		$ViewportContainerL.margin_left = 0
		$ViewportContainerL.margin_top = 0
		$ViewportContainerL.margin_bottom = height
		$ViewportContainerL.margin_right = width
		$ViewportContainerL.rect_scale = Vector2(1.0, 1.0)
		$ViewportContainerL/ViewportL.set_size_override(true, Vector2(width, height) )
		$ViewportContainerR.margin_left = 0
		$ViewportContainerR.margin_top = 0
		$ViewportContainerR.margin_bottom = 0
		$ViewportContainerR.margin_right = 0
		$ViewportContainerR/ViewportR.set_size_override(true, Vector2(width, height) )

func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)

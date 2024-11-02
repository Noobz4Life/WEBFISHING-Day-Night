extends Node

const defaultSkyColor = Color("ffeed5")
const defaultRainColor = Color("#778688")

const nightColor = Color("222242")
const noonColor = Color("ffce86")
const morningColor = Color("d5fffb")

# Config stuffs
var syncToRealTime := true;
var timescale := 60;
var twelveHourClock := true;

var hostSync := false;
var hostTimescale := 1;

var curTime:float = 79200.0;
var worldenv:WorldEnvironment;

var inRain = false;

#const gradient_data := {
#	0.1: nightColor,
#	0.25: noonColor,
#	0.4: defaultSkyColor,
#	0.6: defaultSkyColor,
#	0.75: noonColor,
#	0.9: nightColor
#}

const timeDivisor = 86400.0

var startOfMorningTime     = 21600.0/timeDivisor # 6 am
var endOfMorningTime       = 32400.0/timeDivisor # 9 am
var startOfAfternoonTime   = 46800.0/timeDivisor # 1 pm
var endOfAfternoonTime     = 61200.0/timeDivisor # 5 pm
var startOfNightTime       = 72000.0/timeDivisor # 8 pm
var startOfDarkerNightTime = 79200.0/timeDivisor # 10 pm

var default_gradient_data = {
	0.0: nightColor, # 12 AM
	(startOfMorningTime): nightColor, # 6 AM
	(endOfMorningTime): morningColor, # 9 AM
	(startOfAfternoonTime): defaultSkyColor, # 1 PM
	(endOfAfternoonTime): defaultSkyColor, # 5 PM
	(startOfNightTime): noonColor, # 8 PM
	(startOfDarkerNightTime): nightColor, # 10 PM
	1.0: nightColor, # 12 AM
}

var temp_darker_night_gradient_data = {
	0.0: Color("0c0c2d"), # 12 AM
	(startOfMorningTime): Color("0c0c2d"), # 6 AM
	(endOfMorningTime): morningColor, # 9 AM
	(startOfAfternoonTime): defaultSkyColor, # 1 PM
	(endOfAfternoonTime): defaultSkyColor, # 5 PM
	(startOfNightTime): noonColor, # 8 PM
	(startOfDarkerNightTime): Color("0c0c2d"), # 10 PM
	1.0: Color("0c0c2d"), # 12 AM
}
var tempDarkerNight = true;

#const default_gradient_data := {
#	0.0: nightColor, # 12 AM
#	21600.0: nightColor, # 6 AM
#	32400.0: morningColor, # 9 AM
#	46800.0: defaultSkyColor, # 1 PM
#	61200.0: defaultSkyColor, # 5 PM
#	72000.0: noonColor, # 8 PM
#	79200.0: nightColor, # 10 PM
#	1.0: nightColor, # 12 AM
#}

#var gradient_data:Dictionary = default_gradient_data

var timezoneBias:int;

export var gradient:Gradient = null;

var hudTime:Control;

# Called when the node enters the scene tree for the first time.
func _ready():
	print("test")
	print(Time.get_unix_time_from_datetime_string("06:00:00"))
	_create_gradient(default_gradient_data)
		
	timezoneBias = Time.get_time_zone_from_system().bias
	
	Network.connect("_user_connected", self, "_send_rpc_sync")
	Network.connect("_user_disconnected", self, "_send_rpc_sync")
	Network.connect("_instance_actor", self, "_send_rpc_sync")
	Network.connect("_handshake_recieved", self, "_send_rpc_sync")
	Network.connect("_new_player_join_empty", self, "_send_rpc_sync")
	Network.connect("_chat_update", self, "_send_rpc_sync")
	
	print(startOfMorningTime)
	print(temp_darker_night_gradient_data)
	_load_config()
	_save_config()
	print(startOfMorningTime)
	print(temp_darker_night_gradient_data)
	
	pass # Replace with function body.

func _create_gradient(gradient_data:Dictionary = default_gradient_data):
	gradient = Gradient.new();
	gradient.offsets = gradient_data.keys()
	gradient.colors = gradient_data.values()
		
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR

func _get_config_location():
	var exePath = OS.get_executable_path().get_base_dir()
	var path = exePath.plus_file("GDWeave").plus_file("configs").plus_file("nubz4lif.daynightcycle.json")
	
	var dir = Directory.new()
	dir.open(exePath)
	dir.make_dir_recursive(path.get_base_dir())
	
	return path

func _save_config():
	var path = _get_config_location()
	var data = {
		"syncToRealTime": syncToRealTime,
		"timescale": timescale,
		"twelveHourClock": twelveHourClock,
		"darkerNight": tempDarkerNight,
		
		# undo time divisor 
		"startOfMorningTime": Time.get_time_string_from_unix_time(startOfMorningTime*timeDivisor),
		"endOfMorningTime": Time.get_time_string_from_unix_time(endOfMorningTime*timeDivisor),
		"startOfAfternoonTime": Time.get_time_string_from_unix_time(startOfAfternoonTime*timeDivisor),
		"endOfAfternoonTime": Time.get_time_string_from_unix_time(endOfAfternoonTime*timeDivisor),
		"startOfNightTime": Time.get_time_string_from_unix_time(startOfNightTime*timeDivisor),
		"startOfDarkerNightTime": Time.get_time_string_from_unix_time(startOfDarkerNightTime*timeDivisor)
	}
	var json := JSON.print(data)
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(json)
	file.close()
	
	pass
	
func _load_config():
	var path = _get_config_location()
	
	var file = File.new()
	file.open(path, File.READ)
	var data = file.get_as_text()
	file.close()
	
	var p = JSON.parse(data)
	if typeof(p.result) == TYPE_DICTIONARY:
		if p.result.has('syncToRealTime'):
			syncToRealTime = bool(p.result['syncToRealTime'])
		
		if p.result.has('twelveHourClock'):
			twelveHourClock = bool(p.result['twelveHourClock'])
		
		if p.result.has('timescale'):
			timescale = abs(int(p.result['timescale']))
			
		if p.result.has('darkerNight'):
			tempDarkerNight = bool(p.result['darkerNight'])
			if tempDarkerNight:
				_create_gradient(temp_darker_night_gradient_data)
		
		if p.result.has("startOfMorningTime"):
			startOfMorningTime = setNewTime(str(p.result["startOfMorningTime"]))
		
		if p.result.has("endOfMorningTime"):
			endOfMorningTime = setNewTime(str(p.result["endOfMorningTime"]))
		
		if p.result.has("startOfAfternoonTime"):
			startOfAfternoonTime = setNewTime(str(p.result["startOfAfternoonTime"]))
		
		if p.result.has("endOfAfternoonTime"):
			endOfAfternoonTime = setNewTime(str(p.result["endOfAfternoonTime"]))
		
		if p.result.has("startOfNightTime"):
			startOfNightTime = setNewTime(str(p.result["startOfMorningTime"]))
		
		if p.result.has("startOfDarkerNightTime"):
			startOfDarkerNightTime = setNewTime(str(p.result["startOfDarkerNightTime"]))
	
	_create_gradient_data()

func setNewTime(time: String) -> float:
	var unixTime = Time.get_unix_time_from_datetime_string(time)
	return unixTime/timeDivisor

# (re)creates the 2 gradients from the given times
func _create_gradient_data():
	default_gradient_data = {}
	temp_darker_night_gradient_data = {}
	default_gradient_data = {
		0.0: nightColor, # 12 AM
		(startOfMorningTime): nightColor, # 6 AM
		(endOfMorningTime): morningColor, # 9 AM
		(startOfAfternoonTime): defaultSkyColor, # 1 PM
		(endOfAfternoonTime): defaultSkyColor, # 5 PM
		(startOfNightTime): noonColor, # 8 PM
		(startOfDarkerNightTime): nightColor, # 10 PM
		1.0: nightColor, # 12 AM
	}
	temp_darker_night_gradient_data = {
		0.0: Color("0c0c2d"), # 12 AM
		(startOfMorningTime): Color("0c0c2d"), # 6 AM
		(endOfMorningTime): morningColor, # 9 AM
		(startOfAfternoonTime): defaultSkyColor, # 1 PM
		(endOfAfternoonTime): defaultSkyColor, # 5 PM
		(startOfNightTime): noonColor, # 8 PM
		(startOfDarkerNightTime): Color("0c0c2d"), # 10 PM
		1.0: Color("0c0c2d"), # 12 AM
	}
	print("gradient data generated !")

func _send_rpc_sync():
	if Network.PLAYING_OFFLINE || not Network.GAME_MASTER: return 
	
	print("attempting to send rpc")
	if Network.GAME_MASTER:
		var data = {"type": "daynightcycle-sync", "curTime": curTime,  "timescale": timescale}
		
		if syncToRealTime: data['timescale'] = 1
		
		Network._send_P2P_Packet(data, "all", 3, 7)
		
		print("sent curtime rpc!!")

func _read_rpc_sync():
	if Network.PLAYING_OFFLINE || Network.GAME_MASTER || Network.STEAM_LOBBY_ID == 0: return 
	
	var PACKET_SIZE = Steam.getAvailableP2PPacketSize(7)
	if PACKET_SIZE > 0:
		var PACKET = Steam.readP2PPacket(PACKET_SIZE, 7)
		
		if PACKET.empty():
			print("Error! Empty Packet!")
		
		var DATA = bytes2var(PACKET.data.decompress_dynamic( - 1, File.COMPRESSION_GZIP))
		
		if typeof(DATA) == TYPE_DICTIONARY:
			var type = DATA["type"]
			
			if type == "daynightcycle-sync":
				if DATA.has('curTime'): curTime = int(DATA['curTime']);
				if DATA.has('timescale'): hostTimescale = int(DATA['timescale']);
				
				print("received curtime rpc!!")
				
				hostSync = true;

func _physics_process(delta):	
	if gradient == null:
		return
		
	_read_rpc_sync()
	if !hostSync || (Network.PLAYING_OFFLINE || Network.GAME_MASTER || Network.STEAM_LOBBY_ID == 0):
		if syncToRealTime:
			curTime = Time.get_unix_time_from_system();
			
			if timezoneBias != 0:
				if timezoneBias == null:
					timezoneBias = Time.get_time_zone_from_system().bias
					print(timezoneBias)
				else:
					curTime += timezoneBias * 60
		elif timescale > 0:
			curTime += delta * timescale;
			
		hostSync = false;
	else:
		curTime += delta * hostTimescale
	
	# i dont wanna have to patch playerhud for this, so i do it this way instead
	# probably a better way to do this -me for all the code ive written for this
	if hudTime == null || !is_instance_valid(hudTime):
		var parent = get_tree().get_root().get_node_or_null("./playerhud/main/in_game")
		if parent != null && is_instance_valid(parent):
			hudTime = load("res://mods/nubz4lif.daynightcycle/hud_time.tscn").instance()
			hudTime.name = "current_time"
			hudTime.mainDNC = self
			hudTime.anchor_left = 0.941
			hudTime.anchor_right = 0.997
			hudTime.anchor_top = 0.122
			hudTime.anchor_bottom = 0.166
			
			parent.add_child(hudTime)
	
	var instant = false;
	if worldenv == null || !is_instance_valid(worldenv):
		var world_viewport = get_tree().get_nodes_in_group("world_viewport")
		if world_viewport.empty(): return
		
		# There is probably a better way to do this, but this works
		var env = world_viewport[0].get_node_or_null("./main/map/main_map/WorldEnvironment")
		
		if env != null && is_instance_valid(env):
			worldenv = env
			instant = true;
		else:
			return
	
	curTime = fmod(curTime, 86400)
	
	#var point = abs((curTime / (86400/2)) - 1)
	var point = fmod(curTime, 86400) / 86400
	#print(point)
	
	var color = gradient.interpolate(point)
	
	# ill make a better implementation later, i promise!!
	if worldenv.rain:
		var grey = (color.r + color.b + color.g) / 3
		color = Color(grey,grey,grey).darkened(0.25)
		
	worldenv.des_color = color
	
	if instant:
		worldenv.environment.background_color = worldenv.des_color
		worldenv.environment.background_color = worldenv.des_color
		worldenv.environment.ambient_light_color = worldenv.des_color
		worldenv.environment.fog_color = worldenv.des_color

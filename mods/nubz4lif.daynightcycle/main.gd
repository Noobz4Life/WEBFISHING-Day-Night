extends Node

const defaultSkyColor = Color("ffeed5")
const defaultRainColor = Color("#778688")

const nightColor = Color("07071a")
const noonColor = Color("ffc165")

var syncToRealTime := true;
var timescale := 60;

var hostTimescale := 1;

var curTime:float = 86400 / 2;
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

const gradient_data := {
	0.0: nightColor,
	(21600.0/86400.0): nightColor, # 6 AM
	(32400.0/86400.0): noonColor, # 9 AM
	(46800.0/86400.0): defaultSkyColor, # 1 PM
	(61200.0/86400.0): defaultSkyColor, # 5 PM
	(75600.0/86400.0): noonColor, # 8 PM
	1.0: nightColor, # 10 PM
}

var timezoneBias:int;

export var gradient:Gradient = null;

var hudTime:Control;

# Called when the node enters the scene tree for the first time.
func _ready():
	if gradient == null:
		gradient = Gradient.new();
		gradient.offsets = gradient_data.keys()
		gradient.colors = gradient_data.values()
		
		gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
		
	timezoneBias = Time.get_time_zone_from_system().bias
	
	Network.connect("_user_connected", self, "_send_rpc_sync")
	Network.connect("_user_disconnected", self, "_send_rpc_sync")
	
	pass # Replace with function body.

func _send_rpc_sync():
	if Network.GAME_MASTER:
		var data = {"type": "daynightcycle-sync", "curTime": curTime,  "timescale": timescale}
		
		if syncToRealTime: data['timescale'] = 1
		
		Network._send_P2P_Packet(data, "all", 7)

func _read_rpc_sync():
	if Network.PLAYING_OFFLINE || Network.GAME_MASTER || Network.STEAM_LOBBY_ID == 0: return 
	
	var PACKET_SIZE = Steam.getAvailableP2PPacketSize(7)
	if PACKET_SIZE > 0:
		var PACKET = Steam.readP2PPacket(PACKET_SIZE, 7)
		
		if PACKET.empty():
			print("Error! Empty Packet!")
		
		var DATA = bytes2var(PACKET.data.decompress_dynamic( - 1, File.COMPRESSION_GZIP))
		var type = DATA["type"]
		
		if type == "daynightcycle-sync":
			curTime = int(DATA['curTime']);
			hostTimescale = int(DATA['timescale']);

func _physics_process(delta):
	if gradient == null:
		return
		
	_read_rpc_sync()
	if Network.PLAYING_OFFLINE || Network.GAME_MASTER || Network.STEAM_LOBBY_ID == 0:
		if syncToRealTime:
			curTime = Time.get_unix_time_from_system();
			
			if timezoneBias != 0:
				if timezoneBias == null:
					timezoneBias = Time.get_time_zone_from_system().bias
					print(timezoneBias)
				else:
					curTime += timezoneBias * 60
		else:
			curTime += delta * timescale;
	else:
		curTime += delta * hostTimescale
	
	# i dont wanna have to patch playerhud for this, so i do it this way instead
	# probably a better way to do this -me for all the code ive written for this
	if hudTime == null || !is_instance_valid(hudTime):
		var parent = get_tree().get_root().get_node_or_null("./playerhud/main/in_game")
		if parent != null && is_instance_valid(parent):
			hudTime = load("res://mods/nubz4lif.daynightcycle/hud_time.tscn").instance()
			hudTime.name = "current_time"
			hudTime.rect_position = Vector2(1784,128)
			hudTime.rect_size = Vector2(96,46)
			hudTime.mainDNC = self
			
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
			
	print(curTime)
		
	curTime = fmod(curTime, 86400)
	
	#var point = abs((curTime / (86400/2)) - 1)
	var point = fmod(curTime, 86400) / 86400
	#print(point)
	
	var color = gradient.interpolate(point)
	
	# ill make a better implementation later, i promise!!
	if worldenv.rain:
		var grey = (color.r + color.b + color.g) / 3
		color = Color(grey,grey,grey).darkened(0.05)
		
	worldenv.des_color = color
	
	if instant:
		worldenv.environment.background_color = worldenv.des_color
		worldenv.environment.background_color = worldenv.des_color
		worldenv.environment.ambient_light_color = worldenv.des_color
		worldenv.environment.fog_color = worldenv.des_color

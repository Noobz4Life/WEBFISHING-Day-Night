extends Panel


var time = 0;
var mainDNC;

func _physics_process(_delta):
	var time = Time.get_datetime_dict_from_unix_time(mainDNC.curTime)
	var display_string : String = "%02d:%02d" % [time.hour, time.minute]
	
	$HBoxContainer/Label.text = display_string

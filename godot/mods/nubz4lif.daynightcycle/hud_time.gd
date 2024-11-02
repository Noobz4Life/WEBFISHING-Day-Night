extends Panel


var time = 0;
var mainDNC;

func _physics_process(_delta):
	var time = Time.get_datetime_dict_from_unix_time(mainDNC.curTime)
	if mainDNC.twelveHourClock:
		var hour = fmod(time.hour - 1, 12) + 1
		var pmOrAm = "AM"
		
		if time.hour > 12:
			pmOrAm = "PM"
		
		var display_string : String = "%02d:%02d %s" % [hour, time.minute, pmOrAm]
		$Label.text = display_string
	else:
		var display_string : String = "%02d:%02d" % [time.hour, time.minute]
		
		$Label.text = display_string

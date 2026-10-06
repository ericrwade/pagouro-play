extends SceneTree
## One-off (2026-10-06): freeze the daily puzzle calendar. Until 0.2.9 the game shuffled the whole picture list with a
## fixed seed every time, so adding a single picture would have reshuffled every day for everyone. This writes that
## same shuffle out as an explicit calendar, one picture per day from 2026-01-01 to the end of 2027, which later
## picture packs edit only for dates well in the future. Run with:
##   tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path jigsaw -s ../tools_src/write_daily_schedule.gd

const PICTURES := "res://art/be/pictures.json"
const OUT := "res://art/be/daily_schedule.json"
const DAYS := 730  # 2026-01-01 .. 2027-12-31


func _init() -> void:
	var pictures: Array = JSON.parse_string(FileAccess.get_file_as_string(PICTURES))
	# the exact shuffle main.gd used through 0.2.8
	var order := range(pictures.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1888
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = order[i]; order[i] = order[j]; order[j] = t
	var days := []
	for d in range(DAYS):
		days.append(String(pictures[order[d % order.size()]].file).get_file().get_basename())
	var out := {
		"about": "The daily puzzle calendar: days[0] is 2026-01-01 (puzzle #1), one picture per day. Append-only in time: a picture pack may replace entries only for dates at least two weeks after its release, so players who update late still share every daily up to then. Past the end, the calendar repeats from the start.",
		"days": days,
	}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	print("wrote %d days; 2026-10-06 (#279) = %s" % [days.size(), days[278]])
	quit()

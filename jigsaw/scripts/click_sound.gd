class_name ClickSound
extends RefCounted
## The "tchk" when pieces fit (Eric, 2026-10-04). Made here from numbers, not recorded or downloaded, so it carries no
## license question: a very short burst of filtered noise (the cardboard edge) over a soft low knock (the table).


static func make(seed_value := 7) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * 0.07)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	var prev := 0.0
	for i in range(n):
		var t := float(i) / rate
		# the edge: noise, high-passed a little and gone in about 6 ms
		var noise := rng.randf_range(-1.0, 1.0)
		lp += (noise - lp) * 0.35
		var click := (noise - lp) * exp(-t / 0.006) * 0.55
		# the knock: a low tone that falls in pitch and fades in about 25 ms
		var f := 210.0 - 60.0 * t / 0.07
		var knock := sin(TAU * f * t) * exp(-t / 0.025) * 0.5
		var s: float = (click + knock) * min(1.0, i / 40.0)  # a 1 ms fade-in, so it never pops
		s = 0.6 * s + 0.4 * prev  # soften the very top
		prev = s
		data.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

class_name Dia2Audio
extends Node
## Audio procedural para el Día 2 · Tormenta de polvo.
## Genera efectos sonoros en memoria sin depender de archivos de audio externos.

var canal_efectos: AudioStreamPlayer
var canal_viento: AudioStreamPlayer

var wav_clic: AudioStreamWAV
var wav_alerta: AudioStreamWAV
var wav_esclusa: AudioStreamWAV
var wav_reparar: AudioStreamWAV
var wav_oxigeno: AudioStreamWAV
var wav_error: AudioStreamWAV
var wav_viento: AudioStreamWAV

func _ready() -> void:
	canal_efectos = AudioStreamPlayer.new()
	canal_efectos.bus = &"Master"
	add_child(canal_efectos)

	canal_viento = AudioStreamPlayer.new()
	canal_viento.bus = &"Master"
	add_child(canal_viento)

	wav_clic = _crear_tono(0.035, 1100.0, 0.28, true)
	wav_alerta = _crear_dos_tonos(0.08, 880.0, 1320.0, 0.32)
	wav_esclusa = _crear_ruido(0.55, 0.35)
	wav_reparar = _crear_clic_doble(0.14, 440.0, 620.0, 0.38)
	wav_oxigeno = _crear_acorde(0.40, [523.25, 659.25, 783.99], 0.26)
	wav_error = _crear_tono(0.12, 180.0, 0.36, true)
	wav_viento = _crear_viento(2.4, 0.30)

	canal_viento.stream = wav_viento
	canal_viento.volume_db = -18.0

func sonar_clic() -> void:
	_sonar(wav_clic)

func sonar_alerta() -> void:
	_sonar(wav_alerta)

func sonar_esclusa() -> void:
	_sonar(wav_esclusa)

func sonar_reparar() -> void:
	_sonar(wav_reparar)

func sonar_oxigeno() -> void:
	_sonar(wav_oxigeno)

func sonar_error() -> void:
	_sonar(wav_error)

func actualizar_viento(activo: bool, interior: bool, intensidad: float) -> void:
	if not activo:
		if canal_viento.playing:
			canal_viento.stop()
		return
	if not canal_viento.playing:
		canal_viento.play()
	var base_db := -26.0 if interior else -12.0
	canal_viento.volume_db = lerpf(canal_viento.volume_db, base_db + clampf(intensidad, 0.0, 1.0) * 8.0, 0.1)

func _sonar(wav: AudioStreamWAV) -> void:
	if wav == null or canal_efectos == null:
		return
	canal_efectos.stream = wav
	canal_efectos.play()

func _crear_tono(duracion: float, freq: float, vol: float, decaimiento: bool) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duracion * rate)
	var raw := PackedByteArray()
	raw.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * 36.0) if decaimiento else 1.0
		var s := sin(t * freq * TAU) * env * vol
		var v := clampi(int(s * 32767.0), -32768, 32767)
		raw.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = raw
	return w

func _crear_dos_tonos(dur: float, f1: float, f2: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var raw := PackedByteArray()
	raw.resize(n * 2)
	var mitad := n / 2
	for i in n:
		var t := float(i) / rate
		var f := f1 if i < mitad else f2
		var env := sin(float(i % mitad) / float(mitad) * PI)
		var s := sin(t * f * TAU) * env * vol
		var v := clampi(int(s * 32767.0), -32768, 32767)
		raw.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = raw
	return w

func _crear_ruido(dur: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var raw := PackedByteArray()
	raw.resize(n * 2)
	var val := 0.0
	for i in n:
		var t := float(i) / float(n)
		var env := sin(t * PI)
		val = lerpf(val, randf_range(-1.0, 1.0), 0.18)
		var s := val * env * vol
		var v := clampi(int(s * 32767.0), -32768, 32767)
		raw.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = raw
	return w

func _crear_clic_doble(dur: float, f1: float, f2: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var raw := PackedByteArray()
	raw.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env1 := exp(-t * 50.0)
		var t2 := maxf(0.0, t - 0.06)
		var env2 := exp(-t2 * 50.0) if t >= 0.06 else 0.0
		var s := (sin(t * f1 * TAU) * env1 + sin(t * f2 * TAU) * env2) * vol
		var v := clampi(int(s * 32767.0), -32768, 32767)
		raw.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = raw
	return w

func _crear_acorde(dur: float, freqs: Array, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var raw := PackedByteArray()
	raw.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := sin(float(i) / float(n) * PI)
		var s := 0.0
		for f: float in freqs:
			s += sin(t * f * TAU)
		s = (s / float(freqs.size())) * env * vol
		var v := clampi(int(s * 32767.0), -32768, 32767)
		raw.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = raw
	return w

func _crear_viento(dur: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var raw := PackedByteArray()
	raw.resize(n * 2)
	var val := 0.0
	for i in n:
		var t := float(i) / float(n)
		var pulso := 0.65 + 0.35 * sin(t * TAU * 2.5)
		val = lerpf(val, randf_range(-1.0, 1.0), 0.07)
		var s := val * pulso * vol
		var v := clampi(int(s * 32767.0), -32768, 32767)
		raw.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	w.data = raw
	return w

extends Node
## Lightweight procedural SFX. This keeps the mobile build self-contained while
## still giving each combat action audible feedback.

const MIX_RATE: float = 22050.0
const MIN_GAP_SECONDS: float = 0.045

var _players: Array[AudioStreamPlayer] = []
var _playbacks: Array[AudioStreamGeneratorPlayback] = []
var _next_player: int = 0
var _last_sound_ms: int = 0

func _ready() -> void:
	for index: int in 3:
		var stream := AudioStreamGenerator.new()
		stream.mix_rate = int(MIX_RATE)
		stream.buffer_length = 0.25
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -10.0
		player.stream = stream
		add_child(player)
		player.play()
		_players.append(player)
		_playbacks.append(player.get_stream_playback())

func play_attack(tower_id: String = "") -> void:
	var base_frequency: float = 260.0
	if tower_id in ["arcane", "tesla", "void_tower"]:
		base_frequency = 520.0
	elif tower_id in ["cannon", "fire_tower"]:
		base_frequency = 125.0
	_tone(base_frequency, 0.055, 0.23, true)

func play_hit(heavy: bool = false) -> void:
	_tone(105.0 if heavy else 180.0, 0.07 if heavy else 0.04, 0.28, false)

func play_build() -> void:
	_tone(620.0, 0.11, 0.24, true)

func play_upgrade() -> void:
	_tone(820.0, 0.14, 0.25, true)

func play_ui() -> void:
	_tone(440.0, 0.035, 0.16, true)

func _tone(frequency: float, duration: float, volume: float, rising: bool) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_sound_ms < int(MIN_GAP_SECONDS * 1000.0):
		return
	_last_sound_ms = now
	if _playbacks.is_empty():
		return
	var playback: AudioStreamGeneratorPlayback = _playbacks[_next_player]
	_next_player = (_next_player + 1) % _playbacks.size()
	var frames: int = maxi(1, roundi(duration * MIX_RATE))
	for frame: int in frames:
		var progress: float = float(frame) / float(frames)
		var pitch: float = frequency * (1.24 - progress * 0.24) if rising else frequency * (1.0 - progress * 0.36)
		var envelope: float = (1.0 - progress) * (1.0 - progress)
		var sample: float = sin(TAU * pitch * float(frame) / MIX_RATE) * volume * envelope
		playback.push_frame(Vector2(sample, sample))

import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'player_state.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // Streams públicos (broadcast)
  final StreamController<SimplePlayerState> _playerStateController = StreamController<SimplePlayerState>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController = StreamController<Duration?>.broadcast();
  final StreamController<String?> _errorController = StreamController<String?>.broadcast();

  // getters
  Stream<SimplePlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<String?> get errorStream => _errorController.stream;

  AudioService() {
    _init();
  }

  Future<void> _init() async {
    // Configure audio session (recommended)
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
    } catch (e) {
      // no bloquear si falla
    }

    // Listen for changes from just_audio and forward them to our controllers
    _player.playerStateStream.listen((state) {
      final processingState = state.processingState;
      final playing = state.playing;

      if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
        _emitState(SimplePlayerState.loading);
      } else if (!playing) {
        if (processingState == ProcessingState.completed) {
          _emitState(SimplePlayerState.completed);
        } else {
          _emitState(SimplePlayerState.paused);
        }
      } else if (playing) {
        _emitState(SimplePlayerState.playing);
      }
    }, onError: (err, st) {
      _emitError(err.toString());
      _emitState(SimplePlayerState.error);
    });

    _player.positionStream.listen((pos) {
      if (!_positionController.isClosed) _positionController.add(pos);
    });

    _player.durationStream.listen((dur) {
      if (!_durationController.isClosed) _durationController.add(dur);
    });

    _player.playbackEventStream.listen((event) {
      // opcional: manejar bufferedPosition, etc.
    }, onError: (err, st) {
      _emitError(err.toString());
    });
  }

  void _emitState(SimplePlayerState s) {
    if (!_playerStateController.isClosed) _playerStateController.add(s);
  }

  void _emitError(String? e) {
    if (!_errorController.isClosed) _errorController.add(e);
  }

  /// Carga la URL (si es distinta) y la reproduce.
  Future<void> setUrlAndPlay(String url) async {
    try {
      _emitState(SimplePlayerState.loading);
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      _emitError(e.toString());
      _emitState(SimplePlayerState.error);
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      _emitError(e.toString());
    }
  }

  String? get currentSourceUri => _player.sequenceState?.currentSource?.tag?.toString();

  void dispose() {
    _player.dispose();
    _playerStateController.close();
    _positionController.close();
    _durationController.close();
    _errorController.close();
  }
}

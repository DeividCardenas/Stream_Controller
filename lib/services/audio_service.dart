import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'player_state.dart';

class AudioService {
  final _audioPlayer = AudioPlayer();

  // Controladores de streams
  final _playerStateController = StreamController<SimplePlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  Stream<SimplePlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  AudioService() {
    // Escuchar cambios de estado
    _audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
        _playerStateController.add(SimplePlayerState.playing);
      } else if (state.processingState == ProcessingState.idle) {
        _playerStateController.add(SimplePlayerState.idle);
      } else if (state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading) {
        _playerStateController.add(SimplePlayerState.loading);
      } else if (state.processingState == ProcessingState.completed) {
        _playerStateController.add(SimplePlayerState.completed);
      } else {
        _playerStateController.add(SimplePlayerState.paused);
      }
    });

    // Escuchar posición actual
    _audioPlayer.positionStream.listen((pos) {
      _positionController.add(pos);
    });

    // Escuchar duración total
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) _durationController.add(dur);
    });
  }

  Future<void> setUrlAndPlay(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      _playerStateController.add(SimplePlayerState.error);
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _playerStateController.add(SimplePlayerState.stopped);
  }

  void dispose() {
    _audioPlayer.dispose();
    _playerStateController.close();
    _positionController.close();
    _durationController.close();
  }
}

import 'dart:async';
import 'package:video_player/video_player.dart';
import 'player_state.dart';

class VideoService {
  VideoPlayerController? _controller;

  // Streams (broadcast para múltiples listeners)
  final StreamController<SimplePlayerState> _playerStateController =
      StreamController<SimplePlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<bool> _bufferingController =
      StreamController<bool>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();

  // Getters
  Stream<SimplePlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<bool> get bufferingStream => _bufferingController.stream;
  Stream<String?> get errorStream => _errorController.stream;

  VideoPlayerController? get controller => _controller;

  Timer? _positionTimer;

  VideoService();

  Future<void> _attachController(VideoPlayerController c) async {
    // Dispose previo si existe
    await _detachController();

    _controller = c;
    _controller!.addListener(_onControllerUpdated);

    try {
      _emitState(SimplePlayerState.loading);
      await _controller!.initialize();
      _durationController.add(_controller!.value.duration);
      _emitState(_controller!.value.isPlaying ? SimplePlayerState.playing : SimplePlayerState.paused);
      // Iniciar timer para posición (en muchos casos el addListener es suficiente,
      // pero un timer asegura actualizaciones periódicas)
      _positionTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (_controller != null && _controller!.value.isInitialized) {
          _positionController.add(_controller!.value.position);
        }
      });
    } catch (e) {
      _emitError(e.toString());
      _emitState(SimplePlayerState.error);
    }
  }

  void _onControllerUpdated() {
    if (_controller == null) return;
    final v = _controller!.value;
    // Buffering
    if (v.isBuffering) {
      _bufferingController.add(true);
      _emitState(SimplePlayerState.loading);
    } else {
      _bufferingController.add(false);
      if (v.isInitialized) {
        _durationController.add(v.duration);
        _positionController.add(v.position);
        if (v.position >= (v.duration ?? Duration.zero) && v.duration != null && v.duration != Duration.zero && !v.isPlaying) {
          _emitState(SimplePlayerState.completed);
        } else if (v.isPlaying) {
          _emitState(SimplePlayerState.playing);
        } else {
          _emitState(SimplePlayerState.paused);
        }
      }
    }
  }

  void _emitState(SimplePlayerState s) {
    if (!_playerStateController.isClosed) _playerStateController.add(s);
  }

  void _emitError(String? e) {
    if (!_errorController.isClosed) _errorController.add(e);
  }

  /// Carga url (network) y reproduce automáticamente.
  Future<void> setUrlAndPlay(String url) async {
    try {
      _emitState(SimplePlayerState.loading);
      final newController = VideoPlayerController.network(url);
      await _attachController(newController);
      await _controller!.setLooping(false);
      await _controller!.play();
    } catch (e) {
      _emitError(e.toString());
      _emitState(SimplePlayerState.error);
    }
  }

  Future<void> play() async {
    try {
      await _controller?.play();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> pause() async {
    try {
      await _controller?.pause();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _controller?.pause();
      await seek(Duration.zero);
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _controller?.seekTo(position);
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> _detachController() async {
    _positionTimer?.cancel();
    if (_controller != null) {
      try {
        _controller!.removeListener(_onControllerUpdated);
        await _controller!.pause();
        await _controller!.dispose();
      } catch (_) {}
      _controller = null;
    }
  }

  void dispose() {
    _positionTimer?.cancel();
    _detachController();
    _playerStateController.close();
    _positionController.close();
    _durationController.close();
    _bufferingController.close();
    _errorController.close();
  }
}

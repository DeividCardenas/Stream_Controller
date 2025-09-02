import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../services/audio_service.dart';
import '../services/video_service.dart';
import '../services/player_state.dart';

class DetailScreen extends StatefulWidget {
  final MediaItem item;
  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final AudioService _audioService;
  VideoService? _videoService;
  String? _currentPreviewUrl;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _detectMediaType();
  }

  void _detectMediaType() {
    final preview = widget.item.previewUrl ?? '';
    final kind = widget.item.kind.toLowerCase();
    final lower = preview.toLowerCase();
    _isVideo = kind.contains('video') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.mov') ||
        kind.contains('feature-movie');
    if (_isVideo) {
      _videoService = VideoService();
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    _videoService?.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildHeader(double width) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: widget.item.artworkUrl + widget.item.trackName,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.item.artworkUrl.isNotEmpty
                    ? widget.item.artworkUrl
                    : 'https://via.placeholder.com/100',
                width: width * 0.28,
                height: width * 0.28,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.trackName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(widget.item.artistName,
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(widget.item.kind, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    final preview = widget.item.previewUrl;
    if (preview == null || preview.isEmpty) {
      return const Text('No hay preview disponible para este item.');
    }

    return Column(
      children: [
        StreamBuilder<SimplePlayerState>(
          stream: _audioService.playerStateStream,
          initialData: SimplePlayerState.idle,
          builder: (context, snap) {
            final state = snap.data ?? SimplePlayerState.idle;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_currentPreviewUrl != preview) {
                      _currentPreviewUrl = preview;
                      _audioService.setUrlAndPlay(preview);
                    } else {
                      if (state == SimplePlayerState.playing) {
                        _audioService.pause();
                      } else {
                        _audioService.setUrlAndPlay(preview);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
                  child: Icon(
                    state == SimplePlayerState.playing ? Icons.pause : Icons.play_arrow,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _audioService.stop(),
                  child: const Text('Stop'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<Duration?>(
          stream: _audioService.durationStream,
          initialData: Duration.zero,
          builder: (context, durSnap) {
            final duration = durSnap.data ?? Duration.zero;
            return StreamBuilder<Duration>(
              stream: _audioService.positionStream,
              initialData: Duration.zero,
              builder: (context, posSnap) {
                final pos = posSnap.data ?? Duration.zero;
                final totalMs = duration.inMilliseconds;
                return Column(
                  children: [
                    Slider(
                      min: 0,
                      max: totalMs > 0 ? totalMs.toDouble() : 1.0,
                      value: pos.inMilliseconds.clamp(0, totalMs).toDouble(),
                      onChanged: (v) =>
                          _audioService.seek(Duration(milliseconds: v.toInt())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(pos)),
                        Text(_formatDuration(duration)),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    final preview = widget.item.previewUrl;
    if (preview == null || preview.isEmpty) {
      return const Text('No hay preview disponible para este video.');
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  StreamBuilder<VideoPlayerController?>(
                    stream: Stream.value(_videoService?.controller),
                    builder: (context, _) {
                      final ctrl = _videoService?.controller;
                      if (ctrl == null) {
                        return Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _currentPreviewUrl = preview;
                              _videoService?.setUrlAndPlay(preview);
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Cargar y reproducir'),
                          ),
                        );
                      }
                      if (!ctrl.value.isInitialized) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return VideoPlayer(ctrl);
                    },
                  ),
                  Positioned.fill(
                    child: StreamBuilder<SimplePlayerState>(
                      stream: _videoService?.playerStateStream,
                      initialData: SimplePlayerState.idle,
                      builder: (context, snap) {
                        final state = snap.data ?? SimplePlayerState.idle;
                        return GestureDetector(
                          onTap: () {
                            if (state == SimplePlayerState.playing) {
                              _videoService?.pause();
                            } else {
                              if (_currentPreviewUrl != preview) {
                                _currentPreviewUrl = preview;
                                _videoService?.setUrlAndPlay(preview);
                              } else {
                                _videoService?.play();
                              }
                            }
                          },
                          child: Container(
                            color: Colors.black.withOpacity(0.06),
                            child: Center(
                              child: state == SimplePlayerState.loading
                                  ? const CircularProgressIndicator()
                                  : Icon(
                                state == SimplePlayerState.playing
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 64,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<Duration?>(
          stream: _videoService?.durationStream,
          initialData: Duration.zero,
          builder: (context, durSnap) {
            final duration = durSnap.data ?? Duration.zero;
            return StreamBuilder<Duration>(
              stream: _videoService?.positionStream,
              initialData: Duration.zero,
              builder: (context, posSnap) {
                final pos = posSnap.data ?? Duration.zero;
                final totalMs = duration.inMilliseconds;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Slider(
                        min: 0,
                        max: totalMs > 0 ? totalMs.toDouble() : 1.0,
                        value: pos.inMilliseconds.clamp(0, totalMs).toDouble(),
                        onChanged: (v) =>
                            _videoService?.seek(Duration(milliseconds: v.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(pos)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(item.trackName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1F3A), Color(0xFF0F141C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(width),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        if (_isVideo)
                          _buildVideoPlayer(context)
                        else
                          _buildAudioPlayer(),
                        const SizedBox(height: 12),
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Detalles',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Artista: ${item.artistName}'),
                                const SizedBox(height: 6),
                                Text('Tipo: ${item.kind}'),
                                const SizedBox(height: 6),
                                SelectableText(
                                  'Preview URL: ${item.previewUrl ?? "N/A"}',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: item.trackViewUrl.isNotEmpty
                                          ? () => _openUrl(item.trackViewUrl)
                                          : null,
                                      child: const Text('Abrir en Store'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

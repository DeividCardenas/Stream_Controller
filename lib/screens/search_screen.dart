import 'package:flutter/material.dart';
import '../services/media_service.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final MediaService _service;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _service = MediaService();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _service.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  Widget _buildList(List<MediaItem> items, bool hasMore) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No hay resultados',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index < items.length) {
          final item = items[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(item: item))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.01)]),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: item.artworkUrl + item.trackName,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(item.artworkUrl.isNotEmpty ? item.artworkUrl : 'https://via.placeholder.com/80',
                          width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.trackName, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(item.artistName, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                              child: Text(item.kind, style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white54),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: Text(
                'Desliza para cargar más...',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Media Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar música, videos, artistas...',
                hintStyle: const TextStyle(color: Colors.white70),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _controller.clear();
                    _service.searchNow('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (text) => _service.querySink.add(text),
              textInputAction: TextInputAction.search,
              onSubmitted: (text) => _service.searchNow(text),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1C29), Color(0xFF232736)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            StreamBuilder<bool>(
              stream: _service.loadingStream,
              initialData: false,
              builder: (context, snap) {
                final loading = snap.data ?? false;
                return Visibility(
                  visible: loading,
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8F94FB)),
                  ),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<List<MediaItem>>(
                stream: _service.resultsStream,
                initialData: const [],
                builder: (context, snap) {
                  final items = snap.data ?? [];
                  return StreamBuilder<String?>(
                    stream: _service.errorStream,
                    initialData: null,
                    builder: (context, errSnap) {
                      final error = errSnap.data;
                      if (error != null) {
                        return Center(
                          child: Text(
                            'Error: $error',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return StreamBuilder<bool>(
                        stream: _service.hasMoreStream,
                        initialData: false,
                        builder: (context, hasMoreSnap) {
                          final hasMore = hasMoreSnap.data ?? false;
                          return Stack(
                            children: [
                              _buildList(items, hasMore),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: StreamBuilder<bool>(
                                  stream: _service.loadingMoreStream,
                                  initialData: false,
                                  builder: (context, loadingMoreSnap) {
                                    final loadingMore = loadingMoreSnap.data ?? false;
                                    if (!loadingMore) return const SizedBox.shrink();
                                    return Container(
                                      width: double.infinity,
                                      color: Colors.black.withOpacity(0.7),
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8F94FB)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: StreamBuilder<bool>(
                stream: _service.hasMoreStream,
                initialData: false,
                builder: (context, hasMoreSnap) {
                  final hasMore = hasMoreSnap.data ?? false;
                  if (!hasMore) return const SizedBox.shrink();
                  return ElevatedButton(
                    onPressed: () => _service.loadMore(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E54C8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cargar más'),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
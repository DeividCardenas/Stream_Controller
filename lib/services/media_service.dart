import 'dart:async';
import '../models/media_item.dart';
import 'itunes_api.dart';

class MediaService {
  final ITunesApi _api = ITunesApi();

  // Streams públicos
  final StreamController<List<MediaItem>> _resultsController = StreamController<List<MediaItem>>.broadcast();
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();
  final StreamController<bool> _loadingMoreController = StreamController<bool>.broadcast();
  final StreamController<String?> _errorController = StreamController<String?>.broadcast();
  final StreamController<bool> _hasMoreController = StreamController<bool>.broadcast();

  // Sink para queries
  final StreamController<String> _queryController = StreamController<String>();

  Timer? _debounce;

  // Paginación
  String _currentQuery = '';
  int _limit = 25;
  int _offset = 0;
  bool _isFetching = false;
  bool _hasMore = true;
  final List<MediaItem> _accumulated = [];

  MediaService() {
    _queryController.stream.listen((query) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        searchNow(query);
      });
    });
  }

  // Exposiciones
  Stream<List<MediaItem>> get resultsStream => _resultsController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<bool> get loadingMoreStream => _loadingMoreController.stream;
  Stream<String?> get errorStream => _errorController.stream;
  Stream<bool> get hasMoreStream => _hasMoreController.stream;
  Sink<String> get querySink => _queryController.sink;

  void searchNow(String query, {int limit = 25}) {
    _currentQuery = query;
    _limit = limit;
    _offset = 0;
    _hasMore = true;
    _accumulated.clear();
    _emitHasMore();
    _performSearch(reset: true);
  }

  void loadMore() {
    if (_isFetching || !_hasMore || _currentQuery.trim().isEmpty) return;
    _offset += _limit;
    _performSearch(reset: false);
  }

  Future<void> _performSearch({required bool reset}) async {
    if (_currentQuery.trim().isEmpty) {
      if (!_resultsController.isClosed) _resultsController.add([]);
      if (!_loadingController.isClosed) _loadingController.add(false);
      if (!_loadingMoreController.isClosed) _loadingMoreController.add(false);
      if (!_errorController.isClosed) _errorController.add(null);
      _hasMore = false;
      _emitHasMore();
      return;
    }

    try {
      _isFetching = true;
      if (reset) {
        if (!_loadingController.isClosed) _loadingController.add(true);
      } else {
        if (!_loadingMoreController.isClosed) _loadingMoreController.add(true);
      }

      final results = await _api.search(_currentQuery, limit: _limit, offset: _offset);

      if (reset) {
        _accumulated
          ..clear()
          ..addAll(results);
      } else {
        _accumulated.addAll(results);
      }

      if (!_resultsController.isClosed) _resultsController.add(List.unmodifiable(_accumulated));
      _hasMore = results.length == _limit;
      _emitHasMore();

      if (!_errorController.isClosed) _errorController.add(null);
    } catch (e) {
      if (reset) {
        _accumulated.clear();
        if (!_resultsController.isClosed) _resultsController.add([]);
      }
      if (!_errorController.isClosed) _errorController.add(e.toString());
    } finally {
      _isFetching = false;
      if (!_loadingController.isClosed) _loadingController.add(false);
      if (!_loadingMoreController.isClosed) _loadingMoreController.add(false);
    }
  }

  void _emitHasMore() {
    if (!_hasMoreController.isClosed) _hasMoreController.add(_hasMore);
  }

  void searchViaSink(String query) => _queryController.sink.add(query);

  void dispose() {
    _debounce?.cancel();
    _queryController.close();
    _resultsController.close();
    _loadingController.close();
    _loadingMoreController.close();
    _errorController.close();
    _hasMoreController.close();
  }
}

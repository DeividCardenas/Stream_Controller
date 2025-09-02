class MediaItem {
  final String trackName;
  final String artistName;
  final String kind;
  final String artworkUrl;
  final String? previewUrl;
  final String trackViewUrl;

  MediaItem({
    required this.trackName,
    required this.artistName,
    required this.kind,
    required this.artworkUrl,
    required this.previewUrl,
    required this.trackViewUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      trackName: (json['trackName'] ?? json['collectionName'] ?? 'Sin título') as String,
      artistName: (json['artistName'] ?? 'Desconocido') as String,
      kind: (json['kind'] ?? json['wrapperType'] ?? 'unknown') as String,
      artworkUrl: (json['artworkUrl100'] ?? json['artworkUrl60'] ?? '') as String,
      previewUrl: json['previewUrl'] as String?,
      trackViewUrl: (json['trackViewUrl'] ?? json['collectionViewUrl'] ?? '') as String,
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

class ITunesApi {
  Future<List<MediaItem>> search(String term, {int limit = 25, int offset = 0, String media = 'music'}) async {
    final encoded = Uri.encodeQueryComponent(term);
    final url = Uri.parse('https://itunes.apple.com/search?term=$encoded&limit=$limit&offset=$offset&media=$media');
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final Map<String, dynamic> jsonBody = json.decode(res.body) as Map<String, dynamic>;
    final results = jsonBody['results'] as List<dynamic>? ?? [];
    return results.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

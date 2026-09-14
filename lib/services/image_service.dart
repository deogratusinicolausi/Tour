import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  // ⭐️ Weka API keys zako zote hapa
  static const String _pexelsKey = 'M3zOTp6nW4EkMDWDXiOesTF4Cs1vPz1nnhNrGBX1fBni0S7GSIvFf3hr';
  static const String _pixabayKey = '57549213-d3ce1ff67cf19fca20bbb643f';

  // ⭐️ Chagua API unayotaka kutumia
  static const String _primaryApi = 'pixabay'; // au 'pixabay'

  Future<List<Map<String, dynamic>>> searchPhotos(String query) async {
    if (_primaryApi == 'pixabay') {
      return await _searchPixabay(query);
    }
    return await _searchPexels(query);
  }

  // Pexels search
  Future<List<Map<String, dynamic>>> _searchPexels(String query) async {
    final response = await http.get(
      Uri.parse('https://api.pexels.com/v1/search?query=$query&per_page=80'),
      headers: {'Authorization': _pexelsKey},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['photos']);
    }
    throw Exception('Pexels failed');
  }

  // Pixabay search
  Future<List<Map<String, dynamic>>> _searchPixabay(String query) async {
    final response = await http.get(
      Uri.parse('https://pixabay.com/api/?key=$_pixabayKey&q=$query&per_page=80&image_type=photo'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Pixabay inarudisha format tofauti - badilisha iwe sawa na Pexels
      return (data['hits'] as List).map((item) {
        return {
          'id': item['id'].toString(),
          'src': {
            'large': item['largeImageURL'],
            'medium': item['webformatURL'],
          },
        };
      }).toList();
    }
    throw Exception('Pixabay failed');
  }
}
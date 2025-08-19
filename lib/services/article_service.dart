import 'dart:convert';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:young_advmobproglab2/constants.dart';

class ArticleService {
  List listData = [];

  Future<List> getAllArticle() async {
    final response = await http.get(
    Uri.parse('$host/posts'),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Dart/3.0 (Flutter)'
      },
    );


    if (response.statusCode == 200) {
      listData = jsonDecode(response.body);
      return listData;
    } else {
      print('Response: ${response.body}');
      throw Exception('Failed to load data');
    }
  }
}

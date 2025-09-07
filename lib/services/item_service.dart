import 'dart:convert';

import 'package:http/http.dart';
import 'package:young_longexam_mobile/constants.dart';

class ItemService {
  Map<dynamic, dynamic> mapData = {};

  Future<Map> getAllItem() async {
    final response = await get(Uri.parse('$host/api/items/'));
    if (response.statusCode == 200) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map> getActiveItems() async {
    final response = await get(Uri.parse('$host/api/items/active'));
    if (response.statusCode == 200) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map> getArchivedItems() async {
    final response = await get(Uri.parse('$host/api/items/archived'));
    if (response.statusCode == 200) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map> createItem(dynamic article) async {
    final response = await post(
      Uri.parse('$host/api/items'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(article),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      print ('Failed to create item: ${response.statusCode} ${response.body}');
      throw Exception(
        'Failed to create item: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map> updateItem(String id, dynamic article) async {
    final response = await put(
      Uri.parse('$host/api/items/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(article),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception(
        'Failed to update item: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map> deleteItem(String id, dynamic article) async {
    final response = await delete(
      Uri.parse('$host/api/items/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(article),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception(
        'Failed to update article: ${response.statusCode} ${response.body}');
    }
  }
}
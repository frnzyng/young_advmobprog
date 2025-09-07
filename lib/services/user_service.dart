import 'dart:convert';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:young_longexam_mobile/constants.dart';
import 'package:young_longexam_mobile/models/user_model.dart';

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    Response response = await post(Uri.parse('$host/api/users/login'),
        body: {"email": email, "password": password});

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      print(data);
      return data;
      
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> registerUser(firstName, lastName, age, gender, contactNumber, email, username, password, address) async {
    Response response = await post(Uri.parse('$host/api/users/register'),
      body: {
        "firstName": firstName,
        "lastName": lastName,
        "age": age.toString(),
        "gender": gender,
        "contactNumber": contactNumber,
        "email": email,
        "username": username,
        "password": password,
        "address": address,
      }
    );

    if (response.statusCode == 201) {
      data = jsonDecode(response.body);
      print(data);
      
      return data;
      
    } else {
      throw Exception('Failed to register');
    }
  }

  // Save data into SharedPreferences
  //**Save User Data to SharedPreferences**
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', userData['id'] ?? '');
    await prefs.setString('firstName', userData['firstName'] ?? '');
    await prefs.setString('lastName', userData['lastName'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('token', userData['token'] ?? '');
    await prefs.setString('type', userData['type'] ?? '');
  }

  //**Retrieve User Data from SharedPreferences**
  Future<Map<String, dynamic>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('id') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'email': prefs.getString('email') ?? '',
      'token': prefs.getString('token') ?? '',
      'type': prefs.getString('type') ?? '',
    };
  }

  Future<User> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    final response = await http.get(Uri.parse('$host/api/users/info/$userId'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return User.fromJson(data['users']);
    } else {
      throw Exception('Failed to load user info');
    }
  }


  //**Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  //**Logout and Clear User Data**
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
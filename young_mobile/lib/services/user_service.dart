import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:young_advmobprog/constants.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

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
    await prefs.setString('uid', userData['uid'] ?? '');
    await prefs.setString('id', userData['id'] ?? '');
    await prefs.setString('username', userData['username'] ?? '');
    await prefs.setString('firstName', userData['firstName'] ?? '');
    await prefs.setString('lastName', userData['lastName'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('address', userData['address'] ?? '');
    await prefs.setString('gender', userData['gender'] ?? '');
    await prefs.setString('contactNumber', userData['contactNumber'] ?? '');
    await prefs.setString('age', userData['age'] ?? '');
    await prefs.setString('token', userData['token'] ?? '');
    await prefs.setString('type', userData['type'] ?? '');
  }

  //**Retrieve User Data from SharedPreferences**
  Future<Map<String, dynamic>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString('uid') ?? '',
      'id': prefs.getString('id') ?? '',
      'username': prefs.getString('username') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'email': prefs.getString('email') ?? '',
      'address': prefs.getString('address') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'contactNumber': prefs.getString('contactNumber') ?? '',
      'age': prefs.getString('age') ?? '',
      'token': prefs.getString('token') ?? '',
      'type': prefs.getString('type') ?? '',
    };
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

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final userId = await userData['id'];

    final payload = _cleanseData(userData);

    final response = await put(
      Uri.parse('$host/api/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception(
        'Failed to update user: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteUser(id) async {
    await post(Uri.parse('$host/api/users/delete/$id'));
  }



  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();


  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. SIGN IN USER WITH FIREBASE AUTH
      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the authenticated user
      User? user = userCredential.user;
      if (user == null) {
        throw Exception('Authentication successful, but user object is null.');
      }

      // 2. FETCH ADDITIONAL USER DATA FROM FIRESTORE
      DocumentSnapshot<Map<String, dynamic>> userDoc = await firestore
          .collection('Users')
          .doc(user.uid) // Use the User's UID as the document ID
          .get();

      if (!userDoc.exists) {
        // This is a potential issue if registration failed to write to Firestore
        throw Exception('User data not found in Firestore.');
      }

      // 3. RETURN THE FIRESTORE DATA
      // We return the map of user data instead of the UserCredential
      return userDoc.data()!;

    } on FirebaseAuthException catch (e) {
      // Re-throw specific Firebase Auth errors for UI handling
      throw Exception(e.code == 'user-not-found'
          ? 'No user found for that email.'
          : e.code == 'wrong-password'
              ? 'Wrong password provided.'
              : e.message ?? 'An unknown authentication error occurred.');
    } catch (e) {
      // Handle any other errors (e.g., network issues, Firestore read errors)
      throw Exception('Sign-in failed: $e');
    }
  }


  Future<UserCredential> createAccount({
    required String firstName,
    required String lastName,
    required String age,
    required String gender,
    required String contactNumber,
    required String email,
    required String username,
    required String password,
    required String address,
  }) async {
    try {
      // 1. CREATE USER IN FIREBASE AUTH
      UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the newly created user's UID
      String uid = userCredential.user!.uid;

      // 2. SAVE ADDITIONAL USER DETAILS TO FIRESTORE
      await firestore.collection('Users').doc(uid).set({
        'uid': uid, // Store the UID in the document for easy querying
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'gender': gender,
        'contactNumber': contactNumber,
        'email': email,
        'username': username,
        'address': address,
        'type': 'editor'
      });

      // 3. RETURN THE USER CREDENTIAL
      return userCredential;

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors (e.g., email already in use)
      throw Exception('Firebase Auth Error: ${e.message}');
    } catch (e) {
      // Handle other potential errors (e.g., Firestore write error)
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  /// Helper function to remove null or empty values from a map.
  Map<String, dynamic> _cleanseData(Map<String, dynamic> data) {
    return Map.fromEntries(
      data.entries.where((entry) => entry.value != null && entry.value != ''),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:young_advmobprog/services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>> getUserData() async {
    UserService _userService = UserService();
    final userData = await _userService.getUserData();
    return userData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No user data found"),
            );
          }

          final userData = snapshot.data!;
          return buildProfile(userData);
        },
      ),
    );
  }
}

Widget buildProfile(userData) {
  return SingleChildScrollView(
    padding: EdgeInsets.all(20.sp),
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 20),
          Text(
            "${userData['firstName']} ${userData['lastName']}",
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "${userData['type'].toString().substring(0, 1).toUpperCase()}${userData['type'].toString().substring(1)}",
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text("Username"),
                  subtitle: Text(userData['username'] ?? "N/A"),
                ),
                const Divider(height: 1, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text("Email"),
                  subtitle: Text(userData['email'] ?? "N/A"),
                ),
                const Divider(height: 1, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text("Contact Number"),
                  subtitle: Text(userData['contactNumber'] ?? "N/A"),
                ),
                const Divider(height: 1, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text("Address"),
                  subtitle: Text(userData['address'] ?? "N/A"),
                ),
                const Divider(height: 1, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.cake_outlined),
                  title: const Text("Age"),
                  subtitle: Text(userData['age']?.toString() ?? "N/A"),
                ),
                const Divider(height: 1, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.people_alt_outlined),
                  title: const Text("Gender"),
                  subtitle: Text(userData['gender'] ?? "N/A"),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildFirebaseProfile(userData) {
  return SingleChildScrollView(
    padding: EdgeInsets.all(20.sp),
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 20),
          Text(
            userData['username'] != null && userData['username'].isNotEmpty
                ? userData['username']
                : userData['firstName'] ?? "No Name",
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "${userData['type'].toString().substring(0, 1).toUpperCase()}${userData['type'].toString().substring(1)}",
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text("Email"),
                  subtitle: Text(userData['email'] ?? "N/A"),
                ),
                const Divider(height: 1, thickness: 1),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:young_longexam_mobile/models/user_model.dart';
import 'package:young_longexam_mobile/services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // This function now correctly calls getUserInfo and handles the result.
  // It returns a User object instead of a Map, which is a better practice.
  Future<User> getUserData() async {
    UserService _userService = UserService();
    final User userData = await _userService.getUserInfo();
    print(userData);
    return userData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<User>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("${snapshot.error}"),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text("No user data found"),
            );
          }

          // Access the user object directly from the snapshot
          final user = snapshot.data!;

          // Accessing the properties from the User object
          final String firstName = user.firstName ?? '';
          final String lastName = user.lastName ?? '';
          final String username = user.username ?? '';
          final String email = user.email ?? '';
          final String type = user.type ?? '';
          final String age = user.age ?? 'N/A';
          final String gender = user.gender ?? 'N/A';
          final String address = user.address ?? 'N/A';

          return Padding(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  type.isNotEmpty
                      ? "${type[0].toUpperCase()}${type.substring(1)}"
                      : '',
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Full Name'),
                        subtitle: Text(
                          '$firstName $lastName',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.abc),
                        title: const Text('Username'),
                        subtitle: Text(
                          username,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email Address'),
                        subtitle: Text(
                          email,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.cake_outlined),
                        title: const Text('Age'),
                        subtitle: Text(
                          age,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.wc_outlined),
                        title: const Text('Gender'),
                        subtitle: Text(
                          gender,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Contact Number'),
                        subtitle: Text(
                          gender,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.location_city),
                        title: const Text('Address'),
                        subtitle: Text(
                          address,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
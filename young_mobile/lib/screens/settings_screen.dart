import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:young_advmobprog/providers/theme_provider.dart';
import 'package:young_advmobprog/services/user_service.dart';
import 'package:young_advmobprog/widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void logout(BuildContext context) {
    UserService userService = UserService();
    
    userService.logout();
    Navigator.of(context).popAndPushNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: "Settings",
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: "Dark Mode",
                  fontSize: 16.sp,
                ),
                Switch(
                  value: themeProvider.isDark,
                  onChanged: (val) {
                    context.read<ThemeProvider>().toggleTheme();
                  },
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: "Logout",
                  fontSize: 16.sp,
                ),
                IconButton(onPressed: () => logout(context), icon: Icon(Icons.logout))
              ],
            ),
          ],
        )
      ),
    );
  }
}

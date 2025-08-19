import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:young_advmobproglab2/providers/theme_provider.dart';
import 'package:young_advmobproglab2/widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              text: "Dark Mode",
              fontSize: 16.sp,
            ),
            Switch(
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
                          if (themeProvider.isDark) {
                            return const Icon(Icons.dark_mode);
                          }
                          return const Icon(Icons.light_mode);; // All other states will use the default thumbIcon.
                        }),
              value: themeProvider.isDark,
              onChanged: (val) {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }
}

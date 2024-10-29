// lib/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:untitled/views/home_screen.dart'; // 确保导入正确

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);  // 修复构造函数

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2秒后跳转到主页
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {  // 检查 widget 是否还在树中
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/ic_launcher.png',
              width: 800,
              height: 800,
            ),
            const SizedBox(height: 20),
            const Text(
              'Melanoma Detection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
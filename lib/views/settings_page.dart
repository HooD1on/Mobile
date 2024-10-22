import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Set Image Processing Parameters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // 在这里添加设置选项
            Text('Brightness:'),
            // 可以在这里添加滑动条或其他控件调整参数
            Text('Contrast:'),
            // 添加更多设置项...
          ],
        ),
      ),
    );
  }
}

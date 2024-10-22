import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../views/scan_page.dart';
import '../views/history_page.dart';
import '../views/settings_page.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Melanoma Detection'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_a_photo),  // 可以改用图库图标
                  onPressed: viewModel.isModelLoaded
                      ? () => viewModel.pickAndAnalyzeImage(context)
                      : null,
                ),
              ],
            ),
            body: viewModel.isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading model... Please wait.'),
                ],
              ),
            )
                : viewModel.isModelLoaded
                ? Column(
              children: [
                if (viewModel.currentIndex == 0) // 只在 Scan 页面显示
                  ElevatedButton(
                    onPressed: () => viewModel.analyzeTestImage(context),
                    child: const Text('Analyze Test Image'),
                  ),
                Expanded(
                  child: [
                    ScanPage(),
                    HistoryPage(),
                  ][viewModel.currentIndex],
                ),
              ],
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Failed to load model.'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => viewModel.reloadModel(),
                    child: Text('Retry Loading Model'),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: viewModel.currentIndex,
              onTap: viewModel.setCurrentIndex,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera),
                  label: 'Scan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
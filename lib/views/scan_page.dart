import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../viewmodels/scan_viewmodel.dart';
import '../viewmodels/history_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scanViewModel = context.read<ScanViewModel>();
      final settingsViewModel = context.read<SettingsViewModel>();
      settingsViewModel.onSettingsChanged = scanViewModel.onSettingsChanged;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanViewModel>(
      builder: (context, viewModel, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (viewModel.image != null && viewModel.imageProcessingModel.processedImageFile != null)
                Image.file(
                  viewModel.imageProcessingModel.processedImageFile!,
                  height: 200,
                )
              else
                const Text('No image selected.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final historyViewModel = context.read<HistoryViewModel>();
                  await viewModel.pickImage(context, historyViewModel);
                  if (viewModel.result != null) {
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Scan Result"),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (viewModel.imageProcessingModel.processedImageFile != null)
                                  Image.file(
                                    viewModel.imageProcessingModel.processedImageFile!,
                                    height: 200,
                                  ),
                                const SizedBox(height: 20),
                                Text(viewModel.getFormattedResult()),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text("OK"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: const Text('Start Scan'),
              ),
            ],
          ),
        );
      },
    );
  }
}
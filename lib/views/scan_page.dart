import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../viewmodels/scan_viewmodel.dart';
import '../viewmodels/history_viewmodel.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanViewModel(),
      child: Consumer<ScanViewModel>(
        builder: (context, viewModel, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (viewModel.image != null)
                  Image.file(
                    File(viewModel.image!.path),
                    height: 200,
                  )
                else
                  const Text('No image selected.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final historyViewModel = Provider.of<HistoryViewModel>(context, listen: false);
                    await viewModel.pickImage(context, historyViewModel);
                    if (viewModel.result != null) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Scan Result"),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (viewModel.image != null)
                                    Image.file(
                                      File(viewModel.image!.path),
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
      ),
    );
  }
}
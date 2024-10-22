// lib/views/history_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../viewmodels/history_viewmodel.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryViewModel()..loadHistories(),
      child: Consumer<HistoryViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(title: Text('History')),
            body: ListView.separated(  // 使用 ListView.separated 代替 ListView.builder
              itemCount: viewModel.histories.length,
              separatorBuilder: (context, index) => Divider(  // 添加分隔线
                height: 1,
                color: Colors.grey[300],
              ),
              itemBuilder: (context, index) {
                final history = viewModel.histories[index];
                return Padding(  // 添加内边距使列表项看起来更加美观
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    leading: ClipRRect(  // 添加圆角边框
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(history.imagePath),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(history.result),
                    subtitle: Text(
                      history.dateTime.toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[300]),
                      onPressed: () => viewModel.deleteHistory(history.id!),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Scan Result'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(  // 给对话框中的图片也添加圆角
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(File(history.imagePath)),
                                  ),
                                  SizedBox(height: 20),
                                  Text(history.result),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: Text('Close'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
// lib/viewmodels/history_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/history_model.dart';
import '../services/database_helper.dart';

class HistoryViewModel extends ChangeNotifier {
  List<History> _histories = [];
  List<History> get histories => _histories.take(10).toList(); // 只返回最近的10条记录

  Future<void> loadHistories() async {
    // 获取所有记录并按日期降序排序，然后取前10条
    _histories = await DatabaseHelper.instance.getAllHistories();
    _histories.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // 按时间降序排序
    notifyListeners();
  }

  Future<void> addHistory(String imagePath, String result) async {
    final history = History(
      imagePath: imagePath,
      result: result,
      dateTime: DateTime.now(),
    );
    await DatabaseHelper.instance.insert(history);
    await loadHistories();
  }

  Future<void> deleteHistory(int id) async {
    await DatabaseHelper.instance.delete(id);
    await loadHistories();
  }
}
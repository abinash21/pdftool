import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryManager extends ChangeNotifier {
  static const String _storageKey = "pdftool_history";

  final List<HistoryItem> _history = [];

  List<HistoryItem> get history => List.unmodifiable(_history.reversed);

  /// LOAD HISTORY ON START
  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);

    if (data != null) {
      final List decoded = jsonDecode(data);
      _history.clear();
      _history.addAll(decoded.map((e) => HistoryItem.fromJson(e)));
      notifyListeners();
    }
  }

  /// SAVE HISTORY
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_history.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// ADD NEW ENTRY
  Future<void> addHistory(HistoryItem item) async {
    _history.add(item);
    await _saveHistory();
    notifyListeners();
  }

  /// CLEAR ALL
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }
}

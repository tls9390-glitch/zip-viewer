import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String _lastPageKey = 'last_pages';
  static const String _bookmarksKey = 'bookmarks';
  static const String _recentFilesKey = 'recent_files';

  static Future<void> saveLastPage(String filePath, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _getMap(prefs, _lastPageKey);
    map[filePath] = page;
    await prefs.setString(_lastPageKey, jsonEncode(map));
  }

  static Future<int> getLastPage(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _getMap(prefs, _lastPageKey);
    return map[filePath] ?? 0;
  }

  static Future<bool> toggleBookmark(String filePath, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _getMap(prefs, _bookmarksKey);
    final List<int> pages = List<int>.from(map[filePath] ?? []);
    if (pages.contains(page)) {
      pages.remove(page);
    } else {
      pages.add(page);
      pages.sort();
    }
    map[filePath] = pages;
    await prefs.setString(_bookmarksKey, jsonEncode(map));
    return pages.contains(page);
  }

  static Future<List<int>> getBookmarks(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _getMap(prefs, _bookmarksKey);
    return List<int>.from(map[filePath] ?? []);
  }

  static Future<bool> isBookmarked(String filePath, int page) async {
    final bookmarks = await getBookmarks(filePath);
    return bookmarks.contains(page);
  }

  static Future<void> addRecentFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_recentFilesKey) ?? [];
    recent.remove(filePath);
    recent.insert(0, filePath);
    if (recent.length > 20) recent = recent.sublist(0, 20);
    await prefs.setStringList(_recentFilesKey, recent);
  }

  static Future<List<String>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentFilesKey) ?? [];
  }

  static Future<void> removeRecentFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_recentFilesKey) ?? [];
    recent.remove(filePath);
    await prefs.setStringList(_recentFilesKey, recent);
  }

  static Map<String, dynamic> _getMap(SharedPreferences prefs, String key) {
    final str = prefs.getString(key);
    if (str == null) return {};
    return Map<String, dynamic>.from(jsonDecode(str));
  }
}

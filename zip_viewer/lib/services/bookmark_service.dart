import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String _lastPageKey = 'last_pages';
  static const String _bookmarksKey = 'bookmarks';
  static const String _recentFilesKey = 'recent_files';

  /// 마지막으로 읽은 페이지 저장
  static Future<void> saveLastPage(String filePath, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _getMap(prefs, _lastPageKey);
    map[filePath] = page;
    await prefs.setString(_lastPageKey, jsonEncode(map));
  }

  /// 마지막으로 읽은 페이지 불러오기
  static Future<int> getLastPage(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _getMap(prefs, _lastPageKey);
    return map[filePath] ?? 0;
  }

  /// 북마크 추가/제거 토글
  static Future<bool> toggleBookmark(String filePath, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _getMapList(prefs, _bookmarksKey);
    final key = filePath;
    final List<int> pages = List<int>.from(map[key] ?? []);

    if (pages.contains(page)) {
      pages.remove(page);
    } else {
      pages.add(page);
      pages.sort();
    }

    map[key] = pages;
    await prefs.setString(_bookmarksKey, jsonEncode(map));
    return pages.contains(page);
  }

  /// 특정 파일의 북마크 목록
  static Future<List<int>> getBookmarks(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _getMapList(prefs, _bookmarksKey);
    return List<int>.from(map[filePath] ?? []);
  }

  /// 특정 페이지가 북마크인지 확인
  static Future<bool> isBookmarked(String filePath, int page) async {
    final bookmarks = await getBookmarks(filePath);
    return bookmarks.contains(page);
  }

  /// 최근 파일 목록 저장
  static Future<void> addRecentFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_recentFilesKey) ?? [];
    recent.remove(filePath);
    recent.insert(0, filePath);
    if (recent.length > 20) recent = recent.sublist(0, 20);
    await prefs.setStringList(_recentFilesKey, recent);
  }

  /// 최근 파일 목록 불러오기
  static Future<List<String>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentFilesKey) ?? [];
  }

  /// 최근 파일 목록에서 제거
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

  static Map<String, dynamic> _getMapList(SharedPreferences prefs, String key) {
    final str = prefs.getString(key);
    if (str == null) return {};
    return Map<String, dynamic>.from(jsonDecode(str));
  }
}

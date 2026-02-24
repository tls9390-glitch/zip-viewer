import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../services/zip_service.dart';
import '../services/bookmark_service.dart';
import 'viewer_screen.dart';
import 'file_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _recentFiles = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _loadRecent() async {
    final recent = await BookmarkService.getRecentFiles();
    final valid = recent.where((f) => File(f).existsSync()).toList();
    if (mounted) setState(() => _recentFiles = valid);
  }

  Future<void> _openFileBrowser() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FileBrowserScreen()),
    );
    if (result != null) await _openFile(result);
  }

  Future<void> _openFile(String filePath) async {
    setState(() => _loading = true);
    try {
      final images = await ZipService.extractImages(filePath);
      if (images.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 파일이 없습니다.')),
          );
        }
        return;
      }
      final lastPage = await BookmarkService.getLastPage(filePath);
      await BookmarkService.addRecentFile(filePath);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewerScreen(
              filePath: filePath,
              images: images,
              initialPage: lastPage,
            ),
          ),
        );
        _loadRecent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: Color(0xFFE8B86D), size: 26),
            SizedBox(width: 10),
            Text('ZIP Viewer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE8B86D)),
                  SizedBox(height: 16),
                  Text('읽는 중...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _openFileBrowser,
                    icon: const Icon(Icons.folder_open, size: 22),
                    label: const Text('ZIP / CBZ 파일 열기',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8B86D),
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('지원: .zip .cbz',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                if (_recentFiles.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Color(0xFFE8B86D), size: 18),
                        SizedBox(width: 8),
                        Text('최근 파일',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _recentFiles.length,
                      itemBuilder: (ctx, i) {
                        final path = _recentFiles[i];
                        return Dismissible(
                          key: Key(path),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red.withOpacity(0.3),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.red),
                          ),
                          onDismissed: (_) async {
                            await BookmarkService.removeRecentFile(path);
                            _loadRecent();
                          },
                          child: ListTile(
                            leading: const Icon(Icons.archive,
                                color: Color(0xFFE8B86D)),
                            title: Text(p.basename(path),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(path,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.white30),
                            onTap: () => _openFile(path),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Center(
                      child: Text('파일 열기 버튼을 눌러 ZIP 파일을 선택하세요',
                          style:
                              TextStyle(color: Colors.white30, fontSize: 14)),
                    ),
                  ),
              ],
            ),
    );
  }
}

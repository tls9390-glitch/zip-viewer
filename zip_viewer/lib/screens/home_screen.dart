import 'dart:io';
import 'package:flutter/material.dart';
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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
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
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book, size: 80, color: Color(0xFFE8B86D)),
                    const SizedBox(height: 24),
                    const Text('ZIP Viewer',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('ZIP, CBZ 압축파일 이미지 뷰어',
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openFileBrowser,
                        icon: const Icon(Icons.folder_open, size: 24),
                        label: const Text('파일 열기',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8B86D),
                          foregroundColor: const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('지원 형식: .zip  .cbz  .cbr',
                        style: TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
            ),
    );
  }
}

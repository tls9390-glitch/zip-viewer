import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../services/zip_service.dart';
import '../services/bookmark_service.dart';
import '../models/archive_entry.dart';
import 'viewer_screen.dart';

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
  }

  Future<void> _loadRecent() async {
    final recent = await BookmarkService.getRecentFiles();
    // 실제 존재하는 파일만 필터링
    final valid = recent.where((f) => File(f).existsSync()).toList();
    if (mounted) setState(() => _recentFiles = valid);
  }

  Future<void> _pickAndOpenFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'cbz', 'cbr'],
    );

    if (result == null || result.files.single.path == null) return;
    await _openFile(result.files.single.path!);
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

  Future<void> _removeRecent(String filePath) async {
    await BookmarkService.removeRecentFile(filePath);
    _loadRecent();
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
            Text(
              'ZIP Viewer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE8B86D)),
                  SizedBox(height: 16),
                  Text('압축 파일 읽는 중...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Column(
              children: [
                // 파일 열기 버튼
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _pickAndOpenFile,
                    icon: const Icon(Icons.folder_open, size: 22),
                    label: const Text(
                      'ZIP / CBZ 파일 열기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8B86D),
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // 지원 형식 안내
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _formatChip('.zip'),
                      const SizedBox(width: 8),
                      _formatChip('.cbz'),
                      const SizedBox(width: 8),
                      _formatChip('.cbr'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 최근 파일 목록
                if (_recentFiles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFFE8B86D), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          '최근 파일',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _recentFiles.length,
                      itemBuilder: (ctx, i) => _recentFileTile(_recentFiles[i]),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '최근 파일이 없습니다',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _formatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  Widget _recentFileTile(String filePath) {
    final name = p.basename(filePath);
    return Dismissible(
      key: Key(filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.withOpacity(0.3),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => _removeRecent(filePath),
      child: ListTile(
        leading: const Icon(Icons.archive, color: Color(0xFFE8B86D)),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          filePath,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
        onTap: () => _openFile(filePath),
      ),
    );
  }
}

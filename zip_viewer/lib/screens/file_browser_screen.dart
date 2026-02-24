import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  Directory? _currentDir;
  List<FileSystemEntity> _entities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  Future<void> _initDir() async {
    // 내부 저장소 시작
    Directory startDir;
    try {
      startDir = Directory('/storage/emulated/0');
      if (!await startDir.exists()) {
        startDir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      startDir = await getApplicationDocumentsDirectory();
    }
    _navigateTo(startDir);
  }

  Future<void> _navigateTo(Directory dir) async {
    setState(() => _loading = true);
    try {
      final entities = dir.listSync(followLinks: false);
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return p.basename(a.path).toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase());
      });
      // ZIP/CBZ 파일과 폴더만 표시
      final filtered = entities.where((e) {
        if (e is Directory) return true;
        final ext = p.extension(e.path).toLowerCase();
        return ext == '.zip' || ext == '.cbz' || ext == '.cbr';
      }).toList();

      setState(() {
        _currentDir = dir;
        _entities = filtered;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('접근 불가: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          _currentDir != null ? p.basename(_currentDir!.path) : '파일 선택',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentDir != null) {
              final parent = _currentDir!.parent;
              if (parent.path != _currentDir!.path) {
                _navigateTo(parent);
              } else {
                Navigator.pop(context);
              }
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _currentDir?.path ?? '',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8B86D)))
          : _entities.isEmpty
              ? const Center(
                  child: Text('ZIP/CBZ 파일이 없습니다',
                      style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  itemCount: _entities.length,
                  itemBuilder: (ctx, i) {
                    final entity = _entities[i];
                    final isDir = entity is Directory;
                    final name = p.basename(entity.path);
                    final ext = p.extension(entity.path).toLowerCase();

                    return ListTile(
                      leading: Icon(
                        isDir
                            ? Icons.folder
                            : ext == '.zip'
                                ? Icons.archive
                                : Icons.menu_book,
                        color: isDir
                            ? const Color(0xFFE8B86D)
                            : Colors.lightBlueAccent,
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      onTap: () {
                        if (isDir) {
                          _navigateTo(entity as Directory);
                        } else {
                          Navigator.pop(context, entity.path);
                        }
                      },
                    );
                  },
                ),
    );
  }
}

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
  bool _sortByName = true; // 정렬 기준 상태 변수 (true: 이름순, false: 날짜순)

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
        
        // 폴더를 항상 상단에 배치
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        
        // 사용자가 선택한 기준에 따라 정렬 적용
        if (_sortByName) {
          // 이름 오름차순
          return p.basename(a.path).toLowerCase()
              .compareTo(p.basename(b.path).toLowerCase());
        } else {
          // 수정된 날짜 내림차순 (최신 파일이 위로)
          final aStat = a.statSync();
          final bStat = b.statSync();
          return bStat.modified.compareTo(aStat.modified);
        }
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
        actions: [
          // 상단바 우측에 정렬 메뉴 버튼 추가
          PopupMenuButton<bool>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (bool isNameSort) {
              setState(() {
                _sortByName = isNameSort;
                if (_currentDir != null) {
                  _navigateTo(_currentDir!); // 선택한 정렬 기준으로 새로고침
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: true,
                child: Text('이름순'),
              ),
              const PopupMenuItem(
                value: false,
                child: Text('수정된 날짜순 (최신순)'),
              ),
            ],
          ),
        ],
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
                      style: TextStyle(color: Colors.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:path/path.dart' as p;
import '../models/archive_entry.dart';
import '../services/bookmark_service.dart';

class ViewerScreen extends StatefulWidget {
  final String filePath;
  final List<ArchiveEntry> images;
  final int initialPage;

  const ViewerScreen({
    super.key,
    required this.filePath,
    required this.images,
    required this.initialPage,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _pageController;
  late int _currentPage;
  bool _showUI = true;
  bool _isBookmarked = false;
  List<int> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage);
    _loadBookmarks();
    // 전체화면 몰입 모드
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // 마지막 페이지 저장
    BookmarkService.saveLastPage(widget.filePath, _currentPage);
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final bm = await BookmarkService.getBookmarks(widget.filePath);
    final isBm = await BookmarkService.isBookmarked(widget.filePath, _currentPage);
    if (mounted) setState(() {
      _bookmarks = bm;
      _isBookmarked = isBm;
    });
  }

  Future<void> _toggleBookmark() async {
    final result = await BookmarkService.toggleBookmark(widget.filePath, _currentPage);
    final bm = await BookmarkService.getBookmarks(widget.filePath);
    if (mounted) setState(() {
      _isBookmarked = result;
      _bookmarks = bm;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ? '북마크 추가됨 🔖' : '북마크 제거됨'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF2A2A2A),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isBookmarked = _bookmarks.contains(page);
    });
    BookmarkService.saveLastPage(widget.filePath, page);
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    Navigator.pop(context);
  }

  void _showBookmarkList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '북마크 목록',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_bookmarks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('북마크가 없습니다', style: TextStyle(color: Colors.white54)),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _bookmarks.length,
                itemBuilder: (_, i) {
                  final page = _bookmarks[i];
                  return ListTile(
                    leading: const Icon(Icons.bookmark, color: Color(0xFFE8B86D)),
                    title: Text(
                      '${page + 1}페이지 - ${widget.images[page].fileName}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () => _goToPage(page),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showPageJump() {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: '${_currentPage + 1}');
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('페이지 이동', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '1 ~ ${widget.images.length}',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE8B86D)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final page = (int.tryParse(controller.text) ?? 1) - 1;
                final clamped = page.clamp(0, widget.images.length - 1);
                Navigator.pop(ctx);
                _pageController.jumpToPage(clamped);
              },
              child: const Text('이동', style: TextStyle(color: Color(0xFFE8B86D))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(widget.filePath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 이미지 갤러리 (핀치줌 + 스와이프)
          GestureDetector(
            onTap: _toggleUI,
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.images.length,
              onPageChanged: _onPageChanged,
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (context, index) {
                final entry = widget.images[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: MemoryImage(Uint8List.fromList(entry.bytes)),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4.0,
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: 'image_$index'),
                );
              },
              loadingBuilder: (_, event) => Center(
                child: CircularProgressIndicator(
                  value: event?.expectedTotalBytes != null
                      ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                      : null,
                  color: const Color(0xFFE8B86D),
                ),
              ),
            ),
          ),

          // 상단 UI (파일명, 닫기)
          AnimatedOpacity(
            opacity: _showUI ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showUI,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: _isBookmarked ? const Color(0xFFE8B86D) : Colors.white,
                          ),
                          onPressed: _toggleBookmark,
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmarks_outlined, color: Colors.white),
                          onPressed: _showBookmarkList,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 하단 UI (페이지 표시, 슬라이더)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showUI,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    children: [
                      // 페이지 슬라이더
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFE8B86D),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFFE8B86D),
                          overlayColor: const Color(0xFFE8B86D).withOpacity(0.2),
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _currentPage.toDouble(),
                          min: 0,
                          max: (widget.images.length - 1).toDouble(),
                          onChanged: (v) {
                            _pageController.jumpToPage(v.round());
                          },
                        ),
                      ),
                      // 페이지 번호
                      GestureDetector(
                        onTap: _showPageJump,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            '${_currentPage + 1} / ${widget.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

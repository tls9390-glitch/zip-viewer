import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../models/archive_entry.dart';

class ZipService {
  static const List<String> _imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'
  ];

  static Future<List<ArchiveEntry>> extractImages(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('파일을 찾을 수 없습니다.');

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final List<ArchiveEntry> images = [];

    for (final entry in archive) {
      if (entry.isFile) {
        final ext = p.extension(entry.name).toLowerCase();
        if (_imageExtensions.contains(ext)) {
          images.add(ArchiveEntry(
            name: entry.name,
            fileName: p.basename(entry.name),
            bytes: entry.content as List<int>,
          ));
        }
      }
    }

    images.sort((a, b) => _naturalSort(a.name, b.name));
    return images;
  }

  static int _naturalSort(String a, String b) {
    final reg = RegExp(r'(\d+)|(\D+)');
    final am = reg.allMatches(a).toList();
    final bm = reg.allMatches(b).toList();
    for (int i = 0; i < am.length && i < bm.length; i++) {
      final as_ = am[i].group(0)!;
      final bs_ = bm[i].group(0)!;
      final an = int.tryParse(as_);
      final bn = int.tryParse(bs_);
      int cmp = (an != null && bn != null) ? an.compareTo(bn) : as_.compareTo(bs_);
      if (cmp != 0) return cmp;
    }
    return am.length.compareTo(bm.length);
  }
}

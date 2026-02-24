import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../models/archive_entry.dart';

class ZipService {
  static const List<String> _imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'
  ];

  /// ZIP/CBZ 파일을 열고 이미지만 추출하여 파일명 순서로 정렬
  static Future<List<ArchiveEntry>> extractImages(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('파일을 찾을 수 없습니다: $filePath');
    }

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

    // 파일 전체 경로 기준으로 자연스러운 정렬 (숫자 포함)
    images.sort((a, b) => _naturalSort(a.name, b.name));

    return images;
  }

  /// 자연스러운 정렬: "2.jpg" < "10.jpg" 처럼 숫자를 숫자로 비교
  static int _naturalSort(String a, String b) {
    final regExp = RegExp(r'(\d+)|(\D+)');
    final aMatches = regExp.allMatches(a).toList();
    final bMatches = regExp.allMatches(b).toList();

    for (int i = 0; i < aMatches.length && i < bMatches.length; i++) {
      final aStr = aMatches[i].group(0)!;
      final bStr = bMatches[i].group(0)!;
      final aNum = int.tryParse(aStr);
      final bNum = int.tryParse(bStr);

      int cmp;
      if (aNum != null && bNum != null) {
        cmp = aNum.compareTo(bNum);
      } else {
        cmp = aStr.compareTo(bStr);
      }
      if (cmp != 0) return cmp;
    }
    return aMatches.length.compareTo(bMatches.length);
  }

  /// 지원하는 파일 확장자인지 확인
  static bool isSupportedFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.zip' || ext == '.cbz' || ext == '.cbr';
  }
}

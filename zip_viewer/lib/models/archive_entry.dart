class ArchiveEntry {
  final String name;       // 압축파일 전체 경로 (정렬용)
  final String fileName;   // 파일명만
  final List<int> bytes;   // 이미지 바이트 데이터

  ArchiveEntry({
    required this.name,
    required this.fileName,
    required this.bytes,
  });
}

class ZipBook {
  final String filePath;
  final String fileName;
  final List<ArchiveEntry> images;
  int lastPage;

  ZipBook({
    required this.filePath,
    required this.fileName,
    required this.images,
    this.lastPage = 0,
  });

  int get pageCount => images.length;
}

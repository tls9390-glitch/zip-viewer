class ArchiveEntry {
  final String name;
  final String fileName;
  final List<int> bytes;

  ArchiveEntry({
    required this.name,
    required this.fileName,
    required this.bytes,
  });
}

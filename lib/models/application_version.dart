class ApplicationVersion {
  final String name;
  final String versionName;
  final int versionCode;
  final String description;
  final DateTime releaseDate;
  final String author;
  final List<String> updateNotes;
  final String updateUrl;

  ApplicationVersion({
    required this.name,
    required this.versionName,
    required this.versionCode,
    required this.description,
    required this.releaseDate,
    required this.author,
    required this.updateNotes,
    required this.updateUrl,
  });

  factory ApplicationVersion.fromJson(Map<String, dynamic> json) {
    return ApplicationVersion(
      name: json['name'] as String,
      versionName: json['versionName'] as String,
      versionCode: json['versionCode'] as int,
      description: json['description'] as String,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      author: json['author'] as String,
      updateNotes: List<String>.from(json['updateNotes'] as List),
      updateUrl: json['updateUrl'] as String,
    );
  }
}

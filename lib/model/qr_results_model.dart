class QrResults {
  final String? code;
  late final String? format;

  QrResults({this.code, this.format});

  factory QrResults.fromJson(Map<String, dynamic> json) {
    return QrResults(
      code: json['code'],
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'format': format,
    };
  }
}

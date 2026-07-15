/// Model for financial insight data from the API.
class InsightModel {
  final String type;
  final String severity; // 'danger', 'warning', 'info'
  final String title;
  final String message;
  final String icon; // emoji

  const InsightModel({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.icon,
  });

  factory InsightModel.fromJson(Map<String, dynamic> json) {
    return InsightModel(
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      icon: json['icon'] as String? ?? '💡',
    );
  }

  /// Background color based on severity.
  /// Returns a hex-like description for the UI layer to interpret.
  String get severityLabel {
    switch (severity) {
      case 'danger':
        return 'Bahaya';
      case 'warning':
        return 'Peringatan';
      default:
        return 'Info';
    }
  }
}

class Complaint {
  final String id;
  final String title;
  final String description;
  final String image;
  final double latitude;
  final double longitude;
  final String status;
  final String createdBy;
  final String? assignedEngineerId;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;
  final int reportCount;
  final String? resolutionImage;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdBy,
    this.assignedEngineerId,
    required this.createdAt,
    this.verifiedAt,
    this.assignedAt,
    this.resolvedAt,
    this.reportCount = 1,
    this.resolutionImage,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      latitude: json['location']['latitude'].toDouble(),
      longitude: json['location']['longitude'].toDouble(),
      status: json['status'],
      createdBy: json['createdBy'] is Map ? json['createdBy']['name'] : json['createdBy'],
      assignedEngineerId: json['assignedEngineerId'] is Map ? json['assignedEngineerId']['name'] : json['assignedEngineerId'],
      reportCount: json['reportCount'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
      assignedAt: json['assignedAt'] != null ? DateTime.parse(json['assignedAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolutionImage: json['resolutionImage'],
    );
  }

  int get daysTaken {
    if (resolvedAt == null) return DateTime.now().difference(createdAt).inDays;
    return resolvedAt!.difference(createdAt).inDays;
  }
}

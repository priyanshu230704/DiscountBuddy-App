/// Safe int parser that handles both int and String values
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Safe double parser that handles both num and String values
double? _safeDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Safe bool parser
bool _safeBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return fallback;
}

/// Section score for a mystery visit
class MysteryScore {
  final int id;
  final String section;
  final String sectionDisplay;
  final int score;
  final String comment;

  MysteryScore({
    required this.id,
    required this.section,
    required this.sectionDisplay,
    required this.score,
    required this.comment,
  });

  factory MysteryScore.fromJson(Map<String, dynamic> json) {
    return MysteryScore(
      id: _safeInt(json['id']),
      section: json['section']?.toString() ?? '',
      sectionDisplay: json['section_display']?.toString() ?? '',
      score: _safeInt(json['score']),
      comment: json['comment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section': section,
      'section_display': sectionDisplay,
      'score': score,
      'comment': comment,
    };
  }
}

/// Evidence uploaded for a mystery visit
class MysteryEvidence {
  final int id;
  final String file;
  final String fileUrl;
  final String description;
  final DateTime createdAt;

  MysteryEvidence({
    required this.id,
    required this.file,
    required this.fileUrl,
    required this.description,
    required this.createdAt,
  });

  factory MysteryEvidence.fromJson(Map<String, dynamic> json) {
    return MysteryEvidence(
      id: _safeInt(json['id']),
      file: json['file']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file': file,
      'file_url': fileUrl,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Mystery Visit model
class MysteryVisit {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String restaurantCity;
  final String restaurantSlug;
  final int mysteryGuestId;
  final DateTime scheduledFor;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final String status;
  final double? overallScore;
  final bool isRiskFlagged;
  final String comments;
  final List<MysteryScore> scores;
  final List<MysteryEvidence> evidence;
  final DateTime createdAt;

  MysteryVisit({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantCity,
    required this.restaurantSlug,
    required this.mysteryGuestId,
    required this.scheduledFor,
    this.startedAt,
    this.submittedAt,
    required this.status,
    this.overallScore,
    this.isRiskFlagged = false,
    this.comments = '',
    this.scores = const [],
    this.evidence = const [],
    required this.createdAt,
  });

  factory MysteryVisit.fromJson(Map<String, dynamic> json) {
    return MysteryVisit(
      id: _safeInt(json['id']),
      restaurantId: _safeInt(json['restaurant']),
      restaurantName: json['restaurant_name']?.toString() ?? '',
      restaurantCity: json['restaurant_city']?.toString() ?? '',
      restaurantSlug: json['restaurant_slug']?.toString() ?? '',
      mysteryGuestId: _safeInt(json['mystery_guest']),
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.tryParse(json['scheduled_for'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      status: json['status']?.toString() ?? 'assigned',
      overallScore: _safeDouble(json['overall_score']),
      isRiskFlagged: _safeBool(json['is_risk_flagged']),
      comments: json['comments']?.toString() ?? '',
      scores:
          (json['scores'] as List<dynamic>?)
              ?.map((e) => MysteryScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      evidence:
          (json['evidence'] as List<dynamic>?)
              ?.map((e) => MysteryEvidence.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant': restaurantId,
      'restaurant_name': restaurantName,
      'restaurant_city': restaurantCity,
      'restaurant_slug': restaurantSlug,
      'mystery_guest': mysteryGuestId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'status': status,
      'overall_score': overallScore,
      'is_risk_flagged': isRiskFlagged,
      'comments': comments,
      'scores': scores.map((e) => e.toJson()).toList(),
      'evidence': evidence.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

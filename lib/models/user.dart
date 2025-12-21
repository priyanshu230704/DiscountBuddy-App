/// User model
class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final Membership membership;
  final double totalSavings;
  final int restaurantsVisited;
  final DateTime? membershipExpiryDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.membership,
    this.profileImageUrl,
    this.totalSavings = 0.0,
    this.restaurantsVisited = 0,
    this.membershipExpiryDate,
  });

  bool get isMembershipActive {
    if (membershipExpiryDate == null) return false;
    return membershipExpiryDate!.isAfter(DateTime.now());
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      membership: Membership.fromJson(json['membership'] as Map<String, dynamic>),
      totalSavings: (json['totalSavings'] as num?)?.toDouble() ?? 0.0,
      restaurantsVisited: json['restaurantsVisited'] as int? ?? 0,
      membershipExpiryDate: json['membershipExpiryDate'] != null
          ? DateTime.parse(json['membershipExpiryDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'membership': membership.toJson(),
      'totalSavings': totalSavings,
      'restaurantsVisited': restaurantsVisited,
      'membershipExpiryDate': membershipExpiryDate?.toIso8601String(),
    };
  }
}

/// Membership model
class Membership {
  final String membershipId;
  final String tier; // 'basic', 'premium'
  final DateTime startDate;
  final DateTime expiryDate;
  final String status; // 'active', 'expired', 'cancelled'

  Membership({
    required this.membershipId,
    required this.tier,
    required this.startDate,
    required this.expiryDate,
    required this.status,
  });

  bool get isActive => status == 'active' && expiryDate.isAfter(DateTime.now());

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      membershipId: json['membershipId'] as String,
      tier: json['tier'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membershipId': membershipId,
      'tier': tier,
      'startDate': startDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'status': status,
    };
  }
}


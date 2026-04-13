class RecentActivity {
  final String id;
  final String activityType;
  final String title;
  final String description;
  final String createdAt;
  final Broker broker;

  RecentActivity({
    required this.id,
    required this.activityType,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.broker,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'],
      activityType: json['activityType'],
      title: json['title'],
      description: json['description'],
      createdAt: json['createdAt'],
      broker: Broker.fromJson(json['broker']),
    );
  }
}

class Broker {
  final String id;
  final String displayName;
  final String email;
  final String? avatar;
  final String approvalStatus;
  final bool isVerified;

  Broker({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatar,
    required this.approvalStatus,
    required this.isVerified,
  });

  factory Broker.fromJson(Map<String, dynamic> json) {
    return Broker(
      id: json['id'],
      displayName: json['displayName'],
      email: json['email'],
      avatar: json['avatar'],
      approvalStatus: json['approvalStatus'],
      isVerified: json['isVerified'],
    );
  }
}

class Pagination {
  final int page;
  final int totalPages;

  Pagination({
    required this.page,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      totalPages: json['totalPages'],
    );
  }
}

class ActivityResponse {
  final List<RecentActivity> activities;
  final Pagination pagination;

  ActivityResponse({
    required this.activities,
    required this.pagination,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> json) {
    return ActivityResponse(
      activities: (json['data'] as List)
          .map((e) => RecentActivity.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}
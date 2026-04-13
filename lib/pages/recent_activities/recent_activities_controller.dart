import 'package:a2abrokerapp/pages/recent_activities/recent_activities_model.dart';
import 'package:a2abrokerapp/pages/recent_activities/recent_activities_service.dart';

class RecentActivitiesController {
  final RecentActivitiesService _service = RecentActivitiesService();

  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  List<RecentActivity> activities = [];



  Future<void> loadActivities() async {
    if (isLoading || !hasMore) return;

    isLoading = true;

    final response = await _service.fetchActivities(currentPage);

    activities.addAll(response.activities);

    hasMore = currentPage < response.pagination.totalPages;
    currentPage++;

    isLoading = false;
  }
}
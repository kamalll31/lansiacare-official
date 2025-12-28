import 'package:flutter/material.dart';

class RecentActivities extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const RecentActivities({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Center(
                child: Text(
                  'No activities yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...activities.map((activity) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getActivityColor(activity['type']),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getActivityIcon(activity['type']),
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    activity['title'] ?? 'Activity',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(activity['description'] ?? ''),
                  trailing: Text(
                    activity['time'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.blue;
      case 'create':
        return Colors.purple;
      case 'update':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.notifications;
    }
  }
}
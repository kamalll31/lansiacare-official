import 'package:flutter/material.dart';

class EmergencyAlerts extends StatelessWidget {
  final List<Map<String, dynamic>> emergencies;

  const EmergencyAlerts({
    super.key,
    required this.emergencies,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Emergency Alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (emergencies.isEmpty)
              const Center(
                child: Text(
                  'No emergency alerts',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...emergencies.map((alert) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emergency,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['title'] ?? 'Emergency',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert['description'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert['time'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
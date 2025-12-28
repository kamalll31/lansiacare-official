import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/activities_service.dart';
import 'package:lansiacare/src/shared/models/activity_model.dart';
import 'package:lansiacare/src/features/activities/screens/activity_detail_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Activity> _activities = [];
  List<Activity> _upcomingActivities = [];
  ActivityStats _stats = ActivityStats(totalRegistered: 0, upcomingCount: 0, attendedCount: 0);
  bool _isLoading = true;
  String _error = '';
  String _selectedFilter = 'semua';

  final Map<String, String> _activityTypes = {
    'semua': 'Semua',
    'komunitas': 'Komunitas',
    'keluarga': 'Keluarga', 
    'kesehatan': 'Kesehatan',
    'lainnya': 'Lainnya',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final activitiesResponse = await ActivitiesService.getActivities();
      final upcomingResponse = await ActivitiesService.getUpcomingActivities();
      final stats = await ActivitiesService.getActivityStats();

      setState(() {
        _activities = activitiesResponse.activities;
        _upcomingActivities = upcomingResponse.upcomingActivities;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() {
        _error = 'Gagal memuat data aktivitas: $e';
        _isLoading = false;
      });
    }
  }

  List<Activity> get _filteredActivities {
    if (_selectedFilter == 'semua') {
      return _activities;
    }
    return _activities.where((activity) => activity.activityType == _selectedFilter).toList();
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'komunitas':
        return Colors.orange;
      case 'keluarga':
        return Colors.green;
      case 'kesehatan':
        return Colors.blue;
      case 'lainnya':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'komunitas':
        return Icons.group;
      case 'keluarga':
        return Icons.family_restroom;
      case 'kesehatan':
        return Icons.medical_services;
      case 'lainnya':
        return Icons.event;
      default:
        return Icons.calendar_today;
    }
  }

  void _showActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activityId: activity.id),
      ),
    ).then((_) {
      // Refresh data ketika kembali dari detail
      _loadData();
    });
  }

  Future<void> _handleRegistration(Activity activity) async {
    try {
      if (activity.isRegistered) {
        await ActivitiesService.cancelRegistration(activity.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil dibatalkan'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await ActivitiesService.registerActivity(activity.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil mendaftar aktivitas'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Refresh data
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kegiatan & Acara'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semua Kegiatan'),
            Tab(text: 'Akan Datang'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat kegiatan...'),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Semua Kegiatan
                    Column(
                      children: [
                        // Stats Cards
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Terdaftar',
                                  _stats.totalRegistered.toString(),
                                  Icons.event_available,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Akan Datang',
                                  _stats.upcomingCount.toString(),
                                  Icons.upcoming,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Diikuti',
                                  _stats.attendedCount.toString(),
                                  Icons.check_circle,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Filter Chips
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _activityTypes.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(entry.value),
                                    selected: _selectedFilter == entry.key,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedFilter = selected ? entry.key : 'semua';
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // Activities List
                        Expanded(
                          child: _filteredActivities.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tidak ada kegiatan',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Kegiatan akan muncul di sini',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadData,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredActivities.length,
                                    itemBuilder: (context, index) {
                                      final activity = _filteredActivities[index];
                                      return _buildActivityCard(activity);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),

                    // Tab 2: Akan Datang
                    _upcomingActivities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upcoming,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada kegiatan mendatang',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Daftarkan diri Anda pada kegiatan yang tersedia',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _upcomingActivities.length,
                              itemBuilder: (context, index) {
                                final activity = _upcomingActivities[index];
                                return _buildActivityCard(activity);
                              },
                            ),
                          ),
                  ],
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final dateTime = DateTime.parse(activity.startTime);
    final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getActivityColor(activity.activityType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActivityIcon(activity.activityType),
            color: _getActivityColor(activity.activityType),
            size: 24,
          ),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(activity.description.length > 60 
                ? '${activity.description.substring(0, 60)}...' 
                : activity.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$formattedDate $formattedTime', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(activity.location.length > 20 
                    ? '${activity.location.substring(0, 20)}...' 
                    : activity.location, 
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (activity.maxParticipants != null) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: activity.currentParticipants / activity.maxParticipants!,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  activity.availableSlots! > 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${activity.currentParticipants}/${activity.maxParticipants} peserta',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: activity.isRegistered
            ? ElevatedButton(
                onPressed: () => _handleRegistration(activity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Batal'),
              )
            : ElevatedButton(
                onPressed: activity.availableSlots != null && activity.availableSlots! <= 0
                    ? null
                    : () => _handleRegistration(activity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Daftar'),
              ),
        onTap: () => _showActivityDetail(activity),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
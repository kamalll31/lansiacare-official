import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/activities_service.dart';
import 'package:lansiacare/src/shared/models/activity_model.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  _ActivityDetailScreenState createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  ActivityDetail? _activity;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadActivityDetail();
  }

  Future<void> _loadActivityDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final activity = await ActivitiesService.getActivityDetail(widget.activityId);
      setState(() {
        _activity = activity;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activity detail: $e');
      setState(() {
        _error = 'Gagal memuat detail aktivitas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegistration() async {
    if (_activity == null) return;

    try {
      if (_activity!.isRegistered) {
        await ActivitiesService.cancelRegistration(_activity!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil dibatalkan'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await ActivitiesService.registerActivity(_activity!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil mendaftar aktivitas'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Refresh data
      _loadActivityDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kegiatan'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivityDetail,
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
                  Text('Memuat detail kegiatan...'),
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
                        onPressed: _loadActivityDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _activity == null
                  ? const Center(
                      child: Text('Data kegiatan tidak ditemukan'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _getActivityColor(_activity!.activityType).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getActivityIcon(_activity!.activityType),
                                      color: _getActivityColor(_activity!.activityType),
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _activity!.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getActivityColor(_activity!.activityType).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _activity!.activityType.toUpperCase(),
                                      style: TextStyle(
                                        color: _getActivityColor(_activity!.activityType),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Description
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Deskripsi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _activity!.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Activity Details
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Detail Kegiatan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailItem(
                                    Icons.calendar_today,
                                    'Waktu Mulai',
                                    _formatDateTime(_activity!.startTime),
                                  ),
                                  if (_activity!.endTime != null)
                                    _buildDetailItem(
                                      Icons.timer_off,
                                      'Waktu Selesai',
                                      _formatDateTime(_activity!.endTime!),
                                    ),
                                  _buildDetailItem(
                                    Icons.location_on,
                                    'Lokasi',
                                    _activity!.location,
                                  ),
                                  if (_activity!.maxParticipants != null)
                                    _buildDetailItem(
                                      Icons.people,
                                      'Peserta',
                                      '${_activity!.currentParticipants}/${_activity!.maxParticipants} orang',
                                    ),
                                  if (_activity!.isRecurring)
                                    _buildDetailItem(
                                      Icons.repeat,
                                      'Berulang',
                                      'Ya',
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Participants
                          if (_activity!.participants.isNotEmpty) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Peserta Terdaftar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_activity!.participants.length} peserta',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ..._activity!.participants.map((participant) => 
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue[100],
                                          child: Icon(Icons.person, color: Colors.blue[600]),
                                        ),
                                        title: Text(participant.userName),
                                        subtitle: Text('Terdaftar: ${_formatDate(participant.registeredAt)}'),
                                      )
                                    ).toList(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _activity!.isRegistered ? Colors.orange : Colors.blue[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                _activity!.isRegistered ? 'Batalkan Pendaftaran' : 'Daftar Sekarang',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
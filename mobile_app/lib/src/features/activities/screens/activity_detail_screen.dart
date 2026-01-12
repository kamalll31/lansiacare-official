import 'package:flutter/material.dart';
import '../../../shared/services/activities_service.dart';
import '../../../shared/models/activity_model.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
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
      
      // FIX: Cek mounted sebelum setState
      if (mounted) {
        setState(() {
          _activity = activity;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat detail aktivitas: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegistration() async {
    if (_activity == null) return;

    try {
      if (_activity!.isRegistered) {
        // Batal Daftar
        await ActivitiesService.cancelRegistration(_activity!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran berhasil dibatalkan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Daftar Baru
        await ActivitiesService.registerActivity(_activity!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil mendaftar aktivitas'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      // Refresh data untuk update status & slot
      _loadActivityDetail();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'komunitas': return Colors.orange;
      case 'keluarga': return Colors.green;
      case 'kesehatan': return Colors.blue;
      case 'lainnya': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'komunitas': return Icons.group;
      case 'keluarga': return Icons.family_restroom;
      case 'kesehatan': return Icons.medical_services;
      case 'lainnya': return Icons.event;
      default: return Icons.calendar_today;
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
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadActivityDetail, child: const Text("Coba Lagi"))
                      ],
                    ),
                  ),
                )
              : _activity == null
                  ? const Center(child: Text('Data tidak ditemukan'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. HEADER (ICON & JUDUL)
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: _getActivityColor(_activity!.activityType).withOpacity(0.1),
                                  child: Icon(
                                    _getActivityIcon(_activity!.activityType),
                                    size: 40,
                                    color: _getActivityColor(_activity!.activityType),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _activity!.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text(_activity!.activityType.toUpperCase()),
                                  backgroundColor: _getActivityColor(_activity!.activityType).withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: _getActivityColor(_activity!.activityType),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 2. INFO CARDS
                          _buildSectionTitle("Informasi"),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildInfoRow(Icons.calendar_today, "Mulai", _formatDateTime(_activity!.startTime)),
                                  if (_activity!.endTime != null)
                                    _buildInfoRow(Icons.access_time, "Selesai", _formatDateTime(_activity!.endTime!)),
                                  _buildInfoRow(Icons.location_on, "Lokasi", _activity!.location),
                                  if (_activity!.maxParticipants != null)
                                    _buildInfoRow(Icons.people, "Kuota", 
                                      "${_activity!.currentParticipants} / ${_activity!.maxParticipants} Peserta"),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3. DESCRIPTION
                          _buildSectionTitle("Deskripsi"),
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _activity!.description,
                                style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4. PARTICIPANTS LIST (Jika ada)
                          if (_activity!.participants.isNotEmpty) ...[
                            _buildSectionTitle("Peserta Terdaftar (${_activity!.participants.length})"),
                            Card(
                              elevation: 2,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _activity!.participants.length,
                                separatorBuilder: (ctx, i) => const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final p = _activity!.participants[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[50],
                                      child: Text(
                                        p.userName.isNotEmpty ? p.userName[0].toUpperCase() : '?',
                                        style: TextStyle(color: Colors.blue[800]),
                                      ),
                                    ),
                                    title: Text(p.userName),
                                    subtitle: Text("Daftar: ${_formatDate(p.registeredAt)}"),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 5. ACTION BUTTON (LOGIKA DIPERBAIKI)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              // Disable tombol jika penuh DAN user belum terdaftar
                              onPressed: (_activity!.availableSlots != null && 
                                          _activity!.availableSlots! <= 0 && 
                                          !_activity!.isRegistered)
                                  ? null 
                                  : _handleRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _activity!.isRegistered ? Colors.orange : Colors.blue[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[600],
                              ),
                              child: Text(
                                _activity!.isRegistered 
                                    ? "Batalkan Pendaftaran" 
                                    : (_activity!.availableSlots != null && _activity!.availableSlots! <= 0) 
                                        ? "Kuota Penuh" 
                                        : "Daftar Sekarang",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.day}/${dt.month}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (e) {
      return isoString;
    }
  }
}
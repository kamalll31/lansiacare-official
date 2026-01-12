import 'package:flutter/material.dart';
import '../../../shared/services/activities_service.dart';
import '../../../shared/models/activity_model.dart';
import 'activity_detail_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    // Kita punya 2 Tab Utama: Jadwal Harian (Personal) & Event Komunitas (Sosial)
    _mainTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas Lansia'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.check_box_outlined), text: 'Jadwal Harian'),
            Tab(icon: Icon(Icons.people_outline), text: 'Event Komunitas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: const [
          _DailyScheduleView(),  // Fitur Baru Fase 5
          _CommunityEventsView(), // Fitur Lama Anda (Dipertahankan)
        ],
      ),
    );
  }
}

// =============================================================================
// 1. VIEW JADWAL HARIAN (PERSONAL & OBAT) - FASE 5
// =============================================================================

class _DailyScheduleView extends StatefulWidget {
  const _DailyScheduleView();

  @override
  State<_DailyScheduleView> createState() => _DailyScheduleViewState();
}

class _DailyScheduleViewState extends State<_DailyScheduleView> {
  List<ActivityItem> _dailyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  Future<void> _loadDaily() async {
    try {
      setState(() => _isLoading = true);
      final data = await ActivitiesService.getDailySchedule();
      setState(() {
        _dailyItems = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading daily: $e");
    }
  }

  Future<void> _toggleItem(ActivityItem item) async {
    // Optimistic Update
    setState(() => item.isCompleted = !item.isCompleted);
    try {
      await ActivitiesService.toggleStatus(item.id, item.type);
    } catch (e) {
      // Revert if fail
      setState(() => item.isCompleted = !item.isCompleted);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update status")));
    }
  }

  Future<void> _deleteItem(ActivityItem item) async {
    try {
      await ActivitiesService.deleteItem(item.id, item.type);
      _loadDaily(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item dihapus")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AddActivityForm(onSaved: () {
          Navigator.pop(context);
          _loadDaily();
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_dailyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.today, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Belum ada jadwal hari ini", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text("Buat Jadwal"),
            )
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDaily,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _dailyItems.length,
          itemBuilder: (context, index) {
            final item = _dailyItems[index];
            final isMedication = item.type == 'medication';

            return Dismissible(
              key: Key('${item.type}_${item.id}'),
              background: Container(
                color: Colors.red, 
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white)
              ),
              confirmDismiss: (dir) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Hapus?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              onDismissed: (dir) => _deleteItem(item),
              child: Card(
                elevation: item.isCompleted ? 0 : 2,
                color: item.isCompleted ? Colors.grey[100] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMedication ? Colors.red[50] : Colors.blue[50],
                    child: Icon(
                      isMedication ? Icons.medication : Icons.fitness_center,
                      color: isMedication ? Colors.red : Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      color: item.isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  subtitle: Text("${item.time} • ${item.description}"),
                  trailing: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: item.isCompleted,
                      shape: const CircleBorder(),
                      activeColor: Colors.green,
                      onChanged: (val) => _toggleItem(item),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Form Tambah (Modal Bottom Sheet)
class _AddActivityForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddActivityForm({required this.onSaved});
  @override
  State<_AddActivityForm> createState() => _AddActivityFormState();
}

class _AddActivityFormState extends State<_AddActivityForm> {
  bool _isMedication = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tambah ${_isMedication ? 'Jadwal Obat' : 'Kegiatan'}", 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Switch Tipe
          Row(
            children: [
              FilterChip(
                label: const Text("Kegiatan"),
                selected: !_isMedication,
                onSelected: (val) => setState(() => _isMedication = false),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text("Minum Obat"),
                selected: _isMedication,
                checkmarkColor: Colors.white,
                selectedColor: Colors.red[100],
                labelStyle: TextStyle(color: _isMedication ? Colors.red[800] : Colors.black),
                onSelected: (val) => setState(() => _isMedication = true),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: _isMedication ? "Nama Obat" : "Nama Kegiatan",
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: _isMedication ? "Dosis (cth: 1 Tablet)" : "Keterangan (cth: Di teras)",
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text("Jam"),
            trailing: Text(_time.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMedication ? Colors.red : Colors.blue[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (_titleController.text.isEmpty) return;
                
                final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
                
                if (_isMedication) {
                  await ActivitiesService.addMedication(_titleController.text, _descController.text, timeStr);
                } else {
                  await ActivitiesService.addActivity(_titleController.text, _descController.text, timeStr);
                }
                widget.onSaved();
              },
              child: const Text("SIMPAN"),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. VIEW EVENT KOMUNITAS (FITUR LAMA ANDA)
// =============================================================================

class _CommunityEventsView extends StatefulWidget {
  const _CommunityEventsView();

  @override
  State<_CommunityEventsView> createState() => _CommunityEventsViewState();
}

class _CommunityEventsViewState extends State<_CommunityEventsView> {
  List<Activity> _activities = [];
  ActivityStats _stats = ActivityStats(totalRegistered: 0, upcomingCount: 0, attendedCount: 0);
  bool _isLoading = true;
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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final activitiesResponse = await ActivitiesService.getActivities();
      final stats = await ActivitiesService.getActivityStats();

      if (!mounted) return;
      setState(() {
        _activities = activitiesResponse.activities;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Activity> get _filteredActivities {
    if (_selectedFilter == 'semua') return _activities;
    return _activities.where((a) => a.activityType == _selectedFilter).toList();
  }

  // --- Helpers UI dari Kode Lama ---
  Color _getActivityColor(String type) {
    switch (type) {
      case 'komunitas': return Colors.orange;
      case 'keluarga': return Colors.green;
      case 'kesehatan': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'komunitas': return Icons.group;
      case 'keluarga': return Icons.family_restroom;
      case 'kesehatan': return Icons.medical_services;
      default: return Icons.event;
    }
  }

  Future<void> _handleRegistration(Activity activity) async {
    try {
      if (activity.isRegistered) {
        await ActivitiesService.cancelRegistration(activity.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batal daftar sukses')));
      } else {
        await ActivitiesService.registerActivity(activity.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil daftar!')));
      }
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // 1. Stats Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildStatCard('Terdaftar', _stats.totalRegistered.toString(), Icons.event_available, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Akan Datang', _stats.upcomingCount.toString(), Icons.upcoming, Colors.orange)),
            ],
          ),
        ),

        // 2. Filters
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _activityTypes.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(entry.value),
                  selected: _selectedFilter == entry.key,
                  onSelected: (selected) => setState(() => _selectedFilter = selected ? entry.key : 'semua'),
                ),
              );
            }).toList(),
          ),
        ),

        // 3. List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _filteredActivities.isEmpty 
              ? const Center(child: Text("Tidak ada event komunitas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredActivities.length,
                  itemBuilder: (context, index) => _buildActivityCard(_filteredActivities[index]),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_getActivityIcon(activity.activityType), color: _getActivityColor(activity.activityType), size: 32),
        title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(activity.location),
        trailing: ElevatedButton(
          onPressed: () => _handleRegistration(activity),
          style: ElevatedButton.styleFrom(
            backgroundColor: activity.isRegistered ? Colors.orange : Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(60, 30),
          ),
          child: Text(activity.isRegistered ? 'Batal' : 'Daftar', style: const TextStyle(fontSize: 12)),
        ),
        onTap: () {
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => ActivityDetailScreen(activityId: activity.id),
               ),
             );
        },
      ),
    );
  }
}
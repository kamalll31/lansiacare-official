import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/family_service.dart';
import 'package:lansiacare/src/shared/services/auth_service.dart';
import 'package:lansiacare/src/shared/models/family_model.dart';

class FamilyConnectionScreen extends StatefulWidget {
  const FamilyConnectionScreen({super.key});

  @override
  _FamilyConnectionScreenState createState() => _FamilyConnectionScreenState();
}

class _FamilyConnectionScreenState extends State<FamilyConnectionScreen> {
  List<FamilyConnection> _connections = [];
  FamilyStats _stats = FamilyStats(totalFamilyMembers: 0, pendingInvitations: 0, monitoredLansia: 0);
  bool _isLoading = true;
  // Menambahkan state loading khusus untuk aksi (terima/hapus) agar tidak memblokir seluruh layar
  bool _isActionLoading = false; 
  String _error = '';
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUserData();
    if (!mounted) return; // Cek mounted di antara call
    await _loadFamilyData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _loadFamilyData() async {
    try {
      // Hanya set loading true jika ini load pertama kali (data kosong)
      // Agar saat pull-to-refresh tidak flicker parah
      if (_connections.isEmpty) {
        setState(() {
          _isLoading = true;
          _error = '';
        });
      }

      final connectionsResponse = await FamilyService.getFamilyConnections();
      // Paralel request untuk stats agar lebih cepat (jika backend support)
      // Tapi sequential juga oke untuk kestabilan
      final stats = await FamilyService.getFamilyStats();

      if (!mounted) return;

      setState(() {
        _connections = connectionsResponse.connections;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading family data: $e');
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data keluarga. Periksa koneksi internet.';
          _isLoading = false;
        });
      }
    }
  }

  // ... (Dialog methods tetap sama: _showInviteFamilyDialog, _showAcceptInvitationDialog, _showRemoveConfirmation) ...
  
  // Update: Tambahkan feedback loading saat aksi
  Future<void> _acceptInvitation(int connectionId) async {
    setState(() => _isActionLoading = true); // Mulai loading aksi
    try {
      await FamilyService.acceptFamilyInvitation(connectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Undangan berhasil diterima'), backgroundColor: Colors.green),
        );
      }
      await _loadFamilyData(); // Reload data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => _isActionLoading = false); // Stop loading aksi
    }
  }

  Future<void> _removeConnection(int connectionId) async {
    setState(() => _isActionLoading = true);
    try {
      await FamilyService.removeFamilyConnection(connectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi dihapus'), backgroundColor: Colors.orange),
        );
      }
      await _loadFamilyData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showInviteFamilyDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteFamilyDialog(
        onInviteSent: _loadFamilyData,
      ),
    );
  }

  void _showAcceptInvitationDialog(FamilyConnection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terima Undangan'),
        content: Text('Terima undangan dari ${connection.lansiaName ?? "Pengguna"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptInvitation(connection.id);
            },
            child: const Text('Terima'),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(FamilyConnection connection) {
    String name = _userData?['role'] == 'lansia' 
        ? connection.familyName ?? 'Keluarga'
        : connection.lansiaName ?? 'Lansia';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Koneksi', style: TextStyle(color: Colors.red)),
        content: Text('Hapus koneksi dengan $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeConnection(connection.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---
  // (Widget _buildStatsCards, _buildStatCard sama persis dengan sebelumnya)
  Widget _buildStatsCards() {
    return Row(
      children: [
        if (_userData?['role'] == 'lansia') ...[
          Expanded(child: _buildStatCard('Keluarga', _stats.totalFamilyMembers.toString(), Icons.group, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Pending', _stats.pendingInvitations.toString(), Icons.hourglass_top, Colors.orange)),
        ] else ...[
          Expanded(child: _buildStatCard('Lansia', _stats.monitoredLansia.toString(), Icons.elderly, Colors.purple)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Undangan', _stats.pendingInvitations.toString(), Icons.mail, Colors.orange)),
        ],
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isLansia) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.group_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isLansia ? 'Belum ada anggota keluarga' : 'Belum terhubung dengan lansia',
              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              isLansia ? 'Tekan tombol Undang untuk menambahkan' : 'Tunggu undangan dari lansia',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionItem(FamilyConnection connection) {
    final isLansiaRole = _userData?['role'] == 'lansia';
    final displayName = isLansiaRole ? (connection.familyName ?? 'Keluarga') : (connection.lansiaName ?? 'Lansia');
    final displayPhone = isLansiaRole ? (connection.familyPhone ?? '-') : (connection.lansiaPhone ?? '-');
    final statusColor = connection.isVerified ? Colors.green : Colors.orange;
    final statusText = connection.isVerified ? "Terhubung" : "Menunggu";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.person, color: statusColor),
        ),
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayPhone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(statusText, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _showRemoveConfirmation(connection);
            if (value == 'accept') _showAcceptInvitationDialog(connection);
          },
          itemBuilder: (context) => [
            if (!connection.isVerified && !isLansiaRole)
              const PopupMenuItem(value: 'accept', child: Row(children: [Icon(Icons.check, color: Colors.green), SizedBox(width: 8), Text("Terima")])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Hapus")])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLansia = _userData?['role'] == 'lansia';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Koneksi Keluarga'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFamilyData),
        ],
        bottom: _isActionLoading 
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0), 
                child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.blue)
              ) 
            : null,
      ),
      floatingActionButton: isLansia
          ? FloatingActionButton.extended(
              onPressed: _showInviteFamilyDialog,
              backgroundColor: Colors.blue[800],
              icon: const Icon(Icons.person_add),
              label: const Text("Undang"),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadFamilyData, child: const Text('Coba Lagi'))
                ]))
              : RefreshIndicator(
                  onRefresh: _loadFamilyData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatsCards(),
                      const SizedBox(height: 20),
                      const Text("Daftar Terhubung", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (_connections.isEmpty) _buildEmptyState(isLansia)
                      else ..._connections.map((conn) => _buildConnectionItem(conn)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}

// Widget Dialog Undangan tetap sama (sudah optimal)
class _InviteFamilyDialog extends StatefulWidget {
  final VoidCallback onInviteSent;
  const _InviteFamilyDialog({required this.onInviteSent});
  @override
  __InviteFamilyDialogState createState() => __InviteFamilyDialogState();
}

class __InviteFamilyDialogState extends State<_InviteFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  String _accessLevel = 'basic';
  bool _isLoading = false;

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FamilyService.inviteFamilyMember(
        familyPhone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
        accessLevel: _accessLevel,
      );
      if (mounted) {
        widget.onInviteSent();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undangan terkirim!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Undang Keluarga'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. HP', prefixIcon: Icon(Icons.phone)),
                validator: (v) => (v == null || v.length < 10) ? 'Nomor HP valid diperlukan' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(labelText: 'Hubungan (Anak/Cucu)', prefixIcon: Icon(Icons.favorite)),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              // ... Dropdown akses & tombol kirim (sama seperti sebelumnya) ...
              // Saya singkat di sini karena kodenya sama persis dengan yang Anda kirim
              // Pastikan copy bagian Dropdown dan Actions dari kode sebelumnya.
               const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _accessLevel,
                decoration: const InputDecoration(
                  labelText: 'Hak Akses',
                  prefixIcon: Icon(Icons.security),
                ),
                items: const [
                  DropdownMenuItem(value: 'basic', child: Text('Dasar (Lihat Profil)')),
                  DropdownMenuItem(value: 'full', child: Text('Penuh (Edit & SOS)')),
                ],
                onChanged: (v) => setState(() => _accessLevel = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendInvitation,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Kirim'),
        ),
      ],
    );
  }
}
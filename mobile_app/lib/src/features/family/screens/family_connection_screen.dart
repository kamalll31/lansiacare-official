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
  String _error = '';
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFamilyData();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthService.getUserData();
    setState(() {
      _userData = userData;
    });
  }

  Future<void> _loadFamilyData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final connectionsResponse = await FamilyService.getFamilyConnections();
      final stats = await FamilyService.getFamilyStats();

      setState(() {
        _connections = connectionsResponse.connections;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading family data: $e');
      setState(() {
        _error = 'Gagal memuat data keluarga: $e';
        _isLoading = false;
      });
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
        content: Text('Terima undangan dari ${connection.lansiaName} (${connection.lansiaPhone})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _acceptInvitation(connection.id);
              Navigator.pop(context);
            },
            child: const Text('Terima'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(int connectionId) async {
    try {
      await FamilyService.acceptFamilyInvitation(connectionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Undangan berhasil diterima'),
          backgroundColor: Colors.green,
        ),
      );
      _loadFamilyData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menerima undangan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeConnection(int connectionId) async {
    try {
      await FamilyService.removeFamilyConnection(connectionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koneksi berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadFamilyData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus koneksi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRemoveConfirmation(FamilyConnection connection) {
    String name = _userData?['role'] == 'lansia' 
        ? connection.familyName ?? '' 
        : connection.lansiaName ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Koneksi'),
        content: Text('Yakin ingin menghapus koneksi dengan $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeConnection(connection.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_userData?['role'] == 'lansia') ...[
            Expanded(
              child: _buildStatCard(
                'Anggota Keluarga',
                _stats.totalFamilyMembers.toString(),
                Icons.group,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Undangan Tertunda',
                _stats.pendingInvitations.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ] else if (_userData?['role'] == 'keluarga') ...[
            Expanded(
              child: _buildStatCard(
                'Lansia Dipantau',
                _stats.monitoredLansia.toString(),
                Icons.visibility,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Undangan Tertunda',
                _stats.pendingInvitations.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ],
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

  Widget _buildConnectionItem(FamilyConnection connection) {
    bool isLansia = _userData?['role'] == 'lansia';
    String name = isLansia ? connection.familyName ?? '' : connection.lansiaName ?? '';
    String phone = isLansia ? connection.familyPhone ?? '' : connection.lansiaPhone ?? '';
    String role = isLansia ? 'Keluarga' : 'Lansia';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: connection.isVerified ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            isLansia ? Icons.family_restroom : Icons.elderly,
            color: connection.isVerified ? Colors.green : Colors.orange,
          ),
        ),
        title: Row(
          children: [
            Text(
              name.isNotEmpty ? name : 'Loading...',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            if (connection.isVerified)
              const Icon(Icons.verified, color: Colors.green, size: 16),
            if (!connection.isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Menunggu',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phone),
            Text('$role • ${connection.relationship}'),
            const SizedBox(height: 4),
            Text(
              'Akses: ${connection.accessLevel == 'full' ? 'Lengkap' : 'Dasar'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: !connection.isVerified && _userData?['role'] == 'keluarga'
            ? ElevatedButton(
                onPressed: () => _showAcceptInvitationDialog(connection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Terima'),
              )
            : PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view_activity',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Lihat Aktivitas'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus Koneksi'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _showRemoveConfirmation(connection);
                  } else if (value == 'view_activity') {
                    // TODO: Navigate to activity screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur aktivitas akan segera hadir'),
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Koneksi Keluarga'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (_userData?['role'] == 'lansia')
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showInviteFamilyDialog,
              tooltip: 'Undang Keluarga',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFamilyData,
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
                  Text('Memuat data keluarga...'),
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
                        onPressed: _loadFamilyData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildStatsCards(),
                    
                    Expanded(
                      child: _connections.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _userData?['role'] == 'lansia'
                                        ? 'Belum ada anggota keluarga'
                                        : 'Belum terhubung dengan lansia',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _userData?['role'] == 'lansia'
                                        ? 'Undang anggota keluarga untuk mulai'
                                        : 'Terima undangan dari lansia untuk mulai',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (_userData?['role'] == 'lansia')
                                    ElevatedButton(
                                      onPressed: _showInviteFamilyDialog,
                                      child: const Text('Undang Keluarga Pertama'),
                                    ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadFamilyData,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _connections.length,
                                itemBuilder: (context, index) {
                                  return _buildConnectionItem(_connections[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

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

  final List<Map<String, String>> _relationshipOptions = [
    {'value': 'anak', 'label': 'Anak'},
    {'value': 'menantu', 'label': 'Menantu'},
    {'value': 'cucu', 'label': 'Cucu'},
    {'value': 'saudara', 'label': 'Saudara'},
    {'value': 'keponakan', 'label': 'Keponakan'},
    {'value': 'lainnya', 'label': 'Lainnya'},
  ];

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FamilyService.inviteFamilyMember(
        familyPhone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
        accessLevel: _accessLevel,
      );

      widget.onInviteSent();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Undangan berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim undangan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Undang Anggota Keluarga'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon Keluarga *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Contoh: 081234567890',
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor telepon harus diisi';
                  }
                  if (value.trim().length < 10) {
                    return 'Nomor telepon harus valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Hubungan Keluarga *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                  hintText: 'Contoh: Anak, Menantu, Cucu',
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hubungan keluarga harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _accessLevel,
                decoration: const InputDecoration(
                  labelText: 'Level Akses',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'basic',
                    child: Text('Akses Dasar'),
                  ),
                  DropdownMenuItem(
                    value: 'full', 
                    child: Text('Akses Lengkap'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _accessLevel = value ?? 'basic';
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                _accessLevel == 'basic' 
                    ? 'Akses dasar: Melihat informasi dasar dan aktivitas'
                    : 'Akses lengkap: Semua akses termasuk data darurat',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Mengirim undangan...'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendInvitation,
          child: const Text('Kirim Undangan'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }
}
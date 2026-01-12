import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/emergency_service.dart';
import 'package:lansiacare/src/shared/models/emergency_model.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  _EmergencyContactsScreenState createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      
      final response = await EmergencyService.getEmergencyContacts();
      
      if (mounted) {
        setState(() {
          _contacts = response.contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat kontak: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditContactDialog(
        onContactSaved: _loadContacts,
      ),
    );
  }

  void _showEditContactDialog(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => _AddEditContactDialog(
        contact: contact,
        onContactSaved: _loadContacts,
      ),
    );
  }

  Future<void> _deleteContact(int contactId) async {
    try {
      setState(() => _isLoading = true);
      await EmergencyService.deleteEmergencyContact(contactId);
      
      if (mounted) {
        setState(() {
          _contacts.removeWhere((contact) => contact.id == contactId);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kontak dihapus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
      _loadContacts(); // Refresh jika gagal (rollback UI)
    }
  }

  void _showDeleteConfirmation(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kontak'),
        content: Text('Hapus ${contact.contactName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContact(contact.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak Darurat'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddContactDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadContacts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : _contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Belum ada kontak darurat', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _showAddContactDialog,
                            child: const Text('Tambah Kontak'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: contact.isPrimary ? Colors.red[100] : Colors.blue[100],
                              child: Icon(
                                contact.isPrimary ? Icons.star : Icons.person,
                                color: contact.isPrimary ? Colors.red : Colors.blue,
                              ),
                            ),
                            title: Text(contact.contactName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${contact.phone} • ${contact.relationship}'),
                            trailing: PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'edit') _showEditContactDialog(contact);
                                if (value == 'delete') _showDeleteConfirmation(contact);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _AddEditContactDialog extends StatefulWidget {
  final EmergencyContact? contact;
  final VoidCallback onContactSaved;

  const _AddEditContactDialog({this.contact, required this.onContactSaved});

  @override
  __AddEditContactDialogState createState() => __AddEditContactDialogState();
}

class __AddEditContactDialogState extends State<_AddEditContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _relationshipController;
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.contactName ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _relationshipController = TextEditingController(text: widget.contact?.relationship ?? 'Keluarga');
    _isPrimary = widget.contact?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.contact == null) {
        await EmergencyService.addEmergencyContact(
          contactName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relationship: _relationshipController.text.trim(),
          isPrimary: _isPrimary,
        );
      } else {
        await EmergencyService.updateEmergencyContact(
          contactId: widget.contact!.id,
          contactName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relationship: _relationshipController.text.trim(),
          isPrimary: _isPrimary,
        );
      }

      if (mounted) {
        widget.onContactSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kontak disimpan'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Tambah Kontak' : 'Edit Kontak'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama', icon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. HP', icon: Icon(Icons.phone)),
                validator: (v) => v!.length < 10 ? 'No HP tidak valid' : null,
              ),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(labelText: 'Hubungan', icon: Icon(Icons.group)),
              ),
              CheckboxListTile(
                title: const Text('Kontak Utama'),
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveContact,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan'),
        ),
      ],
    );
  }
}
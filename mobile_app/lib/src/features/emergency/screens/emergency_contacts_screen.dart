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
      
      print('DEBUG: 🟡 Loading contacts from server...');
      
      final response = await EmergencyService.getEmergencyContacts();
      setState(() {
        _contacts = response.contacts;
        _isLoading = false;
      });
      
      print('DEBUG: 🟢 Successfully loaded ${_contacts.length} contacts');
      
    } catch (e) {
      print('DEBUG: 🔴 Error loading contacts: $e');
      setState(() {
        _error = 'Gagal memuat kontak: $e';
        _isLoading = false;
      });
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
      print('DEBUG: 🟡 Deleting contact $contactId');
      
      // Tampilkan loading
      setState(() {
        _isLoading = true;
      });

      // Hapus dari server
      await EmergencyService.deleteEmergencyContact(contactId);
      
      // Hapus dari local state
      setState(() {
        _contacts.removeWhere((contact) => contact.id == contactId);
        _isLoading = false;
      });
      
      print('DEBUG: 🟢 Successfully deleted contact $contactId');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kontak berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('DEBUG: 🔴 Error deleting contact: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus kontak: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Refresh data untuk memastikan state sync
      _loadContacts();
    }
  }

  void _showDeleteConfirmation(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kontak'),
        content: Text('Yakin ingin menghapus ${contact.contactName}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContact(contact.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak Darurat'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddContactDialog,
            tooltip: 'Tambah Kontak Baru',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
            tooltip: 'Refresh Data',
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
                  Text('Memuat kontak darurat...'),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContacts,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.contacts,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada kontak darurat',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SOS akan mengirim notifikasi ke kontak darurat yang terdaftar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _showAddContactDialog,
                            child: const Text('Tambah Kontak Pertama'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadContacts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: contact.isPrimary ? Colors.red : Colors.blue,
                                child: Icon(
                                  contact.isPrimary ? Icons.star : Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                contact.contactName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contact.phone),
                                  Text(
                                    '${contact.relationship}${contact.isPrimary ? ' • Kontak Utama' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Hapus'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditContactDialog(contact);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(contact);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        tooltip: 'Tambah Kontak Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddEditContactDialog extends StatefulWidget {
  final EmergencyContact? contact;
  final VoidCallback onContactSaved;

  const _AddEditContactDialog({
    this.contact,
    required this.onContactSaved,
  });

  @override
  __AddEditContactDialogState createState() => __AddEditContactDialogState();
}

class __AddEditContactDialogState extends State<_AddEditContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.contactName;
      _phoneController.text = widget.contact!.phone;
      _relationshipController.text = widget.contact!.relationship;
      _isPrimary = widget.contact!.isPrimary;
    } else {
      _relationshipController.text = 'Keluarga';
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: 🔴 Form validation failed');
      return;
    }

    print('DEBUG: 🟡 Saving contact...');
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.contact == null) {
        // Add new contact
        print('DEBUG: 🟡 Adding new contact...');
        
        await EmergencyService.addEmergencyContact(
          contactName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relationship: _relationshipController.text.trim(),
          isPrimary: _isPrimary,
        );
        
        print('DEBUG: 🟢 Successfully added contact');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kontak berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update existing contact
        print('DEBUG: 🟡 Updating contact ${widget.contact!.id}...');
        
        await EmergencyService.updateEmergencyContact(
          contactId: widget.contact!.id,
          contactName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relationship: _relationshipController.text.trim(),
          isPrimary: _isPrimary,
        );
        
        print('DEBUG: 🟢 Successfully updated contact');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kontak berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Panggil callback untuk refresh data
      widget.onContactSaved();
      
      // Close dialog
      Navigator.pop(context);
      
    } catch (e) {
      print('DEBUG: 🔴 Error saving contact: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Tambah Kontak Darurat' : 'Edit Kontak Darurat'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kontak *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama kontak harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor telepon harus diisi';
                  }
                  if (value.trim().length < 10) {
                    return 'Nomor telepon harus valid (min. 10 digit)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Hubungan *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hubungan harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text(
                  'Jadikan sebagai kontak utama',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Kontak utama akan dihubungi pertama saat SOS'),
                value: _isPrimary,
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _isPrimary = value ?? false;
                  });
                },
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Menyimpan...'),
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
          onPressed: _isLoading ? null : _saveContact,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.contact == null ? 'Tambah' : 'Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }
}
class EmergencyContact {
  final int id;
  final String contactName;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final String? createdAt;

  EmergencyContact({
    required this.id,
    required this.contactName,
    required this.phone,
    required this.relationship,
    required this.isPrimary,
    this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    // Debug logging untuk melihat struktur data
    print('DEBUG: Parsing contact from JSON: $json');
    
    return EmergencyContact(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      contactName: json['contact_name']?.toString() ?? json['contactName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? 'Keluarga',
      isPrimary: json['is_primary'] is bool ? json['is_primary'] : (json['is_primary']?.toString() == 'true'),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_name': contactName,
      'phone': phone,
      'relationship': relationship,
      'is_primary': isPrimary,
      'created_at': createdAt,
    };
  }

  @override
  String toString() {
    return 'EmergencyContact{id: $id, name: $contactName, phone: $phone}';
  }
}

class EmergencyContactsResponse {
  final List<EmergencyContact> contacts;

  EmergencyContactsResponse({required this.contacts});

  factory EmergencyContactsResponse.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Parsing contacts response: $json');
    
    List<EmergencyContact> contacts = [];
    
    if (json['emergency_contacts'] is List) {
      final contactsList = json['emergency_contacts'] as List;
      contacts = contactsList
          .map<EmergencyContact>((contactJson) {
            try {
              return EmergencyContact.fromJson(contactJson);
            } catch (e) {
              print('DEBUG: Error parsing contact: $e - Data: $contactJson');
              return EmergencyContact(
                id: 0,
                contactName: 'Error',
                phone: '000',
                relationship: 'Error',
                isPrimary: false,
              );
            }
          })
          .where((contact) => contact.id > 0) // Filter out error contacts
          .toList();
    } else if (json['contacts'] is List) {
      // Alternative field name
      final contactsList = json['contacts'] as List;
      contacts = contactsList
          .map<EmergencyContact>((contactJson) => EmergencyContact.fromJson(contactJson))
          .toList();
    }
    
    return EmergencyContactsResponse(contacts: contacts);
  }
}

class ContactStats {
  final int totalContacts;
  final bool hasPrimary;
  final String? primaryContact;

  ContactStats({
    required this.totalContacts,
    required this.hasPrimary,
    this.primaryContact,
  });

  factory ContactStats.fromJson(Map<String, dynamic> json) {
    return ContactStats(
      totalContacts: json['total_contacts'] is int ? json['total_contacts'] : 0,
      hasPrimary: json['has_primary'] is bool ? json['has_primary'] : false,
      primaryContact: json['primary_contact']?.toString(),
    );
  }
}

class SOSResponse {
  final String message;
  final String emergencyId;
  final String timestamp;
  final int contactsNotified;
  final Map<String, dynamic>? details;

  SOSResponse({
    required this.message,
    required this.emergencyId,
    required this.timestamp,
    required this.contactsNotified,
    this.details,
  });

  factory SOSResponse.fromJson(Map<String, dynamic> json) {
    return SOSResponse(
      message: json['message']?.toString() ?? 'SOS terkirim',
      emergencyId: json['emergency_id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      contactsNotified: json['contacts_notified'] is int ? json['contacts_notified'] : 0,
      details: json['details'] is Map ? Map<String, dynamic>.from(json['details']) : null,
    );
  }
}
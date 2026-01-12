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
    return EmergencyContact(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      
      // [FIX] Cek 'contactName' (Camel) dulu, baru fallback ke 'contact_name' (Snake)
      contactName: json['contactName']?.toString() ?? json['contact_name']?.toString() ?? '',
      
      phone: json['phone']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? 'Keluarga',
      
      // [FIX] Cek 'isPrimary' (Camel) dulu
      isPrimary: json['isPrimary'] != null 
          ? (json['isPrimary'] == true || json['isPrimary'] == 'true')
          : (json['is_primary'] == true || json['is_primary'] == 'true'),
          
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactName': contactName, // [FIX] Gunakan CamelCase untuk konsistensi
      'phone': phone,
      'relationship': relationship,
      'isPrimary': isPrimary,     // [FIX] Gunakan CamelCase
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
    List<EmergencyContact> contacts = [];
    
    // Support kedua format: 'contacts' (Backend Baru) & 'emergency_contacts' (Legacy)
    var listData = json['contacts'] ?? json['emergency_contacts'];

    if (listData is List) {
      contacts = listData
          .map<EmergencyContact>((contactJson) {
            try {
              return EmergencyContact.fromJson(contactJson);
            } catch (e) {
              return EmergencyContact(id: 0, contactName: 'Error', phone: '000', relationship: 'Error', isPrimary: false);
            }
          })
          .where((contact) => contact.id > 0)
          .toList();
    }
    
    return EmergencyContactsResponse(contacts: contacts);
  }
}

class ContactStats {
  final int totalContacts;
  final bool hasPrimary;
  final String? primaryContact;

  ContactStats({required this.totalContacts, required this.hasPrimary, this.primaryContact});

  factory ContactStats.fromJson(Map<String, dynamic> json) {
    return ContactStats(
      totalContacts: json['totalContacts'] is int ? json['totalContacts'] : (json['total_contacts'] ?? 0),
      hasPrimary: json['hasPrimary'] is bool ? json['hasPrimary'] : (json['has_primary'] ?? false),
      primaryContact: json['primaryName']?.toString() ?? json['primary_contact']?.toString(),
    );
  }
}

class SOSResponse {
  final String message;
  final String emergencyId;
  final String timestamp;
  final int contactsNotified;
  final Map<String, dynamic>? details;

  SOSResponse({required this.message, required this.emergencyId, required this.timestamp, required this.contactsNotified, this.details});

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
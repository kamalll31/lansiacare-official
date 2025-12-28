import 'dart:convert';
import 'package:lansiacare/src/shared/models/emergency_model.dart';
import 'api_service.dart';

class EmergencyService {
  static Future<EmergencyContactsResponse> getEmergencyContacts() async {
    try {
      print('DEBUG: Getting emergency contacts...');
      
      final response = await ApiService.getEmergencyContacts();
      
      print('DEBUG: Contacts response status: ${response.statusCode}');
      print('DEBUG: Contacts response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final contactsResponse = EmergencyContactsResponse.fromJson(data);
        
        print('DEBUG: Successfully parsed ${contactsResponse.contacts.length} contacts');
        return contactsResponse;
      } else {
        final errorMessage = 'Failed to load emergency contacts: ${response.statusCode}';
        print('DEBUG: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error in getEmergencyContacts: $e');
      throw Exception('Gagal memuat kontak darurat: $e');
    }
  }

  static Future<EmergencyContact> addEmergencyContact({
    required String contactName,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    try {
      print('DEBUG: Adding new contact: $contactName, $phone, $relationship, primary: $isPrimary');
      
      final response = await ApiService.addEmergencyContact({
        'contact_name': contactName,
        'phone': phone,
        'relationship': relationship,
        'is_primary': isPrimary,
      });
      
      print('DEBUG: Add contact response status: ${response.statusCode}');
      print('DEBUG: Add contact response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final contactData = data['contact'];
        
        if (contactData == null) {
          throw Exception('Contact data is null in response');
        }
        
        print('DEBUG: Successfully parsed new contact: $contactData');
        return EmergencyContact.fromJson(contactData);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to add contact. Status: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error in addEmergencyContact: $e');
      throw Exception('Gagal menambah kontak: $e');
    }
  }

  static Future<EmergencyContact> updateEmergencyContact({
    required int contactId,
    required String contactName,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    try {
      print('DEBUG: Updating contact $contactId: $contactName, $phone, $relationship, primary: $isPrimary');
      
      final response = await ApiService.updateEmergencyContact(contactId, {
        'contact_name': contactName,
        'phone': phone,
        'relationship': relationship,
        'is_primary': isPrimary,
      });
      
      print('DEBUG: Update contact response status: ${response.statusCode}');
      print('DEBUG: Update contact response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final contactData = data['contact'];
        
        if (contactData == null) {
          throw Exception('Contact data is null in response');
        }
        
        print('DEBUG: Successfully updated contact: $contactData');
        return EmergencyContact.fromJson(contactData);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to update contact. Status: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error in updateEmergencyContact: $e');
      throw Exception('Gagal mengupdate kontak: $e');
    }
  }

  static Future<void> deleteEmergencyContact(int contactId) async {
    try {
      print('DEBUG: Deleting contact $contactId');
      
      final response = await ApiService.deleteEmergencyContact(contactId);
      
      print('DEBUG: Delete contact response status: ${response.statusCode}');
      print('DEBUG: Delete contact response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Successfully deleted contact: $data');
        return;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to delete contact. Status: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error in deleteEmergencyContact: $e');
      throw Exception('Gagal menghapus kontak: $e');
    }
  }

  static Future<ContactStats> getContactStats() async {
    try {
      final response = await ApiService.getEmergencyStats();
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContactStats.fromJson(data);
      } else {
        throw Exception('Failed to load contact stats: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getContactStats: $e');
      return ContactStats(
        totalContacts: 0,
        hasPrimary: false,
        primaryContact: null,
      );
    }
  }

  static Future<Map<String, dynamic>> triggerSOS() async {
    try {
      print('DEBUG: Triggering SOS...');
      
      final response = await ApiService.triggerSOS();
      
      print('DEBUG: SOS response status: ${response.statusCode}');
      print('DEBUG: SOS response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to trigger SOS';
        
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('DEBUG: Error in triggerSOS: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<void> debugBackendResponse() async {
    try {
      print('DEBUG: Testing backend connection...');
      final response = await ApiService.getEmergencyContacts();
      print('DEBUG: Backend response status: ${response.statusCode}');
      print('DEBUG: Backend response body: ${response.body}');
    } catch (e) {
      print('DEBUG: Backend connection error: $e');
    }
  }
}
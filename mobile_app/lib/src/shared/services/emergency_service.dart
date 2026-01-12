import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lansiacare/src/shared/models/emergency_model.dart';
import 'api_service.dart';

class EmergencyService {
  
  // --- CRUD METHODS (TETAP SAMA) ---

  static Future<EmergencyContactsResponse> getEmergencyContacts() async {
    try {
      final response = await ApiService.getEmergencyContacts();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EmergencyContactsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load emergency contacts: ${response.statusCode}');
      }
    } catch (e) {
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
      final response = await ApiService.addEmergencyContact({
        'contact_name': contactName,
        'phone': phone,
        'relationship': relationship,
        'is_primary': isPrimary,
      });
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return EmergencyContact.fromJson(data['contact']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add contact');
      }
    } catch (e) {
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
      final response = await ApiService.updateEmergencyContact(contactId, {
        'contact_name': contactName,
        'phone': phone,
        'relationship': relationship,
        'is_primary': isPrimary,
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EmergencyContact.fromJson(data['contact']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update contact');
      }
    } catch (e) {
      throw Exception('Gagal mengupdate kontak: $e');
    }
  }

  static Future<void> deleteEmergencyContact(int contactId) async {
    try {
      final response = await ApiService.deleteEmergencyContact(contactId);
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete contact');
      }
    } catch (e) {
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
        throw Exception('Failed to load contact stats');
      }
    } catch (e) {
      return ContactStats(totalContacts: 0, hasPrimary: false, primaryContact: null);
    }
  }

  // --- SOS TRIGGER METHOD (UPDATED FOR HYBRID LOGIC) ---

  static Future<Map<String, dynamic>> triggerSOS() async {
    try {
      print('DEBUG: Getting location for SOS...');
      // 1. Ambil Lokasi GPS
      Position position = await _determinePosition();
      
      print('DEBUG: Triggering SOS API...');
      // 2. Kirim ke Backend
      final response = await ApiService.triggerSOS();
      
      print('DEBUG: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 3. Ambil daftar target dari backend (Gabungan Keluarga + Manual)
        List<dynamic> targets = data['targets'] ?? [];

        if (targets.isNotEmpty) {
          // Ambil target prioritas pertama
          var primeTarget = targets[0];
          String phone = primeTarget['phone'];
          String name = primeTarget['name'];
          
          // Format nomor WA (08 -> 628)
          if (phone.startsWith('0')) {
            phone = '62${phone.substring(1)}';
          }

          // Buat Link Google Maps
          String googleMapsLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
          
          // Pesan Default
          String message = "🚨 *SOS DARURAT!* 🚨\n\nSaya butuh bantuan segera!\nNama Kontak: $name\n📍 Lokasi Saya: $googleMapsLink";
          
          // 4. Buka WhatsApp Otomatis
          await _launchWhatsApp(phone, message);
          
          return {
            'success': true,
            'message': 'Membuka WhatsApp ke $name',
            'data': data
          };
        } else {
          // Kasus aneh: Sukses 200 tapi list target kosong
           return {
            'success': true, 
            'message': 'SOS Tercatat di Server, tapi tidak ada nomor kontak ditemukan.'
          };
        }
      } else {
        // Error dari server (misal 404 tidak ada kontak)
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? errorData['error'] ?? 'Gagal mengirim SOS',
        };
      }
    } catch (e) {
      print('DEBUG: Error in triggerSOS: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Helper: Buka WhatsApp
  static Future<void> _launchWhatsApp(String phone, String message) async {
    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
    final Uri webUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("Error launching WA: $e");
    }
  }

  // Helper: Izin Lokasi
  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Jika GPS mati, coba minta nyalakan atau throw error
      // Untuk demo, kita throw error simple
      throw Exception('Layanan Lokasi (GPS) mati. Mohon nyalakan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Ubah di pengaturan.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
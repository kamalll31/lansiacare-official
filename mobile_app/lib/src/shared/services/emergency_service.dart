import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lansiacare/src/shared/models/emergency_model.dart';
import 'api_service.dart';

class EmergencyService {
  
  // ===========================================================================
  // 1. MANAJEMEN KONTAK DARURAT (CRUD)
  // ===========================================================================

  static Future<EmergencyContactsResponse> getEmergencyContacts() async {
    try {
      final response = await ApiService.get('/emergency/contacts');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EmergencyContactsResponse.fromJson(data);
      } else {
        throw Exception('Gagal memuat kontak: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error memuat kontak: $e');
    }
  }

  static Future<EmergencyContact> addEmergencyContact({
    required String contactName,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    try {
      final response = await ApiService.post('/emergency/contacts', {
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
        throw Exception(errorData['error'] ?? 'Gagal menambah kontak');
      }
    } catch (e) {
      throw Exception('Error menambah kontak: $e');
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
      final response = await ApiService.put('/emergency/contacts/$contactId', {
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
        throw Exception(errorData['error'] ?? 'Gagal update kontak');
      }
    } catch (e) {
      throw Exception('Error update kontak: $e');
    }
  }

  static Future<void> deleteEmergencyContact(int contactId) async {
    try {
      final response = await ApiService.delete('/emergency/contacts/$contactId');
      
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Gagal hapus kontak');
      }
    } catch (e) {
      throw Exception('Error hapus kontak: $e');
    }
  }

  static Future<ContactStats> getContactStats() async {
    try {
      final response = await ApiService.get('/emergency/contacts/stats');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContactStats.fromJson(data);
      } else {
        throw Exception('Gagal memuat statistik');
      }
    } catch (e) {
      return ContactStats(totalContacts: 0, hasPrimary: false, primaryContact: null);
    }
  }

  // ===========================================================================
  // 2. SISTEM SOS & LOKASI (PROFESSIONAL VERSION)
  // ===========================================================================

  static Future<Map<String, dynamic>> triggerSOS() async {
    try {
      print('DEBUG: Getting location for SOS...');
      
      // 1. Ambil Lokasi GPS (High Accuracy Mode)
      Position position = await _determinePosition();
      
      print('DEBUG: Triggering SOS API...');
      
      // 2. Kirim ke Backend untuk Log Medis
      final response = await ApiService.post('/emergency/sos', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      
      print('DEBUG: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 3. Ambil Daftar Kontak Target
        List<dynamic> targets = data['targets'] ?? [];

        if (targets.isNotEmpty) {
          var primeTarget = targets[0];
          String phone = primeTarget['phone'];
          String name = primeTarget['name']; // Nama Lansia (User)
          
          // Format nomor WA (08 -> 628)
          if (phone.startsWith('0')) {
            phone = '62${phone.substring(1)}';
          }

          // 4. Generate Link Google Maps Resmi (Standard Universal Link)
          String googleMapsLink = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
          
          // 5. Susun Pesan Formal
          String message = 
              "⚠️ *PERINGATAN DARURAT - LANSIA CARE* ⚠️\n\n"
              "Yth. Keluarga / Kerabat,\n\n"
              "Sistem mendeteksi sinyal bahaya (SOS) dari pengguna:\n"
              "👤 Nama: *$name*\n"
              "❗ Status: *MEMBUTUHKAN BANTUAN SEGERA*\n\n"
              "Mohon segera hubungi pengguna atau cek lokasi terkini di bawah ini:\n"
              "📍 *Lokasi Real-time:*\n$googleMapsLink\n\n"
              "_Pesan ini dikirim otomatis oleh Aplikasi Lansia Care._";
          
          // 6. Buka WhatsApp
          await _launchWhatsApp(phone, message);
          
          return {
            'success': true,
            'message': 'Mengirim notifikasi resmi ke keluarga',
            'data': data
          };
        } else {
           return {
            'success': true, 
            'message': 'SOS Tercatat di Server, tapi belum ada kontak keluarga/darurat yang terhubung.'
          };
        }
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal mengirim SOS',
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

  // Helper: Buka WhatsApp dengan Fallback
  static Future<void> _launchWhatsApp(String phone, String message) async {
    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
    final Uri webUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback ke browser jika aplikasi WA tidak terinstall
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("Error launching WA: $e");
    }
  }

  // Helper: Izin Lokasi & GPS High Accuracy
  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek Service GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan Lokasi (GPS) mati. Mohon nyalakan GPS Anda.');
    }

    // Cek Izin Aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Ubah di pengaturan HP.');
    }

    // AMBIL LOKASI (High Accuracy)
    // Time limit 10 detik agar HP punya waktu mencari satelit
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }
}
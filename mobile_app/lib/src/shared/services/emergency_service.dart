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
      // [FIX] UBAH KEY JADI CAMELCASE (contactName) AGAR DITERIMA BACKEND
      final response = await ApiService.post('/emergency/contacts', {
        'contactName': contactName,  // <--- PERUBAHAN UTAMA
        'phone': phone,
        'relationship': relationship,
        'isPrimary': isPrimary,      // <--- PERUBAHAN UTAMA
      });
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return EmergencyContact.fromJson(data['contact'] ?? data); // Handle variasi response
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
      // [FIX] UBAH KEY JADI CAMELCASE
      final response = await ApiService.put('/emergency/contacts/$contactId', {
        'contactName': contactName, // <--- PERUBAHAN UTAMA
        'phone': phone,
        'relationship': relationship,
        'isPrimary': isPrimary,     // <--- PERUBAHAN UTAMA
      });
      
      if (response.statusCode == 200) {
        // Backend mungkin tidak mengembalikan full object, kita construct manual
        // atau ambil dari response jika ada
        return EmergencyContact(
           id: contactId,
           contactName: contactName,
           phone: phone,
           relationship: relationship,
           isPrimary: isPrimary
        );
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
  // 2. SISTEM SOS & LOKASI
  // ===========================================================================

  static Future<Map<String, dynamic>> triggerSOS() async {
    try {
      print('DEBUG: Getting location for SOS...');
      
      Position position = await _determinePosition();
      
      print('DEBUG: Triggering SOS API...');
      
      final response = await ApiService.post('/emergency/sos', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      
      print('DEBUG: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> targets = data['targets'] ?? [];

        if (targets.isNotEmpty) {
          var primeTarget = targets[0];
          String phone = primeTarget['phone'];
          String name = primeTarget['name'];
          
          if (phone.startsWith('0')) {
            phone = '62${phone.substring(1)}';
          }

          String googleMapsLink = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
          
          String message = 
              "⚠️ *PERINGATAN DARURAT - LANSIA CARE* ⚠️\n\n"
              "Yth. Keluarga / Kerabat,\n\n"
              "Sistem mendeteksi sinyal bahaya (SOS) dari pengguna:\n"
              "👤 Nama: *$name*\n"
              "❗ Status: *MEMBUTUHKAN BANTUAN SEGERA*\n\n"
              "Mohon segera hubungi pengguna atau cek lokasi terkini di bawah ini:\n"
              "📍 *Lokasi Real-time:*\n$googleMapsLink\n\n"
              "_Pesan ini dikirim otomatis oleh Aplikasi Lansia Care._";
          
          await _launchWhatsApp(phone, message);
          
          return {
            'success': true,
            'message': 'Mengirim notifikasi resmi ke keluarga',
            'data': data
          };
        } else {
           return {
            'success': true, 
            'message': 'SOS Tercatat, tapi belum ada kontak keluarga/darurat.'
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

  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("GPS Mati, pakai lokasi default");
      return Position(longitude: 106.8456, latitude: -6.2088, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
         return Position(longitude: 106.8456, latitude: -6.2088, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
       return Position(longitude: 106.8456, latitude: -6.2088, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }
}
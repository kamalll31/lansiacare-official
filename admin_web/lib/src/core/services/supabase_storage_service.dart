import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_web/src/core/config/app_config.dart';

class SupabaseStorageService {
  // Instance private
  final SupabaseClient _supabase;

  // Constructor
  SupabaseStorageService() : _supabase = Supabase.instance.client;

  /// Inisialisasi Supabase (Panggil ini di main.dart)
  static Future<void> initialize() async {
    // [FIX] Gunakan AppConfig, jangan string manual!
    await Supabase.initialize(
      url: AppConfig.supabaseUrl, 
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  Future<Map<String, dynamic>> uploadFile(PlatformFile file, String folder) async {
    try {
      // 1. Buat nama file unik (timestamp_filename)
      // Membersihkan nama file dari spasi dan karakter aneh
      final cleanName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      final path = '$folder/$fileName';

      // 2. Upload File (Web vs Native beda handling)
      if (kIsWeb) {
        if (file.bytes == null) throw Exception('File bytes kosong (Web)');
        
        await _supabase.storage.from('content-media').uploadBinary(
          path,
          file.bytes!,
          fileOptions: const FileOptions(
            cacheControl: '3600', 
            upsert: false,
            contentType: null // Biarkan Supabase detect otomatis
          ),
        );
      } else {
        if (file.path == null) throw Exception('File path kosong (Native)');
        
        await _supabase.storage.from('content-media').upload(
          path,
          File(file.path!),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      }

      // 3. Ambil Public URL
      final publicUrl = _supabase.storage.from('content-media').getPublicUrl(path);

      if (kDebugMode) {
        print('✅ Upload Success: $publicUrl');
      }

      return {
        'success': true,
        'url': publicUrl,
        'path': path,
        'duration': null, 
      };
    } catch (e) {
      if (kDebugMode) print('❌ Supabase Upload Error: $e');
      return {'success': false, 'error': 'Gagal upload: $e'};
    }
  }
}
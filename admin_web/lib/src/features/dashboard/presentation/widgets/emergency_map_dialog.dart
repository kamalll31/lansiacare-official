import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EmergencyMapDialog extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String userName;
  final String time;

  const EmergencyMapDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.userName,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 800, // Lebar peta di layar
        height: 500, // Tinggi peta
        child: Column(
          children: [
            // Header Dialog
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Lokasi Darurat: $userName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Waktu: $time", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            
            // Peta OpenStreetMap
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude), // Pusatkan peta ke lokasi SOS
                  initialZoom: 15.0, // Zoom level yang pas
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.lansiacare.admin',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(latitude, longitude),
                        width: 80,
                        height: 80,
                        child: const Column(
                          children: [
                            Icon(Icons.location_on, color: Colors.red, size: 40),
                            Text("SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Footer Info Koordinat
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  SelectableText("$latitude, $longitude", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
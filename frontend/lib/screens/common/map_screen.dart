import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint_model.dart';

class MapScreen extends StatefulWidget {
  final bool showOnlyUserComplaints;

  const MapScreen({super.key, this.showOnlyUserComplaints = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _currentMapLayer = 'Modern';
  final MapController _mapController = MapController();

  // Map Tile Layers
  final _layers = {
    'Modern': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'Street': 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    'Satellite': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.red;
      case 'VERIFIED':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.blue;
      case 'RESOLVED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final allComplaints = complaintProvider.complaints;
    
    // Filter logic if needed (handled by provider usually, but we ensure here)
    final complaints = allComplaints;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Suchak HeatMap"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _currentMapLayer = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Modern', child: Text("Modern (OSM)")),
              const PopupMenuItem(value: 'Street', child: Text("Street (HOT)")),
              const PopupMenuItem(value: 'Satellite', child: Text("Satellite (ESRI)")),
            ],
            icon: const Icon(Icons.layers),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(20.5937, 78.9629), // Center on India
          initialZoom: 5.0,
        ),
        children: [
          TileLayer(
            urlTemplate: _layers[_currentMapLayer],
            userAgentPackageName: 'com.example.suchak',
          ),
          MarkerLayer(
            markers: complaints.map((complaint) {
              return Marker(
                point: LatLng(complaint.latitude, complaint.longitude),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showComplaintDetails(context, complaint),
                  child: Icon(
                    Icons.location_on,
                    color: _getStatusColor(complaint.status),
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (complaints.isNotEmpty) {
            _mapController.move(
              LatLng(complaints.first.latitude, complaints.first.longitude),
              12.0,
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showComplaintDetails(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(complaint.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Status: ${complaint.status}", style: TextStyle(color: _getStatusColor(complaint.status), fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(complaint.description),
            const SizedBox(height: 10),
            Text("Created: ${complaint.createdAt.toLocal().toString().split('.')[0]}"),
          ],
        ),
      ),
    );
  }
}

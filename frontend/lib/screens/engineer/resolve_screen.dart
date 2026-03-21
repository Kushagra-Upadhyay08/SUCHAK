import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';

class ResolveScreen extends StatefulWidget {
  final Complaint complaint;
  const ResolveScreen({super.key, required this.complaint});

  @override
  State<ResolveScreen> createState() => _ResolveScreenState();
}

class _ResolveScreenState extends State<ResolveScreen> {
  XFile? _image;
  Position? _currentPosition;
  bool _isLoading = false;

  Future<void> _captureProof() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _image = image);
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() => _currentPosition = position);
  }

  void _submitResolution() async {
    if (_image == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Capture proof image first")));
      return;
    }

    setState(() => _isLoading = true);
    final bytes = await File(_image!.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    final success = await Provider.of<ComplaintProvider>(context, listen: false).resolveComplaint(
      widget.complaint.id,
      base64Image,
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    setState(() => _isLoading = false);
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Distance Check Failed: You must be near the complaint location!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resolve Complaint")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Issue: ${widget.complaint.title}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _image != null 
              ? Image.file(File(_image!.path), height: 250)
              : OutlinedButton.icon(onPressed: _captureProof, icon: const Icon(Icons.camera_alt), label: const Text("Capture Proof (Real-time)")),
            const SizedBox(height: 20),
            if (_currentPosition != null) Text("Verified at: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}"),
            const Spacer(),
            _isLoading 
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _submitResolution, child: const Text("Mark as Resolved"))
                ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/complaint_provider.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  XFile? _image;
  Position? _position;
  bool _isLoading = false;

  Future<void> _captureImage() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    // Simple implementation for demo
    // In a real app, use a dedicated camera screen
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _image = image);
      _getLocation();
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() => _position = position);
  }

  void _submit() async {
    if (_image == null || _position == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide all details")));
      return;
    }

    setState(() => _isLoading = true);
    final bytes = await File(_image!.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    final success = await Provider.of<ComplaintProvider>(context, listen: false).createComplaint(
      title: _titleController.text,
      description: _descController.text,
      image: base64Image,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
    );

    setState(() => _isLoading = false);
    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Complaint")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title (e.g. Large Pothole)")),
            const SizedBox(height: 10),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
            const SizedBox(height: 20),
            _image != null 
              ? Image.file(File(_image!.path), height: 200)
              : ElevatedButton.icon(onPressed: _captureImage, icon: const Icon(Icons.camera_alt), label: const Text("Capture Image")),
            const SizedBox(height: 10),
            if (_position != null) Text("Location: ${_position!.latitude}, ${_position!.longitude}"),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _submit, child: const Text("Submit Complaint")),
          ],
        ),
      ),
    );
  }
}

// Helper to use ImagePicker

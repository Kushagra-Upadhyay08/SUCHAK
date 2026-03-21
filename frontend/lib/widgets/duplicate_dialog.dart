import 'dart:convert';
import 'package:flutter/material.dart';

class DuplicateDialog extends StatelessWidget {
  final Map<String, dynamic> existingComplaint;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DuplicateDialog({
    super.key,
    required this.existingComplaint,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    try {
      final imgString = existingComplaint['image']?.toString() ?? '';
      // If image is too large (e.g. > 1MB), skip it to avoid OOM crash on mobile
      if (imgString.isNotEmpty && imgString.length < 1000000) {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(imgString),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildImageError("Invalid image data"),
          ),
        );
      } else if (imgString.length >= 1000000) {
        imageWidget = _buildImageError("Image too large to preview");
      } else {
        imageWidget = _buildImageError("No image available");
      }
    } catch (e) {
      imageWidget = _buildImageError("Error loading image");
    }

    return AlertDialog(
      title: const Text("Similar Complaint Detected"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "A similar type of complaint is already registered from near your location.",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 15),
            imageWidget,
            const SizedBox(height: 10),
            Text("Title: ${existingComplaint['title'] ?? 'No Title'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Status: ${existingComplaint['status'] ?? 'Unknown'}"),
            const SizedBox(height: 15),
            const Text("Would you like to link your report to this existing complaint? This helps authorities prioritize the issue faster."),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text("Yes, Link My Report"),
        ),
      ],
    );
  }

  Widget _buildImageError(String message) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

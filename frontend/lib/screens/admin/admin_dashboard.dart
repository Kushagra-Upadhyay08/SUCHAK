import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../role_selection_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<ComplaintProvider>(context, listen: false).fetchComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final filteredComplaints = _filterStatus == 'ALL' 
        ? complaintProvider.complaints 
        : complaintProvider.complaints.where((c) => c.status == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredComplaints.length,
              itemBuilder: (context, index) {
                final complaint = filteredComplaints[index];
                return _buildComplaintCard(complaint);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: ['ALL', 'PENDING', 'VERIFIED', 'ASSIGNED', 'RESOLVED'].map((status) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(status),
              selected: _filterStatus == status,
              onSelected: (val) => setState(() => _filterStatus = status),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComplaintCard(complaint) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: ListTile(
        title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Status: ${complaint.status}\nBy: ${complaint.createdBy}"),
        trailing: _buildActionButtons(complaint),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildActionButtons(complaint) {
    if (complaint.status == 'PENDING') {
      return ElevatedButton(
        onPressed: () => Provider.of<ComplaintProvider>(context, listen: false).verifyComplaint(complaint.id),
        child: const Text("Verify"),
      );
    } else if (complaint.status == 'VERIFIED') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        onPressed: () => _showAssignDialog(complaint.id),
        child: const Text("Assign"),
      );
    }
    return const Icon(Icons.check_circle, color: Colors.green);
  }

  void _showAssignDialog(String id) {
    String engineerId = ""; // In a real app, this would be a selection from a list of engineers
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Assign Engineer"),
        content: TextField(
          decoration: const InputDecoration(labelText: "Engineer ID (demo: 123)"),
          onChanged: (val) => engineerId = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Provider.of<ComplaintProvider>(context, listen: false).assignComplaint(id, engineerId);
              Navigator.pop(context);
            }, 
            child: const Text("Assign")
          )
        ],
      ),
    );
  }
}

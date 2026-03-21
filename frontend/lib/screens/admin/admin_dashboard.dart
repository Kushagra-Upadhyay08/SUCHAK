import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/complaint_model.dart';
import '../common/map_screen.dart';
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
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen())),
          ),
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

  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: ListTile(
        onTap: () => _showComplaintDetails(complaint),
        title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: ${complaint.status}"),
            Text("By: ${complaint.createdBy}"),
            if (complaint.reportCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    "${complaint.reportCount} citizens facing the same problem",
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        trailing: _buildActionButtons(complaint),
        isThreeLine: true,
      ),
    );
  }

  void _showComplaintDetails(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(complaint.image),
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(complaint.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Status: ${complaint.status}", style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
              if (complaint.reportCount > 1)
                Text("${complaint.reportCount} combined reports", style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(complaint.description),
              const SizedBox(height: 10),
              Text("Reported by: ${complaint.createdBy}"),
              Text("Created: ${complaint.createdAt.toLocal().toString().split('.')[0]}"),
              if (complaint.verifiedAt != null) Text("Verified: ${complaint.verifiedAt!.toLocal().toString().split('.')[0]}"),
              if (complaint.assignedEngineerId != null) Text("Assigned To: ${complaint.assignedEngineerId}"),
            ],
          ),
        ),
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

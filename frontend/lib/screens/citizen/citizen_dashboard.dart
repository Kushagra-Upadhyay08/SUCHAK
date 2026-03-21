import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import 'create_complaint_screen.dart';
import '../role_selection_screen.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<ComplaintProvider>(context, listen: false).fetchComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Complaints"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: complaintProvider.complaints.isEmpty
          ? const Center(child: Text("No complaints yet. Report one!"))
          : ListView.builder(
              itemCount: complaintProvider.complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaintProvider.complaints[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Status: ${complaint.status}\nCreated: ${complaint.createdAt.toString().split('.')[0]}"),
                    trailing: Chip(
                      label: Text("${complaint.daysTaken}d"),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateComplaintScreen()));
        },
        label: const Text("Report Issue"),
        icon: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

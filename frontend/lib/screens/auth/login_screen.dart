import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../citizen/citizen_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../engineer/engineer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await auth.login(_nameController.text, _passwordController.text);
      if (success) {
        if (auth.user?.role != widget.role) {
          auth.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("You are not authorized as ${widget.role}")),
          );
          return;
        }
        _navigateToDashboard(auth.user!.role);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Failed: Invalid credentials")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard(String role) {
    Widget nextScreen;
    if (role == 'admin') {
      nextScreen = const AdminDashboard();
    } else if (role == 'engineer') {
      nextScreen = const EngineerDashboard();
    } else {
      nextScreen = const CitizenDashboard();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.role[0].toUpperCase()}${widget.role.substring(1)} Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _login, child: const Text("Login")),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen(role: widget.role)));
              }, 
              child: const Text("Don't have an account? Register")
            )
          ],
        ),
      ),
    );
  }
}

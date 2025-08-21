import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitsyncgemini/widgets/common/backend_status_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/viewmodels/auth_viewmodel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Backend connection status
          const BackendStatusWidget(),

          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Account'),
            subtitle: Text('Manage your account'),
          ),
          const ListTile(
            leading: Icon(Icons.palette),
            title: Text('Theme'),
            subtitle: Text('Customize app appearance'),
          ),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Notification preferences'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('App info and version'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
              // Clear navigation stack and go to /auth
              if (context.mounted) {
                context.go('/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

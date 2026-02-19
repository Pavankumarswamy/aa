import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/screens/auth/login_screen.dart';
import 'package:smartlearn/providers/content_provider.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/screens/admin/manage_courses_screen.dart';
import 'package:smartlearn/screens/admin/manage_users_screen.dart';
import 'package:smartlearn/screens/admin/admin_analytics_screen.dart';
import 'package:smartlearn/screens/admin/manage_badges_screen.dart';
import 'package:smartlearn/screens/admin/manage_certificates_screen.dart';
import 'package:smartlearn/screens/user/course_list_screen.dart';
import 'package:smartlearn/screens/admin/admin_profile_screen.dart';
import 'package:smartlearn/screens/admin/manage_media_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'View User Dashboard',
            icon: const Icon(Icons.person_pin),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CourseListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85, // Give more height than width
          children: [
            _buildDashboardCard(
              context,
              icon: Icons.auto_stories,
              title: 'Courses',
              subtitle: 'Manage curriculum',
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageCoursesScreen(),
                  ),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.analytics,
              title: 'Analytics',
              subtitle: 'View insights',
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminAnalyticsScreen(),
                  ),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.perm_media,
              title: 'Manage Media',
              subtitle: 'Pics, Blogs, Music',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageMediaScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.badge,
              title: 'Badges',
              subtitle: 'Manage rewards',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageBadgesScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.card_membership,
              title: 'Certificates',
              subtitle: 'Manage templates',
              color: Colors.red,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageCertificatesScreen(),
                  ),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.people,
              title: 'Users',
              subtitle: 'View all users',
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.build_circle,
              title: 'Fix Data',
              subtitle: 'Init Difficulty',
              color: Colors.deepOrange,
              onTap: () async {
                final contentProvider = Provider.of<ContentProvider>(
                  context,
                  listen: false,
                );
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                await contentProvider.migrateConceptDifficulties();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data migration complete!')),
                  );
                }
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.person,
              title: 'Profile',
              subtitle: 'Edit creator info',
              color: Colors.pink,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

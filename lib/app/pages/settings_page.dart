import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
import 'package:roomie_tasks/app/providers/theme_provider.dart';
import 'package:roomie_tasks/app/services/onboarding_service.dart';
import 'package:roomie_tasks/config/routes/routes.dart';
import 'package:roomie_tasks/dependency_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';
  final Uri githubRepoUrl =
      Uri.https('github.com', '/irangareddy/roomie_tasks');
  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildThemeSection(),
          _buildDataSection(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('Dark Mode'),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
        );
      },
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(
          thickness: 0.1,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('Google Sheets Setup'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.googleSheetsSetup),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('Reset Onboarding'),
          trailing: const Icon(Icons.refresh),
          onTap: _resetOnboarding,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('Wipe Off All Roomie Tasks'),
          trailing: const Icon(Icons.delete_forever),
          onTap: _wipeOffAssignedTasks,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(
          thickness: 0.1,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('Version'),
          trailing: Text(_appVersion),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('View Source Code'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchInBrowser(githubRepoUrl),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('License'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchInBrowser(Uri.parse(
              'https://github.com/irangareddy/roomie_tasks/blob/main/LICENSE',),),
        ),
        const Divider(
          thickness: 0.1,
          height: 30,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundImage: CachedNetworkImageProvider(
                  'https://avatars.githubusercontent.com/u/60821111?s=400&u=bdedf7f9e8d584477ead6e40ee85de418ec80061&v=4', // Replace with your actual image URL
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ranga Reddy Nukala',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Developer of Roomie Tasks',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Created Roomie Tasks in just 3 days. '
            'Expertise in mobile app development focusing on iOS and Flutter. '
            'Also a Data Engineer by profession.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialIcon(
                FontAwesomeIcons.linkedin,
                'https://www.linkedin.com/in/irangareddy',
              ),
              _buildSocialIcon(
                FontAwesomeIcons.xTwitter,
                'https://twitter.com/irangareddy',
              ),
              _buildSocialIcon(
                FontAwesomeIcons.instagram,
                'https://www.instagram.com/irangareddy',
              ),
              _buildSocialIcon(
                FontAwesomeIcons.github,
                'https://github.com/irangareddy',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '✨ If you like this app, please star the GitHub repository! 🌟\n'
            'Made with 💙 using Flutter 🚀',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () => _launchInBrowser(Uri.parse(url)),
    );
  }

  Future<void> _resetOnboarding() async {
    final onboardingService = sl<OnboardingService>();
    await onboardingService.resetOnboarding();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding reset. Please restart the app.'),
        ),
      );
    }
  }

  Future<void> _wipeOffAssignedTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wipe Off All Roomie Tasks'),
          content: const Text(
            // ignore: lines_longer_than_80_chars
            'Are you sure you want to delete all assigned tasks? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Wipe Off'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.wipeOffAssignedTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All assigned tasks have been wiped off.'),
          ),
        );
      }
    }
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}

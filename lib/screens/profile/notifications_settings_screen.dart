import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/notification_service.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends ConsumerState<NotificationsSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, bool> _settings = {
    'pushNotifications': true,
    'emailNotifications': true,
    'orderUpdates': true,
    'messages': true,
    'statusUpdates': true,
    'promotions': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(notificationServiceProvider).getNotificationSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(notificationServiceProvider).updateNotificationSettings(_settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        children: [
          // Notification Channels
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Notification Channels',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications on your device'),
            value: _settings['pushNotifications'] ?? true,
            onChanged: (value) {
              setState(() => _settings['pushNotifications'] = value);
            },
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive notifications via email'),
            value: _settings['emailNotifications'] ?? true,
            onChanged: (value) {
              setState(() => _settings['emailNotifications'] = value);
            },
          ),
          const Divider(),

          // Notification Types
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Notification Types',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Order Updates'),
            subtitle: const Text('Get notified about your order status'),
            value: _settings['orderUpdates'] ?? true,
            onChanged: _settings['pushNotifications'] == true ? (value) {
              setState(() => _settings['orderUpdates'] = value);
            } : null,
          ),
          SwitchListTile(
            title: const Text('Messages'),
            subtitle: const Text('Get notified about new messages'),
            value: _settings['messages'] ?? true,
            onChanged: _settings['pushNotifications'] == true ? (value) {
              setState(() => _settings['messages'] = value);
            } : null,
          ),
          SwitchListTile(
            title: const Text('Status Updates'),
            subtitle: const Text('Get notified about account and profile updates'),
            value: _settings['statusUpdates'] ?? true,
            onChanged: _settings['pushNotifications'] == true ? (value) {
              setState(() => _settings['statusUpdates'] = value);
            } : null,
          ),
          SwitchListTile(
            title: const Text('Promotions'),
            subtitle: const Text('Get notified about deals and promotions'),
            value: _settings['promotions'] ?? true,
            onChanged: _settings['pushNotifications'] == true ? (value) {
              setState(() => _settings['promotions'] = value);
            } : null,
          ),
        ],
      ),
    );
  }
} 
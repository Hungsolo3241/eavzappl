import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _receiveAllNotifications = true;
  bool _newMatchNotifications = true;
  bool _newLikeNotifications = true;
  bool _profileViewNotifications = true;
  bool _appUpdatesNotifications = true;
  bool _vibrate = true;
  // String _notificationTone = "Default";

  bool _isLoading = true; // For loading state

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      log("Error: User not logged in. Cannot load notification settings.", name: 'NotificationsScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notification_settings')
          .get();

      if (settingsDoc.exists && settingsDoc.data() != null) {
        Map<String, dynamic> data = settingsDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _receiveAllNotifications = data['receiveAllNotifications'] ?? true;
            _newMatchNotifications = data['newMatchNotifications'] ?? true;
            _newLikeNotifications = data['newLikeNotifications'] ?? true;
            _profileViewNotifications =
                data['profileViewNotifications'] ?? true;
            _appUpdatesNotifications =
                data['appUpdatesNotifications'] ?? true;
            _vibrate = data['vibrate'] ?? true;
            // _notificationTone = data['notificationTone'] ?? "Default";
          });
        }
      } else {
        log("Notification settings not found, initializing with defaults for user $userId.", name: 'NotificationsScreen');
        await _saveAllSettings(userId); // Save initial defaults based on current state variables
      }
    } catch (e) {
      log("Error loading notification settings: $e", name: 'NotificationsScreen');
      // Handle error, maybe show a snackbar or use default values
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAllSettings(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notification_settings')
          .set({
        'receiveAllNotifications': _receiveAllNotifications,
        'newMatchNotifications': _newMatchNotifications,
        'newLikeNotifications': _newLikeNotifications,
        'profileViewNotifications': _profileViewNotifications,
        'appUpdatesNotifications': _appUpdatesNotifications,
        'vibrate': _vibrate,
        // 'notificationTone': _notificationTone,
      });
      log("Initial notification settings saved for user $userId", name: 'NotificationsScreen');
    } catch (e) {
      log("Error saving initial notification settings: $e", name: 'NotificationsScreen');
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      log("Error: User not logged in. Cannot update notification settings.", name: 'NotificationsScreen');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notification_settings')
          .set({key: value}, SetOptions(merge: true));
      log("Notification setting '$key' updated to '$value'", name: 'NotificationsScreen');
    } catch (e) {
      log("Error updating notification setting '$key': $e", name: 'NotificationsScreen');
      // Optionally, revert UI change or show an error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text("Notification Settings")),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
      ),
      body: _buildSettingsList(),
    );
  }

  Widget _buildSettingsList() {
    return ListView(
      children: <Widget>[
        SwitchListTile(
          title: const Text("Receive All Notifications"),
          subtitle: const Text("Master switch for all app notifications"),
          value: _receiveAllNotifications,
          onChanged: (bool value) {
            setState(() {
              _receiveAllNotifications = value;
              // If master is turned off, turn all others off.
              // If master is turned on, turn all others on.
              _newMatchNotifications = value;
              _newLikeNotifications = value;
              _profileViewNotifications = value;
              _appUpdatesNotifications = value;
              // Note: _vibrate could be independent or also controlled by master.
              // For now, let's also tie it to the master switch for consistency.
              _vibrate = value;
            });

            // Update Firestore for the master switch
            _updateSetting('receiveAllNotifications', value);

            // Update Firestore for all subsidiary settings based on the new master value
            _updateSetting('newMatchNotifications', value);
            _updateSetting('newLikeNotifications', value);
            _updateSetting('profileViewNotifications', value);
            _updateSetting('appUpdatesNotifications', value);
            _updateSetting('vibrate', value); // Also update vibrate setting
          },
          secondary: Icon(_receiveAllNotifications
              ? Icons.notifications_active
              : Icons.notifications_off),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Detailed Preferences",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
        SwitchListTile(
          title: const Text("New Match Alerts"),
          value: _newMatchNotifications,
          onChanged: _receiveAllNotifications
              ? (bool value) {
                  setState(() {
                    _newMatchNotifications = value;
                  });
                  _updateSetting('newMatchNotifications', value);
                }
              : null,
        ),
        SwitchListTile(
          title: const Text("New Like Alerts"),
          value: _newLikeNotifications,
          onChanged: _receiveAllNotifications
              ? (bool value) {
                  setState(() {
                    _newLikeNotifications = value;
                  });
                  _updateSetting('newLikeNotifications', value);
                }
              : null,
        ),
        SwitchListTile(
          title: const Text("Profile View Alerts"),
          value: _profileViewNotifications,
          onChanged: _receiveAllNotifications
              ? (bool value) {
                  setState(() {
                    _profileViewNotifications = value;
                  });
                  _updateSetting('profileViewNotifications', value);
                }
              : null,
        ),
        SwitchListTile(
          title: const Text("App News & Updates"),
          value: _appUpdatesNotifications,
          onChanged: _receiveAllNotifications
              ? (bool value) {
                  setState(() {
                    _appUpdatesNotifications = value;
                  });
                  _updateSetting('appUpdatesNotifications', value);
                }
              : null,
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Sound & Vibration",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
        SwitchListTile(
          title: const Text("Vibrate"),
          value: _vibrate,
          onChanged: _receiveAllNotifications // Vibration can also be tied to master switch or be independent
              ? (bool value) {
                  setState(() {
                    _vibrate = value;
                  });
                  _updateSetting('vibrate', value);
                }
              : null,
        ),
        // ListTile(
        //   title: const Text("Notification Tone"),
        //   subtitle: Text(_notificationTone),
        //   onTap: _receiveAllNotifications ? () {
        //     // TODO: Open a dialog or new screen to select a tone
        //     print("Select tone tapped");
        //   } : null,
        // ),
      ],
    );
  }
}

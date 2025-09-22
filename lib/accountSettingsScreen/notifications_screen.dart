import 'package:flutter/material.dart';
// TODO: Import Firebase and any other necessary packages for saving settings

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // --- Placeholder State for Notification Settings ---
  // In a real implementation, these would be fetched from and saved to Firestore.
  bool _receiveAllNotifications = true; // Master switch
  bool _newMatchNotifications = true;
  bool _newLikeNotifications = true;
  bool _profileViewNotifications = true;
  bool _appUpdatesNotifications = true; // Example: for general app news/updates
  bool _vibrate = true;
  // String _notificationTone = "Default"; // Example if allowing tone selection

  // TODO: Add a loading state
  // bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Implement fetching settings from Firestore
    // setState(() {
    //   _receiveAllNotifications = ...;
    //   _newMatchNotifications = ...;
    //   // ... and so on
    //   _isLoading = false;
    // });
    // For now, using placeholder values.
    setState(() {
      // _isLoading = false; // Uncomment when actual loading happens
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    // TODO: Implement saving the specific setting 'key' with 'value' to Firestore
    // Example: FirebaseFirestore.instance.collection('users').doc(userId).collection('preferences').doc('notification_settings').update({key: value});
    print("Setting $key updated to $value"); // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    // if (_isLoading) {
    //   return Scaffold(appBar: AppBar(title: const Text("Notification Settings")), body: Center(child: CircularProgressIndicator()));
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
        // Your app's common AppBar styling
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
              // If master is turned off, perhaps turn all others off too?
              if (!value) {
                _newMatchNotifications = false;
                _newLikeNotifications = false;
                _profileViewNotifications = false;
                _appUpdatesNotifications = false;
              }
            });
            _updateSetting('receiveAllNotifications', value);
            if(!value) { // Also update subsidiary settings if master is off
              _updateSetting('newMatchNotifications', false);
              _updateSetting('newLikeNotifications', false);
              _updateSetting('profileViewNotifications', false);
              _updateSetting('appUpdatesNotifications', false);
            }
          },
          secondary: Icon(_receiveAllNotifications ? Icons.notifications_active : Icons.notifications_off),
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
          onChanged: _receiveAllNotifications ? (bool value) { // Only allow change if master is on
            setState(() {
              _newMatchNotifications = value;
            });
            _updateSetting('newMatchNotifications', value);
          } : null, // Disable if master is off
        ),
        SwitchListTile(
          title: const Text("New Like Alerts"),
          value: _newLikeNotifications,
          onChanged: _receiveAllNotifications ? (bool value) {
            setState(() {
              _newLikeNotifications = value;
            });
            _updateSetting('newLikeNotifications', value);
          } : null,
        ),
        SwitchListTile(
          title: const Text("Profile View Alerts"),
          value: _profileViewNotifications,
          onChanged: _receiveAllNotifications ? (bool value) {
            setState(() {
              _profileViewNotifications = value;
            });
            _updateSetting('profileViewNotifications', value);
          } : null,
        ),
        SwitchListTile(
          title: const Text("App News & Updates"),
          value: _appUpdatesNotifications,
          onChanged: _receiveAllNotifications ? (bool value) {
            setState(() {
              _appUpdatesNotifications = value;
            });
            _updateSetting('appUpdatesNotifications', value);
          } : null,
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
          onChanged: _receiveAllNotifications ? (bool value) { // Vibrate can also be independent or tied to master
            setState(() {
              _vibrate = value;
            });
            _updateSetting('vibrate', value);
          } : null,
        ),
        // Example for a sound preference (more complex to implement fully)
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

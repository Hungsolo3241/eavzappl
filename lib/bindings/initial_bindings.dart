// lib/bindings/initial_bindings.dart

import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/controllers/like_controller.dart';
import 'package:eavzappl/controllers/location_controller.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:eavzappl/pushNotifications/push_notifications.dart';
class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthenticationController());

    // These controllers need to persist throughout the user's session.
    Get.put(ProfileController(), permanent: true);
    Get.put(LikeController(), permanent: true);
    Get.put(PushNotifications(), permanent: true);
    // These can be created on demand.
    Get.lazyPut(() => LocationController(), fenix: true);
    Get.lazyPut(() => FilterPreferences(), fenix: true);
  }
}

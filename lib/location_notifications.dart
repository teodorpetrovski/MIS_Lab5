import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:lab5/main.dart';
import 'package:location/location.dart';

class LocationNotificationService {
  int id = 1;
  static Faculty campus = Faculty(
      name: "Campus",
      longitude: 21.409333319543716,
      latitude: 42.004245732111556);
  DateTime? lastNotification;
  Location _locationController = new Location();

  LocationNotificationService() {
    Timer.periodic(const Duration(seconds: 20), (timer) {
      checkLocationAndNotify();
    });
  }

  Future<void> checkLocationAndNotify() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        if (isInRange(currentLocation.latitude, currentLocation.longitude,
            campus.latitude, campus.longitude)) {
          if (canSendNotification()) {
            lastNotification = DateTime.now();
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: id++,
                channelKey: "basic_channel",
                title: "Location reached!",
                body: "You are close to your campus for the exam!",
              ),
            );
          }
        }
      }
    });
  }

  bool canSendNotification() {
    if (lastNotification == null) {
      return true;
    }

    return DateTime.now().difference(lastNotification!) >
        const Duration(minutes: 30);
  }

  bool isInRange(double? currentLat, double? currentLon, double targetLat,
      double targetLon) {
    return (currentLat! - targetLat).abs() <= 0.01 &&
        (currentLon! - targetLon).abs() <= 0.01;
  }
}

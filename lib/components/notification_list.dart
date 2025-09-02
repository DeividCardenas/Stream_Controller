import 'package:flutter/material.dart';
import 'package:stream_controller/services/notification_service.dart';

class NotificationList extends StatelessWidget {
  final NotificationService notificationService;

  const NotificationList({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: notificationService.notificationStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            'Total de notificaciones: ${snapshot.data}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

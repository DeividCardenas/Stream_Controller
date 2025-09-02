import 'dart:async';

class NotificationService {
  // Crear un Broadcast StreamController
  final StreamController<int> _notificationController =
      StreamController<int>.broadcast();

  // Método para obtener el Stream
  Stream<int> get notificationStream => _notificationController.stream;

  // Método para agregar nuevas notificaciones
  void addNotification(int count) {
    _notificationController.add(count);
  }

  // Cerrar el StreamController cuando ya no sea necesario
  void dispose() {
    _notificationController.close();
  }
}

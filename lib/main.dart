import 'package:dogcare/entities/perro.dart';
import 'package:dogcare/views/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:dogcare/views/Perros.dart';
import 'package:dogcare/views/FichaPerro.dart';
import 'package:dogcare/views/Consultas.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar zonas horarias
  tz.initializeTimeZones();

  // Inicialización de notificaciones
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App',
      initialRoute: '/',
      routes: {
        '/': (context) => const Dashboard(),
        '/perros': (context) => const PerrosScreen(),
        '/ficha_perro': (context) =>
            FichaPerro(perro: ModalRoute.of(context)!.settings.arguments as Perro),
        '/consultas': (context) => const ConsultasVeterinariasScreen(),
      },
    );
  }
}

// Función para programar notificación
Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tzScheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'dogcare_channel',
        'DogCare Avisos',
        channelDescription: 'Notificaciones de avisos de mascotas',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // para hora específica
  );
}

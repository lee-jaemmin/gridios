import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prost/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:prost/constants/sizes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prost/screens/home_screen.dart';
import 'package:prost/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("백그라운드 메시지 수신: ${message.messageId}");
}

// iOS 전용 수동 알림 표시 함수
void _showIOSNotification(RemoteNotification notification) {
  flutterLocalNotificationsPlugin.show(
    id: notification.hashCode,
    title: notification.title,
    body: notification.body,
    notificationDetails: const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: false, // 화면에 알림 배너 표시
        presentBadge: true, // 앱 아이콘에 숫자 표시
        presentSound: false, // 알림 소리 재생
      ),
    ),
  );
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Prost());

  _initAsyncTasks();
}

Future<void> _initAsyncTasks() async {
  await FirebaseAppCheck.instance.activate(
    // 웹 환경이 아니라면 androidProvider에 Play Integrity를 설정합니다.
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
  );

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // 2. 플러그인 초기화 실행
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await requestNotificationPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    AppleNotification? apple = message.notification?.apple;

    if (notification != null) {
      if (Platform.isAndroid && android != null) {
        // 안드로이드 수동 알림
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  });
}

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('사용자가 알림 권한을 승인했습니다.');
  } else {
    print('사용자가 알림 권한을 거절했습니다.');
  }
}

class Prost extends StatelessWidget {
  const Prost({super.key});

  @override
  Widget build(BuildContext context) {
    const seedGreen = Color(0xFF16A34A); // 원하는 초록

    final scheme = ColorScheme.fromSeed(
      seedColor: seedGreen,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Prost',
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.green.shade600,
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: Sizes.size18,
            color: Colors.black,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const UnderlineInputBorder(),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          floatingLabelStyle: TextStyle(color: scheme.primary),
        ),
        // 진행바 색
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: scheme.primary,
        ),
        // BottomNavigationBar 색
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: scheme.surface,
          selectedItemColor: scheme.primary,
          unselectedItemColor: scheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. 로그인 정보가 있으면 -> 홈 화면으로
          if (snapshot.hasData) {
            return HomeScreen();
          }
          // 2. 없으면 -> 로그인 화면으로
          return const LoginScreen();
        },
      ),
    );
  }
}

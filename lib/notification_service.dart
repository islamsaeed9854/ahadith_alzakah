import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  final List<String> hadiths = [
    "قال رسول الله صلى الله عليه وسلم: من صلى البردين دخل الجنة",
    "قال رسول الله صلى الله عليه وسلم: خيركم من تعلم القرآن وعلمه",
    "قال رسول الله صلى الله عليه وسلم: الدعاء هو العبادة",
  ];

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'daily_hadith_channel',
          channelName: 'Daily Hadith',
          channelDescription: 'Daily Hadith notifications',
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> scheduleDailyHadithNotification() async {
    final hadith = hadiths[DateTime.now().day % hadiths.length];
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:100,
        channelKey: 'daily_hadith_channel',
        title: 'حديث اليوم',
        body: hadith,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 20,
        minute: 7,
        second: 0,
        repeats: true,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> cancelNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
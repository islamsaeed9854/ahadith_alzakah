import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  final List<String> hadiths = [
    "قال رسول الله صلى الله عليه وسلم: من صلى البردين دخل الجنة",
    "قال رسول الله صلى الله عليه وسلم: خيركم من تعلم القرآن وعلمه",
    "قال رسول الله صلى الله عليه وسلم: الدعاء هو العبادة",
  ];

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/logo.png',
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

    // فحص وطلب إذن الإشعارات
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
       // id: DateTime.now().millisecondsSinceEpoch.remainder(100000), // ID فريد
        channelKey: 'daily_hadith_channel',
        title: 'حديث اليوم',
        body: hadith,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 12,
        minute: 15,
        second: 0,
        repeats: true,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
    print('Notification scheduled for hadith: $hadith at 12:15 PM');
  }

  Future<void> cancelNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
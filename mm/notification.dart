import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FirebaseMessaging _messaging;
  String? _token;
  String subscriptionStatus = "Not subscribed";
  List<String> notifications = [];

  @override
  void initState() {
    super.initState();
    _messaging = FirebaseMessaging.instance;
    _messaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        notifications.insert(
          0,
          "${message.notification?.title ?? 'No Title'} - ${message.notification?.body ?? 'No Body'}",
        );
      });
    });
  }

  Future<void> _subscribe() async {
    try {
      _token = await _messaging.getToken();
      print("FCM Token: $_token");

      final response = await http.post(
        Uri.parse("http://192.168.0.103:5000/subscribe"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': 'user1', 'token': _token}),
      );

      setState(() {
        subscriptionStatus = response.statusCode == 200
            ? "Subscribed successfully"
            : "Subscription failed";
      });
    } catch (e) {
      setState(() {
        subscriptionStatus = "Error: $e";
      });
    }
  }

  Future<void> _unsubscribe() async {
    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/unsubscribe"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': 'user1'}),
      );

      setState(() {
        subscriptionStatus = response.statusCode == 200
            ? "Unsubscribed successfully"
            : "Unsubscribe failed";
      });
    } catch (e) {
      setState(() {
        subscriptionStatus = "Error: $e";
      });
    }
  }

  Future<void> _refreshToken() async {
    _token = await _messaging.getToken(); // force refresh
    setState(() {});
  }

  void _testNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Pretend a test notification was received.")),
    );

    setState(() {
      notifications.insert(0, "🔔 Test Notification - Hello from Flutter!");
    });
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed,
      {Color? color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Push Notifications Demo",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Push Notifications"),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 2,
                child: ListTile(
                  title: const Text("Subscription Status"),
                  subtitle: Text(subscriptionStatus),
                  leading: const Icon(Icons.notifications_active),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildButton("Subscribe", Icons.subscriptions, _subscribe),
                  _buildButton("Unsubscribe", Icons.cancel, _unsubscribe,
                      color: Colors.redAccent),
                  _buildButton("Refresh Token", Icons.refresh, _refreshToken),
                  _buildButton(
                      "Test Notification", Icons.send, _testNotification,
                      color: Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: ExpansionTile(
                  title: const Text("FCM Token (Click to Expand)"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SelectableText(_token ?? "Token not generated"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: notifications.isEmpty
                    ? const Center(
                        child: Text("No notifications received yet."))
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 1,
                            child: ListTile(
                              leading: const Icon(Icons.message),
                              title: Text(notifications[index]),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

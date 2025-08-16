import 'package:flutter/material.dart';

class ViewSentViewReceivedScreen extends StatefulWidget {
  const ViewSentViewReceivedScreen({super.key});

  @override
  State<ViewSentViewReceivedScreen> createState() => _ViewSentViewReceivedScreenState();
}

class _ViewSentViewReceivedScreenState extends State<ViewSentViewReceivedScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          child: Text(
            "View Sent View Received",
            style: TextStyle(
              color: Colors.green,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
    );
  }
}

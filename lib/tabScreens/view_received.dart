import 'package:flutter/material.dart';

class ViewReceivedScreen extends StatefulWidget {
  const ViewReceivedScreen({super.key});

  @override
  State<ViewReceivedScreen> createState() => _ViewReceivedScreenState();
}

class _ViewReceivedScreenState extends State<ViewReceivedScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          child: Text(
            "View Received",
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
    );
  }
}

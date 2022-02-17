import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecordingsSaved extends StatefulWidget {
  RecordingsSaved();

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _RecordingsSavedState createState() => _RecordingsSavedState();
}

class _RecordingsSavedState extends State<RecordingsSaved>
    with WidgetsBindingObserver {
  late User user;

  // Wakelock.toggle(enable: isPlaying);

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void backButton() {
    // print("Back button pressed");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    user = ModalRoute.of(context)!.settings.arguments as User;
    print(user.email);
    return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: Container());
  }
}

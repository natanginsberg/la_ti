import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JamsSaved extends StatefulWidget {
  JamsSaved();

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _JamsSavedState createState() => _JamsSavedState();
}

class _JamsSavedState extends State<JamsSaved> with WidgetsBindingObserver {
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

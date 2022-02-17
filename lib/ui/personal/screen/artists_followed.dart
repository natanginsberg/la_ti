import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ArtistsFollowed extends StatefulWidget {
  ArtistsFollowed();

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _ArtistsFollowedState createState() => _ArtistsFollowedState();
}

class _ArtistsFollowedState extends State<ArtistsFollowed> with WidgetsBindingObserver {
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

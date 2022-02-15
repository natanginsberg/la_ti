import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JamsSaved extends StatefulWidget {
  JamsSaved();

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _JamsSavedState createState() => _JamsSavedState();
}

class _JamsSavedState extends State<JamsSaved>
    with WidgetsBindingObserver {
  late User user;
  UserDisplayOption itemsDisplayed = UserDisplayOption.uploadedRecordings;

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
        child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                  title: Row(children: [
                    const Text("La-Ci"),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                    ),
                  ])),
              body: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            primary: itemsDisplayed ==
                                UserDisplayOption.uploadedRecordings
                                ? Colors.blueAccent
                                : Colors.white,
                            side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 15.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              'Uploaded Recordings',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: itemsDisplayed ==
                                      UserDisplayOption.uploadedRecordings
                                      ? Colors.white
                                      : Colors.blueAccent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            primary:
                            itemsDisplayed == UserDisplayOption.savedRecordings
                                ? Colors.blueAccent
                                : Colors.white,
                            side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 15.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              'Saved Recordings',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: itemsDisplayed ==
                                      UserDisplayOption.savedRecordings
                                      ? Colors.white
                                      : Colors.blueAccent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              primary:
                              itemsDisplayed == UserDisplayOption.artistFollowed
                                  ? Colors.blueAccent
                                  : Colors.white,
                              side: const BorderSide(color: Colors.blueAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 15.0,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Text(
                                'People I Follow',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: itemsDisplayed ==
                                        UserDisplayOption.artistFollowed
                                        ? Colors.white
                                        : Colors.blueAccent),
                              ),
                            ),
                          )),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            primary: itemsDisplayed == UserDisplayOption.savedJams
                                ? Colors.blueAccent
                                : Colors.white,
                            side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 15.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              'My Jams',
                              style: TextStyle(
                                  fontSize: 20,
                                  color:
                                  itemsDisplayed == UserDisplayOption.savedJams
                                      ? Colors.white
                                      : Colors.blueAccent),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),

                ],
              ),
            )));
  }
}

enum UserDisplayOption {
  uploadedRecordings,
  artistFollowed,
  savedJams,
  savedRecordings
}

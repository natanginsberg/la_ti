import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:la_ti/model/jam.dart';

import 'jams_saved.dart';
import 'uploaded_recordings.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({Key? key}) : super(key: key);

  @override
  _PersonalScreenState createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen>
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
    return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: MaterialApp(
            home: Scaffold(
          appBar: AppBar(
              title: Row(children: [
            const Text("La-Si"),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
            ),
          ])),
          body: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              topRow(),
              if (itemsDisplayed == UserDisplayOption.uploadedRecordings)
                Flexible(child: UploadedRecordings())
              else if (itemsDisplayed == UserDisplayOption.savedJams)
                Flexible(
                    child: JamsSaved(
                  openJam: openJam,
                ))
            ],
          ),
        )));
  }

  topRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (itemsDisplayed != UserDisplayOption.uploadedRecordings) {
                setState(() {
                  itemsDisplayed = UserDisplayOption.uploadedRecordings;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              primary: itemsDisplayed == UserDisplayOption.uploadedRecordings
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
                AppLocalizations.of(context)!.uploadedRecordingsTitle,
                style: TextStyle(
                    fontSize: 20,
                    color:
                        itemsDisplayed == UserDisplayOption.uploadedRecordings
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
            onPressed: () {
              if (itemsDisplayed != UserDisplayOption.savedRecordings) {
                setState(() {
                  itemsDisplayed = UserDisplayOption.savedRecordings;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              primary: itemsDisplayed == UserDisplayOption.savedRecordings
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
                AppLocalizations.of(context)!.saveRecordingsTitle,
                style: TextStyle(
                    fontSize: 20,
                    color: itemsDisplayed == UserDisplayOption.savedRecordings
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
          onPressed: () {
            if (itemsDisplayed != UserDisplayOption.artistFollowed) {
              setState(() {
                itemsDisplayed = UserDisplayOption.artistFollowed;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            primary: itemsDisplayed == UserDisplayOption.artistFollowed
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
              AppLocalizations.of(context)!.followingArtistsTitle,
              style: TextStyle(
                  fontSize: 20,
                  color: itemsDisplayed == UserDisplayOption.artistFollowed
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
            onPressed: () {
              if (itemsDisplayed != UserDisplayOption.savedJams) {
                setState(() {
                  itemsDisplayed = UserDisplayOption.savedJams;
                });
              }
            },
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
                AppLocalizations.of(context)!.savedJamsTitle,
                style: TextStyle(
                    fontSize: 20,
                    color: itemsDisplayed == UserDisplayOption.savedJams
                        ? Colors.white
                        : Colors.blueAccent),
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
      ],
    );
  }

  openJam(Jam jam) {
    Navigator.of(context).pop(jam);
  }
}

enum UserDisplayOption {
  uploadedRecordings,
  artistFollowed,
  savedJams,
  savedRecordings
}

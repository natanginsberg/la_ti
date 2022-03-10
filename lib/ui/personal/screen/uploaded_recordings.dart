import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:la_ti/model/display_recording_uploader.dart';
import 'package:la_ti/model/recording.dart';
import 'package:la_ti/utils/firebase_access/songs.dart';
import 'package:la_ti/utils/wasabi_uploader.dart';

import '../../../utils/main_screen/custom_url_audio_player.dart';

class UploadedRecordings extends StatefulWidget {
  UploadedRecordings();

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _UploadedRecordingsState createState() => _UploadedRecordingsState();
}

class _UploadedRecordingsState extends State<UploadedRecordings>
    with WidgetsBindingObserver {
  late User user;
  UserDisplayOption itemsDisplayed = UserDisplayOption.uploadedRecordings;
  List<DisplayRecordingUploader> itemToDisplay = [];

  bool pageLoaded = false;

  // Wakelock.toggle(enable: isPlaying);

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser!;
    getRecordings();
    super.initState();
  }

  void backButton() {
    // print("Back button pressed");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // return FutureBuilder(
    //   builder: (context, recordingSnap) {
    //     if (recordingSnap.connectionState == ConnectionState.none &&
    //         recordingSnap.hasData) {
    //       return Container();
    //     } else if (recordingSnap.connectionState == ConnectionState.waiting) {
    //       return const CupertinoActivityIndicator();
    //     } else {
    //       if (recordingSnap.data == null) {
    //         return const Center(
    //           child: Text(
    //             "You have not uploaded any recording",
    //             style: TextStyle(fontSize: 24, color: Colors.blueAccent),
    //           ),
    //         );
    //       }
    //       List<DisplayRecordingUploader> items =
    //           recordingSnap.data as List<DisplayRecordingUploader>;
    //       if (items.isEmpty) {
    //         return const Center(
    //           child: Text(
    //             "You have not uploaded any recording",
    //             style: TextStyle(fontSize: 24, color: Colors.blueAccent),
    //           ),
    //         );
    //       }
    //       return buildGrid(items);
    //     }
    //   },
    //   future: getRecordings(),
    // );
    if (pageLoaded) {
      if (itemToDisplay.isEmpty) {
        return const Center(
          child: Text(
            "You have not uploaded any recording",
            style: TextStyle(fontSize: 24, color: Colors.blueAccent),
          ),
        );
      }
      return buildGrid(itemToDisplay);
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  getRecordings() async {
    if (pageLoaded) {
      return itemToDisplay;
    }

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection("recordings")
        .get();
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      if ((doc.data() as Map).containsKey("recordingId")) {
        DocumentSnapshot recordingDoc = await FirebaseFirestore.instance
            .collection("songs")
            .doc(doc.get("songId"))
            .collection("sessions")
            .doc(doc.get("sessionId"))
            .collection("recordings")
            .doc(doc.get("recordingId"))
            .get();
        // for (QueryDocumentSnapshot recordingDoc in recordingsInSession.docs) {
        if (recordingDoc.exists) {
          CustomUrlAudioPlayer customUrlAudioPlayer = getCustomPlayer(
              recordingDoc.data() as Map<String, dynamic>, recordingDoc.id);
          itemToDisplay.add(DisplayRecordingUploader(
              doc.get("songName"),
              doc.get("songArtist"),
              doc.get('songId'),
              doc.get('sessionId'),
              recordingDoc.id,
              doc.id,
              customUrlAudioPlayer));
        }
      } else {
        QuerySnapshot recordingsInSession = await FirebaseFirestore.instance
            .collection("songs")
            .doc(doc.get("songId"))
            .collection("sessions")
            .doc(doc.get("sessionId"))
            .collection("recordings")
            .where("userUploadId", isEqualTo: user.uid)
            .get();
        for (QueryDocumentSnapshot recordingDoc in recordingsInSession.docs) {
          if (recordingDoc.exists) {
            CustomUrlAudioPlayer customUrlAudioPlayer = getCustomPlayer(
                recordingDoc.data() as Map<String, dynamic>, recordingDoc.id);
            itemToDisplay.add(DisplayRecordingUploader(
                doc.get("songName"),
                doc.get("songArtist"),
                // doc.get("dateUploaded"),
                // recordingDoc.get("jamsIn"),
                // doc.get("url"),
                // recordingDoc.get("delay"),
                doc.get('songId'),
                doc.get('sessionId'),
                recordingDoc.id,
                doc.id,
                customUrlAudioPlayer));
          }
        }
      }
    }
    setState(() {
      pageLoaded = true;
    });
    return itemToDisplay;
  }

  Widget buildGrid(List<DisplayRecordingUploader> items) {
    pageLoaded = true;
    return GridView.builder(
      shrinkWrap: false,
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildGridItem(item);
      },
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 0.85,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15),
    );
  }

  Widget _buildGridItem(DisplayRecordingUploader item) {
    String jamsIn = item.customUrlAudioPlayer.recording.jamsIn.toString();
    String artist = item.artistName;
    String songName = item.songName;
    String dateUploaded = item.customUrlAudioPlayer.recording.uploadDate;
    return Container(
      color: Colors.blueAccent,
      width: 400,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height: 300, child: item.customUrlAudioPlayer.playWidget()),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Song Name: $songName",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Artist: $artist",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Date uploaded: $dateUploaded",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Used in $jamsIn jams",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Column(
              children: [
                IconButton(
                  iconSize: 40,
                  icon: item.customUrlAudioPlayer.playPressed
                      ? const Icon(Icons.stop_circle)
                      : const Icon(Icons.play_circle_fill),
                  onPressed: () async {
                    if (item.customUrlAudioPlayer.playPressed) {
                      item.customUrlAudioPlayer.stop();
                      setState(() {
                        item.customUrlAudioPlayer.playPressed = false;
                      });
                    } else {
                      await item.customUrlAudioPlayer.play();
                      setState(() {
                        item.customUrlAudioPlayer.playPressed = true;
                      });
                    }
                  },
                ),
                IconButton(
                    iconSize: 40,
                    onPressed: () {
                      String url = item.customUrlAudioPlayer.recording.url;
                      SongDatabase().deleteFromWasabi(url.split('/').last);
                      FirebaseSongs().removeVideoFromSpecificSong(
                          item.songId, item.sessionId, item.recordingId);
                      FirebaseSongs().removeFromMainScreen(url);
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection("recordings")
                          .doc(item.userSongId)
                          .delete();
                      itemToDisplay.remove(item);
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  CustomUrlAudioPlayer getCustomPlayer(
      Map<String, dynamic> docData, String id) {
    Recording recording = Recording(docData["url"], docData["delay"], id,
        !(docData["url"] as String).contains("AUDIO_ONLY"));

    // these are for later on when we have more data
    if (docData.containsKey("jamsIn")) recording.jamsIn = docData["jamsIn"];
    if (docData.containsKey("instrument")) {
      recording.instrument = docData["instrument"];
    }
    if (docData.containsKey("userUploadDisplayName")) {
      recording.uploaderDisplayName = docData["userUploadDisplayName"];
    }
    if (docData.containsKey("dateUploaded")) {
      recording.uploadDate = docData["dateUploaded"];
    }
    if (docData.containsKey("userUploadId")) {
      recording.uploaderId = docData["userUploadId"];
    }
    // CustomUrlAudioPlayer customUrlAudioPlayer =
    return CustomUrlAudioPlayer(recording, () {}, docData["delay"]);
  }
}

enum UserDisplayOption {
  uploadedRecordings,
  artistFollowed,
  savedJams,
  savedRecordings
}

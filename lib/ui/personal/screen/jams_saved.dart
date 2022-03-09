import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../model/jam.dart';

class JamsSaved extends StatefulWidget {
  Function(Jam) openJam;
  JamsSaved({Key? key, required this.openJam}) : super(key: key);

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
    user = FirebaseAuth.instance.currentUser!;
    return FutureBuilder(
      builder: (context, jamSnap) {
        if (jamSnap.connectionState == ConnectionState.none &&
            jamSnap.hasData) {
          return Container();
        } else if (jamSnap.connectionState == ConnectionState.waiting) {
          return const CupertinoActivityIndicator();
        } else {
          if (jamSnap.data == null) {
            print("some data");
            return const Center(
              child: Text(
                "You have not saved any jams",
                style: TextStyle(fontSize: 24, color: Colors.blueAccent),
              ),
            );
          }
          List<Jam> items = jamSnap.data as List<Jam>;
          if (items.isEmpty) {
            print("other data");
            return const Center(
              child: Text(
                "You have not saved any jams",
                style: TextStyle(fontSize: 24, color: Colors.blueAccent),
              ),
            );
          }
          return buildGrid(items);
        }
      },
      future: getJams(),
    );
  }

  getJams() async {
    List<Jam> jamsToDisplay = [];
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection("jams")
        .get();
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Jam jam = Jam(
          sessionId: doc.get("sessionId"),
          songId: doc.get("songId"),
          songName: doc.get("songName"),
          artistName: doc.get("artistName"),
          instruments: List.from(doc.get("instruments")),
          recordings: List.from(doc.get("recordings")));
      jam.jamId = doc.id;
      jamsToDisplay.add(jam);
    }

    return jamsToDisplay;
  }

  Widget buildGrid(List<Jam> items) {
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

  Widget _buildGridItem(Jam jam) {
    String artist = jam.artistName;
    String songName = jam.songName;
    return Container(
        color: Colors.blueAccent,
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "Song Name: $songName",
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Artist: $artist",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(
              height: 10,
            ),
            ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: jam.instruments.length,
              itemBuilder: (context, index) {
                final item = jam.instruments[index];
                return _buildListItem(item);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {widget.openJam(jam);},
                  icon: const Icon(
                    Icons.library_music,
                    color: Colors.orange,
                  ),
                  iconSize: 40,
                ),
                IconButton(
                    iconSize: 40,
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection("jams")
                          .doc(jam.jamId)
                          .delete();
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    )),
              ],
            ),
          ],
        ));
  }

  Widget _buildListItem(String item) {
    return ListTile(
      title: Text(
        item,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

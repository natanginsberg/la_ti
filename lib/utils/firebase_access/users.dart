import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:la_ti/model/jam_instruments.dart';

import '../../model/jam.dart';
import '../../model/song.dart';

class FirebaseUsers {
  updateFollowingList(String docId, List<String> artistsFollowed) {
    FirebaseFirestore.instance
        .collection("users")
        .doc(docId)
        .update({"artistFollowed": artistsFollowed});
  }

  addRecordingToUser(Song currentSong, String docId, User user) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("recordings")
        .doc()
        .set({
      'recordingId': docId,
      'songName': currentSong.name,
      'songArtist': currentSong.artist,
      'songId': currentSong.getId(),
      'sessionId': currentSong.currentSession.id,
    });
  }

  addJamToUser(Jam jam, User user) async {
    List<String> instruments = [];
    for (JamInstruments jamInstruments in jam.instruments) {
      instruments
          .add(jamInstruments.displayName + ": " + jamInstruments.instrument);
    }
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("jams")
        .doc()
        .set({
      'recordings': jam.recordings,
      'songName': jam.songName,
      'songArtist': jam.artistName,
      'songId': jam.songId,
      'sessionId': jam.sessionId,
      'instruments': instruments,
      "title": jam.title
    });
  }

  incrementUploads(User user) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({"uploads": FieldValue.increment(1)});
  }
}

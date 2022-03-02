import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  incrementUploads(User user) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({"uploads": FieldValue.increment(1)});
  }
}

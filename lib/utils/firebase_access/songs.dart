import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSongs {
  incrementRecordingByOne(String currentSongId, String currentSessionId,
      String currentRecordingId) {
    FirebaseFirestore.instance
        .collection("songs")
        .doc(currentSongId)
        .collection("sessions")
        .doc(currentSessionId)
        .collection("recordings")
        .doc(currentRecordingId)
        .update({"jamsIn": FieldValue.increment(1)});
  }

  void removeVideoFromSpecificSong(String currentSongId,
      String currentSessionId, String currentRecordingId) {
    FirebaseFirestore.instance
        .collection("songs")
        .doc(currentSongId)
        .collection("sessions")
        .doc(currentSessionId)
        .collection("recordings")
        .doc(currentRecordingId)
        .delete();
  }

  void removeFromMainScreen(String url) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("urls")
        .where('url', isEqualTo: url)
        .get();
    for (DocumentSnapshot doc in querySnapshot.docs) {
      FirebaseFirestore.instance.collection("urls").doc(doc.id).delete();
    }
  }
}

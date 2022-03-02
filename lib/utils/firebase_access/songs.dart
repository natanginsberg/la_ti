import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:la_ti/model/song.dart';

class FirebaseSongs {
  Future<DocumentReference<Object?>> addRecordingToSong(
      Song currentSong, Map<String, dynamic> recordingData) async {
    return await FirebaseFirestore.instance
        .collection('songs')
        .doc(currentSong.getId())
        .collection("sessions")
        .doc(currentSong.currentSession.id)
        .collection("recordings")
        .add(recordingData);
  }

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

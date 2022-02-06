import 'recording.dart';

class Session {
  List<Recording> recordings = [];
  String id;
  String tempo;
  String genre;
  String subGenre = "";

  Session(this.id, this.tempo, this.genre);

  addRecording(Recording recording) {
    recordings.add(recording);
  }

  @override
  bool operator ==(dynamic other) =>
      other != null &&
      other is Session &&
      this.tempo == other.tempo &&
      this.genre == other.genre;

  @override
  int get hashCode => super.hashCode;
}

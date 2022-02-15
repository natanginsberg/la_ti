import 'recording.dart';

class Session {
  List<Recording> recordings = [];
  String id;
  String tempo = "";
  String genre;
  String subGenre;

  Session(this.id, this.subGenre, this.genre);

  addRecording(Recording recording) {
    recordings.add(recording);
  }

  @override
  bool operator ==(dynamic other) =>
      other != null &&
      other is Session &&
      this.subGenre == other.subGenre &&
      this.genre == other.genre;

  @override
  int get hashCode => super.hashCode;
}

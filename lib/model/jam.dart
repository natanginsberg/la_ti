import 'jam_instruments.dart';

class Jam {
  String jamId = "";
  String songName;
  String artistName;
  String songId;
  String sessionId;
  List<String> recordings;
  String title = "";
  List<String> instruments;

  Jam(
      {required this.songName,
      required this.recordings,
      required this.sessionId,
      required this.songId,
      required this.artistName,
      required this.instruments});
}

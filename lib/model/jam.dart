import 'jam_instruments.dart';

class Jam {
  String songName;
  String artistName;
  String songId;
  String sessionId;
  List<String> recordings;
  List<JamInstruments> instruments;
  String title = "";

  Jam(
      {required this.songName,
      required this.recordings,
      required this.sessionId,
      required this.songId,
      required this.artistName,
      required this.instruments});
}

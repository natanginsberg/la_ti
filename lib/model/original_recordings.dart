import 'package:la_ti/model/recording.dart';

class OriginalRecordings extends Recording {
  String songId = "";
  String sessionId = "";

  OriginalRecordings(String url, int delay, String recordingId, bool audioOnly)
      : super(url, delay, recordingId, audioOnly);
}

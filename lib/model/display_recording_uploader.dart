import 'package:la_ti/utils/main_screen/custom_url_audio_player.dart';

class DisplayRecordingUploader {
  // String dateUploaded;
  // int jamsIn;
  String songName;
  String artistName;
  // String url;
  // int delay;
  String songId;
  String sessionId;
  String recordingId;
  String userSongId;
  CustomUrlAudioPlayer customUrlAudioPlayer;

  DisplayRecordingUploader(
      this.songName,
      this.artistName,
      // this.dateUploaded,
      // this.jamsIn,
      // this.url,
      // this.delay,
      this.songId,
      this.sessionId,
      this.recordingId,
      this.userSongId,
      this.customUrlAudioPlayer);
}

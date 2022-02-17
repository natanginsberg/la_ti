class DisplayRecordingUploader {
  String dateUploaded;
  int jamsIn;
  String songName;
  String artistName;
  String url;
  int delay;
  String songId;
  String sessionId;
  String recordingId;
  String userSongId;

  DisplayRecordingUploader(this.songName, this.artistName, this.dateUploaded,
      this.jamsIn, this.url, this.delay, this.songId, this.sessionId, this.recordingId, this.userSongId);
}

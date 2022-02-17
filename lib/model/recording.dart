class Recording {
  String url;
  String nameOfRecorder = "";
  int delay;
  String recordingId;
  int jamsIn;
  String uploadDate;
  String uploaderDisplayName;
  String uploaderId;
  bool userIsFollowing = false;

  Recording(this.url, this.delay, this.recordingId, [this.uploadDate = "2021-22-12", this.uploaderDisplayName = "John John", this.jamsIn = 0, this.uploaderId=""]);
}

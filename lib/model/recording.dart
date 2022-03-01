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
  String instrument = "undefined";

  bool withVideo = true;

  bool local = false;

  Recording(this.url, this.delay, this.recordingId,
      [this.withVideo = true,
      this.uploadDate = "2021-22-12",
      this.uploaderDisplayName = "John John",
      this.jamsIn = 0,
      this.uploaderId = ""]);
}

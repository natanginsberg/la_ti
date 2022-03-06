class VideoStatus {
  bool isPlaying = false;

  bool isVideoVisible = false;

  bool songStarted = false;

  bool songEnded = false;

  bool watching = false;

  bool uploadStarted = false;

  bool recordVideo = false;

  bool recordAudio = false;

  playPressed() {
    isPlaying = true;
    songEnded = false;
    watching = false;
    uploadStarted = false;
  }

  bool onlyAudio() {
    return recordAudio && !recordVideo;
  }

  bool isRecording() {
    return recordVideo || recordAudio;
  }

  bool recordingAndNotWatching() {
    return (recordVideo || recordAudio) && !watching;
  }

  void sessionEnded() {
    watching = false;
    isPlaying = false;
    songStarted = false;
    if (recordVideo || recordAudio) {
      songEnded = true;
    }
  }

  bool songNotEnded() {
    return !songEnded || watching || !(recordVideo || recordAudio);
  }

  bool isWatchingOrPlaying() {
    return watching || isPlaying;
  }

  void videoChange() {
    if (!isVideoVisible) {
      isVideoVisible = true;
    }
    recordVideo = !recordVideo;
    recordAudio = !recordAudio;
    if (recordVideo) {
      recordAudio = true;
    }
  }

  void micChange() {
    if (isVideoVisible) {
      recordVideo = !recordVideo;
      recordAudio = !recordAudio;
      if (recordVideo) {
        recordAudio = true;
      }
    }
  }

  void resetScreen() {
    songEnded = false;
    watching = false;
  }

  recordingInProgress() {
    return songStarted && (recordVideo || recordAudio);
  }
}

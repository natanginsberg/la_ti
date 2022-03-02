class VideoStatus{
  bool isPlaying = false;

  bool isVideoVisible = false;

  bool songStarted = false;

  bool songEnded = false;

  bool watching = false;

  bool uploadStarted = false;

  bool recordVideo = false;

  bool recordAudio = false;

  playPressed(){
    isPlaying = true;
    songEnded = false;
    watching = false;
    uploadStarted = false;
  }


}
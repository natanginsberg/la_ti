import 'package:flutter/cupertino.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';

class RecordingsToPlay {
  List<CustomUrlAudioPlayer> players = [];
  static int counter = 0;
  late VoidCallback songEnded;
  String recordingPath = "";

  late CustomUrlAudioPlayer previousRecordingPlayer;

  int startTime = 0;

  int delay = 0;

  RecordingsToPlay();

  addEndFunction(VoidCallback endSession) {
    songEnded = endSession;
  }

  startVideos() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.play();
    }
  }

  stopVideos() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.stop();
    }
  }

  pauseVideo() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.pause();
    }
    if (players.isNotEmpty) {
      Duration? currentTime = await players[0].getCurrentPosition();
      for (CustomUrlAudioPlayer player in players) {
        if (currentTime != null) await player.seek(currentTime);
      }
    }
  }

  void resetRecordings() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.seek(const Duration(seconds: 0));
    }
  }

  getCurrentPosition() async {
    // int position = await playingUrls[0].getCurrentPosition();
    // print("this is the current position " + position.toString());
    // return Duration(milliseconds: position);
    if (players.isNotEmpty) {
      Duration d = (await players[0].getCurrentPosition())!;
      return Future(() => d);
    }
    return Future(() => const Duration(seconds: 0));
  }

  isEmpty() {
    return players.isEmpty;
  }

  Future<Duration> getSongLength() async {
    return await players[0].getDuration();
  }

  clearPlayers() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.removeAudioPlayer();
    }
    players.clear();
  }

  addPlayer(String path) async {
    counter++;
    CustomUrlAudioPlayer customPlayer = CustomUrlAudioPlayer(path, () {
      songEnded();
    });
    players.add(customPlayer);
    // customUrlAudioPlayer.initialize();
  }

  addCustomPlayer(CustomUrlAudioPlayer player2){
    player2.resetVideo();
    players.add(player2);
  }

  getPlayerController(int index) {
    return players[index].getController();
  }

  removePlayer(int index) {
    players[index].removeAudioPlayer();
    players.removeAt(index);
  }

  void playVideos() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.play();
      if (delay == 0){
        setDelay(DateTime.now().millisecondsSinceEpoch);
      }
    }
  }

  String getPlayerUrl(int index) {
    return players[index].path;
  }

  Widget getPlayWidget(int index) {
    return players[index].playWidget();
  }

  void setRecordingPath(String path) {
    recordingPath = path;
  }

  void addRecordingMadeToRecordings() {
    previousRecordingPlayer = CustomUrlAudioPlayer(recordingPath, () {
      songEnded();
    });
  }

  Future<void> playRecording() async {
    await previousRecordingPlayer.play();
    startVideos();
  }

  void setStartTime(int millisecondsSinceEpoch) {
    startTime = millisecondsSinceEpoch;
  }

  void setDelay(int currentTime) {
    delay = currentTime - startTime;
  }
}

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';

class RecordingsToPlay {
  List<CustomUrlAudioPlayer> players = [];
  static int counter = 0;
  late VoidCallback songEnded;
  String recordingPath = "";
  List<int> startTimes = [];
  Timer? timer;

  late CustomUrlAudioPlayer previousRecordingPlayer;

  int startTime = 0;

  int delay = 0;

  bool delaySet = false;

  bool firstPlayerRemoved = false;

  Duration currentTime = const Duration(seconds: 0);

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

  Future<Duration> getCurrentPosition() async {
    if (players.isNotEmpty) {
      Duration d = (await players[0].getCurrentPosition())!;
      if (!d.isNegative) {
        return Future(() => d);
      }
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
    // customPlayer.initialize();
  }

  addCustomPlayer(CustomUrlAudioPlayer player2) async {
    await player2.resetVideo();
    players.add(player2);
    Future.delayed(const Duration(milliseconds: 1500));
    Duration currentPosition = await getCurrentPosition();
    print(currentPosition.inMilliseconds);
    print(players.length);
    if (currentPosition.inSeconds > 0) {
      await playVideos(false);
      await stopVideos();
      await setAllPlayersToAppropriateSecond(currentPosition);
      await Future.delayed(const Duration(milliseconds: 750));
      print((await players[players.length - 1].getCurrentPosition())
          ?.inMilliseconds);
      playVideos(false);
    }
  }

  getPlayerController(int index) {
    return players[index].getController();
  }

  removePlayer(int index, [bool playing = false]) async {
    if (index == 0 && playing) {
      currentTime = await getCurrentPosition();
    }
    players.removeAt(index);
    if (index == 0) {
      firstPlayerRemoved = true;
    }
    print("this sis the recording to play " + players.length.toString());
  }

  restartOtherPlayers() {
    if (firstPlayerRemoved) {
      setAllPlayersToAppropriateSecond(currentTime);
      playVideos(false);
      firstPlayerRemoved = false;
    }
  }

  playVideos(bool record) async {
    for (CustomUrlAudioPlayer player in players) {
      await player.play();
      startTimes.add(DateTime.now().millisecondsSinceEpoch);
      if (record && !delaySet) {
        timer =
            Timer.periodic(const Duration(milliseconds: 10), (Timer t) async {
          if (!players[0].videoElement.paused) {
            setDelay(DateTime.now().millisecondsSinceEpoch);
          }
        });
      }
    }
    if (players.isEmpty) {
      if (record && !delaySet) {
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

  void setRecording(CustomUrlAudioPlayer recording) {
    previousRecordingPlayer = recording;
  }

  void addRecordingMadeToRecordings() {
    previousRecordingPlayer = CustomUrlAudioPlayer(recordingPath, () {
      songEnded();
    }, delay);
  }

  Future<void> playRecording() async {
    await previousRecordingPlayer.play();
    startVideos();
  }

  void setStartTime(int millisecondsSinceEpoch) {
    startTime = millisecondsSinceEpoch;
  }

  void setDelay(int currentTime) {
    if (!delaySet) {
      delay = currentTime - startTime;
      delaySet = true;
      print(delay);
    }
  }

  setAllPlayersToAppropriateSecond(Duration position) {
    for (CustomUrlAudioPlayer player in players) {
      player.seek(position);
    }
  }

  void stopPlayer(int index) {
    players[index].stop();
  }
}

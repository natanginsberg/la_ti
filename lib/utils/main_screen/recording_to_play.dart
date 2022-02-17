import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';
import 'package:la_ti/model/recording.dart';

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

  double currentTime = 0;

  RecordingsToPlay();

  String instrumentPlayed = "";

  addEndFunction(VoidCallback endSession) {
    songEnded = endSession;
  }

  startVideos() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.play();
    }
  }

  stopVideos() async {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    for (CustomUrlAudioPlayer player in players) {
      await player.stop();
    }
  }

  pauseVideo() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.pause();
    }
    if (players.isNotEmpty) {
      double currentTime = players[0].getCurrentPosition();
      for (CustomUrlAudioPlayer player in players) {
        if (currentTime != null) await player.seek(currentTime);
      }
    }
  }

  void resetRecordings() async {
    for (CustomUrlAudioPlayer player in players) {
      await player.seek(0);
    }
  }

  double getCurrentPosition() {
    if (players.isNotEmpty) {
      double d = players[0].getCurrentPosition();
      if (!d.isNegative) {
        return d;
      }
    }
    return 0.0;
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

  // addPlayer(String path) async {
  //   counter++;
  //   CustomUrlAudioPlayer customPlayer = CustomUrlAudioPlayer(Recording(path, )path, () {
  //     songEnded();
  //   });
  //   players.add(customPlayer);
  //   // customPlayer.initialize();
  // }

  addCustomPlayer(CustomUrlAudioPlayer player2) async {
    await player2.resetVideo();
    double currentPosition = getCurrentPosition();
    player2.playing = true;
    player2.metadataEntered = false;
    players.add(player2);
    if (currentPosition > 0) {
      await stopVideos();
      timer = Timer.periodic(const Duration(milliseconds: 10), (Timer t) async {
        if (player2.metadataEntered) {
          timer!.cancel();
          await setAllPlayersToAppropriateSecond(currentPosition);
          playVideos(false);
        }
      });
    }
  }

  getPlayerController(int index) {
    return players[index].getController();
  }

  removePlayer(int index, [bool playing = false]) async {
    if (timer != null) {
      timer!.cancel();
    }
    double currentPosition = 0;
    if (index < players.length - 1 && playing) {
      currentPosition = getCurrentPosition();
    }
    players[index].playing = false;
    players.removeAt(index);
    for (CustomUrlAudioPlayer player in players.sublist(index)) {
      player.metadataEntered = false;
    }
    await stopVideos();
    if (index == 0) {
      firstPlayerRemoved = true;
    }
    timer = Timer.periodic(const Duration(milliseconds: 10), (Timer t) async {
      if (players.where((element) => !element.metadataEntered).isEmpty) {
        timer!.cancel();
        await setAllPlayersToAppropriateSecond(currentPosition);
        playVideos(false);
      }
    });
  }

  playVideos(bool record) async {
    for (CustomUrlAudioPlayer player in players) {
      print(player.videoElement.currentTime);
      await player.play();
      startTimes.add(DateTime.now().millisecondsSinceEpoch);
      if (record && !delaySet) {
        timer =
            Timer.periodic(const Duration(milliseconds: 10), (Timer t) async {
          if (!players[0].videoElement.paused) {
            timer!.cancel();
            setDelay(DateTime.now().millisecondsSinceEpoch);
          } else if (players.isEmpty) {
            timer!.cancel();
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
    previousRecordingPlayer =
        CustomUrlAudioPlayer(Recording(recordingPath, 0, ""), () {
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
    }
  }

  setAllPlayersToAppropriateSecond(double position) {
    for (CustomUrlAudioPlayer player in players) {
      player.seek(position);
    }
  }

  void stopPlayer(int index) {
    players[index].stop();
  }

  void changeSubscription(String uploaderId) {
    for (CustomUrlAudioPlayer customUrlAudioPlayer in players) {
      if (customUrlAudioPlayer.recording.uploaderId == uploaderId) {
        customUrlAudioPlayer.recording.userIsFollowing =
            !customUrlAudioPlayer.recording.userIsFollowing;
      }
    }
  }
}

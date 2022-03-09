import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:la_ti/model/jam_instruments.dart';
import 'package:la_ti/model/recording.dart';

import 'custom_url_audio_player.dart';

class RecordingsToPlay {
  List<CustomUrlAudioPlayer?> players = [null, null, null, null, null];
  static int counter = 0;
  late VoidCallback songEnded;
  String recordingPath = "";
  List<int> startTimes = [];
  Timer? timer;
  Timer? latencyTimer;

  late CustomUrlAudioPlayer previousRecordingPlayer;

  int startTime = 0;

  int delay = 0;

  bool delaySet = false;

  bool firstPlayerRemoved = false;

  double currentTime = 0;

  bool audioRecording = false;

  bool songStarted = false;

  double largestDifference = 0;

  bool jamAdded = false;

  RecordingsToPlay();

  String instrumentPlayed = "";

  addEndFunction(VoidCallback endSession) {
    songEnded = endSession;
  }

  startVideos() async {
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        await player.play();
      }
    }
  }

  stopVideos() async {
    songStarted = false;
    largestDifference = getDifference();
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        await player.stop();
      }
    }
  }

  pauseVideo() async {
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        await player.pause();
      }
    }
    if (players.isNotEmpty) {
      double currentTime = await getCurrentPosition();
      for (CustomUrlAudioPlayer? player in players) {
        if (player != null) {
          await player.seek(currentTime);
        }
      }
    }
  }

  void resetRecordings() async {
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        await player.seek(0);
      }
    }
  }

  Future<double> getCurrentPosition() async {
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        double d = await player.getCurrentPosition();
        if (!d.isNegative) {
          return d;
        }
      }
    }
    return 0.0;
    return 0.0;
  }

  isEmpty() {
    return players.isEmpty;
  }

  Future<Duration> getSongLength() async {
    Duration maxDuration = const Duration(milliseconds: 0);
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        try {
          Duration duration = await player.getDuration();
          if (duration > maxDuration) {
            maxDuration = duration;
          }
        } catch (exception) {}
      }
    }
    if (maxDuration.inSeconds == 0) {
      return Future(() => const Duration(milliseconds: 240));
    } else {
      return maxDuration;
    }
  }

  addCustomPlayer(CustomUrlAudioPlayer player2) async {
    jamAdded = false;
    if (kDebugMode) {
      print(player2.recording.url);
    }
    if (songStarted) {
      return false;
    }
    await player2.resetVideo();
    double currentPosition = await getCurrentPosition();
    player2.playing = true;
    player2.set = false;
    player2.metadataEntered = false;
    player2.songEnded = songEnded;
    for (int i = 0; i < 5; i++) {
      if (players[i] == null) {
        players[i] = player2;
        break;
      } else if (i == 4) {
        return false;
      }
    }
    // the song is playing because of the delay we need to check 2 seconds
    if (currentPosition > 2) {
      await stopVideos();
      timer = Timer.periodic(const Duration(milliseconds: 10), (Timer t) async {
        if (player2.metadataEntered && player2.set) {
          timer!.cancel();
          await setAllPlayersToAppropriateSecond(currentPosition);
          playVideos(false);
        }
      });
    }
    return true;
  }

  removePlayer(int index, [bool playing = false]) async {
    jamAdded = false;
    players[index] = null;
  }

  bool isPlayersEmpty() {
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        return false;
      }
    }
    return true;
  }

  playVideos(bool record) async {
    songStarted = true;
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        await player.play();
        if (record && !delaySet) {
          timer =
              Timer.periodic(const Duration(milliseconds: 10), (Timer t) async {
            if (!player.isPaused()) {
              timer!.cancel();
              setDelay(DateTime.now().millisecondsSinceEpoch);
            } else if (isPlayersEmpty()) {
              timer!.cancel();
            }
          });
        }
      }
    }
    latencyTimer =
        Timer.periodic(const Duration(milliseconds: 50), (Timer t) async {
      double largestDifference = getDifference();
      print(largestDifference);
      latencyTimer!.cancel();
    });
    if (isPlayersEmpty()) {
      if (record && !delaySet) {
        setDelay(DateTime.now().millisecondsSinceEpoch);
      }
    }
  }

  Widget getPlayWidget(int index) {
    if (players[index] != null) {
      return players[index]!.playWidget();
    }
    return Container();
  }

  void setRecording(CustomUrlAudioPlayer recording) {
    previousRecordingPlayer = recording;
  }

  void addRecordingMadeToRecordings() {
    previousRecordingPlayer =
        CustomUrlAudioPlayer(Recording(recordingPath, delay, ""), () {
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
      if (audioRecording) {
        delay += 10;
      }
      delaySet = true;
    }
  }

  setAllPlayersToAppropriateSecond(double position) {
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        player.seek(position);
      }
    }
  }

  void stopPlayer(int index) {
    songStarted = false;
    if (players[index] != null) {
      players[index]!.stop();
    }
  }

  void changeSubscription(String uploaderId) {
    for (CustomUrlAudioPlayer? customUrlAudioPlayer in players) {
      if (customUrlAudioPlayer != null) {
        if (customUrlAudioPlayer.recording.uploaderId == uploaderId) {
          customUrlAudioPlayer.recording.userIsFollowing =
              !customUrlAudioPlayer.recording.userIsFollowing;
        }
      }
    }
  }

  isUserFollowing(int index) {
    if (players[index] != null) {
      return players[index]!.recording.userIsFollowing;
    }
    return false;
  }

  warmUp([bool watchRecording = false]) async {
    if (watchRecording) {
      await previousRecordingPlayer.play();
    }
    for (CustomUrlAudioPlayer? player in players) {
      if (player != null) {
        await player.play();
      }
    }
    latencyTimer =
        Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
      double largestDifference = getDifference();
      if (kDebugMode) {
        print(largestDifference);
      }
      latencyTimer!.cancel();
    });
    if (watchRecording) {
      previousRecordingPlayer.stop();
    }
    stopVideos();
    resetRecordings();
    if (watchRecording) {
      await previousRecordingPlayer.resetVideo();
    }
  }

  double getDifference() {
    double? maxVal = 0;
    double? min = 1000;
    for (int i = 0; i < 5; i++) {
      if (players[i] != null) {
        {
          num currentTime = players[i]!.videoElement.currentTime -
              players[i]!.recording.delay / 1000;
          if (currentTime > maxVal!) {
            maxVal = currentTime as double?;
          }
          if (currentTime < min!) {
            min = currentTime as double?;
          }
        }
      }
    }
    if (maxVal != null && min != null) {
      return maxVal - min;
    } else {
      return 1;
    }
  }

  void removeAllPayers() {
    for (var i = 0; i < 5; i++) {
      players[i] = null;
    }
  }

  bool notEnoughRecordingsToSaveJam() {
    int counter = 0;
    for (var i = 0; i < 5; i++) {
      if (players[i] != null) counter++;
    }
    return counter < 2;
  }

  List<String> getRecordingIds() {
    List<String> ids = [];
    for (var i = 0; i < 5; i++) {
      if (players[i] != null) ids.add(players[i]!.recording.recordingId);
    }
    return ids;
  }

  List<JamInstruments> getJamInstruments() {
    List<JamInstruments> jamInstruments = [];
    for (var i = 0; i < 5; i++) {
      if (players[i] != null) {
        jamInstruments.add(JamInstruments(
            instrument: players[i]!.recording.instrument,
            displayName: players[i]!.recording.uploaderDisplayName));
      }
    }
    return jamInstruments;
  }
}

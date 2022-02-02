import 'package:la_ti/model/custom_url_audio_player.dart';

class RecordingsToPlay {
  List<CustomUrlAudioPlayer> players = [];

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

  addPlayer(CustomUrlAudioPlayer customUrlAudioPlayer) async {
    players.add(customUrlAudioPlayer);
    customUrlAudioPlayer.initialize();
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
    }
  }
}

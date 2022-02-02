import 'package:flutter/material.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';

class PlayingArea extends StatefulWidget {
  List<CustomUrlAudioPlayer> songsPlaying;

  PlayingArea(this.songsPlaying, {Key? key}) : super(key: key);

  @override
  _PlayingAreaState createState() => _PlayingAreaState();
}

class _PlayingAreaState extends State<PlayingArea> {

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

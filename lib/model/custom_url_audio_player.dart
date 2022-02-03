import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_js/video_js.dart';
import 'package:video_player/video_player.dart';

class CustomUrlAudioPlayer {
  AudioPlayer audioPlayer = AudioPlayer();
  late String path;
  late VideoPlayerController _controller;
  bool playPressed = false;
  late Widget blobPlayer;
  final videoElement = html.VideoElement();

  // final VoidCallback songEnded;

  CustomUrlAudioPlayer(String url, VoidCallback songEnded) {
    path = url;
    _controller = VideoPlayerController.network(url);
    blobPlayer = blobUrlPlayer(
      key: UniqueKey(),
      source: url,
      videoElement: videoElement,
    );
    _controller.addListener(() {
      checkVideo(songEnded);
    });
    videoElement.addEventListener('ended', (event) => songEnded());
  }

  void checkVideo(VoidCallback songEnded) {
    // Implement your calls inside these conditions' bodies :
    if (_controller.value.position ==
        Duration(seconds: 1, minutes: 0, hours: 0)) {}

    if (_controller.value.position >=
        _controller.value.duration - Duration(seconds: 1)) {
      songEnded;
    }
  }

  initialize() async {
    await _controller.initialize();
  }

  play() async {
    videoElement.play();
  }

  stop() async {
    videoElement.pause();
  }

  pause() async {
    videoElement.pause();
  }

  removeAudioPlayer() async {
    // await audioPlayer.release();
    // await audioPlayer.dispose();
    if (_controller.value.isPlaying) await _controller.pause();
    await _controller.dispose();
  }

  seek(Duration time) async {
    videoElement.currentTime = time.inSeconds;
  }

  Future<Duration?> getCurrentPosition() async {
    return Future(() => Duration(seconds: videoElement.currentTime.toInt()));
  }

  VideoPlayerController getController() {
    return _controller;
  }

  getDuration() async {
    // return _controller.value.duration;
    return Future(() => Duration(seconds: videoElement.duration.toInt()));
  }

  void resetVideo() async {
    // await _controller.pause();
    // await _controller.seekTo(const Duration(seconds: 0));
    videoElement.pause();
    videoElement.currentTime = 0;
  }

  Widget playWidget() {
    return blobPlayer;
  }
}

class blobUrlPlayer extends StatefulWidget {
  final String source;
  final videoElement;

  const blobUrlPlayer(
      {required Key key, required this.source, required this.videoElement})
      : super(key: key);

  @override
  _blobUrlPlayerState createState() => _blobUrlPlayerState();
}

// ignore: camel_case_types
class _blobUrlPlayerState extends State<blobUrlPlayer> {
  // Widget _iframeWidget;

  @override
  void initState() {
    super.initState();
    videoHandler();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: UniqueKey(),
      viewType: widget.source,
    );
  }

  void videoHandler() {
    if (widget.videoElement.srcObject == null) {
      widget.videoElement
        ..src = widget.source
        ..autoplay = false
        ..controls = false
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%';

      // Allows Safari iOS to play the video inline
      widget.videoElement.setAttribute('playsinline', 'true');

      // Set autoplay to false since most browsers won't autoplay a video unless it is muted
      widget.videoElement.setAttribute('autoplay', 'false');

      //ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
          widget.source, (int viewId) => widget.videoElement);
      widget.videoElement.pause();
    }
    // if (widget.state == States.play) {
    //   videoElement.play();
    // }
    // else if (widget.state == States.pause) {
    //   videoElement.pause();
    // }
  }
}

import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

class CustomUrlAudioPlayer {
  AudioPlayer audioPlayer = AudioPlayer();
  late String path;

  // late VideoPlayerController _controller;
  bool playPressed = false;
  late Widget blobPlayer;
  final videoElement = html.VideoElement();

  int delay = 0;

  bool paused = true;

  bool playing = false;

  // final VoidCallback songEnded;

  CustomUrlAudioPlayer(String url, VoidCallback songEnded, [int delay = 0]) {
    path = url;
    this.delay = delay;
    // _controller = VideoPlayerController.network(url);
    blobPlayer = blobUrlPlayer(
      key: UniqueKey(),
      source: url,
      videoElement: videoElement,
    );
    // _controller.addListener(() {
    //   checkVideo(songEnded);
    // });
    videoElement.addEventListener('ended', (event) => songEnded());
    videoElement.addEventListener('playing', (event) => {playing = true});
    videoElement.addEventListener('pause', (event) => {playing = false});
    videoElement.addEventListener('loadedmetadata', (event) {
      // print("meta data loaded")
      // if (videoElement.duration.toString() == 'Infinity')
      //   {
      //     videoElement.currentTime = 1e10;
      videoElement.currentTime = delay / 1000;
      // print("this is the current time " +
      //     videoElement.currentTime.toString() +
      //     " and this the delay " +
      //     delay.toString());
      // console.log('The duration and dimensions ' + '
      // of the media and tracks are now known. ');
      // }
    });

    // addDelayToStartTime();
  }

  // void checkVideo(VoidCallback songEnded) {
  //   // Implement your calls inside these conditions' bodies :
  //   if (_controller.value.position ==
  //       Duration(seconds: 1, minutes: 0, hours: 0)) {}
  //
  //   if (_controller.value.position >=
  //       _controller.value.duration - Duration(seconds: 1)) {
  //     songEnded;
  //   }
  // }

  initialize() async {
    // await _controller.initialize();
  }

  play() async {
    if (!playing) {
      videoElement.play();
    }
  }

  stop() async {
    videoElement.pause();
  }

  pause() async {
    if (playing) {
      videoElement.pause();
    }
  }

  removeAudioPlayer() async {
    // await audioPlayer.release();
    // await audioPlayer.dispose();
    // if (_controller.value.isPlaying) await _controller.pause();
    // await _controller.dispose();
  }

  seek(Duration time) async {
    videoElement.currentTime = delay / 1000 + time.inMilliseconds / 1000;
  }

  Future<Duration?> getCurrentPosition() async {
    return Future(() =>
        Duration(seconds: videoElement.currentTime.toInt()) -
        Duration(milliseconds: delay));
  }

  Widget getController() {
    return playWidget();
    // return _controller;
  }

  getDuration() async {
    // return _controller.value.duration;
    return Future(() =>
        Duration(seconds: videoElement.duration.toInt()) -
        Duration(milliseconds: delay));
  }

  Future<void> resetVideo() async {
    // await _controller.pause();
    // await _controller.seekTo(const Duration(seconds: 0));
    videoElement.pause();
    videoElement.currentTime = delay / 1000;
  }

  Widget playWidget() {
    return blobPlayer;
  }

  void addDelayToStartTime() async {
    // await play();
    videoElement.currentTime = delay / 1000;
    // await Future.delayed(Duration(milliseconds: 1000));
    // videoElement.pause();
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

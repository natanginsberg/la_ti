import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:la_ti/model/recording.dart';

class CustomUrlAudioPlayer {
  late String path;

  bool playPressed = false;
  late Widget blobPlayer;

  // if recording.withVideo is true we will show a video element
  html.VideoElement videoElement = html.VideoElement();

  // else we will have the flutter sound package play the stream
  late FlutterSoundPlayer soundPlayer;

  AudioPlayer player = AudioPlayer();

  int delay = 0;

  bool paused = true;

  bool playing = false;

  late Recording recording;

  bool withVideo = false;

  String lastTime = "";

  bool firstTime = false;

  bool metadataEntered = false;

  late VoidCallback songEnded;

  bool set = false;

  // final VoidCallback songEnded;

  CustomUrlAudioPlayer(Recording recording, VoidCallback songEnded,
      [int delay = 0, bool videoRecorded = true]) {
    path = recording.url;
    this.delay = delay;
    this.recording = recording;
    this.songEnded = songEnded;

    // withVideo = recording.withVideo;
    withVideo = true;
    if (withVideo) {
      blobPlayer = blobUrlPlayer(
        key: UniqueKey(),
        source: recording.url,
        videoElement: videoElement,
      );
      setVideoListeners();
    } else {
      soundPlayer = FlutterSoundPlayer();
      setPlayer();
      //
      // setUrl();
      blobPlayer = Container(
        color: Colors.blueAccent,
        child: const Center(
          child: Icon(
            Icons.music_note,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  setVideoListeners() {
    videoElement.addEventListener('stalled', (event) {
      if (set) songEnded();
    });
    videoElement.addEventListener('ended', (event) => songEnded());
    videoElement.addEventListener('playing', (event) {
      if (firstTime) {
        firstTime = false;
        videoElement.pause();
        videoElement.volume = 1;
        set = true;
      }
    });
    videoElement.addEventListener('pause', (event) => {playing = false});
    videoElement.addEventListener('loadedmetadata', (event) async {
      if (playing) {
        videoElement.volume = 0;
        await videoElement.play();
        firstTime = true;
      }

      videoElement.currentTime = delay / 1000;
      metadataEntered = true;
    });
  }

  setUrl() async {
    await player.setUrl(recording.url);
    await player.seek(Duration(milliseconds: recording.delay));
  }

  setPlayer() async {
    await soundPlayer.openPlayer();
  }

  play() async {
    if (withVideo) {
      videoElement.play();
    } else {
      await soundPlayer.startPlayer(fromURI: recording.url);
      await soundPlayer.seekToPlayer(Duration(milliseconds: delay));
      // await player.play();
    }
  }

  stop() async {
    lastTime = videoElement.currentTime.toString();
    if (withVideo) {
      videoElement.pause();
    } else {
      soundPlayer.stopPlayer();
      // await player.stop();
    }
  }

  pause() async {
    if (withVideo) {
      if (playing) {
        videoElement.pause();
      }
    } else {
      soundPlayer.stopPlayer();
      // await player.stop();
    }
  }

  seek(double time) async {
    if (withVideo) {
      videoElement.currentTime = delay / 1000 + time;
    } else {
      await soundPlayer
          .seekToPlayer(Duration(milliseconds: (delay + time * 1000).toInt()));
      // await player.seek(Duration(milliseconds: (delay + time * 1000).toInt()));
    }
  }

  Future<double> getCurrentPosition() async {
    if (withVideo) {
      return videoElement.currentTime - delay / 1000;
    } else {
      print("This is the current time " +
          (await soundPlayer.getProgress()).toString());
      int? currentPosition =
          (await soundPlayer.getProgress())['progress']?.inMilliseconds;
      return (currentPosition! - delay) / 1000;
      // return player.position.inMilliseconds / 1000 - delay / 1000;
    }
  }

  Widget getController() {
    return playWidget();
    // return _controller;
  }

  Future<Duration> getDuration() async {
    // return _controller.value.duration;
    if (withVideo) {
      return Future(() =>
          Duration(seconds: videoElement.duration.toInt()) -
          Duration(milliseconds: delay));
    } else {
      Duration? totalDuration = (await soundPlayer.getProgress())['duration'];
      return totalDuration!;
      // return player.duration;
    }
  }

  Future<void> resetVideo() async {
    if (withVideo) {
      videoElement.pause();
      videoElement.currentTime = delay / 1000;
    } else {
      if (soundPlayer.isPlaying) {
        await soundPlayer.stopPlayer();
        await soundPlayer.seekToPlayer(Duration(milliseconds: delay));
      } // await player.stop();
      // await player.seek(Duration(milliseconds: delay));
    }
  }

  Widget playWidget() {
    return blobPlayer;
  }

  void addDelayToStartTime() async {
    if (withVideo) {
      videoElement.currentTime = delay / 1000;
    } else {
      await soundPlayer.seekToPlayer(Duration(milliseconds: delay));
      // await player.seek(Duration(milliseconds: delay));
    }
  }

  bool isPaused() {
    if (withVideo) {
      return videoElement.paused;
    } else {
      return soundPlayer.isPaused;
      // return !player.playing;
    }
  }
}

class blobUrlPlayer extends StatefulWidget {
  final String source;
  final html.VideoElement videoElement;

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
    return Stack(
      children: [
        const Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator()),
        HtmlElementView(
          key: UniqueKey(),
          viewType: widget.source,
        ),
        if (widget.source.contains("AUDIO_ONLY"))
          Container(
            color: Colors.blueAccent,
            child: const Center(
                child: Icon(
              Icons.music_note,
              color: Colors.white,
              size: 35,
            )),
          )
      ],
    );
  }

  void videoHandler() async {
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
  }
}

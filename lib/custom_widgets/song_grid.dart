import 'dart:async';
import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:la_ti/model/recording_to_play.dart';
import 'package:video_js/video_js.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class SongGrid extends StatefulWidget {
  CameraController? cameraController;
  RecordingsToPlay recordingsToPlay;

  bool recordVideo;

  Widget cameraWidget;

  VoidCallback stopRecording;

  //todo understand how to use the key
  SongGrid(
      {required this.stopRecording,
      this.cameraController,
      required this.recordingsToPlay,
      required this.recordVideo,
      required this.cameraWidget});

  @override
  State<SongGrid> createState() => _SongGridState();
}

class _SongGridState extends State<SongGrid> {
  final ScrollController _mainController = ScrollController();

  Duration songLength = const Duration(seconds: 0);
  Duration _progressValue = const Duration(seconds: 0);

  Timer startTimer = Timer(const Duration(hours: 30), () {});

  Timer timer = Timer(const Duration(hours: 30), () {});

  bool isPlaying = false;

  int countdown = 3;

  bool songStarted = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        countdown != 0 && isPlaying
            ? TextButton(
                onPressed: () {},
                child: Text(
                  countdown.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              )
            : IconButton(
                onPressed: () => isPlaying ? endSession() : playAudio(),
                icon: isPlaying
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.play_arrow),
                color: Colors.white,
                iconSize: 45,
              ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ProgressBar(
              total: songLength,
              progressBarColor: Colors.blue,
              progress: _progressValue,
              thumbRadius: 1,
              timeLabelTextStyle: const TextStyle(color: Colors.white),
              barHeight: 8,
              timeLabelLocation: TimeLabelLocation.sides,
            ),
          ),
        ),
        Flexible(
          child: buildGridView(),
        )
      ],
    );
  }

  buildGridView() {
    return GridView.builder(
        controller: _mainController,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5),
        itemCount: widget.recordingsToPlay.players.length + 1,
        // playingUrls.length + 1,
        itemBuilder: (BuildContext ctx, index) {
          // print(index);
          return index == 0
              ? SizedBox(
                  width: 400,
                  child: Stack(children: [
                    widget.cameraWidget,
                    if (songStarted && widget.recordVideo)
                      const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.transparent,
                            )),
                      )
                  ]))
              : Container(
                  width: 400,
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: VideoJsWidget(
                            videoJsController: widget.recordingsToPlay
                                  .getPlayerController(index - 1),
                            height: MediaQuery.of(context).size.width / 2.5,
                            width: MediaQuery.of(context).size.width / 1.5,
                          )),
                          // VideoPlayer(widget.recordingsToPlay
                          //     .getPlayerController(index - 1))),
                      // playingUrls[index - 1].getController())),
                      SafeArea(
                          child: IconButton(
                        onPressed: () async {
                          // playingUrls[index - 1].removeAudioPlayer();
                          setState(() {
                            // playingUrls.removeAt(index - 1);
                            widget.recordingsToPlay.removePlayer(index - 1);
                          });
                        },
                        icon: const Icon(Icons.remove_circle),
                      ))
                    ],
                  ),
                );
        });
  }

  playAudio() async {
    setState(() {
      isPlaying = true;
    });
    countdown = 3;
    startTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });
      if (countdown == 1 && widget.recordVideo) {
        // if (songStarted) {
        //   controller!.resumeVideoRecording();
        // } else {
        widget.cameraController!.startVideoRecording();
        // }
      } else if (countdown == 0) {
        startTimer.cancel();
        startSession();
      }
    });
  }

  void startSession() async {
    setState(() {
      songStarted = true;
    });
    Wakelock.enable;
    // todo start videos
    widget.recordingsToPlay.playVideos();
    // for (CustomUrlAudioPlayer player in playingUrls) {
    //   await player.play();
    // }
    // if (watchingSession) {
    //   playbackController.play();
    // }
    // if (playingUrls.isNotEmpty) {
    //   songLength = await playingUrls[0].getDuration();
    if (widget.recordingsToPlay.isEmpty()) {
      timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
        setState(() {
          _progressValue = Duration(milliseconds: timer.tick * 100);
        });
      });
    } else {
      timer =
          Timer.periodic(const Duration(milliseconds: 100), (Timer t) async {
        _progressValue = await widget.recordingsToPlay.getCurrentPosition();
        // (await playingUrls[0].getCurrentPosition())!;
        setState(() {});
        songLength = await widget.recordingsToPlay.getSongLength();
        setState(() {});
      });
    }
  }

  void endSession() async {
    timer.cancel();
    setState(() {
      isPlaying = false;
      songStarted = false;
    });
    if (widget.recordVideo) widget.stopRecording();
    // stopVideos();
    // resetRecordings();
    widget.recordingsToPlay.stopVideos();
    widget.recordingsToPlay.resetRecordings();
    if (widget.recordVideo) {
      // calculateDelay();
      // playVideo(videoFile.name);
      // await openPlaybackDialog();
    }
  }
}

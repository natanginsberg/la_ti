import 'dart:async';
import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';
import 'package:la_ti/model/recording_to_play.dart';
import 'package:wakelock/wakelock.dart';

class SongGrid extends StatefulWidget {
  CameraController? cameraController;
  RecordingsToPlay recordingsToPlay;

  bool recordVideo;

  Widget cameraWidget;

  VoidCallback stopRecording;

  VoidCallback uploadRecording;

  Function(CustomUrlAudioPlayer) itemReoved;

  //todo understand how to use the key
  SongGrid(
      {required this.stopRecording,
      this.cameraController,
      required this.recordingsToPlay,
      required this.recordVideo,
      required this.cameraWidget,
      required this.uploadRecording,
      required this.itemReoved});

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

  bool songEnded = false;

  bool watching = false;

  bool uploadStarted = false;

  bool recordVideo = false;

  bool recordAudio = false;

  @override
  void initState() {
    super.initState();
    widget.recordingsToPlay.addEndFunction(endSession);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width * 2 / 3,
      child: Stack(
        children: [
          Positioned(
              top: 10,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width* 2 / 3,
                child: buildGridView(),
              )),
          Positioned(
            bottom: 50,
            height: 80,
            width: MediaQuery.of(context).size.width* 2 / 3,
            child: Column(children: [
              aboveProgressBar(),
              progressBar(),
            ]),
          )
        ],
      ),
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
                  child: watching
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: widget.recordingsToPlay.previousRecordingPlayer
                              .blobPlayer)
                      : Stack(children: [
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
                          // )),
                          child:
                              widget.recordingsToPlay.getPlayWidget(index - 1)),
                      SafeArea(
                          child: IconButton(
                        onPressed: () async {
                          setState(() {
                            widget.itemReoved(
                                widget.recordingsToPlay.players[index - 1]);
                            widget.recordingsToPlay.removePlayer(index - 1);
                          });
                        },
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.white,
                        ),
                      ))
                    ],
                  ),
                );
        });
  }

  playAudio() async {
    setState(() {
      isPlaying = true;
      songEnded = false;
      watching = false;
      uploadStarted = false;
    });
    countdown = 3;
    startTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        countdown--;
      });
      if (countdown == 1 && widget.recordVideo) {
        // if (songStarted) {
        //   controller!.resumeVideoRecording();
        // } else {
        await widget.cameraController!.startVideoRecording();
        widget.recordingsToPlay
            .setStartTime(DateTime.now().millisecondsSinceEpoch);

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
    widget.recordingsToPlay.playVideos();
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
    if (timer.isActive) {
      timer.cancel();
    }
    if (widget.recordVideo && !watching) widget.stopRecording();
    widget.recordingsToPlay.stopVideos();
    if (watching) {
      widget.recordingsToPlay.previousRecordingPlayer.pause();
    } else {
      widget.recordingsToPlay.resetRecordings();
    }
    if (watching) {
      await widget.cameraController!.initialize();
    }
    setState(() {
      watching = false;
      isPlaying = false;
      songStarted = false;
      songEnded = true;
    });

    if (widget.recordVideo) {
      // calculateDelay();
      // playVideo(videoFile.name);
      // await openPlaybackDialog();
    }
  }

  watchRecording() async {
    widget.recordingsToPlay.addRecordingMadeToRecordings();
    setState(() {
      watching = true;
    });
    await Future.delayed(Duration(milliseconds: 500));
    await widget.recordingsToPlay.playRecording();
  }

  startUpload() {
    setState(() {
      uploadStarted = true;
    });
    widget.uploadRecording();
  }

  aboveProgressBar() {
    return countdown != 0 && isPlaying
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
        : !songEnded || watching
            ? Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      onPressed: () =>
                          watching || isPlaying ? endSession() : playAudio(),
                      icon: watching || isPlaying
                          ? const Icon(Icons.stop)
                          : const Icon(Icons.play_arrow),
                      color: Colors.white,
                      iconSize: 45,
                    ),
                  ),
                  Positioned(
                    right: MediaQuery.of(context).size.width / 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Center(
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: recordVideo
                                    ? Colors.redAccent
                                    : Colors.grey,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(15),
                              ),
                              onPressed: () => setState(() {
                                    recordVideo = !recordVideo;
                                    if (recordVideo) {
                                      recordAudio = true;
                                    }
                                  }),
                              child: Icon(
                                Icons.videocam_rounded,
                                color: recordVideo ? Colors.blue : Colors.white,
                                size: 40,
                              )),
                        ),
                        Center(
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: recordAudio
                                    ? Colors.redAccent
                                    : Colors.grey,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(15),
                              ),
                              onPressed: () => setState(() {
                                    recordAudio = !recordAudio;
                                    if (!recordAudio) {
                                      recordVideo = false;
                                    }
                                  }),
                              child: Icon(
                                Icons.mic,
                                color: recordAudio ? Colors.blue : Colors.white,
                                size: 40,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => watchRecording(),
                    child: const Text(
                      "Watch Recording",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.green)),
                  ),
                  TextButton(
                    onPressed: () => playAudio(),
                    child: const Text("Sing Again",
                        style: TextStyle(color: Colors.white)),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.blue)),
                  ),
                  TextButton(
                    onPressed: () => {startUpload()},
                    child:
                        Text(uploadStarted ? "Uploading" : "Upload Recording"),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.yellow)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      songEnded = false;
                      watching = false;
                    }),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red)),
                  ),
                ],
              );
  }

  progressBar() {
    return Center(
      child: ProgressBar(
        total: songLength,
        progressBarColor: Colors.blue,
        progress: _progressValue,
        thumbRadius: 1,
        timeLabelTextStyle: const TextStyle(color: Colors.white),
        barHeight: 8,
        timeLabelLocation: TimeLabelLocation.sides,
      ),
    );
  }
}

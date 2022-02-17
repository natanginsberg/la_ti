import 'dart:async';
import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';
import 'package:wakelock/wakelock.dart';

import '../../utils/main_screen/recording_to_play.dart';

class JammingSession extends StatefulWidget {
  CameraController? cameraController;
  RecordingsToPlay recordingsToPlay;

  Widget cameraWidget;

  VoidCallback incrementJamsUsed;

  VoidCallback stopRecording;

  VoidCallback uploadRecording;

  Function(CustomUrlAudioPlayer) itemRemoved;

  Function(String, bool) followArtist;

  JammingSession(
      {Key? key,
      required this.stopRecording,
      this.cameraController,
      required this.recordingsToPlay,
      required this.cameraWidget,
      required this.uploadRecording,
      required this.itemRemoved,
      required this.incrementJamsUsed,
      required this.followArtist})
      : super(key: key);

  @override
  State<JammingSession> createState() => _JammingSessionState();
}

class _JammingSessionState extends State<JammingSession> {
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

  TextEditingController instrumentController = TextEditingController();

  bool instrumentMustBeEntered = false;

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
                width: MediaQuery.of(context).size.width * 2 / 3,
                child: buildGridView(),
              )),
          Positioned(
            bottom: 50,
            height: 80,
            width: MediaQuery.of(context).size.width * 2 / 3,
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
          bool followingMusician = false;
          if (index > 0) {
            followingMusician = widget
                .recordingsToPlay.players[index - 1].recording.userIsFollowing;
          }
          // print(index);
          return index == 0
              ? Container(
                  color: Colors.transparent,
                  width: 400,
                  child: Stack(children: [
                    Center(child: widget.cameraWidget),
                    if (songStarted && recordVideo)
                      const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.transparent,
                            )),
                      ),
                    if (watching)
                      widget.recordingsToPlay.previousRecordingPlayer.blobPlayer
                  ]))
              : Container(
                  width: 400,
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      widget.recordingsToPlay.getPlayWidget(index - 1),
                      SafeArea(
                          child: IconButton(
                        onPressed: () async {
                          bool problematicRemoval =
                              index < widget.recordingsToPlay.players.length &&
                                  songStarted;
                          if (problematicRemoval) {
                            removeProblematicVideo(index);
                          } else {
                            setState(() {
                              widget.itemRemoved(
                                  widget.recordingsToPlay.players[index - 1]);
                              widget.recordingsToPlay.removePlayer(index - 1);
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.white,
                        ),
                      )),
                      if (!isPlaying)
                        subscribeButton(
                            followingMusician,
                            widget.recordingsToPlay.players[index - 1].recording
                                .uploaderId),
                      Positioned(
                        left: 8,
                        right: 8,
                        child: Text(
                          widget.recordingsToPlay.players[index - 1].lastTime,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                );
        });
  }

  playAudio() async {
    widget.incrementJamsUsed();
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
      if (countdown == 1 && recordVideo) {
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
    await widget.recordingsToPlay.playVideos(recordVideo);
    if (widget.recordingsToPlay.isEmpty()) {
      timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
        setState(() {
          _progressValue = Duration(milliseconds: timer.tick * 100);
        });
      });
    } else {
      timer =
          Timer.periodic(const Duration(milliseconds: 100), (Timer t) async {
        double currentPosition = widget.recordingsToPlay.getCurrentPosition();
        _progressValue =
            Duration(milliseconds: (currentPosition * 1000).toInt());
        setState(() {});
        songLength = await widget.recordingsToPlay.getSongLength();
        setState(() {});
      });
    }
  }

  void endSession() async {
    await Wakelock.disable();
    if (timer.isActive) {
      timer.cancel();
    }
    if (recordVideo && !watching) widget.stopRecording();
    widget.recordingsToPlay.stopVideos();
    if (watching) {
      widget.recordingsToPlay.previousRecordingPlayer.pause();
    } else {
      widget.recordingsToPlay.resetRecordings();
    }
    if (watching) {
      widget.recordingsToPlay.previousRecordingPlayer.resetVideo();
    }
    setState(() {
      _progressValue = const Duration(seconds: 0);
      watching = false;
      isPlaying = false;
      songStarted = false;
      if (recordVideo) {
        songEnded = true;
      }
    });

    if (recordVideo) {
      // calculateDelay();
      // playVideo(videoFile.name);
      // await openPlaybackDialog();
    }
  }

  watchRecording() async {
    // widget.recordingsToPlay.addRecordingMadeToRecordings();
    await Wakelock.enable();
    setState(() {
      watching = true;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    await widget.recordingsToPlay.playRecording();
  }

  startUpload() {
    // if (instrumentController.text.isNotEmpty) {
    setState(() {
      uploadStarted = true;
    });
    widget.recordingsToPlay.instrumentPlayed = instrumentController.text;
    widget.uploadRecording();
    resetScreen();
    // } else {
    //   setState(() {
    //     instrumentMustBeEntered = true;
    //   });
    // }
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
        : !songEnded || watching || !recordVideo
            ? playButtonRow()
            : endRecordingOptions();
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

  playButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // icons in order to center play button
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(
            Icons.mic,
            color: Colors.transparent,
            size: 35,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(
            Icons.mic,
            color: Colors.transparent,
            size: 35,
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: IconButton(
            onPressed: () => watching || isPlaying ? endSession() : playAudio(),
            icon: watching || isPlaying
                ? const Icon(Icons.stop)
                : const Icon(Icons.play_arrow),
            color: Colors.white,
            iconSize: 45,
          ),
        ),
        isPlaying
            ? const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.mic,
                  color: Colors.transparent,
                  size: 35,
                ),
              )
            : Center(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: recordVideo ? Colors.redAccent : Colors.grey,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
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
                      size: 35,
                    )),
              ),
        isPlaying
            ? const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.mic,
                  color: Colors.transparent,
                  size: 35,
                ),
              )
            : Center(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: recordAudio ? Colors.redAccent : Colors.grey,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
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
                      size: 35,
                    )),
              ),
      ],
    );
  }

  endRecordingOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () => watchRecording(),
          child: const Text(
            "Watch Recording",
            style: TextStyle(color: Colors.white),
          ),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.green)),
        ),
        TextButton(
          onPressed: () => {startUpload()},
          child: Text(uploadStarted ? "Uploading" : "Upload Recording"),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.yellow)),
        ),
        TextButton(
          onPressed: () async {
            // await widget.cameraController!.initialize();
            resetScreen();
          },
          child: const Text(
            "Reset",
            style: TextStyle(color: Colors.white),
          ),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red)),
        ),
      ],
    );
  }

  void resetScreen() {
    //todo reset all parameters
    widget.recordingsToPlay.delaySet = false;
    instrumentController.clear();
    setState(() {
      songEnded = false;
      watching = false;
    });
  }

  removeVideo(int index) async {
    await widget.itemRemoved(widget.recordingsToPlay.players[index - 1]);
    await widget.recordingsToPlay.removePlayer(index - 1, true);
    setState(() {});
  }

  void removeProblematicVideo(int index) async {
    await removeVideo(index);
  }

  subscribeButton(bool userIsFollowing, String uploaderId) {
    return Positioned(
      bottom: 8,
      left: 15,
      right: 15,
      child: ElevatedButton(
        onPressed: () async {
          bool userSignIn = await widget.followArtist(uploaderId, userIsFollowing);
          widget.recordingsToPlay.changeSubscription(uploaderId);
          setState(() {});
        },
        style: ElevatedButton.styleFrom(
          primary: Colors.blueAccent,
          side: const BorderSide(color: Colors.blueAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 15.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(userIsFollowing ? 'Following' : 'Follow Musician',
              style: const TextStyle(fontSize: 15, color: Colors.white)),
        ),
      ),
    );
  }
}
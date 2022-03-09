import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:camera/camera.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:la_ti/utils/main_screen/video_status.dart';
import 'package:wakelock/wakelock.dart';

import '../../utils/firebase_access/analytics.dart';
import '../../utils/main_screen/custom_url_audio_player.dart';
import '../../utils/main_screen/monitor.dart';
import '../../utils/main_screen/recording_to_play.dart';

class JammingSession extends StatefulWidget {
  CameraController? cameraController;
  Widget? cameraWidget;

  RecordingsToPlay recordingsToPlay;

  VoidCallback incrementJamsUsed;

  Function addJam;

  Function(bool) stopRecording;

  Function(bool) uploadRecording;

  Function(CustomUrlAudioPlayer) itemRemoved;

  Function(String, bool) followArtist;

  FlutterSoundRecorder soundRecorder;

  BuildContext topTreeContext;

  JammingSession(
      {Key? key,
      required this.stopRecording,
      this.cameraController,
      required this.soundRecorder,
      required this.recordingsToPlay,
      required this.cameraWidget,
      required this.uploadRecording,
      required this.itemRemoved,
      required this.incrementJamsUsed,
      required this.followArtist,
      required this.topTreeContext,
      required this.addJam})
      : super(key: key);

  @override
  State<JammingSession> createState() => _JammingSessionState();
}

class _JammingSessionState extends State<JammingSession> {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final ScrollController _mainController = ScrollController();

  List<bool> showSlider = [false, false, false, false, false];
  Duration songLength = const Duration(seconds: 0);
  Duration _progressValue = const Duration(seconds: 0);

  Timer startTimer = Timer(const Duration(hours: 30), () {});

  Timer timer = Timer(const Duration(hours: 30), () {});

  VideoStatus vs = VideoStatus();

  int countdown = 3;

  TextEditingController instrumentController = TextEditingController();

  bool instrumentMustBeEntered = false;

  String pathForAudio = "my_video.webm";

  FlutterSoundPlayer soundPlayer = FlutterSoundPlayer();

  int currentRecorderTime = 0;

  Monitor monitor = Monitor();

  @override
  void initState() {
    super.initState();
    monitor.initMonitor();
    widget.recordingsToPlay.addEndFunction(endSession);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Wakelock.disable();
    if (timer.isActive) {
      timer.cancel();
    }
    if (startTimer.isActive) {
      startTimer.cancel();
    }
    _mainController.dispose();
    if (soundPlayer.isOpen()) {
      soundPlayer.closePlayer();
    }
    instrumentController.clear();
    instrumentController.dispose();
    monitor.dispose();

    super.dispose();
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
            bottom: 5,
            height: 80,
            width: MediaQuery.of(context).size.width * 2 / 3,
            child: Column(children: [
              progressBar(),
              aboveProgressBar(),
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
            childAspectRatio: 1.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        itemCount: 6,
        itemBuilder: (BuildContext ctx, index) {
          bool followingMusician = false;
          if (index > 0) {
            followingMusician =
                widget.recordingsToPlay.isUserFollowing(index - 1);
          }
          return index == 0
              ? currentUserSession()
              : widget.recordingsToPlay.players[index - 1] == null
                  ? emptyRecording()
                  : recording(index, followingMusician);
        });
  }

  playAudio() async {
    setState(() {
      vs.playPressed();
    });
    countdown = 3;
    startTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        countdown--;
      });
      if (countdown == 2) {
        widget.recordingsToPlay.warmUp();
        if (vs.recordVideo) {
          await widget.cameraController!.startVideoRecording();
          int secondTime = DateTime.now().millisecondsSinceEpoch;
          widget.recordingsToPlay.setStartTime(secondTime);
        } else if (vs.recordAudio) {
          startRecording();
        }
        // }
      } else if (countdown == 0) {
        startTimer.cancel();
        startSession();
      }
    });
  }

  startRecording() async {
    await widget.soundRecorder.openRecorder();
    await widget.soundRecorder
        .startRecorder(toFile: pathForAudio, codec: Codec.opusWebM);
    int secondTime = DateTime.now().millisecondsSinceEpoch;
    widget.recordingsToPlay.setStartTime(secondTime);
  }

  void startSession() async {
    Wakelock.enable;
    Analytics().playAnalytics(vs.recordAudio, vs.recordVideo);
    widget.recordingsToPlay.audioRecording = vs.onlyAudio();
    await widget.recordingsToPlay.playVideos(vs.isRecording());
    setState(() {
      vs.songStarted = true;
    });
    // if (widget.recordingsToPlay.isPlayersEmpty()) {
    timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) async {
      setState(() {
        _progressValue = Duration(milliseconds: timer.tick * 100);
      });
      if (_progressValue.inMinutes == 10) {
        endSession();
      }
      try {
        songLength = await widget.recordingsToPlay.getSongLength();
      } catch (e) {
        songLength = const Duration(seconds: 240);
      }
    });
  }

  void endSession() async {
    await Wakelock.disable();
    if (timer.isActive) {
      timer.cancel();
    }
    if (vs.recordingAndNotWatching()) {
      widget.stopRecording(vs.recordVideo);
    }
    widget.recordingsToPlay.stopVideos();
    if (vs.watching) {
      widget.recordingsToPlay.previousRecordingPlayer.pause();
    } else {
      widget.recordingsToPlay.resetRecordings();
    }
    if (vs.watching) {
      widget.recordingsToPlay.previousRecordingPlayer.resetVideo();
    }
    setState(() {
      monitor.stopMonitor();
      _progressValue = const Duration(seconds: 0);
      vs.sessionEnded();
    });
  }

  watchRecording() async {
    // widget.recordingsToPlay.addRecordingMadeToRecordings();
    await Wakelock.enable();
    setState(() {
      vs.watching = true;
    });
    await widget.recordingsToPlay.warmUp(true);
    await Future.delayed(const Duration(milliseconds: 1000));
    await widget.recordingsToPlay.playRecording();
  }

  startUpload() async {
    vs.uploadStarted = true;
    widget.recordingsToPlay.instrumentPlayed = instrumentController.text;
    bool uploading = await widget.uploadRecording(vs.recordVideo);
    if (uploading) {
      Analytics().uploadFollowedThrough();
      setState(() {});
    } else {
      vs.uploadStarted = false;
      Analytics().uploadNotContinued();
    }
  }

  aboveProgressBar() {
    return countdown != 0 && vs.isPlaying
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
        : vs.songNotEnded()
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
        // Padding(
        //   padding: const EdgeInsets.all(10.0),
        //   child: IconButton(
        //     onPressed: () {
        //       monitor.dispose();
        //     },
        //     icon: const Icon(
        //       Icons.mic,
        //       color: Colors.red,
        //       size: 35,
        //     ),
        //   ),
        // ),
        TextButton(
            style: TextButton.styleFrom(
              backgroundColor: monitor.on ? Colors.green : Colors.grey,
              // primary:
              // shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            onPressed: () {
              setState(() {
                monitor.change();
              });
            },
            child: Text(AppLocalizations.of(widget.topTreeContext)!.monitor)),
        Align(
          alignment: Alignment.center,
          child: IconButton(
            onPressed: () =>
                vs.isWatchingOrPlaying() ? endSession() : playAudio(),
            icon: vs.isWatchingOrPlaying()
                ? const Icon(Icons.stop)
                : const Icon(Icons.play_arrow),
            color: Colors.white,
            iconSize: 45,
          ),
        ),
        if (widget.recordingsToPlay.largestDifference > 0)
          Text(
            widget.recordingsToPlay.largestDifference.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        vs.isPlaying
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
                      primary: vs.recordVideo ? Colors.redAccent : Colors.grey,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
                    ),
                    onPressed: () => setState(() {
                          vs.videoChange();
                        }),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: vs.recordVideo ? Colors.blue : Colors.white,
                      size: 35,
                    )),
              ),
        vs.isPlaying || widget.recordingsToPlay.notEnoughRecordingsToSaveJam()
            ? const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.mic,
                  color: Colors.transparent,
                  size: 35,
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2),
                      Color(0xFF0D47A1),
                    ],
                  ),
                ),
                child: widget.recordingsToPlay.jamAdded
                    ? Text(
                        AppLocalizations.of(widget.topTreeContext)!.jamSaved,
                        style: const TextStyle(color: Colors.white),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          // primary:
                          // shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                        onPressed: () async {
                          if (widget.recordingsToPlay.jamAdded) {
                            bool jamAdded = await widget.addJam();
                            if (jamAdded) {
                              widget.incrementJamsUsed();
                              setState(() {
                                widget.recordingsToPlay.jamAdded = true;
                              });
                            }
                          }
                        },
                        child: Text(
                          AppLocalizations.of(widget.topTreeContext)!.saveJam,
                          style: const TextStyle(color: Colors.white),
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
          child: Text(
            AppLocalizations.of(widget.topTreeContext)!.watchVideo,
            style: const TextStyle(color: Colors.white),
          ),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.green)),
        ),
        TextButton(
          onPressed: () => {startUpload()},
          child: Text(vs.uploadStarted
              ? AppLocalizations.of(widget.topTreeContext)!.uploading
              : AppLocalizations.of(widget.topTreeContext)!.upload),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.yellow)),
        ),
        TextButton(
          onPressed: () async {
            // await widget.cameraController!.initialize();
            resetScreen();
          },
          child: Text(
            AppLocalizations.of(widget.topTreeContext)!.reset,
            style: const TextStyle(color: Colors.white),
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
    widget.recordingsToPlay.resetRecordings();
    instrumentController.clear();
    setState(() {
      vs.resetScreen();
    });
  }

  removeVideo(int index) async {
    if (widget.recordingsToPlay.players[index - 1] != null) {
      await widget.itemRemoved(widget.recordingsToPlay.players[index - 1]!);
      await widget.recordingsToPlay.removePlayer(index - 1, true);
      setState(() {});
    }
  }

  void removeProblematicVideo(int index) async {
    await removeVideo(index);
  }

  subscribeButton(bool userIsFollowing, String uploaderId) {
    return ElevatedButton(
      onPressed: () async {
        bool userSignIn =
            await widget.followArtist(uploaderId, userIsFollowing);
        if (userSignIn) {
          widget.recordingsToPlay.changeSubscription(uploaderId);
          setState(() {});
        }
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
        child: Text(
            userIsFollowing
                ? 'Following'
                : AppLocalizations.of(widget.topTreeContext)!.followMusician,
            style: const TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }

  currentUserSession() {
    return Container(
        color: Colors.transparent,
        width: 400,
        child: Stack(children: [
          Center(
              child: Stack(
            children: [
              vs.isVideoVisible
                  ? widget.cameraWidget!
                  : Container(
                      decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          border: Border.all(color: Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(20)),
                      width: 400,
                      height: 400,
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
              if (!vs.isPlaying)
                Positioned(
                  left: 10,
                  right: 10,
                  // width: 50,
                  child: SwitchListTile(
                    title: Text(
                      AppLocalizations.of(widget.topTreeContext)!.video,
                      style: const TextStyle(color: Colors.white),
                    ),
                    secondary: Icon(
                      vs.isVideoVisible ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                    ),
                    value: vs.isVideoVisible,
                    onChanged: (value) {
                      setState(() {
                        vs.isVideoVisible = value;
                        if (value == false) {
                          vs.recordVideo = false;
                        }
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ),
            ],
          )),
          if (vs.recordingInProgress())
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
          if (vs.watching)
            widget.recordingsToPlay.previousRecordingPlayer.blobPlayer
        ]));
  }

  emptyRecording() {
    return Container(
      child: Center(
        child: Text(
          AppLocalizations.of(widget.topTreeContext)!.clickToAdd,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      decoration: BoxDecoration(
          color: Colors.grey,
          border: Border.all(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(20)),
    );
  }

  recording(int index, bool followingMusician) {
    return Container(
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
                      vs.songStarted;
              if (problematicRemoval) {
                removeProblematicVideo(index);
              } else {
                setState(() {
                  widget
                      .itemRemoved(widget.recordingsToPlay.players[index - 1]!);
                  widget.recordingsToPlay.removePlayer(index - 1);
                });
              }
            },
            icon: const Icon(
              Icons.remove_circle,
              color: Colors.white,
            ),
          )),
          if (!vs.isPlaying &&
              !widget.recordingsToPlay.players[index - 1]!.recording.local)
            Positioned(
              bottom: 8,
              left: 25,
              right: 25,
              child: subscribeButton(
                  followingMusician,
                  widget.recordingsToPlay.players[index - 1]!.recording
                      .uploaderId),
            ),
          Positioned(
            left: 20,
            right: 20,
            child: Text(
              widget.recordingsToPlay.players[index - 1]!.lastTime,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Positioned(top: 8, right: 10, child: iconSlider(index - 1))
        ],
      ),
    );
  }

  iconSlider(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
            onPressed: () {
              setState(() {
                showSlider[index] = !showSlider[index];
              });
            },
            icon: const Icon(
              Icons.volume_up_outlined,
              color: Colors.white,
            )),
        if (showSlider[index])
          RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: widget.recordingsToPlay.players[index]!.videoElement.volume
                      .toDouble() *
                  100,
              max: 100,
              divisions: 100,
              onChanged: (double value) {
                setState(() {
                  widget.recordingsToPlay.players[index]!.videoElement.volume =
                      value / 100;
                });
              },
            ),
          )
      ],
    );
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:la_ti/custom_widgets/song_grid.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';
import 'package:la_ti/model/recording.dart';
import 'package:la_ti/model/recording_to_play.dart';
import 'package:la_ti/model/session.dart';
import 'package:la_ti/model/song.dart';
import 'package:la_ti/model/suggestions.dart';
import 'package:minio/minio.dart';
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

// List<CameraDescription> cameras;

List<String> _items = [
  "https://firebasestorage.googleapis.com/v0/b/auditech-877eb.appspot.com/o/%D7%AA%D7%95%D7%A4%D7%99%D7%9D%20%D7%9E%D7%A1%D7%95%D7%A0%D7%9B%D7%A8%D7%9F%201.mp4?alt=media&token=5099e210-bd0b-4d1d-9b70-92a17ee9aa71",
  "https://firebasestorage.googleapis.com/v0/b/auditech-877eb.appspot.com/o/Linkin%20Park%20-%20In%20The%20End%20(Vocal%20Track%20Only).mp4?alt=media&token=469c8310-ee43-4a0c-990a-8774a9c94fe7",
  // "https://firebasestorage.googleapis.com/v0/b/auditech-877eb.appspot.com/o/VID_20200907_153553.mp4?alt=media&token=1c7a6c63-66b0-4c46-8bb4-c9b6f0bf6f29",
  // "https://firebasestorage.googleapis.com/v0/b/auditech-877eb.appspot.com/o/VID_20201203_225432.mp4?alt=media&token=adbf9212-78e4-416c-b7fe-0accfc5066b9"
];



class MainScreen extends StatefulWidget {
  MainScreen();

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final minio = Minio(
    endPoint: "s3.wasabisys.com",
    accessKey: accessKey,
    secretKey: privateKey,
  );

  bool cameraReady = false;

  List<CustomUrlAudioPlayer> playingUrls = [];

  List<CustomUrlAudioPlayer> watchingUrls = [];

  RecordingsToPlay recordingsToPlay = RecordingsToPlay();

  List<Suggestion> suggestions = [];
  final ScrollController _mainController = ScrollController();

  var isPlaying = false;
  Timer startTimer = Timer(const Duration(hours: 30), () {});
  Timer timer = Timer(const Duration(hours: 30), () {});

  TextEditingController newSongController = TextEditingController();

  bool recordVideo = false;

  bool recordAudio = false;

  bool songStarted = false;

  bool songFinished = false;

  int countdown = 3;

  Duration delay = const Duration(seconds: 0);

  bool watchingSession = false;

  String currentSongName = "";
  String currentSongArtist = "";
  String currentSessionDoc = "";

  late VideoPlayerController playbackController;

  late XFile vFile;

  String addUrlText = "Add Url";

  bool amIHovering = false;

  double uploadPercent = 0;

  TextEditingController searchController = TextEditingController();

  bool focusOnSearch = false;

  String searchedValue = "";

  TextEditingController artistController = TextEditingController();

  bool focusOnBottom = false;

  String textSearched = "@1212";

  List<Suggestion> currentSuggestions = [];

  bool addOption = false;

  String errorMessage = "";

  String ALREADY_EXISTS_ERROR =
      "The song already exists, please make sure that it is not your song";

  String MISSING_SONG_FIELD_ERROR = "You must enter a song name and an artist";

  bool addSession = false;

  TextEditingController genreController = TextEditingController();

  TextEditingController tempoController = TextEditingController();

  var MISSING_TEMPO_CHECKER_ERROR = "You must enter a tempo name and a genre";

  Song currentSong = Song(name: "", artist: "");

  bool hovering = false;

  Session selectedValue = Session("", "", "");

  String DEFINITELY_EXISTS_ERROR_MESSAGE =
      "The song that you want to add already exists in our system";

  bool addSessionToCurrentSong = false;

  _MainScreenState();

  Duration _progressValue = new Duration(seconds: 0);
  Duration songLength = new Duration(seconds: 0);
  int updateCounter = 0;

  int trackNumber = 0;

  List<CameraDescription> cameras = [];

  CameraController? controller;
  XFile? imageFile;
  late html.File videoFile;

  // VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;
  late AnimationController _exposureModeControlRowAnimationController;
  late Animation<double> _exposureModeControlRowAnimation;
  late AnimationController _focusModeControlRowAnimationController;
  late Animation<double> _focusModeControlRowAnimation;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  TextEditingController songNameController = TextEditingController();

  // Wakelock.toggle(enable: isPlaying);

  @override
  Future<void> dispose() async {
    if (controller != null) {
      controller!.dispose();
      controller = null;
    }
    searchController.dispose();
    if (controller != null) controller!.dispose();
    artistController.dispose();
    songNameController.dispose();
    tempoController.dispose();
    genreController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getFirebaseUrls();
    getCameras();
  }

  //todo tablet addittion
  void getCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      cameras = await availableCameras();
      controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      controller!.initialize().then((value) {
        setState(() {
          cameraReady = true;
        });
      });
    } on CameraException catch (e) {
      // logError(e.code, e.description);
    }
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = controller;
    // print(cameras);
    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Icon(
        Icons.cloud,
        color: Colors.white,
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              // onTapDown: (details) => onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  void backButton() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: WillPopScope(
      onWillPop: () {
        return Future.value(true);
      },
      child: Scaffold(
          body: Container(
        // height: MediaQuery.of(context).size.height,
        // width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
            gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [
            Colors.redAccent,
            Colors.black,
          ],
        )),
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 48,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      "Title: " + currentSong.name,
                      style: const TextStyle(color: Colors.blue),
                    ),
                    Text("Artist: " + currentSong.artist,
                        style: const TextStyle(color: Colors.blue)),
                    Flexible(
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: "Record Video",
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    recordVideo = !recordVideo;
                                    if (recordVideo) {
                                      recordAudio = true;
                                    }
                                  });
                                }),
                        ]),
                      ),
                    ),
                    Theme(
                      data: ThemeData(unselectedWidgetColor: Colors.red),
                      child: Checkbox(
                        //    <-- label
                        value: recordVideo,
                        onChanged: (newValue) {
                          setState(() {
                            recordVideo = !recordVideo;
                            if (recordVideo) {
                              recordAudio = true;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 25,
                    ),
                    Flexible(
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: "Record Audio",
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    recordAudio = !recordAudio;
                                  });
                                }),
                        ]),
                      ),
                    ),
                    Theme(
                      data: ThemeData(unselectedWidgetColor: Colors.red),
                      child: Checkbox(
                        //    <-- label
                        value: recordAudio,
                        onChanged: (newValue) {
                          setState(() {
                            recordAudio = !recordAudio;
                          });
                        },
                      ),
                    )
                  ]),
            ),
            Flexible(
              child: Row(
                children: [
                  SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      child: songsSide()),
                  SizedBox(
                    child: playSide(),
                    width: 2 * MediaQuery.of(context).size.width / 3,
                  )
                ],
              ),
            ),
          ],
        ),
      )),
    ));
  }

  buildGridView() {
    return GridView.builder(
        controller: _mainController,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5),
        itemCount: recordingsToPlay.players.length + 1,
        // playingUrls.length + 1,
        itemBuilder: (BuildContext ctx, index) {
          // print(index);
          return index == 0
              ? SizedBox(
                  width: 400,
                  child: Stack(children: [
                    watchingSession
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: VideoPlayer(playbackController))
                        : _cameraPreviewWidget(),
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
                      )
                  ]))
              : Container(
                  width: 400,
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: VideoPlayer(
                              recordingsToPlay.getPlayerController(index - 1))),
                      // playingUrls[index - 1].getController())),
                      SafeArea(
                          child: IconButton(
                        onPressed: () async {
                          // playingUrls[index - 1].removeAudioPlayer();
                          setState(() {
                            // playingUrls.removeAt(index - 1);
                            recordingsToPlay.removePlayer(index - 1);
                          });
                        },
                        icon: const Icon(Icons.remove_circle),
                      ))
                    ],
                  ),
                );
        });
  }

  Widget _buildMenuList() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16.0),
      itemCount: watchingUrls.length,
      itemBuilder: (context, index) {
        final item = watchingUrls[index];
        return _buildMenuItem(
          item: item,
        );
      },
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 1,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15),
    );
  }

  Widget _buildMenuItem({
    required CustomUrlAudioPlayer item,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (PointerEvent details) => setState(() => amIHovering = true),
      onExit: (PointerEvent details) => setState(() {
        amIHovering = false;
      }),
      child: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 50,
            child: Center(child: VideoPlayer(item.getController())),
          ),
          GestureDetector(
            onTap: () async {
              pauseAudio();
              CustomUrlAudioPlayer customPlayer =
                  CustomUrlAudioPlayer(item.path, () {
                endSession();
              });
              // customPlayer.initialize();
              // resetRecordings();
              recordingsToPlay.resetRecordings();
              setState(() {
                // playingUrls.add(customPlayer);
                recordingsToPlay.addPlayer(customPlayer);
              });
            },
            child: Container(
              width: MediaQuery.of(context).size.width / 2 - 50,
              color: Colors.transparent,
              // child: Center(child: VideoPlayer(item.getController())),
            ),
          ),
        ],
      ),
    );
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
      if (countdown == 1 && recordVideo) {
        // if (songStarted) {
        //   controller!.resumeVideoRecording();
        // } else {
        controller!.startVideoRecording();
        // }
      } else if (countdown == 0) {
        startTimer.cancel();
        startSession();
      }
    });
  }

  pauseAudio() async {
    setState(() {
      isPlaying = false;
    });
    // if (playingUrls.isNotEmpty) {
    //   for (CustomUrlAudioPlayer player in playingUrls) {
    //     await player.pause();
    //   }
    //   Duration? currentTime = await playingUrls[0].getCurrentPosition();
    //   for (CustomUrlAudioPlayer player in playingUrls) {
    //     if (currentTime != null) await player.seek(currentTime);
    //   }
    // }
    recordingsToPlay.pauseVideo();
  }

  // getCurrentPosition() async {
  //   // int position = await playingUrls[0].getCurrentPosition();
  //   // print("this is the current position " + position.toString());
  //   // return Duration(milliseconds: position);
  //   Duration? d = await playingUrls[0].getCurrentPosition();
  //   return d;
  // }

  void startSession() async {
    setState(() {
      songStarted = true;
    });
    Wakelock.enable;
    // todo start videos
    recordingsToPlay.playVideos();
    // for (CustomUrlAudioPlayer player in playingUrls) {
    //   await player.play();
    // }
    // if (watchingSession) {
    //   playbackController.play();
    // }
    // if (playingUrls.isNotEmpty) {
    //   songLength = await playingUrls[0].getDuration();
    if (recordingsToPlay.isEmpty()) {
      timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
        setState(() {
          _progressValue = Duration(milliseconds: timer.tick * 100);
        });
      });
    } else {
      timer =
          Timer.periodic(const Duration(milliseconds: 100), (Timer t) async {
        _progressValue = await recordingsToPlay.getCurrentPosition();
        // (await playingUrls[0].getCurrentPosition())!;
        setState(() {});
        songLength = await recordingsToPlay.getSongLength();
        setState(() {});
      });
    }
  }

  stopVideoRecording() async {
    print("reached");
    setState(() {
      songFinished = true;
    });

    vFile = await controller!.stopVideoRecording();

    videoFile = html.File(await vFile.readAsBytes(), vFile.path);
    playVideo(videoFile.name);
  }

  void endSession() async {
    timer.cancel();
    setState(() {
      isPlaying = false;
      songStarted = false;
    });
    if (recordVideo) await stopVideoRecording();
    // stopVideos();
    // resetRecordings();
    recordingsToPlay.stopVideos();
    recordingsToPlay.resetRecordings();
    setState(() {
      addUrlText = "לפני פתיחה";
    });
    if (recordVideo) {
      calculateDelay();
      playVideo(videoFile.name);
      // await openPlaybackDialog();
    }
  }

  // stopVideos() async {
  //   print("stopped");
  //   for (CustomUrlAudioPlayer player in playingUrls) {
  //     await player.stop();
  //   }
  // }

  // void resetRecordings() async {
  //   for (CustomUrlAudioPlayer player in playingUrls) {
  //     await player.seek(const Duration(seconds: 0));
  //   }
  // }

  void calculateDelay() async {
    // playbackController = VideoPlayerController
    // .(videoFile);
    // await playbackController.initialize();
    // delay = (playbackController.value.duration - songLength);
    // await playbackController.seekTo(delay);
    // print("this is the delay " + delay.inMilliseconds.toString()
    // );
  }

  Future<void> openPlaybackDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Outstanding'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Would you like to watch your session?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                // setState(() {
                //   watchingSession = true;
                // });
                playVideo(videoFile.name);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void playVideo(String atUrl) async {
    if (kIsWeb) {
      // uploadToWasabi(vFile.openRead(), await vFile.length());
      CustomUrlAudioPlayer customUrlAudioPlayer =
          CustomUrlAudioPlayer(vFile.path, endSession);
      setState(() {
        watchingUrls.add(customUrlAudioPlayer);
      });
      customUrlAudioPlayer.initialize();
      // final v = html.window.document.getElementById('videoPlayer');
      // if (v != null) {
      //   v.setInnerHtml('<source type="video/mp4" src="$atUrl">',
      //       validator: html.NodeValidatorBuilder()
      //         ..allowElement('source', attributes: ['src', 'type']));
      //   final a = html.window.document.getElementById('triggerVideoPlayer');
      //   if (a != null) {
      //     a.dispatchEvent(html.MouseEvent('click'));
      //   }
      // }
    } else {
      // we're not on the web platform
      // and should use the video_player package
    }
  }

  void uploadToWasabi(Stream<Uint8List> fileStream, int fileLength) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    String fileName = formattedDate;
    await minio.putObject(
      'new-test-bucket-222',
      fileName,
      fileStream,
      metadata: {'x-amz-acl': 'public-read'},
      onProgress: (bytes) => setState(() {
        uploadPercent = 100 * bytes.toDouble() / fileLength.toDouble();
      }),
    );
    String url = "https://s3.wasabisys.com/new-test-bucket-222/$fileName";
    CustomUrlAudioPlayer customUrlAudioPlayer =
        CustomUrlAudioPlayer(url, endSession);
    setState(() {
      watchingUrls.add(customUrlAudioPlayer);
    });
    customUrlAudioPlayer.initialize();
    addUrlToFirebase(url);
  }

  void getFirebaseUrls() async {
    FirebaseFirestore.instance
        .collection('urls')
        .get()
        .then((QuerySnapshot querySnapshot) {
      print(querySnapshot.docs.length);
      for (var doc in querySnapshot.docs) {
        CustomUrlAudioPlayer customUrlAudioPlayer =
            CustomUrlAudioPlayer(doc.get("path"), endSession);
        customUrlAudioPlayer.initialize();
        setState(() {
          watchingUrls.add(customUrlAudioPlayer);
        });
      }
    });
  }

  void addUrlToFirebase(String value) async {
    FirebaseFirestore.instance.collection('urls').add({"path": value});
    await FirebaseFirestore.instance
        .collection('songs')
        .doc(currentSong.getId())
        .collection("sessions")
        .doc(currentSong.currentSession.id)
        .collection("recordings")
        .doc()
        .set({"url": value});
  }

  pickAndUploadFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      Future<Uint8List> fileStream = Future(() => fileBytes!);
      uploadToWasabi(Stream.fromFuture(fileStream), result.files.first.size);

      // String fileName = result.files.first.name;

      // Upload file
      // await FirebaseStorage.instance.ref('uploads/$fileName').putData(
      //     fileBytes);
    }
  }

  playSide() {
    return SongGrid(
      cameraWidget: _cameraPreviewWidget(),
      recordingsToPlay: recordingsToPlay,
      recordVideo: recordVideo,
      cameraController: controller,
      stopRecording: stopVideoRecording,
    );
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

  songsSide() {
    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 180.0),
              child: _buildMenuList()),
          if (currentSong.sessions.isNotEmpty) buildSessionDropdown(),
          if (currentSong.sessions.isNotEmpty) addSongButton(),
          if (addSessionToCurrentSong) currentSessionAdder(),
          searchBar(),
          // if (focusOnSearch)
        ],
      ),
    );
  }

  searchBar() {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hovering) {
          setState(() {
            focusOnSearch = hasFocus;
          });
        }
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 15, 8, 0),
          child: Column(children: [
            Container(
              width: MediaQuery.of(context).size.width / 4,
              height: 48,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: focusOnSearch
                      ? const BorderRadius.only(
                          topRight: Radius.circular(10.0),
                          topLeft: Radius.circular(10.0))
                      : BorderRadius.circular(50),
                  gradient: const RadialGradient(
                    center: Alignment.center,
                    radius: 4,
                    colors: [
                      Colors.black,
                      Colors.redAccent,
                    ],
                  )),
              child: Stack(children: [
                Center(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Search",
                      hintStyle: TextStyle(color: Colors.white),
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (String value) {
                      setState(() {});
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            focusOnBottom = !focusOnBottom;
                          });
                        },
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        )),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      searchController.clear();
                    },
                  ),
                ),
              ]),
            ),
            if ((focusOnSearch) || focusOnBottom) suggestionBox()
          ]),
        ),
      ),
    );
  }

  getSuggestions() async {
    if (searchController.text.length < textSearched.length) {
      searchedValue = searchController.text;
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('allSongsData').get();
      if (searchController.text == "") {
        currentSuggestions = querySnapshot.docs
            .map((doc) => Suggestion(doc["songName"], doc["songArtist"]))
            .toList();
      } else {
        currentSuggestions = querySnapshot.docs
            .map((doc) => Suggestion(doc["songName"], doc["songArtist"]))
            .where((suggestion) => suggestion.contains(searchController.text))
            .toList();
      }
    } else {
      currentSuggestions = currentSuggestions
          .where((suggestion) => suggestion.contains(searchController.text))
          .toList();
    }
    return currentSuggestions;
  }

  addSongOption() {
    if (addSession) {
      return sessionAdder();
    }
    return Column(
      children: [
        const SizedBox(
          height: 20,
          child: Text("Add Song"),
        ),
        Container(
          width: MediaQuery.of(context).size.width / 4.2,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: TextField(
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
              controller: songNameController,
              decoration: const InputDecoration(
                hintText: "Song Name",
                hintStyle: TextStyle(color: Colors.grey),
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          width: MediaQuery.of(context).size.width / 4.2,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: TextField(
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
              controller: artistController,
              decoration: const InputDecoration(
                hintText: "Song Artist",
                hintStyle: TextStyle(color: Colors.grey),
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        TextButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.green)),
            onPressed: () => continueWithAddingSong(),
            child: const Text(
              "Continue",
              style: TextStyle(color: Colors.white),
            )),
        const SizedBox(
          height: 10,
        ),
        if (errorMessage != "")
          Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          )
      ],
    );
  }

  suggestionBox() {
    return Container(
      height: 200,
      width: MediaQuery.of(context).size.width / 4,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 2),
          borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(10.0),
              bottomLeft: Radius.circular(10.0)),
          color: Colors.white),
      child: focusOnBottom
          ? addSongOption()
          : FutureBuilder(
              builder: (context, suggestionsSnap) {
                if (suggestionsSnap.connectionState == ConnectionState.none &&
                    suggestionsSnap.hasData) {
                  //print('project snapshot data is: ${projectSnap.data}');
                  return Container();
                } else if (suggestionsSnap.connectionState ==
                    ConnectionState.waiting) {
                  return const CupertinoActivityIndicator();
                } else {
                  List<Suggestion> suggestions =
                      suggestionsSnap.data as List<Suggestion>;
                  // if (suggestions.isEmpty) {
                  //   setState(() {
                  //     addOption = true;
                  //   });
                  // }
                  return ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      Suggestion suggestion = suggestions[index];
                      return Column(
                        children: [
                          FocusableActionDetector(
                            onShowHoverHighlight: _handleHoveHighlight,
                            child: TextButton(
                                onPressed: () {
                                  getSongFromFirebase(suggestion);
                                  setState(() {
                                    focusOnSearch = false;
                                    focusOnBottom = false;
                                  });
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: suggestion.songName,
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold),
                                    children: <TextSpan>[
                                      const TextSpan(
                                          text: ' by  ',
                                          style: TextStyle(
                                              fontStyle: FontStyle.italic)),
                                      TextSpan(
                                          text: suggestion.songArtist,
                                          style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                )),
                          )
                        ],
                      );
                    },
                  );
                }
              },
              future: getSuggestions(),
            ),
    );
  }

  void _handleHoveHighlight(bool value) {
    hovering = value;
  }

  continueWithAddingSong() async {
    if (inputCorrect(false)) {
      if (errorMessage != ALREADY_EXISTS_ERROR) {
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance.collection('allSongsData').get();
        List<Suggestion> currentSuggestions = querySnapshot.docs
            .map((doc) => Suggestion(doc["songName"], doc["songArtist"]))
            .toList();
        if (currentSuggestions.indexWhere((element) =>
                element.songName == songNameController.text &&
                element.songArtist == artistController.text) >
            -1) {
          setState(() {
            errorMessage = DEFINITELY_EXISTS_ERROR_MESSAGE;
          });
          return;
        }
        if (currentSuggestions.indexWhere(
                (element) => element.songName == songNameController.text) >
            -1) {
          setState(() {
            errorMessage = ALREADY_EXISTS_ERROR;
          });
          return;
        }
      }
      setState(() {
        errorMessage = "";
        addSession = true;
      });
    }
  }

  bool inputCorrect(bool sessionChecker) {
    if ((sessionChecker &&
            tempoController.text != "" &&
            genreController.text != "") ||
        (!sessionChecker &&
            songNameController.text != "" &&
            artistController.text != "")) {
      return true;
    } else {
      setState(() {
        errorMessage = sessionChecker
            ? MISSING_TEMPO_CHECKER_ERROR
            : MISSING_SONG_FIELD_ERROR;
      });
      return false;
    }
  }

  checkSessionAndUpdate() async {
    if (inputCorrect(true)) {
      if (addSessionToCurrentSong) {
        addSessionToFirebase();
      } else {
        addSongToFirebase();
      }
    }
  }

  void addSongToFirebase() async {
    Map<String, String> songToAdd = {
      "songName": songNameController.text,
      "songArtist": artistController.text
    };

    await FirebaseFirestore.instance.collection('allSongsData').add(songToAdd);
    String id = songNameController.text + " " + artistController.text;
    await FirebaseFirestore.instance.collection('songs').doc(id).set(songToAdd);
    await FirebaseFirestore.instance
        .collection('songs')
        .doc(id)
        .collection("sessions")
        .add({"tempo": tempoController.text, "genre": genreController.text});
    setState(() {
      addSessionToCurrentSong = false;
      addSession = false;
      focusOnBottom = false;
      focusOnSearch = false;
      errorMessage = "";
      resetControllers();
    });
  }

  sessionAdder() {
    return Column(
      children: [
        Center(
          child: SizedBox(
              height: 20,
              child: Text(addSessionToCurrentSong
                  ? "Add s session"
                  : "You must add a session to begin")),
        ),
        Container(
          width: MediaQuery.of(context).size.width / 4.2,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: TextField(
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
              controller: genreController,
              decoration: const InputDecoration(
                hintText: "Genre",
                hintStyle: TextStyle(color: Colors.grey),
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          width: MediaQuery.of(context).size.width / 4.2,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: TextField(
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
              controller: tempoController,
              decoration: const InputDecoration(
                hintText: "Tempo",
                hintStyle: TextStyle(color: Colors.grey),
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        TextButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.green)),
            onPressed: () => checkSessionAndUpdate(),
            child: Text(
              addSessionToCurrentSong ? "Add Session" : "Add Song",
              style: TextStyle(color: Colors.white),
            )),
        const SizedBox(
          height: 10,
        ),
        if (errorMessage != "")
          Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          )
      ],
    );
  }

  void resetControllers() {
    artistController.text = "";
    tempoController.text = "";
    genreController.text = "";
    songNameController.text = "";
  }

  getSongFromFirebase(Suggestion suggestion) async {
    String id = suggestion.songName + " " + suggestion.songArtist;
    DocumentSnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('songs').doc(id).get();
    currentSong = Song(
        name: querySnapshot.get("songName") as String,
        artist: querySnapshot.get("songArtist") as String);
    FirebaseFirestore.instance
        .collection('songs')
        .doc(id)
        .collection("sessions")
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        Session newSession =
            Session(doc.id, doc.get("tempo"), doc.get("genre"));
        try {
          FirebaseFirestore.instance
              .collection('songs')
              .doc(id)
              .collection("sessions")
              .doc(doc.id)
              .collection("recordings")
              .get()
              .then((QuerySnapshot querySnapshot2) {
            querySnapshot2.docs.forEach((doc2) {
              newSession.addRecording(Recording(doc2.get("url")));
            });
          });
        } catch (exception) {}
        currentSong.addSession(newSession);
        setState(() {
          watchingUrls.clear();
          selectedValue = currentSong.currentSession;
        });
        refreshRecordings();
      });
    });
  }

  buildSessionDropdown() {
    return Positioned(
      top: 100,
      height: 50,
      child: Row(
        children: [
          TextButton(
              onPressed: () => setState(() {
                    addSessionToCurrentSong = true;
                  }),
              child: const Text("Add a new session")),
          DropdownButton2(
            // hint: Text(
            //   'Select Session',
            //   style: TextStyle(
            //     fontSize: 14,
            //     color: Theme.of(context).hintColor,
            //   ),
            // ),
            items: currentSong.sessions
                .map((item) => DropdownMenuItem<Session>(
                      value: item,
                      child: Text(
                        "Genre: " + item.genre + " Tempo: " + item.tempo,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                .toList(),
            value: selectedValue,
            onChanged: (value) {
              setState(() {
                selectedValue = value as Session;
              });
              refreshRecordings();
              currentSong.currentSession = selectedValue;
            },
            buttonHeight: 40,
            buttonWidth: MediaQuery.of(context).size.width / 4.2,
            itemHeight: 40,
          ),
        ],
      ),
    );
  }

  addSongButton() {
    return Positioned(
        height: 25,
        top: 155,
        left: (MediaQuery.of(context).size.width / 3 -
                    MediaQuery.of(context).size.width / 4.2) /
                2 -
            10,
        right: (MediaQuery.of(context).size.width / 3 -
                    MediaQuery.of(context).size.width / 4.2) /
                2 -
            10,
        child: TextButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue)),
          onPressed: pickAndUploadFiles,
          child: Text(
            uploadPercent == 0 ? "Add Song" : uploadPercent.toString() + " %",
            style: const TextStyle(color: Colors.white),
          ),
        ));
  }

  void refreshRecordings() {
    setState(() {
      watchingUrls.clear();
    });
    for (Recording recording in selectedValue.recordings) {
      CustomUrlAudioPlayer customUrlAudioPlayer =
          CustomUrlAudioPlayer(recording.url, endSession);
      setState(() {
        watchingUrls.add(customUrlAudioPlayer);
      });
      customUrlAudioPlayer.initialize();
    }
  }

  void openSessionAdder() {}

  void addSessionToFirebase() async {
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('songs')
        .doc(currentSong.getId())
        .collection("sessions")
        .add({"tempo": tempoController.text, "genre": genreController.text});
    Session newSession =
        Session(docRef.id, tempoController.text, genreController.text);
    setState(() {
      currentSong.addSession(newSession);
      currentSong.currentSession = newSession;
      selectedValue = newSession;
      addSessionToCurrentSong = false;
      addSession = false;
      focusOnBottom = false;
      focusOnSearch = false;
      errorMessage = "";
      resetControllers();
    });
  }

  currentSessionAdder() {
    return Positioned(
      top: 155,
      left: (MediaQuery.of(context).size.width / 3 -
                  MediaQuery.of(context).size.width / 4) /
              2 -
          10,
      right: (MediaQuery.of(context).size.width / 3 -
                  MediaQuery.of(context).size.width / 4) /
              2 -
          10,
      child: Container(
          height: 200,
          width: MediaQuery.of(context).size.width / 4,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(10.0),
                  bottomLeft: Radius.circular(10.0)),
              color: Colors.white),
          child: Stack(children: [
            sessionAdder(),
            IconButton(
                onPressed: () => setState(() {
                      addSessionToCurrentSong = false;
                      errorMessage = "";
                      resetControllers();
                    }),
                icon: const Icon(
                  Icons.close,
                  color: Colors.black,
                ))
          ])),
    );
  }
}

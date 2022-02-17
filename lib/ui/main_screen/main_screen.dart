import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';
import 'package:la_ti/model/lasi_user.dart';
import 'package:la_ti/model/recording.dart';
import 'package:la_ti/model/session.dart';
import 'package:la_ti/model/song.dart';
import 'package:la_ti/model/suggestions.dart';
import 'package:la_ti/utils/firebase_access/songs.dart';
import 'package:la_ti/utils/wasabi_uploader.dart';
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart';

import '../../utils/main_screen/recording_to_play.dart';
import 'jammin_session.dart';

class MainScreen extends StatefulWidget {
  MainScreen();

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool cameraReady = false;

  List<CustomUrlAudioPlayer> playingUrls = [];

  List<CustomUrlAudioPlayer> watchingUrls = [];

  RecordingsToPlay recordingsToPlay = RecordingsToPlay();

  List<Suggestion> suggestions = [];

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

  TextEditingController subGenreController = TextEditingController();

  var MISSING_SUB_GENRE_CHECKER_ERROR =
      "You must enter a Sub Genre name and a genre";

  Song currentSong = Song(name: "", artist: "");

  bool hovering = false;

  Session selectedValue = Session("", "", "");

  String DEFINITELY_EXISTS_ERROR_MESSAGE =
      "The song that you want to add already exists in our system";

  bool addSessionToCurrentSong = false;

  late LasiUser lasiUser;

  _MainScreenState();

  Duration songLength = const Duration(seconds: 0);
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
    subGenreController.dispose();
    genreController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    signIn();
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
          appBar: AppBar(
            title: Row(
              children: [
                const Text("La-Si"),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 4,
                ),
                if (currentSong.name != "")
                  Text(
                    "Title: " + currentSong.name,
                    style: const TextStyle(color: Colors.blue),
                  ),
                const SizedBox(
                  width: 80,
                ),
                if (currentSong.name != "")
                  Text("Artist: " + currentSong.artist,
                      style: const TextStyle(color: Colors.blue)),
                const Expanded(
                  child: SizedBox(
                    width: 10,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result =
                        await Navigator.pushNamed(context, '/signIn');
                    if (result != null) {
                      final User user = result as User;
                      changeLasiUser(user);
                      Navigator.pushNamed(context, '/personalScreen',
                          arguments: user);
                    }
                  },
                  child: const Text(
                    "Personal Section",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      FirebaseAuth.instance.signOut();
                      signIn();
                    },
                    child: const Text(
                      "Sign Out",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
            backgroundColor: Colors.black,
          ),
          body: Container(
            // height: MediaQuery.of(context).size.height,
            // width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
                gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [
                Colors.tealAccent,
                Colors.black,
              ],
            )),
            child: Column(
              children: [
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
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: MediaQuery.of(context).size.width / 5,
          childAspectRatio: 0.72,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15),
    );
  }

  Widget _buildMenuItem({
    required CustomUrlAudioPlayer item,
  }) {
    double width = MediaQuery.of(context).size.width / 5;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (PointerEvent details) => setState(() => amIHovering = true),
      onExit: (PointerEvent details) => setState(() {
        amIHovering = false;
      }),
      child: SizedBox(
        width: width,
        child: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.width / 5 - 50,
                    child: item.getController()),
                Column(
                  children: [
                    Text(
                      "Part of " + item.recording.jamsIn.toString() + " jams",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Uploaded on " + item.recording.uploadDate,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "By " + item.recording.uploaderDisplayName,
                      style: const TextStyle(color: Colors.white),
                    )
                  ],
                )
              ],
            ),
            GestureDetector(
              onTap: () async {
                if (!lasiUser.anonymous) {
                  if (lasiUser
                      .isUserFollowingArtist(item.recording.uploaderId)) {
                    item.recording.userIsFollowing = true;
                  } else {
                    item.recording.userIsFollowing = true;
                  }
                }
                recordingsToPlay.addCustomPlayer(item);
                watchingUrls.remove(item);
                setState(() {});
              },
              child: Container(
                width: MediaQuery.of(context).size.width / 2 - 50,
                color: Colors.transparent,
                // child: Center(child: VideoPlayer(item.getController())),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: IconButton(
                iconSize: 40,
                icon: item.playPressed
                    ? const Icon(Icons.stop_circle)
                    : const Icon(Icons.play_circle_fill),
                onPressed: () async {
                  if (item.playPressed) {
                    item.stop();
                    setState(() {
                      item.playPressed = false;
                    });
                  } else {
                    await item.play();
                    setState(() {
                      item.playPressed = true;
                    });
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  pauseAudio() async {
    setState(() {
      isPlaying = false;
    });

    recordingsToPlay.pauseVideo();
  }

  stopVideoRecording() async {
    setState(() {
      songFinished = true;
    });

    vFile = await controller!.stopVideoRecording();
    Recording recording = Recording(vFile.path, recordingsToPlay.delay, "");
    CustomUrlAudioPlayer customUrlAudioPlayer =
        CustomUrlAudioPlayer(recording, endSession, recordingsToPlay.delay);
    // addItemToWatchingUrls(customUrlAudioPlayer);
    recordingsToPlay.setRecording(customUrlAudioPlayer);
    // customUrlAudioPlayer.initialize();
  }

  void endSession() async {
    timer.cancel();
    setState(() {
      isPlaying = false;
      songStarted = false;
    });
    if (recordVideo) await stopVideoRecording();

    recordingsToPlay.stopVideos();
    recordingsToPlay.resetRecordings();
    setState(() {
      addUrlText = "לפני פתיחה";
    });
  }

  void uploadRecordingToWasabi() async {
    final result = await Navigator.pushNamed(context, '/signIn');
    if (result != null) {
      final User user = result as User;
      changeLasiUser(user);
      uploadToWasabi(vFile.openRead(), recordingsToPlay.delay, user);
      Recording recording = Recording(vFile.path, recordingsToPlay.delay, "",
          DateFormat('yyyy-MM-dd').format(DateTime.now()), user.displayName!);
      CustomUrlAudioPlayer customUrlAudioPlayer =
          CustomUrlAudioPlayer(recording, endSession, recordingsToPlay.delay);
      setState(() {
        watchingUrls.add(customUrlAudioPlayer);
      });
    }
  }

  void uploadToWasabi(
      Stream<Uint8List> fileStream, int delay, User user) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd–kk:mm').format(now);
    String fileName = formattedDate + user.uid;
    String url = await SongDatabase().uploadToWasabi(fileStream, fileName);
    addUrlToFirebase(url, delay, user);
  }

  void getFirebaseUrls() async {
    FirebaseFirestore.instance
        .collection('urls')
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        Recording recording =
            Recording(doc.get("url"), doc.get("delay"), doc.id);
        Map docData = doc.data() as Map;
        if (docData.containsKey("jamsIn")) recording.jamsIn = doc.get("jamsIn");
        if (docData.containsKey("userUploadDisplayName")) {
          recording.uploaderDisplayName = doc.get("userUploadDisplayName");
        }
        if (docData.containsKey("dateUploaded")) {
          recording.uploadDate = doc.get("dateUploaded");
        }
        if (docData.containsKey("userUploadId")) {
          recording.uploaderId = doc.get("userUploadId");
        }
        CustomUrlAudioPlayer customUrlAudioPlayer =
            CustomUrlAudioPlayer(recording, endSession, doc.get("delay"));
        addItemToWatchingUrls(customUrlAudioPlayer);
      }
    });
  }

  void addUrlToFirebase(String value, int delay, User user) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Map<String, dynamic> recordingData = {
      "instrument": "undefined",
      "url": value,
      "delay": delay,
      "userUploadId": user.uid,
      "userUploadEmail": user.email,
      "dateUploaded": formattedDate,
      "jamsIn": 0,
      "userUploadDisplayName": user.displayName
    };
    FirebaseFirestore.instance.collection('urls').add(recordingData);
    if (currentSong.name != "") {
      // add document to songs
      await FirebaseFirestore.instance
          .collection('songs')
          .doc(currentSong.getId())
          .collection("sessions")
          .doc(currentSong.currentSession.id)
          .collection("recordings")
          .doc()
          .set(recordingData);
      // add doc to user for user docs
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("recordings")
          .doc()
          .set({
        'songName': currentSong.name,
        'songArtist': currentSong.artist,
        'songId': currentSong.getId(),
        'sessionId': currentSong.currentSession.id,
        'url': value,
        "dateUploaded": formattedDate
      });
      // update the amount of recordings the user has uploaded
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"uploads": FieldValue.increment(1)});
    }
  }

  pickAndUploadFiles() async {
    final signInResult = await Navigator.pushNamed(context, '/signIn');
    if (signInResult != null) {
      final User user = signInResult as User;
      changeLasiUser(user);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'webm'],
      );

      if (result != null) {
        Uint8List? fileBytes = result.files.first.bytes;
        Future<Uint8List> fileStream = Future(() => fileBytes!);
        uploadToWasabi(Stream.fromFuture(fileStream), 0, user);
        // adding the uploaded file to playing options
        Recording recording = Recording(result.files.first.path!, 0, "");
        CustomUrlAudioPlayer customUrlAudioPlayer =
            CustomUrlAudioPlayer(recording, endSession, 0);
        setState(() {
          watchingUrls.add(customUrlAudioPlayer);
        });
      }
    }
  }

  playSide() {
    return JammingSession(
        cameraWidget: _cameraPreviewWidget(),
        recordingsToPlay: recordingsToPlay,
        cameraController: controller,
        stopRecording: stopVideoRecording,
        uploadRecording: uploadRecordingToWasabi,
        itemRemoved: itemRemoved,
        incrementJamsUsed: incrementRecordingsUsed,
        followArtist: followArtist);
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
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green)),
                onPressed: () => continueWithAddingSong(),
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.white),
                )),
            TextButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red)),
                onPressed: () => setState(() {
                      focusOnBottom = false;
                      focusOnSearch = false;
                      resetControllers();
                    }),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                )),
          ],
        ),
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
                  return Container();
                } else if (suggestionsSnap.connectionState ==
                    ConnectionState.waiting) {
                  return const CupertinoActivityIndicator();
                } else {
                  List<Suggestion> suggestions =
                      suggestionsSnap.data as List<Suggestion>;
                  if (suggestions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 70, horizontal: 0),
                      child: Column(
                        children: [
                          const Text("No songs match your search"),
                          FocusableActionDetector(
                            onShowHoverHighlight: _handleHoveHighlight,
                            child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    focusOnBottom = !focusOnBottom;
                                    songNameController.text =
                                        searchController.text;
                                    hovering = false;
                                  });
                                },
                                child:
                                    const Text("To add a new song click here")),
                          )
                        ],
                      ),
                    );
                  } else {
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
                                      hovering = false;
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
                                            text: ' -  ',
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
            subGenreController.text != "" &&
            genreController.text != "") ||
        (!sessionChecker &&
            songNameController.text != "" &&
            artistController.text != "")) {
      return true;
    } else {
      setState(() {
        errorMessage = sessionChecker
            ? MISSING_SUB_GENRE_CHECKER_ERROR
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
        .add({
      "subGenre": subGenreController.text,
      "genre": genreController.text
    });
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
              controller: subGenreController,
              decoration: const InputDecoration(
                hintText: "Sub Genre",
                hintStyle: TextStyle(color: Colors.grey),
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green)),
                onPressed: () => checkSessionAndUpdate(),
                child: Text(
                  addSessionToCurrentSong ? "Add Session" : "Add Song",
                  style: const TextStyle(color: Colors.white),
                )),
            TextButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red)),
                onPressed: () => setState(() {
                      focusOnBottom = false;
                      focusOnSearch = false;
                      resetControllers();
                    }),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                )),
          ],
        ),
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
    subGenreController.text = "";
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
      for (var doc in querySnapshot.docs) {
        Session newSession =
            Session(doc.id, doc.get("subGenre"), doc.get("genre"));
        try {
          FirebaseFirestore.instance
              .collection('songs')
              .doc(id)
              .collection("sessions")
              .doc(doc.id)
              .collection("recordings")
              .get()
              .then((QuerySnapshot querySnapshot2) {
            for (var doc2 in querySnapshot2.docs) {
              Recording recording =
                  Recording(doc2.get("url"), doc2.get("delay"), doc2.id);
              Map docData = doc2.data() as Map;
              if (docData.containsKey("jamsIn")) {
                recording.jamsIn = doc2.get("jamsIn");
              }
              if (docData.containsKey("userUploadDisplayName")) {
                recording.uploaderDisplayName =
                    doc2.get("userUploadDisplayName");
              }
              if (docData.containsKey("dateUploaded")) {
                recording.uploadDate = doc2.get("dateUploaded");
              }
              if (docData.containsKey("userUploadId")) {
                recording.uploaderId = doc.get("userUploadId");
              }
              newSession.addRecording(recording);
            }
            currentSong.addSession(newSession);
            if (currentSong.sessions.length == 1) {
              setState(() {
                selectedValue = currentSong.currentSession;
              });
              refreshRecordings();
            }
          });
        } catch (exception) {}
      }
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
            items: currentSong.sessions
                .map((item) => DropdownMenuItem<Session>(
                      value: item,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "Genre: " + item.genre,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Sub Genre: " + item.subGenre,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          )
                        ],
                      ),
                    ))
                .toList(),
            buttonDecoration: BoxDecoration(
                color: Colors.lightGreen,
                //background color of dropdown button
                border: Border.all(color: Colors.black38, width: 3),
                //border of dropdown button
                borderRadius: BorderRadius.circular(20),
                //border raiuds of dropdown button
                boxShadow: const <BoxShadow>[
                  //apply shadow on Dropdown button
                  BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.57), //shadow for button
                      blurRadius: 5) //blur radius of shadow
                ]),
            value: selectedValue,
            isExpanded: true,
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
          CustomUrlAudioPlayer(recording, endSession, recording.delay);
      addItemToWatchingUrls(customUrlAudioPlayer);
    }
  }

  void openSessionAdder() {}

  void addSessionToFirebase() async {
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('songs')
        .doc(currentSong.getId())
        .collection("sessions")
        .add({
      "subGenre": subGenreController.text,
      "genre": genreController.text
    });
    Session newSession =
        Session(docRef.id, subGenreController.text, genreController.text);
    setState(() {
      watchingUrls.clear();
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

  itemRemoved(CustomUrlAudioPlayer customUrlAudioPlayer) {
    addItemToWatchingUrls(customUrlAudioPlayer);
    // recordingsToPlay.removeCustomPlayer(customUrlAudioPlayer);
  }

  void addItemToWatchingUrls(CustomUrlAudioPlayer customUrlAudioPlayer) {
    setState(() {
      watchingUrls.add(customUrlAudioPlayer);
      watchingUrls.sort((a, b) => a.path.compareTo(b.path));
    });
  }

  void incrementRecordingsUsed() {
    if (currentSong.name != "") {
      for (CustomUrlAudioPlayer player in recordingsToPlay.players) {
        player.recording.jamsIn += 1;
        // FirebaseFirestore.instance
        //     .collection("songs")
        //     .doc(currentSong.getId())
        //     .collection("sessions")
        //     .doc(currentSong.currentSession.id)
        //     .collection("recordings")
        //     .doc(player.recording.recordingId)
        //     .update({"jamsIn": FieldValue.increment(1)});
        FirebaseSongs().incrementRecordingByOne(currentSong.getId(),
            currentSong.currentSession.id, player.recording.recordingId);
        FirebaseFirestore.instance
            .collection('users')
            .doc(player.recording.uploaderId)
            .update({"jamsIn": FieldValue.increment(1)});
      }
    }
  }

  void signIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      lasiUser = LasiUser(userCredential.user!.uid, true);
    } else if (FirebaseAuth.instance.currentUser!.isAnonymous) {
      lasiUser = LasiUser(FirebaseAuth.instance.currentUser!.uid, true);
    } else {
      lasiUser = LasiUser(FirebaseAuth.instance.currentUser!.uid, false);
      getUserFollowers();
    }
  }

  void getUserFollowers() async {
    if (lasiUser.anonymous) return;
    DocumentSnapshot ds = await FirebaseFirestore.instance
        .collection("users")
        .doc(lasiUser.id)
        .get();
    if ((ds.data() as Map).containsKey("artistFollowing")) {
      lasiUser.peopleFollowing = ds.get("artistFollowing");
    }
  }

  void changeLasiUser(User user) {
    lasiUser.id = user.uid;
    lasiUser.anonymous = user.isAnonymous;
    getUserFollowers();
  }

  followArtist(String artistId, bool subscribe) async {
    final result = await Navigator.pushNamed(context, '/signIn');

    if (result != null) {
      final User user = result as User;
      changeLasiUser(user);
      if (subscribe) {
        lasiUser.addArtistToFollow(artistId);

      } else {
        lasiUser.removeArtist(artistId);
      }
      return true;
    }
    return false;
  }
}

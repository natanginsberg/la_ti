import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:la_ti/model/lasi_user.dart';
import 'package:la_ti/model/original_recordings.dart';
import 'package:la_ti/model/recording.dart';
import 'package:la_ti/model/session.dart';
import 'package:la_ti/model/song.dart';
import 'package:la_ti/model/suggestions.dart';
import 'package:la_ti/ui/main_screen/camera_widget.dart';
import 'package:la_ti/ui/main_screen/recordings_queue.dart';
import 'package:la_ti/utils/firebase_access/songs.dart';
import 'package:la_ti/utils/firebase_access/users.dart';
import 'package:la_ti/utils/wasabi_uploader.dart';
import 'package:universal_html/html.dart' as html;

import '../../utils/main_screen/custom_url_audio_player.dart';
import '../../utils/main_screen/recording_to_play.dart';
import 'jammin_session.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  List<CustomUrlAudioPlayer> watchingUrls = [];

  RecordingsToPlay recordingsToPlay = RecordingsToPlay();

  List<Suggestion> suggestions = [];

  var isPlaying = false;
  Timer timer = Timer(const Duration(hours: 30), () {});

  TextEditingController newSongController = TextEditingController();

  String currentSongName = "";
  String currentSongArtist = "";
  String currentSessionDoc = "";

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

  late LasiUser lasiUser = LasiUser("", true);

  bool userInitialized = false;

  String uploadError = "";

  bool uploading = false;

  bool startingNewSong = false;

  _MainScreenState();

  Duration songLength = const Duration(seconds: 0);
  int updateCounter = 0;

  int trackNumber = 0;

  List<CameraDescription> cameras = [];

  CameraController? controller;
  FlutterSoundRecorder soundRecorder = FlutterSoundRecorder();
  XFile? imageFile;
  late html.File videoFile;

  // VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;

  TextEditingController songNameController = TextEditingController();

  // Wakelock.toggle(enable: isPlaying);

  @override
  Future<void> dispose() async {
    if (controller != null) {
      controller!.dispose();
      controller = null;
    }
    searchController.dispose();
    artistController.dispose();
    songNameController.dispose();
    subGenreController.dispose();
    genreController.dispose();
    soundRecorder.closeRecorder();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    signIn();
    getOriginalUrlsToShowUser();
    // initializeDateFormatting();
    // getCameras();
  }

  void backButton() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            TextButton(
                onPressed: () {
                  returnToStart();
                },
                child: const Text(
                  "La-Si",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )),
            const Text(
              "beta",
              style: TextStyle(fontSize: 10),
            ),
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
            const SizedBox(
              width: 80,
            ),
            Text(uploadError, style: const TextStyle(color: Colors.red)),
            const Expanded(
              child: SizedBox(
                width: 10,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/signIn');
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
            if (userInitialized && !lasiUser.anonymous)
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
      body: MaterialApp(
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
      )),
    );
  }

  checkIfFollowing(CustomUrlAudioPlayer item) {
    if (!lasiUser.anonymous) {
      if (lasiUser.isUserFollowingArtist(item.recording.uploaderId)) {
        item.recording.userIsFollowing = true;
      } else {
        item.recording.userIsFollowing = false;
      }
    }
  }

  pauseAudio() async {
    setState(() {
      isPlaying = false;
    });

    recordingsToPlay.pauseVideo();
  }

  stopVideoRecording(bool videoRecorded) async {
    if (videoRecorded) {
      vFile = await controller!.stopVideoRecording();
    } else {
      String? path = await soundRecorder.stopRecorder();
      await soundRecorder.closeRecorder();
      vFile = XFile(path!);
    }
    Recording recording =
        Recording(vFile.path, recordingsToPlay.delay, "", videoRecorded);
    CustomUrlAudioPlayer customUrlAudioPlayer =
        CustomUrlAudioPlayer(recording, endSession, recordingsToPlay.delay);
    // addItemToWatchingUrls(customUrlAudioPlayer);
    recordingsToPlay.setRecording(customUrlAudioPlayer);
    // customUrlAudioPlayer.initialize();
  }

  void endSession() async {
    // timer.cancel();
    // setState(() {
    //   isPlaying = false;
    //   songStarted = false;
    // });
    // if (recordVideo) await stopVideoRecording(recordVideo);
    // recordingsToPlay.stopVideos();
    // recordingsToPlay.resetRecordings();
    // setState(() {
    //   addUrlText = "לפני פתיחה";
    // });
  }

  Future<bool> uploadRecordingToWasabi(bool withVideo) async {
    // making sure the user played on a different recording if there was one there
    final result = await Navigator.pushNamed(context, '/signIn');
    if (result != null) {
      final User user = result as User;
      changeLasiUser(user);
      if (currentSong.name != "" &&
          recordingsToPlay.isPlayersEmpty() &&
          watchingUrls.isNotEmpty) {
        showErrorDialog(
            "You can only upload your recording inside a song with a pre-existing"
            " recording, sorry.");
        return false;
      }
      if (uploading) {
        showErrorDialog('Only one file can be uploaded at a time, sorry.');
        return false;
      } else if (currentSong.name == "") {
        await showAddSongSnackBar().then((value) async {
          if (value == null) {
            return false;
          } else if (value == "Yes") {
            String? value = await getValueOfSongAdderDialog();
            // await openSongAdderDialog().then((value) async {
            if (value == null) {
              return false;
            } else if (value != "Yes") {
              showErrorDialog("Adding song Failed, sorry.");
              return false;
            }
            // });
          } else {
            return false;
          }
        });
      }

      uploadToWasabi(vFile.openRead(), recordingsToPlay.delay, user, withVideo);
      Recording recording = Recording(
          vFile.path,
          recordingsToPlay.delay,
          "",
          withVideo,
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
          user.displayName!);
      recording.local = true;
      CustomUrlAudioPlayer customUrlAudioPlayer =
          CustomUrlAudioPlayer(recording, endSession, recordingsToPlay.delay);
      setState(() {
        watchingUrls.add(customUrlAudioPlayer);
      });
      return true;
    }
    return false;
  }

  Future<String> uploadToWasabi(
      Stream<Uint8List> fileStream, int delay, User user, bool withVideo,
      [bool mp4File = false]) async {
    setState(() {
      uploading = true;
    });
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd–kk:mm').format(now);
    String fileName = formattedDate + user.uid;
    if (!withVideo) {
      fileName += "AUDIO_ONLY";
    }
    if (kDebugMode) {
      fileName += "test";
    }
    if (mp4File) {
      fileName += '.mp4';
    } else {
      fileName += ".webm";
    }
    String url = await SongDatabase().uploadToWasabi(fileStream, fileName);
    await addUrlToFirebase(url, delay, user);
    setState(() {
      uploading = false;
    });
    showSuccessSnackBar('File uploaded successfully');
    return url;
  }

  void getOriginalUrlsToShowUser() async {
    await FirebaseFirestore.instance
        .collection('urls')
        .get()
        .then((QuerySnapshot querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        OriginalRecordings recording = OriginalRecordings(
            doc.get("url"),
            doc.get("delay"),
            doc.get("recordingId"),
            !(doc.get("url") as String).contains("AUDIO_ONLY"));
        Map docData = doc.data() as Map;
        if (kDebugMode) {
          print(docData);
        }
        // these are for later on when we have more data
        if (docData.containsKey("jamsIn")) recording.jamsIn = doc.get("jamsIn");
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
        // these are for the original songs
        if (docData.containsKey("sessionId")) {
          recording.sessionId = doc.get("sessionId");
        }
        if (docData.containsKey("songId")) {
          recording.songId = doc.get("songId");
        }
        CustomUrlAudioPlayer customUrlAudioPlayer =
            CustomUrlAudioPlayer(recording, endSession, doc.get("delay"));
        addItemToWatchingUrls(customUrlAudioPlayer);
        // }
      }
    });
  }

  Future<void> addUrlToFirebase(String value, int delay, User user) async {
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
    if (currentSong.name != "") {
      // add document to songs
      await FirebaseSongs().addRecordingToSong(currentSong, recordingData);
      // add doc to user for user docs
      await FirebaseUsers()
          .addRecordingToUser(currentSong, value, formattedDate, user);
      // update the amount of recordings the user has uploaded
      await FirebaseUsers().incrementUploads(user);
    }
  }

  pickAndUploadFiles() async {
    if (uploading) {
      showErrorDialog('Only one file can be uploaded at a time, sorry.');
    }
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
        String path = await uploadToWasabi(Stream.fromFuture(fileStream), 0,
            user, true, true); //result.files.first.name.endsWith("mp4") || );
        // adding the uploaded file to playing options
        Recording recording = Recording(path, 0, "");
        recording.local = true;
        CustomUrlAudioPlayer customUrlAudioPlayer =
            CustomUrlAudioPlayer(recording, endSession, 0);
        setState(() {
          watchingUrls.add(customUrlAudioPlayer);
        });
      }
    }
  }

  playSide() {
    Widget widget = CameraWidget(controller, cameraInitialized: initialized);

    return JammingSession(
        cameraWidget: widget,
        recordingsToPlay: recordingsToPlay,
        soundRecorder: soundRecorder,
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
          const Positioned(
            top: 280,
            left: 14,
            child: Text(
              "Recordings:",
              style: TextStyle(
                  letterSpacing: 1.4,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Container(
              margin: const EdgeInsets.only(top: 280.0),
              child: RecordingsQueue(
                watchingUrls: watchingUrls,
                lasiUser: lasiUser,
                recordingTapped: recordingTapped,
              )
              // _buildMenuList()
              ),
          // if (currentSong.sessions.isNotEmpty) buildSessionDropdown(),
          if (currentSong.sessions.isNotEmpty) addSongButton(),
          // if (addSessionToCurrentSong) currentSessionAdder(),
          searchBar(),
          //scrollOptionIndicator()
          // if (focusOnSearch)
        ],
      ),
    );
  }

  scrollOptionIndicator() {
    return const Positioned(
        bottom: 10,
        left: 10,
        right: 10,
        child: Icon(
          Icons.arrow_downward,
          color: Colors.white,
        ));
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
            const Text(
              "To find a song search for it here.\n"
              "If the song does not exist you have an option to add it.\n"
              "Clicking on the bar will show available songs.\n",
              style: TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
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
                      hintText: "Search for song",
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
    // if (addSession) {
    //   return sessionAdder();
    // }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(
          height: 20,
          child: Text("Add Song To La-Si"),
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
                onPressed: () async {
                  bool songAdded = await continueWithAddingSong();
                  if (songAdded) {
                    String id =
                        songNameController.text + " " + artistController.text;
                    await getSongFromFirebase(id);
                    resetControllers();
                  }
                },
                child: const Text(
                  "Add", // "Continue",
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
                                    String id = suggestion.songName +
                                        " " +
                                        suggestion.songArtist;
                                    getSongFromFirebase(id);
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

  Future<bool> continueWithAddingSong() async {
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
          return false;
        }
        if (currentSuggestions.indexWhere(
                (element) => element.songName == songNameController.text) >
            -1) {
          setState(() {
            errorMessage = ALREADY_EXISTS_ERROR;
          });
          return false;
        }
      }
      setState(() {
        errorMessage = "";
        // addSession = true;
      });
      bool songAdded = await addSongToFirebase();
      if (songAdded) {
        showSuccessSnackBar("Song added successfully.");
      } else {
        showErrorDialog("Adding song failed.");
      }
      return songAdded;
    }
    return false;
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

  // checkSessionAndUpdate() async {
  //   if (inputCorrect(true)) {
  //     if (addSessionToCurrentSong) {
  //       addSessionToFirebase();
  //     } else {
  //       addSongToFirebase();
  //     }
  //   }
  // }

  Future<bool> addSongToFirebase() async {
    try {
      Map<String, String> songToAdd = {
        "songName": songNameController.text,
        "songArtist": artistController.text
      };

      await FirebaseFirestore.instance
          .collection('allSongsData')
          .add(songToAdd);
      String id = songNameController.text + " " + artistController.text;
      await FirebaseFirestore.instance
          .collection('songs')
          .doc(id)
          .set(songToAdd);
      await FirebaseFirestore.instance
          .collection('songs')
          .doc(id)
          .collection("sessions")
          .add({
        "subGenre": "original", //subGenreController.text,
        "genre": "original", //genreController.text
      });
      setState(() {
        addSessionToCurrentSong = false;
        addSession = false;
        focusOnBottom = false;
        focusOnSearch = false;
        errorMessage = "";
      });
      return true;
    } catch (exception) {
      return false;
    }
  }

  void resetControllers() {
    artistController.text = "";
    subGenreController.text = "";
    genreController.text = "";
    songNameController.text = "";
  }

  getSongFromFirebase(String id, [String defaultSessionId = ""]) async {
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance.collection('songs').doc(id).get();
    currentSong = Song(
        name: documentSnapshot.get("songName") as String,
        artist: documentSnapshot.get("songArtist") as String);
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('songs')
        .doc(id)
        .collection("sessions")
        .get();
    for (var doc in querySnapshot.docs) {
      Session newSession =
          Session(doc.id, doc.get("subGenre"), doc.get("genre"));
      try {
        await FirebaseFirestore.instance
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
              recording.uploaderDisplayName = doc2.get("userUploadDisplayName");
            }
            if (docData.containsKey("dateUploaded")) {
              recording.uploadDate = doc2.get("dateUploaded");
            }
            if (docData.containsKey("userUploadId")) {
              recording.uploaderId = doc2.get("userUploadId");
            }
            newSession.addRecording(recording);
          }
          currentSong.addSession(newSession);
          if ((currentSong.sessions.length == 1 && defaultSessionId == "") ||
              newSession.id == defaultSessionId) {
            currentSong.currentSession = newSession;
            setState(() {
              selectedValue = currentSong.currentSession;
            });
            refreshRecordings();
          }
        });
      } catch (exception) {}
    }
  }

  addSongButton() {
    return Positioned(
        height: 35,
        top: 225,
        left: (MediaQuery.of(context).size.width / 3 -
                    MediaQuery.of(context).size.width / 4.2) /
                2 -
            10,
        right: (MediaQuery.of(context).size.width / 3 -
                    MediaQuery.of(context).size.width / 4.2) /
                2 -
            10,
        child: uploading
            ? const ListTile(
                tileColor: Colors.blueAccent,
                title: Text(
                  "Loading, this may take a few minutes",
                  style: TextStyle(color: Colors.white),
                ),
                trailing: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : TextButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue)),
                onPressed: pickAndUploadFiles,
                child: Text(
                  uploadPercent == 0
                      ? "Add Recording From Desktop"
                      : uploadPercent.toString() + " %",
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

  // void addSessionToFirebase() async {
  //   DocumentReference docRef = await FirebaseFirestore.instance
  //       .collection('songs')
  //       .doc(currentSong.getId())
  //       .collection("sessions")
  //       .add({
  //     "subGenre": subGenreController.text,
  //     "genre": genreController.text
  //   });
  //   Session newSession =
  //       Session(docRef.id, subGenreController.text, genreController.text);
  //   setState(() {
  //     watchingUrls.clear();
  //     currentSong.addSession(newSession);
  //     currentSong.currentSession = newSession;
  //     selectedValue = newSession;
  //     addSessionToCurrentSong = false;
  //     addSession = false;
  //     focusOnBottom = false;
  //     focusOnSearch = false;
  //     errorMessage = "";
  //     resetControllers();
  //   });
  // }

  // currentSessionAdder() {
  //   return Positioned(
  //     top: 255,
  //     left: (MediaQuery.of(context).size.width / 3 -
  //                 MediaQuery.of(context).size.width / 4) /
  //             2 -
  //         10,
  //     right: (MediaQuery.of(context).size.width / 3 -
  //                 MediaQuery.of(context).size.width / 4) /
  //             2 -
  //         10,
  //     child: Container(
  //         height: 200,
  //         width: MediaQuery.of(context).size.width / 4,
  //         decoration: BoxDecoration(
  //             border: Border.all(color: Colors.green, width: 2),
  //             borderRadius: const BorderRadius.only(
  //                 bottomRight: Radius.circular(10.0),
  //                 bottomLeft: Radius.circular(10.0)),
  //             color: Colors.white),
  //         child: Stack(children: [
  //           sessionAdder(),
  //           IconButton(
  //               onPressed: () => setState(() {
  //                     addSessionToCurrentSong = false;
  //                     errorMessage = "";
  //                     resetControllers();
  //                   }),
  //               icon: const Icon(
  //                 Icons.close,
  //                 color: Colors.black,
  //               ))
  //         ])),
  //   );
  // }

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
      for (CustomUrlAudioPlayer? player in recordingsToPlay.players) {
        if (player != null && !player.recording.local) {
          player.recording.jamsIn += 1;
          FirebaseSongs().incrementRecordingByOne(currentSong.getId(),
              currentSong.currentSession.id, player.recording.recordingId);
          FirebaseFirestore.instance
              .collection('users')
              .doc(player.recording.uploaderId)
              .update({"jamsIn": FieldValue.increment(1)});
        }
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
    setState(() {
      userInitialized = true;
    });
  }

  void getUserFollowers() async {
    if (lasiUser.anonymous) return;
    DocumentSnapshot ds = await FirebaseFirestore.instance
        .collection("users")
        .doc(lasiUser.id)
        .get();
    if ((ds.data() as Map).containsKey("artistFollowing")) {
      lasiUser.artistsFollowing = ds.get("artistFollowing");
    }
  }

  void changeLasiUser(User user) {
    lasiUser.id = user.uid;
    lasiUser.anonymous = user.isAnonymous;
    getUserFollowers();
  }

  followArtist(String artistId, bool currentlyFollowing) async {
    final result = await Navigator.pushNamed(context, '/signIn');

    if (result != null) {
      final User user = result as User;
      changeLasiUser(user);
      if (currentlyFollowing) {
        lasiUser.removeArtist(artistId);
      } else {
        lasiUser.addArtistToFollow(artistId);
      }
      FirebaseUsers()
          .updateFollowingList(lasiUser.id, lasiUser.artistsFollowing);
      return true;
    }
    return false;
  }

  initialized(CameraController? cameraController) {
    setState(() {
      controller = cameraController;
    });
  }

  void showErrorDialog(String errorText) {
    SnackBar snackBar = SnackBar(
      backgroundColor: Colors.redAccent,
      content: Text(
        errorText,
      ),
      duration: const Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showSuccessSnackBar(String successString) {
    SnackBar snackBar = SnackBar(
      backgroundColor: Colors.blueAccent,
      content: Text(
        successString,
      ),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void startNewSongWithVideo(CustomUrlAudioPlayer item) async {
    if (startingNewSong) {
      return;
    }
    startingNewSong = true;
    await getSongFromFirebase((item.recording as OriginalRecordings).songId,
        (item.recording as OriginalRecordings).sessionId);
    CustomUrlAudioPlayer clickedPlayer = watchingUrls.firstWhere((element) =>
        element.recording.recordingId == item.recording.recordingId);
    checkIfFollowing(clickedPlayer);
    bool songAdded = await recordingsToPlay.addCustomPlayer(clickedPlayer);
    if (songAdded) {
      watchingUrls.remove(clickedPlayer);
      setState(() {});
    }
    startingNewSong = false;
  }

  recordingTapped(CustomUrlAudioPlayer recordingTapped) async {
    if (currentSong.name == "") {
      startNewSongWithVideo(recordingTapped);
    } else {
      checkIfFollowing(recordingTapped);
      bool songAdded = await recordingsToPlay.addCustomPlayer(recordingTapped);
      if (songAdded) {
        watchingUrls.remove(recordingTapped);
        setState(() {});
      }
    }
  }

  Future<String?> showAddSongSnackBar() {
    return showDialog<String>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Song Picked'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const <Widget>[
                  Text('You can only upload your recording into a song.'),
                  Text('Would you like to add a song?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop("Yes");
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
        });
  }

  Future<String?> openSongAdderDialog([String dialogErrorMessage = ""]) {
    return showDialog<String>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            child: SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                width: min(MediaQuery.of(context).size.width / 4, 340),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(
                      height: 20,
                      child: Text("Add Song To La-Si"),
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
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.green)),
                            onPressed: () async {
                              bool songAdded = await continueWithAddingSong();
                              if (songAdded) {
                                String id = songNameController.text +
                                    " " +
                                    artistController.text;
                                await getSongFromFirebase(id);
                                resetControllers();
                                Navigator.of(context).pop("Yes");
                              } else {
                                Navigator.of(context).pop("Error");
                              }
                            },
                            child: const Text(
                              "Add", // "Continue",
                              style: TextStyle(color: Colors.white),
                            )),
                        TextButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.red)),
                            onPressed: () {
                              setState(() {
                                Navigator.of(context).pop();
                                resetControllers();
                              });
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white),
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (dialogErrorMessage != "")
                      Center(
                        child: Text(
                          dialogErrorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                  ],
                )),
          );
        });
  }

  Future<String?> getValueOfSongAdderDialog([String displayError = ""]) async {
    String? value = await openSongAdderDialog(displayError);
    if (value != null && value == "Error") {
      return getValueOfSongAdderDialog(errorMessage);
    } else {
      errorMessage = "";
      return value;
    }
  }

  void returnToStart() {
    currentSong = Song(name: "", artist: "");
    watchingUrls.clear();
    recordingsToPlay.removeAllPayers();
    getOriginalUrlsToShowUser();
  }
}

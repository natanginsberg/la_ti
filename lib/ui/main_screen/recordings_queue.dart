import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:la_ti/model/lasi_user.dart';
import 'package:la_ti/utils/main_screen/custom_url_audio_player.dart';

class RecordingsQueue extends StatefulWidget {
  List<CustomUrlAudioPlayer> watchingUrls;
  LasiUser lasiUser;
  Function(CustomUrlAudioPlayer) recordingTapped;
  BuildContext topTreeContext;

  RecordingsQueue(
      {Key? key,
      required this.watchingUrls,
      required this.lasiUser,
      required this.recordingTapped,
      required this.topTreeContext})
      : super(key: key);

  @override
  State<RecordingsQueue> createState() => _RecordingsQueueState();
}

class _RecordingsQueueState extends State<RecordingsQueue> {
  bool amIHovering = false;

  bool betaTesting = false;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.watchingUrls.length,
      itemBuilder: (context, index) {
        if (index > -1) {
          final item = widget.watchingUrls[index];
          return _buildMenuItem(
            item: item,
          );
        } else {
          return Container(
            color: Colors.deepOrange,
          );
        }
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.width / 5 - 100,
                    child: item.getController()),
                Column(
                  children: [
                    Directionality(
                      textDirection: Directionality.of(widget.topTreeContext),
                      child: Text(
                        AppLocalizations.of(widget.topTreeContext)!
                            .instrument(item.recording.instrument),
                        // "Part of " + item.recording.jamsIn.toString() + " jams",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Directionality(
                      textDirection: Directionality.of(widget.topTreeContext),
                      child: Text(
                        AppLocalizations.of(widget.topTreeContext)!
                            .jamsPartOf(item.recording.jamsIn),
                        // "Part of " + item.recording.jamsIn.toString() + " jams",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Directionality(
                      textDirection: Directionality.of(widget.topTreeContext),
                      child: Text(
                        AppLocalizations.of(widget.topTreeContext)!
                            .dateUploaded(item.recording.uploadDate),
                        // "Uploaded on " + item.recording.uploadDate,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Directionality(
                      textDirection: Directionality.of(widget.topTreeContext),
                      child: Text(
                        AppLocalizations.of(widget.topTreeContext)!
                            .uploadedBy(item.recording.uploaderDisplayName),
                        // "By " + item.recording.uploaderDisplayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                )
              ],
            ),
            GestureDetector(
              onTap: () async {
                widget.recordingTapped(item);
                // if (currentSong.name == "") {
                //   startNewSongWithVideo(item);
                // } else {
                //   checkIfFollowing(item);
                //   bool songAdded = await recordingsToPlay.addCustomPlayer(item);
                //   if (songAdded) {
                //     widget.watchingUrls.remove(item);
                //     setState(() {});
                //   }
                // }
              },
              child: Container(
                width: MediaQuery.of(context).size.width / 2 - 50,
                color: Colors.transparent,
                // child: Center(child: VideoPlayer(item.getController())),
              ),
            ),
            if (!betaTesting)
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

  checkIfFollowing(CustomUrlAudioPlayer item) {
    if (!widget.lasiUser.anonymous) {
      if (widget.lasiUser.isUserFollowingArtist(item.recording.uploaderId)) {
        item.recording.userIsFollowing = true;
      } else {
        item.recording.userIsFollowing = false;
      }
    }
  }
}

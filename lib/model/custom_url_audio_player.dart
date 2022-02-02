import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_js/video_js.dart';
import 'package:video_player/video_player.dart';

class CustomUrlAudioPlayer {
  AudioPlayer audioPlayer = AudioPlayer();
  late String path;
  late VideoPlayerController _controller;
  late VideoJsController _videoJsController;
  bool playPressed = false;

  // final VoidCallback songEnded;

  CustomUrlAudioPlayer(String url, VoidCallback songEnded) {
    _videoJsController = VideoJsController("videoId",
        videoJsOptions: VideoJsOptions(
            controls: true,
            loop: false,
            muted: false,
            poster:
                'https://file-examples-com.github.io/uploads/2017/10/file_example_JPG_100kB.jpg',
            aspectRatio: '16:9',
            fluid: false,
            language: 'en',
            liveui: false,
            notSupportedMessage: 'this movie type not supported',
            playbackRates: [1, 2, 3],
            preferFullWindow: false,
            responsive: false,
            sources: [Source(url, "video/mp4")],
            suppressNotSupportedError: false));

    // audioPlayer.setUrl(url);
    path = url;
    _controller = VideoPlayerController.network(url);

    _controller.addListener(() {
      checkVideo(songEnded);
    });
  }

  void checkVideo(VoidCallback songEnded) {
    // Implement your calls inside these conditions' bodies :
    if (_controller.value.position ==
        Duration(seconds: 1, minutes: 0, hours: 0)) {}

    if (_controller.value.position >=
        _controller.value.duration - Duration(seconds: 1)) {
      songEnded;
    }
  }

  initialize() async {
    // await _controller.initialize();
  }

  play() async {
    _videoJsController.play();
    // await _controller.play();
    // await audioPlayer.resume();
  }

  stop() async {
    _videoJsController.pause();
    // await _controller.pause();
    // await audioPlayer.stop();
  }

  pause() async {
    // await audioPlayer.pause();
    await _controller.pause();
  }

  removeAudioPlayer() async {
    // await audioPlayer.release();
    // await audioPlayer.dispose();
    if (_controller.value.isPlaying) await _controller.pause();
    await _controller.dispose();
  }

  seek(Duration time) async {
    await _controller.seekTo(time);
    // await audioPlayer.seek(time);
  }

  Future<Duration?> getCurrentPosition() async {
    // return _controller.position;
    return Future(() => Duration(seconds: 0));
    // return audioPlayer.getCurrentPosition();
  }

  VideoPlayerController getController() {
    return _controller;
  }

  getDuration() async {
    return _controller.value.duration;
  }

  void resetVideo() async {
    await _controller.pause();
    await _controller.seekTo(const Duration(seconds: 0));
  }
}

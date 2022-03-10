import 'dart:html' as html;

class Monitor {
  // FlutterSoundPlayer audio = FlutterSoundPlayer();

  var audio = html.AudioElement();
  bool on = true;

  initMonitor() async {
    var constraints = {
      'audio': {
        'echoCancellation': true,
        'echoCancellationType': {'ideal': " system "},
        'channelCount': 1,
        'sampleRate': {'ideal': 'AUDIO_SAMPLE_RATE'},
        'noiseSuppression': false,
        'autoGainControl': true,
        'googEchoCancellation': true,
        'googAutoGainControl': true,
        'googExperimentalAutoGainControl': true,
        'googNoiseSuppression': false,
        'googExperimentalNoiseSuppression': false,
        'googHighpassFilter': true,
        'googTypingNoiseDetection': true,
        'googBeamforming': false,
        'googArrayGeometry': false,
        'googAudioMirroring': true,
        'googNoiseReduction': false,
        'mozNoiseSuppression': false,
        'mozAutoGainControl': false,
        'latency': 0.01,
      },
      'video': false,
    };
    html.window.navigator.mediaDevices!
        .getUserMedia(constraints)
        .then((stream) async {
      // MediaStream098 stream = await navigator.mediaDevices.getUserMedia({
      //   'audio': true,
      // });
      //
      audio
        ..autoplay = false
        ..preload = "auto"
        ..srcObject = stream;
      // html.document.body?.append(audio);
      audio.play();
      // });
      // audio.play();
    });
  }

  stopMonitor() {
    dispose();
    on = false;
  }

  startMonitor() {
    initMonitor();
    on = true;
  }

  isOn() {
    return on;
  }

  change() {
    if (on) {
      stopMonitor();
    } else {
      startMonitor();
    }
  }

  void dispose() {
    print("disposed");
    audio.pause();
    audio.removeAttribute('srcObject'); // empty source
    audio.load();
  }
}

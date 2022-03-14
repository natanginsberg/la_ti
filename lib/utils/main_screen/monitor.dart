import 'dart:html' as html;

class Monitor {
  // FlutterSoundPlayer audio = FlutterSoundPlayer();

  var audio = html.AudioElement();
  bool on = false;

  initMonitor([bool play = false]) async {
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
      // });
      if (play) {
        audio.play();
      }});
  }

  stopMonitor() {
    dispose();
    on = false;
  }

  startMonitor() {
    initMonitor(true);
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
    audio.pause();
    audio.removeAttribute('srcObject'); // empty source
    audio.load();
  }
}

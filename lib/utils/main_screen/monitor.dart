import 'dart:html' as html;

class Monitor {
  var audio = html.AudioElement();
  bool on = true;

  initMonitor() {
    html.window.navigator.getUserMedia(audio: true).then((stream) {
      audio
        ..autoplay = false
        ..srcObject = stream;
      // document.body.append(audio);
    });
    audio.play();
  }

  stopMonitor() {
    audio.pause();
    on = false;
  }

  startMonitor() {
    audio.play();
    on = true;
    // audio.currentTime = 0;
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

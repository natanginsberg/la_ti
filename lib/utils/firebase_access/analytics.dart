import 'package:firebase_analytics/firebase_analytics.dart';

class Analytics {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  playAnalytics(bool recordAudio, bool recordVideo) async {
    if (recordAudio && recordVideo) {
      await analytics.logEvent(name: 'video_and_audio_recording');
    } else if (recordVideo) {
      await analytics.logEvent(name: 'video_recording_only');
    } else if (recordAudio) {
      await analytics.logEvent(name: 'audio_recording_only');
    } else {
      await analytics.logEvent(name: "play_only");
    }
  }

  uploadNotContinued() async {
    await analytics.logEvent(name: 'uploaded_aborted');
  }

  uploadFollowedThrough() async {
    await analytics.logEvent(name: 'uploaded_followed_through');
  }
}

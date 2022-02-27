import 'session.dart';

class Song {
  List<Session> sessions = [];
  late Session currentSession;

  Song({required this.name, required this.artist});

  String artist;
  String name;

  void addSession(Session session) {
    sessions.add(session);
  }

  String getId() {
    return name + " " + artist;
  }
}

import 'dart:core';

class Suggestion {
  String songArtist;
  String songName;

  Suggestion(this.songName, this.songArtist);

  String getSuggestionName() {
    return (songArtist + " by " + songName);
  }

  contains(String searchedValue) {
    return songName.toLowerCase().contains(searchedValue.toLowerCase()) ||
        songArtist.toLowerCase().contains(searchedValue.toLowerCase());
  }
}

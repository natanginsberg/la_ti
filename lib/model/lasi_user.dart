class LasiUser {
  String userName = '';
  String id = '';
  List<String> artistsFollowing = [];
  bool anonymous;

  LasiUser(this.id, this.anonymous);

  addArtistToFollow(String artistId) {
    artistsFollowing.add(artistId);
  }

  isUserFollowingArtist(String artistId) {
    return artistsFollowing.contains(artistId);
  }

  void removeArtist(String artistId) {
    artistsFollowing.remove(artistId);
  }
}

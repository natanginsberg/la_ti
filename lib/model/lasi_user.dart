class LasiUser {
  String userName = '';
  String id = '';
  List<String> peopleFollowing = [];
  bool anonymous;

  LasiUser(this.id, this.anonymous);

  addArtistToFollow(String artistId) {
    peopleFollowing.add(artistId);
  }

  isUserFollowingArtist(String artistId) {
    return peopleFollowing.contains(artistId);
  }

  void removeArtist(String artistId) {
    peopleFollowing.remove(artistId);
  }
}

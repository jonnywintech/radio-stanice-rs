class RadioStation {
  const RadioStation(this.name, this.searchQueries, {this.coverUrl});

  final String name;
  final List<String> searchQueries;
  final String? coverUrl;
}

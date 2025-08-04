class ExploreItem {
  final int id;
  final String title;
  final String author;
  final String authorAvatar;
  final int likes;
  final int views;
  final List<String> tags;
  final String image;
  final bool trending;

  const ExploreItem({
    required this.id,
    required this.title,
    required this.author,
    required this.authorAvatar,
    required this.likes,
    required this.views,
    required this.tags,
    required this.image,
    required this.trending,
  });
}

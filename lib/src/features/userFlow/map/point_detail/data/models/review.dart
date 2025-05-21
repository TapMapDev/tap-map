class Review {
  final String author;
  final DateTime date;
  final int rating;
  final String label;
  final String text;
  final int likes;
  final int dislikes;

  Review({
    required this.author,
    required this.date,
    required this.rating,
    required this.label,
    required this.text,
    this.likes = 0,
    this.dislikes = 0,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    author: j['author'],
    date: DateTime.parse(j['date']),
    rating: j['rating'],
    label: j['label'],
    text: j['text'],
    likes: j['likes'] ?? 0,
    dislikes: j['dislikes'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'author': author,
    'date': date.toIso8601String(),
    'rating': rating,
    'label': label,
    'text': text,
    'likes': likes,
    'dislikes': dislikes,
  };
}

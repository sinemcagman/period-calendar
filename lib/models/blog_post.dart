class BlogPost {
  final int? id;
  final String title;
  final String category;
  final int readTime;
  final String imageUrl;
  final String content;

  BlogPost({
    this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.imageUrl,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'read_time': readTime,
      'image_url': imageUrl,
      'content': content,
    };
  }

  factory BlogPost.fromMap(Map<String, dynamic> map) {
    return BlogPost(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      readTime: map['read_time'],
      imageUrl: map['image_url'],
      content: map['content'],
    );
  }
}

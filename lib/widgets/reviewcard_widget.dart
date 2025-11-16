import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final String username;
  final String userAvatar;
  final double rating;
  final String reviewText;
  final String timeAgo;
  const ReviewCard({
    super.key,
    required this.username,
    required this.userAvatar,
    required this.rating,
    required this.reviewText,
    required this.timeAgo,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        userAvatar.startsWith('http') ||
                            userAvatar.startsWith('https')
                        ? NetworkImage(userAvatar) as ImageProvider
                        : AssetImage(userAvatar),
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    color: index < rating ? Colors.amber : Colors.grey[300],
                    size: 18,
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reviewText,
                      style: TextStyle(color: Colors.grey[800], fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  if (reviewText.length > 50)
                    Text(
                      "Read more",
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

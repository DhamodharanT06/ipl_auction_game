import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PlayerImage extends StatelessWidget {
  const PlayerImage({
    super.key,
    required this.url,
    this.size = 72,
  });

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: Icon(Icons.person, size: size * 0.45),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          child: Icon(Icons.person, size: size * 0.45),
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// CircularImage represents an image rounded by a circular border
class CircularImage extends StatelessWidget {
  const CircularImage({required this.imageUrl, required this.size, super.key});
  final String imageUrl;
  final double size;

  static const _flutterLogo = CircleAvatar(
      foregroundImage: AssetImage('assets/images/flutter_logo.png'));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(size)),
        border: Border.all(
          color: Colors.lightBlueAccent,
          width: size < 100.0 ? 2.0 : 4.0,
        ),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          fit: BoxFit.fill,
          imageUrl: imageUrl,
          width: size,
          height: size,
          placeholder: (context, url) => _flutterLogo,
          errorWidget: (context, url, error) => _flutterLogo,
        ),
      ),
    );
  }
}

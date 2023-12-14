import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pub/common/assets.dart';

class PubAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PubAppBar({super.key, this.bottom});

  final Widget? bottom;
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: SvgPicture.asset(
        Assets.logo,
        height: 30,
      ),
      backgroundColor: const Color(0xFF1B2834),
      bottom: bottom == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: bottom!,
            ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(bottom != null ? 130 : kToolbarHeight);
}

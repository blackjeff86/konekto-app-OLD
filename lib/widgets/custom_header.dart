// lib/widgets/custom_header.dart

import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final double titleFontSize;
  final String headerTitleType;
  final String logoPath;
  final Widget? leading;
  final Widget? trailing;
  final AppThemeData appColors;

  const CustomHeader({
    super.key,
    required this.title,
    required this.appColors,
    this.titleFontSize = 24.0,
    this.headerTitleType = 'text',
    this.logoPath = '',
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Widget titleWidget = headerTitleType == 'image' && logoPath.isNotEmpty
        ? Image.asset(
            logoPath,
            height: titleFontSize,
          )
        : Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: appColors.primaryText, // CORREÇÃO: Usa a cor de texto principal
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                ),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 48,
            child: leading ?? const SizedBox.shrink(),
          ),
          Expanded(
            child: titleWidget,
          ),
          SizedBox(
            width: 48,
            child: trailing ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
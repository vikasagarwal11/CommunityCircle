import 'package:flutter/material.dart';
import '../core/constants.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= AppConstants.tabletBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

class AdaptivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AdaptivePadding({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultPadding = AppConstants.isSmallScreen(screenWidth)
        ? AppConstants.smallPadding
        : AppConstants.defaultPadding;

    return Padding(
      padding: padding ?? EdgeInsets.all(defaultPadding),
      child: child,
    );
  }
}

class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    
    double fontSize = AppConstants.mediumFontSize;
    if (AppConstants.isSmallScreen(screenWidth)) {
      fontSize = AppConstants.smallFontSize;
    } else if (AppConstants.isLargeScreen(screenWidth)) {
      fontSize = AppConstants.largeFontSize;
    }

    return Text(
      text,
      style: baseStyle?.copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool? isPrimary;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = AppConstants.isSmallScreen(screenWidth);
    
    final buttonStyle = style ?? ElevatedButton.styleFrom(
      backgroundColor: isPrimary == true 
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      foregroundColor: isPrimary == true 
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurface,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 16,
        vertical: isSmall ? 8 : 12,
      ),
      minimumSize: Size(
        isSmall ? 80 : 100,
        isSmall ? 36 : 44,
      ),
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}

class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? color;
  final ShapeBorder? shape;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.color,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = AppConstants.isSmallScreen(screenWidth);
    
    return Card(
      margin: margin ?? EdgeInsets.all(isSmall ? 4 : 8),
      elevation: elevation ?? AppConstants.cardElevation,
      color: color,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          isSmall ? AppConstants.borderRadius - 2 : AppConstants.borderRadius,
        ),
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
} 
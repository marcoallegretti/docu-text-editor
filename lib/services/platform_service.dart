import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';


enum DeviceType {
  mobile,
  tablet,
  desktop
}

class PlatformService {
  static DeviceType? _cachedDeviceType;
  static bool? _isDesktopPlatform;

  /// Determine if the current platform is desktop (Windows, macOS, Linux)
  static bool isDesktopPlatform() {
    if (_isDesktopPlatform != null) {
      return _isDesktopPlatform!;
    }
    
    if (kIsWeb) {
      // For web, consider it desktop if the screen is large enough
      _isDesktopPlatform = true;
      return true;
    }
    
    _isDesktopPlatform = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    return _isDesktopPlatform!;
  }

  /// Determine if the current platform supports mouse input
  static bool supportsMouseInput() {
    return isDesktopPlatform();
  }

  /// Determine if the platform supports keyboard shortcuts
  static bool supportsKeyboardShortcuts() {
    return isDesktopPlatform();
  }

  /// Detect device type based on screen size
  static DeviceType getDeviceType(BuildContext context) {
    if (_cachedDeviceType != null) {
      return _cachedDeviceType!;
    }

    // Desktop platforms
    if (isDesktopPlatform()) {
      _cachedDeviceType = DeviceType.desktop;
      return DeviceType.desktop;
    }

    // Use screen size for mobile/tablet detection
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    if (shortestSide < 600) {
      _cachedDeviceType = DeviceType.mobile;
    } else {
      _cachedDeviceType = DeviceType.tablet;
    }

    return _cachedDeviceType!;
  }

  /// Returns true if the device is a tablet or larger
  static bool isLargeScreen(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.tablet || deviceType == DeviceType.desktop;
  }

  /// Returns true if the device is a mobile phone
  static bool isMobileScreen(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  /// Returns the platform-specific padding based on device type
  static EdgeInsets getPlatformPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(12.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(20.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(24.0);
    }
  }
  
  /// Returns appropriate font size multiplier based on device type
  static double getFontSizeMultiplier(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 0.9;
      case DeviceType.tablet:
        return 1.0;
      case DeviceType.desktop:
        return 1.1;
    }
  }
  
  /// Gets the device orientation type
  static bool isLandscape(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }
  
  /// Checks if it's running on a mobile device
  static bool isMobileDevice() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  /// Returns a platform-specific duration for animations
  static Duration getAnimationDuration() {
    if (isDesktopPlatform()) {
      return const Duration(milliseconds: 200); // Faster on desktop
    } else {
      return const Duration(milliseconds: 300); // Slower on mobile
    }
  }
  
  /// Adapt sizing based on form factor
  static double adaptiveSize(BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return small;
      case DeviceType.tablet:
        return medium;
      case DeviceType.desktop:
        return large;
    }
  }
  
  /// Returns a SafeArea with appropriate padding for each platform
  static Widget getPlatformSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    if (isDesktopPlatform()) {
      // On desktop, we don't need as much padding
      return Padding(
        padding: EdgeInsets.only(
          top: top ? 8.0 : 0.0,
          bottom: bottom ? 8.0 : 0.0,
          left: left ? 8.0 : 0.0,
          right: right ? 8.0 : 0.0,
        ),
        child: child,
      );
    } else {
      // On mobile, use SafeArea
      return SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: child,
      );
    }
  }
}
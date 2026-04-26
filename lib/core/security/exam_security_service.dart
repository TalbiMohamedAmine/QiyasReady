import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';

/// Service for managing exam security features:
/// - Screenshot/screen recording prevention
class ExamSecurityService {
  ExamSecurityService._();

  static final ExamSecurityService instance = ExamSecurityService._();

  bool _isProtectionActive = false;

  /// Enable screenshot and screen recording protection.
  /// On mobile, this uses native platform APIs.
  Future<bool> enableProtection() async {
    if (_isProtectionActive) return true;

    try {
      if (kIsWeb) {
        await BrowserContextMenu.disableContextMenu();
        _isProtectionActive = true;
        return true;
      }

      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();

      _isProtectionActive = true;

      debugPrint('ExamSecurityService: Screen protection enabled');
      return true;
    } catch (e) {
      debugPrint('ExamSecurityService: Failed to enable protection - $e');
      // Continue without protection - watermark will serve as fallback
      return false;
    }
  }

  /// Disable screenshot and screen recording protection.
  /// Call this when leaving exam screens.
  Future<void> disableProtection() async {
    if (!_isProtectionActive) return;

    try {
      if (kIsWeb) {
        await BrowserContextMenu.enableContextMenu();
        _isProtectionActive = false;
        return;
      }

      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      _isProtectionActive = false;

      debugPrint('ExamSecurityService: Screen protection disabled');
    } catch (e) {
      debugPrint('ExamSecurityService: Failed to disable protection - $e');
    }
  }

  /// Check if protection is currently active
  bool get isProtectionActive => _isProtectionActive;
}

/// Widget that wraps content with text selection disabled
/// Used to prevent copy/paste of exam content
class SecureContentWrapper extends StatelessWidget {
  const SecureContentWrapper({
    super.key,
    required this.child,
    this.disableSelection = true,
  });

  final Widget child;
  final bool disableSelection;

  @override
  Widget build(BuildContext context) {
    if (!disableSelection) return child;

    return SelectionContainer.disabled(
      child: child,
    );
  }
}

class SecureShortcutBlocker extends StatelessWidget {
  const SecureShortcutBlocker({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyC, control: true):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.keyP, control: true):
            DoNothingAndStopPropagationIntent(),
      },
      child: child,
    );
  }
}

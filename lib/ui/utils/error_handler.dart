import 'package:flutter/material.dart';

import '../../utils/game_exceptions.dart';
import '../styles.dart';
import '../widgets/bulletin_dialog_shell.dart';

/// Centralized error handling system for consistent UI feedback
class ErrorHandler {
  /// Show a user-friendly error dialog with enhanced visual design
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
    bool canDismiss = true,
    Color? accentColor,
  }) async {
    final color = accentColor ?? ClubBlackoutTheme.neonRed;

    return showDialog<void>(
      context: context,
      barrierDismissible: canDismiss,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;

        return BulletinDialogShell(
          accent: color,
          maxWidth: 460,
          padding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              // Details (if provided)
              if (details != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cs.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (canDismiss)
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'DISMISS',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (onRetry != null) ...[
                    if (canDismiss) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRetry();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: color.withValues(alpha: 0.9),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'RETRY',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show enhanced toast notification with better visual design
  static void showToast({
    required BuildContext context,
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);
    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      color: cs.onInverseSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: cs.inverseSurface.withValues(alpha: 0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: color.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: color,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Handle exceptions with appropriate UI feedback
  static void handleException({
    required BuildContext context,
    required dynamic exception,
    String? title,
    VoidCallback? onRetry,
    bool showDialog = true,
  }) {
    String message;
    String? details;
    Color color;

    if (exception is GameException) {
      message = exception.message;
      details = exception.details;
      color = _getColorForGameException(exception);
    } else {
      message = 'An unexpected error occurred';
      details = exception.toString();
      color = ClubBlackoutTheme.neonRed;
    }

    if (showDialog) {
      showErrorDialog(
        context: context,
        title: title ?? _getTitleForException(exception),
        message: message,
        details: details,
        onRetry: onRetry,
        accentColor: color,
      );
    } else {
      showToast(
        context: context,
        title: title ?? _getTitleForException(exception),
        message: message,
        type: ToastType.error,
        onAction: onRetry,
        actionLabel: onRetry != null ? 'RETRY' : null,
      );
    }
  }

  /// Wrap async operations with error handling
  static Future<T?> wrapAsync<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String? errorTitle,
    bool showErrorDialog = true,
    VoidCallback? onRetry,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (context.mounted) {
        handleException(
          context: context,
          exception: e,
          title: errorTitle,
          onRetry: onRetry,
          showDialog: showErrorDialog,
        );
      }
      return null;
    }
  }

  static Color _getColorForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return ClubBlackoutTheme.neonGreen;
      case ToastType.warning:
        return ClubBlackoutTheme.neonOrange;
      case ToastType.error:
        return ClubBlackoutTheme.neonRed;
      case ToastType.info:
        return ClubBlackoutTheme.neonBlue;
    }
  }

  static IconData _getIconForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.error:
        return Icons.error_outline_rounded;
      case ToastType.info:
        return Icons.info_outline_rounded;
    }
  }

  static Color _getColorForGameException(GameException exception) {
    if (exception is PlayerNotFoundException) {
      return ClubBlackoutTheme.neonOrange;
    } else if (exception is RoleAssignmentException) {
      return ClubBlackoutTheme.neonPurple;
    } else if (exception is GameStateException) {
      return ClubBlackoutTheme.neonBlue;
    }
    return ClubBlackoutTheme.neonRed;
  }

  static String _getTitleForException(dynamic exception) {
    if (exception is PlayerNotFoundException) {
      return 'Player Not Found';
    } else if (exception is RoleAssignmentException) {
      return 'Role Assignment Error';
    } else if (exception is GameStateException) {
      return 'Game State Error';
    } else if (exception is GameException) {
      return 'Game Error';
    }
    return 'Error';
  }
}

/// Types of toast notifications
enum ToastType {
  success,
  warning,
  error,
  info,
}

/// Extension to make error handling easier from widgets
extension BuildContextErrorExtension on BuildContext {
  /// Show error dialog
  Future<void> showError({
    required String message,
    String? title,
    String? details,
    VoidCallback? onRetry,
    Color? color,
  }) {
    return ErrorHandler.showErrorDialog(
      context: this,
      title: title ?? 'Error',
      message: message,
      details: details,
      onRetry: onRetry,
      accentColor: color,
    );
  }

  /// Show success message
  void showSuccess(String message, {String? title}) {
    ErrorHandler.showToast(
      context: this,
      message: message,
      title: title,
      type: ToastType.success,
    );
  }

  /// Show warning message
  void showWarning(String message, {String? title}) {
    ErrorHandler.showToast(
      context: this,
      message: message,
      title: title,
      type: ToastType.warning,
    );
  }

  /// Show info message
  void showInfo(String message, {String? title}) {
    ErrorHandler.showToast(
      context: this,
      message: message,
      title: title,
      type: ToastType.info,
    );
  }

  /// Handle exception with UI feedback
  void handleError(dynamic exception, {String? title, VoidCallback? onRetry}) {
    ErrorHandler.handleException(
      context: this,
      exception: exception,
      title: title,
      onRetry: onRetry,
    );
  }
}

import 'package:flutter/material.dart';
import '../styles.dart';

/// Enhanced loading overlay with error handling and retry capabilities
class LoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final String? message;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final Color? accentColor;
  final Duration fadeInDuration;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    this.message,
    this.errorMessage,
    this.onRetry,
    this.onCancel,
    this.accentColor,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final color = accentColor ?? ClubBlackoutTheme.neonBlue;
    final cs = Theme.of(context).colorScheme;
    final hasError = errorMessage != null;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: fadeInDuration,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: cs.scrim.withValues(alpha: 0.8),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasError
                    ? ClubBlackoutTheme.neonRed.withValues(alpha: 0.6)
                    : color.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasError ? ClubBlackoutTheme.neonRed : color)
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading/Error icon
                if (!hasError) ...[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ClubBlackoutTheme.neonRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ClubBlackoutTheme.neonRed.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: ClubBlackoutTheme.neonRed,
                      size: 32,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Message
                Text(
                  hasError ? 'Operation Failed' : (message ?? 'Loading...'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: hasError ? ClubBlackoutTheme.neonRed : cs.onSurface,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (hasError && errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Action buttons for error state
                if (hasError) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (onCancel != null)
                        Expanded(
                          child: TextButton(
                            onPressed: onCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: cs.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      if (onRetry != null) ...[
                        if (onCancel != null) const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: onRetry,
                            style: FilledButton.styleFrom(
                              backgroundColor: ClubBlackoutTheme.neonRed
                                  .withValues(alpha: 0.9),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading state manager for widgets
class LoadingState {
  bool _isLoading = false;
  String? _message;
  String? _errorMessage;
  VoidCallback? _onRetry;
  VoidCallback? _onCancel;

  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  VoidCallback? get onRetry => _onRetry;
  VoidCallback? get onCancel => _onCancel;

  void startLoading({String? message}) {
    _isLoading = true;
    _message = message;
    _errorMessage = null;
    _onRetry = null;
    _onCancel = null;
  }

  void showError({
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    _isLoading = true; // Keep overlay visible
    _errorMessage = message;
    _onRetry = onRetry;
    _onCancel = onCancel;
  }

  void stopLoading() {
    _isLoading = false;
    _message = null;
    _errorMessage = null;
    _onRetry = null;
    _onCancel = null;
  }

  void clear() {
    stopLoading();
  }
}

/// Mixin to easily add loading state to widgets
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  final LoadingState _loadingState = LoadingState();

  LoadingState get loadingState => _loadingState;

  Widget buildWithLoading({
    required Widget child,
    Color? loadingAccentColor,
  }) {
    return Stack(
      children: [
        child,
        LoadingOverlay(
          isVisible: _loadingState.isLoading,
          message: _loadingState.message,
          errorMessage: _loadingState.errorMessage,
          onRetry: _loadingState.onRetry,
          onCancel: _loadingState.onCancel,
          accentColor: loadingAccentColor,
        ),
      ],
    );
  }

  /// Wrap async operations with loading state and error handling
  Future<R?> withLoadingAndError<R>({
    required Future<R> Function() operation,
    String? loadingMessage,
    String? errorTitle,
    bool autoRetry = true,
  }) async {
    setState(() {
      _loadingState.startLoading(message: loadingMessage);
    });

    try {
      final result = await operation();
      setState(() {
        _loadingState.stopLoading();
      });
      return result;
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState.showError(
            message: e.toString(),
            onRetry: autoRetry
                ? () => withLoadingAndError(
                      operation: operation,
                      loadingMessage: loadingMessage,
                      errorTitle: errorTitle,
                      autoRetry: autoRetry,
                    )
                : null,
            onCancel: () {
              setState(() {
                _loadingState.stopLoading();
              });
            },
          );
        });
      }
      return null;
    }
  }
}

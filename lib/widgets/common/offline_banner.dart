import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gamer_flick/services/core/network_service.dart';
import 'package:gamer_flick/theme/app_theme.dart';

/// A banner that shows when the user is offline
/// Automatically appears/disappears based on connectivity status
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _checkInitialConnectivity();
    _listenToConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final isConnected = await NetworkService().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = !isConnected);
      if (_isOffline) {
        _controller.forward();
      }
    }
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (mounted && _isOffline != isOffline) {
        setState(() => _isOffline = isOffline);
        if (_isOffline) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        SlideTransition(
          position: _slideAnimation,
          child: _OfflineBannerContent(isOffline: _isOffline),
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

class _OfflineBannerContent extends StatelessWidget {
  final bool isOffline;

  const _OfflineBannerContent({required this.isOffline});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningColor.withOpacity(0.9),
            AppTheme.warningColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'You\'re offline. Some features may be limited.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simpler inline offline indicator for specific widgets
class OfflineIndicator extends StatefulWidget {
  final Widget online;
  final Widget? offline;

  const OfflineIndicator({
    super.key,
    required this.online,
    this.offline,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenToConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await NetworkService().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = !isConnected);
    }
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (mounted && _isOffline != isOffline) {
        setState(() => _isOffline = isOffline);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline && widget.offline != null) {
      return widget.offline!;
    }
    return widget.online;
  }
}

/// Small offline chip indicator
class OfflineChip extends StatefulWidget {
  const OfflineChip({super.key});

  @override
  State<OfflineChip> createState() => _OfflineChipState();
}

class _OfflineChipState extends State<OfflineChip> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenToConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await NetworkService().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = !isConnected);
    }
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (mounted && _isOffline != isOffline) {
        setState(() => _isOffline = isOffline);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isOffline ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.warningColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 12,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

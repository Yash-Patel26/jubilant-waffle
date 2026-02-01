import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCVideoWidget extends StatefulWidget {
  final MediaStream? stream;
  final BoxFit fit;
  final bool mirror;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const WebRTCVideoWidget({
    super.key,
    required this.stream,
    this.fit = BoxFit.cover,
    this.mirror = false,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<WebRTCVideoWidget> createState() => _WebRTCVideoWidgetState();
}

class _WebRTCVideoWidgetState extends State<WebRTCVideoWidget> {
  RTCVideoRenderer? _renderer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  Future<void> _initializeRenderer() async {
    _renderer = RTCVideoRenderer();
    await _renderer!.initialize();
    setState(() {
      _isInitialized = true;
    });
    _updateStream();
  }

  void _updateStream() {
    if (_isInitialized && _renderer != null && widget.stream != null) {
      _renderer!.srcObject = widget.stream;
    }
  }

  @override
  void didUpdateWidget(WebRTCVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _updateStream();
    }
  }

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _renderer == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.stream == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: Icon(
            Icons.videocam_off_rounded,
            color: Colors.white54,
            size: 48,
          ),
        ),
      );
    }

    Widget videoWidget = RTCVideoView(
      _renderer!,
      objectFit: widget.fit == BoxFit.cover
          ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
          : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
      mirror: widget.mirror,
    );

    if (widget.borderRadius != null) {
      videoWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: videoWidget,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: videoWidget,
    );
  }
}

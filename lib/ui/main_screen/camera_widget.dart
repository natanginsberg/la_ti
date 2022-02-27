import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraWidget extends StatefulWidget {
  CameraController? controller;
  Function(CameraController?) cameraInitialized;

  CameraWidget(this.controller, {required this.cameraInitialized});

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
    with WidgetsBindingObserver {
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  bool cameraReady = false;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  // Wakelock.toggle(enable: isPlaying);

  @override
  Future<void> dispose() async {
    if (widget.controller != null) {
      widget.controller!.dispose();
    }
    cameraReady = false;
    super.dispose();
  }

  @override
  void initState() {
    getCameras();
    super.initState();
  }

  void getCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      var cameras = await availableCameras();
      widget.controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      widget.controller!.initialize().then((value) {
        setState(() {
          cameraReady = true;
        });
        // print("camera initialized ");
        print(widget.controller.toString());
        widget.cameraInitialized(widget.controller);
      });
    } on CameraException catch (e) {
      // logError(e.code, e.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _cameraPreviewWidget();
  }

  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = widget.controller;
    // print(cameras);
    if (cameraController == null ||
        !cameraController.value.isInitialized ||
        cameraReady == false) {
      return const CircularProgressIndicator();
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          widget.controller!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              // onTapDown: (details) => onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (widget.controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await widget.controller!.setZoomLevel(_currentScale);
  }
}

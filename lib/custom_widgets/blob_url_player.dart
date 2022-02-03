import 'dart:html';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ignore: camel_case_types
// class blobUrlPlayer extends StatefulWidget {
//   final String source;
//
//   const blobUrlPlayer({required Key key, required this.source})
//       : super(key: key);
//
//   play(){}
//
//   @override
//   _blobUrlPlayerState createState() => _blobUrlPlayerState();
// }
//
// // ignore: camel_case_types
// class _blobUrlPlayerState extends State<blobUrlPlayer> {
//   // Widget _iframeWidget;
//   final videoElement = VideoElement();
//
//   @override
//   void initState() {
//     super.initState();
//     videoElement
//       ..src = widget.source
//       ..autoplay = false
//       ..controls = false
//       ..style.border = 'none'
//       ..style.height = '100%'
//       ..style.width = '100%';
//
//     // Allows Safari iOS to play the video inline
//     videoElement.setAttribute('playsinline', 'true');
//
//     // Set autoplay to false since most browsers won't autoplay a video unless it is muted
//     videoElement.setAttribute('autoplay', 'false');
//
//     //ignore: undefined_prefixed_name
//     ui.platformViewRegistry
//         .registerViewFactory(widget.source, (int viewId) => videoElement);
//     videoElement.pause();
//   }
//
//   play() {
//     videoElement.play();
//   }
//
//   pause() {
//     videoElement.pause();
//   }
//
//   getCurrentPosition() {
//     videoElement.currentTime;
//   }
//
//   getSongLength() {
//     videoElement.duration;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return HtmlElementView(
//       key: UniqueKey(),
//       viewType: widget.source,
//     );
//   }
// }

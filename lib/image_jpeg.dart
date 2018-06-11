import 'dart:async';

import 'package:flutter/services.dart';

class ImageJpeg {
  static const MethodChannel _channel = const MethodChannel('image_jpeg');


  static Future<String> encodeJpeg(String srcPath, String targetPath, int quality, int maxWidth, int maxHeight) async {
    final Map<String, dynamic> params = <String, dynamic> {
      'srcPath': srcPath,
      'targetPath': targetPath,
      'quality': quality,  // 0~100
      'maxWidth': maxWidth, // default 5000
      'maxHeight': maxHeight  // default 5000
    };
    final String result = await _channel.invokeMethod('encodeJpeg', params);
    return result;
  }

}

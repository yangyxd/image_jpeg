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

  static Future<ImageInfo> getInfo(String imageFile) async {
    Object map = await _channel.invokeMethod("getImgInfo", <String, dynamic> {
      'imageFile': imageFile,
    });
    if (map != null && map is Map) {
      return new ImageInfo(width: map['width'] ?? 0,
        height: map['height'] ?? 0,
        size: map['size'] ?? 0,
        lastModified: map['lastModified'] ?? 0,
        error: map['error'],
      );
    }
    return null;
  }

}

/// 图像信息
class ImageInfo {
  final int width;
  final int height;
  final int size;
  final int lastModified;
  final String error;
  const ImageInfo({this.width, this.height, this.size, this.lastModified, this.error});
}

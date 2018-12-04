import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';

class ImageJpeg {
  static const MethodChannel _channel = const MethodChannel('image_jpeg');

  /// encode JPEG
  static Future<String> encodeJpeg(String srcPath, String targetPath, int quality, int maxWidth, int maxHeight, [int rotate = 0, int blur = 0, int blurZoom = 0]) async {
    final Map<String, dynamic> params = <String, dynamic> {
      'srcPath': srcPath,
      'targetPath': targetPath,
      'quality': quality,  // 0~100
      'maxWidth': maxWidth, // default 5000
      'maxHeight': maxHeight,  // default 5000
      'rotate': rotate,
      'blur': blur,
      'blurZoom' : blurZoom,
    };
    final String result = await _channel.invokeMethod('encodeJpeg', params);
    return result;
  }

  /// encode Buffer JPEG
  static Future<List<int>> encodeJpegWithBuffer(List<int> image, int quality, int maxWidth, int maxHeight, [int rotate = 0, int blur = 0, int blurZoom = 0]) async {
    final result = await _channel.invokeMethod('encodeJpegWithBuffer', [
      Uint8List.fromList(image),
      quality,
      maxWidth,
      maxHeight,
      rotate,
      blur,
      blurZoom
    ]);
    if (result == null) return null;
    return convertDynamic(result);
  }

  /// encode Buffer JPEG with Res
  static Future<List<int>> encodeImageWithRes(String resName, int quality, [String resType = '', int maxWidth = 0, int maxHeight = 0, int rotate = 0, int blur = 0, int blurZoom = 0]) async {
    final result = await _channel.invokeMethod('encodeImageWithRes', [
      resName,
      quality,
      maxWidth,
      maxHeight,
      rotate,
      blur,
      blurZoom,
      resType,
    ]);
    if (result == null) return null;
    return convertDynamic(result);
  }

  /// blur image
  static Future<List<int>> blurImage(List<int> image, int blur, [int blurZoom = 0, int rotate = 0, int quality = 90]) async {
    return encodeJpegWithBuffer(image, quality, 0, 0, rotate, blur, blurZoom);
  }

  /// blur image File
  static Future<List<int>> blurImageWithFlie(String imageFile, int blur, [int blurZoom = 0, int rotate = 0, int quality = 90]) async {
    File f = new File(imageFile);
    if (!f.existsSync())
      return null;
    return blurImage(f.readAsBytesSync(), blur, blurZoom, rotate, quality);
  }

  /// load res file
  static Future<List<int>> loadResFile(String resName, [String resType]) async {
    final result = await _channel.invokeMethod("loadResFile", [resName, resType]);
    return convertDynamic(result);
  }

  // get image info
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

  // get Resources image info
  static Future<ImageInfo> getResImageInfo(String resName, [String resType = '']) async {
    Object map = await _channel.invokeMethod("getResImgInfo", <String, dynamic> {
      'resName': resName,
      'resType': resType,
    });
    if (map != null && map is Map) {
      return new ImageInfo(width: map['width'] ?? 0,
        height: map['height'] ?? 0,
        size: map['size'] ?? 0,
        resId: map['resId'] ?? 0,
        error: map['error'],
      );
    }
    return null;
  }

  /// convert [List<dynamic>] to [List<int>]
  static List<int> convertDynamic(List<dynamic> list) {
    return list.where((item) => item is int).map((item) => item as int).toList();
  }

  /// convert List<int> to Uint8List
  static Uint8List convertToUint8List(List<int> list) {
    return Uint8List.fromList(list);
  }
}

/// 图像信息
class ImageInfo {
  final int width;
  final int height;
  final int size;
  final int resId;
  final int lastModified;
  final String error;
  const ImageInfo({this.width, this.height, this.size, this.resId, this.lastModified, this.error});
  @override
  String toString() {
    return "{width: $width, heigh: $height, size: $size, resId: $resId, error: $error}";
  }
}

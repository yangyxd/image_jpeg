import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_jpeg/image_jpeg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: new Center(
          child: InkWell(
            child: Text('选择图片'),
            onTap: () {
              _selectImage();
            },
          ),
        ),
      ),
    );
  }

  _selectImage() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile == null) {
      print("null");
      return;
    }

    String newfile = null;
    //print("newfile: " + newfile);
    print("srcfile: " + imageFile.path);
    newfile = await ImageJpeg.encodeJpeg(imageFile.path, newfile, 70, 1920, 1920);
    if (newfile == null || newfile.isEmpty) {
      print("无效的图像文件");
    } else {
      File f = new File(newfile);
      print("newfile: " + newfile);
      print("原文件大小: ${getRollupSize(imageFile.lengthSync())}, 新文件大小: ${getRollupSize(f.lengthSync())}");
    }
  }


  static const RollupSize_Units = ["GB", "MB", "KB", "B"];
  /// 返回文件大小字符串
  static String getRollupSize(int size) {
    int idx = 3;
    int r1 = 0;
    String result = "";
    while (idx >= 0) {
      int s1 = size % 1024;
      size = size >> 10;
      if (size == 0 || idx == 0) {
        r1 = (r1 * 100) ~/ 1024;
        if (r1 > 0) {
          if (r1 >= 10)
            result = "$s1.$r1${RollupSize_Units[idx]}";
          else
            result = "$s1.0$r1${RollupSize_Units[idx]}";
        } else
          result = s1.toString() + RollupSize_Units[idx];
        break;
      }
      r1 = s1;
      idx--;
    }
    return result;
  }
}

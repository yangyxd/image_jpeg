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
  String _hintMsg = '';
  String _newfile;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 16.0),
              RaisedButton(onPressed: () {
                _selectImage();
              }, child: Text('选择图片')),
              SizedBox(height: 8.0),
              Text("$_hintMsg", style: TextStyle(
                color: Colors.black,
                fontSize: 11.0,
                fontWeight: FontWeight.w300,
                shadows: [
                  Shadow(blurRadius: 4.0),
                ]
              )),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  child: _newfile == null ? null : Image.file(
                    File(_newfile),
                  ),
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black12,
                        width: 0.5,
                      )
                  ),
                ),
              )
            ],
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
    var t = new DateTime.now().millisecondsSinceEpoch;
    newfile = await ImageJpeg.encodeJpeg(imageFile.path, newfile, 65, 1360, 1360);
    var t2 = new DateTime.now().millisecondsSinceEpoch;
    if (newfile == null || newfile.isEmpty) {
      updateMsg("无效的图像文件");
    } else {
      _newfile = newfile;
      var sv = await ImageJpeg.getInfo(imageFile.path);
      var nv = await ImageJpeg.getInfo(newfile);
      if (sv != null) {
        updateMsg("newfile: " + newfile);
        updateMsg("用时: ${t2 - t}ms \n原文件: ${getRollupSize(sv.size)}, ${sv.width}*${sv.height} \n新文件: ${getRollupSize(nv.size)}, ${nv.width}*${nv.height} \n压缩率: ${(nv.size / sv.size * 100).toStringAsFixed(2)}%");
      } else
        updateMsg("获取文件信息失败");
      //f.delete();
    }
  }

  void updateMsg(final String msg) {
    print(msg);
    setState(() {
      _hintMsg = msg;
    });
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

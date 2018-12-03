import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_jpeg/image_jpeg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zoomable_image/zoomable_image.dart';
import 'dart:io';


void main() => runApp(new MaterialApp(
  home: MyApp(),
));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _hintMsg = '';
  String _newfile;
  bool _roate = false;
  bool _blur = false;
  Uint8List imgbuffer;
  double blurValue = 1.0;
  double blurZomm = 1.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var image = imgbuffer != null && !imgbuffer.isEmpty ? MemoryImage(imgbuffer) :
      _newfile == null ? null : FileImageEx(File(_newfile));

    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: new Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 8.0),
              Row(
                children: <Widget>[
                  SizedBox(width: 16.0),
                  RaisedButton(onPressed: () {
                    _selectImage();
                  }, child: Text('压缩图片')),
                  Checkbox(value: _roate, onChanged: (v) {
                   setState(() {
                     _roate = v;
                   });
                  }),
                  Text('旋转'),
                  SizedBox(width: 8.0),
                  Checkbox(value: _blur, onChanged: (v) {
                    setState(() {
                      _blur = v;
                    });
                  }),
                  Text('高斯模糊'),
                ],
              ),
              Row(
                children: <Widget>[
                  SizedBox(width: 16.0),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      RaisedButton(onPressed: () {
                        _blurImage();
                      }, child: Text('模糊图片')),
                      RaisedButton(onPressed: () {
                        _encodeResImage();
                      }, child: Text('资源图片')),
                      RaisedButton(onPressed: () {
                        _loadResImage();
                      }, child: Text('加载资源')),
                    ],
                  ),
                  SizedBox(width: 8.0),
                  Column(
                    children: <Widget>[
                      Slider(
                        value: blurValue,
                        onChanged: (v) {
                          setState(() {
                            blurValue = v;
                          });
                        },
                      ),
                      Slider(
                        value: blurZomm,
                        onChanged: (v) {
                          setState(() {
                            blurZomm = v;
                          });
                        },
                      ),
                      Text("$_hintMsg", style: TextStyle(
                          color: Colors.black,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w300,
                          shadows: [
                            Shadow(blurRadius: 4.0),
                          ]
                      ))
                    ],
                  ),
                  SizedBox(width: 4.0),
                ],
              ),
              SizedBox(height: 0.0),
              Expanded(
                child: GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.all(2.0),
                    width: double.infinity,
                    child: image == null ? null : Image(image: image),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black12,
                          width: 0.5,
                        )
                    ),
                  ),
                  onTap: imgbuffer == null && _newfile == null ? null : () {
                    _openNewPage(image);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openNewPage(ImageProvider image) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
          return new Scaffold(
            body: ZoomableImage(
                image,
                placeholder: const Center(child: const CircularProgressIndicator()),
                backgroundColor: Colors.black,
                onTap: () {
                  Navigator.pop(context);
                },
            ),
          );
        },
    ));
  }

  _deleteLastFile(String newfile) {
    if (_newfile != null && _newfile != newfile) {
      File f = new File(_newfile);
      f.delete();
    }
    _newfile = newfile;
  }

  _selectImage() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile == null) {
      print("null");
      return;
    }

    print("srcfile: " + imageFile.path);
    var t = new DateTime.now().millisecondsSinceEpoch;
    String newfile = await ImageJpeg.encodeJpeg(imageFile.path, null, 65, 1360, 1360, _roate ? 90 : 0,
        _blur ? (blurValue * 100).toInt() : 0, (blurZomm * 10).toInt());
    var t2 = new DateTime.now().millisecondsSinceEpoch;
    if (newfile == null || newfile.isEmpty) {
      updateMsg("无效的图像文件");
    } else {
      _deleteLastFile(newfile);
      imgbuffer = null;
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

  _blurImage() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    print("srcfile: " + imageFile.path);
    var t = new DateTime.now().millisecondsSinceEpoch;
    List<int> data = await ImageJpeg.blurImageWithFlie(imageFile.path, (blurValue * 100).toInt(), (blurZomm * 10).toInt(), _roate ? 100 : 0);
    var t2 = new DateTime.now().millisecondsSinceEpoch;
    if (data == null || data.isEmpty) {
      updateMsg("无效的图像文件");
    } else {
      _deleteLastFile(null);
      imgbuffer = ImageJpeg.convertToUint8List(data);
      var sv = await ImageJpeg.getInfo(imageFile.path);
      if (sv != null)
        updateMsg("用时: ${t2 - t}ms \n图像大小: ${getRollupSize(sv.size)}, ${sv.width}*${sv.height} \n输出大小: ${getRollupSize(data == null ? 0 : data.length)}");
      else
        updateMsg("获取文件信息失败");
    }
  }

  _encodeResImage() async {
      var t = new DateTime.now().millisecondsSinceEpoch;
      List<int> data = await ImageJpeg.encodeImageWithRes("test", 70, 'drawable', 1000, 1000, _roate ? 90 : 0,
          _blur ? (blurValue * 100).toInt() : 0, (blurZomm * 10).toInt());
      var t2 = new DateTime.now().millisecondsSinceEpoch;
      if (data == null || data.isEmpty) {
        updateMsg("无效的图像文件");
      } else {
        _deleteLastFile(null);
        imgbuffer = ImageJpeg.convertToUint8List(data);
        var sv = await ImageJpeg.getResImageInfo("test", "drawable");
        if (sv != null)
          updateMsg("用时: ${t2 - t}ms \n资源ID: ${sv.resId} \n图像大小: ${getRollupSize(sv.size)}, ${sv.width}*${sv.height} \n输出大小: ${getRollupSize(data == null ? 0 : data.length)}");
        else
          updateMsg("获取文件信息失败");
      }
  }

  _loadResImage() async {
    var t = new DateTime.now().millisecondsSinceEpoch;
    List<int> data = await ImageJpeg.loadResFile("ic_launcher");
    var t2 = new DateTime.now().millisecondsSinceEpoch;
    if (data == null || data.isEmpty) {
      updateMsg("无效的图像文件");
    } else {
      _deleteLastFile(null);
      imgbuffer = ImageJpeg.convertToUint8List(data);
      var sv = await ImageJpeg.getResImageInfo("ic_launcher");
      if (sv != null)
        updateMsg("用时: ${t2 - t}ms \n资源ID: ${sv.resId} \n图像大小: ${getRollupSize(sv.size)}, ${sv.width}*${sv.height} \n输出大小: ${getRollupSize(data == null ? 0 : data.length)}");
      else
        updateMsg("获取文件信息失败");
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

class FileImageEx extends FileImage {
  int fileSize = 0;
  FileImageEx(File file, { double scale = 1.0 })
      : assert(file != null),
        assert(scale != null),
        super(file, scale: scale) {
    if (file.existsSync())
      fileSize = file.lengthSync();
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final FileImageEx typedOther = other;
    return file?.path == typedOther.file?.path
        && scale == typedOther.scale && fileSize == typedOther.fileSize;
  }
}
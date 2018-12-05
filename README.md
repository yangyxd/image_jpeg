# image_jpeg

[![pub package](https://img.shields.io/pub/v/image_jpeg.svg)](https://pub.dartlang.org/packages/image_jpeg)
![GitHub](https://img.shields.io/github/license/yangyxd/image_jpeg.svg)
[![GitHub stars](https://img.shields.io/github/stars/yangyxd/image_jpeg.svg?style=social&label=Stars)](https://github.com/yangyxd/image_jpeg)

Flutter plug-in for image compression JPEG upload supports image blurring, rotation processing, and loading resource files and memory images (bytes).

## Usage
To use this plugin, add `image_jpeg` as a dependency in your `pubspec.yaml` file.

## ROADMAP

* [x] Compressed to JPEG
* [x] Image Zoom
* [x] Image Rotate
* [x] Get image information (width, height, fileSize, lastModified)
* [x] Gaussian Blur
* [x] Loading resource images

> Supported  Platforms
> * Android
> * IOS

## Examples

  * [Examples App](https://github.com/yangyxd/image_jpeg/tree/master/example) - Demonstrates how to use the image_jpeg plugin.

```dart
import 'package:image_jpeg/image_jpeg.dart';

// 调用 encodeJpeg ，返回输出的文件名
String newfileName = await ImageJpeg.encodeJpeg(imageFile.path, newfile, 70, JpgImageWidth, JpgImageHeigh);

// 调用encodeImageWithRes从资源文件中加载并处理，返回bytes
List<int> data = await ImageJpeg.encodeImageWithRes(resName, 70, 'drawable', 1000, 1000,  0, 10, 4);

// 加载资源文件（可以不是图像）
List<int> data = await ImageJpeg.loadResFile(resName);

// 高斯模糊
List<int> data = await ImageJpeg.blurImageWithFlie(imageFile.path, 10, 4, 0);

// 获取资源文件信息
var sv = await ImageJpeg.getResImageInfo(resName);

// 获取文件信息
var sv = await ImageJpeg.getInfo(imageFile.path);

```

## License MIT

Copyright (c) 2018 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

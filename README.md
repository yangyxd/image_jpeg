# image_jpeg

Flutter plugin image encode jpeg.


## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).

> Supported  Platforms
> * Android
> * IOS

## How to Use

```yaml
# add this line to your dependencies
image_jpeg:
  git: https://github.com/yangyxd/image_jpeg
```

```dart
import 'package:image_jpeg/image_jpeg.dart';


// 检查图片大小，如果过大则压缩
        File imageFile = new File('xxx');
        int filesize = imageFile.lengthSync();
        try {
          if (filesize > 1024 * 256) {
            // 大于256kb开始压缩
            cancelWait = false;

            // scale image
            String newfile = await Tools.getDocumentsPath() + Tools.pathSeparator + tempfilename;
            newfile = await ImageJpeg.encodeJpeg(imageFile.path, newfile, 70, JpgImageWidth, JpgImageHeigh);
            if (Tools.strIsEmpty(newfile)) {
              print("无效的图像文件");
            } else {
              File f = new File(newfile);
              print("原文件大小: ${Tools.getRollupSize(imageFile.lengthSync())}, 新文件大小: ${Tools.getRollupSize(f.lengthSync())}");              
            }

            return;
          }
        } catch (e) {
          print("无效的图像文件");
          return;
        }

```

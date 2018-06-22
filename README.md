# image_jpeg

Flutter plugin image encode jpeg.

The compression and zoom plug-in before the image is uploaded. Use native code for processing.

> Supported  Platforms
> * Android
> * IOS

## How to Use

```yaml
# add this line to your dependencies
image_jpeg:
  git: git://github.com/yangyxd/image_jpeg.git
```

```dart
import 'package:image_jpeg/image_jpeg.dart';

// 调用 encodeJpeg ，返回输出的文件名
String newfileName = await ImageJpeg.encodeJpeg(imageFile.path, newfile, 70, JpgImageWidth, JpgImageHeigh);

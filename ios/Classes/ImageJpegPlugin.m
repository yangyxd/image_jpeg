#import "ImageJpegPlugin.h"

@implementation ImageJpegPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"image_jpeg"
            binaryMessenger:[registrar messenger]];
  ImageJpegPlugin* instance = [[ImageJpegPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"encodeJpeg" isEqualToString:call.method]) {
    NSString *srcPath = call.arguments[@"srcPath"];
    NSString *targetPath = call.arguments[@"targetPath"];
    NSString *squality = call.arguments[@"quality"];
    NSString *smaxWidth = call.arguments[@"maxWidth"];
    NSString *smaxHeight = call.arguments[@"maxHeight"];

    int mw = 0;
    int mh = 0;
    int quality = 70;
    @try{
        quality = [squality intValue];
        mw = [smaxWidth intValue];
        mh = [smaxHeight intValue];
    } @catch(NSException *e){
        mw = 0;
        mh = 0;
        quality = 70;
    }

    if(mw < 1 ) mw = 5000;
    if(mh < 1 ) mh = 5000;
    if (quality < 0) quality = 0;
    if (quality > 100) quality = 100;

    if (targetPath == nil || targetPath == NULL || [targetPath isKindOfClass:[NSNull class]]) {
        targetPath = [srcPath  stringByAppendingString: @".jpg"];
    }

    UIImage *image = [UIImage imageWithContentsOfFile:srcPath]; // init image

    NSNumber *nmw = [NSNumber numberWithInt:mw];
    NSNumber *nmh = [NSNumber numberWithInt:mh];
    image = [self scaledImage:image maxWidth:nmw maxHeight:nmh];

    CGFloat compression = quality / 100;
    NSData *data = UIImageJPEGRepresentation(image, compression);

    if ([[NSFileManager defaultManager] createFileAtPath:targetPath contents:data attributes:nil]) {
        result(targetPath);
    } else {
        result([FlutterError errorWithCode:@"Encode Jpeg Failed"
                                message:@"Temporary file could not be created"
                                details:nil]);
    }
  } else if ([@"getImgInfo" isEqualToString:call.method]) {
      NSString *srcPath = call.arguments[@"imageFile"];
      [self getImgInfo:result fileName:srcPath];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (UIImage *)scaledImage:(UIImage *)image
                maxWidth:(NSNumber *)maxWidth
               maxHeight:(NSNumber *)maxHeight {
  double originalWidth = image.size.width;
  double originalHeight = image.size.height;

  bool hasMaxWidth = maxWidth != (id)[NSNull null];
  bool hasMaxHeight = maxHeight != (id)[NSNull null];

  double width = hasMaxWidth ? MIN([maxWidth doubleValue], originalWidth) : originalWidth;
  double height = hasMaxHeight ? MIN([maxHeight doubleValue], originalHeight) : originalHeight;

  bool shouldDownscaleWidth = hasMaxWidth && [maxWidth doubleValue] < originalWidth;
  bool shouldDownscaleHeight = hasMaxHeight && [maxHeight doubleValue] < originalHeight;
  bool shouldDownscale = shouldDownscaleWidth || shouldDownscaleHeight;

  if (shouldDownscale) {
    double downscaledWidth = (height / originalHeight) * originalWidth;
    double downscaledHeight = (width / originalWidth) * originalHeight;

    if (width < height) {
      if (!hasMaxWidth) {
        width = downscaledWidth;
      } else {
        height = downscaledHeight;
      }
    } else if (height < width) {
      if (!hasMaxHeight) {
        height = downscaledHeight;
      } else {
        width = downscaledWidth;
      }
    } else {
      if (originalWidth < originalHeight) {
        width = downscaledWidth;
      } else if (originalHeight < originalWidth) {
        height = downscaledHeight;
      }
    }
  }

  UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
  [image drawInRect:CGRectMake(0, 0, width, height)];

  UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return scaledImage;
}

- (void) getImgInfo:(FlutterResult)callback
    fileName: (NSString *) fileName {

    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isFile = [manager fileExistsAtPath:fileName isDirectory:&isDir];

    if (!isDir) {
        if (!isFile) {
            callback(@{
                    @"file": fileName,
                    @"error": @("file doesn't exist or is not a file")
                });
        } else {
            UIImage *image = [UIImage imageWithContentsOfFile:fileName];

            callback(@{
                @"file": fileName,
                @"width": @((int) image.size.width),
                @"height": @((int)image.size.height),
                @"size": @([manager attributesOfItemAtPath:fileName error:nil].fileSize)
            });
        }
    } else {
        callback(@{
            @"file": fileName,
            @"error": @("file doesn't exist or is not a file")
        });
    }
}

@end

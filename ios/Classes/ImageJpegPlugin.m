#import <Flutter/Flutter.h>
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
    NSString *srotate = call.arguments[@"rotate"];
    NSString *sblur = call.arguments[@"blur"];
    NSString *sblurZoom = call.arguments[@"blurZoom"];

    int mw = 0;
    int mh = 0;
    int quality = 70;
    int rotate = 0;
    int blur = 0;
    int blurZoom = 0;

    @try{
        quality = [squality intValue];
        mw = [smaxWidth intValue];
        mh = [smaxHeight intValue];
        rotate = [srotate intValue];
        blur = [sblur intValue];
        blurZoom = [sblurZoom intValue];
    } @catch(NSException *e){ }

    if (targetPath == nil || targetPath == NULL || [targetPath isKindOfClass:[NSNull class]]) {
        targetPath = [srcPath  stringByAppendingString: @".jpg"];
    }

    UIImage *image = [UIImage imageWithContentsOfFile:srcPath]; // init image
    NSData *data = [self processImage:image
                                   mw:mw
                                   mh:mh
                               rotate:rotate
                                 blur:blur
                             blurZoom:blurZoom
                              quality:quality
    ];

    if ([[NSFileManager defaultManager] createFileAtPath:targetPath contents:data attributes:nil]) {
        result(targetPath);
    } else {
        result([FlutterError errorWithCode:@"Encode Jpeg Failed"
                                message:@"Temporary file could not be created"
                                details:nil]);
    }

  } else if ([@"encodeJpegWithBuffer" isEqualToString:call.method]) {
    NSArray *args = call.arguments;
    FlutterStandardTypedData *list = args[0];
    int quality = [args[1] intValue];
    int mw = [args[2] intValue];
    int mh = [args[3] intValue];
    int rotate = [args[4] intValue];
    int blur = [args[5] intValue];
    int blurZoom = [args[6] intValue];

    UIImage *image = [[UIImage alloc] initWithData:list.data];
    NSData *data = [self processImage:image
                           mw:mw
                           mh:mh
                       rotate:rotate
                         blur:blur
                     blurZoom:blurZoom
                      quality:quality
    ];

    NSMutableArray *array = [NSMutableArray array];
    Byte *bytes = data.bytes;
    for (int i = 0; i < data.length; ++i) {
        [array addObject:@(bytes[i])];
    }
    result(array);

  } else if ([@"encodeImageWithRes" isEqualToString:call.method]) {
    NSArray *args = call.arguments;
    NSString *resName = args[0];
    int quality = [args[1] intValue];
    int mw = [args[2] intValue];
    int mh = [args[3] intValue];
    int rotate = [args[4] intValue];
    int blur = [args[5] intValue];
    int blurZoom = [args[6] intValue];

    UIImage *image = [UIImage imageNamed:resName];

    if (image == nil || image == NULL || [image isKindOfClass:[NSNull class]]) {
        result(NULL);
    } else {
        NSData *data = [self processImage:image
                                       mw:mw
                                       mh:mh
                                   rotate:rotate
                                     blur:blur
                                 blurZoom:blurZoom
                                  quality:quality
        ];

        NSMutableArray *array = [NSMutableArray array];
        Byte *bytes = data.bytes;
        for (int i = 0; i < data.length; ++i) {
            [array addObject:@(bytes[i])];
        }
        result(array);
    }

  } else if ([@"loadResFile" isEqualToString:call.method]) {
    NSArray *args = call.arguments;
    NSString *resName = args[0];

    UIImage *image = [UIImage imageNamed:resName];
    if (image == nil || image == NULL || [image isKindOfClass:[NSNull class]]) {
        result(NULL);
    } else {
        NSData *data = UIImagePNGRepresentation(image);
        if (!data) {
            data = UIImageJPEGRepresentation(image, 0.85);
        }

        NSMutableArray *array = [NSMutableArray array];
        Byte *bytes = data.bytes;
        for (int i = 0; i < data.length; ++i) {
            [array addObject:@(bytes[i])];
        }
        result(array);
    }

  } else if ([@"getImgInfo" isEqualToString:call.method]) {
      NSString *srcPath = call.arguments[@"imageFile"];
      [self getImgInfo:result fileName:srcPath];

  } else if ([@"getResImgInfo" isEqualToString:call.method]) {
      NSString *resName = call.arguments[@"resName"];
      [self getResImgInfo:result resName:resName];

  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (NSData *)processImage:(UIImage *)image
    mw: (int) mw
    mh: (int) mh
    rotate: (int) rotate
    blur: (int) blur
    blurZoom: (int) blurZoom
    quality: (int) quality
{
    if (mw < 0) mw = 0;
    if (mh < 0) mh = 0;
    if (quality < 0) quality = 0;
    if (quality > 100) quality = 100;
    if (blur < 0) blur = 0;
    if (blur > 100) blur = 100;
    if (blurZoom < 0) blurZoom = 0;

    // 缩放
    if (mw > 0 && mh > 0) {
        NSNumber *nmw = [NSNumber numberWithInt:mw];
        NSNumber *nmh = [NSNumber numberWithInt:mh];
        image = [self scaledImage:image maxWidth:nmw maxHeight:nmh];
    }
    
    // 旋转
    if (rotate % 360 != 0){
        image = [self rotate: image rotate: rotate];
    }

    // 高斯模糊
    if (blur > 0) {
        image = [self blurImage:image blur:blur blurZoom:blurZoom];
    }

    // 压缩
    CGFloat compression = quality / 100;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    return data;
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

  return [self scaleImageWithMP: image w:width h:height];
}

- (UIImage *)rotate:(UIImage*)image
             rotate:(CGFloat) rotate {
    return [self imageRotatedByDegrees: image deg:rotate];
}

- (UIImage *)imageRotatedByDegrees:(UIImage*)oldImage deg:(CGFloat)degrees{
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,oldImage.size.width, oldImage.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degrees * M_PI / 180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;

    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();

    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

    // Rotate the image context
    CGContextRotateCTM(bitmap, (degrees * M_PI / 180));

    // draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)blurImage:(UIImage*)image blur:(CGFloat)blur blurZoom:(CGFloat)blurZoom {
    double aw = image.size.width;
    double ah = image.size.height;
    if (blurZoom > 0) {
        image = [self scaleImageWithMP:image w:(aw / blurZoom) h:(ah / blurZoom)];
    }

    blur = blur / 100.0f * 25.0f;
    if (blur > 25.0f)  blur = 25.0f;

    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];

    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    NSNumber *number = [NSNumber numberWithFloat:blur];
    [filter setValue:number forKey:@"inputRadius"];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];

    UIImage *returnImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    if (blurZoom > 0) {
        return [self scaleImageWithMP:returnImage w:aw h:ah];
    } else
        return returnImage;
}

- (UIImage *) scaleImageWithMP: (UIImage*) image  w:(CGFloat) w  h:(CGFloat) h {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, w, h)];

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

- (void) getResImgInfo:(FlutterResult)callback
    resName: (NSString *) resName {

    UIImage *image = [UIImage imageNamed:resName];

    if (image == nil || image == NULL || [image isKindOfClass:[NSNull class]]) {
        callback(@{
            @"resName": resName,
            @"error": @("resources doesn't exist")
        });
    } else {
        NSData *data = UIImagePNGRepresentation(image);
        if (!data) {
            data = UIImageJPEGRepresentation(image, 0.85);
        }
        double dataLength = [data length] * 1.0;

        callback(@{
            @"resName": resName,
            @"width": @((int) image.size.width),
            @"height": @((int)image.size.height),
            @"size": @((int) dataLength)
        });
    }
}


@end

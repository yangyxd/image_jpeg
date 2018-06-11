package com.yangyxd.imagejpeg;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import java.io.File;
import java.io.FileOutputStream;

/**
 * ImageJpegPlugin
 */
public class ImageJpegPlugin implements MethodCallHandler {
  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "image_jpeg");
    channel.setMethodCallHandler(new ImageJpegPlugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("encodeJpeg")) {
      String srcPath = call.argument("srcPath");
      String targetPath = call.argument("targetPath");
      int quality = call.argument("quality");
      int maxWidth = call.argument("maxWidth");
      int maxHeight = call.argument("maxHeight");

      if (srcPath == null || srcPath.length() == 0) {
        result.error("Filename not valid", null, null);
        return;
      }

      if (maxWidth < 1) maxWidth = 5000;
      if (maxHeight < 1) maxHeight = 5000;
      if (quality < 0) quality = 0;
      if (quality > 100) quality = 100;

      if (targetPath == null || targetPath.length() == 0)
        targetPath = srcPath + ".jpg";

      String newPath = compressImage(srcPath, targetPath, quality, maxWidth, maxHeight);
      if (newPath == null || newPath.length() == 0)
        result.error("Encode Jpeg Failed", null, null);
      else
        result.success(newPath);
    } else {
      result.notImplemented();
    }
  }

  public static String compressImage(String filePath, String targetPath, int quality, int maxWidth, int maxHeight)  {
    try {
      Bitmap bm = getSmallBitmap(filePath, maxWidth, maxHeight);
      File outputFile = new File(targetPath);

      if (!outputFile.exists()) {
        outputFile.getParentFile().mkdirs();
      } else {
        outputFile.delete();
      }
      FileOutputStream out = new FileOutputStream(outputFile);
      bm.compress(Bitmap.CompressFormat.JPEG, quality, out);

      return outputFile.getPath();
    } catch (Exception e){
      return null;
    }
  }

  public static Bitmap getSmallBitmap(String filePath, int maxWidth, int maxHeight) {
    final BitmapFactory.Options options = new BitmapFactory.Options();
    options.inJustDecodeBounds = true;
    BitmapFactory.decodeFile(filePath, options);
    options.inSampleSize = calculateInSampleSize(options, maxWidth, maxHeight);
    options.inJustDecodeBounds = false;
    return BitmapFactory.decodeFile(filePath, options);
  }

  public static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
    final int height = options.outHeight;
    final int width = options.outWidth;
    int inSampleSize = 1;
    if (height > reqHeight || width > reqWidth) {
      final int heightRatio = Math.round((float) height / (float) reqHeight);
      final int widthRatio = Math.round((float) width / (float) reqWidth);
      inSampleSize = heightRatio < widthRatio ? heightRatio : widthRatio;
    }
    return inSampleSize;
  }

}

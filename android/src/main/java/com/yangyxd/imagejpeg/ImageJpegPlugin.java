package com.yangyxd.imagejpeg;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;

/**
 * ImageJpegPlugin
 */
public class ImageJpegPlugin implements MethodCallHandler {
  private final Registrar mRegistrar;

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "image_jpeg");
    channel.setMethodCallHandler(new ImageJpegPlugin(registrar));
  }

  private ImageJpegPlugin(Registrar registrar) {
    this.mRegistrar = registrar;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("encodeJpeg")) {
      // 压缩图像
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

    } else if (call.method.equals("getImgInfo")) {
      String imageFile = call.argument("imageFile");
      this.getImgInfo(result, imageFile);
    } else {
      result.notImplemented();
    }
  }

  public String compressImage(String filePath, String targetPath, int quality, int maxWidth, int maxHeight)  {
      Log.d("image_jpeg", String.format("srcfile: %s", filePath));
      Log.d("image_jpeg", String.format("mw: %d, mh: %d, quality: %d, targetfile: %s", maxWidth, maxHeight, quality, targetPath));

      try {
        Bitmap bm = getSmallBitmap(filePath, maxWidth, maxHeight);
        Log.d("image_jpeg", String.format("nw: %d, nh: %d", bm.getWidth(), bm.getHeight()));

        File outputFile = getOutputFile(targetPath, true);

        if (outputFile == null) {
          return null;
        }
        FileOutputStream out = new FileOutputStream(outputFile);
        bm.compress(Bitmap.CompressFormat.JPEG, quality, out);

        Log.d("image_jpeg", String.format("targerSize: %d, outputfile: %s", out.getChannel().size(), outputFile.getPath()));

        out.close();

        return outputFile.getPath();

      } catch (Exception e) {
        Log.d("image_jpeg", e.getMessage());
        return null;
      }
  }

  public File getOutputFile(String afile, boolean canTry) {
    try {
      File outputFile = new File(afile);
      if (!outputFile.exists()) {
        outputFile.getParentFile().mkdirs();
      } else {
        outputFile.delete();
      }
      return  outputFile;
    } catch (Exception e) {
      if (!canTry)
        return null;
      String fileName = getFileName(afile);
      File v = null;
      try {
        v = getOutputFile(mRegistrar.context().getCacheDir().getPath() + afile, false);
        if (v != null) return v;
        v = getOutputFile(Environment.getExternalStorageDirectory().getAbsolutePath() + afile, false);
      } catch (Exception e1) {
        return null;
      }
      return v;
    }
  }

  public String getFileName(String pathandname){
    int start=pathandname.lastIndexOf("/");
    int end=pathandname.lastIndexOf(".");
    if (start!=-1 && end!=-1)
      return pathandname.substring(start+1, end);
    else
      return null;
  }

  public static Bitmap getSmallBitmap(String filePath, int maxWidth, int maxHeight) {
    final BitmapFactory.Options options = new BitmapFactory.Options();
    options.inJustDecodeBounds = true;
    BitmapFactory.decodeFile(filePath, options);
    options.inSampleSize = calculateInSampleSize(options, maxWidth, maxHeight);
    options.inJustDecodeBounds = false;
    Log.d("image_jpeg", String.format("outRatio: %d", options.inSampleSize));
    return BitmapFactory.decodeFile(filePath, options);
  }

  public static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
    final int height = options.outHeight;
    final int width = options.outWidth;
    int inSampleSize = 1;
    if (height > reqHeight || width > reqWidth) {
      final int heightRatio = Math.round((float) height / (float) reqHeight);
      final int widthRatio = Math.round((float) width / (float) reqWidth);
      inSampleSize = heightRatio > widthRatio ? heightRatio : widthRatio;
      Log.d("image_jpeg", String.format("w: %d, h: %d, wRatio: %d, hRatio: %d", width, height, widthRatio, heightRatio));
    };
    return inSampleSize;
  }

  public void getImgInfo(Result successResult, String fileName) {
    HashMap map = new HashMap();
    map.put("file", fileName);
    try {
      File f = new File(fileName);
      final BitmapFactory.Options options = new BitmapFactory.Options();
      options.inJustDecodeBounds = true;
      if (f.exists() && f.isFile()) {
        map.put("size", f.length());
        map.put("lastModified", f.lastModified());
        BitmapFactory.decodeFile(fileName, options);
        map.put("width", options.outWidth);
        map.put("height", options.outHeight);
      } else {
        map.put("error", "file doesn't exist or is not a file");
      }
      successResult.success(map);
    } catch (Exception e) {
      map.put("error", e.getMessage());
      successResult.success(map);
    }
  }

}

package com.yangyxd.imagejpeg;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.os.Build;
import android.os.Environment;
import android.renderscript.Allocation;
import android.renderscript.Element;
import android.renderscript.RenderScript;
import android.renderscript.ScriptIntrinsicBlur;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.List;

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
    String method = call.method;

    if ("encodeJpeg".equals(method)) {
      // 压缩图像
      String srcPath = call.argument("srcPath");
      String targetPath = call.argument("targetPath");
      int quality = call.argument("quality");
      int maxWidth = call.argument("maxWidth");
      int maxHeight = call.argument("maxHeight");
      int rotate = call.argument("rotate");
      int blur = call.argument("blur");
      int blurZoom = call.argument("blurZoom");

      if (srcPath == null || srcPath.length() == 0) {
        result.error("Filename not valid", null, null);
        return;
      }

      if (maxWidth < 0) maxWidth = 0;
      if (maxHeight < 0) maxHeight = 0;
      if (quality < 0) quality = 0;
      if (quality > 100) quality = 100;

      if (targetPath == null || targetPath.length() == 0)
        targetPath = srcPath + ".jpg";

      String newPath = compressImage(srcPath, targetPath, quality, maxWidth, maxHeight, rotate, blur, blurZoom);
      if (newPath == null || newPath.length() == 0)
        result.error("Encode Jpeg Failed", null, null);
      else
        result.success(newPath);

    } else if ("getImgInfo".equals(method)) {

      String imageFile = call.argument("imageFile");
      this.getImgInfo(result, imageFile);

    } else if ("getResImgInfo".equals(method)) {

      String resName = call.argument("resName");
      String resType = call.argument("resType");
      if (resType == null || resType.length() == 0)
        resType = "mipmap";
      String packageName = mRegistrar.activity().getPackageName();
      Resources res = mRegistrar.activity().getResources();
      int id = getResID(res, resName, resType, packageName);
      if (id != 0) {
        this.getImgInfo(result, res, id);
      } else
        result.success(null);

    } else if ("encodeJpegWithBuffer".equals(method)) {

      try {
        List<Object> args = (List<Object>) call.arguments;
        byte[] arr = (byte[]) args.get(0);
        int quality = (int) args.get(1);
        int maxWidth = (int) args.get(2);
        int maxHeight = (int) args.get(3);
        int rotate = (int) args.get(4);
        int blur = (int) args.get(5);
        int blurZoom = (int) args.get(6);

        if (maxWidth < 0) maxWidth = 0;
        if (maxHeight < 0) maxHeight = 0;
        if (quality < 0) quality = 0;
        if (quality > 100) quality = 100;

        result.success(compressBytesImage(arr, quality, maxWidth, maxHeight, rotate, blur, blurZoom));
      } catch (Exception e) {
        e.printStackTrace();
        result.success(null);
      }

    } else if ("encodeImageWithRes".equals(method)) {

      try {
        List<Object> args = (List<Object>) call.arguments;
        String resName = (String) args.get(0);
        int quality = (int) args.get(1);
        int maxWidth = (int) args.get(2);
        int maxHeight = (int) args.get(3);
        int rotate = (int) args.get(4);
        int blur = (int) args.get(5);
        int blurZoom = (int) args.get(6);
        String resType = null;
        if (args.size() >= 8) {
          resType = (String) args.get(7);
        }
        if (resType == null || resType.length() == 0)
          resType = "mipmap";

        if (maxWidth < 0) maxWidth = 0;
        if (maxHeight < 0) maxHeight = 0;
        if (quality < 0) quality = 0;
        if (quality > 100) quality = 100;

        String packageName = mRegistrar.activity().getPackageName();
        result.success(compressResImage(resName, resType, packageName, quality, maxWidth, maxHeight, rotate, blur, blurZoom));
      } catch (Exception e) {
        e.printStackTrace();
        result.success(null);
      }

    } else if ("loadResFile".equals(method)) {

      try {
        List<Object> args = (List<Object>) call.arguments;
        String resName = (String) args.get(0);
        String resType = (String) args.get(1);
        if (resType == null || resType.length() == 0)
          resType = "mipmap";
        String packageName = mRegistrar.activity().getPackageName();
        Resources res = mRegistrar.activity().getResources();
        int id = getResID(res, resName, resType, packageName);
        if (id != 0) {
          InputStream is = res.openRawResource(id);
          ByteArrayOutputStream bs = new ByteArrayOutputStream();
          byte[] buffer = new byte[4096];
          while (true) {
            int len = is.read(buffer);
            if (len > 0) bs.write(buffer, 0, len);
            if (len < buffer.length)
              break;
          }
          is.close();
          result.success(bs.toByteArray());
        } else
          result.success(null);
      } catch (Exception e) {
        e.printStackTrace();
        result.success(null);
      }

    } else {
      result.notImplemented();
    }
  }

  public String compressImage(String filePath, String targetPath, int quality, int maxWidth, int maxHeight, int rotate, int blur, int blurZoom)  {
      //Log.d("image_jpeg", String.format("srcfile: %s", filePath));
      //Log.d("image_jpeg", String.format("mw: %d, mh: %d, quality: %d, targetfile: %s", maxWidth, maxHeight, quality, targetPath));

      try {
        Bitmap bm = getSmallBitmap(filePath, maxWidth, maxHeight);
        // 旋转处理
        bm = rotateImage(bm, rotate);
        // 高斯模糊
        if (blur > 0) bm = blurImage(bm, blur, blurZoom);

        //Log.d("image_jpeg", String.format("nw: %d, nh: %d", bm.getWidth(), bm.getHeight()));

        File outputFile = getOutputFile(targetPath, true);
        if (outputFile == null) {
          return null;
        }
        FileOutputStream out = new FileOutputStream(outputFile);
        bm.compress(Bitmap.CompressFormat.JPEG, quality, out);

        //Log.d("image_jpeg", String.format("targerSize: %d, outputfile: %s", out.getChannel().size(), outputFile.getPath()));

        out.close();
        return outputFile.getPath();

      } catch (Exception e) {
        Log.d("image_jpeg", e.getMessage());
        return null;
      }
  }

  public byte[] compressBytesImage(byte[] buffer, int quality, int maxWidth, int maxHeight, int rotate, int blur, int blurZoom)  {
    try {
      Bitmap bm = getSmallBitmap(buffer, maxWidth, maxHeight);
      // 旋转处理
      bm = rotateImage(bm, rotate);
      // 高斯模糊
      if (blur > 0) bm = blurImage(bm, blur, blurZoom);

      ByteArrayOutputStream out = new ByteArrayOutputStream();
      bm.compress(Bitmap.CompressFormat.JPEG, quality, out);
      return out.toByteArray();
    } catch (Exception e) {
      Log.d("image_jpeg", e.getMessage());
      return null;
    }
  }

  public byte[] compressResImage(String resName, String resType, String packageName, int quality, int maxWidth, int maxHeight, int rotate, int blur, int blurZoom)  {
    try {
      Resources res = mRegistrar.activity().getResources();
      int id = getResID(res, resName, resType, packageName);
      if (id == 0) return null;

      Bitmap bm = getSmallBitmap(res, id, maxWidth, maxHeight);
      if (bm == null) return null;
      // 旋转处理
      bm = rotateImage(bm, rotate);
      // 高斯模糊
      if (blur > 0) bm = blurImage(bm, blur, blurZoom);

      ByteArrayOutputStream out = new ByteArrayOutputStream();
      bm.compress(Bitmap.CompressFormat.JPEG, quality, out);
      bm = null;
      return out.toByteArray();
    } catch (Exception e) {
      Log.d("image_jpeg", e.getMessage());
      return null;
    }
  }

  public Bitmap rotateImage(Bitmap bm, int rotate) {
    if (rotate % 360 != 0) {
      Matrix matrix = new Matrix();
      matrix.setRotate((float) rotate);
      return Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight(), matrix, false);
    } else
      return bm;
  }

  public Bitmap blurImage(Bitmap bm, int blur, int blurZoom) {
      if (blur > 0 && android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
          RenderScript rs = RenderScript.create(mRegistrar.activity());
          ScriptIntrinsicBlur _blur = ScriptIntrinsicBlur.create(rs, Element.U8_4(rs));
          int w = bm.getWidth();
          int h = bm.getHeight();
          Bitmap _temp;
          if (blurZoom == 0) {
              _temp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
          } else {
              int tw = w / blurZoom;
              int th = h / blurZoom;
              bm = Bitmap.createScaledBitmap(bm, tw, th, false);
              _temp = Bitmap.createBitmap(tw, th, Bitmap.Config.ARGB_8888);
          }
          Allocation _in = Allocation.createFromBitmap(rs, bm);
          Allocation _out = Allocation.createFromBitmap(rs, _temp);
          _blur.setRadius(Math.min(25.0f, (((float) blur) / 100.0f) * 25.0f)); // 0 ~ 25
          _blur.setInput(_in);
          _blur.forEach(_out);
          _out.copyTo(_temp);
          rs.destroy();
          if (blurZoom == 0)
              return Bitmap.createBitmap(_temp);
          else
              return Bitmap.createScaledBitmap(_temp, w, h, true);
      } else
          return bm;
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
        v = getOutputFile(mRegistrar.context().getCacheDir().getPath() + fileName, false);
        if (v != null) return v;
        v = getOutputFile(Environment.getExternalStorageDirectory().getAbsolutePath() + fileName, false);
      } catch (Exception e1) {
        return null;
      }
      return v;
    }
  }

  public String getFileName(String pathandname){
    int start = pathandname.lastIndexOf("/");
    int end = pathandname.lastIndexOf(".");
    if (start!=-1 && end!=-1)
      return pathandname.substring(start+1, end);
    else
      return pathandname;
  }

  public static Bitmap getSmallBitmap(String filePath, int maxWidth, int maxHeight) {
    final BitmapFactory.Options options = new BitmapFactory.Options();
    if (maxWidth > 0 && maxHeight > 0) {
      options.inJustDecodeBounds = true;
      BitmapFactory.decodeFile(filePath, options);
      options.inSampleSize = calculateInSampleSize(options, maxWidth, maxHeight);
      //Log.d("image_jpeg", String.format("outRatio: %d", options.inSampleSize));
    }
    options.inJustDecodeBounds = false;
    return BitmapFactory.decodeFile(filePath, options);
  }

  public static Bitmap getSmallBitmap(byte[] buffer, int maxWidth, int maxHeight) {
    final BitmapFactory.Options options = new BitmapFactory.Options();
    if (maxWidth > 0 && maxHeight > 0) {
      options.inJustDecodeBounds = true;
      BitmapFactory.decodeByteArray(buffer, 0, buffer.length);
      options.inSampleSize = calculateInSampleSize(options, maxWidth, maxHeight);
    }
    options.inJustDecodeBounds = false;
    return BitmapFactory.decodeByteArray(buffer, 0, buffer.length);
  }

  public static Bitmap getSmallBitmap(Resources res, int resId, int maxWidth, int maxHeight) {
    InputStream _is = res.openRawResource(resId);
    try {
      final BitmapFactory.Options options = new BitmapFactory.Options();
      if (maxWidth > 0 && maxHeight > 0) {
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeStream(_is, null, options);
        options.inSampleSize = calculateInSampleSize(options, maxWidth, maxHeight);
      }
      options.inJustDecodeBounds = false;
      Bitmap bm = BitmapFactory.decodeStream(_is, null, options);
      _is.close();
      return bm;
    } catch (IOException e) {
      return null;
    }
  }

  public static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
    final int width = options.outWidth;
    final int height = options.outHeight;
    int inSampleSize = 1;
    if (height > reqHeight || width > reqWidth) {
      final int heightRatio = Math.round((float) height / (float) reqHeight);
      final int widthRatio = Math.round((float) width / (float) reqWidth);
      inSampleSize = heightRatio > widthRatio ? heightRatio : widthRatio;
      Log.d("image_jpeg", String.format("w: %d, h: %d, wRatio: %d, hRatio: %d", width, height, widthRatio, heightRatio));
    };
    return inSampleSize;
  }

  public static int getResID(Resources res, String name, String resType, String packageName) {
    int id = 0;
    if (res != null && name != null && name.length() > 0) {
      try {
        id = res.getIdentifier(name, resType, packageName);
      } catch (Exception e) {
        e.printStackTrace();
      }
    }
    return id;
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

  public void getImgInfo(Result successResult, Resources res, int resId) {
    HashMap map = new HashMap();
    map.put("resId", resId);
    try {
      final BitmapFactory.Options options = new BitmapFactory.Options();
      options.inJustDecodeBounds = true;
      if (resId != 0) {
        map.put("size", res.openRawResourceFd(resId).getLength());
        InputStream is = res.openRawResource(resId);
        BitmapFactory.decodeStream(is, null, options);
        is.close();
        map.put("width", options.outWidth);
        map.put("height", options.outHeight);
      } else {
        map.put("error", "resources doesn't exist");
      }
      successResult.success(map);
    } catch (Exception e) {
      map.put("error", e.getMessage());
      successResult.success(map);
    }
  }

}

package com.example.pdftool;

import android.content.ContentValues;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;

import java.util.concurrent.Executors;
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader;

import java.util.Map;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.File;
import java.util.List;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "PDFTOOL_MERGE";

    private static final String CHANNEL = "pdftool/pdf";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        PDFBoxResourceLoader.init(getApplicationContext());

        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL).setMethodCallHandler((call, result) -> {

                    if (call.method.equals("merge")) {

                        List<String> files = call.argument("files");
                        String outputName = call.argument("outputName");

                        if (files == null || files.size() < 2) {
                            result.error("NO_FILES", "Select at least 2 files", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {

                                Log.d(TAG, "Merge started");
                                Log.d(TAG, "Input files: " + files.toString());

                                String fileName;

                                if (outputName != null && !outputName.trim().isEmpty()) {
                                    fileName = outputName + ".pdf";
                                } else {
                                    fileName = "merged_" + System.currentTimeMillis() + ".pdf";
                                }

                                ContentValues contentValues = new ContentValues();
                                contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
                                contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH,
                                        Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                Uri uri = getContentResolver().insert(
                                        MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                        contentValues);

                                if (uri == null) {
                                    Log.e(TAG, "Failed to create MediaStore entry");
                                    throw new Exception("Failed to create file");
                                }

                                File tempFile = new File(getCacheDir(), "temp_merge.pdf");

                                Log.d(TAG, "Temp output path: " + tempFile.getAbsolutePath());

                                PdfMergeService.merge(files, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);

                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;

                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                Log.d(TAG, "Merge completed successfully");

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {

                                Log.e(TAG, "Merge failed", e);

                                runOnUiThread(() -> result.error("MERGE_ERROR", e.getMessage(), null));
                            }
                        });

                    } else if (call.method.equals("split")) {

                        String inputPath = call.argument("inputPath");
                        Integer startPage = call.argument("startPage");
                        Integer endPage = call.argument("endPage");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || startPage == null || endPage == null) {
                            result.error("INVALID_ARGS", "Missing split arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {

                                Log.d(TAG, "Split started");

                                String fileName;

                                if (outputName != null && !outputName.trim().isEmpty()) {
                                    fileName = outputName + ".pdf";
                                } else {
                                    fileName = "split_" + System.currentTimeMillis() + ".pdf";
                                }

                                ContentValues contentValues = new ContentValues();
                                contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
                                contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH,
                                        Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                Uri uri = getContentResolver().insert(
                                        MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                        contentValues);

                                if (uri == null) {
                                    throw new Exception("Failed to create output file");
                                }

                                File tempFile = new File(getCacheDir(), "temp_split.pdf");

                                PdfSplitService.split(
                                        inputPath,
                                        startPage,
                                        endPage,
                                        tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);

                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;

                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {

                                Log.e(TAG, "Split failed", e);

                                runOnUiThread(() -> result.error("SPLIT_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("rotate")) {

                        String inputPath = call.argument("inputPath");
                        Map<Integer, Integer> rotations = call.argument("rotations");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || rotations == null) {
                            result.error("INVALID_ARGS", "Missing rotate arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {

                                String fileName;

                                if (outputName != null && !outputName.trim().isEmpty()) {
                                    fileName = outputName + ".pdf";
                                } else {
                                    fileName = "rotated_" + System.currentTimeMillis() + ".pdf";
                                }

                                ContentValues contentValues = new ContentValues();
                                contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
                                contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH,
                                        Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                Uri uri = getContentResolver().insert(
                                        MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                        contentValues);

                                if (uri == null) {
                                    throw new Exception("Failed to create output file");
                                }

                                File tempFile = new File(getCacheDir(), "temp_rotate.pdf");

                                PdfRotateService.rotate(
                                        inputPath,
                                        rotations,
                                        tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;

                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {

                                Log.e(TAG, "Rotate failed", e);

                                runOnUiThread(() -> result.error("ROTATE_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("rearrange")) {

                        String inputPath = call.argument("inputPath");
                        List<Integer> pageOrder = call.argument("pageOrder");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || pageOrder == null) {
                            result.error("INVALID_ARGS", "Missing rearrange arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String fileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName + ".pdf"
                                        : "rearranged_" + System.currentTimeMillis() + ".pdf";

                                ContentValues contentValues = new ContentValues();
                                contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
                                contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH,
                                        Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                Uri uri = getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                        contentValues);
                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_rearrange.pdf");

                                PdfRearrangeService.rearrange(inputPath, pageOrder, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                Log.e(TAG, "Rearrange failed", e);
                                runOnUiThread(() -> result.error("REARRANGE_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("addPageNumbers")) {

                        String inputPath = call.argument("inputPath");
                        String format = call.argument("format");
                        String position = call.argument("position");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || format == null || position == null) {
                            result.error("INVALID_ARGS", "Missing page number arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String fileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName + ".pdf"
                                        : "numbered_" + System.currentTimeMillis() + ".pdf";

                                ContentValues contentValues = new ContentValues();
                                contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
                                contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH,
                                        Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                Uri uri = getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                        contentValues);
                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_numbers.pdf");

                                PdfPageNumberService.addNumbers(inputPath, format, position,
                                        tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                Log.e(TAG, "Add page numbers failed", e);
                                runOnUiThread(() -> result.error("PAGENUM_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("addWatermark")) {

                        String inputPath = call.argument("inputPath");
                        String text = call.argument("text");

                        Number colorNum = call.argument("color");
                        Double opacity = call.argument("opacity");
                        Double size = call.argument("size");
                        Double rotation = call.argument("rotation");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || text == null || colorNum == null || opacity == null || size == null
                                || rotation == null) {
                            result.error("INVALID_ARGS", "Missing watermark arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String fileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName + ".pdf"
                                        : "watermarked_" + System.currentTimeMillis() + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = getContentResolver().insert(
                                        android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_watermark.pdf");

                                PdfWatermarkService.addWatermark(
                                        inputPath, text, colorNum.longValue(), opacity, size, rotation,
                                        tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Watermark failed", e);
                                runOnUiThread(() -> result.error("WATERMARK_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("addSignature")) {

                        String inputPath = call.argument("inputPath");
                        List<Map<String, Object>> placements = call.argument("placements");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || placements == null) {
                            result.error("INVALID_ARGS", "Missing signature arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String fileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName + ".pdf"
                                        : "signed_" + System.currentTimeMillis() + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = getContentResolver().insert(
                                        android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_signature.pdf");

                                PdfSignatureService.addSignatures(
                                        inputPath, placements, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Signature failed", e);
                                runOnUiThread(() -> result.error("SIGNATURE_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("compress")) {

                        String inputPath = call.argument("inputPath");
                        String mode = call.argument("mode");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || mode == null) {
                            result.error("INVALID_ARGS", "Missing compress arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "compressed_" + System.currentTimeMillis();
                                String fileName = baseFileName + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".pdf";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_compress.pdf");

                                PdfCompressService.compress(inputPath, mode, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Compress failed", e);
                                runOnUiThread(() -> result.error("COMPRESS_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("convertToGreyscale")) {

                        String inputPath = call.argument("inputPath");
                        String outputName = call.argument("outputName");

                        if (inputPath == null) {
                            result.error("INVALID_ARGS", "Missing greyscale arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "greyscale_" + System.currentTimeMillis();
                                String fileName = baseFileName + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".pdf";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_greyscale.pdf");

                                PdfGreyscaleService.convertToGreyscale(inputPath, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Greyscale failed", e);
                                runOnUiThread(() -> result.error("GREYSCALE_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("repairPdf")) {

                        String inputPath = call.argument("inputPath");
                        String outputName = call.argument("outputName");

                        if (inputPath == null) {
                            result.error("INVALID_ARGS", "Missing repair arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "repaired_" + System.currentTimeMillis();
                                String fileName = baseFileName + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".pdf";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_repair.pdf");

                                PdfRepairService.repair(inputPath, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Repair failed", e);
                                runOnUiThread(() -> result.error("REPAIR_ERROR",
                                        "Could not recover PDF: " + e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("protectPdf")) {

                        String inputPath = call.argument("inputPath");
                        String password = call.argument("password");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || password == null) {
                            result.error("INVALID_ARGS", "Missing protect arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "protected_" + System.currentTimeMillis();
                                String fileName = baseFileName + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".pdf";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_protect.pdf");

                                PdfProtectService.protect(inputPath, password, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Protection failed", e);
                                runOnUiThread(() -> result.error("PROTECT_ERROR",
                                        "Could not protect PDF: " + e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("unlockPdf")) {

                        String inputPath = call.argument("inputPath");
                        String password = call.argument("password");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || password == null) {
                            result.error("INVALID_ARGS", "Missing unlock arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "unlocked_" + System.currentTimeMillis();
                                String fileName = baseFileName + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".pdf";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_unlock.pdf");

                                PdfUnlockService.unlock(inputPath, password, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Unlock failed", e);
                                runOnUiThread(() -> result.error("UNLOCK_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("readMetadata")) {

                        String inputPath = call.argument("inputPath");
                        if (inputPath == null) {
                            result.error("INVALID_ARGS", "Missing inputPath", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                Map<String, String> metaData = PdfMetadataService.readMetadata(inputPath);
                                runOnUiThread(() -> result.success(metaData));
                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Read Metadata failed", e);
                                runOnUiThread(() -> result.error("READ_META_ERROR", e.getMessage(), null));
                            }
                        });

                    } else if (call.method.equals("writeMetadata")) {

                        String inputPath = call.argument("inputPath");
                        String title = call.argument("title");
                        String author = call.argument("author");
                        String subject = call.argument("subject");
                        String keywords = call.argument("keywords");
                        String creator = call.argument("creator");
                        String outputName = call.argument("outputName");

                        if (inputPath == null) {
                            result.error("INVALID_ARGS", "Missing write metadata arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "metadata_" + System.currentTimeMillis();
                                String fileName = baseFileName + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".pdf";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_metadata.pdf");

                                PdfMetadataService.writeMetadata(inputPath, title, author, subject, keywords, creator,
                                        tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Write Metadata failed", e);
                                runOnUiThread(() -> result.error("WRITE_META_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("pdfToImage")) {

                        String inputPath = call.argument("inputPath");
                        String format = call.argument("format");
                        String outputName = call.argument("outputName");

                        if (inputPath == null || format == null) {
                            result.error("INVALID_ARGS", "Missing pdf to image arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "images_" + System.currentTimeMillis();

                                String fileName = baseFileName + ".zip";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/zip");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".zip";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_images.zip");

                                PdfToImageService.convert(inputPath, format, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "PDF to Image failed", e);
                                runOnUiThread(() -> result.error("PDF_TO_IMAGE_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("imageToPdf")) {

                        List<String> imagePaths = call.argument("imagePaths");
                        String outputName = call.argument("outputName");

                        if (imagePaths == null || imagePaths.isEmpty()) {
                            result.error("INVALID_ARGS", "Missing image paths", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "images_to_pdf_" + System.currentTimeMillis();
                                String fileName = baseFileName + ".pdf";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE,
                                        "application/pdf");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".pdf";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_image_to_pdf.pdf");

                                ImageToPdfService.convert(imagePaths, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "Image to PDF failed", e);
                                runOnUiThread(() -> result.error("IMAGE_TO_PDF_ERROR", e.getMessage(), null));
                            }
                        });
                    } else if (call.method.equals("pdfToText")) {

                        String inputPath = call.argument("inputPath");
                        String outputName = call.argument("outputName");

                        if (inputPath == null) {
                            result.error("INVALID_ARGS", "Missing pdf to text arguments", null);
                            return;
                        }

                        Executors.newSingleThreadExecutor().execute(() -> {
                            try {
                                String baseFileName = (outputName != null && !outputName.trim().isEmpty())
                                        ? outputName
                                        : "extracted_" + System.currentTimeMillis();

                                String fileName = baseFileName + ".txt";

                                android.content.ContentValues contentValues = new android.content.ContentValues();
                                contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                contentValues.put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "text/plain");
                                contentValues.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
                                        android.os.Environment.DIRECTORY_DOWNLOADS + "/Pdftool");

                                android.net.Uri uri = null;
                                try {
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                } catch (Exception e) {
                                    fileName = baseFileName + "_" + System.currentTimeMillis() + ".txt";
                                    contentValues.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                                    uri = getContentResolver().insert(
                                            android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
                                }

                                if (uri == null)
                                    throw new Exception("Failed to create output file");

                                File tempFile = new File(getCacheDir(), "temp_text.txt");

                                PdfToTextService.extractText(inputPath, tempFile.getAbsolutePath());

                                java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri);
                                java.io.InputStream inputStream = new java.io.FileInputStream(tempFile);

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }

                                inputStream.close();
                                outputStream.close();
                                tempFile.delete();

                                final String finalFileName = fileName;
                                runOnUiThread(() -> result.success("Saved in Downloads/Pdftool/" + finalFileName));

                            } catch (Exception e) {
                                android.util.Log.e(TAG, "PDF to Text failed", e);
                                runOnUiThread(() -> result.error("PDF_TO_TEXT_ERROR", e.getMessage(), null));
                            }
                        });
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
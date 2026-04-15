package com.example.pdftool;

import android.graphics.Bitmap;
import android.graphics.pdf.PdfRenderer;
import android.os.ParcelFileDescriptor;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class PdfToImageService {

    public static void convert(String inputPath, String format, String pageRange, String outputPath) throws Exception {
        File file = new File(inputPath);
        ParcelFileDescriptor fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);

        PdfRenderer renderer = new PdfRenderer(fd);
        FileOutputStream fos = new FileOutputStream(outputPath);
        ZipOutputStream zos = new ZipOutputStream(fos);

        try {
            int totalPages = renderer.getPageCount();
            List<Integer> pagesToConvert = parsePageRange(pageRange, totalPages);

            if (pagesToConvert.isEmpty()) {
                throw new Exception("No valid pages selected to convert.");
            }

            float scale = 2.0f;
            Bitmap.CompressFormat compressFormat = format.equals("PNG") ? Bitmap.CompressFormat.PNG : Bitmap.CompressFormat.JPEG;
            String fileExtension = format.equals("PNG") ? ".png" : ".jpg";

            for (int pageIndex : pagesToConvert) {
                PdfRenderer.Page rendererPage = renderer.openPage(pageIndex);

                try {
                    int width = (int) (rendererPage.getWidth() * scale);
                    int height = (int) (rendererPage.getHeight() * scale);

                    Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                    
                    bitmap.eraseColor(android.graphics.Color.WHITE);
                    rendererPage.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT);

                    ByteArrayOutputStream stream = new ByteArrayOutputStream();
                    bitmap.compress(compressFormat, 100, stream);

                    ZipEntry entry = new ZipEntry("page_" + (pageIndex + 1) + fileExtension);
                    zos.putNextEntry(entry);
                    
                    zos.write(stream.toByteArray());
                    zos.closeEntry();

                    stream.close();
                    bitmap.recycle();

                } finally {
                    if (rendererPage != null) {
                        rendererPage.close();
                    }
                }
            }
        } finally {
            zos.close();
            fos.close();
            renderer.close();
            fd.close();
        }
    }

    private static List<Integer> parsePageRange(String range, int totalPages) throws Exception {
        List<Integer> result = new ArrayList<>();
        
        if (range == null || range.trim().isEmpty() || range.equalsIgnoreCase("all")) {
            for (int i = 0; i < totalPages; i++) {
                result.add(i);
            }
            return result;
        }

        try {
            String[] parts = range.split(",");
            for (String part : parts) {
                part = part.trim();
                if (part.contains("-")) {
                    String[] bounds = part.split("-");
                    int start = Integer.parseInt(bounds[0].trim()) - 1;
                    int end = Integer.parseInt(bounds[1].trim()) - 1;
                    
                    // Ensure valid bounds
                    start = Math.max(0, start);
                    end = Math.min(totalPages - 1, end);
                    
                    for (int i = start; i <= end; i++) {
                        if (!result.contains(i)) result.add(i);
                    }
                } else {
                    int page = Integer.parseInt(part) - 1;
                    if (page >= 0 && page < totalPages && !result.contains(page)) {
                        result.add(page);
                    }
                }
            }
        } catch (NumberFormatException e) {
            throw new Exception("Invalid page range format. Please use formats like '1, 3, 5-10'.");
        }
        
        return result;
    }
}
package com.example.pdftool;

import android.graphics.Bitmap;
import android.graphics.pdf.PdfRenderer;
import android.os.ParcelFileDescriptor;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class PdfToImageService {

    public static void convert(String inputPath, String format, String outputPath) throws Exception {
        File file = new File(inputPath);
        ParcelFileDescriptor fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);

        PdfRenderer renderer = new PdfRenderer(fd);

        FileOutputStream fos = new FileOutputStream(outputPath);
        ZipOutputStream zos = new ZipOutputStream(fos);

        try {
            float scale = 2.0f;
            
            Bitmap.CompressFormat compressFormat = format.equals("PNG") ? Bitmap.CompressFormat.PNG : Bitmap.CompressFormat.JPEG;
            String fileExtension = format.equals("PNG") ? ".png" : ".jpg";

            for (int i = 0; i < renderer.getPageCount(); i++) {
                PdfRenderer.Page rendererPage = renderer.openPage(i);

                try {
                    int width = (int) (rendererPage.getWidth() * scale);
                    int height = (int) (rendererPage.getHeight() * scale);

                    Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                    
                    bitmap.eraseColor(android.graphics.Color.WHITE);
                    rendererPage.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT);

                    ByteArrayOutputStream stream = new ByteArrayOutputStream();
                    bitmap.compress(compressFormat, 100, stream);

                    ZipEntry entry = new ZipEntry("page_" + (i + 1) + fileExtension);
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
}
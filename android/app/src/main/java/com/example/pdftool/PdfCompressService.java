package com.example.pdftool;

import android.graphics.Bitmap;
import android.graphics.pdf.PdfRenderer;
import android.os.ParcelFileDescriptor;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream;
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle;
import com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory;
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject;

import java.io.File;

public class PdfCompressService {

    public static void compress(
            String inputPath,
            String mode,
            String outputPath) throws Exception {

        float scale = 1.0f;
        float quality = 1.0f;

        switch (mode) {
            case "HIGH_QUALITY": 
                scale = 2.0f;
                quality = 0.7f;
                break;
            case "STANDARD":     
                scale = 1.5f;
                quality = 0.4f;
                break;
            case "SMALLEST":     
                scale = 1.0f;
                quality = 0.15f;
                break;
        }

        File file = new File(inputPath);
        ParcelFileDescriptor fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
        
        PdfRenderer renderer = new PdfRenderer(fd);
        PDDocument document = new PDDocument();

        try {
            for (int i = 0; i < renderer.getPageCount(); i++) {
                PdfRenderer.Page rendererPage = renderer.openPage(i);
                
                int width = (int) (rendererPage.getWidth() * scale);
                int height = (int) (rendererPage.getHeight() * scale);
                
                Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                bitmap.eraseColor(android.graphics.Color.WHITE); 
                
                rendererPage.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT);
                
                PDPage page = new PDPage(new PDRectangle(rendererPage.getWidth(), rendererPage.getHeight()));
                document.addPage(page);
                
                PDImageXObject pdImage = JPEGFactory.createFromImage(document, bitmap, quality);
                PDPageContentStream contentStream = new PDPageContentStream(document, page);
                contentStream.drawImage(pdImage, 0, 0, rendererPage.getWidth(), rendererPage.getHeight());
                
                contentStream.close();
                rendererPage.close();
                bitmap.recycle();
            }

            document.save(outputPath);
            
        } finally {
            document.close();
            renderer.close();
            fd.close();
        }
    }
}
package com.example.pdftool;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.ColorMatrix;
import android.graphics.ColorMatrixColorFilter;
import android.graphics.Paint;
import android.graphics.pdf.PdfRenderer;
import android.os.ParcelFileDescriptor;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream;
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle;
import com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory;
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject;

import java.io.File;

public class PdfGreyscaleService {

    public static void convertToGreyscale(String inputPath, String outputPath) throws Exception {
        File file = new File(inputPath);
        ParcelFileDescriptor fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);

        PdfRenderer renderer = new PdfRenderer(fd);
        PDDocument document = new PDDocument();

        ColorMatrix matrix = new ColorMatrix();
        matrix.setSaturation(0);
        ColorMatrixColorFilter filter = new ColorMatrixColorFilter(matrix);
        Paint greyscalePaint = new Paint();
        greyscalePaint.setColorFilter(filter);

        try {
            float scale = 2.0f;

            for (int i = 0; i < renderer.getPageCount(); i++) {
                PdfRenderer.Page rendererPage = renderer.openPage(i);
                
                try {
                    int width = (int) (rendererPage.getWidth() * scale);
                    int height = (int) (rendererPage.getHeight() * scale);

                    Bitmap colorBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                    colorBitmap.eraseColor(android.graphics.Color.WHITE);
                    rendererPage.render(colorBitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT);

                    Bitmap greyBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                    Canvas canvas = new Canvas(greyBitmap);
                    canvas.drawBitmap(colorBitmap, 0, 0, greyscalePaint);

                    PDPage page = new PDPage(new PDRectangle(rendererPage.getWidth(), rendererPage.getHeight()));
                    document.addPage(page);

                    PDImageXObject pdImage = JPEGFactory.createFromImage(document, greyBitmap, 0.7f);
                    PDPageContentStream contentStream = new PDPageContentStream(document, page);
                    contentStream.drawImage(pdImage, 0, 0, rendererPage.getWidth(), rendererPage.getHeight());

                    contentStream.close();
                    colorBitmap.recycle();
                    
                } finally {
                    if (rendererPage != null) {
                        rendererPage.close();
                    }
                }
            }

            document.save(outputPath);

        } finally {
            document.close();
            renderer.close();
            fd.close();
        }
    }
}
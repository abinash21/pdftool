package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream;
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle;
import com.tom_roush.pdfbox.pdmodel.font.PDFont;
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font;
import com.tom_roush.pdfbox.pdmodel.graphics.state.PDExtendedGraphicsState;
import com.tom_roush.pdfbox.util.Matrix;

import java.io.File;

public class PdfWatermarkService {

    public static void addWatermark(
            String inputPath, 
            String text, 
            long colorValue, 
            double opacity,
            double size, 
            double rotationDegrees, 
            String outputPath) throws Exception {

        PDDocument document = PDDocument.load(new File(inputPath));
        
        try {
            PDFont font = PDType1Font.HELVETICA_BOLD;

            int r = (int) ((colorValue >> 16) & 0xFF);
            int g = (int) ((colorValue >> 8) & 0xFF);
            int b = (int) ((colorValue >> 0) & 0xFF);

            PDExtendedGraphicsState graphicsState = new PDExtendedGraphicsState();
            graphicsState.setNonStrokingAlphaConstant((float) opacity);

            for (PDPage page : document.getPages()) {
                PDRectangle mediaBox = page.getMediaBox();
                
                PDPageContentStream contentStream = new PDPageContentStream(
                        document, page, PDPageContentStream.AppendMode.APPEND, true, true);

                contentStream.setGraphicsStateParameters(graphicsState);
                contentStream.setNonStrokingColor(r, g, b);
                contentStream.beginText();
                contentStream.setFont(font, (float) size);

                float textWidth = (font.getStringWidth(text) / 1000.0f) * (float) size;
                float textHeight = (font.getFontDescriptor().getCapHeight() / 1000.0f) * (float) size;

                float centerX = mediaBox.getWidth() / 2;
                float centerY = mediaBox.getHeight() / 2;

                Matrix matrix = Matrix.getTranslateInstance(centerX, centerY);
                matrix.rotate(Math.toRadians(rotationDegrees));
                matrix.translate(-textWidth / 2, -textHeight / 2);

                contentStream.setTextMatrix(matrix);
                contentStream.showText(text);
                contentStream.endText();
                contentStream.close();
            }

            document.save(outputPath);
        } finally {
            document.close();
        }
    }
}
package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream;
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle;
import com.tom_roush.pdfbox.pdmodel.font.PDFont;
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font;

import java.io.File;

public class PdfPageNumberService {

    public static void addNumbers(
            String inputPath,
            String format,
            String position,
            String outputPath) throws Exception {

        PDDocument document = PDDocument.load(new File(inputPath));
        
        try {
            PDFont font = PDType1Font.HELVETICA_BOLD;
            int fontSize = 10;
            int totalPages = document.getNumberOfPages();

            for (int i = 0; i < totalPages; i++) {
                PDPage page = document.getPage(i);
                PDRectangle mediaBox = page.getMediaBox();
                
                float width = mediaBox.getWidth();
                float height = mediaBox.getHeight();

                String pageText = format.replace("{n}", String.valueOf(i + 1))
                                        .replace("{total}", String.valueOf(totalPages));

                float textWidth = (font.getStringWidth(pageText) / 1000.0f) * fontSize;
                float margin = 30;

                float x = 0;
                float y = 0;

                switch (position) {
                    case "TOP_LEFT":
                        x = margin;
                        y = height - margin;
                        break;
                    case "TOP_CENTER":
                        x = (width - textWidth) / 2;
                        y = height - margin;
                        break;
                    case "TOP_RIGHT":
                        x = width - textWidth - margin;
                        y = height - margin;
                        break;
                    case "BOTTOM_LEFT":
                        x = margin;
                        y = margin;
                        break;
                    case "BOTTOM_CENTER":
                        x = (width - textWidth) / 2;
                        y = margin;
                        break;
                    case "BOTTOM_RIGHT":
                        x = width - textWidth - margin;
                        y = margin;
                        break;
                }

                PDPageContentStream contentStream = new PDPageContentStream(
                        document, page, PDPageContentStream.AppendMode.APPEND, true, true);
                
                contentStream.beginText();
                contentStream.setFont(font, fontSize);
                contentStream.newLineAtOffset(x, y);
                contentStream.showText(pageText);
                contentStream.endText();
                contentStream.close();
            }

            document.save(outputPath);
        } finally {
            document.close();
        }
    }
}
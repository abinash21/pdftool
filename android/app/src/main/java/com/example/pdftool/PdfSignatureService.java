package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream;
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle;
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject;

import java.io.File;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class PdfSignatureService {

    public static void addSignatures(
            String inputPath,
            List<Map<String, Object>> placements,
            String outputPath) throws Exception {

        PDDocument document = PDDocument.load(new File(inputPath));

        Map<String, PDImageXObject> imageCache = new HashMap<>();
        
        try {
            int totalPages = document.getNumberOfPages();

            for (Map<String, Object> placement : placements) {
                
                int pageNum = ((Number) placement.get("page")).intValue();
                double xPercent = ((Number) placement.get("xPercent")).doubleValue();
                double yPercent = ((Number) placement.get("yPercent")).doubleValue();
                double widthPercent = ((Number) placement.get("widthPercent")).doubleValue();
                String imagePath = (String) placement.get("imagePath");

                if (pageNum < 1 || pageNum > totalPages || imagePath == null) continue;
                
                PDImageXObject pdImage = imageCache.get(imagePath);
                if (pdImage == null) {
                    pdImage = PDImageXObject.createFromFile(imagePath, document);
                    imageCache.put(imagePath, pdImage);
                }

                float imageAspectRatio = pdImage.getHeight() / (float) pdImage.getWidth();
                
                PDPage page = document.getPage(pageNum - 1); 
                PDRectangle mediaBox = page.getMediaBox();

                float pageWidth = mediaBox.getWidth();
                float pageHeight = mediaBox.getHeight();

                float actualSigWidth = (float) (pageWidth * widthPercent);
                float actualSigHeight = actualSigWidth * imageAspectRatio;

                float x = (float) (pageWidth * xPercent);
                float y = (float) (pageHeight - (pageHeight * yPercent) - actualSigHeight);

                PDPageContentStream contentStream = new PDPageContentStream(
                        document, page, PDPageContentStream.AppendMode.APPEND, true, true);

                contentStream.drawImage(pdImage, x, y, actualSigWidth, actualSigHeight);
                contentStream.close();
            }

            document.save(outputPath);
        } finally {
            document.close();
        }
    }
}
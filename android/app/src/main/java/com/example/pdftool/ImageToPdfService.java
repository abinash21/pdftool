package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream;
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle;
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject;

import java.io.File;
import java.util.List;

public class ImageToPdfService {

    public static void convert(List<String> imagePaths, String outputPath) throws Exception {
        PDDocument document = new PDDocument();

        try {
            for (String imagePath : imagePaths) {
                PDImageXObject pdImage = PDImageXObject.createFromFile(imagePath, document);

                float width = pdImage.getWidth();
                float height = pdImage.getHeight();
                PDPage page = new PDPage(new PDRectangle(width, height));
                
                document.addPage(page);

                PDPageContentStream contentStream = new PDPageContentStream(document, page);
                contentStream.drawImage(pdImage, 0, 0, width, height);
                contentStream.close();
            }

            document.save(outputPath);
        } finally {
            document.close();
        }
    }
}
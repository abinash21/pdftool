package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;

import java.io.File;
import java.util.Map;

public class PdfRotateService {

    public static void rotate(
            String inputPath,
            Map<Integer, Integer> rotations,
            String outputPath) throws Exception {

        PDDocument document = PDDocument.load(new File(inputPath));

        try {

            int totalPages = document.getNumberOfPages();

            for (Map.Entry<Integer, Integer> entry : rotations.entrySet()) {

                int pageIndex = entry.getKey();
                int angle = entry.getValue();

                if (pageIndex >= 0 && pageIndex < totalPages) {

                    PDPage page = document.getPage(pageIndex);

                    int currentRotation = page.getRotation();

                    int newRotation = (currentRotation + angle) % 360;

                    page.setRotation(newRotation);
                }
            }

            document.save(outputPath);

        } finally {

            document.close();
        }
    }
}
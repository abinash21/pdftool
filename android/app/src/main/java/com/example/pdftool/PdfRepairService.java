package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;

import java.io.File;

public class PdfRepairService {

    public static void repair(String inputPath, String outputPath) throws Exception {
        
        PDDocument document = PDDocument.load(new File(inputPath));
        
        try {
            document.save(outputPath);
        } finally {
            document.close();
        }
    }
}
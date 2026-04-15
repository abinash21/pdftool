package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;

import java.io.File;

public class PdfUnlockService {

    public static void unlock(String inputPath, String password, String outputPath) throws Exception {
        
        PDDocument document = PDDocument.load(new File(inputPath), password);

        try {
            document.setAllSecurityToBeRemoved(true);
            
            document.save(outputPath);
            
        } finally {
            document.close();
        }
    }
}
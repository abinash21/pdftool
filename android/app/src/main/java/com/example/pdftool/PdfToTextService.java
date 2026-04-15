package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.text.PDFTextStripper;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;

public class PdfToTextService {

    public static void extractText(String inputPath, String outputPath) throws Exception {
        PDDocument document = PDDocument.load(new File(inputPath));

        try {
            PDFTextStripper stripper = new PDFTextStripper();
            
            String text = stripper.getText(document);

            FileOutputStream fos = new FileOutputStream(outputPath);
            OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
            
            osw.write(text);
            
            osw.close();
            fos.close();
            
        } finally {
            document.close();
        }
    }
}
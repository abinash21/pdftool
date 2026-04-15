package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.encryption.AccessPermission;
import com.tom_roush.pdfbox.pdmodel.encryption.StandardProtectionPolicy;

import java.io.File;

public class PdfProtectService {

    public static void protect(String inputPath, String password, String outputPath) throws Exception {
        PDDocument document = PDDocument.load(new File(inputPath));

        try {
            AccessPermission accessPermission = new AccessPermission();

            StandardProtectionPolicy spp = new StandardProtectionPolicy(password, password, accessPermission);
            
            spp.setEncryptionKeyLength(128);
            
            document.protect(spp);
            
            document.save(outputPath);
            
        } finally {
            document.close();
        }
    }
}
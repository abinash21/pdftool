package com.example.pdftool;

import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDDocumentInformation;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

public class PdfMetadataService {

    public static Map<String, String> readMetadata(String inputPath) throws Exception {
        PDDocument document = PDDocument.load(new File(inputPath));
        Map<String, String> metaMap = new HashMap<>();

        try {
            PDDocumentInformation info = document.getDocumentInformation();
            if (info != null) {
                metaMap.put("title", info.getTitle() != null ? info.getTitle() : "");
                metaMap.put("author", info.getAuthor() != null ? info.getAuthor() : "");
                metaMap.put("subject", info.getSubject() != null ? info.getSubject() : "");
                metaMap.put("keywords", info.getKeywords() != null ? info.getKeywords() : "");
                metaMap.put("creator", info.getCreator() != null ? info.getCreator() : "");
            }
        } finally {
            document.close();
        }
        return metaMap;
    }

    public static void writeMetadata(
            String inputPath, 
            String title, 
            String author, 
            String subject, 
            String keywords, 
            String creator, 
            String outputPath) throws Exception {
            
        PDDocument document = PDDocument.load(new File(inputPath));

        try {
            PDDocumentInformation info = document.getDocumentInformation();
            if (info == null) {
                info = new PDDocumentInformation();
                document.setDocumentInformation(info);
            }

            info.setTitle(title);
            info.setAuthor(author);
            info.setSubject(subject);
            info.setKeywords(keywords);
            info.setCreator(creator);

            document.save(outputPath);
            
        } finally {
            document.close();
        }
    }
}
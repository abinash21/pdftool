package com.example.pdftool;

import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.kernel.pdf.PdfWriter;

import java.util.List;

public class PdfRearrangeService {

    public static void rearrange(
            String inputPath,
            List<Integer> newPageOrder,
            String outputPath) throws Exception {

        PdfDocument src = new PdfDocument(new PdfReader(inputPath));
        PdfDocument dest = new PdfDocument(new PdfWriter(outputPath));

        try {
            for (int pageNum : newPageOrder) {
                src.copyPagesTo(pageNum, pageNum, dest);
            }
        } finally {
            src.close();
            dest.close();
        }
    }
}
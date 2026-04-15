package com.example.pdftool;

import com.itextpdf.kernel.pdf.*;
import com.itextpdf.kernel.utils.PdfMerger;

import java.util.List;
import java.util.ArrayList;
import java.io.File;

public class PdfSplitService {
    public static String split(String inputPath, int startPage, int endPage, String outputPath) throws Exception {
        PdfDocument src = new PdfDocument(new PdfReader(inputPath));
        int n = src.getNumberOfPages();

        if (startPage < 1) startPage = 1;
        if (endPage > n) endPage = n;
        if (startPage > endPage) {
            src.close();
            throw new IllegalArgumentException("startPage must be <= endPage");
        }

        PdfDocument dest = new PdfDocument(new PdfWriter(outputPath));
        PdfMerger merger = new PdfMerger(dest);
        merger.merge(src, startPage, endPage);

        src.close();
        dest.close();
        return outputPath;
    }
}
package com.example.pdftool;

import com.itextpdf.kernel.pdf.*;
import com.itextpdf.kernel.utils.PdfMerger;

import java.util.List;
import android.util.Log;

public class PdfMergeService {
    private static final String TAG = "PDFTOOL_MERGE";

    public static String merge(List<String> inputPaths, String outputPath) throws Exception {

    Log.d(TAG, "Creating output PDF: " + outputPath);

    PdfDocument pdf = new PdfDocument(new PdfWriter(outputPath));
    PdfMerger merger = new PdfMerger(pdf);

    for (String path : inputPaths) {

        Log.d(TAG, "Merging file: " + path);

        PdfDocument src = new PdfDocument(new PdfReader(path));
        merger.merge(src, 1, src.getNumberOfPages());
        src.close();
    }

    pdf.close();

    Log.d(TAG, "Merge finished");

    return outputPath;
}
}
# PDFBox Android rules
-keep class com.tom_roush.pdfbox.** { *; }
-keep class org.apache.fontbox.** { *; }

# Tell the compiler to ignore missing optional image decoders
-dontwarn com.tom_roush.pdfbox.**
-dontwarn org.apache.fontbox.**
-dontwarn com.gemalto.jp2.**
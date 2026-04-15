# 📄 PDFTool

**PDFTool** is a powerful, fully offline, feature-rich PDF manipulation suite for Android. Built with a beautiful Flutter UI and powered by deep native Java integrations (via Apache PDFBox and Android PdfRenderer), this app brings desktop-class PDF tools directly to your mobile device without relying on expensive cloud APIs.

## ✨ Features

PDFTool is designed as a "Swiss Army Knife" for documents. All processing is done **100% locally** on the device, ensuring maximum privacy and zero data usage.

* **🔀 Merge PDFs:** Select and reorder multiple PDF files and stitch them into a single document.
* **✂️ Split PDF:** Extract specific pages or divide a large document into smaller pieces.
* **🗜️ Compress PDF:** Reduce file size for easy email sharing.
* **🔒 Protect PDF:** Encrypt documents with secure passwords.
* **🔓 Unlock PDF:** Remove password protection from encrypted documents.
* **🖼️ PDF to Image:** Render all pages into high-quality JPG or PNG images, automatically packaged into a clean `.zip` archive.
* **📸 Image to PDF:** Select multiple images from your gallery, drag to reorder, and instantly convert them into a perfectly sized PDF.
* **📝 PDF to Text:** Extract all readable text from a document and save it as a lightweight `.txt` file.
* **📄 PDF to Word:** A custom, zero-dependency offline engine that extracts PDF text and dynamically builds a valid Microsoft Word (`.docx`) XML archive.
* **🏷️ Metadata Editor:** Read and completely rewrite hidden document properties (Title, Author, Creator, Keywords).
* **🕒 History Manager:** Easily track and revisit your previously modified files.
* **🌗 Dynamic Theme:** Seamlessly switch between beautiful Light and Dark modes.

## 🛠️ Tech Stack & Architecture

This project leverages Flutter for a fluid, responsive UI and MethodChannels to communicate with highly optimized Native Android code for heavy file lifting.

* **Frontend:** Flutter (Dart)
* **Backend (Native Android):** Java
* **Core PDF Engine:** `com.tom_roush.pdfbox` (Android port of Apache PDFBox)
* **Rendering Engine:** Android Native `PdfRenderer`
* **Key Packages:** `file_picker`, `syncfusion_flutter_pdfviewer`

## 🚀 Getting Started

### Prerequisites
* Flutter SDK installed
* Android Studio / Android SDK installed
* Git installed

### Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/abinash21/pdftool-flutter.git](https://github.com/abinash21/pdftool-flutter.git)
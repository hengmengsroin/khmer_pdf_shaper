import Foundation
import PDFKit

let pdfUrl = URL(fileURLWithPath: ".dart_tool/mixed_script_test.pdf")
guard let document = PDFDocument(url: pdfUrl) else {
    print("Failed to open PDF")
    exit(1)
}

var fullText = ""
for i in 0..<document.pageCount {
    if let page = document.page(at: i) {
        fullText += (page.string ?? "") + "\n"
    }
}

let extractedLines = fullText.components(separatedBy: .newlines)
    .map { $0.trimmingCharacters(in: .whitespaces) }
    .filter { !$0.isEmpty }

print("Extracted \(extractedLines.count) lines from PDFKit:")
for (i, line) in extractedLines.enumerated() {
    print("  [\(i)]: \(line)")
}

let expected = [
    "Invoice សួស្តី 123",
    "Price: $10 កម្ពុជា",
    "ABCកម្ពុជា123"
]

var passed = true
for (i, exp) in expected.enumerated() {
    if i >= extractedLines.count {
        print("Missing line \(i): expected '\(exp)'")
        passed = false
    } else if extractedLines[i] != exp {
        print("Mismatch on line \(i): expected '\(exp)', got '\(extractedLines[i])'")
        passed = false
    }
}

if passed {
    print("\nSUCCESS: macOS PDFKit extracted all mixed-script lines with 100% exact character equality!")
    exit(0)
} else {
    print("\nFAILURE: Mismatches detected in PDFKit extraction.")
    exit(1)
}

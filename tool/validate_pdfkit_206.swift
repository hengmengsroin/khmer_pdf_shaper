import Foundation
import PDFKit

let pdfUrl = URL(fileURLWithPath: "/Users/hengmengsroin/.gemini/antigravity-ide/brain/124ef2f0-1d61-4b71-b0d3-671001f9375b/scratch/khmer_golden_206_fixtures.pdf")
guard let document = PDFDocument(url: pdfUrl) else {
    print("Failed to open PDF")
    exit(1)
}

let fixturesUrl = URL(fileURLWithPath: "test/fixtures/khmer_golden_fixtures.json")
let fixturesData = try Data(contentsOf: fixturesUrl)
let json = try JSONSerialization.jsonObject(with: fixturesData) as! [String: Any]
let fixtures = json["fixtures"] as! [[String: Any]]

var fullText = ""
for i in 0..<document.pageCount {
    if let page = document.page(at: i) {
        fullText += (page.string ?? "") + "\n"
    }
}

let lines = fullText.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
print("Extracted \(lines.count) lines from PDFKit")

var mismatches = 0
for (idx, fixture) in fixtures.enumerated() {
    let expectedText = fixture["text"] as! String
    if idx < lines.count {
        let actual = lines[idx]
        if actual != expectedText {
            mismatches += 1
            print("Mismatch [\(idx)] (\(fixture["id"]!)): expected [\(expectedText)], got [\(actual)]")
        }
    } else {
        mismatches += 1
        print("Missing line [\(idx)] (\(fixture["id"]!))")
    }
}

if mismatches == 0 {
    print("\nSUCCESS: macOS PDFKit extracted 206/206 fixtures with 100% exact character equality!")
} else {
    print("\nFAILURE: \(mismatches) mismatches found in PDFKit.")
}

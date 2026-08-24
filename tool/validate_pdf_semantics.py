import json
import pypdf
import pdfplumber

pdf_path = "/Users/hengmengsroin/.gemini/antigravity-ide/brain/124ef2f0-1d61-4b71-b0d3-671001f9375b/scratch/khmer_golden_206_fixtures.pdf"
fixtures_path = "test/fixtures/khmer_golden_fixtures.json"

with open(fixtures_path, "r", encoding="utf-8") as f:
    fixtures_data = json.load(f)
    fixtures = fixtures_data["fixtures"]

print(f"Total fixtures to validate: {len(fixtures)}")

reader = pypdf.PdfReader(pdf_path)
full_text = ""
for i, page in enumerate(reader.pages):
    page_text = page.extract_text() or ""
    full_text += page_text + "\n"

lines = [line.strip() for line in full_text.split("\n") if line.strip()]
print(f"Extracted {len(lines)} non-empty lines from PDF")

# Verify each fixture
mismatches = 0
for idx, fixture in enumerate(fixtures):
    expected_text = fixture["text"]
    if idx < len(lines):
        actual_line = lines[idx]
        if actual_line != expected_text:
            mismatches += 1
            print(f"Mismatch at index {idx} ({fixture['id']}): expected {repr(expected_text)}, got {repr(actual_line)}")
    else:
        mismatches += 1
        print(f"Missing line at index {idx} ({fixture['id']}): expected {repr(expected_text)}")

if mismatches == 0:
    print(f"\nSUCCESS: 206/206 golden fixtures extracted with 100% exact character equality!")
else:
    print(f"\nFAILURE: {mismatches} mismatches found.")

import json
import pdfplumber

pdf_path = "/Users/hengmengsroin/.gemini/antigravity-ide/brain/124ef2f0-1d61-4b71-b0d3-671001f9375b/scratch/khmer_golden_206_fixtures.pdf"
fixtures_path = "test/fixtures/khmer_golden_fixtures.json"

with open(fixtures_path, "r", encoding="utf-8") as f:
    fixtures_data = json.load(f)
    fixtures = fixtures_data["fixtures"]

with pdfplumber.open(pdf_path) as pdf:
    full_text = ""
    for page in pdf.pages:
        full_text += (page.extract_text() or "") + "\n"

lines = [line.strip() for line in full_text.split("\n") if line.strip()]
print(f"pdfplumber extracted {len(lines)} lines")

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
        print(f"Missing line at index {idx}")

if mismatches == 0:
    print("\nSUCCESS: pdfplumber extracted 206/206 golden fixtures with 100% exact character equality!")
else:
    print(f"\nFAILURE: {mismatches} mismatches found in pdfplumber.")

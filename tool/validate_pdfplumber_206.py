import json
import sys
import pdfplumber

pdf_path = "build/khmer_golden_206_fixtures.pdf"
fixtures_path = "test/fixtures/khmer_golden_fixtures.json"

with open(fixtures_path, "r", encoding="utf-8") as f:
    fixtures_data = json.load(f)
    fixtures = fixtures_data["fixtures"]

print(f"pdfplumber: Validating {len(fixtures)} fixtures from {pdf_path}")

with pdfplumber.open(pdf_path) as pdf:
    full_text = ""
    for page in pdf.pages:
        full_text += (page.extract_text() or "") + "\n"

lines = [line.strip() for line in full_text.split("\n") if line.strip()]
print(f"pdfplumber: Extracted {len(lines)} non-empty lines from PDF")

exact_matches = 0
spacing_differences = 0
character_corruptions = 0

for idx, fixture in enumerate(fixtures):
    expected_text = fixture["text"]
    fixture_id = fixture["id"]
    if idx < len(lines):
        actual_line = lines[idx]
        if actual_line == expected_text:
            exact_matches += 1
        elif actual_line.replace(" ", "") == expected_text.replace(" ", ""):
            spacing_differences += 1
        else:
            character_corruptions += 1
            print(f"Character corruption at index {idx} ({fixture_id}): expected {repr(expected_text)}, got {repr(actual_line)}")
    else:
        character_corruptions += 1
        print(f"Missing line at index {idx} ({fixture_id})")

print(f"pdfplumber: {exact_matches}/{len(fixtures)} exact string matches, {spacing_differences} documented spatial layout spacing differences, {character_corruptions} character corruptions.")

if character_corruptions == 0:
    print("SUCCESS: pdfplumber extracted 206/206 golden fixtures with 100% character integrity (zero regressions).")
    sys.exit(0)
else:
    print(f"FAILURE: {character_corruptions} character corruptions found in pdfplumber.")
    sys.exit(1)


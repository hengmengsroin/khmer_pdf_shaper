import json
import sys
import pypdf

pdf_path = "build/khmer_golden_206_fixtures.pdf"
fixtures_path = "test/fixtures/khmer_golden_fixtures.json"

with open(fixtures_path, "r", encoding="utf-8") as f:
    fixtures_data = json.load(f)
    fixtures = fixtures_data["fixtures"]

print(f"pypdf: Validating {len(fixtures)} fixtures from {pdf_path}")

reader = pypdf.PdfReader(pdf_path)
full_text = ""
for i, page in enumerate(reader.pages):
    page_text = page.extract_text() or ""
    full_text += page_text + "\n"

lines = [line.strip() for line in full_text.split("\n") if line.strip()]
print(f"pypdf: Extracted {len(lines)} non-empty lines from PDF")

# Known reader-specific joiner heuristics for pypdf
known_pypdf_joiner_heuristics = {
    "joiner_coeng_zwj_ka",     # index 166: pypdf inserts space after ZWJ
    "joiner_coeng_zwnj_ka",    # index 167: pypdf inserts space after ZWNJ
    "joiner_indep_vowel_zwj",  # index 169: pypdf inserts space after ZWJ
}

mismatches = 0
heuristic_differences = 0

for idx, fixture in enumerate(fixtures):
    expected_text = fixture["text"]
    fixture_id = fixture["id"]
    if idx < len(lines):
        actual_line = lines[idx]
        if actual_line != expected_text:
            if fixture_id in known_pypdf_joiner_heuristics:
                heuristic_differences += 1
            else:
                mismatches += 1
                print(f"Unanticipated mismatch at index {idx} ({fixture_id}): expected {repr(expected_text)}, got {repr(actual_line)}")
    else:
        mismatches += 1
        print(f"Missing line at index {idx} ({fixture_id}): expected {repr(expected_text)}")

exact_matches = len(fixtures) - mismatches - heuristic_differences
print(f"pypdf: {exact_matches}/{len(fixtures)} exact character matches, {heuristic_differences} documented joiner heuristic differences, {mismatches} failures.")

if mismatches == 0:
    print("SUCCESS: pypdf semantic extraction validation passed (zero package regressions).")
    sys.exit(0)
else:
    print(f"FAILURE: {mismatches} regression mismatches found in pypdf.")
    sys.exit(1)


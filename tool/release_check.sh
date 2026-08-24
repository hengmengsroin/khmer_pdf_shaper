#!/bin/bash
set -e

# ==============================================================================
# Khmer PDF Shaper — Release Quality Regression Runner (Phase 8)
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TOTAL_START=$(date +%s)

echo "=============================================================================="
echo "           KHMER PDF SHAPER — RELEASE GATE VERIFICATION RUNNER"
echo "=============================================================================="
echo "Date:      $(date)"
echo "Host OS:   $(uname -s) $(uname -r) ($(uname -m))"
echo "Directory: $ROOT_DIR"
echo ""

# ------------------------------------------------------------------------------
# 1. Environment & Tool Version Diagnostics
# ------------------------------------------------------------------------------
echo "--- Toolchain & Environment Diagnostics ---"
echo "Flutter:    $(flutter --version 2>/dev/null | head -n 1 || echo 'N/A')"
echo "Dart:       $(dart --version 2>&1 | head -n 1 || echo 'N/A')"
if command -v python3 >/dev/null 2>&1; then
    echo "Python3:    $(python3 --version 2>&1)"
    echo "fontTools:  $(python3 -c 'import fontTools; print(fontTools.__version__)' 2>/dev/null || echo 'Not installed')"
    echo "pypdf:      $(python3 -c 'import pypdf; print(pypdf.__version__)' 2>/dev/null || echo 'Not installed')"
    echo "pdfplumber: $(python3 -c 'import pdfplumber; print(pdfplumber.__version__)' 2>/dev/null || echo 'Not installed')"
else
    echo "Python3:    Not found"
fi

if command -v swift >/dev/null 2>&1; then
    echo "Swift:      $(swift --version 2>&1 | head -n 1)"
else
    echo "Swift:      Not found"
fi

if command -v hb-shape >/dev/null 2>&1; then
    echo "HarfBuzz:   $(hb-shape --version 2>&1 | head -n 1)"
else
    echo "HarfBuzz:   External hb-shape CLI not in PATH (Fixtures use frozen 14.2.1 oracle)"
fi
echo ""

# Gate Results Tracking
declare -a GATES
declare -a STATUSES
declare -a DURATIONS

run_gate() {
    local gate_id="$1"
    local gate_name="$2"
    local gate_cmd="$3"
    
    echo "=============================================================================="
    echo ">>> RUNNING $gate_id: $gate_name"
    echo "    Command: $gate_cmd"
    echo "------------------------------------------------------------------------------"
    
    local start_time=$(date +%s)
    
    if eval "$gate_cmd"; then
        local end_time=$(date +%s)
        local elapsed=$((end_time - start_time))
        echo "--> $gate_id PASSED (${elapsed}s)"
        GATES+=("$gate_id — $gate_name")
        STATUSES+=("PASS")
        DURATIONS+=("${elapsed}s")
    else
        local end_time=$(date +%s)
        local elapsed=$((end_time - start_time))
        echo "--> $gate_id FAILED (${elapsed}s)"
        GATES+=("$gate_id — $gate_name")
        STATUSES+=("FAIL")
        DURATIONS+=("${elapsed}s")
        echo "CRITICAL FAILURE in $gate_id: $gate_name"
        exit 1
    fi
    echo ""
}

skip_gate() {
    local gate_id="$1"
    local gate_name="$2"
    local reason="$3"
    
    echo "=============================================================================="
    echo ">>> SKIPPING $gate_id: $gate_name"
    echo "    Reason: $reason"
    echo "------------------------------------------------------------------------------"
    GATES+=("$gate_id — $gate_name")
    STATUSES+=("SKIPPED ($reason)")
    DURATIONS+=("0s")
    echo ""
}

# ------------------------------------------------------------------------------
# GATE A — Static Analysis
# ------------------------------------------------------------------------------
run_gate "GATE A" "Static Analysis (flutter analyze)" "flutter analyze"

# ------------------------------------------------------------------------------
# GATE B — Comprehensive Flutter/Dart Tests (Fast Tier)
# ------------------------------------------------------------------------------
run_gate "GATE B" "Unit and Integration Tests (flutter test)" "flutter test"

# ------------------------------------------------------------------------------
# GATE C — HarfBuzz Differential Shaping Oracle Gate
# ------------------------------------------------------------------------------
run_gate "GATE C" "HarfBuzz Differential Shaping (206 Goldens + 805 Stress Cases)" \
    "flutter test test/harfbuzz_differential_test.dart test/stress_corpus_test.dart"

# ------------------------------------------------------------------------------
# GATE D — PDF Semantic Extraction Gate (PDFKit, pypdf, pdfplumber)
# ------------------------------------------------------------------------------
if [[ "$(uname -s)" == "Darwin" ]] && command -v swift >/dev/null 2>&1; then
    run_gate "GATE D" "PDF Semantic Extraction (PDFKit 206/206 + Mixed Script)" \
        "swift tool/validate_pdfkit_206.swift && swift tool/validate_mixed_pdf_extraction.swift && python3 tool/validate_pdf_semantics.py && python3 tool/validate_pdfplumber_206.py"
else
    skip_gate "GATE D" "PDFKit Native Semantic Extraction" "PLATFORM UNAVAILABLE (Non-macOS or Swift missing)"
    run_gate "GATE D (Portable)" "PDF Semantic Extraction (pypdf + pdfplumber)" \
        "python3 tool/validate_pdf_semantics.py && python3 tool/validate_pdfplumber_206.py"
fi

# ------------------------------------------------------------------------------
# GATE E — Visual Parity & Layout Regression Gate
# ------------------------------------------------------------------------------
run_gate "GATE E" "Visual Parity & Layout Regression" \
    "flutter test test/robustness/visual_regression_stress_test.dart test/layout/khmer_line_breaking_test.dart test/layout/khmer_newline_test.dart"

# ------------------------------------------------------------------------------
# GATE F — Flutter Web Release Build Gate
# ------------------------------------------------------------------------------
run_gate "GATE F" "Flutter Web Release Build" \
    "(cd example && flutter build web --release)"

# ------------------------------------------------------------------------------
# GATE G — Pure Dart CLI Consumer Gate
# ------------------------------------------------------------------------------
run_gate "GATE G" "Pure Dart CLI Consumer" \
    "dart run tool/dart_cli_consumer.dart"

# ------------------------------------------------------------------------------
# GATE H — Font, Structural & Subset TrueType Validation Gate
# ------------------------------------------------------------------------------
run_gate "GATE H" "Font Structural, Composite & Subset Validation (fontTools)" \
    "flutter test test/pdf/pdf_structure_release_test.dart test/robustness/zero_length_glyph_hardening_test.dart test/robustness/composite_glyph_stress_test.dart && python3 tool/validate_subset_fonttools.py"

# ------------------------------------------------------------------------------
# Final Release Summary Report
# ------------------------------------------------------------------------------
TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

echo "=============================================================================="
echo "                 RELEASE QUALITY SUITE EXECUTION SUMMARY"
echo "=============================================================================="
printf "%-10s %-55s %-12s %s\n" "GATE" "DESCRIPTION" "STATUS" "DURATION"
echo "------------------------------------------------------------------------------"

ALL_PASSED=true
for i in "${!GATES[@]}"; do
    STATUS="${STATUSES[$i]}"
    if [[ "$STATUS" == FAIL* ]]; then
        ALL_PASSED=false
    fi
    printf "%-65s %-15s %s\n" "${GATES[$i]}" "${STATUSES[$i]}" "${DURATIONS[$i]}"
done

echo "------------------------------------------------------------------------------"
echo "Total Execution Duration: ${TOTAL_DURATION}s"
echo "Repository Working Tree:  $(git status --short | wc -l | tr -d ' ') modified tracked files"

if [ "$ALL_PASSED" = true ]; then
    echo ""
    echo ">>> ALL RELEASE GATES PASSED SUCCESSFULLY <<<"
    echo "Exit Assessment: Phase 8 ready for release preparation"
    echo "=============================================================================="
    exit 0
else
    echo ""
    echo ">>> RELEASE GATES CONTAINED FAILURES <<<"
    echo "Exit Assessment: Phase 8 requires regression-suite follow-up"
    echo "=============================================================================="
    exit 1
fi

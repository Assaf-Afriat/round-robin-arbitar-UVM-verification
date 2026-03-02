# ============================================================================
# Assertion Report Generation Script for Round-Robin Arbiter
# ============================================================================
# Usage: vsim -c -do assertion_report.do
#    or: vsim -c -do "set TEST_NAME RrFullTest4; do assertion_report.do"
# Generates assertion report from UCDB file (run with --coverage-report first)
# ============================================================================

set PROJECT_ROOT [file normalize [file join [pwd] ".." ".."]]
set COVERAGE_DIR "$PROJECT_ROOT/coverage"

# Allow TEST_NAME to be set externally, default to RrFullTest4
if {![info exists TEST_NAME]} {
    set TEST_NAME "RrFullTest4"
}

set UCDB_FILE "$COVERAGE_DIR/${TEST_NAME}.ucdb"
set REPORT_DIR "$COVERAGE_DIR/assertion_report"
set REPORT_TXT "$REPORT_DIR/${TEST_NAME}_assertion_report.txt"
set REPORT_HTML "$REPORT_DIR/html"

file mkdir $REPORT_DIR

puts "============================================================================"
puts "              ROUND-ROBIN ARBITER - ASSERTION REPORT"
puts "============================================================================"
puts "UCDB File: $UCDB_FILE"
puts "Report Dir: $REPORT_DIR"
puts "============================================================================"

if {![file exists $UCDB_FILE]} {
    puts "ERROR: UCDB file not found: $UCDB_FILE"
    puts "Please run: python run.py --coverage-report"
    quit -f
}

puts "\n--- Generating Text Assertion Report ---"
vcover report -assert -details -output $REPORT_TXT $UCDB_FILE

puts "\n--- Generating HTML Assertion Report ---"
vcover report -assert -html -htmldir $REPORT_HTML $UCDB_FILE

puts "\n============================================================================"
puts "                    ASSERTION REPORT SUMMARY"
puts "============================================================================"
vcover report -assert $UCDB_FILE

puts "============================================================================"
puts "Reports Generated:"
puts "  Text Report: $REPORT_TXT"
puts "  HTML Report: $REPORT_HTML/index.html"
puts "============================================================================"

quit -f

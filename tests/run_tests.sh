#!/bin/bash

# Test Runner for MSFT Collector Expect Scripts
# Runs all unit and integration tests and generates reports

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_TEST_DIR="$SCRIPT_DIR/unit"
INTEGRATION_TEST_DIR="$SCRIPT_DIR/integration"
TEST_RESULTS_DIR="$SCRIPT_DIR/../test_results"
TEST_LOGS_DIR="$SCRIPT_DIR/../test_logs"

# Create results directories
mkdir -p "$TEST_RESULTS_DIR"
mkdir -p "$TEST_LOGS_DIR"

# Test result tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Log file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$TEST_LOGS_DIR/test_run_${TIMESTAMP}.log"

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to run a test file
run_test_file() {
    local test_file=$1
    local test_name=$(basename "$test_file")
    
    print_color "$BLUE" "Running $test_name..."
    
    # Run the test and capture output
    if expect "$test_file" >> "$LOG_FILE" 2>&1; then
        print_color "$GREEN" "  ✓ $test_name PASSED"
        ((PASSED_TESTS++))
        return 0
    else
        print_color "$RED" "  ✗ $test_name FAILED"
        ((FAILED_TESTS++))
        echo "  See $LOG_FILE for details"
        return 1
    fi
}

# Function to run all tests in a directory
run_tests_in_dir() {
    local dir=$1
    local type=$2
    
    if [ ! -d "$dir" ]; then
        print_color "$YELLOW" "Warning: $type test directory not found: $dir"
        return
    fi
    
    local test_files=$(find "$dir" -name "test_*.exp" -type f)
    
    if [ -z "$test_files" ]; then
        print_color "$YELLOW" "No $type tests found in $dir"
        return
    fi
    
    print_color "$BLUE" "\n========================================="
    print_color "$BLUE" "$type Tests"
    print_color "$BLUE" "=========================================\n"
    
    for test_file in $test_files; do
        run_test_file "$test_file"
        ((TOTAL_TESTS++))
    done
}

# Function to check if expect is installed
check_dependencies() {
    if ! command -v expect &> /dev/null; then
        print_color "$RED" "Error: 'expect' is not installed"
        echo "Install it with:"
        echo "  macOS: brew install expect"
        echo "  Ubuntu/Debian: sudo apt-get install expect"
        echo "  RHEL/CentOS: sudo yum install expect"
        exit 1
    fi
}

# Function to print summary
print_summary() {
    echo ""
    print_color "$BLUE" "========================================="
    print_color "$BLUE" "Test Summary"
    print_color "$BLUE" "========================================="
    echo "Total Tests:  $TOTAL_TESTS"
    print_color "$GREEN" "Passed:       $PASSED_TESTS"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        print_color "$RED" "Failed:       $FAILED_TESTS"
    else
        print_color "$GREEN" "Failed:       $FAILED_TESTS"
    fi
    
    echo ""
    echo "Log file: $LOG_FILE"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_color "$GREEN" "✓ All tests passed!"
        return 0
    else
        print_color "$RED" "✗ Some tests failed"
        return 1
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] [TEST_TYPE]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo ""
    echo "Test Types:"
    echo "  unit           Run only unit tests"
    echo "  integration    Run only integration tests"
    echo "  all            Run all tests (default)"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run all tests"
    echo "  $0 unit            # Run only unit tests"
    echo "  $0 integration     # Run only integration tests"
    echo "  $0 -v all          # Run all tests with verbose output"
}

# Main script
main() {
    local test_type="all"
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            unit|integration|all)
                test_type=$1
                shift
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Print header
    print_color "$BLUE" "========================================="
    print_color "$BLUE" "MSFT Collector Test Runner"
    print_color "$BLUE" "========================================="
    echo "Timestamp: $(date)"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Initialize log file
    echo "Test run started at $(date)" > "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    # Run tests based on type
    case $test_type in
        unit)
            run_tests_in_dir "$UNIT_TEST_DIR" "Unit"
            ;;
        integration)
            run_tests_in_dir "$INTEGRATION_TEST_DIR" "Integration"
            ;;
        all)
            run_tests_in_dir "$UNIT_TEST_DIR" "Unit"
            run_tests_in_dir "$INTEGRATION_TEST_DIR" "Integration"
            ;;
    esac
    
    # Print summary and exit with appropriate code
    if print_summary; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
